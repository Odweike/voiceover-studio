import XCTest
@testable import VoiceoverStudio

final class XLSXReaderTests: XCTestCase {
    private func read(sheet: String, shared: String? = nil) throws -> [ScriptBlock] {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let content = root.appendingPathComponent("content")
        let sheets = content.appendingPathComponent("xl/worksheets")
        try FileManager.default.createDirectory(at: sheets, withIntermediateDirectories: true)
        try Data(sheet.utf8).write(to: sheets.appendingPathComponent("sheet1.xml"))
        if let shared { try Data(shared.utf8).write(to: content.appendingPathComponent("xl/sharedStrings.xml")) }
        let archive = root.appendingPathComponent("fixture.xlsx")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-q", "-r", archive.path, "xl"]
        process.currentDirectoryURL = content
        try process.run()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        return try XLSXReader.read(archive)
    }

    func testInlineAndSharedStringsWithRichText() throws {
        let blocks = try read(sheet: """
        <worksheet><sheetData>
          <row r="1"><c r="D1" t="inlineStr"><is><t>Russian</t></is></c><c r="E1" t="inlineStr"><is><t>English</t></is></c></row>
          <row r="2"><c r="A2"><v>1.0</v></c><c r="D2" t="inlineStr"><is><t>Привет &amp; мир</t></is></c><c r="E2" t="s"><v>0</v></c></row>
        </sheetData></worksheet>
        """, shared: "<sst><si><r><t>Hello </t></r><r><t>world</t></r></si></sst>")
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].number, "1")
        XCTAssertEqual(blocks[0].russian, "Привет & мир")
        XCTAssertEqual(blocks[0].english, "Hello world")
    }

    func testRejectsBrokenXMLAndWrongColumns() {
        XCTAssertThrowsError(try read(sheet: "<worksheet>"))
        XCTAssertThrowsError(try read(sheet: "<worksheet/>", shared: "<sst>"))
        XCTAssertThrowsError(try read(sheet: "<worksheet><sheetData><row><c r='A2'><v>1</v></c></row></sheetData></worksheet>"))
    }

    func testRejectsOversizedDecompressedXML() {
        XCTAssertThrowsError(try read(sheet: "<worksheet>" + String(repeating: " ", count: 16 * 1024 * 1024) + "</worksheet>"))
    }
}
