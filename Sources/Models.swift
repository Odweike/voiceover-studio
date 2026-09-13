import Foundation

struct ScriptBlock: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let number: String
    let videoRussian: String?
    let videoEnglish: String?
    let russian: String
    let english: String
    let voiceStatus: String?
    let voiceNote: String?
}

struct VoiceSegment: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let text: String

    static func parse(_ value: String, fallbackID: String, fallbackLabel: String) -> [VoiceSegment] {
        var result: [VoiceSegment] = []
        var marker: String?
        var lines: [String] = []

        func segmentMarker(_ line: String) -> String? {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("[voice:"), trimmed.hasSuffix("]") else { return nil }
            let name = String(trimmed.dropFirst(7).dropLast())
            guard !name.isEmpty,
                  name.range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil else { return nil }
            return name
        }

        func appendCurrent() {
            guard let marker else { return }
            let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                result.append(VoiceSegment(id: "voice:\(marker)", label: marker, text: text))
            }
        }

        for line in value.components(separatedBy: .newlines) {
            if let next = segmentMarker(line) {
                appendCurrent()
                marker = next
                lines = []
            } else if marker != nil {
                lines.append(line)
            }
        }
        appendCurrent()

        return result.isEmpty
            ? [VoiceSegment(id: fallbackID, label: fallbackLabel, text: value)]
            : result
    }
}

extension ScriptBlock {
    var voiceSegments: [VoiceSegment] {
        let text = english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? russian : english
        return VoiceSegment.parse(text, fallbackID: id, fallbackLabel: number)
    }

    var hasVoiceMarkers: Bool { voiceSegments.first?.id.hasPrefix("voice:") == true }

    var voiceMarkerIssue: String? {
        var languages: [[String]] = []
        for text in [english, russian] where !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let lines = text.components(separatedBy: .newlines)
            let marked = lines.filter { $0.contains("[voice:") }
            let segments = VoiceSegment.parse(text, fallbackID: id, fallbackLabel: number)
                .filter { $0.id.hasPrefix("voice:") }
            if !marked.isEmpty {
                guard let first = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }),
                      first.trimmingCharacters(in: .whitespaces).hasPrefix("[voice:") else {
                    return Strings.current.markerPreamble
                }
                if marked.count != segments.count { return Strings.current.markerInvalid }
                if Set(segments.map(\.id)).count != segments.count { return Strings.current.markerUnique }
            }
            languages.append(segments.map(\.id))
        }
        if languages.count == 2 && languages[0] != languages[1] {
            return Strings.current.markerMismatch
        }
        return nil
    }
}

struct Take: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let blockID: String
    let fileName: String
    let createdAt: Date
    var selected: Bool
}

struct Manifest: Codable {
    var takes: [Take] = []
}


struct StudioError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

extension ScriptBlock {
    static func validate(_ blocks: [ScriptBlock]) throws {
        guard !blocks.isEmpty else { throw StudioError(message: Strings.current.errScriptEmpty) }
        var blockIDs = Set<String>()
        var segmentIDs = Set<String>()
        for block in blocks {
            guard !block.id.isEmpty, blockIDs.insert(block.id).inserted else {
                throw StudioError(message: Strings.current.errBlockIDs)
            }
            guard !block.russian.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                  !block.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw StudioError(message: Strings.current.errBlockNoText(block.number))
            }
            if let issue = block.voiceMarkerIssue { throw StudioError(message: Strings.current.blockError(block.number, issue)) }
            for segment in block.voiceSegments {
                guard segmentIDs.insert(segment.id).inserted else {
                    throw StudioError(message: Strings.current.errDuplicateLineID(segment.id))
                }
            }
        }
    }
}
