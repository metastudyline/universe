import SwiftUI

// ✦ 多态教学组件渲染工厂 (Polymorphic Block View Factory)

public struct PedagogicalBlockFactoryView: View {
    public let block: PedagogicalBlock

    public init(block: PedagogicalBlock) {
        self.block = block
    }

    @ViewBuilder
    public var body: some View {
        switch block {
        case .bilingualSource(_, let model):
            BilingualPrimarySourceBlockView(model: model)

        case .formalSyllogism(_, let model):
            FormalSyllogismBlockView(model: model)

        case .memoryLayout(_, let model):
            MemoryLayoutBlockView(model: model)

        case .liveCell(_, let model):
            InteractiveLiveCellView(
                cellId: model.cellId,
                initialCode: model.initialCode
            )

        case .workshopStepper(_, let model):
            WorkshopStepperBlockView(model: model)

        case .markdown(_, let content):
            MarkdownTextBlockView(content: content)
        }
    }
}

// 1. 双语一手原典对照视图
struct BilingualPrimarySourceBlockView: View {
    let model: BilingualSourceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(StudyLineTheme.kintsugiGold)
                Text(model.citation.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .tracking(2)
                    .foregroundStyle(StudyLineTheme.kintsugiGold)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(model.originalText)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .lineSpacing(5)
                    .foregroundStyle(Color.primary.opacity(0.95))

                Divider()
                    .background(StudyLineTheme.kintsugiGold.opacity(0.3))

                Text(model.translationText)
                    .font(.system(size: 13, design: .serif))
                    .lineSpacing(5)
                    .foregroundStyle(Color.primary.opacity(0.85))
            }
            .padding(14)
            .background(Color.primary.opacity(0.03))
            .overlay(
                Rectangle()
                    .fill(StudyLineTheme.kintsugiGold)
                    .frame(width: 3),
                alignment: .leading
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// 2. 形式化论证三段论卡片
struct FormalSyllogismBlockView: View {
    let model: FormalSyllogismModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = model.title {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundStyle(StudyLineTheme.kintsugiGold)
            }

            VStack(alignment: .leading, spacing: 6) {
                syllogismLine(tag: "P1", text: model.p1, color: StudyLineTheme.cosmicUltramarine)
                syllogismLine(tag: "P2", text: model.p2, color: StudyLineTheme.cosmicUltramarine)
                if let r = model.reductio {
                    syllogismLine(tag: "R ", text: r, color: StudyLineTheme.cinnabarRed)
                }
                Divider()
                syllogismLine(tag: "C ", text: model.conclusion, color: StudyLineTheme.bambooGreen, isBold: true)
            }
            .padding(14)
            .background(Color.primary.opacity(0.025))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(StudyLineTheme.kintsugiGold.opacity(0.35), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func syllogismLine(tag: String, text: String, color: Color, isBold: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(tag)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(text)
                .font(.system(size: 12, weight: isBold ? .bold : .regular))
                .foregroundStyle(Color.primary.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// 3. 物理内存拓扑图视图
struct MemoryLayoutBlockView: View {
    let model: MemoryLayoutModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundColor(StudyLineTheme.cosmicUltramarine)
                Text(model.title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(model.arch)
                    .font(.system(size: 9, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(model.rawDiagram)
                .font(.system(size: 11, design: .monospaced))
                .lineSpacing(4)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// 4. 工坊 TDD 进度看板视图
struct WorkshopStepperBlockView: View {
    let model: WorkshopStepperModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(StudyLineTheme.kintsugiGold)
                    Text("工程实战工坊: \(model.title)")
                        .font(.system(size: 12, weight: .bold))
                }
                Text("运行 `./studyline workshop test \(model.workshopId)` 开启 TDD 自动化单测验收")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(StudyLineTheme.kintsugiGold.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(StudyLineTheme.kintsugiGold.opacity(0.3), lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// 5. 正文 Markdown 块视图
struct MarkdownTextBlockView: View {
    let content: String

    var body: some View {
        Text(content)
            .font(StudyLineTheme.Typography.body)
            .lineSpacing(6)
            .foregroundStyle(Color.primary.opacity(0.92))
            .textSelection(.enabled)
    }
}
