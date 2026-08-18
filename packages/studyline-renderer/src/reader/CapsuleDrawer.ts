// =============================================================================
// StudyLine Capsule Drawer Engine (Typora Academic Edition)
// =============================================================================

import { AcademicMarkdownParser } from "./AcademicMarkdownParser";

export interface CapsuleDetail {
    id: string;
    title: string;
    genre: string;
    mastery: number;
    lines: string;
    contentMarkdown: string;
}

export class CapsuleDrawer {
    private container: HTMLElement;
    private isOpen = false;
    private onZenModeRequest?: (nodeId: string, markdown: string) => void;
    private currentDetail?: CapsuleDetail;

    constructor() {
        let drawerEl = document.getElementById("lecture-drawer");
        if (!drawerEl) {
            drawerEl = document.createElement("aside");
            drawerEl.id = "lecture-drawer";
            drawerEl.className = "lecture-drawer";
            document.body.appendChild(drawerEl);
        }
        this.container = drawerEl;

        const closeBtn = document.getElementById("drawer-close-btn");
        closeBtn?.addEventListener("click", () => this.close());

        const zenBtn = document.getElementById("drawer-zen-btn");
        zenBtn?.addEventListener("click", () => {
            if (this.currentDetail && this.onZenModeRequest) {
                this.onZenModeRequest(this.currentDetail.id, this.currentDetail.contentMarkdown);
            }
        });
    }

    public setOnZenModeRequest(cb: (nodeId: string, markdown: string) => void): void {
        this.onZenModeRequest = cb;
    }

    public open(detail: CapsuleDetail): void {
        this.isOpen = true;
        this.currentDetail = detail;
        this.container.classList.add("open");

        const idTag = document.getElementById("drawer-node-id");
        if (idTag) idTag.textContent = detail.id;

        const linesTag = document.getElementById("drawer-node-lines");
        if (linesTag) linesTag.textContent = detail.lines || detail.genre;

        const bodyEl = document.getElementById("drawer-body");
        if (bodyEl) {
            const parsed = AcademicMarkdownParser.parse(detail.contentMarkdown);
            bodyEl.innerHTML = `
                <div class="drawer-reading-header">
                    <button id="drawer-zen-action-btn" class="btn-kintsugi-gold" style="font-size: 11px; padding: 4px 10px; margin-bottom: 16px;">
                        ⛶ 全屏 Zen 纸张研读
                    </button>
                </div>
                ${parsed.html}
            `;

            document.getElementById("drawer-zen-action-btn")?.addEventListener("click", () => {
                if (this.onZenModeRequest) {
                    this.onZenModeRequest(detail.id, detail.contentMarkdown);
                }
            });
        }
    }

    public close(): void {
        this.isOpen = false;
        this.container.classList.remove("open");
    }
}
