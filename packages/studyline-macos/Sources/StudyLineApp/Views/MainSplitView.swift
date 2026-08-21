// =============================================================================
// StudyLine macOS Native MainSplitView (2-Column + Inspector)
// Strict Y=90pt Kintsugi Gold Line Alignment across all three columns
// Dynamically driven by StudyLineDomainRepository (Real Git Monorepo Data)
// =============================================================================

import SwiftUI
import AppKit

public struct MainSplitView: View {
    @Binding public var selectedNodeId: String
    @Binding public var isZenMode: Bool
    @Binding public var isExamPresented: Bool

    @ObservedObject private var repo = StudyLineDomainRepository.shared
    @State private var showInspector: Bool = true
    @State private var searchQuery: String = ""
    @State private var selectedDomainFilter: String = "all"

    public init(
        selectedNodeId: Binding<String>,
        isZenMode: Binding<Bool>,
        isExamPresented: Binding<Bool>
    ) {
        self._selectedNodeId = selectedNodeId
        self._isZenMode = isZenMode
        self._isExamPresented = isExamPresented
    }

    public var body: some View {
        NavigationSplitView {
            // MARK: - 左侧 210pt 导航侧边栏 (动态全域学线)
            VStack(spacing: 0) {
                StudyLineHeaderBar(
                    sectionName: "REAL MONOREPO KNOWLEDGE",
                    title: "因果学线",
                    badgeText: "\(repo.allNodes.count) 讲"
                )

                // 领域切换筛选胶囊 (All / Rust / Philosophy)
                HStack(spacing: 4) {
                    filterCapsule(title: "全部", tag: "all")
                    filterCapsule(title: "🦀 Rust", tag: "rust")
                    filterCapsule(title: "🏛️ 哲学史", tag: "philosophy")
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // 搜索栏
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField("搜索节点 ID、标题、知识点...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(StudyLineTheme.hairlineBorder, lineWidth: 0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // 动态节点列表 (从 Git 物理磁盘实时呈现)
                List(selection: $selectedNodeId) {
                    ForEach(filteredDomains) { domain in
                        Section(header: domainHeader(domain: domain)) {
                            ForEach(domain.stages) { stage in
                                ForEach(stage.nodes.filter { matchesSearch($0) }) { node in
                                    nodeRow(node: node)
                                        .tag(node.id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
            .background(Color.clear)
        } detail: {
            // MARK: - 中央核心学术讲义研读工作台 (真正加载 index.md)
            HStack(spacing: 0) {
                LectureWorkbenchView(
                    selectedNodeId: $selectedNodeId,
                    isZenMode: $isZenMode,
                    showInspector: $showInspector
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MARK: - 右侧 280pt 检查器边栏
                if showInspector && !isZenMode {
                    Rectangle()
                        .fill(StudyLineTheme.hairlineBorder)
                        .frame(width: 0.8)

                    VStack(spacing: 0) {
                        StudyLineHeaderBar(
                            sectionName: "INSPECTOR",
                            title: "知识因果分析",
                            badgeText: "DAG"
                        )

                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                let activeNode = repo.allNodes.first(where: { $0.id == selectedNodeId })

                                // 节点基本信息卡片
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("当前研读节点")
                                        .font(.system(size: 10, weight: .bold, design: .serif))
                                        .foregroundStyle(StudyLineTheme.kintsugiGold)

                                    HStack {
                                        Text(selectedNodeId)
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundStyle(selectedNodeId.hasPrefix("R") ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            ForEach(0..<5) { _ in
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(StudyLineTheme.kintsugiGold)
                                            }
                                        }
                                    }

                                    Text(activeNode?.title ?? "第一性原理因果讲义")
                                        .font(StudyLineTheme.Typography.title2)
                                        .foregroundStyle(.primary)
                                }
                                .studylineLiquidGlass(cornerRadius: 12, padding: 14)

                                // 物理文件路径指示器 (证明真实读取)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("物理磁盘讲义路径 (Git Monorepo)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.secondary)

                                    Text(activeNode?.markdownPath ?? "domains/.../index.md")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(StudyLineTheme.bambooGreen)
                                        .lineLimit(2)
                                }
                                .studylineLiquidGlass(cornerRadius: 10, padding: 12)

                                // 前置公理依赖卡片
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("前置公理依赖 (Prerequisites)")
                                        .font(.system(size: 10, weight: .bold, design: .serif))
                                        .foregroundStyle(StudyLineTheme.kintsugiGold)

                                    if let prereqs = activeNode?.prerequisites, !prereqs.isEmpty {
                                        ForEach(prereqs, id: \.self) { pre in
                                            Text("• \(pre)")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                        }
                                    } else {
                                        Text("• 0段公理原点（无前置约束）")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .studylineLiquidGlass(cornerRadius: 12, padding: 14)

                                // 快捷出段考核胶囊按钮
                                Button(action: {
                                    isExamPresented = true
                                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                                }) {
                                    HStack {
                                        Image(systemName: "pencil.and.outline")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("启动出段考核 (⌘E)")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(StudyLineTheme.bambooGreen)
                                    .foregroundStyle(Color.white)
                                    .clipShape(Capsule())
                                    .shadow(color: StudyLineTheme.bambooGreen.opacity(0.35), radius: 6, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(16)
                        }
                        .frame(width: 280)
                    }
                    .background(Color.clear)
                }
            }
        }
        .background(Color.clear)
    }

    // MARK: - 辅助组件
    private var filteredDomains: [DynamicDomain] {
        if selectedDomainFilter == "all" {
            return repo.domains
        } else {
            return repo.domains.filter { $0.id == selectedDomainFilter }
        }
    }

    private func matchesSearch(_ node: DynamicNode) -> Bool {
        if searchQuery.isEmpty { return true }
        return node.id.localizedCaseInsensitiveContains(searchQuery) ||
               node.title.localizedCaseInsensitiveContains(searchQuery) ||
               node.summary.localizedCaseInsensitiveContains(searchQuery)
    }

    private func filterCapsule(title: String, tag: String) -> some View {
        Button(action: {
            selectedDomainFilter = tag
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        }) {
            Text(title)
                .font(.system(size: 11, weight: selectedDomainFilter == tag ? .bold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(selectedDomainFilter == tag ? StudyLineTheme.kintsugiGold.opacity(0.18) : Color.primary.opacity(0.025))
                .foregroundStyle(selectedDomainFilter == tag ? StudyLineTheme.kintsugiGold : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func domainHeader(domain: DynamicDomain) -> some View {
        HStack {
            Text(domain.name)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundStyle(domain.id == "rust" ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
            Spacer()
            Text("\(domain.totalNodeCount)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func nodeRow(node: DynamicNode) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(node.domain == "rust" ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(node.id)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(selectedNodeId == node.id ? StudyLineTheme.kintsugiGold : .secondary)
                    Spacer()
                    Text(node.stage)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                Text(node.title)
                    .font(.system(size: 12, weight: selectedNodeId == node.id ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}
