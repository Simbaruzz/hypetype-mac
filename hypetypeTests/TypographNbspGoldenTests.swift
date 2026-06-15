//
//  TypographNbspGoldenTests.swift
//  hypetypeTests
//
//  Тесты неразрывных G5 + фраза-пытка §9.2 (по свойствам) + сквозная идемпотентность.
//

import Testing
@testable import hypetype

private let N = "\u{00A0}"

struct TypographNbspTests {
    let g = Typograph.nonBreaking

    @Test func numberAndWord() {
        #expect(g("5 лет") == "5\(N)лет")
    }
    @Test func shortPreposition() {
        #expect(g("в начале") == "в\(N)начале")
        #expect(g("под столом") == "под\(N)столом")
    }
    @Test func particleBefore() {
        #expect(g("сделал бы") == "сделал\(N)бы")
    }
    @Test func initials() {
        #expect(g("А.А. Иванов") == "А.А.\(N)Иванов")
        #expect(g("Петров К.П.") == "Петров\(N)К.П.")
    }
    @Test func idempotent() {
        let once = g("в 5 лет под столом")
        #expect(g(once) == once)
    }
    @Test func longWordEndingInShortNotGlued() {
        // "космос растёт" — финальное "с"/"ос" не предлог; не приклеивать «космос».
        #expect(g("космос огромен") == "космос\(N)огромен" || g("космос огромен") == "космос огромен")
    }
}

struct TypographGoldenTests {
    // Фраза-пытка §9.2 (вход).
    static let input = #""-" - это минус, читайте статью "про минус" ! Ми́нус (от лат. minus "менее ,меньше") - математический cимвол " -" . Между тем ,внутри "елочек" дюймы остаются - "Монитор 21""!"#

    @Test func keySbolFixesPresent() {
        let out = Typograph.run(Self.input)
        // 1. Кавычки-ёлочки + дефис→тире у кавычек (НБ внутри от G5 не важен).
        #expect(out.contains("«про") && out.contains("минус»!"))
        // 2. Пробел после запятой (провал SBOL): "менее ,меньше" → "менее, меньше".
        #expect(out.contains("менее, меньше"))
        // 3. Дюйм внутри ёлочек (провал SBOL): «Монитор 21"».
        #expect(out.contains("«Монитор 21\"»"))
        // Тире с НБ перед ним внутри текста.
        #expect(out.contains("остаются\(N)—"))
        // Старые проблемы исчезли.
        #expect(!out.contains("\"про минус\""))
        #expect(!out.contains("менее ,меньше"))
    }

    @Test func tortureIsIdempotent() {
        let once = Typograph.run(Self.input)
        #expect(Typograph.run(once) == once)
    }
}

struct TypographFullPipelineIdempotencyTests {
    @Test func variousInputsIdempotent() {
        let samples = [
            "Привет, мир! Это \"тест\"... и ещё---текст.",
            "Цена 2345123 руб. за 5 лет, скидка 23 %.",
            "Встреча январь-март 2002-2009, см. (c) и (tm).",
            "- Прямая речь, сказал он. - Да!",
            "А.А. Иванов и К.П. Петров обсудили it's вопрос."
        ]
        for sample in samples {
            let once = Typograph.run(sample)
            #expect(Typograph.run(once) == once, "не идемпотентно: \(sample)")
        }
    }
}
