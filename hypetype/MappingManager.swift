//
//  MappingManager.swift
//  hypetype
//
//  Управление маппингами символов из JSON файла
//

import Foundation
import AppKit

class MappingManager {
    static let shared = MappingManager()
    
    private let fileName = "config.json"
    
    // ⚠️ Флаг: используем ли fallback путь
    private var usingFallbackPath = false
    
    // 🔤 Константы для символов (используются в маппингах)
    private static let deadKey = "\u{0060}\u{0020}"  // ` + пробел (для dead keys)
    private static let space = "\u{0020}"            // обычный пробел
    private static let empty = ""                    // пустая строка
    
    // Кешируем путь чтобы не вычислять каждый раз
    private lazy var configURL: URL = {
        return getConfigURL()
    }()
    
    // 🛡️ БЕЗОПАСНОЕ получение пути к конфигу с fallback
    private func getConfigURL() -> URL {
        let fileManager = FileManager.default
        
        // Попытка 1: Стандартный путь в Application Support
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appFolder = appSupportURL.appendingPathComponent("hypetype")
            let configPath = appFolder.appendingPathComponent(fileName)
            
            print("🔍 Путь к конфигу (Application Support):")
            print("   Config Path: \(configPath.path)")
            
            // Пробуем создать папку если не существует
            if !fileManager.fileExists(atPath: appFolder.path) {
                do {
                    try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
                    print("   ✅ Папка создана")
                    return configPath
                } catch {
                    print("   ⚠️ Не удалось создать папку: \(error.localizedDescription)")
                    // Переходим к fallback
                }
            } else {
                print("   ✅ Папка существует")
                return configPath
            }
        }
        
        // Попытка 2: Fallback — временная папка
        print("⚠️ Application Support недоступен, используем Temporary Directory")
        usingFallbackPath = true
        
        let tempURL = fileManager.temporaryDirectory
            .appendingPathComponent("hypetype")
            .appendingPathComponent(fileName)
        
        print("   Fallback Path: \(tempURL.path)")
        
        // Создаём папку в Temp
        let tempFolder = tempURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: tempFolder.path) {
            do {
                try fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true)
                print("   ✅ Временная папка создана")
            } catch {
                print("   ❌ Критическая ошибка: не удалось создать даже временную папку")
                // Показываем алерт пользователю
                showCriticalError(message: "Не удалось создать папку настроек.\n\nПроверьте права доступа к файловой системе.")
            }
        }
        
        return tempURL
    }
    
    // Структура для JSON
    struct KeyMapping: Codable {
        let keyCode: Int
        let normal: String
        let shift: String
        let comment: String?
    }
    
    // Загрузка маппингов
    func loadMappings() -> [Int: (normal: String, shift: String)] {
        // Если файл существует — загружаем
        if FileManager.default.fileExists(atPath: configURL.path) {
            do {
                let data = try Data(contentsOf: configURL)
                let mappings = try JSONDecoder().decode([KeyMapping].self, from: data)
                
                var result: [Int: (normal: String, shift: String)] = [:]
                for mapping in mappings {
                    result[mapping.keyCode] = (mapping.normal, mapping.shift)
                }
                
                print("✅ Маппинги загружены из: \(configURL.path)")
                print("📊 Загружено символов: \(result.count)")
                return result
            } catch {
                print("⚠️ Ошибка чтения JSON: \(error)")
                print("🔄 Используем defaults и создаём новый файл")
            }
        }
        
        // Если файла нет или ошибка — создаём с defaults
        let defaults = KeyDefinitions.defaultLayout
        saveMappings(defaults)
        return defaults
    }
    
    // Сохранение маппингов
    func saveMappings(_ mappings: [Int: (normal: String, shift: String)]) {
        print("💾 Начало сохранения маппингов...")
        print("   Количество маппингов: \(mappings.count)")
        print("   Целевой путь: \(configURL.path)")

        var array: [KeyMapping] = []

        // Конвертируем в массив с комментариями
        for (keyCode, values) in mappings.sorted(by: { $0.key < $1.key }) {
            let comment = KeyDefinitions.byMacKeyCode[keyCode]?.displayLabel
            array.append(KeyMapping(
                keyCode: keyCode,
                normal: values.normal,
                shift: values.shift,
                comment: comment
            ))
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(array)
            
            print("   JSON размер: \(data.count) байт")
            
            // 🛡️ Пробуем записать файл
            try data.write(to: configURL, options: .atomic)
            
            print("✅ Маппинги успешно сохранены!")
            print("📍 Полный путь: \(configURL.path)")
            
            // Проверяем что файл действительно создался
            if FileManager.default.fileExists(atPath: configURL.path) {
                print("✅ Файл существует!")
                if let attrs = try? FileManager.default.attributesOfItem(atPath: configURL.path) {
                    print("   Размер файла: \(attrs[.size] ?? 0) байт")
                }
            } else {
                print("⚠️ ВНИМАНИЕ: Файл НЕ найден после записи!")
            }
        } catch let error as NSError {
            // 🛡️ ОБРАБОТКА ОШИБОК ЗАПИСИ
            print("❌ Ошибка сохранения: \(error.localizedDescription)")
            print("   Код ошибки: \(error.code)")
            print("   Домен: \(error.domain)")
            
            // Определяем тип ошибки и показываем понятное сообщение
            var errorMessage = "Не удалось сохранить настройки."
            var suggestion = ""
            
            if error.domain == NSCocoaErrorDomain {
                switch error.code {
                case NSFileWriteOutOfSpaceError:
                    errorMessage = "Диск заполнен!"
                    suggestion = "Освободите место на диске и попробуйте снова."
                case NSFileWriteNoPermissionError:
                    errorMessage = "Нет прав на запись файла."
                    suggestion = "Проверьте права доступа к:\n\(configURL.path)"
                case NSFileWriteVolumeReadOnlyError:
                    errorMessage = "Диск только для чтения."
                    suggestion = "Настройки будут потеряны при перезапуске."
                default:
                    suggestion = "Ошибка: \(error.localizedDescription)"
                }
            }
            
            // Показываем алерт пользователю
            showSaveError(message: errorMessage, suggestion: suggestion)
            
            // 🛡️ Если используем fallback путь — предупреждаем
            if usingFallbackPath {
                print("⚠️ ВНИМАНИЕ: Используется временная папка!")
                print("   Настройки будут потеряны при перезагрузке системы.")
            }
        }
    }
    
    // 🛡️ Показать ошибку сохранения
    private func showSaveError(message: String, suggestion: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = suggestion
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // Открыть файл в Finder (для удобства)
    func revealConfigFile() {
        NSWorkspace.shared.activateFileViewerSelecting([configURL])
    }
    
    // Показать путь к файлу в алерте
    func showConfigPath() {
        let alert = NSAlert()
        alert.messageText = "Расположение файла настроек"
        alert.informativeText = "Файл: \(fileName)\n\nПуть:\n\(configURL.path)\n\nСуществует: \(FileManager.default.fileExists(atPath: configURL.path) ? "✅ Да" : "❌ Нет")"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Открыть в Finder")
        alert.addButton(withTitle: "Скопировать путь")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            // Открыть в Finder
            revealConfigFile()
        } else if response == .alertSecondButtonReturn {
            // Скопировать путь
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(configURL.path, forType: .string)
        }
    }
    
    // Получить путь к конфигу (для внешнего использования)
    func getConfigPath() -> String {
        return configURL.path
    }
    
    // 🛡️ Показать критическую ошибку пользователю
    private func showCriticalError(message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Критическая ошибка файловой системы"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
}
