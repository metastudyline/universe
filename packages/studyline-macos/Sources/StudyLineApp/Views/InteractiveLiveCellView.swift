// =============================================================================
// StudyLine Interactive Live Cell View (In-Situ Executable Lecture Code Cell)
// Inline In-Situ Code Editing × ⌘R Instant Subprocess Execution × Dirty Reset
// =============================================================================

import SwiftUI
import AppKit

public struct InteractiveLiveCellView: View {
    public let cellId: String
    public let initialCode: String
    
    @State private var currentCode: String
    @State private var consoleOutput: String = ""
    @State private var isRunning: Bool = false
    @State private var isExpanded: Bool = true
    @State private var executionDuration: String? = nil
    @State private var hasError: Bool = false

    public init(cellId: String, initialCode: String) {
        self.cellId = cellId
        self.initialCode = initialCode
        self._currentCode = State(initialValue: initialCode)
    }

    private var isDirty: Bool {
        currentCode.trimmingCharacters(in: .whitespacesAndNewlines) != initialCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Live Cell 顶栏
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isDirty ? StudyLineTheme.bambooGreen : StudyLineTheme.kintsugiGold)
                        .frame(width: 7, height: 7)
                    
                    Text("LIVE CELL [\(cellId)]")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(StudyLineTheme.kintsugiGold)
                    
                    if isDirty {
                        Text("• 已修改")
                            .font(.system(size: 9))
                            .foregroundColor(StudyLineTheme.bambooGreen)
                    }
                }

                Spacer()

                if let duration = executionDuration {
                    Text(duration)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(hasError ? StudyLineTheme.cinnabarRed : StudyLineTheme.bambooGreen)
                }

                if isDirty {
                    Button(action: { currentCode = initialCode }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: runCellCode) {
                    HStack(spacing: 4) {
                        if isRunning {
                            ProgressView().scaleEffect(0.5)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("运行 (⌘R)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(StudyLineTheme.kintsugiGold)
                    .foregroundColor(.black)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isRunning)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))

            Divider().background(Color.white.opacity(0.1))

            // 2. 原位内嵌代码编辑器
            TextEditor(text: $currentCode)
                .font(.system(size: 12.5, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 120, maxHeight: 220)
                .background(Color.black.opacity(0.55))

            // 3. 控制台输出就地展开
            if !consoleOutput.isEmpty {
                Divider().background(hasError ? StudyLineTheme.cinnabarRed.opacity(0.4) : StudyLineTheme.kintsugiGold.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("STDOUT / 诊断:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Button("收起") { consoleOutput = "" }
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                            .buttonStyle(.plain)
                    }

                    Text(consoleOutput)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundColor(hasError ? StudyLineTheme.cinnabarRed : StudyLineTheme.bambooGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding(10)
                .background(Color.black.opacity(0.8))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isDirty ? StudyLineTheme.bambooGreen.opacity(0.5) : StudyLineTheme.kintsugiGold.opacity(0.25), lineWidth: 0.8)
        )
    }

    private func runCellCode() {
        guard !isRunning else { return }
        isRunning = true
        hasError = false
        consoleOutput = "极速编译执行中..."
        executionDuration = nil

        let code = currentCode
        let id = cellId

        DispatchQueue.global(qos: .userInitiated).async {
            let start = Date()
            let tempDir = NSTemporaryDirectory()
            let srcFile = (tempDir as NSString).appendingPathComponent("cell_\(id.lowercased()).rs")
            let binFile = (tempDir as NSString).appendingPathComponent("cell_\(id.lowercased())_bin")

            do {
                try code.write(toFile: srcFile, atomically: true, encoding: .utf8)
            } catch {
                DispatchQueue.main.async {
                    self.consoleOutput = "写入失败: \(error.localizedDescription)"
                    self.isRunning = false
                    self.hasError = true
                }
                return
            }

            let compile = Process()
            compile.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            compile.arguments = ["rustc", "-o", binFile, srcFile]
            let errPipe = Pipe()
            compile.standardError = errPipe

            do {
                try compile.run()
                compile.waitUntilExit()

                if compile.terminationStatus != 0 {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? "编译失败"
                    DispatchQueue.main.async {
                        self.consoleOutput = "💥 编译错误:\n" + errStr
                        self.isRunning = false
                        self.hasError = true
                        let elapsed = Int(Date().timeIntervalSince(start) * 1000)
                        self.executionDuration = "编译失败 (\(elapsed)ms)"
                    }
                    return
                }

                let run = Process()
                run.executableURL = URL(fileURLWithPath: binFile)
                let outPipe = Pipe()
                let runErrPipe = Pipe()
                run.standardOutput = outPipe
                run.standardError = runErrPipe

                try run.run()
                run.waitUntilExit()

                let outStr = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let runErrStr = String(data: runErrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let elapsed = Int(Date().timeIntervalSince(start) * 1000)

                DispatchQueue.main.async {
                    var finalOut = outStr
                    if !runErrStr.isEmpty { finalOut += "\n[STDERR]:\n" + runErrStr }
                    self.consoleOutput = finalOut.isEmpty ? "(运行成功，无输出)" : finalOut
                    self.isRunning = false
                    self.hasError = run.terminationStatus != 0
                    self.executionDuration = "✔ (\(elapsed)ms)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.consoleOutput = "启动失败: \(error.localizedDescription)"
                    self.isRunning = false
                    self.hasError = true
                }
            }
        }
    }
}
