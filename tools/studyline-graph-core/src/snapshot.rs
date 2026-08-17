use crate::dag::{KnowledgeGraph, NodeMetadata, DependencyEdge};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub struct GraphSnapshot {
    pub version: String,
    pub nodes: Vec<NodeMetadata>,
    pub edges: Vec<(String, String, DependencyEdge)>,
}

impl GraphSnapshot {
    pub fn from_graph(graph: &KnowledgeGraph) -> Self {
        let mut nodes = Vec::new();
        let mut edges = Vec::new();

        for node_idx in graph.graph.node_indices() {
            nodes.push(graph.graph[node_idx].clone());
        }

        for edge_idx in graph.graph.edge_indices() {
            if let Some((from_idx, to_idx)) = graph.graph.edge_endpoints(edge_idx) {
                let from_id = graph.graph[from_idx].id.clone();
                let to_id = graph.graph[to_idx].id.clone();
                let edge = graph.graph[edge_idx].clone();
                edges.push((from_id, to_id, edge));
            }
        }

        Self {
            version: "1.0.0".to_string(),
            nodes,
            edges,
        }
    }

    pub fn to_graph(&self) -> Result<KnowledgeGraph, crate::dag::GraphError> {
        let mut graph = KnowledgeGraph::new();
        for node in &self.nodes {
            graph.add_node(node.clone());
        }
        for (from_id, to_id, edge) in &self.edges {
            graph.add_prerequisite_edge(from_id, to_id, edge.clone())?;
        }
        Ok(graph)
    }
}
