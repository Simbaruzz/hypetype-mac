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
        let defaults = getDefaultMappings()
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
            let comment = getKeyComment(for: keyCode)
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
    
    // Defaults — маппинги из Windows версии (все символы в Unicode)
    func getDefaultMappings() -> [Int: (normal: String, shift: String)] {
        return [
            // Цифровой ряд
            0x12: ("\u{00B9}", "\u{00A1}"),      // 1 - ¹ ¡ (superscript one, inverted exclamation)
            0x13: ("\u{00B2}", "\u{00BD}"),      // 2 - ² ½ (superscript two, one half)
            0x14: ("\u{00B3}", "\u{2153}"),      // 3 - ³ ⅓ (superscript three, one third)
            0x15: ("\u{0024}", "\u{00BC}"),      // 4 - $ ¼ (dollar, one quarter)
            0x17: ("\u{2030}", "\u{0020}"),      // 5 - ‰ пробел (per mille, space)
            0x16: ("\u{2191}", "\u{0302}"),      // 6 - ↑ ̂ (up arrow, combining circumflex)
            0x1A: ("\u{2197}", "\u{00BF}"),      // 7 - пробел ¿ (arrow, inverted question mark)
            0x1C: ("\u{221E}", "\u{0020}"),      // 8 - ∞ пробел (infinity, space)
            0x19: ("\u{2190}", "\u{2039}"),      // 9 - ← ‹ (left arrow, single left angle quote)
            0x1D: ("\u{2192}", "\u{203A}"),      // 0 - → › (right arrow, single right angle quote)
            0x1B: ("\u{2014}", "\u{2013}"),      // - - — – (em dash, en dash)
            0x18: ("\u{2260}", "\u{00B1}"),      // = - ≠ ± (not equal, plus-minus)
            
            // Верхний буквенный ряд QWERTY
            0x0C: ("\u{0020}", "\u{0306}"),      // Q - пробел ̆ (space, combining breve)
            0x0D: ("\u{2713}", "\u{2303}"),      // W - ✓ ⌃ (check mark, control symbol)
            0x0E: ("\u{20AC}", "\u{2325}"),      // E - € ⌥ (euro, option key)
            0x0F: ("\u{00AE}", "\u{030A}"),      // R - ® ̊ (registered, combining ring above)
            0x11: ("\u{2122}", ""),              // T - ™ пусто (trademark, empty)
            0x10: ("\u{0463}", "\u{0462}"),      // Y - ѣ Ѣ (yat lowercase, yat uppercase)
            0x20: ("\u{0475}", "\u{0474}"),      // U - ѵ Ѵ (izhitsa lowercase, izhitsa uppercase)
            0x22: ("\u{0456}", "\u{0406}"),      // I - і І (byelorussian i lowercase, uppercase)
            0x1F: ("\u{0473}", "\u{0472}"),      // O - ѳ Ѳ (fita lowercase, fita uppercase)
            0x23: ("\u{2032}", "\u{2033}"),      // P - ′ ″ (prime, double prime)
            0x21: ("\u{005B}", "\u{007B}"),      // [ - [ { (left square bracket, left curly bracket)
            0x1E: ("\u{005D}", "\u{007D}"),      // ] - ] } (right square bracket, right curly bracket)
            
            // Средний буквенный ряд ASDF
            0x00: ("\u{2248}", "\u{2318}"),      // A - ≈ ⌘ (almost equal, command key)
            0x01: ("\u{00A7}", "\u{21E7}"),      // S - § ⇧ (section sign, shift key)
            0x02: ("\u{00B0}", "\u{2300}"),      // D - ° ⌀ (degree, diameter)
            0x03: ("\u{00A3}", "\u{0020}"),      // F - £ пробел (pound sterling, space)
            0x05: ("\u{F8FF}", "\u{229E}"),      // G - Apple ⊞ (apple, squared plus)
            0x04: ("\u{20BD}", "\u{030B}"),      // H - ₽ ̋ (ruble, combining double acute)
            0x26: ("\u{201E}", "\u{0020}"),      // J - „ пробел (double low-9 quotation, space)
            0x28: ("\u{201C}", "\u{2019}"),      // K - " ' (left double quote, right single quote)
            0x25: ("\u{201D}", "\u{2018}"),      // L - " ' (right double quote, left single quote)
            0x29: ("\u{2019}", "\u{0308}"),      // ; - ' ̈ (right single quote, combining diaeresis)
            0x27: ("\u{2018}", "\u{0020}"),      // ' - ' пробел (left single quote, space)
            0x2A: ("\u{007C}", "\u{005C}"),      // \ - | \ (vertical bar, backslash)
            
            // Нижний буквенный ряд ZXCVBNM
            0x06: ("\u{0020}", "\u{0327}"),      // Z - пробел ̧ (space, combining cedilla)
            0x07: ("\u{00D7}", "\u{00B7}"),      // X - × · (multiplication sign, middle dot)
            0x08: ("\u{00A9}", "\u{00A2}"),      // C - © ¢ (copyright, cent)
            0x09: ("\u{2193}", "\u{030C}"),      // V - ↓ ̌ (down arrow, combining caron)
            0x0B: ("\u{00DF}", "\u{1E9E}"),      // B - ß ẞ (sharp s lowercase, uppercase)
            0x2D: ("\u{2116}", "\u{0303}"),      // N - №  ̃ (nubmer, combining tilde)
            0x2E: ("\u{2212}", "\u{2022}"),      // M - − • (minus sign, bullet)
            0x2B: ("\u{00AB}", "\u{201E}"),      // , - « „ (left guillemet, double low-9 quote)
            0x2F: ("\u{00BB}", "\u{201C}"),      // . - » " (right guillemet, left double quote)
            0x2C: ("\u{2026}", "\u{0301}"),      // / - slash (ellipsis, combining acute accent)
            
            // Специальные клавиши
            0x32: ("\u{007E}", "\u{0300}"),      // ` ~ - пусто `` (empty, double backtick)
            0x31: ("\u{00A0}", "\u{0020}"),      // Space - пробел пробел (space, space)
        ]
    }
    
    // Комментарии для ключей (чтобы JSON было читаемым)
    private func getKeyComment(for keyCode: Int) -> String? {
        let comments: [Int: String] = [
            0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x17: "5",
            0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9", 0x1D: "0",
            0x1B: "-", 0x18: "=",
            0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R", 0x11: "T",
            0x10: "Y", 0x20: "U", 0x22: "I", 0x1F: "O", 0x23: "P",
            0x21: "[", 0x1E: "]",
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x05: "G",
            0x04: "H", 0x26: "J", 0x28: "K", 0x25: "L", 0x29: ";",
            0x27: "'",
            0x2A: "\\", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x2D: "N", 0x2E: "M", 0x32: "`~", 0x2B: ",", 0x2F: ".",
            0x2C: "/",
            0x31: "Space"
        ]
        return comments[keyCode]
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
    
    // ТЕСТ: Принудительно создать файл с тестовым содержимым
    func forceCreateTestFile() -> Bool {
        print("🧪 ТЕСТ: Принудительное создание файла...")
        print("   Путь: \(configURL.path)")
        
        let testContent = "TEST FILE CREATED"
        
        do {
            try testContent.write(to: configURL, atomically: true, encoding: .utf8)
            print("   ✅ Тестовый файл создан!")
            
            // Проверяем существование
            if FileManager.default.fileExists(atPath: configURL.path) {
                print("   ✅ Файл подтверждён!")
                return true
            } else {
                print("   ❌ Файл НЕ найден после создания!")
                return false
            }
        } catch {
            print("   ❌ Ошибка создания: \(error)")
            print("   Детали: \(error.localizedDescription)")
            return false
        }
    }
}
