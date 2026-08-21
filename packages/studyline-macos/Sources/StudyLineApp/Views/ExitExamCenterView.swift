// =============================================================================
// StudyLine Exit Exam Center & Mastery Scorecard View
// Stage Exit Certification × Formal Reasoning Tests × Historical Mastery Radar
// =============================================================================

import SwiftUI

public struct ExitExamCardInfo: Identifiable {
    public var id: String { nodeId }
    public let nodeId: String
    public let title: String
    public let domain: String
    public let stage: String
    public let totalQuestions: Int
    public let passThreshold: String
    public let stars: Int
    public let lastScore: String?
}

public struct ExitExamCenterView: View {
    @Binding public var selectedNodeId: String
    @Binding public var isExamPresented: Bool

    @State private var examCards: [ExitExamCardInfo] = [
        ExitExamCardInfo(
            nodeId: "R13",
            title: "0段出段综合大考：计算机物理内存与安全发生学因果总闭环",
            domain: "rust",
            stage: "0段·物理内存",
            totalQuestions: 13,
            passThreshold: "80%",
            stars: 5,
            lastScore: "100%"
        ),
        ExitExamCardInfo(
            nodeId: "R50",
            title: "阶段A出段综合大考：所有权三大定律、借用检查器与生命周期",
            domain: "rust",
            stage: "阶段A·所有权与生命周期",
            totalQuestions: 10,
            passThreshold: "80%",
            stars: 4,
            lastScore: "90%"
        ),
        ExitExamCardInfo(
            nodeId: "R100",
            title: "阶段C暨Rust大系终极大考：异步状态机、Pin钉住与Unsafe形式化模型",
            domain: "rust",
            stage: "阶段C·并发、异步与Unsafe",
            totalQuestions: 15,
            passThreshold: "85%",
            stars: 0,
            lastScore: nil
        ),
        ExitExamCardInfo(
            nodeId: "philosophy.stage0.season-grand-synthesis",
            title: "0段出段大考：古希腊神话宇宙论、悲剧城邦正义与语言发生学",
            domain: "philosophy",
            stage: "0段·神话与悲剧",
            totalQuestions: 20,
            passThreshold: "80%",
            stars: 5,
            lastScore: "95%"
        )
    ]

    public init(selectedNodeId: Binding<String>, isExamPresented: Binding<Bool>) {
        self._selectedNodeId = selectedNodeId
        self._isExamPresented = isExamPresented
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. 顶部 Header 状态横幅
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(StudyLineTheme.cinnabarRed)
                                .font(.system(size: 20))
                            Text("出段大考与掌握度认证中枢")
                                .font(StudyLineTheme.Typography.displayTitle)
                                .foregroundColor(.white)
                        }
                        Text("基于形式化论证重构与硬件因果律的闭卷严格考核 · 达标即授掌握度星级")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                // 2. 考核卡片列表
                VStack(spacing: 16) {
                    ForEach(examCards) { card in
                        examCardRow(card: card)
                    }
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 40)
            }
        }
    }

    private func examCardRow(card: ExitExamCardInfo) -> some View {
        HStack(spacing: 20) {
            // 左侧状态徽章
            ZStack {
                Circle()
                    .fill(card.domain == "rust" ? StudyLineTheme.cosmicUltramarine.opacity(0.8) : StudyLineTheme.bambooGreen.opacity(0.8))
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(StudyLineTheme.kintsugiGold, lineWidth: 1.5))

                Image(systemName: card.stars > 0 ? "checkmark.seal.fill" : "lock.open.fill")
                    .font(.system(size: 22))
                    .foregroundColor(card.stars > 0 ? StudyLineTheme.kintsugiGold : .white.opacity(0.7))
            }

            // 中间元数据
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("[\(card.nodeId)]")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyLineTheme.kintsugiGold)
                    Text(card.stage)
                        .font(.system(size: 11))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.white.opacity(0.8))
                }

                Text(card.title)
                    .font(StudyLineTheme.Typography.title1)
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    Text("题量: \(card.totalQuestions) 题")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Text("及格线: \(card.passThreshold)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    if let score = card.lastScore {
                        Text("最高得分: \(score)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(StudyLineTheme.bambooGreen)
                    }
                }
            }

            Spacer()

            // 右侧星级与开始按钮
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { idx in
                        Image(systemName: idx < card.stars ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(idx < card.stars ? StudyLineTheme.kintsugiGold : .white.opacity(0.2))
                    }
                }

                Button("开始出段大考 ➔") {
                    selectedNodeId = card.nodeId
                    isExamPresented = true
                }
                .buttonStyle(.borderedProminent)
                .tint(StudyLineTheme.cinnabarRed)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.45))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(StudyLineTheme.kintsugiGold.opacity(0.3), lineWidth: 0.8))
        )
    }
}
