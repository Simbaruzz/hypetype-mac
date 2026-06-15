//
//  MappingManager.swift
//  hypetype
//
//  Чтение/запись config.json (legacy JSON-формат, Этап 1).
//  Этап 2 заменит этот файл на LayoutStore.swift + LayoutFormat.swift.
//

import Foundation
import AppKit
import OSLog

private let log = Logger(subsystem: "hypetype", category: "MappingManager")

class MappingManager {
    static let shared = MappingManager()

    private let fileName = "config.json"
    private var usingFallbackPath = false

    private lazy var configURL: URL = getConfigURL()

    private func getConfigURL() -> URL {
        let fm = FileManager.default

        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let folder = appSupport.appendingPathComponent("hypetype")
            let config = folder.appendingPathComponent(fileName)

            if fm.fileExists(atPath: folder.path) {
                return config
            }
            do {
                try fm.createDirectory(at: folder, withIntermediateDirectories: true)
                return config
            } catch {
                log.error("Cannot create Application Support folder: \(error)")
            }
        }

        usingFallbackPath = true
        let temp = fm.temporaryDirectory.appendingPathComponent("hypetype").appendingPathComponent(fileName)
        try? fm.createDirectory(at: temp.deletingLastPathComponent(), withIntermediateDirectories: true)
        log.warning("Using temporary folder as fallback: \(temp.path)")
        return temp
    }

    // MARK: - Model

    struct KeyMapping: Codable {
        let keyCode: Int
        let normal: String
        let shift: String
        let comment: String?
    }

    // MARK: - Load / Save

    func loadMappings() -> [Int: (normal: String, shift: String)] {
        if FileManager.default.fileExists(atPath: configURL.path) {
            do {
                let data = try Data(contentsOf: configURL)
                let mappings = try JSONDecoder().decode([KeyMapping].self, from: data)
                let result = Dictionary(uniqueKeysWithValues: mappings.map { ($0.keyCode, ($0.normal, $0.shift)) })
                log.info("Loaded \(result.count) mappings from \(self.configURL.lastPathComponent)")
                return result
            } catch {
                log.error("Failed to read config: \(error) — falling back to defaults")
            }
        }

        let defaults = KeyDefinitions.defaultLayout
        saveMappings(defaults)
        return defaults
    }

    func saveMappings(_ mappings: [Int: (normal: String, shift: String)]) {
        let array = mappings.sorted { $0.key < $1.key }.map {
            KeyMapping(
                keyCode: $0.key,
                normal: $0.value.normal,
                shift: $0.value.shift,
                comment: KeyDefinitions.byMacKeyCode[$0.key]?.displayLabel
            )
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(array)
            try data.write(to: configURL, options: .atomic)
            log.info("Saved \(mappings.count) mappings to \(self.configURL.lastPathComponent)")
        } catch let error as NSError {
            log.error("Save failed (\(error.domain) \(error.code)): \(error.localizedDescription)")
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Не удалось сохранить настройки"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    // MARK: - Helpers

    func revealConfigFile() {
        NSWorkspace.shared.activateFileViewerSelecting([configURL])
    }

    func getConfigPath() -> String {
        return configURL.path
    }
}
