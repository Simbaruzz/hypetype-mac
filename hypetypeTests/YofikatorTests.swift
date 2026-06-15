//
//  YofikatorTests.swift
//  hypetypeTests
//
//  Тесты ёфикатора G8: раскрытие парадигм, регистр, идемпотентность, загрузка словаря.
//

import Testing
@testable import hypetype

struct YofikatorTests {

    // MARK: - Раскрытие парадигм (чистая функция, без словаря)

    @Test func expandParadigm() {
        #expect(Yofikator.expand("актёр(|а|ам)") == ["актёр", "актёра", "актёрам"])
    }
    @Test func expandSingleForm() {
        #expect(Yofikator.expand("алтарём") == ["алтарём"])
    }

    // MARK: - Регистр

    @Test func applyCaseCapitalized() {
        #expect(Yofikator.applyCase(pattern: "Актер", to: "актёр") == "Актёр")
    }
    @Test func applyCaseUpper() {
        #expect(Yofikator.applyCase(pattern: "АКТЕР", to: "актёр") == "АКТЁР")
    }
    @Test func applyCaseLower() {
        #expect(Yofikator.applyCase(pattern: "актер", to: "актёр") == "актёр")
    }

    // MARK: - Реальный словарь из бандла

    @Test func dictionaryLoads() {
        #expect(Yofikator.shared.isLoaded, "yodict.txt не загрузился из бандла")
    }

    @Test func yoficatesCommonWords() {
        let y = Yofikator.shared
        #expect(y.yoficate("актер вышел на сцену") == "актёр вышел на сцену")
        #expect(y.yoficate("Береза") == "Берёза")
    }

    @Test func preservesCaseInSentence() {
        #expect(Yofikator.shared.yoficate("Полет нормальный") == "Полёт нормальный")
    }

    @Test func idempotent() {
        let once = Yofikator.shared.yoficate("актер у березы")
        #expect(Yofikator.shared.yoficate(once) == once)
        // Уже-ё-форма не трогается повторно.
        #expect(Yofikator.shared.yoficate("актёр") == "актёр")
    }

    @Test func leavesUnknownWordsUntouched() {
        #expect(Yofikator.shared.yoficate("дом стоит") == "дом стоит")
    }
}
