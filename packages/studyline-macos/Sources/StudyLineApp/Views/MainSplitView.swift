// =============================================================================
// StudyLine macOS Native MainSplitView (2-Column + Inspector)
// Strict Y=90pt Kintsugi Gold Line Alignment across all three columns
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
        NodeModel(id: "A01", title: "泰勒斯：水是万物的始基", stage: "阶段A·米利都", lines: "DK 11 A12", stars: 4),
        NodeModel(id: "A04", title: "阿那克西曼德残篇 B1", stage: "阶段A·米利都", lines: "DK 12 B1", stars: 5),
        NodeModel(id: "A16", title: "赫拉克利特：活火与对立", stage: "阶段A·爱非斯", lines: "DK 22 B30", stars: 4),
        NodeModel(id: "A25", title: "巴门尼德：真理之路", stage: "阶段A·爱利亚", lines: "DK 28 B2", stars: 5),
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

    private var activeNode: NodeModel {
        nodes.first(where: { $0.id == selectedNodeId }) ?? nodes[6]
    }

    public var body: some View {
        NavigationSplitView {
            // 1. Sidebar (左侧学科树)
            VStack(spacing: 0) {
                TTZipHeaderBar(
                    sectionName: "DISCIPLINE_TREE",
                    title: "学科大纲",
                    badgeText: "\(nodes.count) 讲"
                )

                List(nodes, id: \.id, selection: $selectedNodeId) { node in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(node.id == selectedNodeId ? TTZipTheme.kintsugiGold : Color.gray.opacity(0.4))
                            .frame(width: 6, height: 6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(node.id): \(node.title)")
                                .font(.system(size: 13, weight: node.id == selectedNodeId ? .semibold : .regular))
                                .foregroundStyle(node.id == selectedNodeId ? TTZipTheme.kintsugiGold : .primary)
                            Text(node.stage)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNodeId = node.id
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
            .background(VisualEffectBlur(material: .sidebar))
        } detail: {
            // 2. Central Lecture Workbench (中央原典研读区)
            VStack(spacing: 0) {
                TTZipHeaderBar(
                    sectionName: "PRIMARY_SOURCE",
                    title: "\(activeNode.id) · \(activeNode.title)",
                    badgeText: "DK 12 B1"
                )

                LectureWorkbenchView(node: activeNode, onOpenExam: {
                    isExamPresented = true
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                })
            }
            .background(Color.primary.opacity(0.015))
            .inspector(isPresented: $showInspector) {
                // 3. Inspector (右侧检查器：TOC 与掌握度)
                VStack(spacing: 0) {
                    TTZipHeaderBar(
                        sectionName: "MASTERY_TOC",
                        title: "大纲与掌握度",
                        badgeText: "85%"
                    )

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 掌握度星级
                            VStack(alignment: .leading, spacing: 6) {
                                Text("当前章节掌握度")
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    ForEach(0..<5) { star in
                                        Image(systemName: star < activeNode.stars ? "star.fill" : "star")
                                            .font(.system(size: 12))
                                            .foregroundStyle(TTZipTheme.kintsugiGold)
                                    }
                                    Text("5星达标")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(TTZipTheme.bambooGreen)
                                        .padding(.leading, 4)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))

                            // 目录大纲
                            VStack(alignment: .leading, spacing: 8) {
                                Text("目录导航 (TOC)")
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundStyle(.secondary)

                                ForEach(["1. 一手原典文献锚点", "2. 核心哲学发生学解析", "3. 形式化论证三段论", "4. 核心范畴演进对照表"], id: \.self) { item in
                                    Text(item)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.primary.opacity(0.8))
                                        .padding(.vertical, 2)
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))

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
                                .padding(.vertical, 9)
                                .background(TTZipTheme.bambooGreen)
                                .foregroundStyle(Color.white)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                    }
                    .inspectorColumnWidth(min: 240, ideal: 280, max: 320)
                }
            }
        }
    }
}
