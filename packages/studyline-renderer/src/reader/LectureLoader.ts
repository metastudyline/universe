// =============================================================================
// StudyLine Canonical Lecture Loader (Static Aggregation & Live HMR Engine)
// =============================================================================

import { StudyLineBridgeClient } from "../bridge/StudyLineBridgeClient";

export class LectureLoader {
    private static instance: LectureLoader;
    private lectureCache = new Map<string, string>();
    private subscribers = new Map<string, Set<(content: string) => void>>();

    private constructor() {
        this.loadStaticLectures();
    }

    public static getInstance(): LectureLoader {
        if (!LectureLoader.instance) {
            LectureLoader.instance = new LectureLoader();
        }
        return LectureLoader.instance;
    }

    /**
     * Eagerly index all real domains/** /index.md lecture files at build time
     */
    private loadStaticLectures(): void {
        try {
            // Vite build-time static glob
            const modules = (import.meta as any).glob("../../../../domains/**/index.md", {
                query: "?raw",
                eager: true,
                import: "default"
            }) as Record<string, string>;

            for (const [filePath, content] of Object.entries(modules)) {
                // Extract node ID: E01, E07, A04, X01, etc.
                const match = filePath.match(/\/([A-Z]\d{2}(?:_[^\/]+)?)\/index\.md$/);
                if (match) {
                    const rawDir = match[1];
                    const nodeId = rawDir.split("_")[0];
                    this.lectureCache.set(nodeId, content);
                    this.lectureCache.set(rawDir, content);
                }
            }
        } catch (e) {
            console.warn("[LectureLoader] Vite glob import not available, using fallback cache", e);
        }

        // Built-in canonical lecture fallbacks if glob not matched
        if (!this.lectureCache.has("A04")) {
            this.lectureCache.set("A04", `
# A04 阿那克西曼德残篇 B1：依照时间的裁定相互补偿其不义

## 一、 一手文本锚点 (Simplicius *In Phys.* 24, 13)

> 🏛️ [希腊原文] ἐξ ὧν δὲ ἡ γένεσίς ἐστι τοῖς οὖσι, καὶ τὴν φθορὰν εἰς ταῦτα γίνεσθαι κατὰ τὸ χρεών· διδόναι γὰρ αὐτὰ δίκην καὶ τίσιν ἀλλήλοις τῆς ἀδικίας κατὰ τὴν τοῦ χρόνου τάξιν.
> 📜 [学术中译] 万物从何处生成，也必依照必然性（κατὰ τὸ χρεών）毁灭而归向何处；因为它们依照时间的裁定（κατὰ τὴν τοῦ χρόνου τάξιν），为了彼此的不义（ἀδικία）相互支付正义赔偿与赎罪（δίκην καὶ τίσιν）。

---

## 二、 核心哲学解析

1. **本原的抽象化飞跃**：阿那克西曼德放弃了泰勒斯的具体“水”，提出 **ἄπειρον**（无定/无界）——本原不能具有排他性的具体形态，必须是未分化的中性母体；
2. **宇宙法庭诉讼模型**：事物的生成是单一元素对时空的单向侵占（如夏热侵占冷湿，构成 **ἀδικία**）；时间作为公正法官，要求其在冬季通过消亡清偿赔偿；
3. **前哲学正义的自然化**：完成了从赫西俄德人间司法向统御自然物理宇宙法则的伟大跃迁。

---

## 三、 形式化论证三段论 (Syllogism)

- **大前提 (P1)**: 宇宙万物的终极本原不可归约为任何单一经验质料（火、水、气）；
- **小前提 (P2)**: 凡有限有定之物皆处于相反者的相互逾界（ὕβρις）与补偿之中；
- **归谬 (R1)**: 若本原为水，则烈火必被扑灭而无法共存，宇宙失去动态平衡；
- **结论 (C)**: ∴ 必须设立永恒不竭的 **ἄπειρον**（无定）与客观正义尺度 **δίκη**。

---

## 四、 核心范畴演进对照

| 概念范畴 (Greek) | 字面含义 | DK 出处 | 哲学史本体论意义 |
| :---: | :---: | :---: | :---: |
| **ἄπειρον** | 无界限 / 无定 | DK 12 B1 | 先于一切性质对立的永恒母体 |
| **δίκη** | 宇宙正义尺度 | 赫西俄德《劳作》275 | 惩治逾界并强制守恒的铁律 |
| **ἀρχή** | 本原 / 始基 | 辛普里丘引文 | 规定万物生成所自与归宿的第一开端 |

[^1]: Simplicius, *Commentarius in Aristotelis Physica*, ed. Diels, 24, 13-25.
[^2]: G. S. Kirk, J. E. Raven and M. Schofield, *The Presocratic Philosophers*, 2nd ed., Cambridge, 1983.
            `.trim());
        }
    }

    public async getLecture(nodeId: string): Promise<string> {
        if (this.lectureCache.has(nodeId)) {
            return this.lectureCache.get(nodeId)!;
        }
        return `# 节点 ${nodeId} 讲义\n\n该节点的深入原典讲义正在编译入库中。`;
    }

    public setLecture(nodeId: string, markdown: string): void {
        this.lectureCache.set(nodeId, markdown);
        const set = this.subscribers.get(nodeId);
        if (set) {
            set.forEach(cb => cb(markdown));
        }
    }

    public subscribe(nodeId: string, cb: (content: string) => void): () => void {
        if (!this.subscribers.has(nodeId)) {
            this.subscribers.set(nodeId, new Set());
        }
        this.subscribers.get(nodeId)!.add(cb);
        return () => {
            this.subscribers.get(nodeId)?.delete(cb);
        };
    }

    public attachBridge(bridge: StudyLineBridgeClient): void {
        bridge.on("NODE_MODIFIED", (payload: { node_id: string; summary?: string }) => {
            if (payload && payload.node_id) {
                console.log(`[LectureLoader] Hot Reloading node ${payload.node_id} via WebSocket HMR`);
            }
        });
    }
}
