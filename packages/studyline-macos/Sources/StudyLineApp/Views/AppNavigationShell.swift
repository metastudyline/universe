// =============================================================================
// StudyLine macOS Top-Level Navigation Shell (顶层系统导航中枢外壳)
// Fluid Dynamic Background Canvas × 5-Tab Glass Hub × Y=90pt Kintsugi Gold Line
// =============================================================================

import SwiftUI
import AppKit

public enum AppTab: String, CaseIterable, Identifiable {
    case home = "宇宙主页"
    case topology = "知识星云"
    case workbench = "研读工作台"
    case exam = "出段大考"
    case settings = "引擎设置"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .home: return "sparkles"
        case .topology: return "point.3.connected.trianglepath.dotted"
        case .workbench: return "book.pages"
        case .exam: return "pencil.and.outline"
        case .settings: return "gearshape"
        }
    }
}

public struct AppNavigationShell: View {
    @Binding public var selectedNodeId: String
    @Binding public var currentTab: AppTab
    @Binding public var isZenMode: Bool
    @Binding public var isExamPresented: Bool

    public init(
        selectedNodeId: Binding<String>,
        currentTab: Binding<AppTab>,
        isZenMode: Binding<Bool>,
        isExamPresented: Binding<Bool>
    ) {
        self._selectedNodeId = selectedNodeId
        self._currentTab = currentTab
        self._isZenMode = isZenMode
        self._isExamPresented = isExamPresented
    }

    public var body: some View {
        ZStack {
            // 1. 全局流体动态极光背景底盘 (Fluid Dynamic Mesh Background)
            StudyLineFluidBackgroundView(
                primaryColor: currentTab == .workbench ? StudyLineTheme.bambooGreen : StudyLineTheme.cosmicUltramarine,
                secondaryColor: StudyLineTheme.kintsugiGold,
                accentColor: currentTab == .exam ? StudyLineTheme.cinnabarRed : StudyLineTheme.bambooGreen,
                speed: 0.22
            )
            .allowsHitTesting(false)

            // 2. 核心主内容区与顶栏外壳
            VStack(spacing: 0) {
                // 顶层全局导航 Header Bar (Y=90pt 金线绝对对齐)
                topNavigationHeader

                // 核心视图切换区 (State-Preserving View Switcher)
                ZStack {
                    UniverseHomeView(
                        selectedNodeId: $selectedNodeId,
                        currentTab: $currentTab,
                        isExamPresented: $isExamPresented
                    )
                    .opacity(currentTab == .home ? 1 : 0)
                    .allowsHitTesting(currentTab == .home)

                    MainSplitView(
                        selectedNodeId: $selectedNodeId,
                        isZenMode: $isZenMode,
                        isExamPresented: $isExamPresented
                    )
                    .opacity(currentTab == .workbench ? 1 : 0)
                    .allowsHitTesting(currentTab == .workbench)

                    topologyPlaceholderView
                        .opacity(currentTab == .topology ? 1 : 0)
                        .allowsHitTesting(currentTab == .topology)

                    examArenaPlaceholderView
                        .opacity(currentTab == .exam ? 1 : 0)
                        .allowsHitTesting(currentTab == .exam)

                    settingsPlaceholderView
                        .opacity(currentTab == .settings ? 1 : 0)
                        .allowsHitTesting(currentTab == .settings)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: - 顶层全局导航 Header Bar (Y = 90pt 金线对齐)
    private var topNavigationHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 左侧 Logo
                HStack(spacing: 9) {
                    ZStack {
                        Circle()
                            .fill(StudyLineTheme.kintsugiGold.opacity(0.18))
                            .frame(width: 24, height: 24)
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(StudyLineTheme.kintsugiGold)
                    }
                    Text("STUDYLINE")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .tracking(3)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // 中央 5-Tab Segmented Glass 胶囊
                HStack(spacing: 4) {
                    ForEach(AppTab.allCases) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                currentTab = tab
                            }
                            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 11, weight: currentTab == tab ? .bold : .medium))
                                Text(tab.rawValue)
                                    .font(.system(size: 12, weight: currentTab == tab ? .bold : .regular))
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 6)
                            .background(currentTab == tab ? StudyLineTheme.kintsugiGold.opacity(0.18) : Color.clear)
                            .foregroundStyle(currentTab == tab ? StudyLineTheme.kintsugiGold : .secondary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow))
                .background(Color.primary.opacity(0.02))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(StudyLineTheme.hairlineBorder, lineWidth: 0.6))
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)

                Spacer()

                // 右侧 Zen 模式切换与大考入口
                HStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isZenMode.toggle()
                        }
                        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                    }) {
                        Image(systemName: isZenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(7)
                            .background(Color.primary.opacity(0.03))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Zen 沉浸阅读 (⇧⌘F)")

                    Button(action: {
                        isExamPresented = true
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 11, weight: .bold))
                            Text("出段大考")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(StudyLineTheme.bambooGreen)
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: StudyLineTheme.bambooGreen.opacity(0.3), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 52)

            // Y = 90pt 贯通金线 (38pt padding + 52pt header)
            Rectangle()
                .fill(StudyLineTheme.kintsugiGold)
                .frame(height: 1.5)
        }
        .padding(.top, 38)
    }

    // MARK: - 占位视图
    private var topologyPlaceholderView: some View {
        VStack(spacing: 18) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 52))
                .foregroundStyle(StudyLineTheme.kintsugiGold)
            Text("60FPS 宏观知识星云力导向拓扑画布")
                .font(StudyLineTheme.Typography.displayTitle)
            Text("支持 LOD 0 星系热力 ➔ LOD 1 金色骨干 ➔ LOD 2 胶囊细节的 3 级语义缩放")
                .font(StudyLineTheme.Typography.body)
                .foregroundStyle(.secondary)
            Button("进入研读工作台 (⌘1)") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentTab = .workbench
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(StudyLineTheme.kintsugiGold)
            .foregroundStyle(Color.black)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var examArenaPlaceholderView: some View {
        VStack(spacing: 18) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 52))
                .foregroundStyle(StudyLineTheme.bambooGreen)
            Text("出段考核竞技场 (Exam Arena)")
                .font(StudyLineTheme.Typography.displayTitle)
            Text("完成 0段神话悲剧、阶段A爱利亚存在论与 Rust 内存模型闭卷因果推演")
                .font(StudyLineTheme.Typography.body)
                .foregroundStyle(.secondary)
            Button("启动出段考核 (⌘E)") {
                isExamPresented = true
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .background(StudyLineTheme.bambooGreen)
            .foregroundStyle(Color.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var settingsPlaceholderView: some View {
        VStack(spacing: 18) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("StudyLine 系统级引擎与数据中枢")
                .font(StudyLineTheme.Typography.displayTitle)
            Text("All-in-Rust C-ABI 静态库直连 · rkyv 零拷贝镜像 (.sla) · 本地 Axum 守护进程")
                .font(StudyLineTheme.Typography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
