// =============================================================================
// StudyLine Capsule Drawer Engine (Micro Capsule Reader)
// Slide-over drawer with rich markdown, audio-sync timestamps, and criterion checks
// =============================================================================

import { LexiconHUD, TermData } from "./LexiconHUD";

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
    private lexiconHud: LexiconHUD;
    private isOpen = false;

    constructor(terms: TermData[]) {
        this.lexiconHud = new LexiconHUD(terms);

        this.container = document.createElement("aside");
        this.container.className = "studyline-capsule-drawer";
        this.container.style.transform = "translateX(100%)";
        document.body.appendChild(this.container);
    }

    public open(detail: CapsuleDetail): void {
        this.isOpen = true;
        this.container.style.transform = "translateX(0%)";

        const masteryLabels = ["0 无知", "1 未知", "2 了解", "3 使用", "4 掌握", "5 内化"];
        const masteryLabel = masteryLabels[detail.mastery] || "了解";

        this.container.innerHTML = `
            <div class="drawer-header">
                <div class="drawer-badge-row">
                    <span class="drawer-badge-id">${detail.id}</span>
                    <span class="drawer-badge-genre">${detail.genre}</span>
                    <span class="drawer-badge-mastery">🎯 要求: ${masteryLabel}</span>
                </div>
                <h2 class="drawer-title">${detail.title}</h2>
                <div class="drawer-lines">📖 原典位置: ${detail.lines}</div>
                <button class="drawer-close-btn" aria-label="Close">✕</button>
            </div>
            <div class="drawer-body markdown-body">
                ${this.renderMarkdown(detail.contentMarkdown)}
            </div>
        `;

        const closeBtn = this.container.querySelector(".drawer-close-btn");
        closeBtn?.addEventListener("click", () => this.close());

        // Bind lexicon HUD triggers in the newly rendered markdown
        this.lexiconHud.bindContainer(this.container);
    }

    public close(): void {
        this.isOpen = false;
        this.container.style.transform = "translateX(100%)";
        this.lexiconHud.hide();
    }

    private renderMarkdown(md: string): string {
        // Lightweight markdown parser for headers, lists, code, and bold
        let html = md
            .replace(/^### (.*$)/gim, "<h3>$1</h3>")
            .replace(/^## (.*$)/gim, "<h2>$1</h2>")
            .replace(/^# (.*$)/gim, "<h1>$1</h1>")
            .replace(/\*\*(.*)\*\*/gim, "<strong>$1</strong>")
            .replace(/\*(.*)\*/gim, "<em>$1</em>")
            .replace(/`([^`]+)`/gim, "<code>$1</code>")
            .replace(/\n\n/gim, "<p></p>")
            .replace(/^\- (.*$)/gim, "<li>$1</li>");

        // Auto-wrap known Greek keywords for LexiconHUD trigger
        const greekKeywords = ["δίκη", "ὕβρις", "τιμή", "Χάος", "ἀρχή", "οὐσία", "ψυχή", "νοῦς", "λόγος", "ἀλήθεια"];
        for (const kw of greekKeywords) {
            const regex = new RegExp(`(${kw})`, "g");
            html = html.replace(regex, `<span class="studyline-term" data-term-id="$1">$1</span>`);
        }

        return html;
    }
}
