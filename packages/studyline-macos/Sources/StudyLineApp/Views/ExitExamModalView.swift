// =============================================================================
// StudyLine macOS Native Exit Exam Modal View (640pt × 520pt Liquid Glass)
// Integrated with NSHapticFeedbackManager and TTZip Zen Design System
// =============================================================================

import SwiftUI
import AppKit

public struct ExamQuestionModel: Identifiable {
    public let id: String
    public let prompt: String
    public let options: [String]
    public let correctIndex: Int
}

public struct ExitExamModalView: View {
    @Binding public var isPresented: Bool
    @State private var activeQuestionIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var isSubmitted: Bool = false
    @State private var score: Int = 0

    private let questions: [ExamQuestionModel] = [
        ExamQuestionModel(
            id: "Q1",
            prompt: "阿那克西曼德 DK 12 B1 中，事物向彼此支付赔偿（δίκη καὶ τίσις）的原因是什么？",
            options: [
                "因为事物侵占了神圣祭坛",
                "因为单一元素在生成中逾界侵犯对方，构成 ἀδικία",
                "因为城邦法官下达了强制死刑判决",
                "因为四根被爱憎力量彻底撕裂"
            ],
            correctIndex: 1
        ),
        ExamQuestionModel(
            id: "Q2",
            prompt: "赫西俄德《劳作与时日》中，将 Ἔρις（争斗）一分为二的哲学动机是什么？",
            options: [
                "区分健康的劳动竞争与破坏性的诉讼掠夺",
                "区分奥林匹斯神与提坦神",
                "区分男人与女人的城邦分工",
                "区分诗歌灵感与神谕真理"
            ],
            correctIndex: 0
        )
    ]

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    private var currentQuestion: ExamQuestionModel {
        questions[activeQuestionIndex]
    }

    public var body: some View {
        ZStack {
            // 半透明遮罩
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // 640x520pt 液态玻璃模态框
            VStack(spacing: 0) {
                // Header Bar (52pt)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("EXIT_EXAM_SYSTEM")
                            .font(.system(size: 9, weight: .bold, design: .serif))
                            .tracking(2)
                            .foregroundStyle(TTZipTheme.kintsugiGold)
                        Text("阶段出段综合大考")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.system(size: 10))
                            .foregroundStyle(TTZipTheme.bambooGreen)
                        Text("第 \(activeQuestionIndex + 1)/\(questions.count) 题")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(TTZipTheme.bambooGreen)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(TTZipTheme.bambooGreen.opacity(0.12))
                    .clipShape(Capsule())

                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.gray.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .frame(height: 52)

                // 1.5pt 金线
                Rectangle()
                    .fill(TTZipTheme.kintsugiGold)
                    .frame(height: 1.5)

                // 题目内容区
                VStack(alignment: .leading, spacing: 20) {
                    Text(currentQuestion.prompt)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineSpacing(4)

                    VStack(spacing: 10) {
                        ForEach(0..<currentQuestion.options.count, id: \.self) { idx in
                            let isSelected = selectedOptionIndex == idx
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(isSelected ? TTZipTheme.kintsugiGold : Color.clear)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(isSelected ? TTZipTheme.kintsugiGold : Color.gray.opacity(0.5), lineWidth: 1.5))

                                Text(currentQuestion.options[idx])
                                    .font(.system(size: 13))
                                    .foregroundStyle(isSelected ? TTZipTheme.kintsugiGold : .primary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(isSelected ? TTZipTheme.kintsugiGold.opacity(0.08) : Color.primary.opacity(0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(isSelected ? TTZipTheme.kintsugiGold : TTZipTheme.hairlineBorder, lineWidth: 0.8))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedOptionIndex = idx
                                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                            }
                        }
                    }

                    Spacer()

                    // 底部操作栏
                    if isSubmitted {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(TTZipTheme.bambooGreen)
                                .font(.system(size: 20))
                            Text("考核通过！得分：\(score) 分 (出段判据满足)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(TTZipTheme.bambooGreen)
                            Spacer()
                            Button("完成 (↵)") {
                                isPresented = false
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(TTZipTheme.bambooGreen)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                        }
                    } else {
                        HStack {
                            Text("[快捷键: 1-4 选择答案 │ 回车提交]")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("提交试卷 (↵)") {
                                submitExam()
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 7)
                            .background(selectedOptionIndex != nil ? TTZipTheme.bambooGreen : Color.gray.opacity(0.3))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .buttonStyle(.plain)
                            .disabled(selectedOptionIndex == nil)
                        }
                    }
                }
                .padding(24)
            }
            .frame(width: 640, height: 520)
            .background(
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .overlay(Color.primary.opacity(0.025))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))
            .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
        }
    }

    private func submitExam() {
        if selectedOptionIndex == currentQuestion.correctIndex {
            score = 100
        } else {
            score = 50
        }
        isSubmitted = true
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}
