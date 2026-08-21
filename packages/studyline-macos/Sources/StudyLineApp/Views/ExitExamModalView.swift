// =============================================================================
// StudyLine macOS Native ExitExamModalView (出段大考模态视口)
// 640x520pt Liquid Glass Modal × Dynamic Haptic Feedback × Syllogism Verification
// =============================================================================

import SwiftUI
import AppKit

public struct ExamQuestion: Identifiable {
    public let id: Int
    public let title: String
    public let prompt: String
    public let options: [String]
    public let correctIndex: Int
    public let explanation: String
}

public struct ExitExamModalView: View {
    @Binding public var isPresented: Bool

    @State private var currentQuestionIndex: Int = 0
    @State private var selectedOption: Int? = nil
    @State private var isSubmitted: Bool = false
    @State private var score: Int = 0
    @State private var isCompleted: Bool = false

    public let questions: [ExamQuestion] = [
        ExamQuestion(
            id: 1,
            title: "0段因果论证 · 赫西俄德神谱始基",
            prompt: "在《神谱》116-122行中，关于卡俄斯（Χάος）的生成，下列哪项第一性原理推演完全符合一手文献？",
            options: [
                "A. 卡俄斯是由无定（ἄπειρον）在时间秩序下因不义而分裂出的第一质料",
                "B. 卡俄斯是‘裂开的深渊与原初虚空’（动词 chasko），它是万物分化生成的物理与几何容器空间",
                "C. 卡俄斯是宙斯用闪电击碎克罗诺斯后创造出的神圣正义（δίκη）秩序",
                "D. 卡俄斯是乌拉诺斯被阉割后生殖器落入大海泛起的白色泡沫"
            ],
            correctIndex: 1,
            explanation: "词源考证：Χάος 派生自动词 χάσκω（裂开/敞开），指天地未分时的原初裂隙容器空间，而非现代语义中的混乱或无中生有神创。"
        ),
        ExamQuestion(
            id: 2,
            title: "阶段A本体论 · 巴门尼德真理之路",
            prompt: "巴门尼德在 DK 28 B2/B6 中给出‘思维与存在同一（τὸ γὰρ αὐτὸ νοεῖν ἐστίν τε καὶ εἶναι）’的形式化归谬证明，其核心逻辑是什么？",
            options: [
                "A. 因为非存在（无）不可被思维和言说，一旦试图思维‘无’，‘无’就成了思维的对象（有），故非存在在逻辑上不可能存在",
                "B. 因为神灵通过赫拉的孔雀将存在者的真理直接启示给了沉睡的哲学家",
                "C. 因为万物都是永恒活火按尺度点燃与熄灭的产物，相反者斗争构成了一",
                "D. 因为数字是一切事物的本原，点线面体构成了球形宇宙"
            ],
            correctIndex: 0,
            explanation: "排中律与反证法归谬：凡能被思维与言说的必是存在者，非存在（无）不可思议、不可言说，因此‘生成与毁灭’皆为虚妄幻觉。"
        ),
        ExamQuestion(
            id: 3,
            title: "Rust 系统内存 · 仿射类型系统证明",
            prompt: "在 Rust 内存模型与 POPL 2018 Iris 分离逻辑证明中，‘别名异或可变性（Aliasing XOR Mutability）’的根本意义是什么？",
            options: [
                "A. 允许垃圾回收器在后台 STW 停顿时任意移动指针地址",
                "B. 在同一时空内禁止同时存在共享只读与排他可变，既在编译期根除 UAF/数据竞争，又为 LLVM noalias 激进指令重排提供数学保证",
                "C. 强行将所有堆内存分配重定向到操作系统栈帧顶端",
                "D. 禁用所有的裸指针与汇编内联操作"
            ],
            correctIndex: 1,
            explanation: "数学保证：∀x, (Shared(x) ∧ ¬Mutable(x)) ⊕ (Mutable(x) ∧ Unique(x))，同时锁死内存安全与编译器极端优化潜力。"
        )
    ]

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            // 背景压暗与触觉阻断
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            // 640x540pt 核心液态磨砂大考模态卡片
            VStack(spacing: 0) {
                // 模态顶栏
                HStack(spacing: 10) {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(StudyLineTheme.bambooGreen)

                    Text("STUDYLINE EXIT EXAM ARENA")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(StudyLineTheme.bambooGreen)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(StudyLineTheme.hairlineBorder)
                    .frame(height: 0.8)

                if !isCompleted {
                    examBodyView
                } else {
                    examResultView
                }
            }
            .frame(width: 640, height: 520)
            .studylineLiquidGlass(cornerRadius: StudyLineTheme.Radius.xxl, padding: 0)
            .shadow(color: Color.black.opacity(0.4), radius: 24, y: 12)
        }
    }

    // MARK: - 答题面板
    private var examBodyView: some View {
        let q = questions[currentQuestionIndex]

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("问题 \(currentQuestionIndex + 1) / \(questions.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(StudyLineTheme.kintsugiGold)

                Spacer()

                Text(q.title)
                    .font(StudyLineTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(q.prompt)
                .font(StudyLineTheme.Typography.title2)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // 选项列表
            VStack(spacing: 8) {
                ForEach(0..<q.options.count, id: \.self) { idx in
                    let opt = q.options[idx]
                    Button(action: {
                        if !isSubmitted {
                            selectedOption = idx
                            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                        }
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .strokeBorder(selectedOption == idx ? StudyLineTheme.kintsugiGold : StudyLineTheme.hairlineBorder, lineWidth: selectedOption == idx ? 4 : 1)
                                .frame(width: 14, height: 14)
                                .padding(.top, 2)

                            Text(opt)
                                .font(StudyLineTheme.Typography.callout)
                                .foregroundStyle(.primary)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                        .padding(12)
                        .background(selectedOption == idx ? StudyLineTheme.kintsugiGold.opacity(0.12) : Color.primary.opacity(0.025))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(selectedOption == idx ? StudyLineTheme.kintsugiGold.opacity(0.4) : StudyLineTheme.hairlineBorder, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // 底部操作栏
            HStack {
                Spacer()

                Button(action: {
                    if let selected = selectedOption {
                        if selected == q.correctIndex {
                            score += 1
                        }
                        if currentQuestionIndex + 1 < questions.count {
                            currentQuestionIndex += 1
                            selectedOption = nil
                        } else {
                            isCompleted = true
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(currentQuestionIndex + 1 == questions.count ? "完成大考结算" : "下一题")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(selectedOption != nil ? StudyLineTheme.bambooGreen : Color.secondary.opacity(0.2))
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(selectedOption == nil)
            }
        }
        .padding(24)
    }

    // MARK: - 结算报告面板
    private var examResultView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: score == questions.count ? "laurel.leading" : "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(StudyLineTheme.kintsugiGold)

            Text(score == questions.count ? "出段大考满分通过！" : "考核完成")
                .font(StudyLineTheme.Typography.displayTitle)
                .foregroundStyle(.primary)

            Text("得分：\(score) / \(questions.count) · 获得【巴门尼德存在论与仿射内存大师】金缮勋章")
                .font(StudyLineTheme.Typography.body)
                .foregroundStyle(.secondary)

            Spacer()

            Button("返回研读宇宙") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(StudyLineTheme.bambooGreen)
            .foregroundStyle(Color.white)
            .clipShape(Capsule())
            .shadow(color: StudyLineTheme.bambooGreen.opacity(0.35), radius: 8, y: 3)

            Spacer().frame(height: 10)
        }
        .padding(24)
    }
}
