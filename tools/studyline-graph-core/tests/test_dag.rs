use studyline_graph_core::*;
use std::collections::HashSet;

fn create_mock_node(id: &str) -> NodeMetadata {
    NodeMetadata {
        id: id.to_string(),
        title: format!("Title of {}", id),
        domain: "philosophy".to_string(),
        summary: format!("Summary of {}", id),
        schema_version: "1.0.0".to_string(),
        content_hash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef".to_string(),
        license: "CC-BY-SA-4.0".to_string(),
        maintainers: vec!["@kevin-tung".to_string()],
    }
}

fn create_mock_edge(target_id: &str) -> DependencyEdge {
    DependencyEdge {
        target_node_id: target_id.to_string(),
        dependency_type: dag::DependencyType::Strict,
        min_mastery_level: MasteryLevel::Mastery,
        rationale: Some("Core foundation prerequisite".to_string()),
    }
}

#[test]
fn test_dag_creation_and_topological_sort() {
    let mut graph = KnowledgeGraph::new();
    
    // A -> B -> C
    graph.add_node(create_mock_node("node_A"));
    graph.add_node(create_mock_node("node_B"));
    graph.add_node(create_mock_node("node_C"));

    graph.add_prerequisite_edge("node_A", "node_B", create_mock_edge("node_A")).unwrap();
    graph.add_prerequisite_edge("node_B", "node_C", create_mock_edge("node_B")).unwrap();

    assert!(graph.is_acyclic());
    assert_eq!(graph.node_count(), 3);
    assert_eq!(graph.edge_count(), 2);

    let order = graph.get_topological_order().unwrap();
    assert_eq!(order, vec!["node_A", "node_B", "node_C"]);
}

#[test]
fn test_cycle_detection() {
    let mut graph = KnowledgeGraph::new();
    
    // A -> B -> C -> A (Cycle!)
    graph.add_node(create_mock_node("node_A"));
    graph.add_node(create_mock_node("node_B"));
    graph.add_node(create_mock_node("node_C"));

    graph.add_prerequisite_edge("node_A", "node_B", create_mock_edge("node_A")).unwrap();
    graph.add_prerequisite_edge("node_B", "node_C", create_mock_edge("node_B")).unwrap();
    graph.add_prerequisite_edge("node_C", "node_A", create_mock_edge("node_C")).unwrap();

    assert!(!graph.is_acyclic());
    let cycles = CycleDetector::find_cycles(&graph);
    assert_eq!(cycles.len(), 1);
    assert_eq!(cycles[0].len(), 3);
    
    let diag = CycleDetector::format_cycle_diagnostic(&cycles[0]);
    assert!(diag.contains("node_A") && diag.contains("node_B") && diag.contains("node_C"));
}

#[test]
fn test_path_planning_with_mastered_nodes() {
    let mut graph = KnowledgeGraph::new();
    
    // A -> B -> C -> Target
    graph.add_node(create_mock_node("A"));
    graph.add_node(create_mock_node("B"));
    graph.add_node(create_mock_node("C"));
    graph.add_node(create_mock_node("Target"));

    graph.add_prerequisite_edge("A", "B", create_mock_edge("A")).unwrap();
    graph.add_prerequisite_edge("B", "C", create_mock_edge("B")).unwrap();
    graph.add_prerequisite_edge("C", "Target", create_mock_edge("C")).unwrap();

    let mut mastered = HashSet::new();
    mastered.insert("A".to_string()); // User already knows A

    let path = PathPlanner::plan_path(&graph, "Target", &mastered).unwrap();
    assert_eq!(path.ordered_steps, vec!["B", "C", "Target"]);
    assert_eq!(path.total_prerequisites, 3);
}

#[test]
fn test_blast_radius_computation() {
    let mut graph = KnowledgeGraph::new();
    
    // A -> B -> C, A -> D
    graph.add_node(create_mock_node("A"));
    graph.add_node(create_mock_node("B"));
    graph.add_node(create_mock_node("C"));
    graph.add_node(create_mock_node("D"));

    graph.add_prerequisite_edge("A", "B", create_mock_edge("A")).unwrap();
    graph.add_prerequisite_edge("B", "C", create_mock_edge("B")).unwrap();
    graph.add_prerequisite_edge("A", "D", create_mock_edge("A")).unwrap();

    let changed = vec!["A".to_string()];
    let report = BlastRadiusAnalyzer::compute_blast_radius(&graph, &changed);

    assert_eq!(report.direct_changed, vec!["A"]);
    assert_eq!(report.affected_downstream.len(), 3); // B, C, D
    assert_eq!(report.total_impacted_count, 4);
}
