import XCTest
@testable import VoiceoverStudio

final class SentenceSplitterTests: XCTestCase {
    private func block(_ id: String = "row-2", number: String = "1", english: String = "", russian: String = "") -> ScriptBlock {
        ScriptBlock(id: id, number: number, videoRussian: nil, videoEnglish: nil,
                    russian: russian, english: english, voiceStatus: nil, voiceNote: nil)
    }

    func testSentenceTokenization() {
        XCTAssertEqual(SentenceSplitter.sentences("One two three. Four five! And six?"),
                       ["One two three.", "Four five!", "And six?"])
        XCTAssertEqual(SentenceSplitter.sentences("Первое предложение. Второе тоже! А вот и третье?"),
                       ["Первое предложение.", "Второе тоже!", "А вот и третье?"])
        XCTAssertEqual(SentenceSplitter.sentences("Одно предложение без точки"),
                       ["Одно предложение без точки"])
        XCTAssertEqual(SentenceSplitter.sentences("  \n "), [])
    }

    func testSplitMarksBothLanguagesWithMatchingMarkers() throws {
        let updated = try SentenceSplitter.split(
            block(english: "First here. Second here.", russian: "Сначала одно. Потом другое."),
            existingSegmentIDs: []
        )
        XCTAssertEqual(updated.voiceSegments.map(\.id), ["voice:row-2-1", "voice:row-2-2"])
        XCTAssertEqual(updated.voiceSegments.map(\.text), ["First here.", "Second here."])
        XCTAssertTrue(updated.hasVoiceMarkers)
        XCTAssertNil(updated.voiceMarkerIssue)
        XCTAssertEqual(VoiceSegment.parse(updated.russian, fallbackID: "x", fallbackLabel: "x").map(\.text),
                       ["Сначала одно.", "Потом другое."])
        XCTAssertNoThrow(try ScriptBlock.validate([updated]))
    }

    func testSplitKeepsUntouchedFieldsAndSingleLanguage() throws {
        let original = ScriptBlock(id: "row-9", number: "8", videoRussian: "В", videoEnglish: "V",
                                   russian: "Раз. Два. Три.", english: "",
                                   voiceStatus: "Озвучено", voiceNote: "заметка")
        let updated = try SentenceSplitter.split(original, existingSegmentIDs: [])
        XCTAssertEqual(updated.english, "")
        XCTAssertEqual(updated.voiceSegments.map(\.text), ["Раз.", "Два.", "Три."])
        XCTAssertEqual(updated.videoRussian, "В")
        XCTAssertEqual(updated.videoEnglish, "V")
        XCTAssertEqual(updated.voiceStatus, "Озвучено")
        XCTAssertEqual(updated.voiceNote, "заметка")
    }

    func testSplitFlattensExistingMarkers() throws {
        let marked = "[voice:a]\nПервая часть. Вторая часть.\n\n[voice:b]\nТретья часть."
        let updated = try SentenceSplitter.split(block(russian: marked), existingSegmentIDs: [])
        XCTAssertEqual(updated.voiceSegments.map(\.text), ["Первая часть.", "Вторая часть.", "Третья часть."])
        XCTAssertNil(updated.voiceMarkerIssue)
    }

    func testSplitRejectsSingleSentenceAndMismatchedCounts() {
        XCTAssertThrowsError(try SentenceSplitter.split(block(english: "Just one."), existingSegmentIDs: []))
        XCTAssertThrowsError(try SentenceSplitter.split(
            block(english: "One. Two. Three.", russian: "Раз. Два."),
            existingSegmentIDs: []
        ))
    }

    func testMarkersAvoidCollisionsAndUnsafeCharacters() throws {
        let updated = try SentenceSplitter.split(block("блок 5", english: "One. Two."),
                                                 existingSegmentIDs: ["voice:5-1"])
        let ids = updated.voiceSegments.map(\.id)
        XCTAssertEqual(Set(ids).count, 2)
        XCTAssertFalse(ids.contains("voice:5-1"))
        for id in ids {
            XCTAssertNotNil(id.range(of: "^voice:[A-Za-z0-9._-]+$", options: .regularExpression), id)
        }
        XCTAssertNoThrow(try ScriptBlock.validate([updated]))
    }

    @MainActor
    func testStudioSplitPersistsScenarioAndSelectsFirstSegment() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try ProjectStore.create(in: root, blocks: [
            block("a", english: "First one. Second one.")
        ])
        let suite = "VoiceoverTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let studio = Studio(baseRoot: root, defaults: defaults, loadInitial: false)
        try studio.open(store)

        studio.splitIntoSentences(studio.blocks[0])

        XCTAssertEqual(studio.blocks[0].voiceSegments.map(\.id), ["voice:a-1", "voice:a-2"])
        XCTAssertEqual(studio.selectedRecordingID, "voice:a-1")
        XCTAssertEqual(try store.load().blocks[0].voiceSegments.count, 2)
    }

    @MainActor
    func testStudioSplitWithTakesRequiresConfirmation() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try ProjectStore.create(in: root, blocks: [
            block("a", english: "First one. Second one.")
        ])
        try store.save([store.newTake(recordingID: "a", selected: true)])
        let suite = "VoiceoverTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let studio = Studio(baseRoot: root, defaults: defaults, loadInitial: false)
        try studio.open(store)

        studio.confirmTakeRemoval = { _, _ in false }
        studio.splitIntoSentences(studio.blocks[0])
        XCTAssertEqual(studio.takes.count, 1)
        XCTAssertFalse(studio.blocks[0].hasVoiceMarkers)

        studio.confirmTakeRemoval = { _, _ in true }
        studio.splitIntoSentences(studio.blocks[0])
        XCTAssertTrue(studio.takes.isEmpty)
        XCTAssertEqual(studio.blocks[0].voiceSegments.count, 2)
        XCTAssertEqual(try store.load().takes.count, 0)
    }
}
