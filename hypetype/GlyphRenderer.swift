//
//  GlyphRenderer.swift
//  hypetype
//
//  Рендер «кодпоинт(ы) → человекочитаемый глиф» (§6 FORMAT.md).
//  Используется автокомментариями config.ini, в будущем — подписями клавиш редактора (Этап 4).
//

import Foundation

enum GlyphRenderer {
    /// Носитель для комбинирующей диакритики — DOTTED CIRCLE (U+25CC).
    private static let carrier = "\u{25CC}"

    /// Заглушка для пустого значения.
    static let emptyPlaceholder = "—"

    /// Является ли скаляр комбинирующей диакритикой (U+0300..U+036F).
    static func isCombiningDiacritic(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value >= 0x0300 && scalar.value <= 0x036F
    }

    /// Человекочитаемое представление одного скаляра (§6.2–6.3).
    static func render(_ scalar: Unicode.Scalar) -> String {
        switch scalar.value {
        case 0x20:    return "␣"            // обычный пробел
        case 0xA0:    return "⍽"            // nbsp
        case 0x200B:  return "ZWSP"         // zero-width space
        default:
            break
        }

        if isCombiningDiacritic(scalar) {
            return carrier + String(scalar)  // ◌̋ — диакритика видна на носителе
        }

        // Прочие невидимые/управляющие → ·U+XXXX·
        switch scalar.properties.generalCategory {
        case .control, .format, .lineSeparator, .paragraphSeparator, .spaceSeparator, .unassigned:
            return "·U+\(hex(scalar))·"
        default:
            return String(scalar)
        }
    }

    /// Представление последовательности скаляров; пустая → «—» (§6.4).
    static func render(_ scalars: [Unicode.Scalar]) -> String {
        guard !scalars.isEmpty else { return emptyPlaceholder }
        return scalars.map(render).joined()
    }

    /// Автокомментарий для значения клавиши: `<Alt> | <AltShift>` (§6.1).
    static func comment(for value: LayoutValue) -> String {
        "\(render(value.alt)) | \(render(value.altShift))"
    }

    /// Hex-номер скаляра, верхний регистр, минимум 4 знака.
    private static func hex(_ scalar: Unicode.Scalar) -> String {
        String(format: "%04X", scalar.value)
    }
}
