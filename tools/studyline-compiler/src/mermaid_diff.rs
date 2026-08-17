use studyline_graph_core::blast_radius::BlastRadiusResult;

pub struct MermaidDiffExporter;

impl MermaidDiffExporter {
    pub fn generate_mermaid(result: &BlastRadiusResult) -> String {
        let mut mermaid = String::from("```mermaid\nflowchart TD\n");
        mermaid.push_str("    classDef added fill:#e6ffed,stroke:#2ea44f,stroke-width:2px;\n");
        mermaid.push_str("    classDef modified fill:#fff5b1,stroke:#b08800,stroke-width:2px;\n");
        mermaid.push_str("    classDef affected fill:#f1f8ff,stroke:#0366d6,stroke-dasharray: 3 3;\n\n");

        for direct in &result.direct_changed {
            let sanitized = direct.replace('.', "_").replace('-', "_");
            mermaid.push_str(&format!("    {}[\"[* 变动] {}\"]:::modified\n", sanitized, direct));
        }

        for aff in &result.affected_downstream {
            let sanitized = aff.replace('.', "_").replace('-', "_");
            mermaid.push_str(&format!("    {}[\"[~ 波及] {}\"]:::affected\n", sanitized, aff));
        }

        mermaid.push_str("```\n");
        mermaid
    }
}
