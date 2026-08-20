// =============================================================================
// StudyLine macOS Native Theme & Visual Material Tokens (TTZip Design System)
// Zen Philosophy × WSJ Editorial Typography × Apple Silicon Liquid Glass
// =============================================================================

import SwiftUI
import AppKit

public struct TTZipTheme {
    public static let kintsugiGold   = Color(red: 212/255, green: 175/255, blue: 55/255)   // #D4AF37
    public static let bambooGreen    = Color(red: 46/255,  green: 139/255, blue: 87/255)   // #2E8B57
    public static let cinnabarRed    = Color(red: 200/255, green: 75/255,  blue: 49/255)   // #C84B31
    public static let deepGraphite   = Color(red: 28/255,  green: 28/255,  blue: 30/255)   // #1C1C1E
    public static let inkBlack       = Color(red: 11/255,  green: 11/255,  blue: 12/255)   // #0B0B0C
    public static let washiPaper     = Color(red: 251/255, green: 251/255, blue: 253/255) // #FBFBFD
    public static let hairlineBorder = Color.primary.opacity(0.08)
}

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

public struct TTZipHeaderBar: View {
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
                        .foregroundStyle(TTZipTheme.kintsugiGold)
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                if let badge = badgeText {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundStyle(TTZipTheme.bambooGreen)
                        Text(badge)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(TTZipTheme.bambooGreen)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(TTZipTheme.bambooGreen.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)

            Rectangle()
                .fill(TTZipTheme.kintsugiGold)
                .frame(height: 1.5)
        }
        .padding(.top, 38) // 38pt + 52pt = 90pt 金线绝对对齐
    }
}
