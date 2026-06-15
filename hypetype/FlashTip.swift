//
//  FlashTip.swift
//  hypetype
//
//  Короткий HUD-тултип у курсора (не крадёт фокус), авто-исчезает.
//  Используется обработчиком типографа: «Выделите текст» / «Типографировано ✓» и т.п.
//

import Cocoa

final class FlashTip {
    private static var current: NSPanel?

    static func show(_ message: String, duration: TimeInterval = 1.2) {
        current?.orderOut(nil)
        current = nil

        let label = NSTextField(labelWithString: "  \(message)  ")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        let textSize = label.fittingSize
        let winSize = NSSize(width: textSize.width + 16, height: textSize.height + 12)

        let mouse = NSEvent.mouseLocation
        let rect = NSRect(x: mouse.x + 16, y: mouse.y + 24, width: winSize.width, height: winSize.height)

        let panel = NSPanel(contentRect: rect,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hasShadow = true
        panel.hidesOnDeactivate = false

        let container = NSView(frame: NSRect(origin: .zero, size: winSize))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        container.layer?.cornerRadius = 8
        label.frame = NSRect(x: (winSize.width - textSize.width) / 2,
                             y: (winSize.height - textSize.height) / 2,
                             width: textSize.width, height: textSize.height)
        container.addSubview(label)
        panel.contentView = container
        panel.orderFrontRegardless()
        current = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak panel] in
            panel?.orderOut(nil)
            if current === panel { current = nil }
        }
    }
}
