// =============================================================================
// StudyLine macOS Native Theme & Visual Material Tokens
// TTZip Zen Philosophy × WSJ Editorial Typography × Apple Silicon Fluid Glass
// Signature Theme: Cosmic Ultramarine × Kintsugi Gold × Bamboo Green
// =============================================================================

import SwiftUI
import AppKit

public enum StudyLineTheme {
    // MARK: - 1. Signature Color Palette (签名色彩系统)
    
    /// Cosmic Ultramarine (#1E3A8A / #3B82F6) — 雅典娜深空群青 / 宇宙原点核心签名色
    public static let cosmicUltramarine = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return NSColor(red: 59.0 / 255.0, green: 130.0 / 255.0, blue: 246.0 / 255.0, alpha: 1.0)
        } else {
            return NSColor(red: 30.0 / 255.0, green: 58.0 / 255.0, blue: 138.0 / 255.0, alpha: 1.0)
        }
    }))

    /// Kintsugi Gold (#D4AF37 / #E5C158) — 金缮金线高光，用于主要学线、顶栏 Golden Line 及出段勋章
    public static let kintsugiGold = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return NSColor(red: 230.0 / 255.0, green: 195.0 / 255.0, blue: 92.0 / 255.0, alpha: 1.0)
        } else {
            return NSColor(red: 212.0 / 255.0, green: 175.0 / 255.0, blue: 55.0 / 255.0, alpha: 1.0)
        }
    }))

    /// Bamboo Green (#2E8B57 / #8FA876) — 竹青色，代表 Rust 内存安全、单测通过与知识掌握
    public static let bambooGreen = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return NSColor(red: 143.0 / 255.0, green: 168.0 / 255.0, blue: 118.0 / 255.0, alpha: 1.0)
        } else {
            return NSColor(red: 120.0 / 255.0, green: 146.0 / 255.0, blue: 98.0 / 255.0, alpha: 1.0)
        }
    }))

    /// Cinnabar Red (#C84B31 / #E05A47) — 朱砂红，用于活火概念、重要警示与高阶推演难点
    public static let cinnabarRed = Color(red: 0.82, green: 0.35, blue: 0.28)

    /// Deep Graphite (#0E1117 / #1C1C1E) — 暗色模式下的深空石墨底色
    public static let deepGraphite = Color(red: 0.08, green: 0.09, blue: 0.11)

    /// Washi Paper (#FBFBF9) — 和纸白
    public static let washiPaper = Color(red: 0.98, green: 0.98, blue: 0.97)

    /// Hairline border (0.5pt / 0.8pt) — 超细发丝边框
    public static var hairlineBorder: Color {
        Color(nsColor: .separatorColor).opacity(0.35)
    }

    // MARK: - 2. Typography Ramp (WSJ Editorial 字体阶梯)
    public enum Typography {
        public static let wsjHeadline = Font.system(size: 26, weight: .light, design: .serif)
        public static let wsjSubheadline = Font.system(size: 18, weight: .medium, design: .serif)
        public static let displayTitle = Font.system(size: 22, weight: .semibold, design: .serif)
        public static let title1 = Font.system(size: 18, weight: .semibold, design: .serif)
        public static let title2 = Font.system(size: 15, weight: .medium, design: .default)
        public static let sectionHeader = Font.system(size: 13, weight: .semibold, design: .default)
        public static let body = Font.system(size: 13, weight: .regular, design: .default)
        public static let bodyMedium = Font.system(size: 13, weight: .medium, design: .default)
        public static let callout = Font.system(size: 12, weight: .regular, design: .default)
        public static let subheadline = Font.system(size: 11, weight: .regular, design: .default)
        public static let caption = Font.system(size: 10, weight: .regular, design: .default)
        public static let codeCaption = Font.system(size: 11, weight: .regular, design: .monospaced)
    }

    // MARK: - 3. Spacing Grid
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 36
    }

    // MARK: - 4. Corner Radius Ramp
    public enum Radius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 6
        public static let md: CGFloat = 10
        public static let lg: CGFloat = 14
        public static let xl: CGFloat = 18
        public static let xxl: CGFloat = 22
    }
}

// 兼容旧版引用别名
public typealias TTZipTheme = StudyLineTheme

// MARK: - 5. Visual Effect Blur Representable (macOS 原生磨砂玻璃)
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .withinWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - 6. StudyLine Liquid Glass Card ViewModifier
public struct StudyLineLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat
    @Environment(\.colorScheme) var colorScheme

    public init(
        cornerRadius: CGFloat = StudyLineTheme.Radius.lg,
        padding: CGFloat = StudyLineTheme.Spacing.md
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    colorScheme == .dark
                        ? Color.white.opacity(0.025)
                        : Color.white.opacity(0.65)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color.black.opacity(0.06),
                        lineWidth: 0.6
                    )
            )
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.04),
                radius: colorScheme == .dark ? 8 : 10,
                x: 0,
                y: 3
            )
    }
}

public extension View {
    func studylineLiquidGlass(
        cornerRadius: CGFloat = StudyLineTheme.Radius.lg,
        padding: CGFloat = StudyLineTheme.Spacing.md
    ) -> some View {
        self.modifier(StudyLineLiquidGlassModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func ttzipLiquidGlass(
        cornerRadius: CGFloat = StudyLineTheme.Radius.lg,
        padding: CGFloat = StudyLineTheme.Spacing.md
    ) -> some View {
        self.modifier(StudyLineLiquidGlassModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - 7. 52pt 标准顶栏组件 (包含 Y=90pt 金线绝对对齐)
public struct StudyLineHeaderBar: View {
    public let sectionName: String
    public let title: String
    public let badgeText: String?

    public init(sectionName: String, title: String, badgeText: String? = nil) {
        self.sectionName = sectionName
        self.title = title
        self.badgeText = badgeText
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(sectionName)
                        .font(.system(size: 9, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(StudyLineTheme.kintsugiGold)
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                if let badge = badgeText {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundStyle(StudyLineTheme.bambooGreen)
                        Text(badge)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(StudyLineTheme.bambooGreen)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(StudyLineTheme.bambooGreen.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)

            Rectangle()
                .fill(StudyLineTheme.kintsugiGold)
                .frame(height: 1.5)
        }
        .padding(.top, 38) // 38pt + 52pt = 90pt 金线绝对对齐
    }
}

public typealias TTZipHeaderBar = StudyLineHeaderBar
