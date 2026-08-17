use petgraph::algo::tarjan_scc;
use crate::dag::KnowledgeGraph;

pub struct CycleDetector;

impl CycleDetector {
    /// Detects if there are cycles and returns lists of strongly connected components with >1 node
    pub fn find_cycles(graph: &KnowledgeGraph) -> Vec<Vec<String>> {
        let sccs = tarjan_scc(&graph.graph);
        let mut cycles = Vec::new();

        for scc in sccs {
            if scc.len() > 1 {
                let cycle_node_ids: Vec<String> = scc
                    .into_iter()
                    .map(|idx| graph.graph[idx].id.clone())
                    .collect();
                cycles.push(cycle_node_ids);
            } else if scc.len() == 1 {
                // Check for self-loop
                let node_idx = scc[0];
                if graph.graph.contains_edge(node_idx, node_idx) {
                    cycles.push(vec![graph.graph[node_idx].id.clone()]);
                }
            }
        }
        cycles
    }

    /// Formats a cycle path into a human-readable diagnostic string (e.g. A -> B -> C -> A)
    pub fn format_cycle_diagnostic(cycle: &[String]) -> String {
        if cycle.is_empty() {
            return String::new();
        }
        let mut path = cycle.join(" -> ");
        if let Some(first) = cycle.first() {
            path.push_str(" -> ");
            path.push_str(first);
        }
        path
    }
}
