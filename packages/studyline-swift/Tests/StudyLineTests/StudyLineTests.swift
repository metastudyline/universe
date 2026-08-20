import XCTest
@testable import StudyLine

final class StudyLineTests: XCTestCase {
    func testEngineLifecycle() throws {
        let engine = try StudyLineEngine()
        let markdown = "# Title\n\n**Bold Text**"
        let rendered = engine.renderMarkdown(markdown)
        XCTAssertFalse(rendered.isEmpty)
    }
}
