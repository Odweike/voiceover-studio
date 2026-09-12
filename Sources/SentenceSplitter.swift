import Foundation
import NaturalLanguage

/// Splits a block's voice text into one [voice:...] segment per sentence.
enum SentenceSplitter {
    static func sentences(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let tokenizer = NLTokenizer(unit: .sentence)
        if let language = NLLanguageRecognizer.dominantLanguage(for: trimmed) {
            tokenizer.setLanguage(language)
        }
        tokenizer.string = trimmed
        var result: [String] = []
        tokenizer.enumerateTokens(in: trimmed.startIndex..<trimmed.endIndex) { range, _ in
            let sentence = trimmed[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty { result.append(sentence) }
            return true
        }
        return result
    }

    /// Returns a copy of the block with each non-empty language text rewritten as
    /// [voice:...] segments, one sentence each. Markers are shared between languages,
    /// as required by ScriptBlock validation.
    static func split(_ block: ScriptBlock, existingSegmentIDs: Set<String>) throws -> ScriptBlock {
        let english = sentences(plainText(block.english, block: block))
        let russian = sentences(plainText(block.russian, block: block))
        let count = max(english.count, russian.count)
        guard count > 1 else {
            throw StudioError(message: "Блок \(block.number) содержит одно предложение, разбивка не нужна")
        }
        let counts = [english.count, russian.count].filter { $0 > 0 }
        guard Set(counts).count <= 1 else {
            throw StudioError(message: "Блок \(block.number): предложений в русском тексте \(russian.count), в английском \(english.count). Разбейте вручную маркерами [voice:...]")
        }
        let markers = makeMarkers(block: block, count: count, existingSegmentIDs: existingSegmentIDs)
        func markedText(_ parts: [String]) -> String {
            zip(markers, parts).map { "[voice:\($0)]\n\($1)" }.joined(separator: "\n\n")
        }
        return ScriptBlock(
            id: block.id, number: block.number,
            videoRussian: block.videoRussian, videoEnglish: block.videoEnglish,
            russian: markedText(russian), english: markedText(english),
            voiceStatus: block.voiceStatus, voiceNote: block.voiceNote
        )
    }

    /// Text without [voice:...] markup, so an already segmented block can be re-split.
    private static func plainText(_ text: String, block: ScriptBlock) -> String {
        VoiceSegment.parse(text, fallbackID: block.id, fallbackLabel: block.number)
            .map(\.text)
            .joined(separator: "\n")
    }

    private static func makeMarkers(block: ScriptBlock, count: Int, existingSegmentIDs: Set<String>) -> [String] {
        var base = block.id
            .replacingOccurrences(of: "[^A-Za-z0-9._-]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-."))
        if base.isEmpty { base = "line" }
        var taken = existingSegmentIDs
        return (1...count).map { index in
            var candidate = "\(base)-\(index)"
            var attempt = 2
            while taken.contains("voice:\(candidate)") {
                candidate = "\(base)-\(index)-\(attempt)"
                attempt += 1
            }
            taken.insert("voice:\(candidate)")
            return candidate
        }
    }
}
