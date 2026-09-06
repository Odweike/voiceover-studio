import Foundation

/// One folder is one project. All writes finish before the UI commits new state.
struct ProjectStore {
    let root: URL
    var recordings: URL { root.appendingPathComponent("Recordings", isDirectory: true) }
    private var manifestURL: URL { root.appendingPathComponent("manifest.json") }
    private var pendingURL: URL { root.appendingPathComponent("pending-take.json") }

    static func create(in parent: URL, blocks: [ScriptBlock], name: String = "Scenario") throws -> ProjectStore {
        try ScriptBlock.validate(blocks)
        let label = String(name.replacingOccurrences(of: "[^\\p{L}\\p{N} _-]", with: "_", options: .regularExpression).prefix(60))
        let store = ProjectStore(root: parent.appendingPathComponent("\(label)-\(UUID().uuidString)", isDirectory: true))
        try FileManager.default.createDirectory(at: store.recordings, withIntermediateDirectories: true)
        try store.write(blocks, to: store.root.appendingPathComponent("scenario.json"))
        try store.save([])
        return store
    }

    func load() throws -> (blocks: [ScriptBlock], takes: [Take]) {
        let blocks = try JSONDecoder().decode([ScriptBlock].self, from: Data(contentsOf: root.appendingPathComponent("scenario.json")))
        try ScriptBlock.validate(blocks)
        // A missing or corrupt manifest must never silently become an empty project.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var takes = try decoder.decode(Manifest.self, from: Data(contentsOf: manifestURL)).takes
        try validate(takes)
        if FileManager.default.fileExists(atPath: pendingURL.path) {
            let pending = try decoder.decode(Take.self, from: Data(contentsOf: pendingURL))
            try validate([pending])
            if !takes.contains(where: { $0.id == pending.id }), FileManager.default.fileExists(atPath: try audioURL(pending).path) {
                takes.append(pending)
                try save(takes)
            }
            try FileManager.default.removeItem(at: pendingURL)
        }
        return (blocks, takes)
    }

    func audioURL(_ take: Take) throws -> URL {
        guard !take.fileName.isEmpty, take.fileName != ".", take.fileName != "..",
              !take.fileName.contains("/"), !take.fileName.contains("\\"),
              take.fileName.lowercased().hasSuffix(".wav") else {
            throw StudioError(message: "Некорректное имя аудиофайла")
        }
        let url = recordings.appendingPathComponent(take.fileName)
        guard (try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)) == nil,
              (try? FileManager.default.destinationOfSymbolicLink(atPath: recordings.path)) == nil else {
            throw StudioError(message: "Символические ссылки на аудиофайлы не поддерживаются")
        }
        guard url.resolvingSymlinksInPath().deletingLastPathComponent() == recordings.resolvingSymlinksInPath() else {
            throw StudioError(message: "Аудиофайл находится вне проекта")
        }
        return url
    }

    func newTake(recordingID: String, selected: Bool) -> Take {
        let id = UUID()
        return Take(id: id, blockID: recordingID, fileName: "\(id.uuidString).wav", createdAt: Date(), selected: selected)
    }

    func begin(_ take: Take) throws {
        if FileManager.default.fileExists(atPath: pendingURL.path) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let previous = try decoder.decode(Take.self, from: Data(contentsOf: pendingURL))
            let committed = try decoder.decode(Manifest.self, from: Data(contentsOf: manifestURL))
            if committed.takes.contains(where: { $0.id == previous.id }) {
                try FileManager.default.removeItem(at: pendingURL)
            }
        }
        guard !FileManager.default.fileExists(atPath: pendingURL.path),
              !FileManager.default.fileExists(atPath: try audioURL(take).path) else {
            throw StudioError(message: "Сначала завершите сохранение предыдущей записи")
        }
        try write(take, to: pendingURL)
    }

    func complete(_ take: Take, takes: [Take]) throws -> [Take] {
        var updated = takes
        if !updated.contains(where: { $0.id == take.id }) { updated.append(take) }
        try save(updated)
        // Commit succeeded. A stale journal is harmless and is cleaned by begin/load;
        // never report a committed take as cancellable just because cleanup failed.
        try? FileManager.default.removeItem(at: pendingURL)
        return updated
    }

    func cancel(_ take: Take) throws {
        let url = try audioURL(take)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
        if FileManager.default.fileExists(atPath: pendingURL.path) { try FileManager.default.removeItem(at: pendingURL) }
    }

    func save(_ takes: [Take]) throws {
        try validate(takes)
        try write(Manifest(takes: takes), to: manifestURL)
    }

    private func validate(_ takes: [Take]) throws {
        guard Set(takes.map(\.id)).count == takes.count,
              Set(takes.map(\.fileName)).count == takes.count else {
            throw StudioError(message: "В manifest найдены повторяющиеся дубли или имена файлов")
        }
        for take in takes { _ = try audioURL(take) }
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(value).write(to: url, options: .atomic)
    }
}
