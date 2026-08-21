// =============================================================================
// StudyLine macOS Native LectureWorkbenchView (Academic Markdown Reader)
// WSJ Editorial Typography × Typora Academic Fidelity × Bilingual Primary Source
// Fluid Liquid Glass Cards & Syllogism Formal Deduction
// Dynamically reads real physical `index.md` from the Git Monorepo
// =============================================================================

import SwiftUI
import AppKit

public struct LectureWorkbenchView: View {
    @Binding public var selectedNodeId: String
    @Binding public var isZenMode: Bool
    @Binding public var showInspector: Bool

    @ObservedObject private var repo = StudyLineDomainRepository.shared
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

    private var currentNode: DynamicNode? {
        repo.allNodes.first(where: { $0.id == selectedNodeId })
    }

    private var nodeIndex: Int {
        repo.allNodes.firstIndex(where: { $0.id == selectedNodeId }) ?? 0
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - 顶栏 (Y=90pt 金线绝对对齐)
            StudyLineHeaderBar(
                sectionName: selectedNodeId.hasPrefix("R") ? "RUST FIRST-PRINCIPLES WORKBENCH" : "PHILOSOPHY ACADEMIC WORKBENCH",
                title: "第 \(selectedNodeId) 讲 · \(currentNode?.title ?? "第一性原理研读")",
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
                        HStack(spacing: 8) {
                            Text(currentNode?.stage ?? "第一性原理阶段")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .tracking(3)
                                .foregroundStyle(selectedNodeId.hasPrefix("R") ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)

                            Spacer()

                            Text("节点 \(nodeIndex + 1) / \(repo.allNodes.count)")
                                .font(StudyLineTheme.Typography.codeCaption)
                                .foregroundStyle(.tertiary)
                        }

                        Text(currentNode?.title ?? "第一性原理因果讲义")
                            .font(StudyLineTheme.Typography.wsjHeadline)
                            .foregroundStyle(.primary)

                        Text(currentNode?.summary ?? "一手文献直读 · 形式化三段论推演 · 机器汇编与物理内存映射")
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
                    } else if selectedNodeId.hasPrefix("R") {
                        bilingualSourceBlock(
                            greekText: "// Rust 核心安全定理: 仿射类型系统 (Affine Types)\npub const fn forget<T>(t: T) {\n    let _ = ManuallyDrop::new(t);\n}",
                            translationText: "变量占用的栈空间在函数返回时通过 `add rsp, N` 单周期正常销毁，但其管理的堆内存被移出析构管线，证明了所有权与硬件栈帧的确定性分离。",
                            citation: "Rust 标准库 · library/core/src/mem/mod.rs"
                        )
                    } else {
                        bilingualSourceBlock(
                            greekText: "ἤτοι μὲν πρώτιστα Χάος γένετ' αὐτὰρ ἔπειτα\nΓαῖ' εὐρύστερνος, πάντων ἕδος ἀσφαλὲς αἰεὶ",
                            translationText: "最初生成的是卡俄斯（原初裂开的虚空），接着是宽胸的大地（盖亚），万物永远稳固的居所。",
                            citation: "赫西俄德 · 《神谱》116-118行"
                        )
                    }

                    // 3. 形式化论证三段论卡片 (Syllogism Card)
                    syllogismCard(
                        p1: selectedNodeId.hasPrefix("R") ? "物理事实 (P1)：CPU 以 64 字节 Cache Line 访问内存，栈帧连续分配天然命中 L1 缓存；" : "大前提 (P1)：凡是能被思维和言说的对象，必须是某种‘存在者’（ἔστιν）；",
                        p2: selectedNodeId.hasPrefix("R") ? "系统约束 (P2)：C 语言允许指针任意别名与就地突变，引发 UAF 与数据竞争；" : "小前提 (P2)：‘非存在（无）’既不可被感知，也不可在思维中呈现（οὐκ ἔστιν）；",
                        reductio: selectedNodeId.hasPrefix("R") ? "归谬推导 (R)：若不引入编译期仿射类型系统，程序必须在运行期付出 GC STW 停顿或面临安全漏洞；" : "归谬推导 (R)：若主张‘非存在存在’或‘生成自非存在’，则必须思维‘无’，在逻辑上陷入自相矛盾；",
                        conclusion: selectedNodeId.hasPrefix("R") ? "结论 (C)：Rust 的别名异或可变性定理在编译期同时锁死内存安全与零成本汇编优化。" : "结论 (C)：存在者不生不灭、完整单一、连续不动，它是万物唯一稳固的形而上学之锚。"
                    )

                    // 4. 真实物理 Markdown 讲义渲染区
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(StudyLineTheme.cosmicUltramarine)
                            Text("CANONICAL LECTURE TEXT (物理磁盘真实讲义)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(currentNode?.markdownPath.components(separatedBy: "/").suffix(2).joined(separator: "/") ?? "index.md")
                                .font(StudyLineTheme.Typography.codeCaption)
                                .foregroundStyle(.tertiary)
                        }

                        Text(repo.loadNodeMarkdown(id: selectedNodeId))
                            .font(StudyLineTheme.Typography.body)
                            .lineSpacing(6)
                            .foregroundStyle(.primary.opacity(0.92))
                            .textSelection(.enabled)
                    }
                    .studylineLiquidGlass(cornerRadius: 14, padding: 20)

                    // 5. 实时编程沙盒与运行控制台 (Live Code Playground)
                    LiveCodePlaygroundView(nodeId: selectedNodeId)

                    // 6. 底部连贯学线跳转按钮 (Previous / Next Lesson)
                    HStack {
                        if nodeIndex > 0 {
                            Button(action: {
                                selectedNodeId = repo.allNodes[nodeIndex - 1].id
                                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.left")
                                    Text("上一讲: \(repo.allNodes[nodeIndex - 1].id)")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.primary.opacity(0.04))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        if nodeIndex + 1 < repo.allNodes.count {
                            Button(action: {
                                selectedNodeId = repo.allNodes[nodeIndex + 1].id
                                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                            }) {
                                HStack(spacing: 6) {
                                    Text("下一讲: \(repo.allNodes[nodeIndex + 1].id) ➔")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(StudyLineTheme.bambooGreen)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: StudyLineTheme.bambooGreen.opacity(0.35), radius: 6, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)

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
                Text("形式化论证三段论 (FORMAL SYLLOGISM)")
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
