import SwiftUI
import AVFoundation
import AppKit
import UniformTypeIdentifiers
import Combine

/// Display status of a script block. Computed statuses are localized at render time;
/// statuses imported from the user's spreadsheet pass through unchanged.
enum BlockStatus: Equatable, Sendable {
    case markerError
    case recording
    case approved
    case inProgress
    case hasTakes
    case notRecorded
    case imported(String)
}

@MainActor
final class Studio: ObservableObject {
    @Published private(set) var blocks: [ScriptBlock] = []
    @Published private(set) var takes: [Take] = []
    @Published private(set) var selectedBlockID = ""
    @Published private(set) var selectedRecordingID = ""
    @Published private(set) var message = Strings.current.readyToRecord
    @Published private(set) var busy = false
    @Published private(set) var pendingTake: Take?
    @Published private(set) var projectName = "Voiceover Studio"
    let audio = AudioController()
    private var store: ProjectStore?
    private var lease: ProjectLease?
    private var audioUpdates: AnyCancellable?
    private let baseRoot: URL
    private let defaults: UserDefaults

    /// Asks before dropping a block's takes during sentence split. Overridden in tests.
    var confirmTakeRemoval: (ScriptBlock, Int) -> Bool = { block, count in
        let s = Strings.current
        let alert = NSAlert()
        alert.messageText = s.splitAlertTitle(block.number, count)
        alert.informativeText = s.splitAlertBody
        alert.alertStyle = .warning
        alert.addButton(withTitle: s.splitAlertConfirm)
        alert.addButton(withTitle: s.cancel)
        return alert.runModal() == .alertFirstButtonReturn
    }

    var recording: Bool { audio.recording }
    var playingID: UUID? { audio.playingID }
    var locked: Bool { busy || pendingTake != nil }
    var selectedBlock: ScriptBlock? { blocks.first { $0.id == selectedBlockID } }

    static var defaultRoot: URL {
        if let path = ProcessInfo.processInfo.environment["VOICEOVER_STUDIO_DATA_DIR"] {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies/Voiceover Studio")
    }
    private var projectPreference: String { "projectPath:" + baseRoot.path }

    init(baseRoot: URL = Studio.defaultRoot,
         defaults: UserDefaults = .standard, loadInitial: Bool = true) {
        self.baseRoot = baseRoot
        self.defaults = defaults
        audioUpdates = audio.$recording.combineLatest(audio.$playingID).sink { [weak self] _ in self?.objectWillChange.send() }
        audio.onRecordingError = { [weak self] error in
            self?.stopRecording()
            self?.message = error + ". " + (self?.message ?? "")
        }
        guard loadInitial else { return }
        do {
            if let path = defaults.string(forKey: projectPreference) {
                try open(ProjectStore(root: URL(fileURLWithPath: path)))
            } else if FileManager.default.fileExists(atPath: baseRoot.appendingPathComponent("scenario.json").path) {
                // Existing personal data stays in place; no destructive migration.
                try open(ProjectStore(root: baseRoot))
            } else {
                guard let url = Bundle.main.url(forResource: "scenario", withExtension: "json") else {
                    throw StudioError(message: Strings.current.noSampleScript)
                }
                let blocks = try JSONDecoder().decode([ScriptBlock].self, from: Data(contentsOf: url))
                try open(ProjectStore.create(in: baseRoot.appendingPathComponent("Projects"), blocks: blocks))
            }
        } catch { report(error) }
    }

    func open(_ candidate: ProjectStore) throws {
        guard !locked else { throw StudioError(message: Strings.current.finishRecordingFirst) }
        let nextLease = store?.root.standardizedFileURL == candidate.root.standardizedFileURL
            ? lease : try ProjectLease(root: candidate.root)
        let loaded = try candidate.load()
        audio.stopPlayback()
        store = candidate
        lease = nextLease
        blocks = loaded.blocks
        takes = loaded.takes
        selectedBlockID = blocks.first?.id ?? ""
        selectedRecordingID = blocks.first?.voiceSegments.first?.id ?? ""
        projectName = candidate.root.lastPathComponent == "Voiceover Studio" ? Strings.current.myScript : candidate.root.lastPathComponent
        if projectName.count > 37, UUID(uuidString: String(projectName.suffix(36))) != nil {
            projectName = String(projectName.dropLast(37))
        } else if UUID(uuidString: projectName) != nil {
            projectName = Strings.current.scriptNBlocks(blocks.count)
        }
        defaults.set(candidate.root.path, forKey: projectPreference)
        let missing = takes.filter { take in
            guard let url = try? candidate.audioURL(take) else { return true }
            return !FileManager.default.fileExists(atPath: url.path)
        }.count
        message = missing == 0 ? Strings.current.projectOpened : Strings.current.missingAudio(missing)
    }

    func openProject() {
        guard !locked else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = Strings.current.openPanelHint
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try open(ProjectStore(root: url)) } catch { report(error) }
    }

    func importScenario() {
        guard !locked else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, UTType(filenameExtension: "xlsx") ?? .data]
        panel.allowsMultipleSelection = false
        panel.message = Strings.current.importPanelHint
        guard panel.runModal() == .OK, let url = panel.url else { return }
        busy = true
        audio.stopPlayback()
        Task {
            do {
                // Parsing/decompression runs away from the UI actor; only immutable models cross back.
                let decoded = try await Task.detached {
                    let blocks = url.pathExtension.lowercased() == "xlsx"
                        ? try XLSXReader.read(url)
                        : try JSONDecoder().decode([ScriptBlock].self, from: Data(contentsOf: url))
                    try ScriptBlock.validate(blocks)
                    return blocks
                }.value
                let candidate = try ProjectStore.create(in: baseRoot.appendingPathComponent("Projects"), blocks: decoded, name: url.deletingPathExtension().lastPathComponent)
                busy = false
                try open(candidate)
                projectName = url.deletingPathExtension().lastPathComponent
                message = Strings.current.projectCreated
            } catch { busy = false; report(error) }
        }
    }

    func record(_ block: ScriptBlock) {
        let segment = block.voiceSegments.first { !hasSelectedTake(for: $0.id) } ?? block.voiceSegments.first
        if let segment { record(block, segment: segment) }
    }

    func record(_ block: ScriptBlock, segment: VoiceSegment) {
        guard !locked, block.voiceMarkerIssue == nil,
              blocks.contains(where: { $0.id == block.id }), block.voiceSegments.contains(segment), let store else { return }
        // Recording must not change the row selection; the red highlight marks the segment.
        selectedRecordingID = segment.id
        let take = store.newTake(recordingID: segment.id, selected: !hasSelectedTake(for: segment.id))
        busy = true
        Task {
            let allowed: Bool
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized: allowed = true
            case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .audio)
            default: allowed = false
            }
            defer { busy = false }
            guard allowed else { message = Strings.current.allowMicrophone; return }
            do {
                try store.begin(take)
                pendingTake = take
                try audio.start(at: store.audioURL(take))
                message = Strings.current.recordingInProgress
            } catch {
                // Keep any created WAV and its recovery journal, even on a device failure.
                report(error)
            }
        }
    }

    func stopRecording() {
        audio.stopRecording()
        guard let take = pendingTake, let store else { return }
        do {
            let url = try store.audioURL(take)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw StudioError(message: Strings.current.audioNotCreated)
            }
            takes = try store.complete(take, takes: takes)
            pendingTake = nil
            message = Strings.current.takeSaved
        } catch { report(error) }
    }

    func cancelRecording() {
        audio.stopRecording()
        guard let take = pendingTake, let store else { return }
        do { try store.cancel(take); pendingTake = nil; message = Strings.current.recordingCancelled }
        catch { report(error) }
    }

    func prepareToQuit() -> Bool {
        if busy { message = Strings.current.waitForOperation; return false }
        if pendingTake != nil { stopRecording() }
        guard pendingTake == nil else {
            let alert = NSAlert()
            alert.messageText = Strings.current.couldNotSaveTake
            alert.informativeText = message + "\n" + Strings.current.checkFolderAccess
            alert.runModal()
            return false
        }
        audio.stopPlayback()
        return true
    }

    func togglePlayback(_ take: Take) {
        guard !locked, let store else { return }
        do { try audio.togglePlayback(take, url: store.audioURL(take)) } catch { report(error) }
    }

    func select(_ take: Take) {
        guard !locked, let store else { return }
        var updated = takes
        for index in updated.indices where updated[index].blockID == take.blockID {
            updated[index].selected = updated[index].id == take.id
        }
        do { try store.save(updated); takes = updated; message = Strings.current.bestTakeSelected }
        catch { report(error) }
    }

    func delete(_ take: Take) {
        guard !locked, let store, takes.contains(where: { $0.id == take.id }) else { return }
        audio.stopPlayback()
        var updated = takes.filter { $0.id != take.id }
        if !updated.contains(where: { $0.blockID == take.blockID && $0.selected }),
           let index = updated.firstIndex(where: { $0.blockID == take.blockID }) { updated[index].selected = true }
        do {
            let url = try store.audioURL(take)
            // Commit metadata first. If moving to Trash fails, the original WAV remains recoverable.
            try store.save(updated)
            takes = updated
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            }
            message = Strings.current.takeMovedToTrash
        } catch { report(error) }
    }

    func revealFolder() {
        if let store { NSWorkspace.shared.open(store.root) }
    }

    func splitIntoSentences(_ block: ScriptBlock) {
        guard !locked, let store, let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        guard block.voiceMarkerIssue == nil else {
            message = Strings.current.fixMarkupFirst(block.number)
            return
        }
        let segmentIDs = Set(block.voiceSegments.map(\.id))
        let blockTakes = takes.filter { segmentIDs.contains($0.blockID) }
        if !blockTakes.isEmpty {
            guard confirmTakeRemoval(block, blockTakes.count) else { return }
            do { try removeTakes(blockTakes, store: store) } catch { report(error); return }
        }
        do {
            let existing = Set(blocks.lazy.filter { $0.id != block.id }.flatMap { $0.voiceSegments.map(\.id) })
            let updated = try SentenceSplitter.split(block, existingSegmentIDs: existing)
            var newBlocks = blocks
            newBlocks[index] = updated
            try store.save(blocks: newBlocks)
            blocks = newBlocks
            selectedBlockID = updated.id
            selectedRecordingID = updated.voiceSegments.first?.id ?? updated.id
            message = Strings.current.blockSplit(block.number, updated.voiceSegments.count)
        } catch { report(error) }
    }

    private func removeTakes(_ doomed: [Take], store: ProjectStore) throws {
        audio.stopPlayback()
        let updated = takes.filter { take in !doomed.contains(take) }
        // Commit metadata first, same ordering as delete(_:).
        try store.save(updated)
        takes = updated
        for take in doomed {
            guard let url = try? store.audioURL(take),
                  FileManager.default.fileExists(atPath: url.path) else { continue }
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }
    }

    func selectBlock(_ id: String) {
        guard !locked, let block = blocks.first(where: { $0.id == id }) else { return }
        selectedBlockID = id
        if !block.voiceSegments.contains(where: { $0.id == selectedRecordingID }) {
            selectedRecordingID = block.voiceSegments.first?.id ?? id
        }
        audio.stopPlayback()
    }

    func selectSegment(_ block: ScriptBlock, segment: VoiceSegment) {
        guard !locked else { return }
        selectedBlockID = block.id
        selectedRecordingID = segment.id
        audio.stopPlayback()
    }

    private func report(_ error: Error) { message = Strings.current.error(error.localizedDescription) }
    func takes(for recordingID: String) -> [Take] {
        takes.filter { $0.blockID == recordingID }.sorted { $0.createdAt < $1.createdAt }
    }

    func selectedTake(for recordingID: String) -> Take? {
        takes.first { $0.blockID == recordingID && $0.selected }
    }

    func status(for block: ScriptBlock) -> BlockStatus {
        if block.voiceMarkerIssue != nil { return .markerError }
        let ids = Set(block.voiceSegments.map(\.id))
        if recording && ids.contains(selectedRecordingID) { return .recording }
        if block.hasVoiceMarkers && block.voiceSegments.allSatisfy({ hasSelectedTake(for: $0.id) }) { return .approved }
        if block.hasVoiceMarkers && block.voiceSegments.contains(where: { hasTake(for: $0.id) }) { return .inProgress }
        if hasSelectedTake(block) { return .approved }
        if hasTake(block) { return .hasTakes }
        if let voiceStatus = block.voiceStatus, !voiceStatus.isEmpty { return .imported(voiceStatus) }
        return .notRecorded
    }

    func needsRecording(_ block: ScriptBlock) -> Bool {
        switch status(for: block) {
        case .notRecorded:
            true
        case .imported(let value):
            // Statuses imported from the user's spreadsheet keep their original wording.
            value == "Нужно записать" || value == "Нужно перезаписать"
        default:
            false
        }
    }

    func hasTake(for recordingID: String) -> Bool { takes.contains { $0.blockID == recordingID } }
    func hasSelectedTake(for recordingID: String) -> Bool { takes.contains { $0.blockID == recordingID && $0.selected } }
    func hasTake(_ block: ScriptBlock) -> Bool { hasTake(for: block.id) }
    func hasSelectedTake(_ block: ScriptBlock) -> Bool { hasSelectedTake(for: block.id) }

}
