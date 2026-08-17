// =============================================================================
// StudyLine Polytonic Greek Lexicon HUD (Zero-Reflow Dictionary Engine)
// =============================================================================

export interface TermData {
    id: string;
    greek: string;
    ipa: string;
    literalMeaning: string;
    source: string;
    etymology: string;
}

export class LexiconHUD {
    private cardEl: HTMLElement;
    private termsMap = new Map<string, TermData>();

    constructor(initialTerms: TermData[] = []) {
        for (const t of initialTerms) {
            this.termsMap.set(t.greek, t);
            this.termsMap.set(t.id, t);
        }

        // Built-in canonical Pre-Socratic & Archaic Greek Lexicon
        const canonicalLexicon: TermData[] = [
            {
                id: "apeiron",
                greek: "ἄπειρον",
                ipa: "/á.peː.ron/",
                literalMeaning: "无界限者 / 无定",
                source: "阿那克西曼德 DK 12 B1",
                etymology: "否定前缀 ἀ- (无) + πεῖραρ (界限/终点)。先于冷热干湿等一切具体对立性质分化，永恒不竭地生成并收回万物的终极本原。"
            },
            {
                id: "dike",
                greek: "δίκη",
                ipa: "/dí.kɛː/",
                literalMeaning: "正义 / 宇宙裁决尺度",
                source: "赫西俄德《劳作》275行 / DK 12 B1 / DK 28 B8",
                etymology: "原指指示方向与边界的路径（deiknymi），在宇宙论中引申为惩罚过度僭越（ὕβρις）并强制作出补偿的客观守恒铁律。"
            },
            {
                id: "logos",
                greek: "λόγος",
                ipa: "/ló.ɡos/",
                literalMeaning: "客观逻各斯 / 尺度 / 聚集",
                source: "赫拉克利特 DK 22 B1, B50",
                etymology: "动词 λέγειν (聚集/言说)。指支配万物相反相成、按尺度燃烧与熄灭的普遍客观秩序与理性结构。"
            },
            {
                id: "chaos",
                greek: "Χάος",
                ipa: "/kʰá.os/",
                literalMeaning: "深渊裂隙 / 原始虚空",
                source: "赫西俄德《神谱》116行",
                etymology: "动词 χαίνω (张开/裂开)。并非现代意义上的混乱无序，而是空间开裂后提供的第一存在舞台。"
            },
            {
                id: "estin",
                greek: "ἔστιν",
                ipa: "/és.tin/",
                literalMeaning: "它是 / 存在者存在",
                source: "巴门尼德 DK 28 B2, B8",
                etymology: "系动词 εἶναι 的单数现在时。巴门尼德由此确立西方形而上学本体论（Ontology）的第一公理：非存在不可思不可言。"
            }
        ];

        for (const t of canonicalLexicon) {
            this.termsMap.set(t.greek, t);
            this.termsMap.set(t.id, t);
        }

        let existingCard = document.getElementById("lexicon-hud-card");
        if (!existingCard) {
            existingCard = document.createElement("div");
            existingCard.id = "lexicon-hud-card";
            existingCard.className = "lexicon-hud-card";
            document.body.appendChild(existingCard);
        }
        this.cardEl = existingCard;

        this.initGlobalEvents();
    }

    private initGlobalEvents(): void {
        document.addEventListener("click", (e) => {
            const target = (e.target as HTMLElement).closest(".greek-term-token, .studyline-term") as HTMLElement;
            if (target) {
                const greek = target.dataset.greek || target.dataset.termId || target.textContent?.trim() || "";
                this.showForElement(target, greek);
            } else if (!this.cardEl.contains(e.target as Node)) {
                this.hide();
            }
        });
    }

    public showForElement(target: HTMLElement, greekKey: string): void {
        const data = this.termsMap.get(greekKey);
        if (!data) return;

        const rect = target.getBoundingClientRect();
        const top = rect.bottom + window.scrollY + 8;
        const left = Math.min(Math.max(rect.left + window.scrollX - 40, 16), window.innerWidth - 340);

        this.cardEl.style.top = `${top}px`;
        this.cardEl.style.left = `${left}px`;
        this.cardEl.innerHTML = `
            <div class="hud-greek-headword">${data.greek}</div>
            <div class="hud-ipa">${data.ipa} · <span style="color: var(--text-tertiary);">${data.source}</span></div>
            <div class="hud-context"><strong>【字面义】</strong>${data.literalMeaning}</div>
            <div class="hud-context" style="margin-top: 8px; font-size: 12px; color: #B0B0B8;">${data.etymology}</div>
        `;
        this.cardEl.classList.add("visible");
    }

    public hide(): void {
        this.cardEl.classList.remove("visible");
    }

    public bindContainer(container: HTMLElement): void {
        // Automatically wired via global click delegation
    }
}
