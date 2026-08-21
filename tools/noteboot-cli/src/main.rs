mod db;
mod mount;
mod parser;

use clap::{Parser, Subcommand};
use db::Database;
use mount::VirtualVaultScanner;
use parser::parse_markdown_metadata;
use prettytable::{Cell, Row, Table};
use std::fs;
use std::path::{Path, PathBuf};
use std::time::Instant;

#[derive(Parser)]
#[command(name = "noteboot")]
#[command(about = "NoteBoot: 本地优先 · 虚拟库挂载 · 块级双链与 SQL 驱动的个人知识构建操作系统", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// 初始化新的 NoteBoot 知识库 (Vault)
    Init {
        #[arg(default_value = ".")]
        path: String,
    },
    /// 创建新笔记并自动提取双向链接
    New {
        path: String,
        #[arg(short, long)]
        title: Option<String>,
        #[arg(short, long)]
        content: Option<String>,
    },
    /// 虚拟零拷贝挂载外部知识宇宙 (如 /path/to/studyline-universe)
    Mount {
        path: String,
        #[arg(long = "as")]
        as_namespace: String,
        #[arg(short, long)]
        description: Option<String>,
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 卸载已挂载的知识宇宙
    Unmount {
        namespace: String,
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 列出当前知识库挂载的所有只读知识源
    Mounts {
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 全量扫描本地与挂载知识库并更新嵌入式 SQLite 索引
    Sync {
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 查询指定笔记、概念或块锚点的反向链接引用 (Backlinks)
    Backlinks {
        target: String,
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 对个人知识库执行原生 SQL 查询与多维表格分析 (支持 v_tasks 等视图)
    Query {
        sql: String,
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 查看当前知识库节点、双链、块锚点与命名空间拓扑统计
    Stats {
        #[arg(default_value = ".")]
        vault_path: String,
    },
}

fn get_db_path(vault: &str) -> PathBuf {
    let p = Path::new(vault).join(".noteboot");
    let _ = fs::create_dir_all(&p);
    p.join("noteboot.db")
}

fn sync_vault(vault_dir: &str) -> Result<(), Box<dyn std::error::Error>> {
    let db_path = get_db_path(vault_dir);
    let mut db = Database::open(&db_path)?;
    let start = Instant::now();

    let scanned_docs = VirtualVaultScanner::scan_all(vault_dir);
    let total_scanned = scanned_docs.len();

    for doc in scanned_docs {
        if let Ok(content) = fs::read_to_string(&doc.physical_path) {
            let metadata = doc.physical_path.metadata()?;
            let mtime = metadata.modified()?.duration_since(std::time::UNIX_EPOCH)?.as_millis() as i64;
            let file_name = doc.physical_path.file_name().unwrap_or_default().to_string_lossy().to_string();

            let parsed = parse_markdown_metadata(&content, &file_name);
            let id = format!("{:x}", md5_hash(&doc.canonical_path));

            db.upsert_note(
                &id,
                &doc.vault,
                &doc.canonical_path,
                &doc.physical_path.to_string_lossy(),
                &parsed.title,
                &content,
                mtime,
                doc.is_readonly,
                &parsed.frontmatter_meta,
                &parsed.outbound_links,
                &parsed.block_anchors,
            )?;
        }
    }

    let elapsed = start.elapsed();
    let (notes, edges, blocks, _vaults) = db.get_stats()?;
    println!(
        "  \x1b[1;32m✔\x1b[0m 知识库同步完成！已扫描 \x1b[1m{}\x1b[0m 篇文档 | 索引 \x1b[1;33m{} 节点 / {} 链接边 / {} 块锚点\x1b[0m | 耗时: \x1b[1m{:?}\x1b[0m",
        total_scanned, notes, edges, blocks, elapsed
    );
    Ok(())
}

fn md5_hash(input: &str) -> u128 {
    let mut hash: u128 = 0xcbf29ce484222325;
    for b in input.as_bytes() {
        hash ^= *b as u128;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    hash
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Init { path } => {
            println!("\n  \x1b[1;33m╔═══════════════════════════════════════════════════════════════════════╗\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m             \x1b[1;37m✦  N O T E B O O K   V A U L T   I N I T  ✦\x1b[0m                \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m║\x1b[0m       \x1b[36m约定优于配置 · 100% 本地优先 · 虚拟库挂载与 SQL 驱动\x1b[0m            \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            let vault_dir = Path::new(&path);
            let noteboot_dir = vault_dir.join(".noteboot");
            fs::create_dir_all(&noteboot_dir)?;

            let db_path = noteboot_dir.join("noteboot.db");
            let _db = Database::open(&db_path)?;

            let _ = fs::create_dir_all(vault_dir.join("00-Daily"));
            let _ = fs::create_dir_all(vault_dir.join("01-Inbox"));
            let _ = fs::create_dir_all(vault_dir.join("02-Concepts"));
            let _ = fs::create_dir_all(vault_dir.join("03-Workshops"));

            let welcome_md = vault_dir.join("Welcome.md");
            if !welcome_md.exists() {
                fs::write(
                    &welcome_md,
                    "---\ntitle: 欢迎来到 NoteBoot 个人知识宇宙\nstatus: active\npriority: P0\ntags: [pkm, first-principles]\n---\n\n# 欢迎来到 NoteBoot 个人知识宇宙\n\n- 欢迎体验以知识拓扑为索引的个人双链笔记；\n- 关联概念示例: [[02-Concepts/First-Principles.md]]；\n- 细粒度块锚点示例: 第一性原理思考法 ^core-thought\n",
                )?;
            }

            println!("  \x1b[32m✔\x1b[0m 知识库成功初始化于: \x1b[1m{}\x1b[0m", path);
            sync_vault(&path)?;
        }
        Commands::New { path, title, content } => {
            let p = Path::new(&path);
            if let Some(parent) = p.parent() {
                let _ = fs::create_dir_all(parent);
            }

            let t = title.unwrap_or_else(|| p.file_stem().unwrap_or_default().to_string_lossy().to_string());
            let c = content.unwrap_or_else(|| format!("---\ntitle: {}\nstatus: in_progress\n---\n\n# {}\n\n- 创建于 NoteBoot 知识构建系统\n", t, t));

            fs::write(p, &c)?;
            println!("  \x1b[32m✔\x1b[0m 新建笔记: \x1b[1m{}\x1b[0m", path);
            let _ = sync_vault(".");
        }
        Commands::Mount { path, as_namespace, description, vault_path } => {
            let entry = VirtualVaultScanner::add_mount(&vault_path, &path, &as_namespace, description)?;
            println!("\n  \x1b[1;32m✔\x1b[0m 成功虚拟挂载外部知识宇宙！");
            println!("  命名空间: \x1b[1;36m{}\x1b[0m", entry.namespace);
            println!("  源物理路径: \x1b[90m{}\x1b[0m", entry.source_path);
            println!("  访问模式: \x1b[33m{}\x1b[0m (零文件复制保障)\n", entry.mode);
            sync_vault(&vault_path)?;
        }
        Commands::Unmount { namespace, vault_path } => {
            if VirtualVaultScanner::remove_mount(&vault_path, &namespace)? {
                println!("  \x1b[32m✔\x1b[0m 成功卸载命名空间: \x1b[1m{}\x1b[0m", namespace);
                sync_vault(&vault_path)?;
            } else {
                println!("  \x1b[31m✖\x1b[0m 未找到命名空间: \x1b[1m{}\x1b[0m", namespace);
            }
        }
        Commands::Mounts { vault_path } => {
            let config = VirtualVaultScanner::load_mounts(&vault_path);
            println!("\n  \x1b[1;33m✦ [NOTEBOOT VIRTUAL MOUNTS]\x1b[0m 当前挂载的知识宇宙清单:\n");
            if config.mounts.is_empty() {
                println!("  \x1b[90m暂无任何挂载的外部知识库。使用 `noteboot mount <path> --as @namespace` 进行挂载。\x1b[0m\n");
            } else {
                for (idx, m) in config.mounts.iter().enumerate() {
                    println!("  \x1b[1;36m{:2}.\x1b[0m \x1b[1;37m{}\x1b[0m ── \x1b[90m{}\x1b[0m [{}]", idx + 1, m.namespace, m.source_path, m.mode);
                    if let Some(ref d) = m.description {
                        println!("      \x1b[33m描述:\x1b[0m {}", d);
                    }
                }
                println!();
            }
        }
        Commands::Sync { vault_path } => {
            sync_vault(&vault_path)?;
        }
        Commands::Backlinks { target, vault_path } => {
            let db_path = get_db_path(&vault_path);
            let db = Database::open(&db_path)?;

            println!("\n  \x1b[1;33m✦ [NOTEBOOT BACKLINKS]\x1b[0m 正在检索目标: \x1b[1m{}\x1b[0m 的所有反向引用...", target);
            let results = db.get_backlinks(&target)?;

            if results.is_empty() {
                println!("  \x1b[90m暂无任何反向引用链接。\x1b[0m\n");
            } else {
                println!("  已发现 \x1b[1;32m{}\x1b[0m 条反向链接引用:\n", results.len());
                for (idx, b) in results.iter().enumerate() {
                    let anchor_str = b.anchor.as_ref().map(|a| format!(" #{}", a)).unwrap_or_default();
                    println!(
                        "  \x1b[1;36m{:2}.\x1b[0m [\x1b[35m{}\x1b[0m] \x1b[1m{}\x1b[0m (\x1b[33m{}\x1b[0m) ── 引用类型: [{}{}]",
                        idx + 1, b.source_vault, b.source_title, b.source_path, b.kind, anchor_str
                    );
                    if let Some(ref snip) = b.snippet {
                        println!("      \x1b[90m片段:\x1b[0m \"{}\"", snip);
                    }
                }
                println!();
            }
        }
        Commands::Query { sql, vault_path } => {
            let db_path = get_db_path(&vault_path);
            let db = Database::open(&db_path)?;

            println!("\n  \x1b[1;33m✦ [NOTEBOOT SQL & BENTO ENGINE]\x1b[0m 执行查询: \x1b[36m{}\x1b[0m", sql);
            let start = Instant::now();
            let (cols, rows) = db.execute_raw_query(&sql)?;
            let elapsed = start.elapsed();

            let mut table = Table::new();
            let header_row: Vec<Cell> = cols.iter().map(|c| Cell::new(c).style_spec("bFb")).collect();
            table.add_row(Row::new(header_row));

            for r in &rows {
                let cells: Vec<Cell> = r.iter().map(|v| Cell::new(v)).collect();
                table.add_row(Row::new(cells));
            }

            println!();
            table.printstd();
            println!("\n  \x1b[1;32m✔\x1b[0m 查询返回 \x1b[1m{}\x1b[0m 行记录 · 耗时: \x1b[1m{:?}\x1b[0m\n", rows.len(), elapsed);
        }
        Commands::Stats { vault_path } => {
            let db_path = get_db_path(&vault_path);
            let db = Database::open(&db_path)?;
            let (notes, edges, blocks, vaults) = db.get_stats()?;

            println!("\n  ╔═══════════════════════════════════════════════════════════════════════╗");
            println!("  ║           ✦  N O T E B O O K   V A U L T   S T A T S  ✦             ║");
            println!("  ╠═══════════════════════════════════════════════════════════════════════╣");
            println!("  ║  知识库路径: {:52}║", vault_path);
            println!("  ║  总笔记节点: {:52}║", format!("{} 篇 Markdown 文档", notes));
            println!("  ║  双向链接边: {:52}║", format!("{} 条 WikiLink 边", edges));
            println!("  ║  细粒度锚点: {:52}║", format!("{} 个 ^block-id 锚点", blocks));
            println!("  ╠═══════════════════════════════════════════════════════════════════════╣");
            println!("  ║  命名空间分布:                                                       ║");
            for (v_name, v_count) in vaults {
                println!("  ║    • {:20} : {:31}║", v_name, format!("{} 篇", v_count));
            }
            println!("  ║  存储引擎  : {:52}║", "SQLite 3 (WAL + FTS5 + JSON1 + Virtual Mounts)");
            println!("  ╚═══════════════════════════════════════════════════════════════════════╝\n");
        }
    }

    Ok(())
}
