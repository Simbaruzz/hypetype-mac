//
//  TypographTests.swift
//  hypetypeTests
//
//  Тесты чистого типографа (TYPOGRAPH.md §9). Каждый кейс проверяется на
//  идемпотентность: повторное применение группы не меняет результат (§3).
//

import Testing
@testable import hypetype

/// Проверка «вход → ожидаемый выход» + идемпотентность (двойной прогон).
private func check(_ f: (String) -> String, _ input: String, _ expected: String,
                   _ comment: Comment? = nil, sourceLocation: SourceLocation = #_sourceLocation) {
    let once = f(input)
    #expect(once == expected, comment, sourceLocation: sourceLocation)
    #expect(f(once) == once, "не идемпотентно", sourceLocation: sourceLocation)
}

struct TypographPunctTests {
    let g: (String) -> String = { Typograph.punctuation($0, .default) }

    @Test func ellipsis() {
        check(g, "точки...", "точки\u{2026}")
        check(g, "много.....", "много\u{2026}")
    }
    @Test func collapseRepeats() {
        check(g, "что!!!", "что!")
        check(g, "как???", "как?")
        check(g, "пауза,,,", "пауза,")
    }
    @Test func mixedWithEllipsis() {
        check(g, "правда...?", "правда?\u{2025}")
        check(g, "правда?...", "правда?\u{2025}")
        check(g, "ого...!", "ого!\u{2025}")
    }
    @Test func interrobangOrder() {
        check(g, "что!?", "что?!")
    }
    @Test func negativeAlreadyDone() {
        check(g, "готово?\u{2025}", "готово?\u{2025}")
        check(g, "одно\u{2026}", "одно\u{2026}")
    }
}

struct TypographSpaceTests {
    let g: (String) -> String = { Typograph.spaceClean($0, .default) }

    @Test func spaceAfterComma() {
        check(g, "менее,меньше", "менее, меньше")
    }
    @Test func spaceBeforeAndAfterComma() {
        check(g, "менее ,меньше", "менее, меньше")
    }
    @Test func bracketsAndPunct() {
        check(g, "( пример )", "(пример)")
        check(g, "слово !", "слово!")
    }
    @Test func percentDefaultGlued() {
        check({ Typograph.percentSpacing($0, .default) }, "23 %", "23%")
    }
    @Test func percentNarrow() {
        let narrow: (String) -> String = {
            var s = TypographSettings.default; s.percentSpace = .narrow
            return Typograph.percentSpacing($0, s)
        }
        check(narrow, "23 %", "23\u{202F}%")
        check(narrow, "23%", "23\u{202F}%")
    }
    @Test func percentRegular() {
        let reg: (String) -> String = {
            var s = TypographSettings.default; s.percentSpace = .regular
            return Typograph.percentSpacing($0, s)
        }
        check(reg, "23%", "23 %")
        check(reg, "23\u{202F}%", "23 %")
    }
    @Test func doubleSpaces() {
        check(g, "слово  слово", "слово слово")
    }
    @Test func negativeDecimalsAndTime() {
        check(g, "143,56", "143,56")
        check(g, "12:30", "12:30")
        check(g, "1:0", "1:0")
    }
}

struct TypographSymbolsTests {
    let g = Typograph.symbols

    @Test func copyright() {
        check(g, "(c)", "\u{00A9}")
        check(g, "(C)", "\u{00A9}")
        check(g, "(\u{0441})", "\u{00A9}")   // кириллическая с
    }
    @Test func registeredAndTm() {
        check(g, "(r)", "\u{00AE}")
        check(g, "(R)", "\u{00AE}")
        check(g, "(tm)", "\u{2122}")
        check(g, "(TM)", "\u{2122}")
    }
    @Test func plusMinus() {
        check(g, "+-", "\u{00B1}")
    }
    @Test func numero() {
        check(g, "№ 5", "№\u{00A0}5")
    }
    @Test func negativeEnumeration() {
        check(g, "а) б) в)", "а) б) в)")
    }
}

struct TypographPipelineTests {
    @Test func trimsLineEdgesPreservingNewlines() {
        #expect(Typograph.run("  абзац один  \n   абзац два  ") == "абзац один\nабзац два")
    }
    @Test func groupTogglesOff() {
        var s = TypographSettings.default
        s.punctEllipsis = false
        #expect(Typograph.run("точки...", s) == "точки...")
    }
}

/// Под-тумблеры расщеплённых групп: каждый выключает только своё правило.
struct TypographSubToggleTests {
    private func run(_ input: String, _ mutate: (inout TypographSettings) -> Void) -> String {
        var s = TypographSettings.default
        mutate(&s)
        return Typograph.run(input, s)
    }

    @Test func dashRangesOffKeepsTextDash() {
        // Диапазоны выключены — 2002-2009 не трогаем, но тире в тексте работает.
        let out = run("с 2002-2009 - это диапазон") { $0.dashRanges = false }
        #expect(out.contains("2002-2009"))
        #expect(out.contains("\u{00A0}— это"))
    }

    @Test func nbspShortWordsOffKeepsNumberWord() {
        // Предлоги выключены — "в лесу" без НБ, но "5 лет" с НБ (другой под-тумблер).
        let out = run("в лесу 5 лет") { $0.nbspShortWords = false }
        #expect(out.contains("в лесу"))
        #expect(out.contains("5\u{00A0}лет"))
    }

    @Test func currencyGroupingOffKeepsSymbol() {
        // Группировка выключена — символ валюты ставится, но разряды не группируются.
        let out = run("2345123 руб.") { $0.currencyGrouping = false }
        #expect(out.contains("2345123\u{00A0}₽"))
    }

    @Test func punctOrderOffKeepsCollapse() {
        // Порядок !? не чиним, но повторы схлопываем.
        let out = run("что!? да!!!") { $0.punctOrder = false }
        #expect(out.contains("что!?"))
        #expect(out.contains("да!"))
    }
}
