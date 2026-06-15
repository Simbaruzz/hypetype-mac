//
//  TypographNumberTests.swift
//  hypetypeTests
//
//  Тесты чисел и валюты G6 (TYPOGRAPH.md §5.G6).
//

import Testing
@testable import hypetype

private func check(_ input: String, _ expected: String, _ settings: TypographSettings = .default,
                   sourceLocation: SourceLocation = #_sourceLocation) {
    let once = Typograph.numbers(input, settings)
    #expect(once == expected, sourceLocation: sourceLocation)
    #expect(Typograph.numbers(once, settings) == once, "не идемпотентно", sourceLocation: sourceLocation)
}

struct TypographNumberTests {

    @Test func currencyAfterFromSymbol() {
        check("109$", "109\u{00A0}$")
        check("$ 109", "109\u{00A0}$")
    }

    @Test func currencyWordToSymbol() {
        check("50 руб.", "50\u{00A0}₽")
        check("20usd", "20\u{00A0}$")
        check("100 EUR", "100\u{00A0}€")
    }

    @Test func digitGrouping() {
        check("2345123 $", "2\u{00A0}345\u{00A0}123\u{00A0}$")
    }

    @Test func decimalPointToCommaInCurrency() {
        check("143.56 $", "143,56\u{00A0}$")
    }

    @Test func kopecks() {
        check("45 руб. 5 коп.", "45,05\u{00A0}₽")
    }

    @Test func currencyBeforeSetting() {
        var s = TypographSettings.default
        s.currencyPosition = .before
        check("109 $", "$\u{00A0}109", s)
    }

    @Test func negativeYearUntouched() {
        check("в 2026 году", "в 2026 году")
    }

    @Test func negativeVersionUntouched() {
        check("версия 2.5.1", "версия 2.5.1")
    }

    @Test func negativeLongIdUntouched() {
        check("ID 1234567890", "ID 1234567890")
    }
}
