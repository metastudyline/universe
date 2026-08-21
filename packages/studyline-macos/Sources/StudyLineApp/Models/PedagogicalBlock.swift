import SwiftUI

// ✦ 动态教学语义块强类型契约 (Pedagogical Block Protocol)

public struct BilingualSourceModel: Equatable {
    public let originalText: String
    public let originalLang: String
    public let translationText: String
    public let translationLang: String
    public let citation: String

    public init(originalText: String, originalLang: String = "grc", translationText: String, translationLang: String = "zh", citation: String) {
        self.originalText = originalText
        self.originalLang = originalLang
        self.translationText = translationText
        self.translationLang = translationLang
        self.citation = citation
    }
}

public struct FormalSyllogismModel: Equatable {
    public let title: String?
    public let p1: String
    public let p2: String
    public let reductio: String?
    public let conclusion: String

    public init(title: String? = nil, p1: String, p2: String, reductio: String? = nil, conclusion: String) {
        self.title = title
        self.p1 = p1
        self.p2 = p2
        self.reductio = reductio
        self.conclusion = conclusion
    }
}

public struct MemoryLayoutModel: Equatable {
    public let title: String
    public let arch: String
    public let rawDiagram: String

    public init(title: String, arch: String = "x86_64", rawDiagram: String) {
        self.title = title
        self.arch = arch
        self.rawDiagram = rawDiagram
    }
}

public struct LiveCellModel: Equatable {
    public let cellId: String
    public let initialCode: String
    public let language: String

    public init(cellId: String, initialCode: String, language: String = "rust") {
        self.cellId = cellId
        self.initialCode = initialCode
        self.language = language
    }
}

public struct WorkshopStepperModel: Equatable {
    public let workshopId: String
    public let title: String

    public init(workshopId: String, title: String) {
        self.workshopId = workshopId
        self.title = title
    }
}

public enum PedagogicalBlock: Identifiable, Equatable {
    case markdown(id: String, content: String)
    case bilingualSource(id: String, model: BilingualSourceModel)
    case formalSyllogism(id: String, model: FormalSyllogismModel)
    case memoryLayout(id: String, model: MemoryLayoutModel)
    case liveCell(id: String, model: LiveCellModel)
    case workshopStepper(id: String, model: WorkshopStepperModel)

    public var id: String {
        switch self {
        case .markdown(let id, _): return id
        case .bilingualSource(let id, _): return id
        case .formalSyllogism(let id, _): return id
        case .memoryLayout(let id, _): return id
        case .liveCell(let id, _): return id
        case .workshopStepper(let id, _): return id
        }
    }
}
