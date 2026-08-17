use petgraph::graph::{DiGraph, NodeIndex};
use petgraph::algo::toposort;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum GraphError {
    #[error("Cycle detected in knowledge DAG")]
    CycleDetected,
    #[error("Node not found: {0}")]
    NodeNotFound(String),
    #[error("Dangling reference to prerequisite: {0}")]
    DanglingReference(String),
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[repr(u8)]
pub enum MasteryLevel {
    Ignorance = 0,
    Unknown = 1,
    Awareness = 2,
    Application = 3,
    Mastery = 4,
    Internalization = 5,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum DependencyType {
    Strict,
    Supporting,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DependencyEdge {
    pub target_node_id: String,
    pub dependency_type: DependencyType,
    pub min_mastery_level: MasteryLevel,
    pub rationale: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeMetadata {
    pub id: String,
    pub title: String,
    pub domain: String,
    pub summary: String,
    pub schema_version: String,
    pub content_hash: String,
    pub license: String,
    pub maintainers: Vec<String>,
}

pub struct KnowledgeGraph {
    pub graph: DiGraph<NodeMetadata, DependencyEdge, u32>,
    pub node_indices: HashMap<String, NodeIndex<u32>>,
}

impl KnowledgeGraph {
    pub fn new() -> Self {
        Self {
            graph: DiGraph::new(),
            node_indices: HashMap::new(),
        }
    }

    pub fn add_node(&mut self, meta: NodeMetadata) -> NodeIndex<u32> {
        let id = meta.id.clone();
        if let Some(&idx) = self.node_indices.get(&id) {
            self.graph[idx] = meta;
            idx
        } else {
            let idx = self.graph.add_node(meta);
            self.node_indices.insert(id, idx);
            idx
        }
    }

    pub fn add_prerequisite_edge(
        &mut self,
        from_id: &str,
        to_id: &str,
        edge: DependencyEdge,
    ) -> Result<(), GraphError> {
        let from_idx = self
            .node_indices
            .get(from_id)
            .copied()
            .ok_or_else(|| GraphError::DanglingReference(from_id.to_string()))?;
        let to_idx = self
            .node_indices
            .get(to_id)
            .copied()
            .ok_or_else(|| GraphError::NodeNotFound(to_id.to_string()))?;

        // Directed edge: from prerequisite (from_idx) to target dependent (to_idx)
        self.graph.add_edge(from_idx, to_idx, edge);
        Ok(())
    }

    pub fn is_acyclic(&self) -> bool {
        toposort(&self.graph, None).is_ok()
    }

    pub fn get_topological_order(&self) -> Result<Vec<String>, GraphError> {
        toposort(&self.graph, None)
            .map(|indices| {
                indices
                    .into_iter()
                    .map(|idx| self.graph[idx].id.clone())
                    .collect()
            })
            .map_err(|_| GraphError::CycleDetected)
    }

    pub fn node_count(&self) -> usize {
        self.graph.node_count()
    }

    pub fn edge_count(&self) -> usize {
        self.graph.edge_count()
    }
}
