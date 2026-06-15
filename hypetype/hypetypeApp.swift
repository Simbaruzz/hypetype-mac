//
//  hypetypeApp.swift
//  hypetype
//
//  Created by Ruslan Mamedov on 25.12.2025.
//

import SwiftUI
import ServiceManagement

@main
struct hypetypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var eventTapManager: EventTapManager?
    var settingsManager = SettingsManager.shared
    var editorWindow: NSWindow?
    weak var enabledMenuItem: NSMenuItem?  // ✅ Weak ссылка на пункт "Виртуализация"
    weak var launchAtLoginMenuItem: NSMenuItem?  // ✅ Weak ссылка на пункт "Запуск при старте"
    var windowObserver: NSObjectProtocol?  // ✅ Для удаления observer при закрытии окна
    var permissionCheckTimer: Timer?  // ✅ Таймер для проверки разрешений
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Скрываем иконку из Dock - работаем только в menu bar
        NSApp.setActivationPolicy(.accessory)
        
        // Создаем иконку в menu bar
        setupMenuBar()
        
        // ✅ Проверяем разрешения с системным промптом
        // Это автоматически добавит приложение в список и покажет системный диалог
        if !checkAccessibilityPermissions() {
            // Запускаем мониторинг разрешений
            startPermissionCheckTimer()
        } else {
            // Разрешение уже есть - запускаем Event Tap только если включено
            if settingsManager.isEnabled {
                startEventTap()
            }
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Загружаем иконку из Assets (после исправления warning)
            if let icon = NSImage(named: "MenuBarIcon") {
                print("✅ Иконка MenuBarIcon загружена")
                icon.size = NSSize(width: 18, height: 18)
                icon.isTemplate = true
                button.image = icon
            } else {
                // Fallback: текстовая иконка
                button.title = "⌥"
                print("ℹ️ Используется текстовая иконка '⌥'")
            }
        }
        
        let menu = NSMenu()
        
        // Виртуализация
        let enabledItem = NSMenuItem(
            title: "Виртуализация",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.state = settingsManager.isEnabled ? .on : .off
        menu.addItem(enabledItem)
        
        // ✅ Сохраняем ссылку для обновления галочки
        self.enabledMenuItem = enabledItem
        
        // Запуск при старте
        let launchAtLoginItem = NSMenuItem(
            title: "Запуск при старте",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        // ✅ Сохраняем ссылку для обновления галочки
        self.launchAtLoginMenuItem = launchAtLoginItem
        
        menu.addItem(NSMenuItem.separator())
        
        // Редактировать...
        menu.addItem(NSMenuItem(
            title: "Редактировать...",
            action: #selector(openKeyboardEditor),
            keyEquivalent: "e"
        ))
        
        // Открыть папку настроек
        menu.addItem(NSMenuItem(
            title: "Открыть папку настроек",
            action: #selector(openConfigFolder),
            keyEquivalent: ""
        ))
        
        menu.addItem(NSMenuItem.separator())
        
        // Про hypetype↗
        menu.addItem(NSMenuItem(
            title: "Про hypetype↗",
            action: #selector(openGitHub),
            keyEquivalent: ""
        ))
        
        // Выход
        menu.addItem(NSMenuItem(
            title: "Выход",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
        
        statusItem?.menu = menu
    }
    
    @objc func toggleEnabled() {
        settingsManager.isEnabled.toggle()
        
        print("🔄 Переключение: isEnabled = \(settingsManager.isEnabled)")
        
        // ✅ Обновляем состояние галочки через сохраненную ссылку
        enabledMenuItem?.state = settingsManager.isEnabled ? .on : .off
        print("✅ Галочка обновлена: \(settingsManager.isEnabled ? "ON" : "OFF")")
        
        if settingsManager.isEnabled {
            startEventTap()
        } else {
            eventTapManager?.stop()
        }
    }
    

    @objc func quit() {
        // Останавливаем таймер проверки разрешений
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
        
        NSApplication.shared.terminate(nil)
    }
    
    @objc func openGitHub() {
        if let url = URL(string: "https://github.com/Simbaruzz/hypetype") {
            NSWorkspace.shared.open(url)
        }
    }
    

    @objc func openConfigFolder() {
        // Открываем папку с config.json в Finder
        let configPath = MappingManager.shared.getConfigPath()
        let folderPath = (configPath as NSString).deletingLastPathComponent
        
        if let folderURL = URL(string: "file://\(folderPath)") {
            NSWorkspace.shared.open(folderURL)
        }
    }
    
    @objc func openKeyboardEditor() {
        // Если окно уже открыто - показываем его
        if let window = editorWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Создаём новое окно
        let editorView = KeyboardEditorView()
        let hostingController = NSHostingController(rootView: editorView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "hypetype"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 950, height: 530))
        window.center()
        
        // Сохраняем ссылку
        editorWindow = window
        
        // ✅ Сохраняем observer и удаляем его при закрытии окна
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.editorWindow = nil
            
            // Удаляем observer чтобы избежать утечки памяти
            if let observer = self?.windowObserver {
                NotificationCenter.default.removeObserver(observer)
                self?.windowObserver = nil
            }
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    

    func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func startPermissionCheckTimer() {
        // Отменяем предыдущий таймер если был
        permissionCheckTimer?.invalidate()
        
        print("⏳ Запущен мониторинг разрешений...")
        
        // Проверяем каждые 2 секунды
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // ✅ Проверяем БЕЗ промпта (чтобы не показывать системный диалог снова)
            if AXIsProcessTrusted() {
                print("✅ Разрешение получено!")
                timer.invalidate()
                self.permissionCheckTimer = nil
                
                // ✅ ВКЛЮЧАЕМ виртуализацию автоматически
                self.settingsManager.isEnabled = true
                self.enabledMenuItem?.state = .on
                print("✅ Галочка включена автоматически")
                
                // Запускаем Event Tap
                self.startEventTap()
                
                // Показываем уведомление
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Всё чикаго!"
                    alert.informativeText = "Виртуализация включена ^_^\nСмело печатайте символы в стиле hypetype!"
                    alert.alertStyle = .informational
                    alert.runModal()
                }
            }
        }
    }
    
    func startEventTap() {
        guard settingsManager.isEnabled else {
            print("ℹ️ startEventTap: isEnabled = false, пропускаем")
            return
        }
        
        print("🚀 startEventTap: запуск Event Tap...")
        
        if eventTapManager == nil {
            eventTapManager = EventTapManager()
            print("✅ EventTapManager создан")
        }
        
        eventTapManager?.start()
    }
    
    // MARK: - Launch at Login
    
    @objc func toggleLaunchAtLogin() {
        let currentState = isLaunchAtLoginEnabled()
        
        if #available(macOS 13.0, *) {
            do {
                if currentState {
                    // Выключаем
                    try SMAppService.mainApp.unregister()
                    print("✅ Автозапуск выключен")
                } else {
                    // Включаем
                    try SMAppService.mainApp.register()
                    print("✅ Автозапуск включен")
                }
                
                // ✅ Обновляем галочку через сохраненную ссылку
                let newState = isLaunchAtLoginEnabled()
                launchAtLoginMenuItem?.state = newState ? .on : .off
                print("✅ Галочка автозапуска обновлена: \(newState ? "ON" : "OFF")")
                
            } catch {
                print("❌ Ошибка автозапуска: \(error)")
                
                // Показываем алерт с ошибкой
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Ошибка автозапуска"
                    alert.informativeText = "Не удалось изменить настройки автозапуска: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        } else {
            // Для macOS < 13.0
            let alert = NSAlert()
            alert.messageText = "Требуется macOS 13+"
            alert.informativeText = "Автозапуск поддерживается только на macOS 13 Ventura и новее"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    // MARK: - Menu Bar Icon
    
    func createMenuBarIcon() -> NSImage? {
        // Попытка 1: Из Assets через NSImage(named:)
        let possibleNames = ["MenuBarIcon", "icon", "Icon", "AppIcon"]
        
        for name in possibleNames {
            if let icon = NSImage(named: name) {
                print("✅ Иконка найдена в Assets: \(name)")
                icon.size = NSSize(width: 18, height: 18)
                icon.isTemplate = true
                return icon
            }
        }
        
        // Попытка 2: Загрузить PDF из Bundle (если добавлено как Resource)
        if let path = Bundle.main.path(forResource: "icon", ofType: "pdf"),
           let icon = NSImage(contentsOfFile: path) {
            print("✅ PDF иконка загружена из Bundle")
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = true
            return icon
        }
        
        print("⚠️ Иконка не найдена в Assets или Bundle, используем текстовую иконку '⌥'")
        
        // Fallback: текстовая иконка (это тоже OK!)
        return createSimpleTextIcon()
    }
    
    func createSimpleTextIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Рисуем текст "⌥" как иконку
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        
        let text = "⌥" as NSString
        let textSize = text.size(withAttributes: attributes)
        let rect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: rect, withAttributes: attributes)
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("HypeType для macOS")
                .font(.title)
            
            Text("Версия 1.0 • 40+ символов")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Примеры комбинаций:")
                    .font(.headline)
                
                Group {
                    Text("⌥ , → «  ⌥ . → »  (кавычки)")
                    Text("⌥ - → —  ⌥⇧ - → –  (тире)")
                    Text("⌥ E → €  ⌥ H → ₽  (валюты)")
                    Text("⌥ 1 → ¹  ⌥ 2 → ²  (индексы)")
                    Text("⌥ X → ×  ⌥ A → ≈  (математика)")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            Text("💡 Прямой ввод символов — быстро и не трогает буфер обмена")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(30)
        .frame(width: 450, height: 400)
    }
}

