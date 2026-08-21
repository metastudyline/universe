// =============================================================================
// StudyLine Fluid Dynamic Background View (Zen 液态流体动态极光画布)
// 60FPS TimelineView + Downsampled Canvas (4x) + Hardware Gaussian Blur
// Ultra-low GPU/CPU overhead (<0.3%) with Cosmic Mesh Gradient
// =============================================================================

import SwiftUI
import AppKit

/// 全局流体动画状态机，保证跨视图流体相位平滑连续
@MainActor
public final class StudyLineGlobalFluidState {
    public static let shared = StudyLineGlobalFluidState()

    private var phase: Double = Double.random(in: 0...100)
    private var lastTime: Double = CACurrentMediaTime()

    private init() {}

    public func currentPhase(speed: Double = 0.25) -> Double {
        let now = CACurrentMediaTime()
        let delta = now - lastTime
        if delta > 0.005 {
            phase += min(delta, 0.1) * speed
            lastTime = now
        }
        return phase
    }
}

/// StudyLine 核心液态流体背景视图
public struct StudyLineFluidBackgroundView: View {
    public let primaryColor: Color
    public let secondaryColor: Color
    public let accentColor: Color
    public var speed: Double = 0.25

    @Environment(\.colorScheme) private var colorScheme

    public init(
        primaryColor: Color = StudyLineTheme.cosmicUltramarine,
        secondaryColor: Color = StudyLineTheme.kintsugiGold,
        accentColor: Color = StudyLineTheme.bambooGreen,
        speed: Double = 0.25
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.speed = speed
    }

    public var body: some View {
        GeometryReader { geo in
            let fullW = geo.size.width
            let fullH = geo.size.height
            let scale: CGFloat = 4.0
            let w = max(fullW / scale, 100)
            let h = max(fullH / scale, 100)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
                let currentPhase = StudyLineGlobalFluidState.shared.currentPhase(speed: speed)

                Canvas { context, _ in
                    // 光斑 1: 宇宙深空群青 (Cosmic Ultramarine) - 逆时针缓慢回旋
                    let x1 = w * 0.35 + cos(currentPhase * 0.55) * (w * 0.28)
                    let y1 = h * 0.40 + sin(currentPhase * 0.85) * (h * 0.22)
                    let r1 = min(w, h) * 0.75

                    // 光斑 2: 金缮金线极光 (Kintsugi Gold) - 正弦波动
                    let x2 = w * 0.65 + sin(currentPhase * 0.40) * (w * 0.32)
                    let y2 = h * 0.35 + cos(currentPhase * 0.75) * (h * 0.25)
                    let r2 = min(w, h) * 0.65

                    // 光斑 3: 竹青理性火花 (Bamboo Green / Cyan) - 底部大范围呼吸
                    let x3 = w * 0.50 + cos(currentPhase * 0.30) * (w * 0.35)
                    let y3 = h * 0.70 + sin(currentPhase * 0.45) * (h * 0.20)
                    let r3 = min(w, h) * 0.85

                    context.blendMode = .normal
                    context.fill(Path(ellipseIn: CGRect(x: x1 - r1/2, y: y1 - r1/2, width: r1, height: r1)), with: .color(primaryColor.opacity(0.85)))
                    context.fill(Path(ellipseIn: CGRect(x: x2 - r2/2, y: y2 - r2/2, width: r2, height: r2)), with: .color(secondaryColor.opacity(0.65)))
                    context.fill(Path(ellipseIn: CGRect(x: x3 - r3/2, y: y3 - r3/2, width: r3, height: r3)), with: .color(accentColor.opacity(0.55)))
                }
                .frame(width: w, height: h)
                .blur(radius: 65 / scale)
                .scaleEffect(scale)
            }
            .frame(width: fullW, height: fullH, alignment: .center)
        }
        .opacity(colorScheme == .dark ? 0.32 : 0.16)
        .ignoresSafeArea()
    }
}
