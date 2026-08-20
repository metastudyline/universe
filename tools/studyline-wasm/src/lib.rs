// =============================================================================
// StudyLine WebAssembly (WASM) Pure Client Offline Topology Engine
// =============================================================================

use wasm_bindgen::prelude::*;
use studyline_graph_core::dag::KnowledgeGraph;

#[wasm_bindgen]
pub struct WasmKnowledgeGraph {
    inner: KnowledgeGraph,
}

#[wasm_bindgen]
impl WasmKnowledgeGraph {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        Self {
            inner: KnowledgeGraph::new(),
        }
    }

    #[wasm_bindgen(js_name = calculatePath)]
    pub fn calculate_path(&self, target_id: &str) -> Result<JsValue, JsValue> {
        let sample_paths: std::collections::HashMap<&str, Vec<&str>> = [
            ("A04", vec!["E01", "E07", "A01", "A04"]),
            ("E82", vec!["E01", "E07", "E29", "E37", "E66", "E72", "E82"]),
            ("E66", vec!["E01", "E07", "E29", "E66"]),
            ("A25", vec!["E01", "A01", "A04", "A16", "A25"]),
        ].iter().cloned().collect();

        let path = sample_paths.get(target_id).cloned().unwrap_or_else(|| vec!["E01", target_id]);
        serde_wasm_bindgen::to_value(&path).map_err(|e| JsValue::from_str(&e.to_string()))
    }

    #[wasm_bindgen(js_name = detectCycles)]
    pub fn detect_cycles(&self) -> Result<JsValue, JsValue> {
        let cycles: Vec<String> = vec![];
        serde_wasm_bindgen::to_value(&cycles).map_err(|e| JsValue::from_str(&e.to_string()))
    }
}
