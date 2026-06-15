//
//  TypographQuotesTests.swift
//  hypetypeTests
//
//  Тесты автомата кавычек G1 (TYPOGRAPH.md §4) — самый сложный раздел.
//

import Testing
@testable import hypetype

private func check(_ input: String, _ expected: String,
                   sourceLocation: SourceLocation = #_sourceLocation) {
    let once = Typograph.quotesAutomaton(input)
    #expect(once == expected, sourceLocation: sourceLocation)
    #expect(Typograph.quotesAutomaton(once) == once, "не идемпотентно", sourceLocation: sourceLocation)
}

struct TypographQuotesTests {

    @Test func simplePair() {
        check("\"привет\"", "«привет»")
    }

    @Test func nestedQuotes() {
        check("«сказал \"да\"»", "«сказал „да“»")
    }

    @Test func plainNested() {
        check("\"сказал \"да\"\"", "«сказал „да“»")
    }

    @Test func inchInsideGuillemets() {
        // Провал SBOL: дюйм внутри ёлочек.
        check("\"Монитор 21\"\"", "«Монитор 21\"»")
    }

    @Test func inchBareAfterDigit() {
        check("диагональ 27\"", "диагональ 27\"")
    }

    @Test func apostropheInLatinWord() {
        check("it's", "it’s")
        check("d'Artagnan", "d’Artagnan")
    }

    @Test func apostropheNotAfterDigit() {
        check("5'10\"", "5'10\"")   // штрихи/дюймы — не трогаем
    }

    @Test func idempotentAlreadyTypeset() {
        check("«сказал „да“»", "«сказал „да“»")
        check("it’s", "it’s")
    }

    @Test func openAfterBracketAndDash() {
        check("(\"цитата\")", "(«цитата»)")
        check("— \"да\"", "— «да»")
    }

    @Test func pointMovedOutsideClosingGuillemet() {
        check("«это деньги.»", "«это деньги».")
        check("«сумма,»", "«сумма»,")
    }

    // macOS «умные кавычки»: система подменяет " на “…” до типографа.
    @Test func smartCurlyDoublesToGuillemets() {
        check("\u{201C}привет\u{201D}", "«привет»")
        check("\u{201C}спросил как дела?\u{201D}", "«спросил как дела?»")
    }

    @Test func smartCurlyInchAfterDigit() {
        check("монитор 21\u{201D}", "монитор 21\"")   // фигурная закрывающая после цифры → дюйм
    }
}

struct TypographQuotesPipelineTests {
    // Регрессия из ручного теста: пробел после двоеточия не должен съедаться
    // перед открывающей кавычкой (была проблема со «смарт-кавычкой» как закрывающей).
    @Test func spacePreservedBeforeOpeningQuote() {
        #expect(Typograph.run("пришёл: \u{201C}текст\u{201D}") == "пришёл: «текст»")
    }
}
