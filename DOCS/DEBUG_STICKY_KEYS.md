# 🐛 Отладка залипания клавиш

## Что было исправлено?

### Проблема #1: Пропуск `flagsChanged` во время вставки
**Было:**
```swift
if symbolInserter.isInserting {
    return Unmanaged.passRetained(event)  // ❌ Пропускали ВСЁ, включая flagsChanged
}
```

**Стало:**
```swift
// ✅ Обрабатываем flagsChanged ВСЕГДА, даже во время вставки
if type == .flagsChanged {
    // Обновляем rightOptionPressed
    // ...
}

// Только ПОТОМ проверяем isInserting для KeyDown/KeyUp
if symbolInserter.isInserting {
    return Unmanaged.passRetained(event)
}
```

### Проблема #2: Десинхронизация флагов
**Добавлено:**
```swift
// Принудительная синхронизация при каждом keyDown
let actualRightOptionPressed = eventFlags.contains(.maskAlternate)
if actualRightOptionPressed != rightOptionPressed {
    print("⚠️ ДЕСИНХРОНИЗАЦИЯ! Синхронизируем принудительно!")
    rightOptionPressed = actualRightOptionPressed
}
```

---

## Как использовать логгер?

### 1. Включить/выключить логи

В `EventTapManager.swift` найди:
```swift
private var debugLoggingEnabled = true  // ← Измени на false чтобы выключить
```

### 2. Читать логи в Console.app

1. Открой **Console.app** (⌘+Space → Console)
2. Фильтр: введи `hypetype` в поле поиска
3. Нажми клавиши и смотри логи в реальном времени

### 3. Формат логов

```
⌨️ KeyDown | keyCode=3D (R⌥) | flags=⌥ | [R⌥=ON]  | map=  
🔵 Right Option НАЖАТ (было: false, стало: true, прошло: 0.000с)
⌨️ KeyDown | keyCode=04 (H)  | flags=⌥ | [R⌥=ON]  | map=✅
⌨️ KeyUp   | keyCode=04 (H)  | flags=⌥ | [R⌥=ON]  | map=✅
🔵 Right Option ОТПУЩЕН (было: true, стало: false, прошло: 0.123с)
```

**Расшифровка:**
- `⌨️ KeyDown` — нажатие клавиши
- `⌨️ KeyUp` — отпускание клавиши
- `🏳️ Flags` — изменение модификаторов
- `🔵 Right Option НАЖАТ/ОТПУЩЕН` — состояние правого Option
- `[R⌥=ON]` — текущее состояние флага `rightOptionPressed`
- `map=✅` — клавиша есть в маппинге
- `map=  ` — клавиши нет в маппинге

### 4. Что искать при залипании?

#### Признаки залипания:

```
🔵 Right Option НАЖАТ (было: false, стало: true, прошло: 0.000с)
⌨️ KeyDown | keyCode=04 (H)  | flags=⌥ | [R⌥=ON]  | map=✅
// ... вставка символа ...
🔵 Right Option ОТПУЩЕН (было: true, стало: false, прошло: 0.050с) [во время вставки!]  ← ⚠️
⌨️ KeyDown | keyCode=00 (A)  | flags=— | [R⌥=ON]  | map=✅  ← ❌ Залипание!
```

**Обрати внимание:**
- `flags=—` (нет модификаторов)
- НО `[R⌥=ON]` (флаг всё ещё true)
- `map=✅` (клавиша срабатывает как будто ⌥ нажат)

#### Исправление десинхронизации:

```
⌨️ KeyDown | keyCode=00 (A)  | flags=— | [R⌥=ON]  | map=✅
⚠️ ДЕСИНХРОНИЗАЦИЯ! rightOptionPressed=true, но в событии=false
   → Синхронизируем принудительно!
⌨️ KeyDown | keyCode=00 (A)  | flags=— | [R⌥=off] | map=  ← ✅ Исправлено!
```

---

## Экстренный сброс состояния

Если клавиши всё ещё залипли:

### Способ 1: Через меню
1. Кликни на иконку `⌥` в menu bar
2. Выбери **"🔄 Сбросить состояние"** (⌘R)
3. Нажми OK в диалоге

### Способ 2: Программно
```swift
// В любом месте кода
eventTapManager?.resetState()
```

### Способ 3: Перезапуск виртуализации
1. Кликни на иконку в menu bar
2. Сними галочку **"Виртуализация"**
3. Поставь галочку обратно

---

## Отчёт о баге

Если залипание всё ещё происходит, **сделай скриншот логов** из Console.app:

### Что включить в отчёт:

1. **Логи за 2-3 секунды до залипания**
   - Видно последовательность событий
   - Видно где произошёл пропуск

2. **Точная последовательность действий:**
   ```
   1. Нажал Right Option
   2. Быстро нажал H (3 раза подряд)
   3. Отпустил Right Option
   4. Нажал A — вставился символ ≈ вместо A
   ```

3. **Скриншот из Console.app** с фильтром по `hypetype`

4. **Версия macOS:**
   ```
   About This Mac → macOS Ventura 13.5.2
   ```

---

## Дополнительные логи

### Логирование вставки символов

В `SymbolInserter.insertSymbol()` уже есть:
```swift
print("📋 Вставка символа: \(symbol) (метод: \(needsClipboard(symbol) ? "clipboard" : "direct"))")
```

### Логирование диакритики

```swift
print("✨ Режим диакритики: \(diacritic) — жду ввода буквы...")
print("🔤 \(baseChar) + \(waitingDiacritic) → \(normalized)")
print("❌ Режим диакритики отменён")
```

---

## Частые ошибки

### ❌ Залипание при быстрой печати
**Причина:** Пропущено событие `flagsChanged` во время `isInserting = true`  
**Исправление:** ✅ Обрабатываем `flagsChanged` ДО проверки `isInserting`

### ❌ Десинхронизация после Cmd+Tab
**Причина:** Система отправляет события модификаторов в другое приложение  
**Исправление:** ✅ Принудительная синхронизация из `event.flags` при каждом `keyDown`

### ❌ Залипание после Spotlight/Alfred
**Причина:** Другие Event Tap приложения блокируют события  
**Исправление:** ✅ Используй "Сбросить состояние" через меню

---

## Следующие шаги

Если баг всё ещё воспроизводится:

1. **Собери логи** (см. выше)
2. **Попробуй разные сценарии:**
   - Медленная печать (работает?)
   - Быстрая печать (залипает?)
   - С Alfred/Spotlight (залипает?)
   - После переключения приложений Cmd+Tab (залипает?)

3. **Проверь конфликты:**
   - Открой Activity Monitor
   - Найди процессы с "keyboard" или "event tap"
   - Возможно другое приложение конфликтует

4. **Создай issue на GitHub** со всеми логами и деталями

---

## Контакты

GitHub: https://github.com/Simbaruzz/hypetype  
Issues: https://github.com/Simbaruzz/hypetype/issues

---

**Удачной отладки! 🐛→🦋**
