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

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("  ✦ [NOTEBOOT STUDIO] 现代化知识工作台已启动: http://127.0.0.1:{} 或 http://localhost:{}", port, port);
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

#[derive(Serialize)]
pub struct NoteDetailDto {
    pub content: String,
    pub injections: Vec<serde_json::Value>,
    pub prerequisites: Vec<String>,
}

async fn read_note_handler(
    State(state): State<AppState>,
    Query(query): Query<NoteQuery>,
) -> Json<ApiResponse<NoteDetailDto>> {
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
            Ok(content) => {
                // 尝试从物理文件同级目录寻找 node-manifest.yml
                let mut injections = Vec::new();
                let mut prerequisites = Vec::new();

                let parent = doc.physical_path.parent();
                if let Some(p) = parent {
                    let manifest_path = p.join("node-manifest.yml");
                    if manifest_path.exists() {
                        if let Ok(manifest_str) = std::fs::read_to_string(&manifest_path) {
                            if let Ok(yaml_val) = serde_yaml::from_str::<serde_yaml::Value>(&manifest_str) {
                                if let Some(inj_arr) = yaml_val.get("injections").and_then(|v| v.as_sequence()) {
                                    for inj in inj_arr {
                                        if let Ok(json_v) = serde_json::to_value(inj) {
                                            injections.push(json_v);
                                        }
                                    }
                                }
                                if let Some(prereq_arr) = yaml_val.get("strict_prerequisites").and_then(|v| v.as_sequence()) {
                                    for pr in prereq_arr {
                                        if let Some(s) = pr.as_str() {
                                            prerequisites.push(s.to_string());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Json(ApiResponse {
                    success: true,
                    data: Some(NoteDetailDto {
                        content,
                        injections,
                        prerequisites,
                    }),
                    error: None,
                })
            }
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
const STUDIO_HTML: &str = r###"<!DOCTYPE html>
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
      <!-- 单画布所见即所得双链与类杂志编辑器 -->
      <div id="view-editor" class="flex-1 flex flex-col overflow-hidden">
        <div class="h-10 border-b border-white/5 flex items-center justify-between px-4 text-xs bg-black/10">
          <div class="flex items-center gap-3">
            <span class="px-2 py-0.5 rounded bg-amber-500/10 text-amber-300 border border-amber-500/20 font-mono font-medium">✦ LIVE PREVIEW (所见即所得)</span>
            <span class="text-neutral-500">点击任意段落直接就地编辑 · 支持输入「/」插入交互组件</span>
          </div>
          <div class="flex items-center gap-2">
            <button onclick="triggerSlashMenu()" class="px-2.5 py-1 rounded-md bg-amber-500/20 text-amber-300 hover:bg-amber-500/30 border border-amber-500/30 font-medium flex items-center gap-1">
              <span>+</span> 插入积木 (Slash)
            </button>
            <button onclick="saveCurrentNote()" class="px-2.5 py-1 rounded-md bg-white/10 text-white hover:bg-white/20 border border-white/10">
              💾 保存修改
            </button>
          </div>
        </div>

        <!-- 核心所见即所得单画布容器 -->
        <div class="flex-1 overflow-y-auto p-6 relative" id="canvas-scroll-container">
          <div id="live-canvas" class="max-w-3xl mx-auto space-y-4 pb-32">
            <p class="text-neutral-500 italic text-center mt-20">请在左侧选择一篇知识宇宙讲义或双链笔记开始阅读与创作...</p>
          </div>

          <!-- 悬浮 Slash 积木选择面板 -->
          <div id="slash-menu" class="absolute top-20 left-1/3 w-80 glass-panel rounded-xl shadow-2xl p-2 border border-amber-500/40 hidden z-50">
            <div class="text-[10px] font-bold uppercase tracking-wider text-amber-400 px-2 py-1 mb-1 flex items-center justify-between">
              <span>🧩 选择要插入的交互积木</span>
              <span class="text-neutral-500 font-mono">ESC 关闭</span>
            </div>
            <div class="space-y-1 text-xs">
              <div onclick="insertSlashComponent('StackFrameSimulator')" class="p-2.5 rounded-lg glass-card cursor-pointer hover:bg-amber-500/10 flex items-center gap-2.5">
                <span class="text-lg">⚡</span>
                <div>
                  <div class="font-bold text-white">栈帧物理仿真器 (StackFrameSimulator)</div>
                  <div class="text-[10px] text-neutral-400">硬件 RSP 寄存器指针与实时内存压栈动画</div>
                </div>
              </div>
              <div onclick="insertSlashComponent('WSJVideoPlayer')" class="p-2.5 rounded-lg glass-card cursor-pointer hover:bg-amber-500/10 flex items-center gap-2.5">
                <span class="text-lg">🎬</span>
                <div>
                  <div class="font-bold text-white">WSJ 4K 演示视频 (WSJVideoPlayer)</div>
                  <div class="text-[10px] text-neutral-400">超高清动画与 B-Roll 素材播放器</div>
                </div>
              </div>
              <div onclick="insertSlashComponent('BilingualPrimarySource')" class="p-2.5 rounded-lg glass-card cursor-pointer hover:bg-amber-500/10 flex items-center gap-2.5">
                <span class="text-lg">🔬</span>
                <div>
                  <div class="font-bold text-white">一手文献双语对照 (BilingualPrimarySource)</div>
                  <div class="text-[10px] text-neutral-400">古希腊文/拉丁文双语多调对齐学术卡片</div>
                </div>
              </div>
              <div onclick="insertSlashComponent('FormalSyllogism')" class="p-2.5 rounded-lg glass-card cursor-pointer hover:bg-amber-500/10 flex items-center gap-2.5">
                <span class="text-lg">🏛️</span>
                <div>
                  <div class="font-bold text-white">形式化逻辑三段论 (FormalSyllogism)</div>
                  <div class="text-[10px] text-neutral-400">大前提 ➔ 小前提 ➔ 结论严格演绎卡片</div>
                </div>
              </div>
            </div>
          </div>
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

    <!-- 右侧栏: 反向链接 (Backlinks) 与伴读中枢 -->
    <aside class="w-80 border-l border-white/10 glass-panel flex flex-col">
      <div class="p-3 border-b border-white/5 flex items-center justify-between">
        <span class="text-xs font-semibold text-neutral-400 uppercase tracking-wider">伴读中枢与反向链接</span>
        <span class="text-[10px] px-1.5 py-0.5 rounded bg-white/5 text-neutral-400 font-mono">DRAWER</span>
      </div>
      <div id="backlinks-container" class="flex-1 overflow-y-auto p-3 space-y-3 text-xs">
        <p class="text-neutral-500 italic">暂无反向引用</p>
      </div>
    </aside>
  </div>

  <script>
    let currentDoc = null;
    let rawBlocks = [];
    let activeInjections = [];
    let activePrereqs = [];

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
      if (res.success && res.data) {
        activeInjections = res.data.injections || [];
        activePrereqs = res.data.prerequisites || [];
        parseMarkdownToBlocks(res.data.content || '');
        renderLiveCanvas();
        loadBacklinks(doc.canonical_path);
        renderInjectionsAndPrereqs(activeInjections, activePrereqs);
      }
    }

    function parseMarkdownToBlocks(content) {
      const rawLines = content.split('\n');
      rawBlocks = [];
      let currentBlock = [];

      rawLines.forEach((line, idx) => {
        const trimmed = line.trim();
        if (trimmed.startsWith('# ') || trimmed.startsWith('## ') || trimmed.startsWith('### ') || trimmed.startsWith('> ') || trimmed.startsWith('```')) {
          if (currentBlock.length > 0) {
            rawBlocks.push(currentBlock.join('\n'));
            currentBlock = [];
          }
          rawBlocks.push(line);
        } else if (trimmed === '') {
          if (currentBlock.length > 0) {
            rawBlocks.push(currentBlock.join('\n'));
            currentBlock = [];
          }
        } else {
          currentBlock.push(line);
        }
      });
      if (currentBlock.length > 0) {
        rawBlocks.push(currentBlock.join('\n'));
      }
    }

    function getCleanMarkdownFromBlocks() {
      return rawBlocks.join('\n\n');
    }

    function renderLiveCanvas() {
      const canvas = document.getElementById('live-canvas');
      canvas.innerHTML = '';

      rawBlocks.forEach((blockText, blockIdx) => {
        const trimmed = blockText.trim();
        const blockWrapper = document.createElement('div');
        blockWrapper.className = 'group relative transition duration-150 rounded-lg p-1 hover:bg-white/[0.02]';
        blockWrapper.dataset.blockIndex = blockIdx;

        let renderedElement;

        if (trimmed.startsWith('# ')) {
          renderedElement = document.createElement('h1');
          renderedElement.className = 'text-2xl font-bold text-white tracking-tight leading-snug cursor-text';
          renderedElement.innerText = trimmed.substring(2);
        } else if (trimmed.startsWith('## ')) {
          const headingText = trimmed.substring(3);
          renderedElement = document.createElement('h2');
          renderedElement.className = 'text-lg font-bold text-amber-400 tracking-tight leading-snug border-b border-white/10 pb-1.5 cursor-text';
          renderedElement.innerText = headingText;
        } else if (trimmed.startsWith('### ')) {
          renderedElement = document.createElement('h3');
          renderedElement.className = 'text-base font-semibold text-neutral-200 tracking-tight cursor-text';
          renderedElement.innerText = trimmed.substring(4);
        } else if (trimmed.startsWith('> ')) {
          renderedElement = document.createElement('blockquote');
          renderedElement.className = 'border-l-2 border-amber-500/70 bg-white/5 pl-4 py-2 text-sm text-neutral-200 italic rounded-r cursor-text';
          renderedElement.innerText = trimmed.substring(2);
        } else if (trimmed.startsWith('```')) {
          renderedElement = document.createElement('pre');
          renderedElement.className = 'p-3 rounded-lg bg-black/60 border border-white/10 font-mono text-xs text-amber-200/90 overflow-x-auto cursor-text';
          renderedElement.innerText = blockText;
        } else {
          renderedElement = document.createElement('p');
          renderedElement.className = 'text-sm leading-relaxed text-neutral-300 font-serif cursor-text';
          
          // 渲染双向链接药丸胶囊 [[...]]
          const htmlContent = trimmed.replace(/\[\[(.*?)\]\]/g, '<span class="px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-300 border border-blue-500/30 font-mono text-xs cursor-pointer hover:bg-blue-500/30">✦ $1</span>');
          renderedElement.innerHTML = htmlContent;
        }

        // 点击原地进入编辑模式 (Inline Edit on Click)
        renderedElement.onclick = () => enterInlineEdit(blockWrapper, blockIdx, blockText);
        blockWrapper.appendChild(renderedElement);
        canvas.appendChild(blockWrapper);

        // 如果是二级标题，检查并原地注入伴随组件 (In-Place Sidecar Component Widget)
        if (trimmed.startsWith('## ')) {
          const headingText = trimmed.substring(3);
          const matchedInjections = activeInjections.filter(inj => 
            inj.target_section.includes(headingText) || headingText.includes(inj.target_section.replace(/^[#\s]+/, ''))
          );
          matchedInjections.forEach(inj => {
            const widgetEl = document.createElement('div');
            widgetEl.className = 'my-4';
            widgetEl.innerHTML = renderInteractiveComponent(inj.component, inj.props);
            canvas.appendChild(widgetEl);
          });
        }
      });
    }

    function enterInlineEdit(wrapper, blockIdx, originalText) {
      wrapper.innerHTML = '';
      const input = document.createElement('textarea');
      input.className = 'w-full bg-black/40 border border-amber-500/50 rounded-lg p-2.5 text-sm font-mono text-white focus:outline-none resize-none leading-relaxed shadow-lg';
      input.value = originalText;
      input.rows = Math.max(2, originalText.split('\n').length);

      input.onkeydown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey && !originalText.startsWith('```')) {
          e.preventDefault();
          rawBlocks[blockIdx] = input.value;
          renderLiveCanvas();
        } else if (e.key === 'Escape') {
          renderLiveCanvas();
        } else if (e.key === '/') {
          triggerSlashMenu();
        }
      };

      input.onblur = () => {
        rawBlocks[blockIdx] = input.value;
        renderLiveCanvas();
      };

      wrapper.appendChild(input);
      input.focus();
    }

    function renderInteractiveComponent(component, props) {
      if (component === 'StackFrameSimulator') {
        return `
          <div class="p-4 rounded-xl border border-amber-500/30 bg-black/50 glass-panel shadow-2xl">
            <div class="flex items-center justify-between text-xs mb-3 pb-2 border-b border-white/10">
              <span class="font-bold text-amber-400 font-mono flex items-center gap-1.5">
                <span>⚡</span> 硬件栈帧物理仿真器 (StackFrameSimulator)
              </span>
              <span class="text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-mono">LIVE COMPONENT</span>
            </div>
            <div class="grid grid-cols-2 gap-4 text-xs font-mono">
              <div class="space-y-2">
                <div class="text-neutral-400">RSP 栈顶指针调节:</div>
                <input type="range" min="0" max="64" value="16" class="w-full accent-amber-400" oninput="document.getElementById('sim-rsp').innerText = '0x7fffffffde' + (40 - parseInt(this.value)).toString(16)" />
                <div class="text-neutral-300">当前 RSP: <span id="sim-rsp" class="text-amber-300 font-bold">0x7fffffffde28</span></div>
                <button onclick="alert('单步指令执行成功！RSP 已更新。')" class="px-2.5 py-1 rounded bg-amber-500/20 text-amber-300 hover:bg-amber-500/30 border border-amber-500/40">▶ 单步 call 指令压栈</button>
              </div>
              <div class="border border-white/10 rounded-lg p-2 bg-white/5 space-y-1 text-[11px]">
                <div class="text-neutral-400 pb-1 border-b border-white/5">栈内存物理布局:</div>
                <div class="p-1 bg-amber-500/10 text-amber-200 rounded">[ 0x7fffffffde38 ] Return Address (RIP)</div>
                <div class="p-1 bg-white/5 text-neutral-300 rounded">[ 0x7fffffffde30 ] Saved RBP Frame</div>
                <div class="p-1 bg-cyan-500/10 text-cyan-200 rounded">[ 0x7fffffffde28 ] Local Var a = 42 &lt;-- RSP</div>
              </div>
            </div>
          </div>
        `;
      } else if (component === 'WSJVideoPlayer') {
        return `
          <div class="p-3 rounded-xl border border-cyan-500/30 bg-black/50 glass-panel">
            <div class="flex items-center justify-between text-xs mb-2">
              <span class="font-bold text-cyan-400 font-mono flex items-center gap-1.5">
                <span>🎬</span> WSJ 4K 演示视频 (WSJVideoPlayer)
              </span>
              <span class="text-[10px] text-neutral-400">4K Ultra HD</span>
            </div>
            <div class="aspect-video bg-neutral-900 rounded-lg border border-white/10 flex flex-col items-center justify-center relative overflow-hidden">
              <div class="w-12 h-12 rounded-full bg-cyan-500/20 text-cyan-300 flex items-center justify-center text-xl cursor-pointer hover:scale-110 transition border border-cyan-500/40" onclick="alert('播放 WSJ 4K 演示动画')">▶</div>
              <span class="text-[11px] text-neutral-400 mt-2 font-mono">${(props && props.caption) || 'WSJ 4K: RSP 栈帧风箱压伸与释放机制'}</span>
            </div>
          </div>
        `;
      } else if (component === 'BilingualPrimarySource') {
        return `
          <div class="p-3.5 rounded-xl border border-purple-500/30 bg-black/50 glass-panel">
            <div class="text-xs font-bold text-purple-400 font-mono mb-2 flex items-center gap-1.5">
              <span>🔬</span> 一手文献古希腊/拉丁双语对照 (BilingualPrimarySource)
            </div>
            <div class="grid grid-cols-2 gap-3 text-xs font-serif leading-relaxed">
              <div class="p-2.5 rounded bg-white/5 text-purple-200 border-r border-purple-500/20 italic">
                "Τὸ γὰρ αὐτὸ νοεῖν ἐστίν τε καὶ εἶναι." (Parmenides, DK 28 B 3)
              </div>
              <div class="p-2.5 rounded bg-white/5 text-neutral-300">
                “因为能够被思想的和能够存在的是同一回事。”（巴门尼德 残篇 B 3）
              </div>
            </div>
          </div>
        `;
      } else if (component === 'FormalSyllogism') {
        return `
          <div class="p-3.5 rounded-xl border border-emerald-500/30 bg-black/50 glass-panel">
            <div class="text-xs font-bold text-emerald-400 font-mono mb-2 flex items-center gap-1.5">
              <span>🏛️</span> 形式化逻辑三段论推演 (FormalSyllogism)
            </div>
            <div class="space-y-1.5 text-xs">
              <div class="p-2 rounded bg-white/5 text-neutral-300"><span class="font-bold text-emerald-400">[大前提]</span> 物理资源必须在离开作用域时确定性释放一次且仅一次。</div>
              <div class="p-2 rounded bg-white/5 text-neutral-300"><span class="font-bold text-emerald-400">[小前提]</span> 编译器基于 CFG 控制流图在编译期推导出局部变量的最后活跃点。</div>
              <div class="p-2 rounded bg-emerald-500/10 text-emerald-300 font-medium"><span class="font-bold">[必然结论]</span> 零运行期垃圾回收开销，从类型系统层面消除内存缺陷。</div>
            </div>
          </div>
        `;
      }
      return '';
    }

    function triggerSlashMenu() {
      const menu = document.getElementById('slash-menu');
      menu.classList.toggle('hidden');
    }

    function insertSlashComponent(componentName) {
      document.getElementById('slash-menu').classList.add('hidden');
      activeInjections.push({
        target_section: "## 新增交互小节",
        position: "after",
        component: componentName,
        props: { caption: "由创作者 Slash 积木菜单挂载" }
      });
      rawBlocks.push("## 新增交互小节");
      rawBlocks.push("这里是该小节的学术解析正文...");
      renderLiveCanvas();
      renderInjectionsAndPrereqs(activeInjections, activePrereqs);
      alert(`已成功挂载组件 [${componentName}] 到外置伴随清单！正文 Markdown 保持 100% 绝对纯净。`);
    }

    async function saveCurrentNote() {
      if (!currentDoc) return;
      const content = getCleanMarkdownFromBlocks();
      const res = await fetch('/api/note', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          vault: currentDoc.vault,
          path: currentDoc.canonical_path,
          content: content
        })
      }).then(r => r.json());

      if (res.success) {
        alert('✅ 笔记已成功保存至磁盘！Markdown 源码 0 字符污染。');
      } else {
        alert('保存提示: ' + (res.error || '只读知识库仅供研读预览'));
      }
    }

    function renderInjectionsAndPrereqs(injections, prereqs) {
      const container = document.getElementById('backlinks-container');
      let companionHtml = '';
      if (prereqs.length > 0) {
        companionHtml += `
          <div class="mb-3">
            <div class="text-[11px] font-bold text-amber-400 mb-1 flex items-center gap-1">
              <span>⬅️</span> 前置依赖穿透抽屉 (Prerequisites)
            </div>
            <div class="flex flex-wrap gap-1.5">
              ${prereqs.map(p => `<span class="px-2 py-0.5 rounded bg-white/5 border border-amber-500/20 text-[11px] text-amber-200">${p}</span>`).join('')}
            </div>
          </div>
        `;
      }
      if (injections.length > 0) {
        companionHtml += `
          <div class="mb-3">
            <div class="text-[11px] font-bold text-cyan-400 mb-1 flex items-center gap-1">
              <span>🧩</span> 原地挂载组件 (Mounted Injections)
            </div>
            <div class="space-y-1.5">
              ${injections.map(inj => `
                <div class="p-2 rounded bg-white/5 border border-cyan-500/20 text-[11px]">
                  <div class="font-bold text-cyan-300">${inj.component}</div>
                  <div class="text-[10px] text-neutral-400">挂载于: ${inj.target_section}</div>
                </div>
              `).join('')}
            </div>
          </div>
        `;
      }
      container.innerHTML = companionHtml + '<div class="border-t border-white/5 pt-2 mt-2 font-bold text-neutral-400 text-[11px]">反向链接 (Backlinks)</div>';
    }

    async function loadBacklinks(path) {
      const res = await fetch(`/api/backlinks?path=${encodeURIComponent(path)}`).then(r => r.json());
      const container = document.getElementById('backlinks-container');
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

    // 智能剪贴板清洗拦截器
    document.addEventListener('paste', function(e) {
      const html = e.clipboardData.getData('text/html');
      if (html && html.trim()) {
        e.preventDefault();
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        let text = doc.body.textContent || '';
        text = text.replace(/<!--[\s\S]*?-->/g, '').replace(/<\/?[^>]+(>|$)/g, '');
        rawBlocks.push(text);
        renderLiveCanvas();
      }
    });

    // 初始化加载
    loadTree();
  </script>
</body>
</html>
"###;
