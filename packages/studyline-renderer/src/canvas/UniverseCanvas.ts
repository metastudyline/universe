// =============================================================================
// StudyLine Universe Canvas Engine (First-Principles High-Performance Edition)
// 60FPS zero-GC particle pool, Smootherstep LOD, and Kintsugi Gold learning pulses
// =============================================================================

import { SpatialIndex, SpatialItem } from "./SpatialIndex";
import { LODManager, LODLevel } from "./LODManager";

export interface NodeVisual extends SpatialItem {
    id: string;
    title: string;
    genre: "lead" | "reading" | "synthesis" | "spinoff";
    spine: boolean;
    mastery: number;
    lines: string;
    clusterId: string;
}

export interface EdgeVisual {
    from: string;
    to: string;
    type: "strict" | "supporting";
    golden: boolean;
}

export interface UniverseData {
    nodes: NodeVisual[];
    edges: EdgeVisual[];
    clusters: { id: string; title: string; x: number; y: number }[];
}

// Interleaved Particle Structure in Float32Array:
// [progress_t, speed, from_x, from_y, to_x, to_y] (STRIDE = 6)
const PARTICLE_STRIDE = 6;
const MAX_PARTICLES = 2048;

export class UniverseCanvas {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private data: UniverseData;
    private spatialIndex: SpatialIndex<NodeVisual>;
    private lodManager = new LODManager();

    // Viewport transform state
    private offsetX = 0;
    private offsetY = 0;
    private zoom = 1.0;

    // Interaction state
    private isDragging = false;
    private lastMouseX = 0;
    private lastMouseY = 0;
    private hoveredNode: NodeVisual | null = null;
    private highlightedPath = new Set<string>();
    private onNodeSelectCallback?: (node: NodeVisual) => void;

    // Zero-GC Particle Pool
    private particlePool = new Float32Array(MAX_PARTICLES * PARTICLE_STRIDE);
    private activeParticleCount = 0;

    // Animation & Loop state
    private pulsePhase = 0;
    private isRunning = false;

    constructor(canvas: HTMLCanvasElement, data: UniverseData) {
        this.canvas = canvas;
        const context = canvas.getContext("2d");
        if (!context) throw new Error("Canvas 2D context not available");
        this.ctx = context;
        this.data = data;

        // Initialize spatial index
        this.spatialIndex = new SpatialIndex({
            minX: -3000,
            minY: -3000,
            maxX: 3000,
            maxY: 3000
        });

        for (const node of data.nodes) {
            node.radius = node.spine ? 18 : 10;
            this.spatialIndex.insert(node);
        }

        this.initParticlePool();
        this.initEvents();
        this.resize();
    }

    private initParticlePool(): void {
        const goldenEdges = this.data.edges.filter(e => e.golden);
        const nodeMap = new Map(this.data.nodes.map(n => [n.id, n]));
        let pIndex = 0;

        for (const edge of goldenEdges) {
            const from = nodeMap.get(edge.from);
            const to = nodeMap.get(edge.to);
            if (!from || !to) continue;

            // Allocate 2 particles per golden edge
            for (let k = 0; k < 2; k++) {
                if (pIndex >= MAX_PARTICLES) break;
                const offset = pIndex * PARTICLE_STRIDE;
                this.particlePool[offset + 0] = (k * 0.5 + Math.random() * 0.2) % 1.0; // t
                this.particlePool[offset + 1] = 0.008 + Math.random() * 0.004;         // speed
                this.particlePool[offset + 2] = from.x;                                 // from_x
                this.particlePool[offset + 3] = from.y;                                 // from_y
                this.particlePool[offset + 4] = to.x;                                   // to_x
                this.particlePool[offset + 5] = to.y;                                   // to_y
                pIndex++;
            }
        }
        this.activeParticleCount = pIndex;
    }

    public setOnNodeSelect(callback: (node: NodeVisual) => void): void {
        this.onNodeSelectCallback = callback;
    }

    public highlightShortestPath(nodeIds: string[]): void {
        this.highlightedPath = new Set(nodeIds);
        this.rebuildPathParticles();
    }

    public clearHighlight(): void {
        this.highlightedPath.clear();
        this.initParticlePool();
    }

    private rebuildPathParticles(): void {
        const nodeMap = new Map(this.data.nodes.map(n => [n.id, n]));
        let pIndex = 0;

        for (const edge of this.data.edges) {
            const isPath = this.highlightedPath.has(edge.from) && this.highlightedPath.has(edge.to);
            if (!isPath && !edge.golden) continue;

            const from = nodeMap.get(edge.from);
            const to = nodeMap.get(edge.to);
            if (!from || !to) continue;

            for (let k = 0; k < 3; k++) {
                if (pIndex >= MAX_PARTICLES) break;
                const offset = pIndex * PARTICLE_STRIDE;
                this.particlePool[offset + 0] = (k * 0.33 + Math.random() * 0.1) % 1.0;
                this.particlePool[offset + 1] = 0.012 + Math.random() * 0.004;
                this.particlePool[offset + 2] = from.x;
                this.particlePool[offset + 3] = from.y;
                this.particlePool[offset + 4] = to.x;
                this.particlePool[offset + 5] = to.y;
                pIndex++;
            }
        }
        this.activeParticleCount = pIndex;
    }

    public focusNode(nodeId: string): void {
        const target = this.data.nodes.find(n => n.id === nodeId);
        if (!target) return;
        this.offsetX = this.canvas.clientWidth / 2 - target.x * this.zoom;
        this.offsetY = this.canvas.clientHeight / 2 - target.y * this.zoom;
    }

    public fitView(): void {
        if (this.data.nodes.length === 0) return;
        let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
        for (const n of this.data.nodes) {
            minX = Math.min(minX, n.x);
            maxX = Math.max(maxX, n.x);
            minY = Math.min(minY, n.y);
            maxY = Math.max(maxY, n.y);
        }
        const w = this.canvas.clientWidth;
        const h = this.canvas.clientHeight;
        const dx = maxX - minX + 200;
        const dy = maxY - minY + 200;
        this.zoom = Math.min(Math.max(Math.min(w / dx, h / dy), 0.4), 1.6);
        this.offsetX = w / 2 - ((minX + maxX) / 2) * this.zoom;
        this.offsetY = h / 2 - ((minY + maxY) / 2) * this.zoom;
    }

    public zoomIn(): void {
        this.zoom = Math.min(this.zoom * 1.25, 3.5);
    }

    public zoomOut(): void {
        this.zoom = Math.max(this.zoom * 0.8, 0.2);
    }

    public start(): void {
        if (this.isRunning) return;
        this.isRunning = true;
        const loop = () => {
            if (!this.isRunning) return;
            this.pulsePhase = (this.pulsePhase + 0.025) % (Math.PI * 2);
            this.updateParticles();
            this.render();
            requestAnimationFrame(loop);
        };
        requestAnimationFrame(loop);
    }

    private updateParticles(): void {
        for (let i = 0; i < this.activeParticleCount; i++) {
            const offset = i * PARTICLE_STRIDE;
            let t = this.particlePool[offset + 0] + this.particlePool[offset + 1];
            if (t > 1.0) t -= 1.0;
            this.particlePool[offset + 0] = t;
        }
    }

    public stop(): void {
        this.isRunning = false;
    }

    private resize(): void {
        const dpr = window.devicePixelRatio || 1;
        this.canvas.width = this.canvas.clientWidth * dpr;
        this.canvas.height = this.canvas.clientHeight * dpr;
        this.ctx.scale(dpr, dpr);
        this.fitView();
    }

    private initEvents(): void {
        window.addEventListener("resize", () => this.resize());

        this.canvas.addEventListener("mousedown", (e) => {
            this.isDragging = true;
            this.lastMouseX = e.clientX;
            this.lastMouseY = e.clientY;
        });

        window.addEventListener("mousemove", (e) => {
            if (this.isDragging) {
                this.offsetX += e.clientX - this.lastMouseX;
                this.offsetY += e.clientY - this.lastMouseY;
                this.lastMouseX = e.clientX;
                this.lastMouseY = e.clientY;
            } else {
                this.updateHover(e.clientX, e.clientY);
            }
        });

        window.addEventListener("mouseup", () => {
            this.isDragging = false;
        });

        this.canvas.addEventListener("wheel", (e) => {
            e.preventDefault();
            const zoomFactor = e.deltaY < 0 ? 1.08 : 0.92;
            const newZoom = Math.min(Math.max(this.zoom * zoomFactor, 0.15), 3.5);

            const rect = this.canvas.getBoundingClientRect();
            const mouseX = e.clientX - rect.left;
            const mouseY = e.clientY - rect.top;

            this.offsetX = mouseX - (mouseX - this.offsetX) * (newZoom / this.zoom);
            this.offsetY = mouseY - (mouseY - this.offsetY) * (newZoom / this.zoom);
            this.zoom = newZoom;
        }, { passive: false });

        this.canvas.addEventListener("click", () => {
            if (this.hoveredNode && this.onNodeSelectCallback) {
                this.onNodeSelectCallback(this.hoveredNode);
            }
        });
    }

    private updateHover(clientX: number, clientY: number): void {
        const rect = this.canvas.getBoundingClientRect();
        const screenX = clientX - rect.left;
        const screenY = clientY - rect.top;

        const worldX = (screenX - this.offsetX) / this.zoom;
        const worldY = (screenY - this.offsetY) / this.zoom;

        const hit = this.data.nodes.find(n => {
            const dx = n.x - worldX;
            const dy = n.y - worldY;
            return Math.sqrt(dx * dx + dy * dy) <= (n.radius + 8);
        });

        this.hoveredNode = hit || null;
        this.canvas.style.cursor = hit ? "pointer" : "default";
    }

    private render(): void {
        const { clientWidth: width, clientHeight: height } = this.canvas;
        this.ctx.clearRect(0, 0, width, height);

        // 1. Draw Zen Cosmic Deep Background & Golden Dust Grid
        this.drawSpaceBackground(width, height);

        const lod = this.lodManager.getLODState(this.zoom);

        // 2. Draw Cluster Nebula Halos (LOD 0 Smootherstep Alpha)
        if (lod.alphaGalaxy > 0.01) {
            for (const cluster of this.data.clusters) {
                this.drawClusterHalo(cluster, lod.alphaGalaxy);
            }
        }

        // 3. Draw Kintsugi Gold Dependency Edges & Golden Stream
        this.drawEdges(lod);

        // 4. Batch Draw Gold Flowing Stream Particles (Zero-GC)
        this.drawStreamParticles();

        // 5. Draw Nodes with Dual Rings & Mastery Arc (LOD 1 & 2)
        this.drawNodes(lod, width, height);
    }

    private drawSpaceBackground(w: number, h: number): void {
        this.ctx.save();
        const bgGrad = this.ctx.createRadialGradient(w / 2, h / 2, 50, w / 2, h / 2, Math.max(w, h));
        bgGrad.addColorStop(0, "#121215");
        bgGrad.addColorStop(1, "#0B0B0C");
        this.ctx.fillStyle = bgGrad;
        this.ctx.fillRect(0, 0, w, h);

        this.ctx.strokeStyle = "rgba(212, 175, 55, 0.025)";
        this.ctx.lineWidth = 0.8;
        const gridSize = 100 * this.zoom;
        const startX = this.offsetX % gridSize;
        const startY = this.offsetY % gridSize;

        for (let x = startX; x < w; x += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(x, 0);
            this.ctx.lineTo(x, h);
            this.ctx.stroke();
        }
        for (let y = startY; y < h; y += gridSize) {
            this.ctx.beginPath();
            this.ctx.moveTo(0, y);
            this.ctx.lineTo(w, y);
            this.ctx.stroke();
        }
        this.ctx.restore();
    }

    private drawClusterHalo(cluster: { id: string; title: string; x: number; y: number }, alpha: number): void {
        const screenX = cluster.x * this.zoom + this.offsetX;
        const screenY = cluster.y * this.zoom + this.offsetY;

        this.ctx.save();
        const gradient = this.ctx.createRadialGradient(screenX, screenY, 20, screenX, screenY, 320 * this.zoom);
        gradient.addColorStop(0, `rgba(212, 175, 55, ${0.08 * alpha})`);
        gradient.addColorStop(0.6, `rgba(212, 175, 55, ${0.02 * alpha})`);
        gradient.addColorStop(1, "rgba(0, 0, 0, 0)");
        this.ctx.fillStyle = gradient;
        this.ctx.beginPath();
        this.ctx.arc(screenX, screenY, 320 * this.zoom, 0, Math.PI * 2);
        this.ctx.fill();

        if (this.zoom < 0.6) {
            this.ctx.font = "bold 12px Newsreader, serif";
            this.ctx.fillStyle = `rgba(212, 175, 55, ${0.65 * alpha})`;
            this.ctx.textAlign = "center";
            this.ctx.fillText(cluster.title, screenX, screenY - 60 * this.zoom);
        }
        this.ctx.restore();
    }

    private drawEdges(lod: { level: LODLevel; alphaSpine: number; alphaLeaf: number }): void {
        this.ctx.save();
        const nodeMap = new Map(this.data.nodes.map(n => [n.id, n]));

        for (const edge of this.data.edges) {
            const from = nodeMap.get(edge.from);
            const to = nodeMap.get(edge.to);
            if (!from || !to) continue;

            const isGolden = edge.golden || (this.highlightedPath.has(edge.from) && this.highlightedPath.has(edge.to));
            const x1 = from.x * this.zoom + this.offsetX;
            const y1 = from.y * this.zoom + this.offsetY;
            const x2 = to.x * this.zoom + this.offsetX;
            const y2 = to.y * this.zoom + this.offsetY;

            this.ctx.beginPath();
            if (isGolden) {
                this.ctx.strokeStyle = "#D4AF37";
                this.ctx.lineWidth = 2.4;
                this.ctx.shadowColor = "rgba(212, 175, 55, 0.6)";
                this.ctx.shadowBlur = 12;
                this.ctx.setLineDash([]);
            } else if (edge.type === "supporting") {
                this.ctx.strokeStyle = `rgba(255, 255, 255, ${0.12 * lod.alphaLeaf})`;
                this.ctx.lineWidth = 0.9;
                this.ctx.setLineDash([4, 4]);
            } else {
                this.ctx.strokeStyle = `rgba(255, 255, 255, ${0.22 * lod.alphaSpine})`;
                this.ctx.lineWidth = 1.2;
                this.ctx.setLineDash([]);
            }

            const midX = (x1 + x2) / 2;
            const midY = (y1 + y2) / 2 - 20 * this.zoom;
            this.ctx.quadraticCurveTo(midX, midY, x2, y2);
            this.ctx.stroke();
        }
        this.ctx.restore();
    }

    private drawStreamParticles(): void {
        if (this.activeParticleCount === 0) return;
        this.ctx.save();
        this.ctx.fillStyle = "#FFFFFF";
        this.ctx.shadowColor = "#D4AF37";
        this.ctx.shadowBlur = 10;
        this.ctx.beginPath();

        for (let i = 0; i < this.activeParticleCount; i++) {
            const offset = i * PARTICLE_STRIDE;
            const t = this.particlePool[offset + 0];
            const fx = this.particlePool[offset + 2] * this.zoom + this.offsetX;
            const fy = this.particlePool[offset + 3] * this.zoom + this.offsetY;
            const tx = this.particlePool[offset + 4] * this.zoom + this.offsetX;
            const ty = this.particlePool[offset + 5] * this.zoom + this.offsetY;

            const midX = (fx + tx) / 2;
            const midY = (fy + ty) / 2 - 20 * this.zoom;

            const px = (1 - t) * (1 - t) * fx + 2 * (1 - t) * t * midX + t * t * tx;
            const py = (1 - t) * (1 - t) * fy + 2 * (1 - t) * t * midY + t * t * ty;

            this.ctx.moveTo(px + 2.5, py);
            this.ctx.arc(px, py, 2.5, 0, Math.PI * 2);
        }
        this.ctx.fill();
        this.ctx.restore();
    }

    private drawNodes(lod: { level: LODLevel; alphaDetail: number; alphaLeaf: number }, w: number, h: number): void {
        const viewportBox = {
            minX: (-this.offsetX) / this.zoom,
            minY: (-this.offsetY) / this.zoom,
            maxX: (w - this.offsetX) / this.zoom,
            maxY: (h - this.offsetY) / this.zoom
        };

        const visibleNodes = this.spatialIndex.queryViewport(viewportBox);

        for (const node of visibleNodes) {
            const screenX = node.x * this.zoom + this.offsetX;
            const screenY = node.y * this.zoom + this.offsetY;
            const isHovered = this.hoveredNode?.id === node.id;
            const isHighlighted = this.highlightedPath.has(node.id);

            this.ctx.save();

            // 1. Outer Breath Glow
            if (node.spine || isHighlighted || isHovered) {
                const glowRadius = (node.radius + (isHovered ? 12 : 6)) * this.zoom;
                const glow = this.ctx.createRadialGradient(screenX, screenY, node.radius * this.zoom, screenX, screenY, glowRadius);
                glow.addColorStop(0, "rgba(212, 175, 55, 0.45)");
                glow.addColorStop(1, "rgba(212, 175, 55, 0)");
                this.ctx.fillStyle = glow;
                this.ctx.beginPath();
                this.ctx.arc(screenX, screenY, glowRadius, 0, Math.PI * 2);
                this.ctx.fill();
            }

            // 2. Node Core Solid Disc
            this.ctx.beginPath();
            this.ctx.arc(screenX, screenY, node.radius * this.zoom, 0, Math.PI * 2);

            if (node.genre === "synthesis") {
                this.ctx.fillStyle = "#D4AF37";
            } else if (node.genre === "spinoff") {
                this.ctx.fillStyle = "#4B5563";
            } else {
                this.ctx.fillStyle = node.spine ? "#1E293B" : "#0F172A";
            }
            this.ctx.fill();

            // 3. Kintsugi Gold Dual Ring Outline
            this.ctx.strokeStyle = isHovered ? "#FFF" : (node.spine ? "#D4AF37" : "rgba(255, 255, 255, 0.35)");
            this.ctx.lineWidth = node.spine ? 2 : 1;
            this.ctx.stroke();

            // 4. Mastery Circular Progress Arc
            if (node.mastery > 0) {
                const startAngle = -Math.PI / 2;
                const endAngle = startAngle + (Math.PI * 2 * (node.mastery / 5));
                this.ctx.strokeStyle = "#10B981";
                this.ctx.lineWidth = 2.5;
                this.ctx.beginPath();
                this.ctx.arc(screenX, screenY, (node.radius + 3) * this.zoom, startAngle, endAngle);
                this.ctx.stroke();
            }

            // 5. WSJ Editorial Typography Labels (Smootherstep LOD 2)
            if (this.zoom >= 0.4) {
                this.ctx.font = node.spine ? "600 12px Newsreader, serif" : "11px -apple-system, sans-serif";
                this.ctx.fillStyle = isHovered ? "#FFFFFF" : (node.spine ? "#F3E5AB" : "#A1A1A8");
                this.ctx.textAlign = "center";
                this.ctx.fillText(`${node.id} · ${node.title.slice(0, 8)}`, screenX, screenY + (node.radius + 16) * this.zoom);
            }

            this.ctx.restore();
        }
    }
}
