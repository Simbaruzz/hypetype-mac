//
//  DiacriticIndicatorWindow.swift
//  hypetype
//
//  HUD-индикатор режима диакритики (NSPanel — не крадёт фокус).
//

import Cocoa

class DiacriticIndicatorWindow {
    private var panel: NSPanel?
    private let diacritic: String

    init(diacritic: String) {
        self.diacritic = diacritic
    }

    func show() {
        let mouseLocation = NSEvent.mouseLocation
        let displayText = "  \(diacritic)  "

        let label = NSTextField(labelWithString: displayText)
        label.font = .systemFont(ofSize: 24, weight: .regular)
        label.textColor = .labelColor
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false

        let labelSize = label.fittingSize
        let windowSize = NSSize(width: labelSize.width + 20, height: labelSize.height + 16)
        let windowRect = NSRect(
            origin: NSPoint(x: mouseLocation.x + 20, y: mouseLocation.y + 40),
            size: windowSize
        )

        // nonactivatingPanel — ключевое: не крадёт фокус у целевого приложения
        let panel = NSPanel(
            contentRect: windowRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false

        let container = NSView(frame: NSRect(origin: .zero, size: windowSize))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        container.layer?.cornerRadius = 8

        label.frame = NSRect(
            x: (windowSize.width - labelSize.width) / 2,
            y: (windowSize.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        container.addSubview(label)

        panel.contentView = container
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }
}
