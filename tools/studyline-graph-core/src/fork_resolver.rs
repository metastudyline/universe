use crate::dag::KnowledgeGraph;
use std::collections::HashSet;

pub struct ForkResolver;

impl ForkResolver {
    /// Finds lowest common ancestor nodes between two school branches
    pub fn find_common_ancestors(
        graph: &KnowledgeGraph,
        branch_a_node: &str,
        branch_b_node: &str,
    ) -> Vec<String> {
        let mut ancestors_a = HashSet::new();
        let mut ancestors_b = HashSet::new();

        if let Some(&idx_a) = graph.node_indices.get(branch_a_node) {
            let mut queue = vec![idx_a];
            while let Some(curr) = queue.pop() {
                for parent in graph.graph.neighbors_directed(curr, petgraph::Direction::Incoming) {
                    if ancestors_a.insert(parent) {
                        queue.push(parent);
                    }
                }
            }
        }

        if let Some(&idx_b) = graph.node_indices.get(branch_b_node) {
            let mut queue = vec![idx_b];
            while let Some(curr) = queue.pop() {
                for parent in graph.graph.neighbors_directed(curr, petgraph::Direction::Incoming) {
                    if ancestors_b.insert(parent) {
                        queue.push(parent);
                    }
                }
            }
        }

        ancestors_a
            .intersection(&ancestors_b)
            .map(|&idx| graph.graph[idx].id.clone())
            .collect()
    }
}
