// =============================================================================
// StudyLine Zen Fullscreen Academic Reader View Engine
// Immersive A4 Paper Layout, TOC Navigation, & Dual-Theme System
// =============================================================================

import { AcademicMarkdownParser, ParsedAcademicArticle } from "./AcademicMarkdownParser";

export class ZenReaderView {
    private overlayEl: HTMLElement;
    private isOpen = false;
    private currentTheme: "graphite" | "washi" = "graphite";
    private activeNodeId = "";

    constructor() {
        let el = document.getElementById("zen-reader-overlay");
        if (!el) {
            el = document.createElement("div");
            el.id = "zen-reader-overlay";
            el.className = "zen-reader-overlay";
            document.body.appendChild(el);
        }
        this.overlayEl = el;
        this.initEvents();
    }

    private initEvents(): void {
        window.addEventListener("keydown", (e) => {
            if (this.isOpen && e.key === "Escape") {
                this.close();
            }
        });
    }

    public open(nodeId: string, rawMarkdown: string): void {
        this.isOpen = true;
        this.activeNodeId = nodeId;
        this.overlayEl.classList.add("open");

        const parsed = AcademicMarkdownParser.parse(rawMarkdown);
        this.render(parsed);
    }

    public close(): void {
        this.isOpen = false;
        this.overlayEl.classList.remove("open");
    }

    public toggleTheme(): void {
        this.currentTheme = this.currentTheme === "graphite" ? "washi" : "graphite";
        if (this.currentTheme === "washi") {
            this.overlayEl.setAttribute("data-theme", "washi");
        } else {
            this.overlayEl.removeAttribute("data-theme");
        }
    }

    private render(parsed: ParsedAcademicArticle): void {
        this.overlayEl.innerHTML = `
            <!-- Top Progress Bar -->
            <div class="reading-progress-bar-container">
                <div id="zen-progress-bar" class="reading-progress-bar"></div>
            </div>

            <!-- Zen Navigation Bar -->
            <header class="zen-header-bar">
                <div class="zen-header-left">
                    <span class="zen-badge">🏛️ 沉浸学术研读</span>
                    <span style="font-family: var(--font-mono-data); color: var(--color-kintsugi-gold); font-size: 13px; font-weight: 700;">${this.activeNodeId}</span>
                </div>
                <div class="zen-header-actions">
                    <button id="zen-theme-toggle" class="btn-zen-tool" title="切换和纸白/墨黑主题">🌓 纸张色彩</button>
                    <button id="zen-close-btn" class="btn-zen-tool" title="退出全屏 (Esc)">✕ 退出</button>
                </div>
            </header>

            <!-- Zen Paper Workspace -->
            <div id="zen-scroll-container" class="zen-scroll-container">
                <div class="zen-layout-grid">
                    <!-- Left/Floating TOC -->
                    <aside class="zen-toc-sidebar">
                        <div class="academic-toc-panel">
                            <div style="font-weight: 700; color: var(--color-kintsugi-gold); font-size: 12px; margin-bottom: 10px; letter-spacing: 1px;">大纲目录 (TOC)</div>
                            ${parsed.headings.map(h => `
                                <a href="#${h.id}" class="toc-heading-item level-${h.level}">${h.title}</a>
                            `).join("")}
                        </div>
                    </aside>

                    <!-- Center A4 Paper -->
                    <main id="write" class="latex-article zen-paper">
                        ${parsed.html}
                    </main>
                </div>
            </div>
        `;

        document.getElementById("zen-close-btn")?.addEventListener("click", () => this.close());
        document.getElementById("zen-theme-toggle")?.addEventListener("click", () => this.toggleTheme());

        // Bind Reading Progress Bar & TOC Scroll Spy
        const scrollContainer = document.getElementById("zen-scroll-container");
        const progressBar = document.getElementById("zen-progress-bar");

        if (scrollContainer && progressBar) {
            let ticking = false;
            scrollContainer.addEventListener("scroll", () => {
                if (!ticking) {
                    requestAnimationFrame(() => {
                        const maxScroll = scrollContainer.scrollHeight - scrollContainer.clientHeight;
                        const progress = maxScroll > 0 ? scrollContainer.scrollTop / maxScroll : 0;
                        progressBar.style.transform = `scaleX(${progress})`;
                        ticking = false;
                    });
                    ticking = true;
                }
            }, { passive: true });
        }

        // TOC click smooth scroll
        this.overlayEl.querySelectorAll(".toc-heading-item").forEach(link => {
            link.addEventListener("click", (e) => {
                e.preventDefault();
                const targetId = (link as HTMLAnchorElement).getAttribute("href")?.replace("#", "");
                if (targetId) {
                    const targetEl = document.getElementById(targetId);
                    targetEl?.scrollIntoView({ behavior: "smooth", block: "start" });
                }
            });
        });
    }
}
