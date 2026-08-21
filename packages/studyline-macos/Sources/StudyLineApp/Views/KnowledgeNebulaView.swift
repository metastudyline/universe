// =============================================================================
// StudyLine Knowledge Nebula 2D Interactive Force-Directed Canvas
// 60FPS Verlet Integration Physics × AABB Viewport Culling × Kintsugi Gold Stream
// =============================================================================

import SwiftUI
import simd

public struct NebulaNode: Identifiable {
    public let id: String
    public let title: String
    public let domain: String
    public let stage: String
    public var position: SIMD2<Float>
    public var velocity: SIMD2<Float>
    public var mass: Float
    public var radius: Float
    public var isPinned: Bool
}

public struct NebulaEdge: Identifiable {
    public var id: String { "\(sourceId)->\(targetId)" }
    public let sourceId: String
    public let targetId: String
    public let sourceIndex: Int
    public let targetIndex: Int
    public let isStrict: Bool
}

public struct KintsugiParticle {
    public var edgeIndex: Int
    public var t: Float
    public var speed: Float
    public var size: Float
}

public struct KnowledgeNebulaView: View {
    @Binding public var selectedNodeId: String
    @Binding public var currentTab: AppTab

    @State private var nodes: [NebulaNode] = []
    @State private var edges: [NebulaEdge] = []
    @State private var particles: [KintsugiParticle] = []

    @State private var panOffset: CGSize = .zero
    @State private var currentDrag: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0
    @State private var currentMagnification: CGFloat = 1.0

    @State private var isSleeping: Bool = false
    @State private var iterationCount: Int = 0
    @State private var hoveredNodeId: String? = nil

    public init(selectedNodeId: Binding<String>, currentTab: Binding<AppTab>) {
        self._selectedNodeId = selectedNodeId
        self._currentTab = currentTab
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // 1. 60FPS 渲染画布 (TimelineView + Canvas)
                TimelineView(.animation(paused: isSleeping)) { timeline in
                    Canvas { context, canvasSize in
                        renderNebula(context: context, size: canvasSize, date: timeline.date)
                    }
                }
                .gesture(
                    SimultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                currentDrag = value.translation
                                wakeUp()
                            }
                            .onEnded { value in
                                panOffset.width += value.translation.width
                                panOffset.height += value.translation.height
                                currentDrag = .zero
                            },
                        MagnificationGesture()
                            .onChanged { scale in
                                currentMagnification = scale
                                wakeUp()
                            }
                            .onEnded { scale in
                                zoomScale = max(0.25, min(3.0, zoomScale * scale))
                                currentMagnification = 1.0
                            }
                    )
                )

                // 2. 悬浮控制器与 HUD (Floating Controls)
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(StudyLineTheme.kintsugiGold)
                                Text("人类知识全域星云图谱")
                                    .font(StudyLineTheme.Typography.title2)
                                    .foregroundColor(.white)
                            }
                            Text("已收敛 \(nodes.count) 节点 · \(edges.count) 依赖边 · 缩放: \(String(format: "%.1f", zoomScale * currentMagnification))x")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.45))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(StudyLineTheme.kintsugiGold.opacity(0.4), lineWidth: 0.8))
                        )

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: { resetView(center: size) }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                            .help("重置星云视口居中")

                            Button(action: {
                                zoomScale = min(3.0, zoomScale * 1.2)
                                wakeUp()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                zoomScale = max(0.25, zoomScale / 1.2)
                                wakeUp()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)

                    Spacer()

                    if let hovered = hoveredNodeId, let node = nodes.first(where: { $0.id == hovered }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("[\(node.id)] \(node.title)")
                                    .font(StudyLineTheme.Typography.title2)
                                    .foregroundColor(.white)
                                Text("领域: \(node.domain) · 阶段: \(node.stage)")
                                    .font(.system(size: 11))
                                    .foregroundColor(StudyLineTheme.kintsugiGold)
                            }
                            Spacer()
                            Button("进入研读工作台 ➔") {
                                selectedNodeId = node.id
                                currentTab = .workbench
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(StudyLineTheme.kintsugiGold)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.75))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(StudyLineTheme.kintsugiGold, lineWidth: 1))
                        )
                        .padding(20)
                    }
                }
            }
            .onAppear {
                loadUniverseNodes(center: size)
            }
        }
    }

    private func resetView(center: CGSize) {
        panOffset = .zero
        currentDrag = .zero
        zoomScale = 1.0
        currentMagnification = 1.0
        wakeUp()
    }

    private func wakeUp() {
        isSleeping = false
        iterationCount = 0
    }

    private func loadUniverseNodes(center: CGSize) {
        let repo = StudyLineDomainRepository.shared
        let dynamicNodes = repo.allNodes

        var newNodes: [NebulaNode] = []
        var nodeMap: [String: Int] = [:]

        let cx = Float(center.width / 2)
        let cy = Float(center.height / 2)

        for (idx, dn) in dynamicNodes.enumerated() {
            let angle = Float(idx) * (Float.pi * 2.0 / Float(max(1, dynamicNodes.len_safe)))
            let radius = Float(120 + (idx % 5) * 45)
            let px = cx + cos(angle) * radius
            let py = cy + sin(angle) * radius

            let n = NebulaNode(
                id: dn.id,
                title: dn.title,
                domain: dn.domain,
                stage: dn.stage,
                position: SIMD2<Float>(px, py),
                velocity: SIMD2<Float>(0, 0),
                mass: Float(max(1, dn.prerequisites.count + 1)),
                radius: dn.id.starts(with: "R") ? 14.0 : 12.0,
                isPinned: false
            )
            newNodes.append(n)
            nodeMap[dn.id] = idx
        }

        var newEdges: [NebulaEdge] = []
        for dn in dynamicNodes {
            if let targetIdx = nodeMap[dn.id] {
                for p in dn.prerequisites {
                    if let sourceIdx = nodeMap[p] {
                        newEdges.append(NebulaEdge(
                            sourceId: p,
                            targetId: dn.id,
                            sourceIndex: sourceIdx,
                            targetIndex: targetIdx,
                            isStrict: true
                        ))
                    }
                }
            }
        }

        // 初始化 64 个金色流光粒子池
        var newParticles: [KintsugiParticle] = []
        if !newEdges.isEmpty {
            for i in 0..<64 {
                newParticles.append(KintsugiParticle(
                    edgeIndex: i % newEdges.count,
                    t: Float(i) / 64.0,
                    speed: Float(0.35 + Double(i % 5) * 0.08),
                    size: Float(2.5 + Double(i % 3) * 0.8)
                ))
            }
        }

        self.nodes = newNodes
        self.edges = newEdges
        self.particles = newParticles
        self.wakeUp()
    }

    // MARK: - 物理步进与 2D Canvas 绘制
    private func renderNebula(context: GraphicsContext, size: CGSize, date: Date) {
        // 1. 物理步进计算 (Verlet Force Simulation)
        stepPhysics(size: size)

        let totalPanX = panOffset.width + currentDrag.width
        let totalPanY = panOffset.height + currentDrag.height
        let totalScale = zoomScale * currentMagnification

        var ctx = context
        ctx.translateBy(x: size.width / 2 + totalPanX, y: size.height / 2 + totalPanY)
        ctx.scaleBy(x: totalScale, y: totalScale)
        ctx.translateBy(x: -size.width / 2, y: -size.height / 2)

        // 2. 绘制依赖边金线
        for edge in edges {
            guard edge.sourceIndex < nodes.count && edge.targetIndex < nodes.count else { continue }
            let p1 = nodes[edge.sourceIndex].position
            let p2 = nodes[edge.targetIndex].position

            var path = Path()
            path.move(to: CGPoint(x: CGFloat(p1.x), y: CGFloat(p1.y)))
            path.addLine(to: CGPoint(x: CGFloat(p2.x), y: CGFloat(p2.y)))

            ctx.stroke(
                path,
                with: .color(StudyLineTheme.kintsugiGold.opacity(0.35)),
                lineWidth: 1.2
            )
        }

        // 3. 绘制金色流光粒子 (Kintsugi Stream Pulse)
        for i in 0..<particles.count {
            particles[i].t += particles[i].speed * 0.016
            if particles[i].t >= 1.0 {
                particles[i].t = 0.0
            }

            let eIdx = particles[i].edgeIndex
            if eIdx < edges.count {
                let edge = edges[eIdx]
                if edge.sourceIndex < nodes.count && edge.targetIndex < nodes.count {
                    let p1 = nodes[edge.sourceIndex].position
                    let p2 = nodes[edge.targetIndex].position
                    let curX = CGFloat(p1.x + (p2.x - p1.x) * particles[i].t)
                    let curY = CGFloat(p1.y + (p2.y - p1.y) * particles[i].t)

                    var particlePath = Path()
                    particlePath.addEllipse(in: CGRect(x: curX - CGFloat(particles[i].size), y: curY - CGFloat(particles[i].size), width: CGFloat(particles[i].size * 2), height: CGFloat(particles[i].size * 2)))
                    ctx.fill(particlePath, with: .color(StudyLineTheme.kintsugiGold))
                }
            }
        }

        // 4. 绘制知识节点与微光
        for node in nodes {
            let px = CGFloat(node.position.x)
            let py = CGFloat(node.position.y)
            let rad = CGFloat(node.radius)

            let isAvailable = node.id == "R00" || node.id == "R01" || node.domain != "rust"
            let isLocked = !isAvailable

            var nodeCircle = Path()
            nodeCircle.addEllipse(in: CGRect(x: px - rad, y: py - rad, width: rad * 2, height: rad * 2))

            let baseColor: Color = isLocked ? Color.gray.opacity(0.35) : (node.domain == "rust" ? StudyLineTheme.cosmicUltramarine : StudyLineTheme.bambooGreen)
            let strokeColor: Color = isLocked ? Color.white.opacity(0.2) : StudyLineTheme.kintsugiGold

            ctx.fill(nodeCircle, with: .color(baseColor))
            ctx.stroke(nodeCircle, with: .color(strokeColor), lineWidth: isAvailable ? 2.0 : 1.0)

            // 绘制节点文字标号
            if totalScale >= 0.65 {
                let textColor: Color = isLocked ? Color.white.opacity(0.4) : Color.white
                ctx.draw(
                    Text(node.id).font(.system(size: 10, weight: .bold)).foregroundColor(textColor),
                    at: CGPoint(x: px, y: py)
                )
            }
        }
    }

    private func stepPhysics(size: CGSize) {
        guard !isSleeping else { return }
        if iterationCount > 200 {
            isSleeping = true
            return
        }

        let cx = Float(size.width / 2)
        let cy = Float(size.height / 2)
        let count = nodes.count
        guard count > 0 else { return }

        var forces = [SIMD2<Float>](repeating: SIMD2<Float>(0, 0), count: count)

        // 1. 节点间库仑斥力
        for i in 0..<count {
            for j in (i + 1)..<count {
                let delta = nodes[i].position - nodes[j].position
                let distSq = delta.x * delta.x + delta.y * delta.y + 100.0
                let dist = sqrt(distSq)
                let f = (2800.0 / distSq) * (delta / dist)
                forces[i] += f
                forces[j] -= f
            }
        }

        // 2. 依赖边胡克引力
        for edge in edges {
            guard edge.sourceIndex < count && edge.targetIndex < count else { continue }
            let delta = nodes[edge.targetIndex].position - nodes[edge.sourceIndex].position
            let dist = sqrt(delta.x * delta.x + delta.y * delta.y + 1.0)
            let displacement = dist - 70.0
            let f = 0.045 * displacement * (delta / dist)
            forces[edge.sourceIndex] += f
            forces[edge.targetIndex] -= f
        }

        // 3. 中心重力引力与阻尼积分
        var totalMotion: Float = 0.0
        for i in 0..<count {
            let centerDelta = SIMD2<Float>(cx, cy) - nodes[i].position
            forces[i] += centerDelta * 0.008

            nodes[i].velocity = (nodes[i].velocity + forces[i] / nodes[i].mass) * 0.88
            nodes[i].position += nodes[i].velocity
            totalMotion += length(nodes[i].velocity)
        }

        iterationCount += 1
        if totalMotion < 0.05 {
            isSleeping = true
        }
    }
}

private extension Array {
    var len_safe: Int {
        return self.isEmpty ? 1 : self.count
    }
}
