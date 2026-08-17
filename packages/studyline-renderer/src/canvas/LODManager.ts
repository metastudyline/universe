// =============================================================================
// StudyLine 3-Level Semantic Level of Detail (LOD) Manager
// Smooth transitions across cosmic scale, backbone pathways, and micro capsules
// =============================================================================

export enum LODLevel {
    LOD_0_GALAXY_CLUSTERS = 0, // Zoom < 0.35: Macro nebula halos and domain centers
    LOD_1_SPINE_PATHWAYS = 1,   // 0.35 <= Zoom < 0.85: Core spine nodes and golden paths
    LOD_2_FULL_CAPSULES = 2     // Zoom >= 0.85: Full detail nodes, badges, criteria
}

export interface LODState {
    level: LODLevel;
    zoomScale: number;
    alphaSpine: number;    // 0.0 to 1.0 smooth opacity
    alphaDetail: number;   // 0.0 to 1.0 smooth opacity
}

export class LODManager {
    public getLODState(zoom: number): LODState {
        let level: LODLevel;
        let alphaSpine = 1.0;
        let alphaDetail = 1.0;

        if (zoom < 0.35) {
            level = LODLevel.LOD_0_GALAXY_CLUSTERS;
            alphaSpine = Math.max(0, (zoom - 0.2) / 0.15);
            alphaDetail = 0.0;
        } else if (zoom < 0.85) {
            level = LODLevel.LOD_1_SPINE_PATHWAYS;
            alphaSpine = 1.0;
            alphaDetail = Math.max(0, (zoom - 0.35) / 0.5);
        } else {
            level = LODLevel.LOD_2_FULL_CAPSULES;
            alphaSpine = 1.0;
            alphaDetail = 1.0;
        }

        return {
            level,
            zoomScale: zoom,
            alphaSpine,
            alphaDetail
        };
    }
}
