// ✦ NoteBoot Virtual Vault Mount & TTZip Universal Archive Integrator
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use walkdir::WalkDir;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MountEntry {
    pub id: String,
    pub namespace: String,       // e.g. "@studyline/rust"
    pub source_path: String,     // e.g. "/path/to/domains/rust" or "/path/to/universe.tar.zst"
    #[serde(default = "default_readonly")]
    pub mode: String,            // "readonly" | "readwrite"
    #[serde(default = "default_includes")]
    pub include: Vec<String>,
    #[serde(default)]
    pub exclude: Vec<String>,
    #[serde(default)]
    pub is_archive: bool,        // 是否为通过 TTZip 支持的归档文件 (tar.zst, 7z, zip 等)
    #[serde(default)]
    pub description: Option<String>,
}

fn default_readonly() -> String {
    "readonly".to_string()
}

fn default_includes() -> Vec<String> {
    vec!["**/*.md".to_string()]
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MountsConfig {
    pub version: String,
    pub mounts: Vec<MountEntry>,
}

impl Default for MountsConfig {
    fn default() -> Self {
        Self {
            version: "1.0.0".to_string(),
            mounts: Vec::new(),
        }
    }
}

pub struct VirtualVaultScanner;

#[derive(Debug, Clone)]
pub struct ScannedDocument {
    pub vault: String,           // "@local" or "@studyline/rust"
    pub canonical_path: String,  // e.g. "@studyline/rust/stage0/R03.md" or "01-Inbox/idea.md"
    pub physical_path: PathBuf,
    pub is_readonly: bool,
    pub is_archive_entry: bool,  // 是否从 TTZip 归档中动态流式提取
    pub archive_file: Option<PathBuf>,
    pub entry_name: Option<String>,
}

impl VirtualVaultScanner {
    pub fn load_mounts(vault_dir: &str) -> MountsConfig {
        let mounts_file = Path::new(vault_dir).join(".noteboot").join("mounts.json");
        if let Ok(content) = fs::read_to_string(&mounts_file) {
            if let Ok(config) = serde_json::from_str::<MountsConfig>(&content) {
                return config;
            }
        }
        MountsConfig::default()
    }

    pub fn save_mounts(vault_dir: &str, config: &MountsConfig) -> Result<(), Box<dyn std::error::Error>> {
        let noteboot_dir = Path::new(vault_dir).join(".noteboot");
        fs::create_dir_all(&noteboot_dir)?;
        let mounts_file = noteboot_dir.join("mounts.json");
        let content = serde_json::to_string_pretty(config)?;
        fs::write(mounts_file, content)?;
        Ok(())
    }

    pub fn add_mount(
        vault_dir: &str,
        source_path: &str,
        namespace: &str,
        description: Option<String>,
    ) -> Result<MountEntry, Box<dyn std::error::Error>> {
        let p = Path::new(source_path);
        let abs_source = if p.exists() {
            fs::canonicalize(p)?
        } else {
            return Err(format!("挂载源路径不存在: {}", source_path).into());
        };

        let is_archive = abs_source.is_file();

        let mut config = Self::load_mounts(vault_dir);
        let ns = if namespace.starts_with('@') {
            namespace.to_string()
        } else {
            format!("@{}", namespace)
        };

        if config.mounts.iter().any(|m| m.namespace == ns) {
            return Err(format!("命名空间 {} 已存在", ns).into());
        }

        let id = ns.trim_start_matches('@').replace('/', "-");
        let entry = MountEntry {
            id,
            namespace: ns,
            source_path: abs_source.to_string_lossy().to_string(),
            mode: "readonly".to_string(),
            include: default_includes(),
            exclude: vec![".git/**".to_string(), "target/**".to_string(), ".noteboot/**".to_string()],
            is_archive,
            description,
        };

        config.mounts.push(entry.clone());
        Self::save_mounts(vault_dir, &config)?;
        Ok(entry)
    }

    pub fn remove_mount(vault_dir: &str, namespace: &str) -> Result<bool, Box<dyn std::error::Error>> {
        let mut config = Self::load_mounts(vault_dir);
        let before_len = config.mounts.len();
        config.mounts.retain(|m| m.namespace != namespace && m.id != namespace);
        if config.mounts.len() < before_len {
            Self::save_mounts(vault_dir, &config)?;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    pub fn read_document_content(doc: &ScannedDocument) -> Result<String, Box<dyn std::error::Error>> {
        if doc.is_archive_entry {
            if let (Some(ref arc), Some(ref entry)) = (&doc.archive_file, &doc.entry_name) {
                // 调用 ttzip-cli cat 零落盘流式输出
                let output = Command::new("ttzip-cli")
                    .arg("cat")
                    .arg(arc)
                    .arg(entry)
                    .output()
                    .or_else(|_| {
                        // 尝试从工作区根目录调用 ./ttzip-cli
                        Command::new("./ttzip-cli")
                            .arg("cat")
                            .arg(arc)
                            .arg(entry)
                            .output()
                    })?;

                if output.status.success() {
                    return Ok(String::from_utf8_lossy(&output.stdout).to_string());
                } else {
                    return Err(format!("ttzip-cli cat 解压失败: {}", String::from_utf8_lossy(&output.stderr)).into());
                }
            }
        }
        Ok(fs::read_to_string(&doc.physical_path)?)
    }

    pub fn scan_all(vault_dir: &str) -> Vec<ScannedDocument> {
        let mut docs = Vec::new();

        // 1. 扫描 @local 本地工作区
        for entry in WalkDir::new(vault_dir).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.is_file() && path.extension().map_or(false, |ext| ext == "md") {
                let path_str = path.to_string_lossy();
                if path_str.contains("/.noteboot/") || path_str.contains("/.git/") || path_str.contains("/node_modules/") || path_str.contains("/target/") {
                    continue;
                }
                let rel = path.strip_prefix(vault_dir).unwrap_or(path).to_string_lossy().to_string();
                docs.push(ScannedDocument {
                    vault: "@local".to_string(),
                    canonical_path: rel,
                    physical_path: path.to_path_buf(),
                    is_readonly: false,
                    is_archive_entry: false,
                    archive_file: None,
                    entry_name: None,
                });
            }
        }

        // 2. 扫描挂载的只读知识宇宙
        let config = Self::load_mounts(vault_dir);
        for m in config.mounts {
            let mount_path = Path::new(&m.source_path);
            if !mount_path.exists() {
                continue;
            }

            if m.is_archive {
                // TTZip 全格式归档包挂载：通过 `ttzip-cli list --json` 极速获取结构化文件清单
                let cmd_output = Command::new("ttzip-cli")
                    .arg("list")
                    .arg("--json")
                    .arg(&m.source_path)
                    .output()
                    .or_else(|_| {
                        Command::new("./ttzip-cli")
                            .arg("list")
                            .arg("--json")
                            .arg(&m.source_path)
                            .output()
                    });

                if let Ok(output) = cmd_output {
                    if output.status.success() {
                        let stdout_str = String::from_utf8_lossy(&output.stdout);
                        for line in stdout_str.lines() {
                            let trimmed = line.trim();
                            if trimmed.is_empty() { continue; }
                            if let Ok(val) = serde_json::from_str::<serde_json::Value>(trimmed) {
                                let entries_opt = val.get("archive_metadata")
                                    .and_then(|m| m.get("entries"))
                                    .or_else(|| val.get("entries"))
                                    .and_then(|e| e.as_array());

                                if let Some(entries) = entries_opt {
                                    for (idx, item) in entries.iter().enumerate() {
                                        if let Some(entry_path) = item.get("path").and_then(|p| p.as_str()) {
                                            if entry_path.ends_with(".md") {
                                                let canonical = format!("{}/entry_{}_{}", m.namespace, idx, entry_path);
                                                docs.push(ScannedDocument {
                                                    vault: m.namespace.clone(),
                                                    canonical_path: canonical,
                                                    physical_path: mount_path.to_path_buf(),
                                                    is_readonly: true,
                                                    is_archive_entry: true,
                                                    archive_file: Some(mount_path.to_path_buf()),
                                                    entry_name: Some(entry_path.to_string()),
                                                });
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                // 物理目录扫描
                for entry in WalkDir::new(mount_path).into_iter().filter_map(|e| e.ok()) {
                    let path = entry.path();
                    if path.is_file() && path.extension().map_or(false, |ext| ext == "md") {
                        let path_str = path.to_string_lossy();
                        if path_str.contains("/.noteboot/") || path_str.contains("/.git/") || path_str.contains("/target/") {
                            continue;
                        }
                        let rel = path.strip_prefix(mount_path).unwrap_or(path).to_string_lossy().to_string();
                        let canonical = format!("{}/{}", m.namespace, rel);
                        docs.push(ScannedDocument {
                            vault: m.namespace.clone(),
                            canonical_path: canonical,
                            physical_path: path.to_path_buf(),
                            is_readonly: true,
                            is_archive_entry: false,
                            archive_file: None,
                            entry_name: None,
                        });
                    }
                }
            }
        }

        docs
    }
}
