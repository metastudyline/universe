// =============================================================================
// StudyLine Universe Workbench Orchestrator (Demo Entry)
// =============================================================================

import { UniverseCanvas, UniverseData, NodeVisual } from "../src/canvas/UniverseCanvas";
import { CapsuleDrawer } from "../src/reader/CapsuleDrawer";
import { StudyLineBridgeClient } from "../src/bridge/StudyLineBridgeClient";
import stage0Dataset from "./data/stage0_dataset.json";

// Initialize Data & Canvas
const canvasEl = document.getElementById("universe-canvas") as HTMLCanvasElement;
const drawer = new CapsuleDrawer();

const universeData: UniverseData = {
    nodes: (stage0Dataset.nodes as any[]).map(n => ({
        id: n.id,
        title: n.title,
        genre: n.genre as any,
        spine: n.spine ?? true,
        mastery: n.mastery ?? 0,
        lines: n.lines ?? "",
        clusterId: n.clusterId ?? "stage0_c1",
        x: n.x ?? (Math.random() * 800 - 400),
        y: n.y ?? (Math.random() * 800 - 400),
        radius: n.spine ? 18 : 10
    })),
    edges: (stage0Dataset.edges as any[]).map(e => ({
        from: e.from,
        to: e.to,
        type: e.type ?? "strict",
        golden: e.golden ?? false
    })),
    clusters: [
        { id: "stage0_c1", title: "0段 · 赫西俄德神谱宇宙论", x: -280, y: -100 },
        { id: "stage0_c2", title: "0段 · 荷马史诗与分配正义", x: 0, y: -200 },
        { id: "stage0_c3", title: "0段 · 悲剧与雅典城邦撕裂", x: 280, y: 50 },
        { id: "stageA_c1", title: "阶段A · 米利都与爱利亚本体论", x: 450, y: -150 }
    ]
};

const universeCanvas = new UniverseCanvas(canvasEl, universeData);
universeCanvas.start();

// Handle Node Selection -> Open Drawer
universeCanvas.setOnNodeSelect((node: NodeVisual) => {
    drawer.open({
        id: node.id,
        title: `${node.id} · ${node.title}`,
        genre: node.genre,
        mastery: node.mastery,
        lines: node.lines || "一手原典",
        contentMarkdown: `
## 核心哲学问题与一手原典考据

本节点在知识拓扑中处于核心枢纽地位。通过对希腊一手原典的细读，揭示概念体系的发生学流变。

### 核心论证三段论 (Syllogism)

1. **大前提 (P1)**: 宇宙万物的本原不可归约为任何单一经验质料；
2. **小前提 (P2)**: 凡有限有定之物皆处于相反者的相互逾界与补偿之中；
3. **结论 (C)**: 必须设立永恒不竭的 **ἄπειρον** 与客观法则 **δίκη**。
        `
    });
});

// Viewport Controls
document.getElementById("btn-zoom-in")?.addEventListener("click", () => universeCanvas.zoomIn());
document.getElementById("btn-zoom-out")?.addEventListener("click", () => universeCanvas.zoomOut());
document.getElementById("btn-fit-view")?.addEventListener("click", () => universeCanvas.fitView());

// Path Calculation
const targetSelect = document.getElementById("target-node-select") as HTMLSelectElement;
document.getElementById("calculate-path-btn")?.addEventListener("click", () => {
    const target = targetSelect.value;
    // Highlight shortest path to target
    const samplePaths: Record<string, string[]> = {
        "E82": ["E01", "E07", "E29", "E37", "E66", "E72", "E82"],
        "E66": ["E01", "E07", "E29", "E66"],
        "E72": ["E01", "E07", "E66", "E72"],
        "A25": ["E01", "A01", "A04", "A16", "A25"],
        "A16": ["E01", "A01", "A04", "A16"],
        "A04": ["E01", "A01", "A04"]
    };
    const path = samplePaths[target] || ["E01", target];
    universeCanvas.highlightShortestPath(path);
    universeCanvas.focusNode(target);
});

document.getElementById("clear-path-btn")?.addEventListener("click", () => {
    universeCanvas.clearHighlight();
});

// Command+K Search Modal
const modalOverlay = document.getElementById("command-modal-overlay");
const searchTriggerBtn = document.getElementById("search-trigger-btn");
const searchInput = document.getElementById("command-search-input") as HTMLInputElement;
const resultsList = document.getElementById("command-results-list");

function openSearch() {
    modalOverlay?.classList.add("open");
    searchInput?.focus();
    renderSearchResults("");
}

function closeSearch() {
    modalOverlay?.classList.remove("open");
    if (searchInput) searchInput.value = "";
}

searchTriggerBtn?.addEventListener("click", openSearch);
modalOverlay?.addEventListener("click", (e) => {
    if (e.target === modalOverlay) closeSearch();
});

window.addEventListener("keydown", (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        openSearch();
    } else if (e.key === "Escape") {
        closeSearch();
        drawer.close();
    }
});

function renderSearchResults(query: string) {
    if (!resultsList) return;
    const q = query.toLowerCase().trim();
    const filtered = universeData.nodes.filter(n =>
        n.id.toLowerCase().includes(q) || n.title.toLowerCase().includes(q)
    );

    resultsList.innerHTML = filtered.slice(0, 8).map(n => `
        <div class="command-result-row" data-id="${n.id}">
            <div class="result-main">
                <span class="result-id-tag">${n.id}</span>
                <span class="result-title-text">${n.title}</span>
            </div>
            <span style="font-size: 11px; color: var(--text-tertiary); font-family: var(--font-mono-data);">${n.lines || "Spine"}</span>
        </div>
    `).join("");

    resultsList.querySelectorAll(".command-result-row").forEach(row => {
        row.addEventListener("click", () => {
            const id = (row as HTMLElement).dataset.id;
            if (id) {
                universeCanvas.focusNode(id);
                const node = universeData.nodes.find(n => n.id === id);
                if (node) {
                    drawer.open({
                        id: node.id,
                        title: `${node.id} · ${node.title}`,
                        genre: node.genre,
                        mastery: node.mastery,
                        lines: node.lines,
                        contentMarkdown: `## 节点 ${node.id}: ${node.title}\n\n已成功从 Command+K 全局快速导航进入。`
                    });
                }
            }
            closeSearch();
        });
    });
}

searchInput?.addEventListener("input", (e) => {
    renderSearchResults((e.target as HTMLInputElement).value);
});

// Rust Bridge Connection
const bridgeClient = new StudyLineBridgeClient({
    serverUrl: "ws://127.0.0.1:3001/ws",
    onStatusChange: (status) => {
        const dot = document.getElementById("status-dot");
        const txt = document.getElementById("bridge-status-text");
        if (status === "CONNECTED") {
            dot?.classList.add("connected");
            if (txt) txt.textContent = "🟢 Rust 守护进程已直连 :3001";
        } else {
            dot?.classList.remove("connected");
            if (txt) txt.textContent = "🟡 离线静态模式 (Local Fallback)";
        }
    }
});
bridgeClient.connect();
