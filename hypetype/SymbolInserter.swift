//
//  SymbolInserter.swift
//  hypetype
//
//  Вставка Unicode-символов: прямой ввод через CGEvent + clipboard-путь для пробелов.
//

import Cocoa
import OSLog

private let log = Logger(subsystem: "hypetype", category: "SymbolInserter")

class SymbolInserter {
    private(set) var isInserting = false

    private weak var eventTapManager: EventTapManager?

    /// Один переиспользуемый источник событий вместо создания на каждый символ
    /// (иначе память подрастает на каждое нажатие).
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    init(eventTapManager: EventTapManager) {
        self.eventTapManager = eventTapManager
    }

    func insertSymbol(_ symbol: String) {
        if symbol.isEmpty { return }

        isInserting = true
        insertDirect(symbol)

        // Задержка load-bearing: гонка с системной обработкой синтетических CGEvent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.isInserting = false
        }
    }

    // MARK: - Private

    private func insertDirect(_ symbol: String) {
        // Пробельные символы — только через clipboard (CGEvent их нормализует)
        if symbol.trimmingCharacters(in: .whitespaces).isEmpty {
            insertViaClipboard(symbol)
            return
        }

        guard let keyDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: true) else { return }
        let utf16 = Array(symbol.utf16)
        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        // Снимаем модификаторы с синтетического события. Источник .hidSystemState
        // захватывает реально зажатые R⌥/⇧, и без обнуления агрессивные приложения
        // (VS Code/Electron) читают вброс как аккорд ⌥⇧+клавиша и запускают свой хоткей
        // вместо вставки символа. С пустыми флагами это чистый ввод текста.
        keyDown.flags = []
        keyDown.post(tap: .cghidEventTap)

        usleep(1000) // 1 ms — гонка CGEvent Down/Up

        guard let keyUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0, keyDown: false) else { return }
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.flags = []
        keyUp.post(tap: .cghidEventTap)
    }

    private func insertViaClipboard(_ symbol: String) {
        let pasteboard = NSPasteboard.general
        let savedItems = pasteboard.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
        let savedChangeCount = pasteboard.changeCount

        // Запись с маркерами «не пиши в историю» — Spotlight Clipboard History (Tahoe)
        // и сторонние менеджеры (по конвенции nspasteboard.org) её пропускают.
        // HTML-обёртка остаётся — нужна для ProseMirror-редакторов (иначе whitespace
        // нормализуется).
        PasteboardPrivacy.writePrivateWithHTML(symbol, to: pasteboard)

        simulateCommandV()

        // Восстанавливаем буфер после вставки
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard pasteboard.changeCount == savedChangeCount + 1,
                  pasteboard.string(forType: .string) == symbol else { return }
            // С маркерами — иначе восстановление картинки/файла даёт дубль в
            // Spotlight Clipboard History (см. PasteboardPrivacy.restorePrivate).
            PasteboardPrivacy.restorePrivate(savedItems, to: pasteboard)
        }
    }

    private func simulateCommandV() {
        let cmdDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)

        let vDown = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)

        usleep(10000) // 10 ms

        let vUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        vUp?.post(tap: .cghidEventTap)

        usleep(1000) // 1 ms

        let cmdUp = CGEvent(keyboardEventSource: eventSource, virtualKey: 0x37, keyDown: false)
        cmdUp?.flags = []
        cmdUp?.post(tap: .cghidEventTap)
    }
}
