use crate::dag::KnowledgeGraph;
use std::collections::HashSet;

pub struct LearningPath {
    pub target_id: String,
    pub ordered_steps: Vec<String>,
    pub total_prerequisites: usize,
}

pub struct PathPlanner;

impl PathPlanner {
    /// Computes the minimal learning path to achieve target_id given already mastered nodes
    pub fn plan_path(
        graph: &KnowledgeGraph,
        target_id: &str,
        mastered_nodes: &HashSet<String>,
    ) -> Option<LearningPath> {
        let target_idx = *graph.node_indices.get(target_id)?;
        
        // Reverse BFS/DFS to collect all ancestor prerequisites
        let mut required_nodes = HashSet::new();
        
        // Use an inverted traversal
        let mut queue = vec![target_idx];
        let mut visited = HashSet::new();
        visited.insert(target_idx);

        while let Some(curr_idx) = queue.pop() {
            let curr_id = &graph.graph[curr_idx].id;
            if !mastered_nodes.contains(curr_id) {
                required_nodes.insert(curr_id.clone());
            }

            // Find incoming edges (prerequisites)
            for neighbor in graph.graph.neighbors_directed(curr_idx, petgraph::Direction::Incoming) {
                if visited.insert(neighbor) {
                    queue.push(neighbor);
                }
            }
        }

        // Get global topological order and filter by required_nodes
        let full_order = graph.get_topological_order().ok()?;
        let ordered_steps: Vec<String> = full_order
            .into_iter()
            .filter(|id| required_nodes.contains(id))
            .collect();

        let total_prerequisites = ordered_steps.len();

        Some(LearningPath {
            target_id: target_id.to_string(),
            ordered_steps,
            total_prerequisites,
        })
    }
}
