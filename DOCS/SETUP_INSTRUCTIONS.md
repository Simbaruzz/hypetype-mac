# 🚀 Настройка проекта HypeType MVP

## ✅ Что уже сделано

Созданы файлы:
- ✅ hypetypeApp.swift (заменен)
- ✅ EventTapManager.swift (создан)
- ✅ SettingsManager.swift (создан)
- ✅ Info.plist (создан)

## 📋 Что нужно сделать в Xcode

### Шаг 1: Удалить ненужные файлы

В Xcode найдите и удалите:
- ❌ ContentView.swift (если есть)
- ❌ Папки с тестами (hypetypeTests, hypetypeUITests) - можно оставить, но не обязательно

### Шаг 2: Настроить Info.plist

1. В Xcode выберите проект (синяя иконка "hypetype" вверху слева)
2. Выберите Target "hypetype"
3. Перейдите на вкладку **Info**
4. Найдите или добавьте следующие ключи:

**Вариант A - через GUI:**
```
Application is agent (UIElement): YES
Privacy - Accessibility Usage Description: HypeType требует разрешение для перехвата клавиш
Privacy - AppleEvents Sending Usage Description: HypeType нужен доступ для управления событиями
```

**Вариант B - через исходный код Info.plist (проще):**
- Найдите Info.plist в Project Navigator
- Правый клик → Open As → Source Code
- Скопируйте содержимое из файла Info.plist который я создал
- Сохраните

### Шаг 3: Настроить Signing & Capabilities

1. Выберите проект → Target "hypetype" → вкладка **Signing & Capabilities**

2. Настройте подписание:
   - ✅ Automatically manage signing
   - Team: выберите свою команду (или None для локальной сборки)
   - Bundle Identifier: должен быть уникальным (например `com.yourname.hypetype`)

3. Добавьте **Hardened Runtime**:
   - Нажмите **+ Capability** вверху
   - Найдите "Hardened Runtime"
   - Добавьте
   - В опциях Hardened Runtime включите:
     - ✅ Disable Library Validation
     - ✅ Allow Execution of JIT-compiled Code (опционально)

### Шаг 4: Проверить настройки сборки

1. Project → Target "hypetype" → вкладка **General**
2. Minimum Deployments: **macOS 13.0** или выше

### Шаг 5: Первая сборка

1. В Xcode выберите схему: **hypetype > My Mac**
2. Нажмите **Product → Build** (⌘B)
3. Исправьте любые ошибки, если появятся

### Шаг 6: Запуск

1. Нажмите кнопку **Play** (▶) или **Product → Run** (⌘R)
2. При первом запуске система попросит разрешение Accessibility:
   - Откройте **Системные настройки**
   - **Конфиденциальность и безопасность**
   - **Универсальный доступ**
   - Найдите "hypetype" и включите галочку
3. Перезапустите приложение

## 🧪 Тестирование

После запуска:

1. Вы должны увидеть иконку клавиатуры в menu bar (правый верхний угол)
2. Откройте TextEdit или любой текстовый редактор
3. Попробуйте комбинации:
   - **Right Option + [** → «
   - **Right Option + ]** → »
   - **Right Option + -** → –
   - **Right Option + Shift + -** → —
   - **Right Option + .** → …

## 🐛 Решение проблем

### Проблема: "Cannot find 'SettingsManager' in scope"
**Решение:** Убедитесь что файл SettingsManager.swift добавлен в Target:
- Выберите файл в Project Navigator
- File Inspector (правая панель) → Target Membership → ✅ hypetype

### Проблема: Event Tap не работает
**Решение:**
1. Проверьте разрешения Accessibility
2. В Terminal выполните: `tccutil reset Accessibility com.yourname.hypetype`
3. Перезапустите приложение

### Проблема: Иконка не появляется в menu bar
**Решение:** Проверьте что LSUIElement = true в Info.plist

### Проблема: Компиляция не проходит
**Решение:**
1. Product → Clean Build Folder (⌘⇧K)
2. Перезапустите Xcode
3. Проверьте что все файлы имеют Target Membership = hypetype

## 📊 Проверка работы через Console

Откройте Console.app и фильтруйте по "hypetype" - вы увидите логи:
- ✅ Event Tap запущен
- 🔵 Right Option нажат/отпущен
- ⌨️ Перехвачено: keyCode=...
- 📋 Вставлено через clipboard: ...

## 🎯 Что дальше

После успешного MVP можно добавить:
1. ✨ GUI редактор раскладки
2. 💾 Загрузка config.json
3. 🎨 Диакритика
4. 🚀 Автозагрузка
5. 📦 Более богатый набор символов

---

**Готово!** После выполнения всех шагов у вас будет рабочий MVP HypeType! 🎉
'/Users/vishnya/Library/Containers/hypetype.hypetype/Data/Library/Application Support/hypetype'
