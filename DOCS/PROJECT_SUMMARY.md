# 📦 HypeType MVP - Список файлов

## ✅ Созданные файлы

### Основные файлы проекта

1. **hypetypeApp.swift** (ИЗМЕНЕН)
   - Главный файл приложения
   - AppDelegate с menu bar
   - SettingsView
   - Управление разрешениями

2. **EventTapManager.swift** (СОЗДАН)
   - Перехват клавиатурных событий
   - Определение правого Option (keyCode 0x3D)
   - SymbolInserter с двумя методами
   - Жестко закодированные тестовые маппинги

3. **SettingsManager.swift** (СОЗДАН)
   - ObservableObject для настроек
   - Сохранение в UserDefaults
   - isEnabled и useClipboardMethod

4. **Info.plist** (СОЗДАН)
   - LSUIElement = true (menu bar app)
   - Описания разрешений Accessibility

### Документация

5. **README.md**
   - Описание MVP
   - Тестовые символы
   - Критерии успеха

6. **SETUP_INSTRUCTIONS.md**
   - Пошаговая настройка в Xcode
   - Настройка Signing & Capabilities
   - Инструкции по тестированию

7. **TROUBLESHOOTING.md**
   - Решение типичных проблем
   - Отладка через Console.app
   - Проблемы в конкретных приложениях

8. **.gitignore**
   - Стандартный .gitignore для Xcode проектов

---

## 🎯 Тестовые маппинги (жестко закодированы)

```swift
0x21: ("«", "„"),  // [ key
0x1E: ("»", """),  // ] key
0x1B: ("–", "—"),  // - key
0x2F: ("…", "•"),  // . key
```

---

## 🚀 Следующие шаги

### Шаг 1: Откройте проект в Xcode
```bash
open /Users/vishnya/Desktop/hypetype/hypetype.xcodeproj
```

### Шаг 2: Проверьте что все файлы на месте

В Project Navigator слева должны быть:
- hypetypeApp.swift
- EventTapManager.swift
- SettingsManager.swift
- Info.plist

**Если каких-то файлов нет:**

1. Файлы созданы в папке проекта, но Xcode их не видит
2. Нужно добавить их вручную:
   - Правый клик на папку "hypetype" в Project Navigator
   - **Add Files to "hypetype"...**
   - Выберите недостающие файлы
   - Убедитесь что галочка "Copy items if needed" стоит
   - Выберите Target "hypetype"

### Шаг 3: Следуйте SETUP_INSTRUCTIONS.md

Откройте файл **SETUP_INSTRUCTIONS.md** и выполните все шаги:
1. Удалите ContentView.swift
2. Настройте Info.plist
3. Настройте Signing & Capabilities
4. Соберите проект (⌘B)
5. Запустите (⌘R)

---

## 🎨 Архитектура MVP

```
┌─────────────────────────────┐
│     hypetypeApp.swift       │
│                             │
│  ┌─────────────────────┐   │
│  │   AppDelegate        │   │
│  │   - Menu Bar         │   │
│  │   - Permissions      │   │
│  └──────┬──────────────┘   │
│         │                   │
└─────────┼───────────────────┘
          │
    ┌─────┴──────┐
    │            │
┌───▼──────┐ ┌──▼─────────────┐
│ Settings │ │ EventTapManager│
│ Manager  │ │                │
│          │ │ - Right Option │
│ - Enable │ │ - Mappings     │
│ - Method │ │ - Insert       │
└──────────┘ └────────────────┘
```

---

## 🧪 План тестирования

### Этап 1: Базовая проверка
- [ ] Проект собирается без ошибок
- [ ] Приложение запускается
- [ ] Иконка появляется в menu bar
- [ ] Можно открыть Settings (⌘,)

### Этап 2: Разрешения
- [ ] При первом запуске появляется диалог Accessibility
- [ ] После разрешения Event Tap запускается
- [ ] В Console видно "✅ Event Tap запущен"

### Этап 3: Детекция Right Option
- [ ] При нажатии правого Option в Console: "🔵 Right Option нажат"
- [ ] При нажатии левого Option - ничего не происходит

### Этап 4: Вставка символов (TextEdit)
- [ ] Right Option + [ → «
- [ ] Right Option + ] → »
- [ ] Right Option + - → –
- [ ] Right Option + Shift + - → —
- [ ] Right Option + . → …

### Этап 5: Figma
- [ ] Создать текстовый блок
- [ ] Проверить все 5 комбинаций
- [ ] Переключить метод вставки если не работает

### Этап 6: Adobe
- [ ] Photoshop: текстовый слой
- [ ] Illustrator: текстовый объект
- [ ] Проверить все комбинации

---

## ✅ Критерии успеха MVP

Проект считается успешным если:

1. ✅ **Right Option детектится** отдельно от левого
2. ✅ **Символы вставляются** в TextEdit
3. ✅ **Работает в Figma** (хотя бы одним методом)
4. ✅ **Работает в Adobe** (хотя бы одним методом)
5. ✅ **Left Option свободен** для других задач

Если все 5 пунктов ✅ - концепция жизнеспособна! 🎉

Можно переходить к полной версии с GUI редактором, config.json, диакритикой и т.д.

---

## 📝 Заметки

### Про определение правого Option

Используется отслеживание через `flagsChanged` события:
- Right Option имеет keyCode **0x3D (61)**
- Left Option имеет keyCode **0x3A (58)**

Это надежный способ различать клавиши!

### Про методы вставки

**Clipboard метод (по умолчанию):**
- Работает практически везде
- Сохраняет оригинальный буфер и восстанавливает через 150ms
- Может быть проблема если пользователь очень быстро жмет Cmd+C

**Direct метод:**
- Не трогает буфер обмена
- Использует CGEvent.keyboardSetUnicodeString
- Может не работать в некоторых приложениях (особенно Electron-based)

---

Удачи с тестированием! 🚀
