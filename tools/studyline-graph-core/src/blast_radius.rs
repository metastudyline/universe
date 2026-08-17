use crate::dag::KnowledgeGraph;
use std::collections::{HashSet, VecDeque};

#[derive(Debug, Clone)]
pub struct BlastRadiusResult {
    pub direct_changed: Vec<String>,
    pub affected_downstream: Vec<String>,
    pub total_impacted_count: usize,
}

pub struct BlastRadiusAnalyzer;

impl BlastRadiusAnalyzer {
    /// Computes all downstream nodes that depend directly or transitively on changed_nodes
    pub fn compute_blast_radius(
        graph: &KnowledgeGraph,
        changed_nodes: &[String],
    ) -> BlastRadiusResult {
        let mut direct_changed = Vec::new();
        let mut affected = HashSet::new();
        let mut queue = VecDeque::new();

        for id in changed_nodes {
            if let Some(&idx) = graph.node_indices.get(id) {
                direct_changed.push(id.clone());
                queue.push_back(idx);
            }
        }

        while let Some(curr_idx) = queue.pop_front() {
            // Traverse outgoing edges (nodes that depend on curr_idx)
            for downstream_idx in graph.graph.neighbors_directed(curr_idx, petgraph::Direction::Outgoing) {
                let downstream_id = graph.graph[downstream_idx].id.clone();
                if affected.insert(downstream_id) {
                    queue.push_back(downstream_idx);
                }
            }
        }

        let total_impacted_count = direct_changed.len() + affected.len();
        let affected_downstream: Vec<String> = affected.into_iter().collect();

        BlastRadiusResult {
            direct_changed,
            affected_downstream,
            total_impacted_count,
        }
    }
}
