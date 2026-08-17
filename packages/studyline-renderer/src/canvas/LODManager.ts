// =============================================================================
// StudyLine LOD Manager (Level of Detail Smooth Interpolation Engine)
// Based on 5th-order Quintic Hermite Polynomial (Smootherstep: S(u) = 6u^5 - 15u^4 + 10u^3)
// =============================================================================

export enum LODLevel {
    LOD_0_GALAXY = 0,    // Zoom < 0.35: Macro Discipline Nebula & Heatmap
    LOD_1_SPINE = 1,     // 0.35 <= Zoom < 0.85: Topology Backbone & Golden Pulses
    LOD_2_CAPSULE = 2    // Zoom >= 0.85: Academic Capsule, Greek Lexicon & Arcs
}

export interface LODState {
    level: LODLevel;
    alphaGalaxy: number;   // Alpha for Nebula halos (0.0 .. 1.0)
    alphaSpine: number;    // Alpha for Backbone & Strict Edges (0.0 .. 1.0)
    alphaLeaf: number;     // Alpha for Spinoff Leaves & Supporting Edges
    alphaDetail: number;   // Alpha for Labels, Lexicon & Mastery Arcs
}

export class LODManager {
    private lastZoom = 1.0;
    private hysteresisBuffer = 0.02;

    /**
     * Quintic Hermite Smootherstep (C^2 Continuous: S'(0)=S'(1)=0, S''(0)=S''(1)=0)
     */
    public smootherstep(edge0: number, edge1: number, x: number): number {
        const u = Math.min(Math.max((x - edge0) / (edge1 - edge0), 0.0), 1.0);
        return u * u * u * (u * (u * 6 - 15) + 10);
    }

    public getLODState(zoom: number): LODState {
        this.lastZoom = zoom;

        // Level classification with smooth blending
        let level = LODLevel.LOD_1_SPINE;
        if (zoom < 0.35) {
            level = LODLevel.LOD_0_GALAXY;
        } else if (zoom >= 0.85) {
            level = LODLevel.LOD_2_CAPSULE;
        }

        // LOD 0: Galaxy Nebula Halo Alpha (1.0 at zoom<=0.2, fade to 0.0 at zoom>=0.4)
        const alphaGalaxy = 1.0 - this.smootherstep(0.20, 0.40, zoom);

        // LOD 1: Leaf & Secondary Edge Alpha (fade in 0.30..0.45, partial fade out 0.70..0.90)
        const alphaLeafIn = this.smootherstep(0.30, 0.45, zoom);
        const alphaLeaf = alphaLeafIn;

        // LOD 2: Fine Detail Alpha (fade in 0.65..0.90)
        const alphaDetail = this.smootherstep(0.65, 0.90, zoom);

        return {
            level,
            alphaGalaxy,
            alphaSpine: 1.0, // Spine nodes and golden lines are always 100% visible
            alphaLeaf,
            alphaDetail
        };
    }
}
