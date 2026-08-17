// =============================================================================
// StudyLine Capsule Drawer Engine (WSJ Editorial Academic Edition)
// =============================================================================

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
    }

    public open(detail: CapsuleDetail): void {
        this.isOpen = true;
        this.container.classList.add("open");

        const idTag = document.getElementById("drawer-node-id");
        if (idTag) idTag.textContent = detail.id;

        const linesTag = document.getElementById("drawer-node-lines");
        if (linesTag) linesTag.textContent = detail.lines || detail.genre;

        const bodyEl = document.getElementById("drawer-article-body");
        if (bodyEl) {
            bodyEl.innerHTML = `
                <h1>${detail.title}</h1>
                <div class="bilingual-primary-box">
                    <div class="greek-quote">« ἤτοι μὲν πρώτιστα Χάος γένετ' · αὐτὰρ ἔπειτα Γαῖ' εὐρύστερνος ... »</div>
                    <div class="chinese-translation">「最初生成的是卡俄斯（虚空深渊），紧接着生成的是宽胸的大地盖亚……」—— 《神谱》116-117行</div>
                </div>
                ${this.renderMarkdown(detail.contentMarkdown)}
            `;
        }
    }

    public close(): void {
        this.isOpen = false;
        this.container.classList.remove("open");
    }

    private renderMarkdown(md: string): string {
        if (!md) return "<p>暂无精读讲义正文。</p>";
        let html = md
            .replace(/^### (.*$)/gim, "<h3>$1</h3>")
            .replace(/^## (.*$)/gim, "<h2>$1</h2>")
            .replace(/^# (.*$)/gim, "<h1>$1</h1>")
            .replace(/\*\*(.*)\*\*/gim, "<strong style='color: var(--color-kintsugi-gold);'>$1</strong>")
            .replace(/\*(.*)\*/gim, "<em>$1</em>")
            .replace(/`([^`]+)`/gim, "<code style='font-family: var(--font-mono-data); color: var(--color-bamboo-green);'>$1</code>")
            .replace(/\n\n/gim, "</p><p>")
            .replace(/^\- (.*$)/gim, "<li>$1</li>");

        const terms = ["ἄπειρον", "δίκη", "ὕβρις", "τιμή", "Χάος", "ἀρχή", "οὐσία", "ψυχή", "νοῦς", "λόγος", "ἀλήθεια", "ἔστιν"];
        for (const t of terms) {
            const reg = new RegExp(`(${t})`, "g");
            html = html.replace(reg, `<span class="greek-term-token" data-greek="$1">$1</span>`);
        }
        return `<p>${html}</p>`;
    }
}
