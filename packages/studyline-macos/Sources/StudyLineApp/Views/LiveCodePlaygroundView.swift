// =============================================================================
// StudyLine Live Code Playground Runner (macOS Native In-App Code Editor & Console)
// Editable Rust Source × Async Process Dispatch × 60FPS Terminal Console Output
// =============================================================================

import SwiftUI
import AppKit

public struct LiveCodePlaygroundView: View {
    public let nodeId: String
    @State private var sourceCode: String
    @State private var consoleOutput: String = ""
    @State private var isRunning: Bool = false
    @State private var executionDuration: String? = nil
    @State private var hasError: Bool = false

    public init(nodeId: String, initialCode: String? = nil) {
        self.nodeId = nodeId
        let defaultCode = initialCode ?? """
// ✦ StudyLine [\(nodeId)] 实时编程实验沙盒
fn main() {
    let message = "✦ 欢迎在 StudyLine 原生工作台实时修改并运行代码！";
    println!("{}", message);

    let mut count = 0;
    for i in 1..=5 {
        count += i;
    }
    println!("累加计算结果: 1 + ... + 5 = {}", count);
}
"""
        self._sourceCode = State(initialValue: defaultCode)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 顶部操作栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundColor(StudyLineTheme.kintsugiGold)
                    Text("实时编程沙盒 (Live Code Playground)")
                        .font(StudyLineTheme.Typography.title2)
                        .foregroundColor(.white)
                }

                Spacer()

                if let duration = executionDuration {
                    Text(duration)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(hasError ? StudyLineTheme.cinnabarRed : StudyLineTheme.bambooGreen)
                }

                Button(action: runCode) {
                    HStack(spacing: 6) {
                        if isRunning {
                            ProgressView().scaleEffect(0.6)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("运行代码 (⌘R)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(StudyLineTheme.kintsugiGold)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isRunning)
                .keyboardShortcut("r", modifiers: .command)
            }

            // 2. 代码编辑器区域
            VStack(alignment: .leading, spacing: 4) {
                Text("可直接编辑代码:")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))

                TextEditor(text: $sourceCode)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.white)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 180, maxHeight: 260)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 0.8))
            }

            // 3. 终端输出控制台 (Console Output)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("控制台输出 (Console Output):")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    if !consoleOutput.isEmpty {
                        Button("清屏") { consoleOutput = "" }
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .buttonStyle(.plain)
                    }
                }

                ScrollView {
                    HStack {
                        Text(consoleOutput.isEmpty ? "点击上方「运行代码」查看输出..." : consoleOutput)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(hasError ? StudyLineTheme.cinnabarRed : StudyLineTheme.bambooGreen)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                    }
                    .padding(12)
                }
                .frame(minHeight: 80, maxHeight: 160)
                .background(Color.black.opacity(0.75))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(hasError ? StudyLineTheme.cinnabarRed.opacity(0.5) : StudyLineTheme.kintsugiGold.opacity(0.3), lineWidth: 0.8))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(StudyLineTheme.kintsugiGold.opacity(0.3), lineWidth: 0.8))
        )
    }

    private func runCode() {
        guard !isRunning else { return }
        isRunning = true
        hasError = false
        consoleOutput = "正在调用本地 rustc 极速编译中..."
        executionDuration = nil

        let code = sourceCode
        let currentId = nodeId

        DispatchQueue.global(qos: .userInitiated).async {
            let start = Date()
            let tempDir = NSTemporaryDirectory()
            let srcFile = (tempDir as NSString).appendingPathComponent("studyline_\(currentId.lowercased()).rs")
            let binFile = (tempDir as NSString).appendingPathComponent("studyline_\(currentId.lowercased())_bin")

            do {
                try code.write(toFile: srcFile, atomically: true, encoding: .utf8)
            } catch {
                DispatchQueue.main.async {
                    self.consoleOutput = "写入源码失败: \(error.localizedDescription)"
                    self.isRunning = false
                    self.hasError = true
                }
                return
            }

            // 1. 编译
            let compileProcess = Process()
            compileProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            compileProcess.arguments = ["rustc", "-o", binFile, srcFile]
            let compileErrPipe = Pipe()
            compileProcess.standardError = compileErrPipe

            do {
                try compileProcess.run()
                compileProcess.waitUntilExit()

                if compileProcess.terminationStatus != 0 {
                    let errData = compileErrPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? "编译失败"
                    DispatchQueue.main.async {
                        self.consoleOutput = "💥 编译错误 (Compile Error):\n\(errStr)"
                        self.isRunning = false
                        self.hasError = true
                        let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                        self.executionDuration = "编译失败 (\(elapsed)ms)"
                    }
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self.consoleOutput = "无法启动 rustc: \(error.localizedDescription)"
                    self.isRunning = false
                    self.hasError = true
                }
                return
            }

            // 2. 执行
            let runProcess = Process()
            runProcess.executableURL = URL(fileURLWithPath: binFile)
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            runProcess.standardOutput = stdoutPipe
            runProcess.standardError = stderrPipe

            do {
                try runProcess.run()
                runProcess.waitUntilExit()

                let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let outStr = String(data: outData, encoding: .utf8) ?? ""
                let errStr = String(data: errData, encoding: .utf8) ?? ""

                let elapsed = Int(Date().timeIntervalSince(start) * 1000)

                DispatchQueue.main.async {
                    var combined = outStr
                    if !errStr.isEmpty {
                        combined += "\n[STDERR]:\n" + errStr
                    }
                    self.consoleOutput = combined.isEmpty ? "(程序正常退出，无标准输出)" : combined
                    self.isRunning = false
                    self.hasError = runProcess.terminationStatus != 0
                    self.executionDuration = "✔ 运行成功 (\(elapsed)ms)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.consoleOutput = "执行失败: \(error.localizedDescription)"
                    self.isRunning = false
                    self.hasError = true
                }
            }
        }
    }
}
