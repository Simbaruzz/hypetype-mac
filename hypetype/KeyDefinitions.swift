//
//  KeyDefinitions.swift
//  hypetype
//
//  Single source of truth for all 48 mapped keys (§5 FORMAT.md).
//  Replaces: getDefaultMappings, getKeyComment, KeyCodeMapper, hardcoded editor rows.
//

import Foundation

nonisolated struct KeyDef {
    let w3cName: String        // W3C UI Events code (canonical key in config.ini)
    let macKeyCode: Int        // macOS CGEvent key code
    let displayLabel: String   // label shown on keyboard button
    let defaultNormal: String  // default symbol — Right Option
    let defaultShift: String   // default symbol — Right Option + Shift
}

nonisolated enum KeyDefinitions {
    // All 48 keys in row order matching §5 FORMAT.md table.
    // Rows: [0..<12] digit, [12..<24] QWERTY, [24..<36] ASDF, [36..<48] ZXCV+Space+Backquote
    static let all: [KeyDef] = [
        // Digit row
        KeyDef(w3cName: "Digit1",       macKeyCode: 0x12, displayLabel: "1",   defaultNormal: "\u{00B9}", defaultShift: "\u{00A1}"),
        KeyDef(w3cName: "Digit2",       macKeyCode: 0x13, displayLabel: "2",   defaultNormal: "\u{00B2}", defaultShift: "\u{00BD}"),
        KeyDef(w3cName: "Digit3",       macKeyCode: 0x14, displayLabel: "3",   defaultNormal: "\u{00B3}", defaultShift: "\u{2153}"),
        KeyDef(w3cName: "Digit4",       macKeyCode: 0x15, displayLabel: "4",   defaultNormal: "\u{0024}", defaultShift: "\u{00BC}"),
        KeyDef(w3cName: "Digit5",       macKeyCode: 0x17, displayLabel: "5",   defaultNormal: "\u{2030}", defaultShift: "\u{0020}"),
        KeyDef(w3cName: "Digit6",       macKeyCode: 0x16, displayLabel: "6",   defaultNormal: "\u{2191}", defaultShift: "\u{0302}"),
        KeyDef(w3cName: "Digit7",       macKeyCode: 0x1A, displayLabel: "7",   defaultNormal: "\u{2197}", defaultShift: "\u{00BF}"),
        KeyDef(w3cName: "Digit8",       macKeyCode: 0x1C, displayLabel: "8",   defaultNormal: "\u{221E}", defaultShift: "\u{0020}"),
        KeyDef(w3cName: "Digit9",       macKeyCode: 0x19, displayLabel: "9",   defaultNormal: "\u{2190}", defaultShift: "\u{2039}"),
        KeyDef(w3cName: "Digit0",       macKeyCode: 0x1D, displayLabel: "0",   defaultNormal: "\u{2192}", defaultShift: "\u{203A}"),
        KeyDef(w3cName: "Minus",        macKeyCode: 0x1B, displayLabel: "-",   defaultNormal: "\u{2014}", defaultShift: "\u{2013}"),
        KeyDef(w3cName: "Equal",        macKeyCode: 0x18, displayLabel: "=",   defaultNormal: "\u{2260}", defaultShift: "\u{00B1}"),
        // QWERTY row
        KeyDef(w3cName: "KeyQ",         macKeyCode: 0x0C, displayLabel: "Q",   defaultNormal: "\u{0020}", defaultShift: "\u{0306}"),
        KeyDef(w3cName: "KeyW",         macKeyCode: 0x0D, displayLabel: "W",   defaultNormal: "\u{2713}", defaultShift: "\u{2303}"),
        KeyDef(w3cName: "KeyE",         macKeyCode: 0x0E, displayLabel: "E",   defaultNormal: "\u{20AC}", defaultShift: "\u{2325}"),
        KeyDef(w3cName: "KeyR",         macKeyCode: 0x0F, displayLabel: "R",   defaultNormal: "\u{00AE}", defaultShift: "\u{030A}"),
        KeyDef(w3cName: "KeyT",         macKeyCode: 0x11, displayLabel: "T",   defaultNormal: "\u{2122}", defaultShift: ""),
        KeyDef(w3cName: "KeyY",         macKeyCode: 0x10, displayLabel: "Y",   defaultNormal: "\u{0463}", defaultShift: "\u{0462}"),
        KeyDef(w3cName: "KeyU",         macKeyCode: 0x20, displayLabel: "U",   defaultNormal: "\u{0475}", defaultShift: "\u{0474}"),
        KeyDef(w3cName: "KeyI",         macKeyCode: 0x22, displayLabel: "I",   defaultNormal: "\u{0456}", defaultShift: "\u{0406}"),
        KeyDef(w3cName: "KeyO",         macKeyCode: 0x1F, displayLabel: "O",   defaultNormal: "\u{0473}", defaultShift: "\u{0472}"),
        KeyDef(w3cName: "KeyP",         macKeyCode: 0x23, displayLabel: "P",   defaultNormal: "\u{2032}", defaultShift: "\u{2033}"),
        KeyDef(w3cName: "BracketLeft",  macKeyCode: 0x21, displayLabel: "[",   defaultNormal: "\u{005B}", defaultShift: "\u{007B}"),
        KeyDef(w3cName: "BracketRight", macKeyCode: 0x1E, displayLabel: "]",   defaultNormal: "\u{005D}", defaultShift: "\u{007D}"),
        // ASDF row
        KeyDef(w3cName: "KeyA",         macKeyCode: 0x00, displayLabel: "A",   defaultNormal: "\u{2248}", defaultShift: "\u{2318}"),
        KeyDef(w3cName: "KeyS",         macKeyCode: 0x01, displayLabel: "S",   defaultNormal: "\u{00A7}", defaultShift: "\u{21E7}"),
        KeyDef(w3cName: "KeyD",         macKeyCode: 0x02, displayLabel: "D",   defaultNormal: "\u{00B0}", defaultShift: "\u{2300}"),
        KeyDef(w3cName: "KeyF",         macKeyCode: 0x03, displayLabel: "F",   defaultNormal: "\u{00A3}", defaultShift: "\u{0020}"),
        KeyDef(w3cName: "KeyG",         macKeyCode: 0x05, displayLabel: "G",   defaultNormal: "\u{F8FF}", defaultShift: "\u{229E}"),
        KeyDef(w3cName: "KeyH",         macKeyCode: 0x04, displayLabel: "H",   defaultNormal: "\u{20BD}", defaultShift: "\u{030B}"),
        KeyDef(w3cName: "KeyJ",         macKeyCode: 0x26, displayLabel: "J",   defaultNormal: "\u{201E}", defaultShift: "\u{0020}"),
        KeyDef(w3cName: "KeyK",         macKeyCode: 0x28, displayLabel: "K",   defaultNormal: "\u{201C}", defaultShift: "\u{2019}"),
        KeyDef(w3cName: "KeyL",         macKeyCode: 0x25, displayLabel: "L",   defaultNormal: "\u{201D}", defaultShift: "\u{2018}"),
        KeyDef(w3cName: "Semicolon",    macKeyCode: 0x29, displayLabel: ";",   defaultNormal: "\u{2019}", defaultShift: "\u{0308}"),
        KeyDef(w3cName: "Quote",        macKeyCode: 0x27, displayLabel: "'",   defaultNormal: "\u{2018}", defaultShift: "\u{0020}"),
        KeyDef(w3cName: "Backslash",    macKeyCode: 0x2A, displayLabel: "\\",  defaultNormal: "\u{007C}", defaultShift: "\u{005C}"),
        // ZXCV row + Space + Backquote
        KeyDef(w3cName: "KeyZ",         macKeyCode: 0x06, displayLabel: "Z",   defaultNormal: "\u{0020}", defaultShift: "\u{0327}"),
        KeyDef(w3cName: "KeyX",         macKeyCode: 0x07, displayLabel: "X",   defaultNormal: "\u{00D7}", defaultShift: "\u{00B7}"),
        KeyDef(w3cName: "KeyC",         macKeyCode: 0x08, displayLabel: "C",   defaultNormal: "\u{00A9}", defaultShift: "\u{00A2}"),
        KeyDef(w3cName: "KeyV",         macKeyCode: 0x09, displayLabel: "V",   defaultNormal: "\u{2193}", defaultShift: "\u{030C}"),
        KeyDef(w3cName: "KeyB",         macKeyCode: 0x0B, displayLabel: "B",   defaultNormal: "\u{00DF}", defaultShift: "\u{1E9E}"),
        KeyDef(w3cName: "KeyN",         macKeyCode: 0x2D, displayLabel: "N",   defaultNormal: "\u{2116}", defaultShift: "\u{0303}"),
        KeyDef(w3cName: "KeyM",         macKeyCode: 0x2E, displayLabel: "M",   defaultNormal: "\u{2212}", defaultShift: "\u{2022}"),
        KeyDef(w3cName: "Comma",        macKeyCode: 0x2B, displayLabel: ",",   defaultNormal: "\u{00AB}", defaultShift: "\u{201E}"),
        KeyDef(w3cName: "Period",       macKeyCode: 0x2F, displayLabel: ".",   defaultNormal: "\u{00BB}", defaultShift: "\u{201C}"),
        KeyDef(w3cName: "Slash",        macKeyCode: 0x2C, displayLabel: "/",   defaultNormal: "\u{2026}", defaultShift: "\u{0301}"),
        KeyDef(w3cName: "Space",        macKeyCode: 0x31, displayLabel: "␣",   defaultNormal: "\u{00A0}", defaultShift: "\u{0020}"),
        KeyDef(w3cName: "Backquote",    macKeyCode: 0x32, displayLabel: "`",   defaultNormal: "\u{007E}", defaultShift: "\u{0300}"),
    ]

    // Lookup by macKeyCode
    static let byMacKeyCode: [Int: KeyDef] = Dictionary(uniqueKeysWithValues: all.map { ($0.macKeyCode, $0) })

    // Lookup by W3C name (canonical key in config.ini)
    static let byW3CName: [String: KeyDef] = Dictionary(uniqueKeysWithValues: all.map { ($0.w3cName, $0) })

    // Default layout: macKeyCode → (normal, shift)
    static var defaultLayout: [Int: (normal: String, shift: String)] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.macKeyCode, ($0.defaultNormal, $0.defaultShift)) })
    }

    // Keyboard rows for the editor (slices of `all` — indices match the table)
    static let numberRow: ArraySlice<KeyDef> = all[0..<12]
    static let qwertyRow: ArraySlice<KeyDef> = all[12..<24]
    static let asdfRow:   ArraySlice<KeyDef> = all[24..<36]
    static let zxcvRow:   ArraySlice<KeyDef> = all[36..<48]
}
