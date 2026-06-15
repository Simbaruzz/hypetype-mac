//
//  KeyCodes.swift
//  hypetype
//
//  Справочник key codes для macOS
//  Используется для добавления новых маппингов
//

import Foundation

// MARK: - Key Code Reference

/*
 
 ⌨️ СПРАВОЧНИК KEY CODES macOS
 
 Используйте эти значения для добавления новых маппингов в EventTapManager
 
 === БУКВЫ ===
 0x00 = A        0x0B = B        0x08 = C        0x02 = D
 0x0E = E        0x03 = F        0x05 = G        0x04 = H
 0x22 = I        0x26 = J        0x28 = K        0x25 = L
 0x2E = M        0x2D = N        0x1F = O        0x23 = P
 0x0C = Q        0x0F = R        0x01 = S        0x11 = T
 0x20 = U        0x09 = V        0x0D = W        0x07 = X
 0x10 = Y        0x06 = Z
 
 === ЦИФРЫ ===
 0x12 = 1        0x13 = 2        0x14 = 3        0x15 = 4
 0x17 = 5        0x16 = 6        0x1A = 7        0x1C = 8
 0x19 = 9        0x1D = 0
 
 === СИМВОЛЫ ===
 0x18 = =        0x1B = -        0x21 = [        0x1E = ]
 0x27 = '        0x29 = ;        0x2A = \        0x2B = ,
 0x2C = /        0x2F = .        0x32 = `
 
 === МОДИФИКАТОРЫ (для справки) ===
 0x37 = Command (Left)
 0x38 = Shift (Left)
 0x3A = Option (Left)      ⚠️ НЕ ИСПОЛЬЗУЕМ
 0x3D = Option (Right)     ✅ ИСПОЛЬЗУЕМ
 0x3B = Control (Left)
 0x3C = Shift (Right)
 0x3E = Control (Right)
 0x36 = Command (Right)
 
 === СПЕЦИАЛЬНЫЕ ===
 0x24 = Return
 0x30 = Tab
 0x31 = Space
 0x33 = Delete
 0x35 = Escape
 
 === FUNCTION KEYS ===
 0x7A = F1       0x78 = F2       0x63 = F3       0x76 = F4
 0x60 = F5       0x61 = F6       0x62 = F7       0x64 = F8
 0x65 = F9       0x6D = F10      0x67 = F11      0x6F = F12
 
 === СТРЕЛКИ ===
 0x7E = Up       0x7D = Down     0x7B = Left     0x7C = Right
 
 */

// MARK: - Helper Extension

extension Int {
    /// Получить читаемое название клавиши
    var keyName: String {
        return KeyCodeMapper.keyName(for: self)
    }
}

struct KeyCodeMapper {
    static func keyName(for keyCode: Int) -> String {
        let names: [Int: String] = [
            // Буквы
            0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E",
            0x03: "F", 0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J",
            0x28: "K", 0x25: "L", 0x2E: "M", 0x2D: "N", 0x1F: "O",
            0x23: "P", 0x0C: "Q", 0x0F: "R", 0x01: "S", 0x11: "T",
            0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X", 0x10: "Y",
            0x06: "Z",
            
            // Цифры
            0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x17: "5",
            0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9", 0x1D: "0",
            
            // Символы
            0x18: "=", 0x1B: "-", 0x21: "[", 0x1E: "]", 0x27: "'",
            0x29: ";", 0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2F: ".",
            0x32: "`",
            
            // Специальные
            0x24: "Return", 0x30: "Tab", 0x31: "Space",
            0x33: "Delete", 0x35: "Escape",
            
            // Модификаторы (для справки)
            0x37: "Cmd(L)", 0x38: "Shift(L)", 0x3A: "Opt(L)",
            0x3D: "Opt(R)", 0x3B: "Ctrl(L)", 0x3C: "Shift(R)",
            0x3E: "Ctrl(R)", 0x36: "Cmd(R)",
        ]
        
        return names[keyCode] ?? "Key(\(keyCode))"
    }
}

