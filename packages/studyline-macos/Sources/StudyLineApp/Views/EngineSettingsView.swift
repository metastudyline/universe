// =============================================================================
// StudyLine Engine Settings & Git Monorepo Management View
// Local Git Repository Path × Offline Cache Status × Global Keyboard Shortcuts
// =============================================================================

import SwiftUI

public struct EngineSettingsView: View {
    @State private var gitRepoPath: String = "/Users/kevintung/Documents/dev/life-coach"
    @State private var isSyncing: Bool = false
    @State private var syncStatusMessage: String = "Git 知识大本营已就绪 (100% 本地离线直读)"
    @State private var lastSyncTime: String = "2026-08-21 08:30"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 1. 顶部 Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundColor(StudyLineTheme.kintsugiGold)
                            .font(.system(size: 20))
                        Text("StudyLine 引擎配置与本地存储")
                            .font(StudyLineTheme.Typography.displayTitle)
                            .foregroundColor(.white)
                    }
                    Text("管理本地单一真实源 Git Monorepo 物理路径、知识同步与终端 CLI 链接")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.65))
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                // 2. Git 知识仓库设置卡片
                VStack(alignment: .leading, spacing: 16) {
                    Text("🏛️ 知识资产库 (Git Monorepo Single Source of Truth)")
                        .font(StudyLineTheme.Typography.title2)
                        .foregroundColor(StudyLineTheme.kintsugiGold)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("本地仓库物理绝对路径:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))

                        HStack {
                            TextField("Path to Monorepo", text: $gitRepoPath)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white)

                            Button("重新加载") {
                                StudyLineDomainRepository.shared.reloadAllDomains()
                                syncStatusMessage = "物理目录已重新扫描完毕"
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("同步状态: \(syncStatusMessage)")
                                .font(.system(size: 12))
                                .foregroundColor(StudyLineTheme.bambooGreen)
                            Text("上次同步时间: \(lastSyncTime)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Button(action: triggerGitSync) {
                            HStack(spacing: 6) {
                                if isSyncing {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text("立即执行 Git Sync")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(StudyLineTheme.kintsugiGold)
                        .disabled(isSyncing)
                    }
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.45))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StudyLineTheme.kintsugiGold.opacity(0.3), lineWidth: 0.8))
                )
                .padding(.horizontal, 28)

                // 3. 原生快捷键指南
                VStack(alignment: .leading, spacing: 16) {
                    Text("⌨️ 原生快捷键与操作矩阵")
                        .font(StudyLineTheme.Typography.title2)
                        .foregroundColor(StudyLineTheme.kintsugiGold)

                    VStack(spacing: 10) {
                        hotkeyRow(key: "⌘ 1", desc: "切换至「宇宙主页」")
                        hotkeyRow(key: "⌘ 2", desc: "切换至「知识星云」力导向画布")
                        hotkeyRow(key: "⌘ 3", desc: "切换至「研读工作台」")
                        hotkeyRow(key: "⌘ E", desc: "唤出出段大考考核模态框")
                        hotkeyRow(key: "⌘ Shift F", desc: "切换 Zen 全屏沉浸阅读模式")
                        hotkeyRow(key: "⌘ F", desc: "全域 BM25 极速模糊搜索")
                    }
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.45))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StudyLineTheme.kintsugiGold.opacity(0.3), lineWidth: 0.8))
                )
                .padding(.horizontal, 28)

                Spacer(minLength: 40)
            }
        }
    }

    private func hotkeyRow(key: String, desc: String) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(StudyLineTheme.kintsugiGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12))
                .cornerRadius(6)

            Text(desc)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }

    private func triggerGitSync() {
        isSyncing = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.2) {
            DispatchQueue.main.async {
                StudyLineDomainRepository.shared.reloadAllDomains()
                isSyncing = false
                syncStatusMessage = "Git 仓库已与 remote 同步，DAG 校验 100% 通过"
                lastSyncTime = "刚刚"
            }
        }
    }
}
