// =============================================================================
// StudyLine macOS Native Universe Home Portal (知识宇宙控制台主页)
// Hero Panorama × Resume Card × Bento Grid Domains × Daily Epigram
// =============================================================================

import SwiftUI
import AppKit

public struct UniverseHomeView: View {
    @Binding public var selectedNodeId: String
    @Binding public var currentTab: AppTab
    @Binding public var isExamPresented: Bool

    @State private var epigram: EpigramItem = DailyEpigramEngine.todayEpigram()
    @State private var searchQuery: String = ""

    public init(
        selectedNodeId: Binding<String>,
        currentTab: Binding<AppTab>,
        isExamPresented: Binding<Bool>
    ) {
        self._selectedNodeId = selectedNodeId
        self._currentTab = currentTab
        self._isExamPresented = isExamPresented
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 28) {
                
                // 1. Hero 宏观控制台概览 (Header Panorama)
                heroSection

                // 2. Resume Learning 快速续读主卡 (Continue Reading Card)
                resumeLearningCard

                // 3. Bento Grid 领域知识矩阵 (Domain Bento Cards)
                bentoDomainsGrid

                // 4. Daily Epigram 每日一手原典思维火花
                dailyEpigramCard

                // 底部留白
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
        }
        .background(Color.clear)
    }

    // MARK: - 1. Hero 宏观控制台概览
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UNIVERSAL KNOWLEDGE DASHBOARD")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .tracking(3)
                        .foregroundStyle(TTZipTheme.kintsugiGold)

                    Text("知识宇宙控制台")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)

                    Text("跨越古希腊本体论哲学与系统级 Rust 硬件内存模型的因果拓扑中枢")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 快速全域统计徽章
                HStack(spacing: 16) {
                    statCapsule(title: "全库知识点", value: "126+", icon: "sparkles", color: TTZipTheme.kintsugiGold)
                    statCapsule(title: "掌握度星级", value: "48★", icon: "star.fill", color: TTZipTheme.kintsugiGold)
                    statCapsule(title: "连续研读", value: "7 天", icon: "flame.fill", color: TTZipTheme.cinnabarRed)
                }
            }
        }
        .padding(24)
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow))
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(TTZipTheme.kintsugiGold.opacity(0.35), lineWidth: 1)
        )
    }

    private func statCapsule(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))
    }

    // MARK: - 2. Resume Learning 快速续读主卡
    private var resumeLearningCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(TTZipTheme.bambooGreen)
                        .frame(width: 8, height: 8)
                    Text("最近研读断点 (RESUME LEARNING)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(TTZipTheme.bambooGreen)
                }

                Spacer()

                Text("上次学习于 2 小时前")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(selectedNodeId.hasPrefix("R") ? "RUST 系统大系" : "古希腊哲学史大系")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(selectedNodeId.hasPrefix("R") ? TTZipTheme.bambooGreen.opacity(0.15) : TTZipTheme.kintsugiGold.opacity(0.15))
                            .foregroundStyle(selectedNodeId.hasPrefix("R") ? TTZipTheme.bambooGreen : TTZipTheme.kintsugiGold)
                            .clipShape(Capsule())

                        Text("第 \(selectedNodeId) 讲")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Text(selectedNodeId == "A04" ? "巴门尼德真理之路与存在论之锚" : (selectedNodeId == "R07" ? "从 C 语言内存缺陷到所有权发生学：UAF 与数据竞争" : "物理内存与类型系统形式化证明"))
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)

                    Text("当前阶段研读进度 65% · 已完成前置因果证明推演")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 继续研读主按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentTab = .workbench
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("继续研读 (↵)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(TTZipTheme.bambooGreen)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: TTZipTheme.bambooGreen.opacity(0.3), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow))
        .background(Color.primary.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(TTZipTheme.bambooGreen.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 3. Bento Grid 领域知识矩阵
    private var bentoDomainsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DOMAINS & ACADEMIC PATHWAYS")
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundStyle(TTZipTheme.kintsugiGold)

            HStack(spacing: 18) {
                // 领域 1: 古希腊哲学史大系
                domainBentoCard(
                    domainName: "古希腊哲学史大系",
                    tag: "94期全景 · 32期深度",
                    headline: "从神话宇宙论到爱利亚一元论",
                    description: "赫西俄德神谱、荷马正义分配、悲剧司法与巴门尼德存在论之锚。",
                    nodeCount: "126 讲义",
                    accentColor: TTZipTheme.kintsugiGold,
                    icon: "building.columns.fill",
                    targetNode: "A04"
                )

                // 领域 2: Rust 系统级第一性原理大系
                domainBentoCard(
                    domainName: "Rust 系统级第一性原理大系",
                    tag: "100 讲全景因果大系",
                    headline: "物理内存、仿射类型与无畏并发",
                    description: "从 C 语言 UAF 崩溃到仿射逻辑、NLL Polonius、Pin 钉住证明与 Miri 模型。",
                    nodeCount: "100 讲义",
                    accentColor: TTZipTheme.bambooGreen,
                    icon: "cpu.fill",
                    targetNode: "R01"
                )
            }
        }
    }

    private func domainBentoCard(
        domainName: String,
        tag: String,
        headline: String,
        description: String,
        nodeCount: String,
        accentColor: Color,
        icon: String,
        targetNode: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accentColor)

                Text(tag)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.12))
                    .foregroundStyle(accentColor)
                    .clipShape(Capsule())

                Spacer()

                Text(nodeCount)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(domainName)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)

                Text(headline)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            Button(action: {
                selectedNodeId = targetNode
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentTab = .workbench
                }
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            }) {
                HStack {
                    Text("探索领域学线")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(accentColor.opacity(0.3), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow))
        .background(Color.primary.opacity(0.025))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - 4. 每日一手原典思维火花
    private var dailyEpigramCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(TTZipTheme.kintsugiGold)
                    Text("DAILY FIRST-PRINCIPLES EPIGRAM (每日一手原典)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(TTZipTheme.kintsugiGold)
                }

                Spacer()

                Text(epigram.domain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // 原典原文字段 (古希腊文或标准库原典)
            Text(epigram.primaryText)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .italic()
                .lineSpacing(4)
                .foregroundStyle(TTZipTheme.kintsugiGold)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(TTZipTheme.kintsugiGold.opacity(0.25), lineWidth: 0.8))

            // 权威学术中译
            Text(epigram.translationCn)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.primary)
                .lineSpacing(3)

            HStack {
                Text(epigram.citation)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(epigram.insight)
                    .font(.system(size: 11))
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow))
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8)
        )
    }
}
