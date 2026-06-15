//
//  EventTapManager.swift
//  hypetype
//
//  Перехват клавиатурных событий и вставка символов
//

import Cocoa
import Carbon

class EventTapManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var symbolInserter: SymbolInserter!
    
    // Состояние клавиш-модификаторов
    private var rightOptionPressed = false
    private var shiftPressed = false
    
    // Маппинги символов (загружаются из файла)
    private var mappings: [Int: (normal: String, shift: String)] = [:]
    
    // ✨ Режим диакритики
    private var isDiacriticMode = false
    private var waitingDiacritic = ""
    private var diacriticTimer: DispatchWorkItem?
    private var diacriticIndicator: DiacriticIndicatorWindow?
    
    // 🔍 DEBUG: Логирование
    private var debugLoggingEnabled = false  // Включи для отладки
    
    init() {
        // Создаём symbolInserter с ссылкой на self для сброса флагов
        self.symbolInserter = SymbolInserter(eventTapManager: self)
        
        // Подписываемся на изменения маппингов
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
    
    /// Проверяет, является ли символ комбинированной диакритикой (U+0300..U+036F)
    private func isCombiningDiacritic(_ symbol: String) -> Bool {
        guard let scalar = symbol.unicodeScalars.first else { return false }
        let value = scalar.value
        return value >= 0x0300 && value <= 0x036F
    }
    
    /// Нормализует строку в форму NFC (склейка базового символа + диакритика)
    private func normalizeString(_ str: String) -> String {
        return str.precomposedStringWithCanonicalMapping
    }
    
    /// Запускает режим ожидания буквы для диакритики
    private func startDiacriticMode(with diacritic: String) {
        isDiacriticMode = true
        waitingDiacritic = diacritic
        
        print("✨ Режим диакритики: \(diacritic) — жду ввода буквы...")
        
        // ✅ Закрываем предыдущий индикатор если есть (избегаем накопления окон)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Закрываем старое окно
            self.diacriticIndicator?.hide()
            
            // Создаём новое
            self.diacriticIndicator = DiacriticIndicatorWindow(diacritic: diacritic)
            self.diacriticIndicator?.show()
        }
        
        // Отменяем предыдущий таймер, если был
        diacriticTimer?.cancel()
        
        // Создаём таймаут на 5 секунд
        let timer = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            print("⏱️ Таймаут диакритики (5 секунд прошло)")
            self.cancelDiacriticMode()
        }
        diacriticTimer = timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timer)
    }
    
    /// Отменяет режим диакритики
    private func cancelDiacriticMode() {
        isDiacriticMode = false
        waitingDiacritic = ""
        diacriticTimer?.cancel()
        diacriticTimer = nil
        
        // ✅ Скрываем HUD-индикатор
        DispatchQueue.main.async { [weak self] in
            self?.diacriticIndicator?.hide()
            self?.diacriticIndicator = nil
        }
        
        print("❌ Режим диакритики отменён")
    }
    
    /// Применяет диакритику к введённой букве
    private func applyDiacritic(to baseChar: String) {
        guard !waitingDiacritic.isEmpty else {
            print("⚠️ applyDiacritic: waitingDiacritic пуст!")
            return
        }
        
        // Склеиваем: базовый символ + диакритика
        let combined = baseChar + waitingDiacritic
        let normalized = normalizeString(combined)
        
        print("🔤 \(baseChar) + \(waitingDiacritic) → \(normalized)")
        
        // Вставляем результат
        symbolInserter.insertSymbol(normalized)
        
        // Выходим из режима диакритики
        cancelDiacriticMode()
    }
    
    @objc private func mappingsDidChange() {
        reloadMappings()
    }
    
    func start() {
        // Загружаем маппинги из файла
        mappings = MappingManager.shared.loadMappings()
        
        // Создаем Event Tap для перехвата клавиатуры
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,  // Изменено: перехватываем на уровне HID (раньше всех)
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("❌ Ошибка: не удалось создать Event Tap")
            print("💡 Приложение добавлено в список Универсального доступа")
            print("💡 Откройте Системные настройки и включите тумблер для hypetype")
            
            // НЕ показываем алерт здесь - он показывается в AppDelegate
            return
        }
        
        // Добавляем в Run Loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("✅ Event Tap запущен")
        print("🎯 Маппинги загружены: \(mappings.count) символов")
    }
    
    func stop() {
        guard let eventTap = eventTap else { return }
        
        CGEvent.tapEnable(tap: eventTap, enable: false)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        print("⏹️ Event Tap остановлен")
    }
    
    // Перезагрузка маппингов из файла
    func reloadMappings() {
        mappings = MappingManager.shared.loadMappings()
        print("🔄 Маппинги перезагружены: \(mappings.count) символов")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // ВАЖНО: Игнорируем все события пока вставляем символ (защита от зацикливания)
        if symbolInserter.isInserting {
            return Unmanaged.passRetained(event)
        }
        
        // Обработка отключения Event Tap
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                print("⚠️ Event Tap переактивирован")
            }
            return Unmanaged.passRetained(event)
        }
        
        // Отслеживание состояния модификаторов
        if type == .flagsChanged {
            let flags = event.flags
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            
            // Right Option = keyCode 0x3D (61), Left Option = 0x3A (58)
            if keyCode == 0x3D {
                // Правый Option нажат/отпущен
                let wasPressed = rightOptionPressed
                rightOptionPressed = flags.contains(.maskAlternate)
                
                // 🔧 ВАЖНО: Логируем изменения для отладки
                if wasPressed != rightOptionPressed {
                    print("🔵 Right Option (flagsChanged): \(wasPressed ? "нажат" : "отпущен") → \(rightOptionPressed ? "нажат" : "отпущен")")
                }
            } else if keyCode == 0x3A {
                // Левый Option нажат/отпущен — НЕ трогаем rightOptionPressed!
                // Он остаётся false
            }
            
            // Shift
            shiftPressed = flags.contains(.maskShift)
            
            return Unmanaged.passRetained(event)
        }
        
        // Обработка KeyUp - блокируем для наших маппингов
        if type == .keyUp {
            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            
            // Блокируем KeyUp для наших маппингов если Right Option нажат
            // (используем флаг из flagsChanged)
            if rightOptionPressed && mappings[keyCode] != nil {
                return nil
            }
            return Unmanaged.passRetained(event)
        }
        
        // Обработка нажатий клавиш (KeyDown)
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        // Проверяем активность
        guard SettingsManager.shared.isEnabled else {
            return Unmanaged.passRetained(event)
        }
        
        // 🔧 ЗАЩИТА ОТ ЗАЛИПАНИЯ: Проверяем что наш флаг rightOptionPressed актуален
        // ВАЖНО: В keyDown мы НЕ МОЖЕМ различить Left/Right Option через CGEventFlags!
        // Поэтому доверяем flagsChanged для установки флага, но проверяем актуальность
        let eventFlags = event.flags
        let eventHasAnyOption = eventFlags.contains(.maskAlternate)
        let currentShift = eventFlags.contains(.maskShift)
        
        // Если событие говорит что НЕТ Option вообще, а наш флаг true — сбрасываем
        if !eventHasAnyOption && rightOptionPressed {
            print("🔧 Right Option АВТО-СБРОС: событие без Option, но флаг true")
            rightOptionPressed = false
        }
        
        shiftPressed = currentShift
        
        // Проверяем наш флаг (установленный через flagsChanged с различением Left/Right)
        guard rightOptionPressed else {
            // ✨ Если в режиме диакритики — применяем к обычной букве
            if isDiacriticMode {
                // Получаем введённый символ через keyCode
                if let char = getCharacterFromKeyCode(keyCode, shift: currentShift) {
                    applyDiacritic(to: char)
                    return nil  // Блокируем оригинальное событие
                } else {
                    // Не смогли получить символ — отменяем режим
                    print("⚠️ keyCode=\(keyCode) не найден в маппинге")
                    cancelDiacriticMode()
                }
            }
            return Unmanaged.passRetained(event)
        }
        
        // Ищем маппинг
        if let mapping = mappings[keyCode] {
            // ЗАЩИТА ОТ АВТОПОВТОРА используя встроенный флаг CGEvent
            let autoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if autoRepeat {
                print("🚫 Автоповтор заблокирован: keyCode=\(keyCode)")
                return nil  // Блокируем автоповтор
            }
            
            let symbol = currentShift ? mapping.shift : mapping.normal
            
            // ✨ Проверяем: это диакритика?
            if isCombiningDiacritic(symbol) {
                startDiacriticMode(with: symbol)
                return nil  // Блокируем оригинальное событие
            }
            
            // ✨ Если мы в режиме диакритики — применяем к введённому символу
            if isDiacriticMode {
                applyDiacritic(to: symbol)
                return nil  // Блокируем оригинальное событие
            }
            
            // Обычная вставка символа
            print("⌨️ R⌥ + keyCode(\(keyCode)) → \(symbol)")
            symbolInserter.insertSymbol(symbol)
            
            // Блокируем оригинальное событие
            return nil
        }
        
        // Если маппинг не найден, пропускаем событие
        return Unmanaged.passRetained(event)
    }
    
    // MARK: - Helpers
    
    /// Получает символ из keyCode с учётом ТЕКУЩЕЙ раскладки клавиатуры
    private func getCharacterFromKeyCode(_ keyCode: Int, shift: Bool) -> String? {
        // Получаем текущую раскладку клавиатуры
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            print("⚠️ Не удалось получить текущую раскладку")
            return nil
        }
        
        // Получаем layout data
        guard let layoutDataPtr = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            print("⚠️ Не удалось получить layout data")
            return nil
        }
        
        let layoutData = unsafeBitCast(layoutDataPtr, to: CFData.self)
        let layout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)
        
        // Модификаторы: Shift или ничего
        let modifierKeyState: UInt32 = shift ? UInt32(shiftKey >> 8) : 0
        
        // Буфер для результата
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
        
        guard status == noErr, length > 0 else {
            return nil
        }
        
        return String(utf16CodeUnits: chars, count: length)
    }
    
    // MARK: - Debug Logging
    
    /// Переключение отладочных логов
    func toggleDebugLogging() {
        debugLoggingEnabled.toggle()
        print("🔍 Отладочные логи \(debugLoggingEnabled ? "ВКЛЮЧЕНЫ" : "ВЫКЛЮЧЕНЫ")")
    }
    
    /// Проверка состояния логов
    var isDebugLoggingEnabled: Bool {
        return debugLoggingEnabled
    }
}

// MARK: - Symbol Inserter

class SymbolInserter {
    // Флаг для предотвращения зацикливания
    private(set) var isInserting = false
    
    // Слабая ссылка на EventTapManager для сброса флагов
    private weak var eventTapManager: EventTapManager?
    
    init(eventTapManager: EventTapManager) {
        self.eventTapManager = eventTapManager
    }
    
    func insertSymbol(_ symbol: String) {
        // Пустые символы пропускаем
        if symbol.isEmpty {
            return
        }
        
        // Устанавливаем флаг
        isInserting = true
        
        // Всегда используем прямой метод (он сам решит нужен ли clipboard)
        insertDirect(symbol)
        
        // Снимаем флаг с небольшой задержкой (одинаковой для всех символов)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.isInserting = false
        }
    }
    
    // ВСПОМОГАТЕЛЬНЫЙ МЕТОД: Вставка через буфер обмена
    // Используется ТОЛЬКО для пробелов (direct метод с ними не дружит)
    // Восстанавливает буфер с УМНОЙ задержкой чтобы не мешать повторным вставкам
    private func insertViaClipboard(_ symbol: String) {
        let pasteboard = NSPasteboard.general
        
        // Сохраняем текущее содержимое
        let savedContent = pasteboard.string(forType: .string)
        let savedChangeCount = pasteboard.changeCount
        
        // Копируем наш символ
        pasteboard.clearContents()
        pasteboard.setString(symbol, forType: .string)
        
        // ✅ ФИКС: HTML-формат для ProseMirror-редакторов (Habr и т.п.)
        // Без этого whitespace-символы нормализуются и пропадают
        let html = "<span>\(symbol)</span>"
        pasteboard.setString(html, forType: .html)
        
        // Симулируем Cmd+V
        simulateCommandV()
        
        print("📋 Вставлено через CLIPBOARD метод: \(symbol)")
        
        // Восстанавливаем буфер с задержкой
        // ВАЖНО: Даём время на Cmd+V И проверяем что буфер не изменился
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Проверяем что буфер не изменился (пользователь не скопировал что-то ещё)
            // И что это наш символ в буфере (changeCount увеличился ровно на 1)
            if pasteboard.changeCount == savedChangeCount + 1,
               pasteboard.string(forType: .string) == symbol {
                // Всё ок, восстанавливаем
                if let saved = savedContent {
                    pasteboard.clearContents()
                    pasteboard.setString(saved, forType: .string)
                } else {
                    // Если буфер был пустой, очищаем его
                    pasteboard.clearContents()
                }
            }
            // Иначе - пользователь что-то скопировал или вставил ещё раз, не трогаем
        }
    }
    
    // ОСНОВНОЙ МЕТОД ВСТАВКИ
    // 🧪 ЭКСПЕРИМЕНТ: Попробуем ВСЕГДА использовать прямой метод (даже для эмодзи)
    // Это должно решить проблему с залипанием Right Option!
    private func insertDirect(_ symbol: String) {
        // Пробелы - через clipboard (прямой метод с ними не дружит)
        if symbol.trimmingCharacters(in: .whitespaces).isEmpty && symbol.count > 0 {
            insertViaClipboard(symbol)
            return
        }
        
        // 🧪 ВСЁ ОСТАЛЬНОЕ (включая эмодзи!) - прямой ввод через Unicode events
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Создаём KeyDown событие
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else {
            return
        }
        
        let unicodeChars = Array(symbol.utf16)
        keyDownEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: unicodeChars)
        keyDownEvent.post(tap: .cghidEventTap)
        
        // Небольшая задержка между Down и Up
        usleep(1000) // 1ms
        
        // Создаём KeyUp событие
        guard let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return
        }
        
        keyUpEvent.keyboardSetUnicodeString(stringLength: unicodeChars.count, unicodeString: unicodeChars)
        keyUpEvent.post(tap: .cghidEventTap)
        
        print("🎯 Вставлено через DIRECT метод: \(symbol)")
    }
    
    private func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Cmd Down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
        
        // V Down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        
        usleep(10000) // 10ms задержка
        
        // V Up - 🔧 ФИКС: Добавляем флаг Command при отпускании
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand  // ← Важно! Сохраняем контекст модификатора
        vUp?.post(tap: .cghidEventTap)
        
        usleep(1000) // 1ms между V Up и Cmd Up
        
        // Cmd Up - 🔧 ФИКС: Явно отпускаем Command
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.flags = []  // ← Важно! Пустые флаги = все модификаторы отпущены
        cmdUp?.post(tap: .cghidEventTap)
    }
}
// MARK: - Diacritic Indicator Window

/// Простой HUD-индикатор для диакритики (не крадёт фокус!)
class DiacriticIndicatorWindow {
    private var panel: NSPanel?
    private let diacritic: String
    
    init(diacritic: String) {
        self.diacritic = diacritic
    }
    
    func show() {
        // Получаем позицию курсора мыши (приблизительно где каретка)
        let mouseLocation = NSEvent.mouseLocation
        
        // Создаём текст
        let displayText = "  \(diacritic)  "  // Добавляем отступы
        
        // Создаём label
        let label = NSTextField(labelWithString: displayText)
        label.font = .systemFont(ofSize: 24, weight: .regular)  // Крупнее для видимости
        label.textColor = .labelColor
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        
        // Размеры
        let labelSize = label.fittingSize
        let windowSize = NSSize(width: labelSize.width + 20, height: labelSize.height + 16)
        
        // Позиция: рядом с курсором, чуть правее и выше
        let windowOrigin = NSPoint(
            x: mouseLocation.x + 20,
            y: mouseLocation.y + 40
        )
        
        let windowRect = NSRect(origin: windowOrigin, size: windowSize)
        
        // ✅ Используем NSPanel вместо NSWindow — он НЕ КРАДЁТ фокус!
        let panel = NSPanel(
            contentRect: windowRect,
            styleMask: [.borderless, .nonactivatingPanel],  // nonactivatingPanel — ключевое!
            backing: .buffered,
            defer: false
        )
        
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar  // Высокий уровень
        panel.ignoresMouseEvents = true
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        
        // Контейнер с фоном
        let containerView = NSView(frame: NSRect(origin: .zero, size: windowSize))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        containerView.layer?.cornerRadius = 8
        
        // Label по центру
        label.frame = NSRect(
            x: (windowSize.width - labelSize.width) / 2,
            y: (windowSize.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        containerView.addSubview(label)
        
        panel.contentView = containerView
        panel.orderFrontRegardless()
        
        self.panel = panel
    }
    
    func hide() {
        guard let panel = panel else { return }
        
        panel.orderOut(nil)
        panel.close()
        
        self.panel = nil
    }
}

