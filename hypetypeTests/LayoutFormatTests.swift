//
//  LayoutFormatTests.swift
//  hypetypeTests
//
//  Тесты чистого кодека формата config.ini v2 (FORMAT.md §9 — эталонный пример).
//

import Testing
@testable import hypetype

private func scalars(_ s: String) -> [Unicode.Scalar] { Array(s.unicodeScalars) }

struct LayoutFormatTests {

    // Эталонный файл из §9 FORMAT.md.
    static let reference = """
    [hypetype]
    version=2

    [Layout]
    Digit1=00B9|00A1            ; ¹ | ¡
    Digit2=00B2|00BD            ; ² | ½
    Minus=2014|2013             ; — | –
    Equal=2260|00B1             ; ≠ | ±
    KeyE=20AC|2325              ; € | ⌥
    KeyH=20BD|030B              ; ₽ | ◌̋
    KeyV=2193|030C              ; ↓ | ◌̌
    Comma=00AB|201E             ; « | „
    Period=00BB|201C            ; » | “
    Slash=2026|0301             ; … | ◌́
    Backslash=007C|005C         ; | | \\
    Space=0020+00B7+0020|00A0   ; ␣·␣ | ⍽
    KeyT=1F60E|                 ; 😎 | —

    [Windows]
    DiacriticTimeoutMs=3000

    [macOS]
    DiacriticTimeoutMs=3000
    """

    // MARK: - Парсинг значений (§4)

    @Test func parsesSingleCodepoint() {
        let v = LayoutFormat.parseValue("20BD|030B")
        #expect(v == LayoutValue(alt: scalars("₽"), altShift: [Unicode.Scalar(0x030B)!]))
    }

    @Test func parsesSequence() {
        let v = LayoutFormat.parseValue("0020+00B7+0020|00A0")
        #expect(v?.alt == [Unicode.Scalar(0x20)!, Unicode.Scalar(0xB7)!, Unicode.Scalar(0x20)!])
        #expect(v?.altShift == [Unicode.Scalar(0xA0)!])
    }

    @Test func parsesEmptySides() {
        #expect(LayoutFormat.parseValue("1F60E|")?.altShift == [])
        #expect(LayoutFormat.parseValue("|2122")?.alt == [])
        #expect(LayoutFormat.parseValue("|") == LayoutValue.empty)
    }

    @Test func parsesEmojiAsSingleCodepoint() {
        #expect(LayoutFormat.parseValue("1F60E|")?.alt == scalars("😎"))
    }

    @Test func acceptsLowercaseAndShortHex() {
        // Парсер обязан принимать и короткую запись (§4.1).
        #expect(LayoutFormat.parseSequence("20") == [Unicode.Scalar(0x20)!])
        #expect(LayoutFormat.parseSequence("1f60e") == scalars("😎"))
    }

    @Test func rejectsInvalidValues() {
        #expect(LayoutFormat.parseValue("ZZ|00A1") == nil)      // не hex
        #expect(LayoutFormat.parseValue("0041|0042|0043") == nil) // два '|'
        #expect(LayoutFormat.parseValue("110000|") == nil)       // вне диапазона
        #expect(LayoutFormat.parseValue("D800|") == nil)         // суррогат
        #expect(LayoutFormat.parseValue("1234567|") == nil)      // >6 знаков
    }

    @Test func truncatesOverLimit() {
        let long = Array(repeating: "0041", count: 40).joined(separator: "+")
        #expect(LayoutFormat.parseSequence(long)?.count == LayoutFormat.maxCodepoints)
    }

    // MARK: - Сериализация значений

    @Test func formatsUppercaseMin4Digits() {
        #expect(LayoutFormat.formatValue(LayoutValue(alt: scalars("₽"), altShift: [Unicode.Scalar(0x030B)!])) == "20BD|030B")
        #expect(LayoutFormat.formatValue(LayoutValue(alt: scalars("😎"), altShift: [])) == "1F60E|")
    }

    // MARK: - Автокомментарии (§6)

    @Test func rendersComments() {
        #expect(GlyphRenderer.comment(for: LayoutValue(alt: scalars("₽"), altShift: [Unicode.Scalar(0x030B)!])) == "₽ | ◌̋")
        #expect(GlyphRenderer.comment(for: LayoutValue(alt: scalars("😎"), altShift: [])) == "😎 | —")
        let space = LayoutValue(alt: [Unicode.Scalar(0x20)!, Unicode.Scalar(0xB7)!, Unicode.Scalar(0x20)!],
                                altShift: [Unicode.Scalar(0xA0)!])
        #expect(GlyphRenderer.comment(for: space) == "␣·␣ | ⍽")
    }

    // MARK: - Парсинг эталонного файла (§9)

    @Test func parsesReference() {
        let layout = LayoutFormat.parse(Self.reference)
        #expect(layout.version == 2)
        #expect(layout.entries["KeyT"] == LayoutValue(alt: scalars("😎"), altShift: []))
        #expect(layout.entries["Backslash"] == LayoutValue(alt: scalars("|"), altShift: scalars("\\")))
        // Собственная секция [macOS] прочитана:
        #expect(layout.platformSettings.contains(SettingEntry(key: "DiacriticTimeoutMs", value: "3000")))
        // Чужая секция [Windows] сохранена для round-trip:
        #expect(layout.foreignSections.contains { $0.name == "Windows" })
    }

    @Test func backslashRoundTripsAsPipeChar() {
        // Ключевой кейс §4: пользовательский '|' хранится как 007C, не ломает разбор.
        let layout = LayoutFormat.parse(Self.reference)
        #expect(layout.entries["Backslash"]?.alt == scalars("|"))
    }

    // MARK: - Round-trip и идемпотентность (§7)

    @Test func roundTripLosesNothing() {
        let first = LayoutFormat.parse(Self.reference)
        let serialized = LayoutFormat.serialize(first)
        let second = LayoutFormat.parse(serialized)
        #expect(first == second)
    }

    @Test func serializationIsIdempotent() {
        let layout = LayoutFormat.parse(Self.reference)
        let once = LayoutFormat.serialize(layout)
        let twice = LayoutFormat.serialize(LayoutFormat.parse(once))
        #expect(once == twice)
    }

    @Test func preservesForeignWindowsSection() {
        let layout = LayoutFormat.parse(Self.reference)
        let out = LayoutFormat.serialize(layout)
        #expect(out.contains("[Windows]"))
        #expect(out.contains("DiacriticTimeoutMs=3000"))
    }

    @Test func ignoresBOMandCRLF() {
        let crlf = "\u{FEFF}[hypetype]\r\nversion=2\r\n\r\n[Layout]\r\nKeyE=20AC|2325\r\n"
        let layout = LayoutFormat.parse(crlf)
        #expect(layout.version == 2)
        #expect(layout.entries["KeyE"] == LayoutValue(alt: scalars("€"), altShift: scalars("⌥")))
    }

    @Test func preservesUnknownLayoutKey() {
        let input = "[hypetype]\nversion=2\n\n[Layout]\nIntlBackslash=0040|\n"
        let layout = LayoutFormat.parse(input)
        #expect(layout.unknownLayoutEntries == [LayoutRawEntry(key: "IntlBackslash", rawValue: "0040|")])
        #expect(LayoutFormat.serialize(layout).contains("IntlBackslash=0040|"))
    }
}

// MARK: - Секция [Typograph]

struct TypographFormatTests {

    @Test func defaultsWhenSectionMissing() {
        // Реф-файл без [Typograph] → все настройки типографа по умолчанию.
        let layout = LayoutFormat.parse(LayoutFormatTests.reference)
        #expect(layout.typograph == .default)
    }

    @Test func parsesSectionValues() {
        let input = """
        [hypetype]
        version=2

        [Layout]
        KeyE=20AC|2325

        [Typograph]
        Quotes=0
        PercentSpace=narrow
        CurrencyPosition=before
        NbspInitials=0
        """
        let s = LayoutFormat.parse(input).typograph
        #expect(s.quotes == false)
        #expect(s.percentSpace == .narrow)
        #expect(s.currencyPosition == .before)
        #expect(s.nbspInitials == false)
        // Не указанные ключи остаются дефолтными.
        #expect(s.dashText == true)
        #expect(s.symbols == true)
    }

    @Test func ignoresUnknownKeyAndInvalidValue() {
        let input = """
        [hypetype]
        version=2

        [Typograph]
        Quotes=maybe
        FutureKey=42
        PercentSpace=wide
        """
        let s = LayoutFormat.parse(input).typograph
        // Невалидное булево и неизвестное перечисление — остаётся дефолт.
        #expect(s.quotes == true)
        #expect(s.percentSpace == .none)
    }

    @Test func roundTripLosesNothing() {
        var s = TypographSettings.default
        s.quotes = false
        s.dashRanges = false
        s.percentSpace = .regular
        s.currencyPosition = .before
        s.nbspParticles = false
        // Полный кодек: settings → секция [Typograph] → обратно.
        var layout = Layout.standard
        layout.typograph = s
        let text = LayoutFormat.serialize(layout)
        #expect(LayoutFormat.parse(text).typograph == s)
    }

    @Test func serializationIsIdempotent() {
        var layout = Layout.standard
        layout.typograph.percentSpace = .narrow
        let once = LayoutFormat.serialize(layout)
        let twice = LayoutFormat.serialize(LayoutFormat.parse(once))
        #expect(once == twice)
    }

    @Test func sectionEmittedInSerializedFile() {
        let out = LayoutFormat.serialize(Layout.standard)
        #expect(out.contains("[Typograph]"))
        #expect(out.contains("PercentSpace=none"))
        #expect(out.contains("CurrencyPosition=after"))
    }

    @Test func yofikatorRoundTrips() {
        var layout = Layout.standard
        layout.yofikator = true
        let text = LayoutFormat.serialize(layout)
        #expect(text.contains("Yofikator=1"))
        #expect(LayoutFormat.parse(text).yofikator == true)
        // Отсутствие ключа = выключен (реф-файл без [Typograph]).
        #expect(LayoutFormat.parse(LayoutFormatTests.reference).yofikator == false)
    }
}
