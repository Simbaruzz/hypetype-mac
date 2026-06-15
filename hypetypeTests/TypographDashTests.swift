//
//  TypographDashTests.swift
//  hypetypeTests
//
//  Тесты тире G2 (TYPOGRAPH.md §5.G2).
//

import Testing
@testable import hypetype

private func check(_ input: String, _ expected: String,
                   sourceLocation: SourceLocation = #_sourceLocation) {
    let once = Typograph.dashes(input)
    #expect(once == expected, sourceLocation: sourceLocation)
    #expect(Typograph.dashes(once) == once, "не идемпотентно", sourceLocation: sourceLocation)
}

struct TypographDashTests {

    @Test func directSpeechLineStart() {
        check("- Это я", "—\u{00A0}Это я")
    }

    @Test func directSpeechAfterSentence() {
        check("Привет. - Это я", "Привет. —\u{00A0}Это я")
    }

    @Test func internalDash() {
        check("гений и злодейство - две вещи", "гений и злодейство\u{00A0}— две вещи")
    }

    @Test func internalDoubleHyphen() {
        check("слово -- слово", "слово\u{00A0}— слово")
    }

    @Test func existingEmDashGetsNbsp() {
        check("слово — слово", "слово\u{00A0}— слово")
    }

    @Test func numberRange() {
        check("2002-2009", "2002\u{2013}2009")
    }

    @Test func romanRange() {
        check("XI-XII", "XI\u{2013}XII")
    }

    @Test func monthRange() {
        check("январь-март", "январь\u{2013}март")
        check("понедельник-суббота", "понедельник\u{2013}суббота")
    }

    @Test func negativeDateNotTouched() {
        check("12-05-2024", "12-05-2024")
    }

    @Test func negativeHyphenatedWords() {
        check("кто-то", "кто-то")
        check("по-русски", "по-русски")
    }
}
