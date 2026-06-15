# 🎨 Руководство по диакритике в hypetype

## Что такое комбинированная диакритика?

Комбинированная диакритика — это специальные Unicode-символы из диапазона U+0300..U+036F, которые "прилипают" к предыдущему символу, изменяя его внешний вид.

Например:
- `e` + `̈` (U+0308) = `ë` (умлаут)
- `n` + `̃` (U+0303) = `ñ` (тильда)
- `a` + `́` (U+0301) = `á` (acute accent)

## Как это работает в hypetype?

### Режим ожидания диакритики

1. **Нажимаете комбинацию с диакритикой** (например, `ROption+Shift+;` для умлаута ̈)
2. **Появляется индикатор** с текстом "̈ Введите букву..."
3. **Вводите любую букву** (например, `o`)
4. **Получаете склеенный символ** (`ö`)

### Таймаут

Если в течение **5 секунд** не ввести букву — режим диакритики отменяется автоматически.

## Примеры диакритики в маппинге

Вот какие диакритики уже настроены по умолчанию:

| Комбинация | Диакритика | Название | Пример |
|-----------|------------|----------|--------|
| `ROption+Shift+Q` | ̆ (U+0306) | Breve | ă, ĕ, ğ |
| `ROption+Shift+H` | ̋ (U+030B) | Double Acute | ő, ű |
| `ROption+Shift+;` | ̈ (U+0308) | Umlaut/Diaeresis | ö, ü, ë |
| `ROption+Shift+Z` | ̧ (U+0327) | Cedilla | ç, ş, ţ |
| `ROption+Shift+V` | ̌ (U+030C) | Caron | č, š, ž |
| `ROption+Shift+N` | ̃ (U+0303) | Tilde | ñ, ã, õ |
| `ROption+Shift+/` | ́ (U+0301) | Acute Accent | á, é, í |

## Технические детали

### Нормализация Unicode

hypetype использует **NFC (Canonical Composition)** — склеивает базовый символ и диакритику в единый Unicode-символ, если такой существует.

Например:
- `e` + ̈ → `ë` (U+00EB, единый символ)
- Если готового символа нет → остаются два отдельных (базовый + диакритика)

### Код Swift

```swift
// Проверка диакритики
private func isCombiningDiacritic(_ symbol: String) -> Bool {
    guard let scalar = symbol.unicodeScalars.first else { return false }
    return scalar.value >= 0x0300 && scalar.value <= 0x036F
}

// Нормализация (склейка)
private func normalizeString(_ str: String) -> String {
    return str.precomposedStringWithCanonicalMapping
}
```

## Добавление своих диакритик

Откройте **config.json** и добавьте нужные символы в `shift` поле:

```json
{
  "keyCode": 41,
  "normal": "'",
  "shift": "\u0308",  // Умлаут
  "comment": ";"
}
```

### Полный список диакритики

- U+0300 — ̀ Grave
- U+0301 — ́ Acute
- U+0302 — ̂ Circumflex
- U+0303 — ̃ Tilde
- U+0304 — ̄ Macron
- U+0306 — ̆ Breve
- U+0307 — ̇ Dot Above
- U+0308 — ̈ Diaeresis/Umlaut
- U+0309 — ̉ Hook Above
- U+030A — ̊ Ring Above
- U+030B — ̋ Double Acute
- U+030C — ̌ Caron
- U+030F — ̏ Double Grave
- U+0311 — ̑ Inverted Breve
- U+0323 — ̣ Dot Below
- U+0327 — ̧ Cedilla
- U+0328 — ̨ Ogonek

[Полный список на Unicode.org](https://en.wikipedia.org/wiki/Combining_Diacritical_Marks)

## Преимущества

✅ **Работает с любыми буквами** — не нужно заранее определять все комбинации  
✅ **Поддержка всех языков** — автоматическая склейка через Unicode NFC  
✅ **Визуальный индикатор** — видно когда ждёт ввода буквы  
✅ **Таймаут** — не застрянете в режиме ожидания  

## Сравнение с AHK

| Функция | AHK | hypetype |
|---------|-----|----------|
| Проверка диапазона | `code >= 0x0300 && code <= 0x036F` | `scalar.value >= 0x0300 && scalar.value <= 0x036F` |
| Нормализация | `Normaliz.dll` + WinAPI | `precomposedStringWithCanonicalMapping` |
| Индикатор | `ToolTip` | Кастомное NSWindow |
| Таймаут | `Input, L1 I T5` | `DispatchWorkItem` + 5 сек |
| Ввод следующей буквы | `BlockInput` + `Input` | CGEvent перехват |

---

**Приятного использования! 🎨**
