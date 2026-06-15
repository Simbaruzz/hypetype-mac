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

    /// Применять ли ёфикатор (е→ё) вместе с типографом по R⌥+Backspace. По умолчанию выключен (opt-in).
    @Published var useYofikator: Bool {
        didSet {
            UserDefaults.standard.set(useYofikator, forKey: "useYofikator")
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? false
        self.useYofikator = UserDefaults.standard.object(forKey: "useYofikator") as? Bool ?? false
    }
}
