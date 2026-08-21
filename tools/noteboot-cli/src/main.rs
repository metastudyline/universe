mod db;
mod parser;

use clap::{Parser, Subcommand};
use db::Database;
use parser::parse_markdown_metadata;
use prettytable::{Cell, Row, Table};
use std::fs;
use std::path::{Path, PathBuf};
use std::time::Instant;
use walkdir::WalkDir;

#[derive(Parser)]
#[command(name = "noteboot")]
#[command(about = "NoteBoot: 本地优先 · Git 原生 · 块级双链与 SQL 驱动的个人知识构建操作系统", long_about = None)]
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
    /// 全量扫描工作区 Markdown 并更新嵌入式 SQLite 索引库
    Sync {
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 查询指定笔记或概念的反向链接引用 (Backlinks)
    Backlinks {
        target: String,
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 对个人知识库执行原生 SQL 查询与多维表格分析
    Query {
        sql: String,
        #[arg(default_value = ".")]
        vault_path: String,
    },
    /// 查看当前知识库节点、双链与拓扑统计
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

    let mut scanned_count = 0;
    for entry in WalkDir::new(vault_dir).into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_file() && path.extension().map_or(false, |ext| ext == "md") {
            // 忽略 .noteboot, .git, node_modules 目录
            let path_str = path.to_string_lossy();
            if path_str.contains("/.noteboot/") || path_str.contains("/.git/") || path_str.contains("/node_modules/") {
                continue;
            }

            let rel_path = path.strip_prefix(vault_dir).unwrap_or(path).to_string_lossy().to_string();
            let file_name = path.file_name().unwrap_or_default().to_string_lossy().to_string();

            if let Ok(content) = fs::read_to_string(path) {
                let metadata = entry.metadata()?;
                let mtime = metadata.modified()?.duration_since(std::time::UNIX_EPOCH)?.as_millis() as i64;

                let parsed = parse_markdown_metadata(&content, &file_name);
                let id = format!("{:x}", md5_hash(&rel_path));

                db.upsert_note(&id, &rel_path, &parsed.title, &content, mtime, &parsed.outbound_links)?;
                scanned_count += 1;
            }
        }
    }

    let elapsed = start.elapsed();
    let (notes, edges) = db.get_stats()?;
    println!("  \x1b[1;32m✔\x1b[0m 知识库同步完成！已扫描 \x1b[1m{}\x1b[0m 篇文档 | 索引 \x1b[1;33m{} 节点 / {} 链接边\x1b[0m | 耗时: \x1b[1m{:?}\x1b[0m", scanned_count, notes, edges, elapsed);
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
            println!("  \x1b[1;33m║\x1b[0m       \x1b[36m约定优于配置 · 100% 本地优先 · 块级双链与嵌入式 SQL 驱动\x1b[0m      \x1b[1;33m║\x1b[0m");
            println!("  \x1b[1;33m╚═══════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

            let vault_dir = Path::new(&path);
            let noteboot_dir = vault_dir.join(".noteboot");
            fs::create_dir_all(&noteboot_dir)?;

            let db_path = noteboot_dir.join("noteboot.db");
            let _db = Database::open(&db_path)?;

            // 初始化标准目录骨架
            let _ = fs::create_dir_all(vault_dir.join("00-Daily"));
            let _ = fs::create_dir_all(vault_dir.join("01-Inbox"));
            let _ = fs::create_dir_all(vault_dir.join("02-Concepts"));
            let _ = fs::create_dir_all(vault_dir.join("03-Workshops"));

            let welcome_md = vault_dir.join("Welcome.md");
            if !welcome_md.exists() {
                fs::write(
                    &welcome_md,
                    "# 欢迎来到 NoteBoot 个人知识宇宙\n\n- 欢迎体验以知识拓扑为索引的双链笔记；\n- 关联概念示例: [[02-Concepts/First-Principles.md]]；\n- 细粒度块锚点示例: 第一性原理思考法 ^core-thought\n",
                )?;
            }

            println!("  \x1b[32m✔\x1b[0m 知识库成功初始化于: \x1b[1m{}\x1b[0m", path);
            println!("  \x1b[36m👉 执行同步索引: \x1b[1m./noteboot sync {}\x1b[0m\n", path);
            sync_vault(&path)?;
        }
        Commands::New { path, title, content } => {
            let p = Path::new(&path);
            if let Some(parent) = p.parent() {
                let _ = fs::create_dir_all(parent);
            }

            let t = title.unwrap_or_else(|| p.file_stem().unwrap_or_default().to_string_lossy().to_string());
            let c = content.unwrap_or_else(|| format!("# {}\n\n- 创建于 NoteBoot 知识构建系统\n", t));

            fs::write(p, &c)?;
            println!("  \x1b[32m✔\x1b[0m 新建笔记: \x1b[1m{}\x1b[0m", path);

            if let Some(parent_str) = p.parent().and_then(|p| p.to_str()) {
                let vault_root = if parent_str.is_empty() { "." } else { "." };
                let _ = sync_vault(vault_root);
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
                    println!("  \x1b[1;36m{:2}.\x1b[0m \x1b[1m{}\x1b[0m (\x1b[33m{}\x1b[0m) ── 引用类型: [{}{}]", idx + 1, b.source_title, b.source_path, b.kind, anchor_str);
                }
                println!();
            }
        }
        Commands::Query { sql, vault_path } => {
            let db_path = get_db_path(&vault_path);
            let db = Database::open(&db_path)?;

            println!("\n  \x1b[1;33m✦ [NOTEBOOT SQL ENGINE]\x1b[0m 执行查询: \x1b[36m{}\x1b[0m", sql);
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
            let (notes, edges) = db.get_stats()?;

            println!("\n  ╔═══════════════════════════════════════════════════════════════════════╗");
            println!("  ║           ✦  N O T E B O O K   V A U L T   S T A T S  ✦             ║");
            println!("  ╠═══════════════════════════════════════════════════════════════════════╣");
            println!("  ║  知识库路径: {:52}║", vault_path);
            println!("  ║  笔记总节点: {:52}║", format!("{} 篇 Markdown 文档", notes));
            println!("  ║  双向链接边: {:52}║", format!("{} 条 WikiLink / 块级锚点", edges));
            println!("  ║  存储引擎  : {:52}║", "SQLite 3 (WAL + FTS5 + JSON1)");
            println!("  ╚═══════════════════════════════════════════════════════════════════════╝\n");
        }
    }

    Ok(())
}
