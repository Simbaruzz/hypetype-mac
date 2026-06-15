//
//  SettingsManager.swift
//  hypetype
//
//  Управление настройками приложения
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "isEnabled")
        }
    }
    
    // DEPRECATED: Всегда используется прямой ввод (автоматически выбирает clipboard для эмодзи)
    // Оставлено для обратной совместимости
    @Published var useClipboardMethod: Bool {
        didSet {
            UserDefaults.standard.set(useClipboardMethod, forKey: "useClipboardMethod")
        }
    }
    
    private init() {
        // ✅ При первом запуске виртуализация ВСЕГДА выключена (false по умолчанию)
        self.isEnabled = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? false
        self.useClipboardMethod = false // Всегда false - используем только прямой ввод
        
        print("🔧 SettingsManager init: isEnabled = \(self.isEnabled)")
        print("📍 UserDefaults suite: \(UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.contains("isEnabled") })")
    }
    
    // 🧪 DEBUG: Сброс настроек
    #if DEBUG
    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "isEnabled")
        UserDefaults.standard.removeObject(forKey: "useClipboardMethod")
        UserDefaults.standard.synchronize()
        
        self.isEnabled = false
        self.useClipboardMethod = false
        
        print("🧪 DEBUG: Настройки сброшены к defaults")
    }
    #endif
}
