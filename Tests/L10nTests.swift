import XCTest
@testable import VoiceoverStudio

final class L10nTests: XCTestCase {

    /// The memberwise Strings initializer already guarantees completeness at compile
    /// time; this smoke test guards against empty or placeholder translations.
    func testEveryLanguageHasNonEmptyStrings() {
        for language in AppLanguage.allCases {
            let s = Strings(language)
            XCTAssertFalse(s.readyToRecord.isEmpty, "\(language)")
            XCTAssertFalse(s.splitIntoSentences.isEmpty, "\(language)")
            XCTAssertFalse(s.interfaceLanguage.isEmpty, "\(language)")
            XCTAssertFalse(s.statusApproved.isEmpty, "\(language)")
            XCTAssertTrue(s.takeN(2).contains("2"), "\(language)")
            XCTAssertTrue(s.blockSplit("7", 3).contains("7"), "\(language)")
            XCTAssertTrue(s.blockSplit("7", 3).contains("3"), "\(language)")
            XCTAssertTrue(s.error("boom").contains("boom"), "\(language)")
        }
    }

    func testTranslationsActuallyDiffer() {
        let reference = Strings(.en)
        for language in [AppLanguage.ru, .es, .fr] {
            XCTAssertNotEqual(reference.readyToRecord, Strings(language).readyToRecord, "\(language)")
            XCTAssertNotEqual(reference.splitIntoSentences, Strings(language).splitIntoSentences, "\(language)")
        }
    }

    func testLanguageNamesAreNative() {
        XCTAssertEqual(AppLanguage.en.nativeName, "English")
        XCTAssertEqual(AppLanguage.ru.nativeName, "Русский")
        XCTAssertEqual(AppLanguage.es.nativeName, "Español")
        XCTAssertEqual(AppLanguage.fr.nativeName, "Français")
    }

    func testSystemDefaultIsSupported() {
        XCTAssertTrue(AppLanguage.allCases.contains(AppLanguage.systemDefault))
    }
}
