// =============================================================================
// StudyLine Spatial Index (Quadtree & Frustum Culling)
// High-performance 2D spatial queries for macro cosmic view
// =============================================================================

export interface BoundingBox {
    minX: number;
    minY: number;
    maxX: number;
    maxY: number;
}

export interface SpatialItem {
    id: string;
    x: number;
    y: number;
    radius: number;
}

export class SpatialIndex<T extends SpatialItem> {
    private bounds: BoundingBox;
    private maxItems: number;
    private maxDepth: number;
    private depth: number;
    private items: T[] = [];
    private children: SpatialIndex<T>[] = [];

    constructor(bounds: BoundingBox, depth = 0, maxItems = 16, maxDepth = 8) {
        this.bounds = bounds;
        this.depth = depth;
        this.maxItems = maxItems;
        this.maxDepth = maxDepth;
    }

    public insert(item: T): void {
        if (!this.contains(item.x, item.y)) return;

        if (this.children.length > 0) {
            for (const child of this.children) {
                child.insert(item);
            }
            return;
        }

        this.items.push(item);

        if (this.items.length > this.maxItems && this.depth < this.maxDepth) {
            this.subdivide();
            for (const existing of this.items) {
                for (const child of this.children) {
                    child.insert(existing);
                }
            }
            this.items = [];
        }
    }

    private subdivide(): void {
        const { minX, minY, maxX, maxY } = this.bounds;
        const midX = (minX + maxX) / 2;
        const midY = (minY + maxY) / 2;

        this.children = [
            new SpatialIndex({ minX, minY, maxX: midX, maxY: midY }, this.depth + 1, this.maxItems, this.maxDepth),
            new SpatialIndex({ minX: midX, minY, maxX, maxY: midY }, this.depth + 1, this.maxItems, this.maxDepth),
            new SpatialIndex({ minX, minY: midY, maxX: midX, maxY }, this.depth + 1, this.maxItems, this.maxDepth),
            new SpatialIndex({ minX: midX, minY: midY, maxX, maxY }, this.depth + 1, this.maxItems, this.maxDepth)
        ];
    }

    private contains(x: number, y: number): boolean {
        return x >= this.bounds.minX && x <= this.bounds.maxX &&
               y >= this.bounds.minY && y <= this.bounds.maxY;
    }

    public queryViewport(viewport: BoundingBox, result: T[] = []): T[] {
        if (!this.intersects(this.bounds, viewport)) return result;

        for (const item of this.items) {
            if (item.x + item.radius >= viewport.minX &&
                item.x - item.radius <= viewport.maxX &&
                item.y + item.radius >= viewport.minY &&
                item.y - item.radius <= viewport.maxY) {
                result.push(item);
            }
        }

        for (const child of this.children) {
            child.queryViewport(viewport, result);
        }

        return result;
    }

    private intersects(a: BoundingBox, b: BoundingBox): boolean {
        return !(a.maxX < b.minX || a.minX > b.maxX || a.maxY < b.minY || a.minY > b.maxY);
    }
}
