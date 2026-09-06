import XCTest
@testable import VoiceoverStudio

final class ProjectStoreTests: XCTestCase {
    private func block(_ id: String = "intro", english: String = "Hello", russian: String = "Привет") -> ScriptBlock {
        ScriptBlock(id: id, number: "1", videoRussian: nil, videoEnglish: nil, russian: russian, english: english, voiceStatus: nil, voiceNote: nil)
    }

    private func withFolder(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }

    func testProjectLeaseIsExclusiveAndReleased() throws {
        try withFolder { root in
            var first: ProjectLease? = try ProjectLease(root: root)
            XCTAssertNotNil(first)
            XCTAssertThrowsError(try ProjectLease(root: root))
            first = nil
            XCTAssertNoThrow(try ProjectLease(root: root))
        }
    }

    func testDeletedMiddleTakeNeverReusesFileName() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            let original = (0..<3).map { _ in store.newTake(recordingID: "intro", selected: false) }
            try store.save([original[0], original[2]])
            let next = store.newTake(recordingID: "intro", selected: false)
            XCTAssertFalse(original.map(\.fileName).contains(next.fileName))
            XCTAssertEqual(try store.load().takes.count, 2)
        }
    }

    func testProjectsWithIdenticalRowIDsAreIsolated() throws {
        try withFolder { root in
            let first = try ProjectStore.create(in: root, blocks: [block("row-2")])
            let second = try ProjectStore.create(in: root, blocks: [block("row-2", english: "Other script")])
            try first.save([first.newTake(recordingID: "row-2", selected: true)])
            XCTAssertNotEqual(first.root, second.root)
            XCTAssertEqual(try first.load().takes.count, 1)
            XCTAssertTrue(try second.load().takes.isEmpty)
        }
    }

    func testInterruptedRecordingRecoversExactlyOnce() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            let take = store.newTake(recordingID: "intro", selected: true)
            try store.begin(take)
            try Data("recorded audio fixture".utf8).write(to: store.audioURL(take))
            XCTAssertEqual(try store.load().takes.map(\.id), [take.id])
            XCTAssertEqual(try store.load().takes.map(\.id), [take.id])
        }
    }

    func testJournalWithoutCreatedAudioDoesNotBecomeTake() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            try store.begin(store.newTake(recordingID: "intro", selected: true))
            XCTAssertTrue(try store.load().takes.isEmpty)
        }
    }

    func testFailedCommitPreservesAudioAndRecoveryJournal() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            let take = store.newTake(recordingID: "intro", selected: true)
            try store.begin(take)
            let audio = try store.audioURL(take)
            try Data("audio".utf8).write(to: audio)
            let manifest = store.root.appendingPathComponent("manifest.json")
            try FileManager.default.removeItem(at: manifest)
            try FileManager.default.createDirectory(at: manifest, withIntermediateDirectories: false)
            XCTAssertThrowsError(try store.complete(take, takes: []))
            XCTAssertTrue(FileManager.default.fileExists(atPath: audio.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: store.root.appendingPathComponent("pending-take.json").path))
            try FileManager.default.removeItem(at: manifest)
            try store.save([])
            XCTAssertEqual(try store.load().takes.map(\.id), [take.id])
        }
    }

    func testCorruptOrMissingManifestIsNotTreatedAsEmpty() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            let manifest = store.root.appendingPathComponent("manifest.json")
            try Data("broken".utf8).write(to: manifest)
            XCTAssertThrowsError(try store.load())
            XCTAssertEqual(try String(contentsOf: manifest, encoding: .utf8), "broken")
            try FileManager.default.removeItem(at: manifest)
            XCTAssertThrowsError(try store.load())
        }
    }

    func testCancellationRemovesOnlyPendingTake() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            let kept = store.newTake(recordingID: "intro", selected: true)
            try store.save([kept])
            let pending = store.newTake(recordingID: "intro", selected: false)
            try store.begin(pending)
            try Data("audio".utf8).write(to: store.audioURL(pending))
            try store.cancel(pending)
            XCTAssertEqual(try store.load().takes.map(\.id), [kept.id])
            XCTAssertFalse(FileManager.default.fileExists(atPath: try store.audioURL(pending).path))
        }
    }

    func testRejectsUnsafeAudioPathsAndSymlinks() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            for name in ["../secret.wav", "/tmp/test.wav", "..\\secret.wav", "manifest.json"] {
                let take = Take(id: UUID(), blockID: "intro", fileName: name, createdAt: Date(), selected: false)
                XCTAssertThrowsError(try store.save([take]))
            }
            let take = store.newTake(recordingID: "intro", selected: false)
            try FileManager.default.createSymbolicLink(at: store.recordings.appendingPathComponent(take.fileName), withDestinationURL: root.appendingPathComponent("outside.wav"))
            XCTAssertThrowsError(try store.audioURL(take))
        }
    }

    func testRejectsDuplicateIDsMarkersAndUnmarkedPreamble() throws {
        XCTAssertThrowsError(try ScriptBlock.validate([block(), block()]))
        let marked = "[voice:line]\nHello"
        XCTAssertThrowsError(try ScriptBlock.validate([block("a", english: marked, russian: ""), block("b", english: marked, russian: "")]))
        XCTAssertThrowsError(try ScriptBlock.validate([block(english: "Lost text\n" + marked, russian: "")]))
        XCTAssertThrowsError(try ScriptBlock.validate([block(english: "[voice:empty]", russian: "")]))
        XCTAssertThrowsError(try ScriptBlock.validate([block(english: marked, russian: "[voice:other]\nПривет")]))
        XCTAssertNoThrow(try ScriptBlock.validate([block(english: marked, russian: "")]))
        XCTAssertNoThrow(try ScriptBlock.validate([block(english: "", russian: marked)]))
        XCTAssertThrowsError(try ScriptBlock.validate([block(english: "", russian: "")]))
        XCTAssertEqual(VoiceSegment.parse(marked, fallbackID: "a", fallbackLabel: "1").first?.text, "Hello")
    }

    @MainActor
    func testFailedBestTakeWriteDoesNotChangeVisibleState() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block()])
            let first = store.newTake(recordingID: "intro", selected: true)
            let second = store.newTake(recordingID: "intro", selected: false)
            try store.save([first, second])
            let suite = "VoiceoverTests.\(UUID())"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let studio = Studio(baseRoot: root, defaults: defaults, loadInitial: false)
            try studio.open(store)
            let manifest = store.root.appendingPathComponent("manifest.json")
            try FileManager.default.removeItem(at: manifest)
            try FileManager.default.createDirectory(at: manifest, withIntermediateDirectories: false)
            studio.select(second)
            XCTAssertEqual(studio.selectedTake(for: "intro")?.id, first.id)
            XCTAssertTrue(studio.message.hasPrefix("Ошибка:"))
            studio.delete(first)
            XCTAssertEqual(studio.takes.count, 2)
        }
    }

    @MainActor
    func testSwitchSelectionThenCommitKeepsCapturedIdentityAndFailedOpenKeepsProject() throws {
        try withFolder { root in
            let store = try ProjectStore.create(in: root, blocks: [block("a"), block("b")])
            let suite = "VoiceoverTests.\(UUID())"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let studio = Studio(baseRoot: root, defaults: defaults, loadInitial: false)
            try studio.open(store)
            let captured = store.newTake(recordingID: studio.selectedRecordingID, selected: true)
            studio.selectBlock("b")
            try store.begin(captured)
            try Data("audio".utf8).write(to: store.audioURL(captured))
            let saved = try store.complete(captured, takes: [])
            XCTAssertEqual(saved.first?.blockID, "a")
            XCTAssertThrowsError(try studio.open(ProjectStore(root: root.appendingPathComponent("missing"))))
            XCTAssertEqual(studio.blocks.map(\.id), ["a", "b"])
        }
    }
}
