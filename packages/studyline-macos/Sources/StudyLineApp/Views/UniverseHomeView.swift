// =============================================================================
// StudyLine macOS Native Universe Home Portal (知识宇宙控制台主页)
// Hero Panorama × Resume Card × Bento Grid Domains × Daily Epigram
// Dynamically driven by StudyLineDomainRepository (Real Git Monorepo Data)
// =============================================================================

import SwiftUI
import AppKit

public struct UniverseHomeView: View {
    @Binding public var selectedNodeId: String
    @Binding public var currentTab: AppTab
    @Binding public var isExamPresented: Bool

    @ObservedObject private var repo = StudyLineDomainRepository.shared
    @State private var epigram: EpigramItem = DailyEpigramEngine.todayEpigram()
    @State private var showRustSyllabusSheet: Bool = false

    public init(
        selectedNodeId: Binding<String>,
        currentTab: Binding<AppTab>,
        isExamPresented: Binding<Bool>
    ) {
        self._selectedNodeId = selectedNodeId
        self._currentTab = currentTab
        self._isExamPresented = isExamPresented
    }

    private var rustDomain: DynamicDomain? {
        repo.domains.first(where: { $0.id == "rust" })
    }

    private var philDomain: DynamicDomain? {
        repo.domains.first(where: { $0.id == "philosophy" })
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. Hero 宏观控制台概览 (Header Panorama)
                heroSection

                // 2. Resume Learning 快速续读主卡 (Continue Reading Card)
                resumeLearningCard

                // 3. Bento Grid 领域知识矩阵 (Domain Bento Cards)
                bentoDomainsGrid

                // 4. Daily Epigram 每日一手原典思维火花
                dailyEpigramCard

                // 底部留白
                Spacer().frame(height: 36)
            }
            .padding(.horizontal, 36)
            .padding(.top, 24)
        }
        .background(Color.clear)
        .sheet(isPresented: $showRustSyllabusSheet) {
            rustSyllabusModalView
        }
    }

    // MARK: - 1. Hero 宏观控制台概览
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(StudyLineTheme.cosmicUltramarine)
                            .frame(width: 7, height: 7)
                        Text("UNIVERSAL KNOWLEDGE DASHBOARD")
                            .font(.system(size: 9, weight: .bold, design: .serif))
                            .tracking(3)
                            .foregroundStyle(StudyLineTheme.cosmicUltramarine)
                    }

                    Text("知识宇宙控制台")
                        .font(StudyLineTheme.Typography.wsjHeadline)
                        .foregroundStyle(.primary)

                    Text("跨越古希腊本体论哲学与系统级 Rust 硬件内存模型的因果拓扑中枢")
                        .font(StudyLineTheme.Typography.body)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 快速全域统计徽章 (从 Git 物理磁盘动态统计)
                HStack(spacing: 12) {
                    statCapsule(title: "全库讲义", value: "\(repo.allNodes.count) 讲", icon: "sparkles", color: StudyLineTheme.kintsugiGold)
                    statCapsule(title: "掌握星级", value: "48★", icon: "star.fill", color: StudyLineTheme.kintsugiGold)
                    statCapsule(title: "研读天数", value: "7 天", icon: "flame.fill", color: StudyLineTheme.cinnabarRed)
                }
            }
        }
        .studylineLiquidGlass(cornerRadius: StudyLineTheme.Radius.xl, padding: 22)
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
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(StudyLineTheme.hairlineBorder, lineWidth: 0.5))
    }

    // MARK: - 2. Resume Learning 快速续读主卡
    private var resumeLearningCard: some View {
        let activeNode = repo.allNodes.first(where: { $0.id == selectedNodeId }) ?? repo.allNodes.first

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(StudyLineTheme.bambooGreen)
                        .frame(width: 8, height: 8)
                    Text("最近研读断点 (RESUME LEARNING)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(StudyLineTheme.bambooGreen)
                }

                Spacer()

                Text("上次学习于 2 小时前")
                    .font(StudyLineTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(selectedNodeId.hasPrefix("R") ? "RUST 系统大系" : "古希腊哲学史大系")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(selectedNodeId.hasPrefix("R") ? StudyLineTheme.bambooGreen.opacity(0.14) : StudyLineTheme.kintsugiGold.opacity(0.14))
                            .foregroundStyle(selectedNodeId.hasPrefix("R") ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
                            .clipShape(Capsule())

                        Text("第 \(selectedNodeId) 讲")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Text(activeNode?.title ?? "第一性原理因果研读")
                        .font(StudyLineTheme.Typography.title1)
                        .foregroundStyle(.primary)

                    Text(activeNode?.summary ?? "当前阶段研读进度 65% · 已完成前置因果证明推演")
                        .font(StudyLineTheme.Typography.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 继续研读主按钮
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
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
                    .padding(.vertical, 10)
                    .background(StudyLineTheme.bambooGreen)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: StudyLineTheme.bambooGreen.opacity(0.35), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .studylineLiquidGlass(cornerRadius: StudyLineTheme.Radius.xl, padding: 20)
    }

    // MARK: - 3. Bento Grid 领域知识矩阵
    private var bentoDomainsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DOMAINS & ACADEMIC PATHWAYS")
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundStyle(StudyLineTheme.kintsugiGold)

            HStack(spacing: 18) {
                // 领域 1: 古希腊哲学史大系
                domainBentoCard(
                    domainName: "古希腊哲学史大系",
                    tag: "\(philDomain?.totalNodeCount ?? 94) 讲全景因果",
                    headline: "从神话宇宙论到爱利亚一元论",
                    description: "赫西俄德神谱、荷马正义分配、悲剧司法与巴门尼德存在论之锚。",
                    nodeCount: "\(philDomain?.totalNodeCount ?? 94) 讲义",
                    accentColor: StudyLineTheme.kintsugiGold,
                    icon: "building.columns.fill",
                    targetNode: "E01",
                    onShowSyllabus: nil
                )

                // 领域 2: Rust 系统级第一性原理大系
                domainBentoCard(
                    domainName: "Rust 系统级第一性原理大系",
                    tag: "\(rustDomain?.totalNodeCount ?? 100) 讲系统大系",
                    headline: "物理内存、仿射类型与无畏并发",
                    description: "从 C 语言 UAF 崩溃到仿射逻辑、NLL Polonius、Pin 钉住证明与 Miri 模型。",
                    nodeCount: "\(rustDomain?.totalNodeCount ?? 100) 讲义",
                    accentColor: StudyLineTheme.bambooGreen,
                    icon: "cpu.fill",
                    targetNode: "R01",
                    onShowSyllabus: { showRustSyllabusSheet = true }
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
        targetNode: String,
        onShowSyllabus: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .font(StudyLineTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(domainName)
                    .font(StudyLineTheme.Typography.title1)
                    .foregroundStyle(.primary)

                Text(headline)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            Text(description)
                .font(StudyLineTheme.Typography.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            HStack(spacing: 8) {
                // 主入口: 从第 1 讲开始
                Button(action: {
                    selectedNodeId = targetNode
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        currentTab = .workbench
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }) {
                    HStack {
                        Text(targetNode.hasPrefix("R") ? "从第 1 讲开始研读 (R01)" : "探索领域学线")
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: accentColor.opacity(0.3), radius: 6, y: 2)
                }
                .buttonStyle(.plain)

                if let showSyllabus = onShowSyllabus {
                    Button(action: {
                        showSyllabus()
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.rectangle.portrait")
                            Text("课程大纲")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(StudyLineTheme.hairlineBorder, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 210)
        .studylineLiquidGlass(cornerRadius: StudyLineTheme.Radius.xl, padding: 18)
    }

    // MARK: - 4. 每日一手原典思维火花
    private var dailyEpigramCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(StudyLineTheme.kintsugiGold)
                    Text("DAILY FIRST-PRINCIPLES EPIGRAM (每日一手原典)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(StudyLineTheme.kintsugiGold)
                }

                Spacer()

                Text(epigram.domain)
                    .font(StudyLineTheme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            // 原典原文字段
            Text(epigram.primaryText)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .lineSpacing(4)
                .foregroundStyle(StudyLineTheme.kintsugiGold)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(StudyLineTheme.kintsugiGold.opacity(0.25), lineWidth: 0.6))

            // 权威学术中译
            Text(epigram.translationCn)
                .font(StudyLineTheme.Typography.body)
                .foregroundStyle(.primary)
                .lineSpacing(3)

            HStack {
                Text(epigram.citation)
                    .font(StudyLineTheme.Typography.codeCaption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(epigram.insight)
                    .font(StudyLineTheme.Typography.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
        .studylineLiquidGlass(cornerRadius: StudyLineTheme.Radius.xl, padding: 20)
    }

    // MARK: - Rust 100 讲大系专属路线图模态
    private var rustSyllabusModalView: some View {
        ZStack {
            StudyLineFluidBackgroundView(
                primaryColor: StudyLineTheme.bambooGreen,
                secondaryColor: StudyLineTheme.kintsugiGold,
                accentColor: StudyLineTheme.cosmicUltramarine
            )
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(StudyLineTheme.bambooGreen)
                        Text("Rust 系统级第一性原理大系 · 全景因果路线图")
                            .font(StudyLineTheme.Typography.title1)
                    }

                    Spacer()

                    Button(action: { showRustSyllabusSheet = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)

                Rectangle()
                    .fill(StudyLineTheme.hairlineBorder)
                    .frame(height: 0.8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let rust = rustDomain {
                            ForEach(rust.stages) { stage in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(stage.name)
                                        .font(StudyLineTheme.Typography.title2)
                                        .foregroundStyle(StudyLineTheme.bambooGreen)

                                    VStack(spacing: 6) {
                                        ForEach(stage.nodes) { node in
                                            Button(action: {
                                                selectedNodeId = node.id
                                                showRustSyllabusSheet = false
                                                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                                    currentTab = .workbench
                                                }
                                            }) {
                                                HStack(spacing: 12) {
                                                    Text(node.id)
                                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                        .foregroundStyle(StudyLineTheme.bambooGreen)
                                                        .frame(width: 40, alignment: .leading)

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(node.title)
                                                            .font(.system(size: 13, weight: .medium))
                                                            .foregroundStyle(.primary)
                                                        Text(node.summary)
                                                            .font(.system(size: 11))
                                                            .foregroundStyle(.secondary)
                                                            .lineLimit(1)
                                                    }

                                                    Spacer()

                                                    Image(systemName: "arrow.right.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(StudyLineTheme.bambooGreen.opacity(0.8))
                                                }
                                                .padding(12)
                                                .background(Color.primary.opacity(0.025))
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(StudyLineTheme.hairlineBorder, lineWidth: 0.5))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(16)
                                .studylineLiquidGlass(cornerRadius: 14, padding: 0)
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 720, minHeight: 560)
    }
}
