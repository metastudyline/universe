// =============================================================================
// StudyLine macOS Native App Entry & System Integration
// Commands Menu, Keyboard Shortcuts, Rust C-ABI Engine Bridge
// Universe Home Portal & Full App Navigation Shell
// =============================================================================

import SwiftUI
import AppKit
import StudyLine

@main
struct StudyLineApp: App {
    @State private var selectedNodeId: String = "A04"
    @State private var currentTab: AppTab = .home
    @State private var isZenMode: Bool = false
    @State private var isExamPresented: Bool = false
    @State private var engine: StudyLineEngine? = nil

    init() {
        // Initialize Rust C-ABI engine safely
        do {
            _ = try StudyLineEngine()
        } catch {
            print("[WARN] Rust C-ABI Engine initialization fallback: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppNavigationShell(
                    selectedNodeId: $selectedNodeId,
                    currentTab: $currentTab,
                    isZenMode: $isZenMode,
                    isExamPresented: $isExamPresented
                )

                if isExamPresented {
                    ExitExamModalView(isPresented: $isExamPresented)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(minWidth: 1080, minHeight: 700)
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("回到宇宙主页") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentTab = .home
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
                .keyboardShortcut("h", modifiers: .command)

                Button("全局聚焦搜索") {
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
                .keyboardShortcut("k", modifiers: .command)
            }

            CommandMenu("视图") {
                Button("切换到 研读工作台") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentTab = .workbench
                    }
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("切换到 知识星云拓扑") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentTab = .topology
                    }
                }
                .keyboardShortcut("2", modifiers: .command)

                Divider()

                Button(isZenMode ? "退出 Zen 沉浸模式" : "进入 Zen 沉浸模式") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isZenMode.toggle()
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }

            CommandMenu("考核") {
                Button("启动出段考核") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExamPresented = true
                    }
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
                .keyboardShortcut("e", modifiers: .command)
            }
        }
    }
}
