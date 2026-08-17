// =============================================================================
// StudyLine Universe Canvas Engine (Macro Cosmic View)
// 60FPS hardware-accelerated canvas with golden learning path pulses
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

    // Animation state
    private pulseOffset = 0;
    private isRunning = false;

    constructor(canvas: HTMLCanvasElement, data: UniverseData) {
        this.canvas = canvas;
        const context = canvas.getContext("2d");
        if (!context) throw new Error("Canvas 2D context not available");
        this.ctx = context;
        this.data = data;

        // Initialize spatial index
        this.spatialIndex = new SpatialIndex({
            minX: -2000,
            minY: -2000,
            maxX: 2000,
            maxY: 2000
        });

        for (const node of data.nodes) {
            node.radius = node.spine ? 14 : 8;
            this.spatialIndex.insert(node);
        }

        this.initEvents();
        this.resize();
    }

    public setOnNodeSelect(callback: (node: NodeVisual) => void): void {
        this.onNodeSelectCallback = callback;
    }

    public highlightShortestPath(nodeIds: string[]): void {
        this.highlightedPath = new Set(nodeIds);
    }

    public focusNode(nodeId: string): void {
        const target = this.data.nodes.find(n => n.id === nodeId);
        if (!target) return;
        this.offsetX = this.canvas.width / 2 - target.x * this.zoom;
        this.offsetY = this.canvas.height / 2 - target.y * this.zoom;
    }

    public start(): void {
        if (this.isRunning) return;
        this.isRunning = true;
        const loop = () => {
            if (!this.isRunning) return;
            this.pulseOffset = (this.pulseOffset + 0.03) % (Math.PI * 2);
            this.render();
            requestAnimationFrame(loop);
        };
        requestAnimationFrame(loop);
    }

    public stop(): void {
        this.isRunning = false;
    }

    private resize(): void {
        const dpr = window.devicePixelRatio || 1;
        this.canvas.width = this.canvas.clientWidth * dpr;
        this.canvas.height = this.canvas.clientHeight * dpr;
        this.ctx.scale(dpr, dpr);
        this.offsetX = this.canvas.clientWidth / 2;
        this.offsetY = this.canvas.clientHeight / 2;
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
            const zoomFactor = e.deltaY < 0 ? 1.1 : 0.9;
            const newZoom = Math.min(Math.max(this.zoom * zoomFactor, 0.15), 3.5);

            const mouseX = e.clientX - this.canvas.getBoundingClientRect().left;
            const mouseY = e.clientY - this.canvas.getBoundingClientRect().top;

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
            return Math.sqrt(dx * dx + dy * dy) <= (n.radius + 6);
        });

        this.hoveredNode = hit || null;
        this.canvas.style.cursor = hit ? "pointer" : "default";
    }

    private render(): void {
        const { width, height } = this.canvas.getBoundingClientRect();
        this.ctx.clearRect(0, 0, width, height);

        // 1. Draw Deep Space Background Grid
        this.drawSpaceBackground(width, height);

        const lod = this.lodManager.getLODState(this.zoom);

        // 2. Draw Galaxy Halos (LOD 0)
        for (const cluster of this.data.clusters) {
            this.drawClusterHalo(cluster);
        }

        // 3. Draw Dependency Edges & Golden Learning Path
        this.drawEdges(lod);

        // 4. Draw Visible Nodes with Frustum Culling
        this.drawNodes(lod, width, height);
    }

    private drawSpaceBackground(w: number, h: number): void {
        this.ctx.save();
        this.ctx.fillStyle = "#0a0c10";
        this.ctx.fillRect(0, 0, w, h);

        // Subtle cosmic dust grid
        this.ctx.strokeStyle = "rgba(255, 255, 255, 0.02)";
        this.ctx.lineWidth = 1;
        const gridSize = 80 * this.zoom;
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

    private drawClusterHalo(cluster: { id: string; title: string; x: number; y: number }): void {
        const screenX = cluster.x * this.zoom + this.offsetX;
        const screenY = cluster.y * this.zoom + this.offsetY;

        this.ctx.save();
        const gradient = this.ctx.createRadialGradient(screenX, screenY, 10, screenX, screenY, 260 * this.zoom);
        gradient.addColorStop(0, "rgba(200, 160, 90, 0.12)");
        gradient.addColorStop(1, "rgba(200, 160, 90, 0.0)");
        this.ctx.fillStyle = gradient;
        this.ctx.beginPath();
        this.ctx.arc(screenX, screenY, 260 * this.zoom, 0, Math.PI * 2);
        this.ctx.fill();

        if (this.zoom < 0.6) {
            this.ctx.font = "bold 13px -apple-system, sans-serif";
            this.ctx.fillStyle = "rgba(230, 210, 170, 0.7)";
            this.ctx.textAlign = "center";
            this.ctx.fillText(cluster.title, screenX, screenY - 40 * this.zoom);
        }
        this.ctx.restore();
    }

    private drawEdges(lod: { level: LODLevel; alphaSpine: number }): void {
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
                this.ctx.strokeStyle = "rgba(224, 185, 95, 0.85)";
                this.ctx.lineWidth = 2.5 * Math.min(this.zoom, 1.5);
                this.ctx.setLineDash([]);
            } else if (edge.type === "supporting") {
                this.ctx.strokeStyle = "rgba(120, 140, 160, 0.25)";
                this.ctx.lineWidth = 1;
                this.ctx.setLineDash([4, 4]);
            } else {
                this.ctx.strokeStyle = `rgba(160, 175, 195, ${0.35 * lod.alphaSpine})`;
                this.ctx.lineWidth = 1.2;
                this.ctx.setLineDash([]);
            }

            // Curve control point
            const midX = (x1 + x2) / 2;
            const midY = (y1 + y2) / 2 - 15 * this.zoom;
            this.ctx.quadraticCurveTo(midX, midY, x2, y2);
            this.ctx.stroke();

            // Golden flowing particle
            if (isGolden) {
                const t = (Math.sin(this.pulseOffset + from.x) + 1) / 2;
                const px = (1 - t) * (1 - t) * x1 + 2 * (1 - t) * t * midX + t * t * x2;
                const py = (1 - t) * (1 - t) * y1 + 2 * (1 - t) * t * midY + t * t * y2;

                this.ctx.fillStyle = "#fff";
                this.ctx.beginPath();
                this.ctx.arc(px, py, 3, 0, Math.PI * 2);
                this.ctx.fill();
            }
        }
        this.ctx.restore();
    }

    private drawNodes(lod: { level: LODLevel; alphaDetail: number }, w: number, h: number): void {
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

            // Outer pulse halo for highlighted/hovered node
            if (isHighlighted || isHovered) {
                this.ctx.fillStyle = "rgba(224, 185, 95, 0.3)";
                this.ctx.beginPath();
                this.ctx.arc(screenX, screenY, (node.radius + 8) * this.zoom, 0, Math.PI * 2);
                this.ctx.fill();
            }

            // Core node body
            this.ctx.beginPath();
            this.ctx.arc(screenX, screenY, node.radius * this.zoom, 0, Math.PI * 2);

            if (node.genre === "synthesis") {
                this.ctx.fillStyle = "#d4af37"; // Kintsugi Gold for Synthesis
            } else if (node.genre === "spinoff") {
                this.ctx.fillStyle = "#6b8299"; // Slate for Spinoff
            } else {
                this.ctx.fillStyle = node.spine ? "#3b82f6" : "#60a5fa"; // Azure for Core
            }
            this.ctx.fill();

            // Border
            this.ctx.strokeStyle = isHovered ? "#ffffff" : "rgba(255, 255, 255, 0.4)";
            this.ctx.lineWidth = isHovered ? 2 : 1;
            this.ctx.stroke();

            // Label rendering at LOD 1 & 2
            if (this.zoom >= 0.45) {
                this.ctx.font = node.spine ? "bold 11px -apple-system, sans-serif" : "10px -apple-system, sans-serif";
                this.ctx.fillStyle = isHovered ? "#ffffff" : "rgba(220, 230, 240, 0.85)";
                this.ctx.textAlign = "center";
                this.ctx.fillText(node.id, screenX, screenY + (node.radius + 12) * this.zoom);
            }

            this.ctx.restore();
        }
    }
}
