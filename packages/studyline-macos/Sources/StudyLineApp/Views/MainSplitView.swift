// =============================================================================
// StudyLine macOS Native MainSplitView (2-Column + Inspector)
// Strict Y=90pt Kintsugi Gold Line Alignment across all three columns
// Fluid Background Compatible & TTZip Zen Liquid Glass
// =============================================================================

import SwiftUI
import AppKit

public struct NodeModel: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let stage: String
    public let lines: String
    public let stars: Int
}

public struct MainSplitView: View {
    @Binding public var selectedNodeId: String
    @Binding public var isZenMode: Bool
    @Binding public var isExamPresented: Bool
    @State private var showInspector: Bool = true
    @State private var searchQuery: String = ""

    public let nodes: [NodeModel] = [
        NodeModel(id: "E01", title: "语言是人类的第一个外挂", stage: "0段·语言", lines: "1-12", stars: 5),
        NodeModel(id: "E07", title: "卡俄斯：裂开的虚空", stage: "0段·神话", lines: "116-122", stars: 4),
        NodeModel(id: "E29", title: "两种争斗与正义的发生", stage: "0段·神话", lines: "1-41", stars: 4),
        NodeModel(id: "E66", title: "战神山法庭与司法的诞生", stage: "0段·悲剧", lines: "566-777", stars: 5),
        NodeModel(id: "E82", title: "0段出段综合大考", stage: "0段·考核", lines: "94期全景", stars: 5),
        NodeModel(id: "A01", title: "世界的质料：米利都三杰与阿派朗", stage: "阶段A·米利都", lines: "DK 12 B1", stars: 5),
        NodeModel(id: "A04", title: "巴门尼德真理之路与存在论之锚", stage: "阶段A·爱利亚", lines: "DK 28 B2-B8", stars: 5),
        NodeModel(id: "R01", title: "栈堆物理布局与 CPU 缓存行", stage: "Rust 0段", lines: "硬件物理", stars: 5),
        NodeModel(id: "R07", title: "从 C 缺陷到所有权发生学：UAF 与数据竞争", stage: "Rust 0段", lines: "缺陷发生学", stars: 5),
        NodeModel(id: "R12", title: "仿射类型系统（Affine Types）数学证明", stage: "Rust 0段", lines: "形式化逻辑", stars: 5)
    ]

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
            // MARK: - 左侧 200pt 导航侧边栏
            VStack(spacing: 0) {
                StudyLineHeaderBar(
                    sectionName: "PHILOSOPHY & RUST",
                    title: "因果学线",
                    badgeText: "\(nodes.count)"
                )

                // 搜索栏
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField("快速索引节点...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(StudyLineTheme.hairlineBorder, lineWidth: 0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                List(nodes.filter { searchQuery.isEmpty || $0.title.contains(searchQuery) || $0.id.contains(searchQuery) }, id: \.id, selection: $selectedNodeId) { node in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(node.id.hasPrefix("R") ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
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
                    .padding(.vertical, 4)
                    .tag(node.id)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 250)
            .background(Color.clear)
        } detail: {
            // MARK: - 中央核心学术讲义研读工作台
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
                            VStack(alignment: .leading, spacing: 18) {
                                // 节点基本信息卡片
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("当前研读节点")
                                        .font(.system(size: 10, weight: .bold, design: .serif))
                                        .foregroundStyle(StudyLineTheme.kintsugiGold)

                                    HStack {
                                        Text(selectedNodeId)
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundStyle(StudyLineTheme.kintsugiGold)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            ForEach(0..<5) { _ in
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(StudyLineTheme.kintsugiGold)
                                            }
                                        }
                                    }

                                    Text(nodes.first(where: { $0.id == selectedNodeId })?.title ?? "真理之路与存在论之锚")
                                        .font(StudyLineTheme.Typography.title2)
                                        .foregroundStyle(.primary)
                                }
                                .studylineLiquidGlass(cornerRadius: 12, padding: 14)

                                // 形式化因果推演卡片
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("前置公理依赖 (Prerequisites)")
                                        .font(.system(size: 10, weight: .bold, design: .serif))
                                        .foregroundStyle(StudyLineTheme.kintsugiGold)

                                    Text(selectedNodeId.hasPrefix("R") ? "• R01: 栈堆物理布局与 Cache Line\n• R06: C 指针别名与就地突变\n• R12: 仿射类型系统证明" : "• E07: 卡俄斯虚空裂开\n• E29: 两种争斗与正义发生\n• A01: 始基与无定阿派朗")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineSpacing(4)
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
}
