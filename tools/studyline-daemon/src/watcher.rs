use anyhow::Result;
use notify_debouncer_mini::{new_debouncer, notify::RecursiveMode, DebounceEventResult};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{broadcast, RwLock};

use studyline_graph_core::blast_radius::BlastRadiusAnalyzer;
use studyline_graph_core::dag::KnowledgeGraph;

use crate::server::{BlastRadiusPayload, BridgeMessage};

pub fn start_file_watcher(
    domains_dir: PathBuf,
    graph: Arc<RwLock<KnowledgeGraph>>,
    tx: broadcast::Sender<BridgeMessage>,
) -> Result<()> {
    let tx_clone = tx.clone();
    let graph_clone = graph.clone();

    std::thread::spawn(move || {
        let (event_tx, event_rx) = std::sync::mpsc::channel();

        let mut debouncer = match new_debouncer(Duration::from_millis(50), event_tx) {
            Ok(d) => d,
            Err(e) => {
                eprintln!("[ERROR] Failed to create file debouncer: {:?}", e);
                return;
            }
        };

        if let Err(e) = debouncer.watcher().watch(Path::new(&domains_dir), RecursiveMode::Recursive) {
            eprintln!("[ERROR] Failed to watch directory {:?}: {:?}", domains_dir, e);
            return;
        }

        println!("[INFO] ⚡ File watcher actively monitoring: {:?}", domains_dir);

        for res in event_rx {
            match res {
                Ok(events) => {
                    let mut changed_files = Vec::new();
                    for event in events {
                        let path_str = event.path.to_string_lossy().to_string();
                        if path_str.ends_with("manifest.yml")
                            || path_str.ends_with("manifest.yaml")
                            || path_str.ends_with(".md")
                        {
                            changed_files.push(path_str);
                        }
                    }

                    if !changed_files.is_empty() {
                        let rt = tokio::runtime::Builder::new_current_thread()
                            .enable_all()
                            .build()
                            .unwrap();

                        rt.block_on(async {
                            let g = graph_clone.read().await;
                            let blast = BlastRadiusAnalyzer::compute_blast_radius(&g, &[]);

                            let msg = BridgeMessage::GraphUpdated {
                                blast_radius: BlastRadiusPayload {
                                    direct_changed: blast.direct_changed,
                                    affected_downstream: blast.affected_downstream,
                                    total_impacted_count: blast.total_impacted_count,
                                },
                                changed_files: changed_files.clone(),
                            };

                            let _ = tx_clone.send(msg);
                            println!("[INFO] 📢 Broadcasted GRAPH_UPDATED for {} files", changed_files.len());
                        });
                    }
                }
                Err(e) => eprintln!("[WARN] Watch error: {:?}", e),
            }
        }
    });

    Ok(())
}
