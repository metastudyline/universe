use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use anyhow::{Context, Result};

#[derive(Debug, Serialize, Deserialize)]
pub struct FederatedRepositoryEntry {
    pub namespace: String,
    pub repository_url: String,
    pub target_branch: String,
    pub pinned_release_tag: String,
    pub pinned_commit_sha: String,
    pub domain_category: String,
    pub maintainer_team: Vec<String>,
    pub exported_node_prefix: String,
    pub node_count: usize,
    pub status: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HubRegistry {
    pub registry_version: String,
    pub last_updated: String,
    pub domain_repositories: Vec<FederatedRepositoryEntry>,
}

pub struct RegistryLoader;

impl RegistryLoader {
    pub fn load_registry(path: &Path) -> Result<HubRegistry> {
        let content = fs::read_to_string(path)
            .with_context(|| format!("Failed to read registry at {}", path.display()))?;
        let registry: HubRegistry = serde_yaml::from_str(&content)
            .with_context(|| "Failed to parse registry YAML")?;
        Ok(registry)
    }
}
