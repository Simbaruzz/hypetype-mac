# 🚀 Roadmap: От MVP к полной версии

После успешного MVP можно приступать к полноценной разработке.

---

## ✅ Что уже работает (MVP)

- ✅ Перехват правого Option
- ✅ 5 тестовых символов
- ✅ Два метода вставки (clipboard/direct)
- ✅ Menu bar интеграция
- ✅ Базовые настройки
- ✅ Логирование

---

## 🎯 Этап 2: Расширенные маппинги (1-2 часа)

### Цель
Добавить полный набор символов как в оригинальном HypeType.

### Что делать

1. **Расширить testMappings в EventTapManager.swift:**

```swift
private let testMappings: [Int: (normal: String, shift: String)] = [
    // Кавычки
    0x21: ("«", "„"),  // [
    0x1E: ("»", """),  // ]
    
    // Тире
    0x1B: ("–", "—"),  // -
    
    // Математика
    0x18: ("≈", "≠"),  // =
    0x2C: ("÷", "⁄"),  // /
    0x19: ("×", "·"),  // 9
    
    // Валюты
    0x02: ("$", "€"),  // D
    0x0F: ("₽", "£"),  // R
    
    // Пунктуация
    0x2F: ("…", "•"),  // .
    0x2B: ("·", "‚"),  // ,
    
    // Специальные
    0x2E: ("™", "®"),  // M
    0x23: ("§", "¶"),  // P
    
    // ... добавьте остальные по аналогии
]
```

2. **Используйте KeyCodes.swift как справочник**

3. **Тестируйте каждую группу символов**

---

## 🎯 Этап 3: Configuration.json (2-3 часа)

### Цель
Загрузка маппингов из файла вместо хардкода.

### Что делать

1. **Создать файл Configuration.swift:**
   - Структуры `KeyMapping` и `Configuration`
   - Методы `load()` и `save()`
   - Кодирование в JSON

2. **Изменить EventTapManager:**
   ```swift
   init(configuration: Configuration) {
       self.configuration = configuration
       // Построить кэш маппингов
   }
   ```

3. **Создать default_config.json:**
   - Стандартная раскладка
   - Автоматическая генерация при первом запуске

4. **Путь к конфигу:**
   ```
   ~/Library/Application Support/HypeType/config.json
   ```

5. **Добавить в menu bar:**
   - "Перезагрузить конфигурацию"
   - "Открыть папку конфигурации"

---

## 🎯 Этап 4: GUI Редактор (4-6 часов)

### Цель
Визуальный редактор раскладки как в файлах из документации.

### Что делать

1. **Создать ConfigEditorView.swift:**
   - Список всех маппингов
   - Поиск по символам/клавишам
   - Редактирование существующих

2. **Создать EditMappingView.swift:**
   - Форма редактирования
   - Выбор символа из библиотеки
   - Предпросмотр

3. **Создать SymbolPickerView.swift:**
   - Категории символов (кавычки, тире, математика и т.д.)
   - Grid с символами
   - Быстрый поиск

4. **Добавить в menu bar:**
   ```swift
   menu.addItem(NSMenuItem(
       title: "Редактор раскладки",
       action: #selector(openEditor),
       keyEquivalent: "e"
   ))
   ```

5. **Горячая клавиша для редактора:**
   - ⌘E или ⌘⇧E

---

## 🎯 Этап 5: Диакритика (3-4 часа)

### Цель
Режим ожидания для комбинирования символов с диакритическими знаками.

### Как работает

1. Пользователь нажимает Right Option + V → активируется гачек ◌̌
2. Появляется индикатор ожидания (5 секунд)
3. Пользователь нажимает букву, например 'g'
4. Вставляется 'ǧ' (g с гачеком)

### Что делать

1. **Создать DiacriticMode.swift:**
   ```swift
   class DiacriticMode {
       var isWaiting: Bool
       var diacriticSymbol: String
       var timer: Timer?
       
       func startWaiting(with: String)
       func applyToCharacter(_ char: String) -> String?
       func cancel()
   }
   ```

2. **Интегрировать в EventTapManager:**
   - Проверять isDiacriticSymbol()
   - Если да → запускать режим ожидания
   - Если уже ждем → применять к следующей букве

3. **Визуальный индикатор:**
   - Изменить иконку в menu bar
   - Или небольшое HUD окно
   - Или системное уведомление

4. **Диакритические символы:**
   ```swift
   0x09: ("\u{030C}", "\u{0302}"),  // V: гачек, циркумфлекс
   0x00: ("\u{0301}", "\u{0300}"),  // A: акут, граве
   0x0E: ("\u{0308}", "\u{0303}"),  // E: умляут, тильда
   ```

---

## 🎯 Этап 6: Автозагрузка (1-2 часа)

### Цель
Запуск HypeType при входе в систему.

### Что делать

1. **Использовать SMAppService (macOS 13+):**
   ```swift
   @objc func toggleLaunchAtLogin() {
       if launchAtLogin {
           try? SMAppService.mainApp.register()
       } else {
           try? SMAppService.mainApp.unregister()
       }
   }
   ```

2. **Добавить в menu bar:**
   ```swift
   let launchItem = NSMenuItem(
       title: "Запуск при входе",
       action: #selector(toggleLaunchAtLogin),
       keyEquivalent: ""
   )
   launchItem.state = isRegistered ? .on : .off
   ```

3. **Сохранить настройку:**
   - В UserDefaults или в config.json

---

## 🎯 Этап 7: Полировка (2-3 часа)

### UX улучшения

1. **Звуковые эффекты** (опционально)
   - Клик при вставке символа
   - Настройка вкл/выкл

2. **Статистика использования**
   - Какие символы используются чаще
   - Показывать в GUI редакторе

3. **Импорт/экспорт конфигурации**
   - Поделиться раскладкой с другими
   - Резервное копирование

4. **Проверка обновлений**
   - GitHub Releases
   - Уведомление о новой версии

5. **О программе**
   - Версия, автор, ссылка на GitHub
   - Благодарности

---

## 🎯 Этап 8: Тестирование (1-2 дня)

### Что тестировать

1. **Различные приложения:**
   - TextEdit, Notes, Mail
   - Figma, Sketch
   - Adobe (Photoshop, Illustrator, InDesign)
   - VS Code, Sublime Text
   - Браузеры (Safari, Chrome, Firefox)
   - Мессенджеры (Telegram, Slack)

2. **Крайние случаи:**
   - Очень быстрая печать
   - Одновременное нажатие нескольких модификаторов
   - Переключение между приложениями во время набора
   - Сон/пробуждение Mac
   - Подключение/отключение внешней клавиатуры

3. **Производительность:**
   - Задержка вставки символов
   - Использование CPU/памяти
   - Конфликты с другими утилитами

---

## 🎯 Этап 9: Распространение (2-3 часа)

### Если не через App Store

1. **Code Signing:**
   - Нужен Apple Developer Account ($99/год)
   - Или использовать ad-hoc signing

2. **Notarization:**
   ```bash
   # Подписать
   codesign --deep --force --sign "Developer ID" HypeType.app
   
   # Создать DMG
   hdiutil create -volname HypeType -srcfolder HypeType.app HypeType.dmg
   
   # Нотаризировать
   xcrun notarytool submit HypeType.dmg --keychain-profile "AC_PASSWORD" --wait
   
   # Прикрепить билет
   xcrun stapler staple HypeType.dmg
   ```

3. **Создать DMG installer:**
   - Красивое фоновое изображение
   - Ярлык на /Applications
   - Инструкции

4. **GitHub Release:**
   - README.md с описанием
   - Скриншоты
   - Инструкции по установке
   - Changelog

---

## 📊 Приоритеты

Рекомендуемая последовательность:

1. **Высокий приоритет:**
   - Этап 2: Расширенные маппинги
   - Этап 3: Configuration.json
   - Этап 4: GUI Редактор

2. **Средний приоритет:**
   - Этап 5: Диакритика
   - Этап 6: Автозагрузка
   - Этап 8: Тестирование

3. **Низкий приоритет:**
   - Этап 7: Полировка
   - Этап 9: Распространение

---

## 🎓 Обучение по ходу

Полезные темы для изучения:

1. **SwiftUI:**
   - Lists, Forms, Navigation
   - @State, @Binding, @ObservedObject
   - Sheets, Alerts, Popovers

2. **Codable:**
   - JSON encoding/decoding
   - Custom CodingKeys
   - Nested structures

3. **macOS APIs:**
   - NSMenu, NSStatusItem
   - NSOpenPanel, NSSavePanel
   - UserDefaults, FileManager

4. **Event Handling:**
   - CGEvent глубже
   - Флаги модификаторов
   - Unicode композиция

---

## 💡 Идеи для будущего

- Touch Bar поддержка
- iCloud синхронизация конфигов
- Профили раскладок (работа, программирование, дизайн)
- Shortcuts.app интеграция
- Плагины для популярных редакторов
- Spotlight плагин для поиска символов
- Widget для быстрого доступа

---

## 📝 Заметки

После каждого этапа:
1. ✅ Тестируйте изменения
2. ✅ Коммитьте в Git
3. ✅ Обновляйте README.md
4. ✅ Обсуждайте спорные моменты

**Не пытайтесь сделать всё сразу!**
Лучше работающий MVP чем незаконченная полная версия.

---

**Удачи в разработке! 🚀**
