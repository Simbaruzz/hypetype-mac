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
}
