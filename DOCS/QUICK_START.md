# ⚡ Quick Start - 5 минут до запуска

Минимальная инструкция для быстрого старта.

---

## 1️⃣ Откройте проект (10 сек)

```bash
cd /Users/vishnya/Desktop/hypetype
open hypetype.xcodeproj
```

---

## 2️⃣ Удалите ContentView.swift (5 сек)

В Project Navigator:
- Найдите `ContentView.swift`
- Delete → Move to Trash

---

## 3️⃣ Настройте Info.plist (30 сек)

1. Кликните на **Info.plist**
2. Правый клик → **Open As** → **Source Code**
3. Замените всё содержимое на:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>LSUIElement</key>
	<true/>
	<key>NSAppleEventsUsageDescription</key>
	<string>HypeType нужен доступ для управления событиями клавиатуры.</string>
	<key>NSAccessibilityUsageDescription</key>
	<string>HypeType требует разрешение для перехвата клавиш.</string>
</dict>
</plist>
```

4. Сохраните (⌘S)

---

## 4️⃣ Добавьте Hardened Runtime (20 сек)

1. Выберите проект (синяя иконка hypetype)
2. Target "hypetype" → вкладка **Signing & Capabilities**
3. Нажмите **+ Capability**
4. Найдите **Hardened Runtime**
5. Включите: **Disable Library Validation**

---

## 5️⃣ Соберите (10 сек)

```
⌘B (или Product → Build)
```

---

## 6️⃣ Запустите (5 сек)

```
⌘R (или нажмите ▶)
```

---

## 7️⃣ Дайте разрешения (60 сек)

1. Появится диалог → **Открыть настройки**
2. **Системные настройки** → **Конфиденциальность** → **Универсальный доступ**
3. Включите ✅ для **Xcode** или **hypetype**
4. Вернитесь в Xcode
5. Остановите (⏹️) и запустите заново (▶)

---

## 8️⃣ Проверьте menu bar (5 сек)

- Иконка клавиатуры появилась в правом верхнем углу? ✅
- Нет? → Смотрите TROUBLESHOOTING.md

---

## 9️⃣ Тест в TextEdit (30 сек)

Откройте TextEdit и попробуйте:

- **Right Option + [** → должно быть **«**
- **Right Option + ]** → должно быть **»**
- **Right Option + -** → должно быть **–**

Работает? 🎉 **MVP успешен!**

Не работает? → Откройте **Console.app**, найдите логи "hypetype", смотрите TROUBLESHOOTING.md

---

## 🔟 Тест в Figma (30 сек)

1. Откройте Figma
2. Создайте текст (T)
3. Попробуйте те же комбинации

Работает? 🎉 **Концепция жизнеспособна!**

---

## ⏱️ Итого: ~5 минут

Если всё получилось - поздравляю! Теперь можно развивать проект дальше.

Подробные инструкции:
- **CHECKLIST.md** - пошаговый чеклист
- **SETUP_INSTRUCTIONS.md** - детальная настройка
- **TROUBLESHOOTING.md** - решение проблем

---

**Удачи! ⚡**
