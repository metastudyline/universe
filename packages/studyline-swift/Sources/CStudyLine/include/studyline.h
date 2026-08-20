/* ==============================================================================
   ✦ StudyLine Universal Knowledge Engine — C-ABI Header (studyline.h)
   Strict Standard C Header for Cross-Platform Native Bindings (Swift, C++, Rust)
   ============================================================================== */

#ifndef STUDYLINE_H
#define STUDYLINE_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Opaque pointer to the core Rust KnowledgeGraph */
typedef struct StudyLineGraph StudyLineGraph;

/* Single step in the shortest learning path */
typedef struct {
    const char* node_id;
    const char* domain;
    uint8_t min_mastery;
    uint32_t estimated_minutes;
} StudyLinePathStep;

/* Result payload returned by studyline_calculate_path */
typedef struct {
    const StudyLinePathStep* steps;
    size_t step_count;
    uint32_t total_estimated_minutes;
    void* _internal_handle;
} StudyLinePathResult;

/* Graph Lifecycle */
StudyLineGraph* studyline_graph_new(void);
void studyline_graph_free(StudyLineGraph* graph);

/* Domain Knowledge Loading */
int32_t studyline_graph_load_domains(StudyLineGraph* graph, const char* domains_dir);

/* Path Planning */
int32_t studyline_calculate_path(
    const StudyLineGraph* graph,
    const char* target_id,
    const char* const* mastered_ids,
    size_t mastered_count,
    StudyLinePathResult** out_result
);

void studyline_path_result_free(StudyLinePathResult* result);

/* Academic Markdown Rendering */
char* studyline_render_markdown(const char* raw_markdown);

/* String Memory Management */
void studyline_string_free(char* ptr);

/* Diagnostic & Error Handling */
const char* studyline_last_error_message(void);

#ifdef __cplusplus
}
#endif

#endif /* STUDYLINE_H */
