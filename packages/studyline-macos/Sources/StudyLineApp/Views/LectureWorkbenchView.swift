// =============================================================================
// StudyLine macOS Native LectureWorkbenchView (Academic Markdown Reader)
// WSJ Editorial Typography × Typora Academic Fidelity × Bilingual Primary Source
// Fluid Liquid Glass Cards & Syllogism Formal Deduction
// =============================================================================

import SwiftUI
import AppKit

public struct LectureWorkbenchView: View {
    @Binding public var selectedNodeId: String
    @Binding public var isZenMode: Bool
    @Binding public var showInspector: Bool

    @State private var readingProgress: Double = 0.65

    public init(
        selectedNodeId: Binding<String>,
        isZenMode: Binding<Bool>,
        showInspector: Binding<Bool>
    ) {
        self._selectedNodeId = selectedNodeId
        self._isZenMode = isZenMode
        self._showInspector = showInspector
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 顶栏 (Y=90pt 金线绝对对齐)
            StudyLineHeaderBar(
                sectionName: selectedNodeId.hasPrefix("R") ? "RUST FIRST-PRINCIPLES WORKBENCH" : "PHILOSOPHY ACADEMIC WORKBENCH",
                title: selectedNodeId == "A04" ? "第 A04 讲 · 巴门尼德真理之路与存在论之锚" : (selectedNodeId == "R07" ? "第 R07 讲 · 从 C 语言缺陷到所有权发生学：UAF 与数据竞争" : "第 \(selectedNodeId) 讲 · 系统第一性原理研读"),
                badgeText: "Typora LaTeX"
            )

            // 阅读进度细线
            GeometryReader { geo in
                Rectangle()
                    .fill(selectedNodeId.hasPrefix("R") ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
                    .frame(width: geo.size.width * readingProgress, height: 2)
            }
            .frame(height: 2)

            // MARK: - 讲义正文滚动区域 (A4 版心 720pt 黄金宽度)
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. 讲义主标题区 (WSJ Editorial 典雅排版)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedNodeId.hasPrefix("R") ? "RUST 0段 · 物理内存与安全缺陷发生学" : "阶段A · 世界的质料与存在之锚")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .tracking(3)
                            .foregroundStyle(selectedNodeId.hasPrefix("R") ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)

                        Text(selectedNodeId == "A04" ? "巴门尼德真理之路与存在论之锚" : (selectedNodeId == "R07" ? "从 C 语言内存缺陷到所有权发生学：UAF 与数据竞争" : "第一性原理因果讲义"))
                            .font(StudyLineTheme.Typography.wsjHeadline)
                            .foregroundStyle(.primary)

                        Text("一手文献直读 · 形式化三段论推演 · 机器汇编映射")
                            .font(StudyLineTheme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 16)

                    // 2. 双语一手原典对照框 (Bilingual Primary Source Block)
                    if selectedNodeId == "A04" {
                        bilingualSourceBlock(
                            greekText: "ἔστι γὰρ εἶναι, μηδὲν δ' οὐκ ἔστιν· τά σ' ἐγὼ φράζεσθαι ἄνωγα.\nεἴργω γάρ σ' ἀπὸ τῆσδε πρωτίστης ὁδοῦ διζήσιος.",
                            translationText: "因为存在者存在，非存在者完全不可能存在；我命令你牢牢将这一真理印在心上。\n我要阻止你走那第一条探求之路。",
                            citation: "巴门尼德 · 《论自然》真理之路 DK 28 B6 (Simplicius Phys. 117, 4)"
                        )
                    } else {
                        bilingualSourceBlock(
                            greekText: "// C 缺陷: 指针别名与就地突变\nchar *buf = malloc(64);\nfree(buf);\n// UAF 漏洞 (CWE-416)\nprintf(\"%s\", buf);",
                            translationText: "通过仿射类型系统 (Affine Types)，Rust 证明了当资源所有权被销毁后，原指针变量永久失效，彻底阻断 UAF 与 Double Free 攻击面。",
                            citation: "RustBelt POPL 2018 · Iris 分离逻辑证明"
                        )
                    }

                    // 3. 形式化论证三段论卡片 (Syllogism Card)
                    syllogismCard(
                        p1: "大前提 (P1)：凡是能被思维和言说的对象，必须是某种‘存在者’（ἔστιν）；",
                        p2: "小前提 (P2)：‘非存在（无）’既不可被感知，也不可在思维中呈现（οὐκ ἔστιν）；",
                        reductio: "归谬推导 (R)：若主张‘非存在存在’或‘生成自非存在’，则必须思维‘无’，此举在逻辑上陷入自相矛盾；",
                        conclusion: "结论 (C)：存在者不生不灭、完整单一、连续不动，它是万物唯一稳固的形而上学之锚。"
                    )

                    // 4. 正文段落精读
                    VStack(alignment: .leading, spacing: 14) {
                        Text("第一性原理发生学剖析")
                            .font(StudyLineTheme.Typography.title1)
                            .foregroundStyle(.primary)

                        Text("在古希腊思想史上，爱利亚学派的巴门尼德完成了人类理性思维第一次惊心动魄的跃迁。他不再满足于米利都学派追问‘万物的质料是什么’（水、无定阿派朗、气、火），而是直接追问‘存在者本身的逻辑必然性’。")
                            .font(StudyLineTheme.Typography.body)
                            .lineSpacing(6)
                            .foregroundStyle(.primary.opacity(0.9))

                        Text("这一形而上学发现，与两千年后现代计算机体系结构中‘地址空间的确定性生命周期与仿射类型系统’具有惊人一致的形式化美感。")
                            .font(StudyLineTheme.Typography.body)
                            .lineSpacing(6)
                            .foregroundStyle(.primary.opacity(0.9))
                    }
                    .studylineLiquidGlass(cornerRadius: 14, padding: 18)

                    Spacer().frame(height: 60)
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 32)
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.clear)
    }

    // MARK: - 双语一手原典对照框
    private func bilingualSourceBlock(greekText: String, translationText: String, citation: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(StudyLineTheme.kintsugiGold)
                    Text("一手原典双语对照 (PRIMARY SOURCE)")
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(StudyLineTheme.kintsugiGold)
                }
                Spacer()
                Text(citation)
                    .font(StudyLineTheme.Typography.codeCaption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                // 左侧原典
                Text(greekText)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .lineSpacing(4)
                    .foregroundStyle(StudyLineTheme.kintsugiGold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.primary.opacity(0.025))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // 右侧中译
                Text(translationText)
                    .font(StudyLineTheme.Typography.body)
                    .lineSpacing(4)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.primary.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .studylineLiquidGlass(cornerRadius: 14, padding: 18)
    }

    // MARK: - 形式化三段论推演卡片
    private func syllogismCard(p1: String, p2: String, reductio: String, conclusion: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "function")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(StudyLineTheme.bambooGreen)
                Text("形式化哲学论证三段论 (FORMAL SYLLOGISM)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(StudyLineTheme.bambooGreen)
            }

            VStack(alignment: .leading, spacing: 8) {
                syllogismRow(tag: "P1", text: p1, color: StudyLineTheme.kintsugiGold)
                syllogismRow(tag: "P2", text: p2, color: StudyLineTheme.kintsugiGold)
                syllogismRow(tag: "R",  text: reductio, color: StudyLineTheme.cinnabarRed)
                syllogismRow(tag: "C",  text: conclusion, color: StudyLineTheme.bambooGreen)
            }
        }
        .studylineLiquidGlass(cornerRadius: 14, padding: 18)
    }

    private func syllogismRow(tag: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(tag)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            Text(text)
                .font(StudyLineTheme.Typography.body)
                .lineSpacing(2)
                .foregroundStyle(.primary.opacity(0.9))
        }
    }
}
