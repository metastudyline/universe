use anyhow::Result;
use clap::Parser;
use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

mod server;
mod watcher;

use server::{create_router, AppState, BridgeMessage};
use studyline_graph_core::dag::KnowledgeGraph;
use watcher::start_file_watcher;

#[derive(Parser, Debug)]
#[command(author, version, about = "StudyLine Local High-Performance Rust Bridge Daemon")]
struct Args {
    #[arg(short, long, default_value = "127.0.0.1:3001")]
    bind: String,

    #[arg(short, long, default_value = "domains")]
    domains_dir: PathBuf,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    println!("======================================================");
    println!("  ✦ StudyLine High-Performance Rust Bridge Daemon     ");
    println!("  ⚡ Address: http://{}", args.bind);
    println!("  📁 Watching: {:?}", args.domains_dir);
    println!("======================================================");

    let graph = Arc::new(RwLock::new(KnowledgeGraph::new()));
    let (tx, _rx) = broadcast::channel::<BridgeMessage>(128);

    // Start file watcher
    let _ = start_file_watcher(args.domains_dir.clone(), graph.clone(), tx.clone());

    let state = AppState {
        graph: graph.clone(),
        tx: tx.clone(),
    };

    let app = create_router(state);
    let addr: SocketAddr = args.bind.parse()?;
    let listener = tokio::net::TcpListener::bind(addr).await?;

    println!("[INFO] 🚀 Daemon server listening on {}", addr);
    axum::serve(listener, app).await?;

    Ok(())
}
