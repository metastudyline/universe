use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    response::IntoResponse,
    routing::get,
    Router,
};
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};
use tower_http::cors::{Any, CorsLayer};

use studyline_graph_core::dag::KnowledgeGraph;

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum BridgeMessage {
    #[serde(rename = "PING")]
    Ping,
    #[serde(rename = "PONG")]
    Pong,
    #[serde(rename = "GRAPH_UPDATED")]
    GraphUpdated {
        blast_radius: BlastRadiusPayload,
        changed_files: Vec<String>,
    },
    #[serde(rename = "NODE_MODIFIED")]
    NodeModified {
        node_id: String,
        title: String,
        summary: String,
        content_hash: String,
        updated_at: String,
    },
    #[serde(rename = "CALCULATE_PATH")]
    CalculatePath {
        target_node_id: String,
        mastered_node_ids: Vec<String>,
    },
    #[serde(rename = "PATH_CALCULATED")]
    PathCalculated {
        target_node_id: String,
        path_nodes: Vec<String>,
        total_weight: usize,
        calculation_time_us: u64,
    },
    #[serde(rename = "GET_GRAPH_SNAPSHOT")]
    GetGraphSnapshot,
    #[serde(rename = "GRAPH_SNAPSHOT")]
    GraphSnapshot {
        schema_version: String,
        total_nodes: usize,
        total_edges: usize,
    },
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct BlastRadiusPayload {
    pub direct_changed: Vec<String>,
    pub affected_downstream: Vec<String>,
    pub total_impacted_count: usize,
}

#[derive(Clone)]
pub struct AppState {
    pub graph: Arc<RwLock<KnowledgeGraph>>,
    pub tx: broadcast::Sender<BridgeMessage>,
}

pub fn create_router(state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .route("/ws", get(ws_handler))
        .route("/health", get(health_handler))
        .layer(cors)
        .with_state(state)
}

async fn health_handler() -> &'static str {
    "OK"
}

async fn ws_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

async fn handle_socket(mut socket: WebSocket, state: AppState) {
    let mut rx = state.tx.subscribe();

    loop {
        tokio::select! {
            // Receive from WebSocket client
            msg = socket.next() => {
                match msg {
                    Some(Ok(Message::Text(text))) => {
                        if let Ok(parsed) = serde_json::from_str::<BridgeMessage>(&text) {
                            match parsed {
                                BridgeMessage::Ping => {
                                    let pong = serde_json::to_string(&BridgeMessage::Pong).unwrap();
                                    let _ = socket.send(Message::Text(pong)).await;
                                }
                                BridgeMessage::CalculatePath { target_node_id, .. } => {
                                    let graph = state.graph.read().await;
                                    let start = std::time::Instant::now();
                                    let path = graph.find_learning_path(&target_node_id).unwrap_or_default();
                                    let elapsed = start.elapsed().as_micros() as u64;

                                    let resp = BridgeMessage::PathCalculated {
                                        target_node_id,
                                        total_weight: path.len(),
                                        path_nodes: path,
                                        calculation_time_us: elapsed,
                                    };
                                    let text = serde_json::to_string(&resp).unwrap();
                                    let _ = socket.send(Message::Text(text)).await;
                                }
                                BridgeMessage::GetGraphSnapshot => {
                                    let graph = state.graph.read().await;
                                    let resp = BridgeMessage::GraphSnapshot {
                                        schema_version: "1.0.0".to_string(),
                                        total_nodes: graph.node_count(),
                                        total_edges: graph.edge_count(),
                                    };
                                    let text = serde_json::to_string(&resp).unwrap();
                                    let _ = socket.send(Message::Text(text)).await;
                                }
                                _ => {}
                            }
                        }
                    }
                    Some(Ok(Message::Close(_))) | None => break,
                    _ => {}
                }
            }
            // Receive broadcast from file watcher
            broadcast_msg = rx.recv() => {
                if let Ok(msg) = broadcast_msg {
                    if let Ok(text) = serde_json::to_string(&msg) {
                        if socket.send(Message::Text(text)).await.is_err() {
                            break;
                        }
                    }
                }
            }
        }
    }
}
