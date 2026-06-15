//
//  EventTapManager.swift
//  hypetype
//
//  Перехват клавиатурных событий через CGEventTap + маршрутизация в SymbolInserter/DiacriticController.
//

import Cocoa
import Carbon
import OSLog

private let log = Logger(subsystem: "hypetype", category: "EventTap")

class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var symbolInserter: SymbolInserter!

    private var rightOptionPressed = false
    private var shiftPressed = false
    private var mappings: [Int: (normal: String, shift: String)] = [:]

    // Диакритика
    private var isDiacriticMode = false
    private var waitingDiacritic = ""
    private var diacriticTimer: DispatchWorkItem?
    private var diacriticIndicator: DiacriticIndicatorWindow?

    init() {
        self.symbolInserter = SymbolInserter(eventTapManager: self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mappingsDidChange),
            name: .mappingsDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        diacriticTimer?.cancel()
    }

    // MARK: - Диакритика

    private func isCombiningDiacritic(_ symbol: String) -> Bool {
        guard let scalar = symbol.unicodeScalars.first else { return false }
        return scalar.value >= 0x0300 && scalar.value <= 0x036F
    }

    private func normalizeString(_ str: String) -> String {
        return str.precomposedStringWithCanonicalMapping
    }

    private func startDiacriticMode(with diacritic: String) {
        isDiacriticMode = true
        waitingDiacritic = diacritic
        log.debug("Diacritic mode: \(diacritic) — waiting for base char")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.diacriticIndicator?.hide()
            self.diacriticIndicator = DiacriticIndicatorWindow(diacritic: diacritic)
            self.diacriticIndicator?.show()
        }

        diacriticTimer?.cancel()
        let timer = DispatchWorkItem { [weak self] in
            log.debug("Diacritic timeout")
            self?.cancelDiacriticMode()
        }
        diacriticTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timer)
    }

    private func cancelDiacriticMode() {
        isDiacriticMode = false
        waitingDiacritic = ""
        diacriticTimer?.cancel()
        diacriticTimer = nil

        DispatchQueue.main.async { [weak self] in
            self?.diacriticIndicator?.hide()
            self?.diacriticIndicator = nil
        }
    }

    private func applyDiacritic(to baseChar: String) {
        guard !waitingDiacritic.isEmpty else { return }
        let normalized = normalizeString(baseChar + waitingDiacritic)
        log.debug("Diacritic: \(baseChar) + \(self.waitingDiacritic) → \(normalized)")
        symbolInserter.insertSymbol(normalized)
        cancelDiacriticMode()
    }

    @objc private func mappingsDidChange() {
        reloadMappings()
    }

    // MARK: - Lifecycle

    func start() {
        mappings = LayoutStore.shared.loadMappings()

        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (_, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let tap = eventTap else {
            log.error("Failed to create Event Tap — grant Accessibility permission in System Settings")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        log.info("Event Tap started, \(self.mappings.count) mappings loaded")
    }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), src, .commonModes)
        }
        log.info("Event Tap stopped")
    }

    func reloadMappings() {
        mappings = LayoutStore.shared.loadMappings()
        log.info("Mappings reloaded: \(self.mappings.count)")
    }

    // MARK: - Event handling

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if symbolInserter.isInserting { return Unmanaged.passRetained(event) }

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            log.warning("Event Tap re-enabled after system disable")
            return Unmanaged.passRetained(event)
        }

        if type == .flagsChanged {
            let flags = event.flags
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))

            // Различаем Left (0x3A) и Right Option (0x3D) только через flagsChanged keyCode
            if keyCode == 0x3D {
                let wasPressed = rightOptionPressed
                rightOptionPressed = flags.contains(.maskAlternate)
                if wasPressed != rightOptionPressed {
                    log.debug("Right Option: \(self.rightOptionPressed ? "down" : "up")")
                }
            }
            shiftPressed = flags.contains(.maskShift)
            return Unmanaged.passRetained(event)
        }

        if type == .keyUp {
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            if rightOptionPressed && mappings[keyCode] != nil { return nil }
            return Unmanaged.passRetained(event)
        }

        guard type == .keyDown else { return Unmanaged.passRetained(event) }

        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))

        guard SettingsManager.shared.isEnabled else { return Unmanaged.passRetained(event) }

        let eventFlags = event.flags
        let currentShift = eventFlags.contains(.maskShift)

        // Авто-сброс флага если система говорит что Option не зажат
        if !eventFlags.contains(.maskAlternate) && rightOptionPressed {
            log.debug("Right Option flag auto-reset")
            rightOptionPressed = false
        }
        shiftPressed = currentShift

        guard rightOptionPressed else {
            if isDiacriticMode {
                if let char = getCharacterFromKeyCode(keyCode, shift: currentShift) {
                    applyDiacritic(to: char)
                    return nil
                } else {
                    cancelDiacriticMode()
                }
            }
            return Unmanaged.passRetained(event)
        }

        if let mapping = mappings[keyCode] {
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return nil }

            let symbol = currentShift ? mapping.shift : mapping.normal

            if isCombiningDiacritic(symbol) {
                startDiacriticMode(with: symbol)
                return nil
            }

            if isDiacriticMode {
                applyDiacritic(to: symbol)
                return nil
            }

            log.debug("R⌥ keyCode(\(keyCode)) → \(symbol)")
            symbolInserter.insertSymbol(symbol)
            return nil
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - Helpers

    private func getCharacterFromKeyCode(_ keyCode: Int, shift: Bool) -> String? {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        guard let layoutDataPtr = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else { return nil }

        let layoutData = unsafeBitCast(layoutDataPtr, to: CFData.self)
        let layout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

        let modifierKeyState: UInt32 = shift ? UInt32(shiftKey >> 8) : 0
        var deadKeyState: UInt32 = 0
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)

        let status = UCKeyTranslate(
            layout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDown),
            modifierKeyState,
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysMask),
            &deadKeyState,
            chars.count,
            &length,
            &chars
        )

        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
    }
}
