//
//  Layout.swift
//  hypetype
//
//  Доменная модель раскладки в памяти (§7 FORMAT.md — round-trip).
//  Чистые типы данных, без I/O и UI. Конвертация String ⇄ Layout — в LayoutFormat.swift.
//

import Foundation

/// Значение одной клавиши: что вводит Hyper+клавиша (alt) и Hyper+Shift+клавиша (altShift).
/// Хранится как массивы Unicode-скаляров (§4 — последовательности кодпоинтов).
struct LayoutValue: Equatable {
    var alt: [Unicode.Scalar]
    var altShift: [Unicode.Scalar]

    var isEmpty: Bool { alt.isEmpty && altShift.isEmpty }

    static let empty = LayoutValue(alt: [], altShift: [])
}

/// Неизвестный ключ внутри [Layout] — сохраняется как есть для round-trip (§4.6, §7.2).
struct LayoutRawEntry: Equatable {
    let key: String
    let rawValue: String   // verbatim текст значения после '=' (без комментария)
}

/// Пара ключ=значение платформенной секции (§3.3).
struct SettingEntry: Equatable {
    let key: String
    let value: String
}

/// Чужая секция (для macOS это [Windows] и любые будущие) — сохраняется построчно (§7.1).
struct ForeignSection: Equatable {
    let name: String        // без скобок
    let lines: [String]     // тело секции verbatim (с комментариями), без строки-заголовка
}

/// Полная модель распарсенного config.ini.
struct Layout: Equatable {
    /// Версия формата (§3.1). 0 = секция [hypetype]/version отсутствует (legacy).
    var version: Int = 2

    /// Известные клавиши [Layout], ключ — W3C-имя (§5).
    var entries: [String: LayoutValue] = [:]

    /// Неизвестные ключи [Layout] в исходном порядке.
    var unknownLayoutEntries: [LayoutRawEntry] = []

    /// Настройки собственной платформенной секции ([macOS]) в исходном порядке.
    var platformSettings: [SettingEntry] = []

    /// Чужие секции в исходном порядке.
    var foreignSections: [ForeignSection] = []

    /// Есть ли валидная версия формата v2+ (иначе — кандидат на миграцию).
    var isLegacy: Bool { version < 2 }
}
