//
//  Yofikator.swift
//  hypetype
//
//  Ёфикатор (G8): восстановление ё в однозначных словоформах по словарю-ресурсу.
//  Словарь — данные (yodict.txt, сабсет eyo-kernel MIT), не код. Только однозначные
//  слова без омографов (все/всё). Подключается отдельной группой в обработчике хоткея.
//

import Foundation
import OSLog

nonisolated final class Yofikator {
    static let shared = Yofikator()

    private static let log = Logger(subsystem: "hypetype", category: "Yofikator")

    /// е-форма (lowercase) → ё-форма (lowercase). Строится лениво один раз.
    private let map: [String: String]

    var isLoaded: Bool { !map.isEmpty }

    private init() {
        map = Yofikator.loadDictionary()
        Yofikator.log.info("Yo dictionary loaded: \(self.map.count) forms")
    }

    // MARK: - Загрузка и раскрытие словаря

    private static func loadDictionary() -> [String: String] {
        guard let url = Bundle(for: Yofikator.self).url(forResource: "yodict", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            log.error("yodict.txt not found in bundle")
            return [:]
        }
        var result: [String: String] = [:]
        text.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            for form in expand(trimmed) {
                let yo = form.lowercased()
                let e = yo.replacingOccurrences(of: "ё", with: "е")
                if e != yo { result[e] = yo }   // только формы, реально содержащие ё
            }
        }
        return result
    }

    /// Раскрывает "основа(суф1|суф2|...)" в полные формы; одиночная форма — как есть.
    static func expand(_ line: String) -> [String] {
        guard let open = line.firstIndex(of: "("), line.hasSuffix(")") else {
            return [line]
        }
        let stem = String(line[..<open])
        let inside = line[line.index(after: open)..<line.index(before: line.endIndex)]
        return inside.components(separatedBy: "|").map { stem + $0 }
    }

    // MARK: - Ёфикация

    /// Заменяет е→ё в однозначных словоформах, сохраняя регистр исходного слова.
    /// Идемпотентна: уже-ё-слова не в словаре (ключи — е-формы), повторно не трогаются.
    func yoficate(_ text: String) -> String {
        guard isLoaded else { return text }
        return Typograph.replaceMatches(text, #"[А-Яа-яЁё]+"#) { groups in
            let token = groups[0]
            guard let yo = map[token.lowercased()] else { return token }
            return Yofikator.applyCase(pattern: token, to: yo)
        }
    }

    /// Накладывает регистр исходного токена на ё-форму (та же длина и буквы, отличие е↔ё).
    static func applyCase(pattern: String, to target: String) -> String {
        let p = Array(pattern), t = Array(target)
        guard p.count == t.count else { return target }
        var out = ""
        for i in t.indices {
            out += p[i].isUppercase ? t[i].uppercased() : String(t[i])
        }
        return out
    }
}
