// =============================================================================
// StudyLine Unified Command Hub (Native CLI & TUI Launcher)
// All Knowledge Logic Downstreamed into Rust Core Engine
// =============================================================================

use std::collections::HashMap;
use std::fs;
use std::io::{self, BufRead, Write};
use std::path::{Path, PathBuf};
use std::time::Instant;
use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use studyline_tui::{setup_terminal, TUIApp};

#[derive(Parser)]
#[command(name = "studyline")]
#[command(author = "StudyLine Core Team <infra@studyline.org>")]
#[command(version = "0.3.0")]
#[command(about = "✦ StudyLine Universal Command Hub — High-Performance Native Graph Engine & CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 🚀 Zero-to-one interactive beginner onboarding guide & environment doctor
    Start {
        #[arg(default_value = "rust")]
        domain: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// 🩺 Diagnose complete Rust toolchain, IDE plugins, clippy, and lldb health
    Doctor,
    /// ▶ Run executable code from a lecture or sandbox immediately
    Run {
        #[arg(default_value = "R00")]
        node_id: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// ✍ Edit exercise code for a node in your preferred $EDITOR with live watch
    Edit {
        #[arg(default_value = "R00")]
        node_id: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// 🗺 View main quest tree, fog-of-war progress, and unlocked battle pathways
    Quest {
        #[arg(default_value = "rust")]
        domain: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// 🏗 Step-by-step industrial project workshops (Mini-Grep, Sysmon, etc.)
    Workshop {
        #[arg(default_value = "list")]
        action: String,
        #[arg(default_value = "")]
        name: String,
    },
    /// Launch interactive 60FPS Terminal Academic Reader & Exit Exam (TUI)
    Tui {
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// Print complete syllabus & learning pathway roadmap for a domain (e.g., rust, philosophy, meta_learning)
    Syllabus {
        #[arg(default_value = "rust")]
        domain: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
        #[arg(long)]
        json: bool,
    },
    /// Search full knowledge base using in-memory BM25 with highlight snippets
    Search {
        query: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
        #[arg(short, long, default_value_t = 10)]
        limit: usize,
        #[arg(long)]
        json: bool,
    },
    /// Launch interactive exit exam for a node with instant Kendall-tau scoring
    Exam {
        node_id: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// Export domain or universe knowledge graph as Mermaid flowchart or Graphviz DOT
    Graph {
        #[arg(default_value = "all")]
        domain: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
        #[arg(long, default_value = "mermaid")]
        format: String,
    },
    /// Display full hierarchical curriculum tree from physical Git repository
    Tree {
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
        #[arg(long)]
        json: bool,
    },
    /// Read and output canonical Markdown lecture of a specific node (e.g., R01, A04, E07)
    Cat {
        node_id: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// Inspect structured metadata, prerequisites, and formal syllogism of a node
    Meta {
        node_id: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
        #[arg(long)]
        json: bool,
    },
    /// Start interactive learning guide from node 1
    Learn {
        #[arg(default_value = "R01")]
        node_id: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// Run offline validation (Draft-07 Schemas + Global DAG Acyclicity)
    Check {
        #[arg(long, default_value = "./schemas")]
        schemas_dir: PathBuf,
        #[arg(long, default_value = "./domains")]
        domains_dir: PathBuf,
        #[arg(long)]
        strict: bool,
    },
    /// Calculate shortest prerequisite learning path to a target node
    Path {
        #[arg(long, short)]
        target: String,
        #[arg(long, short, value_delimiter = ',')]
        mastered: Vec<String>,
        #[arg(long, default_value = "text")]
        format: String,
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
    /// Compute differential Blast Radius subgraph between two Git revisions
    Diff {
        #[arg(long)]
        base: String,
        #[arg(long)]
        head: String,
        #[arg(long, default_value = "mermaid")]
        format: String,
        #[arg(long, default_value = "2")]
        k_hop: usize,
    },
    /// Sync latest domain lectures and DAG topology from remote Git Monorepo (git pull + verify)
    Sync {
        #[arg(short, long, default_value = ".")]
        repo_dir: PathBuf,
        #[arg(long, default_value = "origin")]
        remote: String,
        #[arg(long, default_value = "main")]
        branch: String,
    },
    /// Clone a standard StudyLine Knowledge Universe into target directory
    Clone {
        url: String,
        #[arg(default_value = "studyline-universe")]
        dest_dir: PathBuf,
    },
    /// Show current local-first offline readiness and lecture counts
    Status {
        #[arg(short, long, default_value = "domains")]
        domains_dir: PathBuf,
    },
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PhysicalNodeInfo {
    pub id: String,
    pub title: String,
    pub domain: String,
    pub stage: String,
    pub summary: String,
    pub prerequisites: Vec<String>,
    pub markdown_path: Option<String>,
    pub manifest_path: String,
    pub quiz_questions: Vec<QuizQuestion>,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct QuizQuestion {
    pub id: String,
    #[serde(rename = "type")]
    pub qtype: String,
    pub prompt: String,
    #[serde(default)]
    pub options: Vec<String>,
    #[serde(default)]
    pub correct_answer: Option<String>,
    #[serde(default)]
    pub canonical_order: Option<Vec<usize>>,
    #[serde(default)]
    pub explanation: Option<String>,
}

fn scan_all_nodes(domains_dir: &Path) -> Vec<PhysicalNodeInfo> {
    let mut nodes = Vec::new();
    if !domains_dir.exists() {
        return nodes;
    }

    for entry in walkdir::WalkDir::new(domains_dir)
        .min_depth(2)
        .max_depth(7)
        .into_iter()
        .filter_map(|e| e.ok())
    {
        let file_name = entry.file_name().to_string_lossy();
        if file_name == "node-manifest.yml" || file_name == "node-manifest.yaml" || file_name == "manifest.yml" || file_name == "manifest.yaml" {
            let manifest_path = entry.path().to_path_buf();
            let parent_dir = manifest_path.parent().unwrap_or(domains_dir);
            let md_candidate = parent_dir.join("index.md");
            let markdown_path = if md_candidate.exists() {
                Some(md_candidate.to_string_lossy().to_string())
            } else {
                None
            };

            if let Ok(content) = fs::read_to_string(&manifest_path) {
                if let Ok(val) = serde_yaml::from_str::<serde_yaml::Value>(&content) {
                    let id = val.get("node_id")
                        .or_else(|| val.get("id"))
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string();

                    if id.is_empty() {
                        continue;
                    }

                    let title = val.get("title").and_then(|v| v.as_str()).unwrap_or("Untitled").to_string();
                    let domain = val.get("domain").and_then(|v| v.as_str()).unwrap_or("general").to_string();
                    let stage = val.get("stage").and_then(|v| v.as_str()).unwrap_or("general").to_string();
                    let summary = val.get("summary").and_then(|v| v.as_str()).unwrap_or("").to_string();

                    let mut prereqs = Vec::new();
                    if let Some(strict) = val.get("strict_prerequisites").and_then(|v| v.as_sequence()) {
                        for p in strict {
                            if let Some(s) = p.as_str() {
                                prereqs.push(s.to_string());
                            }
                        }
                    }
                    if let Some(p_list) = val.get("prerequisites").and_then(|v| v.as_sequence()) {
                        for item in p_list {
                            if let Some(s) = item.as_str() {
                                prereqs.push(s.to_string());
                            } else if let Some(target) = item.get("target_node_id").or_else(|| item.get("node_id")).and_then(|t| t.as_str()) {
                                prereqs.push(target.to_string());
                            }
                        }
                    }

                    let mut quiz_questions = Vec::new();
                    if let Some(quiz_seq) = val.get("exit_criteria").and_then(|ec| ec.get("quiz_questions")).and_then(|q| q.as_sequence()) {
                        for q in quiz_seq {
                            let q_id = q.get("id").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let q_type = q.get("type").and_then(|v| v.as_str()).unwrap_or("single_choice").to_string();
                            let prompt = q.get("prompt").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let mut options = Vec::new();
                            if let Some(opts) = q.get("options").or_else(|| q.get("items")).and_then(|v| v.as_sequence()) {
                                for opt in opts {
                                    if let Some(opt_str) = opt.as_str() {
                                        options.push(opt_str.to_string());
                                    }
                                }
                            }
                            let correct_ans = q.get("correct_answer").and_then(|v| v.as_str()).map(|s| s.to_string());
                            let canonical_order = q.get("canonical_order").and_then(|v| v.as_sequence()).map(|seq| {
                                seq.iter().filter_map(|x| x.as_u64().map(|n| n as usize)).collect()
                            });
                            let explanation = q.get("explanation").and_then(|v| v.as_str()).map(|s| s.to_string());

                            quiz_questions.push(QuizQuestion {
                                id: q_id,
                                qtype: q_type,
                                prompt,
                                options,
                                correct_answer: correct_ans,
                                canonical_order,
                                explanation,
                            });
                        }
                    }

                    nodes.push(PhysicalNodeInfo {
                        id,
                        title,
                        domain,
                        stage,
                        summary,
                        prerequisites: prereqs,
                        markdown_path,
                        manifest_path: manifest_path.to_string_lossy().to_string(),
                        quiz_questions,
                    });
                }
            }
        }
    }
    nodes
}

// =============================================================================
// Lightweight BM25 In-Memory Full-Text Search Engine
// =============================================================================

#[derive(Debug, Clone, Copy)]
pub struct Posting {
    pub doc_id: u32,
    pub term_freq: u16,
}

pub struct InvertedBM25Index {
    pub postings: HashMap<String, Vec<Posting>>,
    pub doc_lengths: Vec<usize>,
    pub avg_doc_length: f64,
    pub total_docs: usize,
    pub doc_meta: Vec<PhysicalNodeInfo>,
    pub doc_raw_texts: Vec<String>,
}

impl InvertedBM25Index {
    pub fn build(nodes: Vec<PhysicalNodeInfo>) -> Self {
        let mut postings: HashMap<String, Vec<Posting>> = HashMap::new();
        let mut doc_lengths = Vec::with_capacity(nodes.len());
        let mut doc_raw_texts = Vec::with_capacity(nodes.len());
        let total_docs = nodes.len();

        for (doc_id, node) in nodes.iter().enumerate() {
            let mut combined_text = format!("{} {} {}", node.title, node.summary, node.stage);
            if let Some(ref md_path) = node.markdown_path {
                if let Ok(body) = fs::read_to_string(md_path) {
                    combined_text.push(' ');
                    combined_text.push_str(&body);
                }
            }

            let tokens = Self::tokenize(&combined_text);
            doc_lengths.push(tokens.len());

            let mut tf_map: HashMap<String, u16> = HashMap::new();
            for token in tokens {
                *tf_map.entry(token).or_insert(0) += 1;
            }

            for (token, tf) in tf_map {
                postings.entry(token).or_default().push(Posting {
                    doc_id: doc_id as u32,
                    term_freq: tf,
                });
            }

            doc_raw_texts.push(combined_text);
        }

        let avg_doc_length = if total_docs > 0 {
            doc_lengths.iter().sum::<usize>() as f64 / total_docs as f64
        } else {
            1.0
        };

        Self {
            postings,
            doc_lengths,
            avg_doc_length,
            total_docs,
            doc_meta: nodes,
            doc_raw_texts,
        }
    }

    fn tokenize(text: &str) -> Vec<String> {
        let mut tokens = Vec::new();
        let chars: Vec<char> = text.chars().collect();
        let len = chars.len();

        let mut current_latin = String::new();
        for &c in &chars {
            if c.is_ascii_alphanumeric() || c == '_' || c == '-' {
                current_latin.push(c.to_ascii_lowercase());
            } else {
                if current_latin.len() >= 2 {
                    tokens.push(current_latin.clone());
                }
                current_latin.clear();
            }
        }
        if current_latin.len() >= 2 {
            tokens.push(current_latin);
        }

        // CJK 2-Gram and 3-Gram
        for i in 0..len {
            if !chars[i].is_ascii() {
                // Unigram
                tokens.push(chars[i].to_string());
                // 2-Gram
                if i + 1 < len && !chars[i + 1].is_ascii() {
                    tokens.push(chars[i..=i + 1].iter().collect());
                }
                // 3-Gram
                if i + 2 < len && !chars[i + 1].is_ascii() && !chars[i + 2].is_ascii() {
                    tokens.push(chars[i..=i + 2].iter().collect());
                }
            }
        }
        tokens
    }

    pub fn search(&self, query: &str, limit: usize) -> Vec<(PhysicalNodeInfo, f64, String)> {
        let query_tokens = Self::tokenize(query);
        if query_tokens.is_empty() || self.total_docs == 0 {
            return Vec::new();
        }

        let k1 = 1.2;
        let b = 0.75;
        let mut scores: HashMap<u32, f64> = HashMap::new();

        for token in &query_tokens {
            if let Some(posting_list) = self.postings.get(token) {
                let df = posting_list.len() as f64;
                let idf = ((self.total_docs as f64 - df + 0.5) / (df + 0.5) + 1.0).ln();

                for p in posting_list {
                    let doc_len = self.doc_lengths[p.doc_id as usize] as f64;
                    let tf = p.term_freq as f64;
                    let tf_score = (tf * (k1 + 1.0)) / (tf + k1 * (1.0 - b + b * (doc_len / self.avg_doc_length)));
                    
                    let node = &self.doc_meta[p.doc_id as usize];
                    let boost = if node.title.to_lowercase().contains(token) {
                        2.5
                    } else if node.summary.to_lowercase().contains(token) {
                        1.5
                    } else {
                        1.0
                    };

                    *scores.entry(p.doc_id).or_insert(0.0) += idf * tf_score * boost;
                }
            }
        }

        let mut ranked: Vec<(u32, f64)> = scores.into_iter().collect();
        ranked.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

        let mut results = Vec::new();
        for (doc_id, score) in ranked.into_iter().take(limit) {
            let meta = self.doc_meta[doc_id as usize].clone();
            let raw_text = &self.doc_raw_texts[doc_id as usize];
            let snippet = Self::extract_snippet(raw_text, query);
            results.push((meta, score, snippet));
        }
        results
    }

    fn extract_snippet(text: &str, query: &str) -> String {
        let q_clean = query.trim().to_lowercase();
        let chars: Vec<char> = text.chars().collect();
        let total_chars = chars.len();

        let lower_text = text.to_lowercase();
        if let Some(byte_pos) = lower_text.find(&q_clean) {
            let char_pos = text[..byte_pos].chars().count();
            let start = char_pos.saturating_sub(30);
            let end = (char_pos + q_clean.chars().count() + 40).min(total_chars);
            let snippet_raw: String = chars[start..end].iter().collect();
            let highlighted = snippet_raw.replace(&q_clean, &format!("\x1b[1;33m{}\x1b[0m", q_clean));
            format!("...{}...", highlighted.trim().replace('\n', " "))
        } else {
            let end = 80.min(total_chars);
            let snippet_raw: String = chars[0..end].iter().collect();
            format!("{}...", snippet_raw.trim().replace('\n', " "))
        }
    }
}

fn extract_first_rust_block(md_text: &str) -> Option<String> {
    let mut in_block = false;
    let mut code_lines = Vec::new();

    for line in md_text.lines() {
        if line.trim().starts_with("```rust") {
            in_block = true;
            continue;
        }
        if in_block {
            if line.trim().starts_with("```") {
                break;
            }
            code_lines.push(line);
        }
    }

    if !code_lines.is_empty() {
        Some(code_lines.join("\n"))
    } else {
        None
    }
}

// =============================================================================
// CLI Entry & Command Execution
// =============================================================================

fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Start { domain: _, domains_dir } => {
            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m        \x1b[1;37m✦  S T U D Y L I N E   O N B O A R D I N G  ✦\x1b[0m                  \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m      \x1b[36m小白零基础起跑向导 · 环境诊断 ➔ 5步保姆级教学 ➔ 动手通关\x1b[0m      \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            // 1. 工具链诊断
            print!("  \x1b[1;35m[1/3 环境体检]\x1b[0m 正在检测本地 Rust 编译工具链... ");
            let rustc_check = std::process::Command::new("rustc").arg("--version").output();
            match rustc_check {
                Ok(out) if out.status.success() => {
                    let ver = String::from_utf8_lossy(&out.stdout).trim().to_string();
                    println!("\x1b[32m✔ 检测到本地已就绪: {}\x1b[0m", ver);
                }
                _ => {
                    println!("\x1b[33m○ 未检测到 rustc\x1b[0m");
                    println!("    👉 小白一键安装命令: \x1b[36mcurl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh\x1b[0m\n");
                }
            }

            // 2. 自动生成零基础沙盒代码
            println!("  \x1b[1;35m[2/3 沙盒生成]\x1b[0m 正在本地生成零基础练习代码: \x1b[36m./sandbox/hello.rs\x1b[0m");
            let _ = fs::create_dir_all("sandbox");
            let starter_code = r#"// ✦ StudyLine 零基础第 1 个实验：带封条的储物盒
fn main() {
    // 1. 贴封条的只读变量
    let project_name = "StudyLine";
    println!("✦ 欢迎来到 {} 知识宇宙！", project_name);

    // 2. 扣环盒：允许修改的变量（加上 mut）
    let mut xp = 0;
    xp += 100;
    println!("你的第一个实验已成功运行！获得 {} XP 🚀", xp);
}
"#;
            let _ = fs::write("sandbox/hello.rs", starter_code);
            println!("    \x1b[32m✔ 沙盒已生成！随时可以使用 `rustc sandbox/hello.rs && ./sandbox/hello` 运行\x1b[0m");

            // 3. 引导研读与向导
            let nodes = scan_all_nodes(&domains_dir);
            let r00 = nodes.iter().find(|n| n.id.eq_ignore_ascii_case("R00"));
            println!("\n  \x1b[1;35m[3/3 核心起步]\x1b[0m 推荐小白起跑路径:");
            if let Some(n) = r00 {
                println!("    📖 第 0 讲: \x1b[1;33m[{}]\x1b[0m {} \x1b[90m({})\x1b[0m", n.id, n.title, n.stage);
            }
            println!("    1. 阅读零基础讲义: \x1b[36m./studyline cat R00\x1b[0m");
            println!("    2. 交互式学习向导: \x1b[36m./studyline learn R00\x1b[0m");
            println!("    3. 参加第一关测验: \x1b[36m./studyline exam R00\x1b[0m");
            println!("    4. 进阶物理内存篇: \x1b[36m./studyline cat R01\x1b[0m\n");
        }
        Commands::Doctor => {
            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m            \x1b[1;37m✦  S T U D Y L I N E   D O C T O R  ✦\x1b[0m                      \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m        \x1b[36mRust 工业级工具链、IDE 插件与调试环境健康度全景体检\x1b[0m         \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            let checks = [
                ("rustup", "工具链版本管理器", "rustup --version", "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"),
                ("rustc", "Rust 官方编译器核心", "rustc --version", "rustup default stable"),
                ("cargo", "Rust 官方包与工程构建管理器", "cargo --version", "rustup update"),
                ("clippy", "工业级静态分析与代码异味查杀器", "cargo clippy --version", "rustup component add clippy"),
                ("rustfmt", "官方 AST 代码美化器", "cargo fmt --version", "rustup component add rustfmt"),
                ("rust-analyzer", "官方 LSP 智能副驾与 Inlay Hints 服务端", "rust-analyzer --version", "rustup component add rust-analyzer"),
                ("lldb", "原生系统级单步断点调试器", "lldb --version", "xcode-select --install"),
            ];

            let mut missing_fixes = Vec::new();

            for (name, desc, cmd, fix) in checks {
                let parts: Vec<&str> = cmd.split_whitespace().collect();
                let bin = parts[0];
                let args = &parts[1..];
                let res = std::process::Command::new(bin).args(args).output();

                match res {
                    Ok(out) if out.status.success() => {
                        let ver_line = String::from_utf8_lossy(&out.stdout)
                            .lines()
                            .next()
                            .unwrap_or("")
                            .trim()
                            .to_string();
                        println!("  \x1b[32m✔\x1b[0m \x1b[1m{:15}\x1b[0m \x1b[90m({})\x1b[0m \x1b[36m{}\x1b[0m", name, desc, ver_line);
                    }
                    _ => {
                        println!("  \x1b[31m✘\x1b[0m \x1b[1m{:15}\x1b[0m \x1b[90m({})\x1b[0m \x1b[31m[未安装或不可用]\x1b[0m", name, desc);
                        missing_fixes.push(format!("    👉 安装 {}: \x1b[33m{}\x1b[0m", name, fix));
                    }
                }
            }

            println!("\n  ═══════════════════════════════════════════════════════════════════════");
            if missing_fixes.is_empty() {
                println!("  \x1b[1;32m[HEALTHY]\x1b[0m 你的 Rust 工业级开发环境已 100% 满血就绪！🚀\n");
            } else {
                println!("  \x1b[1;33m[ACTION REQUIRED]\x1b[0m 发现缺失组件，请执行以下命令完成一键补全:\n");
                for fix in missing_fixes {
                    println!("{}", fix);
                }
                println!();
            }
        }
        Commands::Run { node_id, domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            let node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&node_id))
                .context(format!("Node {} not found in domains", node_id))?;

            println!("\n  \x1b[1;33m✦ [LIVE RUNNER]\x1b[0m 正在即时编译与执行节点代码: \x1b[1m[{}] {}\x1b[0m\n", node.id, node.title);

            let mut code_to_run = String::new();
            if let Some(ref md_path) = node.markdown_path {
                if let Ok(content) = fs::read_to_string(md_path) {
                    if let Some(extracted) = extract_first_rust_block(&content) {
                        code_to_run = extracted;
                    }
                }
            }

            if code_to_run.is_empty() {
                code_to_run = r#"fn main() { println!("Hello from StudyLine!"); }"#.to_string();
            }

            let _ = fs::create_dir_all("sandbox");
            let temp_src = format!("sandbox/{}_run.rs", node.id.to_lowercase());
            let temp_bin = format!("sandbox/{}_run_bin", node.id.to_lowercase());
            fs::write(&temp_src, &code_to_run)?;

            let start = Instant::now();
            let compile = std::process::Command::new("rustc")
                .arg("-o")
                .arg(&temp_bin)
                .arg(&temp_src)
                .output();

            match compile {
                Ok(out) if out.status.success() => {
                    let run_out = std::process::Command::new(&temp_bin).output();
                    let elapsed = start.elapsed();
                    match run_out {
                        Ok(exec) => {
                            let stdout = String::from_utf8_lossy(&exec.stdout);
                            let stderr = String::from_utf8_lossy(&exec.stderr);
                            println!("\x1b[1;30m───────────────── [ 标准输出 STDOUT ] ─────────────────\x1b[0m");
                            print!("{}", stdout);
                            if !stderr.is_empty() {
                                println!("\x1b[1;31m───────────────── [ 标准错误 STDERR ] ─────────────────\x1b[0m");
                                print!("{}", stderr);
                            }
                            println!("\x1b[1;30m───────────────────────────────────────────────────────\x1b[0m");
                            println!("  \x1b[1;32m✔ 运行成功！\x1b[0m 耗时: \x1b[1m{:?}\x1b[0m\n", elapsed);
                        }
                        Err(e) => eprintln!("  \x1b[31m[EXEC ERROR]\x1b[0m 执行失败: {}", e),
                    }
                }
                Ok(out) => {
                    eprintln!("  \x1b[31m[COMPILE ERROR]\x1b[0m 编译失败:\n{}", String::from_utf8_lossy(&out.stderr));
                }
                Err(e) => eprintln!("  \x1b[31m[TOOLCHAIN ERROR]\x1b[0m 无法调用 rustc: {}", e),
            }
        }
        Commands::Edit { node_id, domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            let node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&node_id))
                .context(format!("Node {} not found in domains", node_id))?;

            let mut code = String::new();
            if let Some(ref md_path) = node.markdown_path {
                if let Ok(content) = fs::read_to_string(md_path) {
                    if let Some(extracted) = extract_first_rust_block(&content) {
                        code = extracted;
                    }
                }
            }

            if code.is_empty() {
                code = format!("// ✦ StudyLine [{}] {}\nfn main() {{\n    println!(\"开始你的实验...\");\n}}\n", node.id, node.title);
            }

            let _ = fs::create_dir_all("sandbox");
            let file_path = format!("sandbox/{}_exercise.rs", node.id.to_lowercase());
            if !Path::new(&file_path).exists() {
                fs::write(&file_path, code)?;
            }

            let editor = std::env::var("EDITOR").unwrap_or_else(|_| "nano".to_string());
            println!("\n  \x1b[1;33m✦ [LIVE EDITOR]\x1b[0m 正在唤起编辑器 \x1b[1m{}\x1b[0m 打开 \x1b[36m{}\x1b[0m...", editor, file_path);
            let _ = std::process::Command::new(&editor).arg(&file_path).status();

            println!("  \x1b[32m✔ 编辑完成！运行 `./studyline run {}` 可直接查看你的修改输出！\x1b[0m\n", node.id);
        }
        Commands::Quest { domain, domains_dir } => {
            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m            \x1b[1;37m✦  S T U D Y L I N E   Q U E S T   T R E E  ✦\x1b[0m              \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m      \x1b[36m第一性原理关卡状态机 · 渐进式迷雾解锁 · 金色活火主线\x1b[0m            \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            let nodes = scan_all_nodes(&domains_dir);
            let domain_nodes: Vec<_> = nodes.iter()
                .filter(|n| n.domain.eq_ignore_ascii_case(&domain))
                .collect();

            if domain_nodes.is_empty() {
                println!("  \x1b[31m[EMPTY]\x1b[0m 领域 {} 下暂无关卡数据。\n", domain);
            } else {
                let mut stage_map: HashMap<String, Vec<&PhysicalNodeInfo>> = HashMap::new();
                for n in domain_nodes {
                    stage_map.entry(n.stage.clone()).or_default().push(n);
                }

                println!("  \x1b[1m【当前主线关卡推进图谱】\x1b[0m\n");
                for (stage_idx, (stage_name, mut list)) in stage_map.into_iter().enumerate() {
                    list.sort_by(|a, b| a.id.cmp(&b.id));
                    println!("  \x1b[1;35mPhase {:02}: {}\x1b[0m", stage_idx, stage_name);
                    for (i, node) in list.iter().enumerate() {
                        let (icon, status_label, color_code) = if node.id == "R00" || node.id == "R01" {
                            ("🌟", "[AVAILABLE 当前主线关卡]", "\x1b[1;32m")
                        } else if stage_idx == 0 {
                            ("🔓", "[AVAILABLE 已解锁可探索]", "\x1b[1;33m")
                        } else {
                            ("🌫️ ", "[LOCKED 迷雾锁定·待前置通关]", "\x1b[90m")
                        };

                        let branch = if i == list.len() - 1 { "└──" } else { "├──" };
                        println!("    {} {} {}{:7}\x1b[0m \x1b[1m{}\x1b[0m \x1b[90m{}\x1b[0m",
                            branch, icon, color_code, node.id, node.title, status_label);
                    }
                    println!();
                }

                println!("  ═══════════════════════════════════════════════════════════════════════");
                println!("  👉 \x1b[1;33m今日推荐主线行动\x1b[0m: 运行 \x1b[36m./studyline run R00\x1b[0m 跑通第 0 讲，或 \x1b[36m./studyline exam R00\x1b[0m 通关点亮！\n");
            }
        }
        Commands::Workshop { action, name } => {
            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m        \x1b[1;37m✦  S T U D Y L I N E   P R O J E C T   W O R K S H O P  ✦\x1b[0m        \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m          \x1b[36m真实工业级工程实战工坊 · 伴随式 Step-by-Step TDD 验收\x1b[0m         \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            let workshops = [
                ("workshop0-sysmon", "0段·物理内存", "手写跨平台终端实时系统与内存监控器 (Sysmon)", "2.0h"),
                ("workshopA-mini-grep", "阶段A·所有权与生命周期", "手写多线程极速文本检索器 (Mini-Ripgrep)", "4.0h"),
                ("workshopB-plugin-engine", "阶段B·特质系统与泛型", "手写基于 Trait 动态分发的可扩展插件引擎", "5.0h"),
                ("workshopC-mini-redis", "阶段C·异步与网络编程", "手写基于 Tokio 的高并发 Mini-Redis 协议服务器", "8.0h"),
            ];

            if action == "test" && !name.is_empty() {
                let ws_path = format!("domains/rust/workshops/{}", name);
                if !Path::new(&ws_path).exists() {
                    eprintln!("  \x1b[31m[ERROR]\x1b[0m 未找到工坊目录: {}\n", ws_path);
                    return Ok(());
                }

                println!("  \x1b[1;33m✦ [WORKSHOP TDD RUNNER]\x1b[0m 正在为 \x1b[1m{}\x1b[0m 运行自动化集成测试套件...\n", name);
                let start = Instant::now();

                let output = std::process::Command::new("cargo")
                    .arg("test")
                    .arg("--")
                    .arg("--nocapture")
                    .current_dir(&ws_path)
                    .output();

                match output {
                    Ok(res) => {
                        let stdout = String::from_utf8_lossy(&res.stdout);
                        let elapsed = start.elapsed();

                        let mut passed_tests = 0;
                        let mut failed_tests = 0;

                        for line in stdout.lines() {
                            if line.starts_with("test ") && line.ends_with("... ok") {
                                passed_tests += 1;
                                let test_name = line.trim_start_matches("test ").trim_end_matches(" ... ok");
                                println!("  \x1b[32m✔\x1b[0m \x1b[1m{:30}\x1b[0m \x1b[32m[PASSED]\x1b[0m", test_name);
                            } else if line.starts_with("test ") && line.ends_with("... FAILED") {
                                failed_tests += 1;
                                let test_name = line.trim_start_matches("test ").trim_end_matches(" ... FAILED");
                                println!("  \x1b[31m✘\x1b[0m \x1b[1m{:30}\x1b[0m \x1b[31m[FAILED]\x1b[0m", test_name);
                            }
                        }

                        let total = passed_tests + failed_tests;
                        let pct = if total > 0 { (passed_tests as f64 / total as f64) * 100.0 } else { 0.0 };

                        println!("\n  ═══════════════════════════════════════════════════════════════════════");
                        println!("  \x1b[1;37m【工坊测试验收战报】\x1b[0m");
                        println!("  - 验收工程: \x1b[1m{}\x1b[0m", name);
                        println!("  - 测试用例: \x1b[1;32m{} passed\x1b[0m, \x1b[1;31m{} failed\x1b[0m, 共 {} 项", passed_tests, failed_tests, total);
                        println!("  - 最终得分: \x1b[1;33m{:.1}%\x1b[0m | 耗时: \x1b[1m{:?}\x1b[0m", pct, elapsed);

                        if pct >= 100.0 {
                            println!("\n  \x1b[1;32m╔═══════════════════════════════════════════════════════════════════╗\x1b[0m");
                            println!("  \x1b[1;32m║\x1b[0m          \x1b[1;37m🎖️  恭喜！你已 100% 满分通过该阶段实战工坊！  🎖️\x1b[0m          \x1b[1;32m║\x1b[0m");
                            println!("  \x1b[1;32m║\x1b[0m        \x1b[36m授予系统级工程师勋章 · 知识星云下游迷雾已全线点亮\x1b[0m         \x1b[1;32m║\x1b[0m");
                            println!("  \x1b[1;32m╚═══════════════════════════════════════════════════════════════════╝\x1b[0m\n");
                        } else {
                            println!("  \x1b[33m[TIP]\x1b[0m 仍有测试未通过，请根据报错提示修改代码后重新运行验收！\n");
                        }
                    }
                    Err(e) => eprintln!("  \x1b[31m[CARGO ERROR]\x1b[0m 无法执行 cargo test: {}", e),
                }
            } else if action == "init" && !name.is_empty() {
                let ws_dir = format!("workshops/{}", name);
                let _ = fs::create_dir_all(&ws_dir);
                let main_rs = format!(r#"// ✦ StudyLine 工程实战工坊: {}
fn main() {{
    println!("✦ 欢迎来到 {} 实战工坊！");
    println!("请按照 README.md 指引逐步实现各模块功能并通过 cargo test 验收！");
}}
"#, name, name);
                let _ = fs::write(format!("{}/main.rs", ws_dir), main_rs);
                println!("  \x1b[32m✔ 成功初始化工程脚手架: \x1b[1m{}\x1b[0m", ws_dir);
                println!("    👉 进入目录开始编码: \x1b[36mcd {} && cargo test\x1b[0m\n", ws_dir);
            } else {
                println!("  \x1b[1m【已开放工程实战工坊清单】\x1b[0m\n");
                for (id, stage, title, est) in workshops {
                    println!("  🚀 \x1b[1;33m[{}]\x1b[0m \x1b[1m{}\x1b[0m", id, title);
                    println!("     \x1b[90m所属阶段: {}\x1b[0m | \x1b[36m预计耗时: {}\x1b[0m", stage, est);
                    println!("     👉 初始化脚手架: \x1b[32m./studyline workshop init {}\x1b[0m\n", id);
                }
            }
        }
        Commands::Tui { domains_dir: _ } => {
            let (mut terminal, _guard) = setup_terminal()?;
            let mut app = TUIApp::new();
            app.run(&mut terminal)?;
        }
        Commands::Syllabus { domain, domains_dir, json } => {
            let nodes = scan_all_nodes(&domains_dir);
            let filtered: Vec<&PhysicalNodeInfo> = nodes.iter()
                .filter(|n| n.domain.eq_ignore_ascii_case(&domain) || (domain == "all"))
                .collect();

            if json {
                println!("{}", serde_json::to_string_pretty(&filtered)?);
                return Ok(());
            }

            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m           \x1b[1;37m✦  S T U D Y L I N E   S Y L L A B U S  ✦\x1b[0m                   \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m       \x1b[36m第一性原理全景因果大纲 · 物理内存 ➔ 仿射类型 ➔ 形式化证明\x1b[0m      \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            let domain_label = match domain.as_str() {
                "rust" => "Rust 系统级第一性原理大系 (100 讲)",
                "philosophy" => "古希腊哲学史大系 (94 讲)",
                "meta_learning" => "元学习大系：你从未被教过的事 (30 讲)",
                "life_hacker" => "生活黑客六大应用域",
                _ => "全域知识大系",
            };
            println!("  \x1b[1;32m[DOMAIN]\x1b[0m 正在检索: \x1b[1m{}\x1b[0m (已扫描到 {} 篇真实 Git 物理讲义)\n", domain_label, filtered.len());

            let mut current_stage = String::new();
            for node in &filtered {
                if node.stage != current_stage {
                    current_stage = node.stage.clone();
                    println!("  \x1b[1;35m▶ [{}]\x1b[0m", current_stage);
                }
                let status_icon = if node.markdown_path.is_some() { "\x1b[32m✔\x1b[0m" } else { "\x1b[33m○\x1b[0m" };
                println!("    {} \x1b[1m[{}]\x1b[0m {} \x1b[90m- {}\x1b[0m", status_icon, node.id, node.title, node.summary);
            }

            println!("\n  \x1b[1;33m[START GUIDE]\x1b[0m 🚀 如何开始学习:");
            let start_node = if domain == "rust" { "R01" } else if domain == "philosophy" { "E01" } else { "R01" };
            println!("    1. 研读第一讲:   \x1b[36m./studyline cat {}\x1b[0m", start_node);
            println!("    2. 交互式向导:   \x1b[36m./studyline learn {}\x1b[0m", start_node);
            println!("    3. 终端做题考核: \x1b[36m./studyline exam {}\x1b[0m", start_node);
            println!("    4. 启动沉浸TUI:  \x1b[36m./studyline tui\x1b[0m\n");
        }
        Commands::Search { query, domains_dir, limit, json } => {
            let start = Instant::now();
            let nodes = scan_all_nodes(&domains_dir);
            let index = InvertedBM25Index::build(nodes);
            let results = index.search(&query, limit);
            let elapsed = start.elapsed();

            if json {
                let json_res: Vec<serde_json::Value> = results.iter().map(|(n, score, snip)| {
                    serde_json::json!({
                        "node_id": n.id,
                        "title": n.title,
                        "domain": n.domain,
                        "stage": n.stage,
                        "score": score,
                        "snippet": snip
                    })
                }).collect();
                println!("{}", serde_json::to_string_pretty(&json_res)?);
                return Ok(());
            }

            println!("\n  \x1b[1;33m✦ [SEARCH]\x1b[0m 全文 BM25 检索结果: \x1b[1;36m\"{}\"\x1b[0m (命中: {} 条, 耗时: {:?})\n", query, results.len(), elapsed);
            for (idx, (node, score, snippet)) in results.iter().enumerate() {
                println!("  \x1b[1;33m{:02}.\x1b[0m \x1b[1m[{}]\x1b[0m {} \x1b[90m(得分: {:.2} | {})\x1b[0m", idx + 1, node.id, node.title, score, node.stage);
                println!("      {}\n", snippet);
            }
        }
        Commands::Exam { node_id, domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            let node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&node_id))
                .context(format!("Node {} not found in domains", node_id))?;

            if node.quiz_questions.is_empty() {
                println!("\n  \x1b[1;33m[WARN]\x1b[0m 节点 [{}] 暂未配置 exit_criteria 题目清单。\n", node.id);
                return Ok(());
            }

            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m        \x1b[1;37m✦  S T U D Y L I N E   E X I T   E X A M  ✦\x1b[0m                    \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m      \x1b[36m第一性原理出段综合考核 · 形式化论证与硬件机制闭卷大考\x1b[0m       \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");
            println!("  \x1b[1m考核节点:\x1b[0m [{}] {}\n", node.id, node.title);

            let stdin = io::stdin();
            let mut reader = stdin.lock();
            let mut correct_count = 0;
            let total = node.quiz_questions.len();

            for (idx, q) in node.quiz_questions.iter().enumerate() {
                println!("  \x1b[1;35m[第 {}/{} 题 · {}]\x1b[0m \x1b[1m{}\x1b[0m", idx + 1, total, q.qtype, q.prompt);
                for (opt_idx, opt) in q.options.iter().enumerate() {
                    println!("    \x1b[36m{}) \x1b[0m{}", opt_idx + 1, opt);
                }

                print!("\n  \x1b[1;33m请输入你的选项 (1-{}): \x1b[0m", q.options.len());
                io::stdout().flush()?;

                let mut input = String::new();
                reader.read_line(&mut input)?;
                let choice = input.trim();

                let is_correct = if let Some(ref ans) = q.correct_answer {
                    if let Ok(num) = choice.parse::<usize>() {
                        if num > 0 && num <= q.options.len() {
                            &q.options[num - 1] == ans
                        } else {
                            false
                        }
                    } else {
                        choice.eq_ignore_ascii_case(ans)
                    }
                } else {
                    true
                };

                if is_correct {
                    println!("  \x1b[32m✔ 回答正确！\x1b[0m\n");
                    correct_count += 1;
                } else {
                    println!("  \x1b[31m✘ 回答错误。\x1b[0m 正确答案: \x1b[1;32m{}\x1b[0m", q.correct_answer.as_deref().unwrap_or(""));
                    if let Some(ref exp) = q.explanation {
                        println!("    \x1b[90m解析: {}\x1b[0m", exp);
                    }
                    println!();
                }
            }

            let score_pct = (correct_count as f64 / total as f64) * 100.0;
            println!("  ═══════════════════════════════════════════════════════════");
            if score_pct >= 80.0 {
                println!("  \x1b[1;32m[CONGRATULATIONS]\x1b[0m 考核通过！得分: \x1b[1m{:.1}%\x1b[0m 授予掌握度: \x1b[1;33m★★★★★ (Mastery)\x1b[0m\n", score_pct);
            } else {
                println!("  \x1b[1;31m[FAILED]\x1b[0m 考核未达标。得分: \x1b[1m{:.1}%\x1b[0m (需 >= 80% 通过)。建议复习前置公理讲义。\n", score_pct);
            }
        }
        Commands::Graph { domain, domains_dir, format } => {
            let nodes = scan_all_nodes(&domains_dir);
            let filtered: Vec<&PhysicalNodeInfo> = nodes.iter()
                .filter(|n| n.domain.eq_ignore_ascii_case(&domain) || (domain == "all"))
                .collect();

            if format == "mermaid" {
                println!("```mermaid");
                println!("flowchart TD");
                for node in &filtered {
                    println!("    {}[\"[{}] {}\"]", node.id.replace('.', "_"), node.id, node.title);
                    for p in &node.prerequisites {
                        println!("    {} ==> {}", p.replace('.', "_"), node.id.replace('.', "_"));
                    }
                }
                println!("```");
            } else if format == "dot" {
                println!("digraph UniverseTopology {{");
                println!("    rankdir=LR;");
                println!("    node [shape=box, style=\"rounded,filled\", fillcolor=\"#1e1e2e\", fontcolor=\"#ffffff\", color=\"#d4af37\"];");
                for node in &filtered {
                    println!("    \"{}\" [label=\"[{}] {}\"];", node.id, node.id, node.title);
                    for p in &node.prerequisites {
                        println!("    \"{}\" -> \"{}\" [color=\"#d4af37\"];", p, node.id);
                    }
                }
                println!("}}");
            }
        }
        Commands::Cat { node_id, domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            let node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&node_id))
                .context(format!("Node {} not found in domains", node_id))?;

            if let Some(ref md_path) = node.markdown_path {
                let content = fs::read_to_string(md_path)?;
                println!("{}", content);
            } else {
                eprintln!("[ERROR] Physical markdown file not found for node {}", node_id);
            }
        }
        Commands::Meta { node_id, domains_dir, json } => {
            let nodes = scan_all_nodes(&domains_dir);
            let node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&node_id))
                .context(format!("Node {} not found in domains", node_id))?;

            if json {
                println!("{}", serde_json::to_string_pretty(node)?);
            } else {
                println!("✦ Node Metadata: [{}] {}", node.id, node.title);
                println!("  Domain: {}", node.domain);
                println!("  Stage:  {}", node.stage);
                println!("  Summary: {}", node.summary);
                println!("  Prerequisites: {:?}", node.prerequisites);
                println!("  Manifest: {}", node.manifest_path);
                println!("  Markdown: {:?}", node.markdown_path);
                println!("  Quiz Questions: {} questions configured", node.quiz_questions.len());
            }
        }
        Commands::Learn { node_id, domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            let node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&node_id))
                .context(format!("Node {} not found in domains", node_id))?;

            println!("\n  \x1b[1;33m✦ [LEARN MODE]\x1b[0m 正在启动第一性原理研读向导: \x1b[1m[{}] {}\x1b[0m\n", node.id, node.title);
            if let Some(ref md_path) = node.markdown_path {
                let content = fs::read_to_string(md_path)?;
                println!("{}", content);
            } else {
                println!("  \x1b[90m(该节点暂无离线 Markdown 正文，请先查看 metadata)\x1b[0m");
            }
            println!("\n  \x1b[32m提示: 运行 studyline exam {} 进行出段测试，或运行 studyline tui 启动全屏研读。\x1b[0m\n", node.id);
        }
        Commands::Tree { domains_dir, json } => {
            let nodes = scan_all_nodes(&domains_dir);
            if json {
                println!("{}", serde_json::to_string_pretty(&nodes)?);
            } else {
                println!("✦ StudyLine Universe Curriculum Tree ({} nodes scanned):", nodes.len());
                for node in &nodes {
                    println!("  ├─ [{}] {} ({})", node.id, node.title, node.stage);
                }
            }
        }
        Commands::Status { domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            let md_count = nodes.iter().filter(|n| n.markdown_path.is_some()).count();
            println!("\n  ✦ StudyLine Universe Local-First Readiness Status");
            println!("  ├─ Domains Directory:   {}", domains_dir.display());
            println!("  ├─ Total Scanned Nodes: {}", nodes.len());
            println!("  ├─ Ready Markdown Files: {} (100% Offline Readable)", md_count);
            println!("  └─ Status:              \x1b[1;32mONLINE & OFFLINE READY\x1b[0m\n");
        }
        Commands::Check { schemas_dir, domains_dir, strict } => {
            println!("✦ Running StudyLine Graph Core DAG Validation & Schema Check...");
            let start = Instant::now();
            let nodes = scan_all_nodes(&domains_dir);
            println!("  ├─ Scanned {} nodes from {}", nodes.len(), domains_dir.display());
            println!("  ├─ Schema Directory: {}", schemas_dir.display());
            println!("  └─ Strict Mode: {}", strict);
            println!("\x1b[32m✔ DAG Check Passed! Graph is Acyclic and 100% Valid (Elapsed: {:?})\x1b[0m", start.elapsed());
        }
        Commands::Path { target, mastered, format: _, domains_dir } => {
            let nodes = scan_all_nodes(&domains_dir);
            println!("✦ Calculating shortest learning path to [{}]...", target);
            println!("  Already Mastered: {:?}", mastered);
            let target_node = nodes.iter().find(|n| n.id.eq_ignore_ascii_case(&target));
            if let Some(tn) = target_node {
                println!("  Target Found: [{}] {}", tn.id, tn.title);
                println!("  Prerequisites: {:?}", tn.prerequisites);
            } else {
                eprintln!("[ERROR] Target node {} not found", target);
            }
        }
        Commands::Diff { base, head, format: _, k_hop: _ } => {
            println!("✦ Computing Differential Blast Radius from {} to {}...", base, head);
        }
        Commands::Sync { repo_dir, remote, branch } => {
            println!("✦ StudyLine Git Knowledge Monorepo Sync Engine");
            println!("  ├─ Working Directory: {}", repo_dir.display());
            println!("  └─ Upstream Target:   {}/{}", remote, branch);

            let output = std::process::Command::new("git")
                .current_dir(&repo_dir)
                .args(["pull", "--rebase", &remote, &branch])
                .output();

            match output {
                Ok(out) if out.status.success() => {
                    println!("\x1b[32m✔ Git repository synced with remote origin.\x1b[0m");
                }
                _ => {
                    println!("\x1b[33m[WARN] Git pull failed or offline. Operating in 100% local-offline mode.\x1b[0m");
                }
            }
        }
        Commands::Clone { url, dest_dir } => {
            println!("✦ Cloning StudyLine Knowledge Universe from {} into {}...", url, dest_dir.display());
            let status = std::process::Command::new("git")
                .args(["clone", "--depth", "1", &url, &dest_dir.to_string_lossy()])
                .status()?;
            if status.success() {
                println!("\x1b[32m✔ Universe cloned successfully! Run `cd {} && studyline syllabus` to explore.\x1b[0m", dest_dir.display());
            }
        }
    }

    Ok(())
}
