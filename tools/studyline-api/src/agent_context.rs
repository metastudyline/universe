use studyline_graph_core::dag::{KnowledgeGraph, NodeMetadata};

pub struct AgentContextBuilder;

impl AgentContextBuilder {
    /// Generates structured causal grounding prompt for LLM teaching assistants
    pub fn build_grounding_prompt(
        graph: &KnowledgeGraph,
        target_node_id: &str,
    ) -> Option<String> {
        let node_idx = *graph.node_indices.get(target_node_id)?;
        let meta = &graph.graph[node_idx];

        let mut prompt = String::new();
        prompt.push_str(&format!("### [Knowledge World Model Context: {}]\n", meta.title));
        prompt.push_str(&format!("- **Node ID**: `{}`\n", meta.id));
        prompt.push_str(&format!("- **Academic Domain**: {}\n", meta.domain));
        prompt.push_str(&format!("- **Summary**: {}\n\n", meta.summary));

        prompt.push_str("#### Verified Prerequisites (Grounding Dependencies):\n");
        let mut has_prereqs = false;
        for parent_idx in graph.graph.neighbors_directed(node_idx, petgraph::Direction::Incoming) {
            has_prereqs = true;
            let parent_meta = &graph.graph[parent_idx];
            prompt.push_str(&format!(
                "- `{}`: {} (Rationale: Core foundation)\n",
                parent_meta.id, parent_meta.title
            ));
        }

        if !has_prereqs {
            prompt.push_str("- [Root Node] No strict prerequisites required.\n");
        }

        prompt.push_str("\n#### Instruction for AI Assistant:\n");
        prompt.push_str("You must strictly adhere to the causal concepts defined in the verified prerequisites above. Do not assume the student knows concepts beyond this verified boundary without scaffolding.\n");

        Some(prompt)
    }
}
