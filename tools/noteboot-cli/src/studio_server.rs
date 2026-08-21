// ✦ NoteBoot Studio Embedded Server & RPC Bridge
#![allow(clippy::too_many_arguments, dead_code)]

use axum::{
    extract::{Query, State},
    response::{Html, Json},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::Mutex;
use tower_http::cors::{Any, CorsLayer};

use crate::db::Database;
use crate::mount::VirtualVaultScanner;

#[derive(Clone)]
pub struct AppState {
    pub vault_dir: PathBuf,
    pub db: Arc<Mutex<Database>>,
}

#[derive(Deserialize)]
pub struct NoteQuery {
    pub vault: Option<String>,
    pub path: String,
}

#[derive(Deserialize)]
pub struct SearchQuery {
    pub q: String,
}

#[derive(Deserialize)]
pub struct BacklinkQuery {
    pub path: String,
}

#[derive(Deserialize)]
pub struct BentoQuery {
    pub filter: Option<String>,
}

#[derive(Deserialize)]
pub struct SaveNoteRequest {
    pub vault: String,
    pub path: String,
    pub content: String,
}

#[derive(Serialize)]
pub struct ApiResponse<T> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

pub async fn start_studio_server(vault_dir: PathBuf, port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let db_path = vault_dir.join(".noteboot").join("noteboot.db");
    let db = Database::open(&db_path)?;

    let state = AppState {
        vault_dir: vault_dir.clone(),
        db: Arc::new(Mutex::new(db)),
    };

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/", get(index_handler))
        .route("/api/tree", get(tree_handler))
        .route("/api/note", get(read_note_handler).post(save_note_handler))
        .route("/api/search", get(search_handler))
        .route("/api/backlinks", get(backlinks_handler))
        .route("/api/bento", get(bento_handler))
        .route("/api/mounts", get(mounts_handler))
        .layer(cors)
        .with_state(state);

    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    println!("  ✦ [NOTEBOOT STUDIO] 现代化知识工作台已启动: http://localhost:{}", port);
    println!("  ✦ 正在连接本地知识库: {}\n", vault_dir.display());

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}

async fn index_handler() -> Html<&'static str> {
    Html(STUDIO_HTML)
}

async fn tree_handler(State(state): State<AppState>) -> Json<ApiResponse<Vec<ScannedDocumentDto>>> {
    let docs = VirtualVaultScanner::scan_all(state.vault_dir.to_str().unwrap_or("."));
    let dtos: Vec<ScannedDocumentDto> = docs
        .into_iter()
        .map(|d| ScannedDocumentDto {
            vault: d.vault,
            canonical_path: d.canonical_path,
            is_readonly: d.is_readonly,
            is_archive: d.is_archive_entry,
        })
        .collect();
    Json(ApiResponse {
        success: true,
        data: Some(dtos),
        error: None,
    })
}

#[derive(Serialize)]
pub struct ScannedDocumentDto {
    pub vault: String,
    pub canonical_path: String,
    pub is_readonly: bool,
    pub is_archive: bool,
}

async fn read_note_handler(
    State(state): State<AppState>,
    Query(query): Query<NoteQuery>,
) -> Json<ApiResponse<String>> {
    let docs = VirtualVaultScanner::scan_all(state.vault_dir.to_str().unwrap_or("."));
    let target_doc = docs.into_iter().find(|d| {
        if let Some(ref v) = query.vault {
            d.vault == *v && (d.canonical_path == query.path || d.canonical_path.ends_with(&query.path))
        } else {
            d.canonical_path == query.path || d.canonical_path.ends_with(&query.path)
        }
    });

    if let Some(doc) = target_doc {
        match VirtualVaultScanner::read_document_content(&doc) {
            Ok(content) => Json(ApiResponse {
                success: true,
                data: Some(content),
                error: None,
            }),
            Err(e) => Json(ApiResponse {
                success: false,
                data: None,
                error: Some(e.to_string()),
            }),
        }
    } else {
        Json(ApiResponse {
            success: false,
            data: None,
            error: Some("未找到指定笔记".to_string()),
        })
    }
}

async fn save_note_handler(
    State(state): State<AppState>,
    Json(req): Json<SaveNoteRequest>,
) -> Json<ApiResponse<bool>> {
    if req.vault != "@local" {
        return Json(ApiResponse {
            success: false,
            data: None,
            error: Some("只读挂载知识库禁止写入".to_string()),
        });
    }

    let target_path = state.vault_dir.join(&req.path);
    if let Some(parent) = target_path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }

    if let Err(e) = std::fs::write(&target_path, &req.content) {
        return Json(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        });
    }

    Json(ApiResponse {
        success: true,
        data: Some(true),
        error: None,
    })
}

async fn search_handler(
    State(state): State<AppState>,
    Query(query): Query<SearchQuery>,
) -> Json<ApiResponse<Vec<SearchNodeDto>>> {
    let docs = VirtualVaultScanner::scan_all(state.vault_dir.to_str().unwrap_or("."));
    let q_lower = query.q.to_lowercase();

    let matched: Vec<SearchNodeDto> = docs
        .into_iter()
        .filter(|d| {
            d.canonical_path.to_lowercase().contains(&q_lower)
                || d.vault.to_lowercase().contains(&q_lower)
        })
        .take(15)
        .map(|d| SearchNodeDto {
            uri: d.canonical_path.clone(),
            vault: d.vault,
            title: Path::new(&d.canonical_path)
                .file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string(),
        })
        .collect();

    Json(ApiResponse {
        success: true,
        data: Some(matched),
        error: None,
    })
}

#[derive(Serialize)]
pub struct SearchNodeDto {
    pub uri: String,
    pub vault: String,
    pub title: String,
}

async fn backlinks_handler(
    State(state): State<AppState>,
    Query(query): Query<BacklinkQuery>,
) -> Json<ApiResponse<Vec<crate::db::BacklinkItem>>> {
    let db = state.db.lock().await;
    match db.get_backlinks(&query.path) {
        Ok(items) => Json(ApiResponse {
            success: true,
            data: Some(items),
            error: None,
        }),
        Err(e) => Json(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}

async fn bento_handler(
    State(state): State<AppState>,
    Query(_query): Query<BentoQuery>,
) -> Json<ApiResponse<Vec<serde_json::Value>>> {
    let db = state.db.lock().await;
    match db.execute_raw_query("SELECT vault, path, title, status, priority FROM v_tasks") {
        Ok((headers, rows)) => {
            let mut list = Vec::new();
            for r in rows {
                let mut map = serde_json::Map::new();
                for (h, v) in headers.iter().zip(r.iter()) {
                    map.insert(h.clone(), serde_json::Value::String(v.clone()));
                }
                list.push(serde_json::Value::Object(map));
            }
            Json(ApiResponse {
                success: true,
                data: Some(list),
                error: None,
            })
        }
        Err(e) => Json(ApiResponse {
            success: false,
            data: None,
            error: Some(e.to_string()),
        }),
    }
}

async fn mounts_handler(State(state): State<AppState>) -> Json<ApiResponse<Vec<crate::mount::MountEntry>>> {
    let config = VirtualVaultScanner::load_mounts(state.vault_dir.to_str().unwrap_or("."));
    Json(ApiResponse {
        success: true,
        data: Some(config.mounts),
        error: None,
    })
}

// ✦ NoteBoot Studio Modern Liquid Glass Single-Page Application (HTML/JS/Tailwind)
const STUDIO_HTML: &str = r#"<!DOCTYPE html>
<html lang="zh-CN" class="dark">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>NoteBoot Studio — 知识构建操作系统</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          colors: {
            brand: { gold: '#e5a93b', dark: '#0d1117', surface: 'rgba(22, 27, 34, 0.75)' }
          }
        }
      }
    }
  </script>
  <style>
    body { background-color: #0b0f17; color: #e6edf3; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    .glass-panel { background: rgba(18, 24, 38, 0.7); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); border: 1px solid rgba(255, 255, 255, 0.08); }
    .glass-card { background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.06); }
    .glass-card:hover { background: rgba(255, 255, 255, 0.06); border-color: rgba(229, 169, 59, 0.3); }
    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.15); border-radius: 3px; }
  </style>
</head>
<body class="h-screen w-screen flex flex-col overflow-hidden select-none">
  <!-- 顶栏导航 -->
  <header class="h-12 border-b border-white/10 glass-panel flex items-center justify-between px-4 z-20">
    <div class="flex items-center gap-3">
      <span class="w-3 h-3 rounded-full bg-red-500/80 inline-block"></span>
      <span class="w-3 h-3 rounded-full bg-yellow-500/80 inline-block"></span>
      <span class="w-3 h-3 rounded-full bg-green-500/80 inline-block"></span>
      <div class="h-4 w-px bg-white/10 ml-2"></div>
      <span class="text-xs font-bold tracking-wider text-amber-400 font-mono flex items-center gap-1.5">
        ✦ NOTEBOOT STUDIO
      </span>
    </div>

    <!-- 视图切换 Tab -->
    <div class="flex bg-black/40 rounded-lg p-0.5 border border-white/5 text-xs">
      <button id="btn-tab-editor" onclick="switchTab('editor')" class="px-3 py-1 rounded-md bg-amber-500/20 text-amber-300 font-medium">双链编辑器</button>
      <button id="btn-tab-bento" onclick="switchTab('bento')" class="px-3 py-1 rounded-md text-neutral-400 hover:text-white">Bento 多维表格</button>
    </div>

    <!-- 状态指示 -->
    <div class="flex items-center gap-3 text-xs text-neutral-400">
      <span id="active-note-label" class="text-neutral-300 font-mono">Ready</span>
      <span class="px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">SQLite WAL</span>
    </div>
  </header>

  <!-- 主体三栏布局 -->
  <div class="flex-1 flex overflow-hidden">
    <!-- 左侧栏: 知识库文件树与挂载宇宙 -->
    <aside class="w-64 border-r border-white/10 glass-panel flex flex-col">
      <div class="p-3 border-b border-white/5 flex items-center justify-between">
        <span class="text-xs font-semibold text-neutral-400 uppercase tracking-wider">知识宇宙</span>
        <button onclick="loadTree()" class="text-xs text-amber-400 hover:underline">刷新</button>
      </div>
      <div id="tree-container" class="flex-1 overflow-y-auto p-2 space-y-1 text-xs">
        <!-- 动态生成 -->
      </div>
    </aside>

    <!-- 中央核心工作区 -->
    <main id="main-workbench" class="flex-1 flex flex-col overflow-hidden bg-black/20 relative">
      <!-- 双链编辑器视图 -->
      <div id="view-editor" class="flex-1 flex flex-col overflow-hidden">
        <div class="p-4 flex-1 flex flex-col">
          <textarea id="note-editor" class="flex-1 w-full bg-transparent text-sm font-mono text-neutral-200 focus:outline-none resize-none p-2 leading-relaxed" placeholder="选择或输入双链笔记..."></textarea>
        </div>
      </div>

      <!-- Bento 多维表格视图 -->
      <div id="view-bento" class="flex-1 overflow-y-auto p-6 hidden">
        <div class="max-w-5xl mx-auto space-y-4">
          <div class="flex items-center justify-between">
            <h2 class="text-base font-bold text-white flex items-center gap-2">
              <span class="text-amber-400">✦</span> Bento Database 多维任务与笔记视图
            </h2>
            <span class="text-xs text-neutral-400">基于 SQLite JSON1 动态视图生成</span>
          </div>
          <div class="glass-panel rounded-xl overflow-hidden">
            <table class="w-full text-left text-xs border-collapse">
              <thead>
                <tr class="border-b border-white/10 bg-white/5 text-neutral-400 font-mono">
                  <th class="p-3">命名空间</th>
                  <th class="p-3">路径</th>
                  <th class="p-3">标题</th>
                  <th class="p-3">状态</th>
                  <th class="p-3">优先级</th>
                </tr>
              </thead>
              <tbody id="bento-tbody" class="divide-y divide-white/5">
                <!-- 动态填充 -->
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </main>

    <!-- 右侧栏: 反向链接 (Backlinks) -->
    <aside class="w-72 border-l border-white/10 glass-panel flex flex-col">
      <div class="p-3 border-b border-white/5">
        <span class="text-xs font-semibold text-neutral-400 uppercase tracking-wider">反向链接 (Backlinks)</span>
      </div>
      <div id="backlinks-container" class="flex-1 overflow-y-auto p-3 space-y-2 text-xs">
        <p class="text-neutral-500 italic">暂无反向引用</p>
      </div>
    </aside>
  </div>

  <script>
    let currentDoc = null;

    async function loadTree() {
      const res = await fetch('/api/tree').then(r => r.json());
      const container = document.getElementById('tree-container');
      container.innerHTML = '';
      if (!res.data) return;

      const grouped = {};
      res.data.forEach(d => {
        if (!grouped[d.vault]) grouped[d.vault] = [];
        grouped[d.vault].push(d);
      });

      for (const [vault, docs] of Object.entries(grouped)) {
        const isLocal = vault === '@local';
        const groupEl = document.createElement('div');
        groupEl.className = 'mb-2';
        groupEl.innerHTML = `
          <div class="text-[11px] font-mono font-bold px-2 py-1 text-neutral-400 flex items-center justify-between">
            <span>${vault}</span>
            <span class="text-[10px] px-1 rounded ${isLocal ? 'bg-blue-500/20 text-blue-300' : 'bg-amber-500/20 text-amber-300'}">${isLocal ? '本地工作区' : '只读宇宙'}</span>
          </div>
        `;
        docs.forEach(doc => {
          const item = document.createElement('div');
          item.className = 'px-2 py-1.5 rounded cursor-pointer truncate glass-card text-neutral-300 hover:text-white flex items-center gap-1.5';
          item.innerHTML = `<span>📄</span> <span class="truncate">${doc.canonical_path}</span>`;
          item.onclick = () => openNote(doc);
          groupEl.appendChild(item);
        });
        container.appendChild(groupEl);
      }
    }

    async function openNote(doc) {
      currentDoc = doc;
      document.getElementById('active-note-label').innerText = `${doc.vault}/${doc.canonical_path}`;
      const res = await fetch(`/api/note?vault=${encodeURIComponent(doc.vault)}&path=${encodeURIComponent(doc.canonical_path)}`).then(r => r.json());
      if (res.success) {
        document.getElementById('note-editor').value = res.data;
        loadBacklinks(doc.canonical_path);
      }
    }

    async function loadBacklinks(path) {
      const res = await fetch(`/api/backlinks?path=${encodeURIComponent(path)}`).then(r => r.json());
      const container = document.getElementById('backlinks-container');
      container.innerHTML = '';
      if (res.data && res.data.length > 0) {
        res.data.forEach(b => {
          const el = document.createElement('div');
          el.className = 'p-2.5 rounded-lg glass-card cursor-pointer';
          el.innerHTML = `
            <div class="font-bold text-amber-400 text-xs">${b.source_title}</div>
            <div class="text-[10px] text-neutral-400 mt-1 font-mono">${b.source_vault}/${b.source_path}</div>
            <div class="text-xs text-neutral-300 mt-1 line-clamp-2">${b.snippet || ''}</div>
          `;
          container.appendChild(el);
        });
      } else {
        container.innerHTML = '<p class="text-neutral-500 italic">暂无反向引用</p>';
      }
    }

    async function loadBento() {
      const res = await fetch('/api/bento').then(r => r.json());
      const tbody = document.getElementById('bento-tbody');
      tbody.innerHTML = '';
      if (res.data) {
        res.data.forEach(r => {
          const tr = document.createElement('tr');
          tr.className = 'hover:bg-white/5 transition font-mono';
          tr.innerHTML = `
            <td class="p-3 text-amber-400">${r.vault || '@local'}</td>
            <td class="p-3 text-neutral-300">${r.path}</td>
            <td class="p-3 font-sans font-medium text-white">${r.title}</td>
            <td class="p-3"><span class="px-1.5 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[10px]">${r.status || 'active'}</span></td>
            <td class="p-3"><span class="px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-400 text-[10px]">${r.priority || 'P1'}</span></td>
          `;
          tbody.appendChild(tr);
        });
      }
    }

    function switchTab(tab) {
      if (tab === 'editor') {
        document.getElementById('view-editor').classList.remove('hidden');
        document.getElementById('view-bento').classList.add('hidden');
        document.getElementById('btn-tab-editor').className = 'px-3 py-1 rounded-md bg-amber-500/20 text-amber-300 font-medium';
        document.getElementById('btn-tab-bento').className = 'px-3 py-1 rounded-md text-neutral-400 hover:text-white';
      } else {
        document.getElementById('view-editor').classList.add('hidden');
        document.getElementById('view-bento').classList.remove('hidden');
        document.getElementById('btn-tab-bento').className = 'px-3 py-1 rounded-md bg-amber-500/20 text-amber-300 font-medium';
        document.getElementById('btn-tab-editor').className = 'px-3 py-1 rounded-md text-neutral-400 hover:text-white';
        loadBento();
      }
    }

    // 初始化加载
    loadTree();
  </script>
</body>
</html>
"#;
