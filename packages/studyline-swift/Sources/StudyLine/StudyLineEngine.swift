// =============================================================================
// StudyLine Swift Native Core Engine Wrapper
// Zero-Copy, Thread-Safe, Pure Swift RAII Bridge over libstudyline C-ABI
// =============================================================================

import Foundation
import CStudyLine

public struct StudyLineStep: Identifiable, Equatable {
    public var id: String { nodeId }
    public let nodeId: String
    public let domain: String
    public let mastery: UInt8
    public let estimatedMinutes: UInt32
}

public enum StudyLineError: Error, LocalizedError {
    case initializationFailed
    case invalidPath
    case calculationFailed(String)
    case nullPointer

    public var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize StudyLine Rust Knowledge Graph."
        case .invalidPath:
            return "The provided knowledge domains directory does not exist or is invalid."
        case .calculationFailed(let msg):
            return "Topology path calculation failed: \(msg)"
        case .nullPointer:
            return "Null pointer received from C-ABI."
        }
    }
}

public final class StudyLineEngine {
    private var handle: OpaquePointer?

    public init() throws {
        guard let ptr = studyline_graph_new() else {
            throw StudyLineError.initializationFailed
        }
        self.handle = ptr
    }

    deinit {
        if let ptr = handle {
            studyline_graph_free(ptr)
        }
    }

    public func loadDomains(path: String) throws {
        guard let handle = handle else { throw StudyLineError.nullPointer }
        let code = path.withCString { cPath in
            studyline_graph_load_domains(handle, cPath)
        }
        if code != 0 {
            let errorMsg = studyline_last_error_message().flatMap { String(cString: $0) } ?? "Unknown error"
            throw StudyLineError.calculationFailed(errorMsg)
        }
    }

    public func calculatePath(target: String, mastered: [String] = []) throws -> [StudyLineStep] {
        guard let handle = handle else { throw StudyLineError.nullPointer }

        var resultPtr: UnsafeMutablePointer<StudyLinePathResult>?
        let code = target.withCString { cTarget in
            studyline_calculate_path(handle, cTarget, nil, 0, &resultPtr)
        }

        defer {
            if let ptr = resultPtr {
                studyline_path_result_free(ptr)
            }
        }

        if code != 0 {
            let errorMsg = studyline_last_error_message().flatMap { String(cString: $0) } ?? "Unknown error"
            throw StudyLineError.calculationFailed(errorMsg)
        }

        guard let res = resultPtr?.pointee else {
            return []
        }

        let buffer = UnsafeBufferPointer(start: res.steps, count: res.step_count)
        return buffer.map { step in
            StudyLineStep(
                nodeId: String(cString: step.node_id),
                domain: String(cString: step.domain),
                mastery: step.min_mastery,
                estimatedMinutes: step.estimated_minutes
            )
        }
    }

    public func renderMarkdown(_ markdown: String) -> String {
        guard let cHtml = markdown.withCString({ studyline_render_markdown($0) }) else {
            return markdown
        }
        defer { studyline_string_free(cHtml) }
        return String(cString: cHtml)
    }
}
