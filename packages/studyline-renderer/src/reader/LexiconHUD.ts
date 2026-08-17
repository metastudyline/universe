// =============================================================================
// StudyLine Lexicon HUD Engine (Zero-Reflow Term Bubble)
// Floating UI popover for Greek terms with IPA pronunciation & genetic lineage
// =============================================================================

export interface TermData {
    id: string;
    greek: string;
    translit: string;
    ipa: string;
    literal: string;
    cn: string;
    en: string;
    note: string;
}

export class LexiconHUD {
    private container: HTMLElement;
    private termsMap = new Map<string, TermData>();
    private activeTrigger: HTMLElement | null = null;

    constructor(terms: TermData[]) {
        for (const term of terms) {
            this.termsMap.set(term.id.toLowerCase(), term);
            this.termsMap.set(term.greek, term);
            this.termsMap.set(term.translit.toLowerCase(), term);
        }

        this.container = document.createElement("div");
        this.container.className = "studyline-lexicon-hud-container";
        this.container.style.display = "none";
        document.body.appendChild(this.container);

        this.initGlobalDismiss();
    }

    public bindContainer(root: HTMLElement): void {
        const triggers = root.querySelectorAll<HTMLElement>("[data-term-id], .studyline-term");
        triggers.forEach(el => {
            el.style.cursor = "help";
            el.style.borderBottom = "1px dashed #d4af37";
            el.addEventListener("click", (e) => {
                e.stopPropagation();
                const termId = el.getAttribute("data-term-id") || el.innerText.trim();
                this.show(termId, el);
            });
        });
    }

    public show(termId: string, anchor: HTMLElement): void {
        const term = this.termsMap.get(termId.toLowerCase());
        if (!term) return;

        this.activeTrigger = anchor;
        const rect = anchor.getBoundingClientRect();

        this.container.innerHTML = `
            <div class="hud-card">
                <div class="hud-header">
                    <div class="hud-greek-title">
                        <span class="greek-polytonic">${term.greek}</span>
                        <span class="latin-translit">(${term.translit})</span>
                    </div>
                    <span class="hud-ipa">${term.ipa}</span>
                </div>
                <div class="hud-body">
                    <div class="hud-row"><span class="hud-label">字面原义:</span> <span class="hud-val">${term.literal}</span></div>
                    <div class="hud-row"><span class="hud-label">通行中译:</span> <span class="hud-val">${term.cn}</span></div>
                    <div class="hud-row"><span class="hud-label">通行英译:</span> <span class="hud-val">${term.en}</span></div>
                    <div class="hud-note"><span class="hud-note-icon">✦</span> ${term.note}</div>
                </div>
            </div>
        `;

        this.container.style.display = "block";
        this.container.style.position = "fixed";

        // Positioning: top-aligned or bottom-aligned to avoid screen overflow
        const hudWidth = 320;
        let left = rect.left + rect.width / 2 - hudWidth / 2;
        left = Math.max(16, Math.min(window.innerWidth - hudWidth - 16, left));

        let top = rect.bottom + 8;
        if (top + 200 > window.innerHeight) {
            top = rect.top - 210;
        }

        this.container.style.left = `${left}px`;
        this.container.style.top = `${top}px`;
        this.container.style.zIndex = "99999";
    }

    public hide(): void {
        this.container.style.display = "none";
        this.activeTrigger = null;
    }

    private initGlobalDismiss(): void {
        window.addEventListener("click", (e) => {
            if (!this.container.contains(e.target as Node)) {
                this.hide();
            }
        });
        window.addEventListener("keydown", (e) => {
            if (e.key === "Escape") this.hide();
        });
    }
}
