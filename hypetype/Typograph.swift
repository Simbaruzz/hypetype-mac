//
//  Typograph.swift
//  hypetype
//
//  Чистый типограф русского текста (порт src/typograph.ahk, см. TYPOGRAPH.md).
//  Ядро — функция Typograph.run(text, settings) -> text. Без GUI, буфера, хоткеев.
//  Правила идемпотентны: run(run(x)) == run(x) (TYPOGRAPH.md §3).
//
//  Конвейер (порядок критичен, §6):
//    G4-обрезка краёв → G1 кавычки → G3 пунктуация → G2 тире →
//    G4 чистка пробелов → G6 числа/валюта → G7 символы →
//    G5 неразрывные (последними) → финальная G4-чистка.
//

import Foundation

/// Неразрывный пробел U+00A0.
let NBSP = "\u{00A0}"
/// Узкий неразрывный пробел U+202F (для PercentSpace=narrow).
let NNBSP = "\u{202F}"

nonisolated struct TypographSettings: Equatable {
    enum PercentSpace: String { case none, narrow }
    enum CurrencyPosition: String { case after, before }

    var quotes = true
    var dashes = true
    var punct = true
    var spaceClean = true
    var nbsp = true
    var numbers = true
    var symbols = true
    var percentSpace: PercentSpace = .none
    var currencyPosition: CurrencyPosition = .after

    static let `default` = TypographSettings()
}

nonisolated enum Typograph {

    // MARK: - Точка входа

    static func run(_ text: String, _ settings: TypographSettings = .default) -> String {
        var s = text

        s = trimLineEdges(s)                                   // G4 (края)
        if settings.quotes      { s = quotesAutomaton(s) }     // G1
        if settings.punct       { s = punctuation(s) }         // G3
        if settings.dashes      { s = dashes(s) }              // G2
        if settings.spaceClean  { s = spaceClean(s, settings) }// G4
        if settings.numbers     { s = numbers(s, settings) }   // G6
        if settings.symbols     { s = symbols(s) }             // G7
        if settings.nbsp        { s = nonBreaking(s) }         // G5
        s = collapseSpaces(s)                                  // финальная G4

        return s
    }

    // MARK: - G3. Пунктуация (многоточие, схлопывание повторов)

    static func punctuation(_ text: String) -> String {
        var s = text
        // Смешанные с многоточием → SBOL-стиль с ‥ (U+2025). До схлопывания точек.
        s = replace(s, #"\.{3,}([?!])"#, "$1\u{2025}")   // ...?  → ?‥
        s = replace(s, #"([?!])\.{3,}"#, "$1\u{2025}")   // ?...  → ?‥
        // Три и более точек → многоточие.
        s = replace(s, #"\.{3,}"#, "\u{2026}")
        // Схлопывание повторов одного и того же знака до одного.
        s = replace(s, #"!{2,}"#, "!")
        s = replace(s, #"\?{2,}"#, "?")
        s = replace(s, #"([,;:])\1+"#, "$1")
        // Нормализация порядка.
        s = replace(s, #"!\?"#, "?!")
        return s
    }

    // MARK: - G4. Чистка пробелов

    /// Обрезка пробелов/табов в начале и конце каждой строки (переносы сохраняются).
    static func trimLineEdges(_ text: String) -> String {
        var s = text
        s = replace(s, #"(?m)^[ \t]+"#, "")
        s = replace(s, #"(?m)[ \t]+$"#, "")
        return s
    }

    static func spaceClean(_ text: String, _ settings: TypographSettings) -> String {
        var s = text
        // Убрать пробел после открывающих.
        s = replace(s, #"([«„(\[]) +"#, "$1")
        // Убрать пробел перед закрывающими/знаками препинания.
        s = replace(s, #" +([.…:,;?!»“)\]])"#, "$1")
        // Добавить пробел после , ; : перед буквой (не цифрой — десятичные/время не трогаем).
        s = replace(s, #"([,;:])(\p{L})"#, "$1 $2")
        // Процент.
        switch settings.percentSpace {
        case .none:   s = replace(s, #"(\d) +%"#, "$1%")
        case .narrow: s = replace(s, #"(\d)\x{00A0}?\x{202F}? *%"#, "$1\u{202F}%")
        }
        // Двойные+ обычные пробелы → один.
        s = collapseSpaces(s)
        return s
    }

    /// Схлопывание подряд идущих ОБЫЧНЫХ пробелов (НБ-конструкции не трогаем).
    static func collapseSpaces(_ text: String) -> String {
        replace(text, #" {2,}"#, " ")
    }

    // MARK: - G7. Символы

    static func symbols(_ text: String) -> String {
        var s = text
        s = replace(s, #"\([cCсС]\)"#, "\u{00A9}")          // (c) → ©
        s = replace(s, #"\([rR]\)"#, "\u{00AE}")            // (r) → ®
        s = replace(s, #"\((?i:tm)\)"#, "\u{2122}")         // (tm) → ™
        s = replace(s, #"\+-"#, "\u{00B1}")                 // +- → ±
        s = replace(s, #"№ *(\d)"#, "№\u{00A0}$1")          // № 5 → №<НБ>5
        return s
    }

    // MARK: - Заглушки (реализуются следующими шагами)

    static func quotesAutomaton(_ text: String) -> String { text }   // G1 — TODO
    static func dashes(_ text: String) -> String { text }            // G2 — TODO
    static func numbers(_ text: String, _ s: TypographSettings) -> String { text } // G6 — TODO
    static func nonBreaking(_ text: String) -> String { text }       // G5 — TODO

    // MARK: - Regex-хелпер

    static func replace(_ text: String, _ pattern: String, _ template: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return re.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }
}
