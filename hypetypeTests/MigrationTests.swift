//
//  MigrationTests.swift
//  hypetypeTests
//
//  Тесты моста Layout ⇄ рантайм-словарь и миграции legacy config.json (§8.2 FORMAT.md).
//

import Testing
import Foundation
@testable import hypetype

struct MigrationTests {

    // MARK: - Мост macKeyCode ⇄ W3C

    @Test func standardLayoutRoundTripsThroughMacMappings() {
        let layout = Layout.standard
        let mac = layout.toMacMappings()
        // KeyE (0x0E) → € normal, ⌥ shift
        #expect(mac[0x0E]?.normal == "€")
        #expect(mac[0x0E]?.shift == "⌥")
        // Применяем обратно — known-ключи восстанавливаются.
        var rebuilt = Layout(version: 2)
        rebuilt.applyMacMappings(mac)
        #expect(rebuilt.entries["KeyE"] == layout.entries["KeyE"])
    }

    @Test func applyMacMappingsRemovesEmptyKeys() {
        var layout = Layout.standard
        layout.applyMacMappings([0x0E: ("", "")])   // очищаем KeyE
        #expect(layout.entries["KeyE"] == nil)
    }

    @Test func applyMacMappingsPreservesForeignSections() {
        var layout = Layout.standard
        layout.foreignSections = [ForeignSection(name: "Windows", lines: ["DiacriticTimeoutMs=3000"])]
        layout.applyMacMappings([0x0E: ("X", "")])
        #expect(layout.foreignSections.contains { $0.name == "Windows" })
    }

    // MARK: - Миграция legacy JSON (§8.2)

    private func legacyJSON(_ items: [(Int, String, String)]) -> Data {
        let arr = items.map { ["keyCode": $0.0, "normal": $0.1, "shift": $0.2] as [String: Any] }
        return try! JSONSerialization.data(withJSONObject: arr)
    }

    @Test func migratesBasicKeys() {
        let data = legacyJSON([(0x0E, "€", "⌥"), (0x04, "₽", "\u{030B}")])
        let layout = LayoutStore.layoutFromLegacyJSON(data)
        #expect(layout?.entries["KeyE"] == LayoutValue(alt: Array("€".unicodeScalars), altShift: Array("⌥".unicodeScalars)))
        #expect(layout?.entries["KeyH"] == LayoutValue(alt: Array("₽".unicodeScalars), altShift: [Unicode.Scalar(0x030B)!]))
        #expect(layout?.version == 2)
    }

    @Test func migratesEmojiByScalarsNotGraphemes() {
        // Ключевой кейс §8.2: эмодзи должен дать ОДИН кодпоинт 1F60E, а не суррогаты/графему.
        let data = legacyJSON([(0x11, "😎", "")])
        let layout = LayoutStore.layoutFromLegacyJSON(data)
        let alt = layout?.entries["KeyT"]?.alt
        #expect(alt == [Unicode.Scalar(0x1F60E)!])
        #expect(alt?.count == 1)
    }

    @Test func migratesMultiScalarSequence() {
        // Дивайдер ␣·␣ — три скаляра.
        let data = legacyJSON([(0x31, "\u{0020}\u{00B7}\u{0020}", "")])
        let layout = LayoutStore.layoutFromLegacyJSON(data)
        #expect(layout?.entries["Space"]?.alt == [Unicode.Scalar(0x20)!, Unicode.Scalar(0xB7)!, Unicode.Scalar(0x20)!])
    }

    @Test func migrationProducesValidV2File() {
        // Сквозной тест: legacy JSON → Layout → сериализация → парсинг даёт то же.
        let data = legacyJSON([(0x0E, "€", "⌥"), (0x11, "😎", "")])
        let migrated = LayoutStore.layoutFromLegacyJSON(data)!
        let text = LayoutFormat.serialize(migrated)
        let reparsed = LayoutFormat.parse(text)
        #expect(reparsed.entries["KeyE"] == migrated.entries["KeyE"])
        #expect(reparsed.entries["KeyT"] == migrated.entries["KeyT"])
        #expect(text.contains("[hypetype]"))
        #expect(text.contains("KeyT=1F60E|"))
    }

    @Test func rejectsGarbageJSON() {
        #expect(LayoutStore.layoutFromLegacyJSON(Data("not json".utf8)) == nil)
    }

    // MARK: - Таймаут диакритики из [macOS] (§3.3)

    @Test func readsDiacriticTimeoutFromMacOSSection() {
        let text = """
        [hypetype]
        version=2

        [Layout]
        KeyE=20AC|2325

        [macOS]
        DiacriticTimeoutMs=2500
        """
        let layout = LayoutFormat.parse(text)
        #expect(layout.diacriticTimeoutSeconds == 2.5)
    }

    @Test func diacriticTimeoutDefaultsWhenAbsent() {
        // Файл без [macOS] (например, чисто виндовый) → дефолт 3 с.
        let text = "[hypetype]\nversion=2\n\n[Layout]\nKeyE=20AC|2325\n\n[Windows]\nDiacriticTimeoutMs=9999\n"
        let layout = LayoutFormat.parse(text)
        #expect(layout.diacriticTimeoutSeconds == 3.0)   // [Windows] чужая — не читается
    }

    @Test func skipsUnknownKeyCodes() {
        let data = legacyJSON([(0x0E, "€", "⌥"), (999, "X", "Y")])   // 999 нет в таблице
        let layout = LayoutStore.layoutFromLegacyJSON(data)
        #expect(layout?.entries.count == 1)
        #expect(layout?.entries["KeyE"] != nil)
    }
}
