import Foundation

private final class SharedStringsParser: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var text = ""
    private var insideText = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "si" { text = "" }
        if elementName == "t" { insideText = true }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideText { text += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "t" { insideText = false }
        if elementName == "si" { strings.append(text) }
    }
}

private final class SheetParser: NSObject, XMLParserDelegate {
    let sharedStrings: [String]
    var cells: [String: String] = [:]
    private var reference = ""
    private var type = ""
    private var value = ""
    private var readingValue = false

    init(sharedStrings: [String]) { self.sharedStrings = sharedStrings }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "c" {
            reference = attributeDict["r"] ?? ""
            type = attributeDict["t"] ?? ""
            value = ""
        }
        if elementName == "v" || elementName == "t" { readingValue = true }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if readingValue { value += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "v" || elementName == "t" { readingValue = false }
        if elementName == "c", !reference.isEmpty {
            if type == "s", let index = Int(value), sharedStrings.indices.contains(index) {
                cells[reference] = sharedStrings[index]
            } else {
                cells[reference] = value
            }
        }
    }
}

enum XLSXReader {
    static func read(_ url: URL) throws -> [ScriptBlock] {
        let sharedData = try unzip(url, entry: "xl/sharedStrings.xml", optional: true)
        let sharedParser = SharedStringsParser()
        if let sharedData {
            let parser = XMLParser(data: sharedData)
            parser.delegate = sharedParser
            guard parser.parse() else { throw parser.parserError ?? CocoaError(.fileReadCorruptFile) }
        }

        guard let sheetData = try unzip(url, entry: "xl/worksheets/sheet1.xml", optional: false) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let sheetParser = SheetParser(sharedStrings: sharedParser.strings)
        let parser = XMLParser(data: sheetData)
        parser.delegate = sheetParser
        guard parser.parse() else { throw parser.parserError ?? CocoaError(.fileReadCorruptFile) }

        let rows = Set(sheetParser.cells.keys.compactMap { reference in
            Int(reference.drop { $0.isLetter })
        }).filter { $0 > 1 }.sorted()

        guard sheetParser.cells["D1"] != nil, sheetParser.cells["E1"] != nil else {
            throw StudioError(message: "Ожидается шаблон XLSX: заголовки в первой строке, русский текст в D, английский в E")
        }
        return rows.compactMap { row in
            let russian = sheetParser.cells["D\(row)"] ?? ""
            let english = sheetParser.cells["E\(row)"] ?? ""
            guard !russian.isEmpty || !english.isEmpty else { return nil }
            let storedNumber = sheetParser.cells["A\(row)"] ?? ""
            let rawNumber = storedNumber.isEmpty ? "\(row - 1)" : storedNumber
            let number = rawNumber.hasSuffix(".0") ? String(rawNumber.dropLast(2)) : rawNumber
            return ScriptBlock(
                id: "row-\(row)", number: number,
                videoRussian: sheetParser.cells["B\(row)"],
                videoEnglish: sheetParser.cells["C\(row)"],
                russian: russian, english: english,
                voiceStatus: sheetParser.cells["F\(row)"],
                voiceNote: sheetParser.cells["H\(row)"]
            )
        }
    }

    private static func unzip(_ url: URL, entry: String, optional: Bool) throws -> Data? {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-p", url.path, entry]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        // Limit each uncompressed XML entry, not merely the compressed workbook size.
        var data = Data()
        while true {
            let chunk = output.fileHandleForReading.readData(ofLength: 64 * 1024)
            if chunk.isEmpty { break }
            guard data.count + chunk.count <= 16 * 1024 * 1024 else {
                output.fileHandleForReading.closeFile()
                process.terminate()
                process.waitUntilExit()
                throw StudioError(message: "Лист XLSX слишком большой (лимит 16 МБ XML)")
            }
            data.append(chunk)
        }
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            if optional { return nil }
            throw CocoaError(.fileReadCorruptFile)
        }
        return data
    }
}
