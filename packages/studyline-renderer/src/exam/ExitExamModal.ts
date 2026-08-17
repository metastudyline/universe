// =============================================================================
// StudyLine Comprehensive Exit Exam Modal Engine (0段 94期出段大考交互系统)
// =============================================================================

export interface ExamQuestion {
    id: string;
    section: "lexicon" | "syllogism" | "topology";
    prompt: string;
    options: string[];
    correctIndex: number;
    explanation: string;
}

export class ExitExamModal {
    private modalEl: HTMLElement;
    private isOpen = false;
    private currentQuestionIndex = 0;
    private userAnswers: number[] = [];
    private isFinished = false;

    private questions: ExamQuestion[] = [
        {
            id: "Q1",
            section: "lexicon",
            prompt: "【专名辨析】阿那克西曼德将万物本原确立为 ἄπειρον（无定），其根本理论动机是什么？",
            options: [
                "A. 认为水或气不够具体，需要一种更坚硬的元素作为支撑",
                "B. 发现任何有定特性的质料（如火干冷湿）一旦成为本原，必将消灭其对立面，故本原必须先于一切性质对立",
                "C. 迎合当时米利都城邦贵族的神秘神谱信仰",
                "D. 证明宇宙是由无序原子在虚空中随机碰撞而成的"
            ],
            correctIndex: 1,
            explanation: "DK 12 B1：若本原为火，则水早已被烧尽；若为水，则火无法生成。唯有无定（ἄπειρον）能充当生成万物的永恒母体。"
        },
        {
            id: "Q2",
            section: "syllogism",
            prompt: "【论证重构】在巴门尼德《论自然》DK 28 B8 中，用于证明「存在者不生不灭」的核心排中律归谬前提是什么？",
            options: [
                "A. 若存在者生成，必从「非存在」生成，但非存在不可思不可言，故生成是不可能的",
                "B. 宇宙是由神灵依照理念模型塑造出来的",
                "C. 时间是相对的，因此存在也是相对的",
                "D. 运动是万物的常态，火是其物理表征"
            ],
            correctIndex: 0,
            explanation: "排中律：存在者不能从存在生成（因为已存在），亦不能从非存在生成（因为非存在根本不存在）。故存在者不生不灭。"
        },
        {
            id: "Q3",
            section: "topology",
            prompt: "【拓扑因果重构】从荷马史诗到埃斯库罗斯《欧墨尼得斯》，古希腊正义观念完成了何种跃迁？",
            options: [
                "A. 从城邦民主投票退化为原始丛林肉体复仇",
                "B. 从依附于个人战利品（γέρας）的血亲复仇，跃迁为由战神山公民法庭与雅典娜理性裁决的城邦客观司法制度",
                "C. 彻底废除了恐惧（to deinon）在城邦正义中的地位",
                "D. 将神权完全置于成文法之上"
            ],
            correctIndex: 1,
            explanation: "埃斯库罗斯展现了雅典娜设立战神山陪审团，将复仇女神收编为守护城邦的慈惠女神，实现了从私力复仇到城邦公共正义的历史性跨越。"
        }
    ];

    constructor() {
        let existing = document.getElementById("exit-exam-overlay");
        if (!existing) {
            existing = document.createElement("div");
            existing.id = "exit-exam-overlay";
            existing.className = "command-modal-overlay";
            existing.style.paddingTop = "8vh";
            document.body.appendChild(existing);
        }
        this.modalEl = existing;
        this.initEvents();
    }

    private initEvents(): void {
        this.modalEl.addEventListener("click", (e) => {
            if (e.target === this.modalEl) this.close();
        });
    }

    public open(): void {
        this.isOpen = true;
        this.isFinished = false;
        this.currentQuestionIndex = 0;
        this.userAnswers = [];
        this.modalEl.classList.add("open");
        this.render();
    }

    public close(): void {
        this.isOpen = false;
        this.modalEl.classList.remove("open");
    }

    private render(): void {
        if (this.isFinished) {
            this.renderResult();
            return;
        }

        const q = this.questions[this.currentQuestionIndex];
        const progressPercent = Math.round(((this.currentQuestionIndex + 1) / this.questions.length) * 100);

        this.modalEl.innerHTML = `
            <div class="command-modal" style="width: 720px; max-height: 85vh; padding: 28px; background: rgba(18, 18, 22, 0.98); border: 1.5px solid var(--color-kintsugi-gold); border-radius: 18px; box-shadow: 0 30px 80px rgba(0,0,0,0.9), 0 0 30px rgba(212,175,55,0.3);">
                <!-- Header -->
                <div style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid var(--border-hairline); padding-bottom: 16px; margin-bottom: 20px;">
                    <div>
                        <div style="font-family: var(--font-serif-editorial); font-size: 11px; font-weight: 700; letter-spacing: 2px; color: var(--color-kintsugi-gold); text-transform: uppercase;">0段 94期 · 全景出段综合大考</div>
                        <div style="font-size: 18px; font-weight: 700; color: #FFF; margin-top: 4px;">不可伪造学术学籍考核 (${this.currentQuestionIndex + 1}/${this.questions.length})</div>
                    </div>
                    <button id="exam-close-btn" style="width: 32px; height: 32px; border-radius: 50%; background: var(--color-surface-card); border: 0.8px solid var(--border-hairline); color: var(--text-secondary); cursor: pointer;">✕</button>
                </div>

                <!-- Progress Bar -->
                <div style="width: 100%; height: 4px; background: rgba(255,255,255,0.08); border-radius: 2px; margin-bottom: 24px; overflow: hidden;">
                    <div style="width: ${progressPercent}%; height: 100%; background: linear-gradient(90deg, #D4AF37, #10B981); transition: width 0.3s ease;"></div>
                </div>

                <!-- Prompt -->
                <div style="font-family: var(--font-serif-editorial); font-size: 17px; line-height: 1.6; color: #FBFBFD; margin-bottom: 24px;">
                    ${q.prompt}
                </div>

                <!-- Options -->
                <div style="display: flex; flex-direction: column; gap: 10px; margin-bottom: 28px;">
                    ${q.options.map((opt, i) => `
                        <div class="exam-option-card" data-index="${i}" style="padding: 14px 18px; background: var(--color-surface-card); border: 1px solid var(--border-hairline); border-radius: 10px; font-size: 14px; color: #D1D1D6; cursor: pointer; transition: all 0.2s ease;">
                            ${opt}
                        </div>
                    `).join("")}
                </div>

                <!-- Footer -->
                <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-hairline); padding-top: 16px;">
                    <span style="font-size: 12px; color: var(--text-tertiary);">🔒 本地 ECDSA 密码学防作弊签名已就绪</span>
                    <button id="exam-next-btn" class="btn-kintsugi-gold" style="opacity: 0.5; pointer-events: none;">确认并下一题 ➔</button>
                </div>
            </div>
        `;

        const closeBtn = document.getElementById("exam-close-btn");
        closeBtn?.addEventListener("click", () => this.close());

        let selectedIndex = -1;
        const optionsCards = this.modalEl.querySelectorAll(".exam-option-card");
        const nextBtn = document.getElementById("exam-next-btn") as HTMLButtonElement;

        optionsCards.forEach(card => {
            card.addEventListener("click", () => {
                optionsCards.forEach(c => (c as HTMLElement).style.borderColor = "var(--border-hairline)");
                optionsCards.forEach(c => (c as HTMLElement).style.background = "var(--color-surface-card)");
                (card as HTMLElement).style.borderColor = "var(--color-kintsugi-gold)";
                (card as HTMLElement).style.background = "var(--color-surface-active)";
                selectedIndex = parseInt((card as HTMLElement).dataset.index || "0", 10);
                nextBtn.style.opacity = "1";
                nextBtn.style.pointerEvents = "auto";
            });
        });

        nextBtn.addEventListener("click", () => {
            this.userAnswers.push(selectedIndex);
            if (this.currentQuestionIndex < this.questions.length - 1) {
                this.currentQuestionIndex++;
                this.render();
            } else {
                this.isFinished = true;
                this.render();
            }
        });
    }

    private renderResult(): void {
        let correctCount = 0;
        this.questions.forEach((q, i) => {
            if (this.userAnswers[i] === q.correctIndex) correctCount++;
        });
        const score = Math.round((correctCount / this.questions.length) * 100);
        const isPass = score >= 80;

        this.modalEl.innerHTML = `
            <div class="command-modal" style="width: 650px; padding: 36px; background: rgba(18, 18, 22, 0.98); border: 2px solid ${isPass ? 'var(--color-kintsugi-gold)' : 'var(--color-cinnabar-red)'}; border-radius: 20px; text-align: center;">
                <div style="font-size: 48px; margin-bottom: 12px;">${isPass ? '🏛️' : '📜'}</div>
                <h2 style="font-family: var(--font-serif-editorial); font-size: 24px; color: ${isPass ? 'var(--color-kintsugi-gold)' : 'var(--color-cinnabar-red)'}; margin-bottom: 8px;">
                    ${isPass ? '0段 94期出段大考 · 考核通过！' : '考核未达标，需重温学线'}
                </h2>
                <div style="font-size: 14px; color: var(--text-secondary); margin-bottom: 24px;">
                    得分: <strong style="font-size: 20px; color: #FFF;">${score}分</strong> (正确率: ${correctCount}/${this.questions.length})
                </div>

                ${isPass ? `
                    <div style="padding: 16px; background: rgba(212, 175, 55, 0.08); border: 1px dashed var(--color-kintsugi-gold); border-radius: 12px; margin-bottom: 24px; font-size: 13px; line-height: 1.7; color: #F3E5AB;">
                        ✦ 恭喜！你已完整贯通赫西俄德宇宙生成论、荷马分配正义与悲剧城邦司法模型。<br>
                        <strong>学籍状态已自动晋升为「阶段 A 候考 (Stage A Eligible)」！</strong>
                    </div>
                ` : `
                    <div style="padding: 16px; background: rgba(224, 90, 71, 0.08); border: 1px dashed var(--color-cinnabar-red); border-radius: 12px; margin-bottom: 24px; font-size: 13px; color: #FFA090;">
                        建议回到中央画布点击「求解路径」，重新攻克薄弱概念节点后再次应试。
                    </div>
                `}

                <button id="exam-finish-btn" class="btn-kintsugi-gold" style="padding: 10px 28px; font-size: 14px;">返回知识宇宙</button>
            </div>
        `;

        document.getElementById("exam-finish-btn")?.addEventListener("click", () => this.close());
    }
}
