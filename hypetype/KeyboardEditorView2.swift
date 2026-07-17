//
//  KeyboardEditorView2.swift
//  hypetype
//
//  ЭКСПЕРИМЕНТ (ветка hypetype-design). Новый редактор — реалистичная мак-клавиатура.
//  Шаг 1: статичная форма из KeyDefinitions (без интерактива). Живёт рядом со старым
//  KeyboardEditorView, ничего не заменяет. См. DESIGN_PLAN.md.
//
//  Сетка: квадраты + «резиновые» клавиши, добивающие ряд до общей ширины.
//  В SwiftUI: квадрат = фикс-ширина, резиновая = maxWidth .infinity.
//

import SwiftUI
import AppKit

// MARK: - Константы раскладки (масштаб экрана; пропорции как в макете 72:108)

private let kUnit: CGFloat = 58        // квадратная клавиша
private let kWide: CGFloat = 88        // «ТИПОГРАФ» / «Tab» (≈1.5×)
private let kGap: CGFloat = 6
private let kRadius: CGFloat = 10
private let kGlyphFont: CGFloat = 14   // единый размер меток на клавише (как в макете)

/// Ширина всего ряда — по верхнему ряду (13 квадратов + 1 широкая + зазоры).
private let kBoardWidth: CGFloat = 13 * kUnit + kWide + 13 * kGap

/// Фиолетовый акцент (примерно из макета; уточним по Figma).
private let kAccent = Color(red: 0.72, green: 0.45, blue: 1.0)
private let kBoard = Color(white: 0.05)
private let kCapMappable = Color(white: 0.13)
private let kCapDecor = Color(white: 0.09)
private let kBorder = Color(white: 0.22)

// MARK: - Модель клавиши

private enum KeyRole {
    case mappable(KeyDef)          // настраиваемая — показывает глифы
    case decor(String, DecorStyle) // декоративная — подпись, не кликается
    case arrows                    // кластер стрелок (перевёрнутая «Т»)
    case typograph                 // ТИПОГРАФ + ⌫ (физически — клавиша Backspace)
}

/// Стили декоративных клавиш.
private enum DecorStyle {
    case dim        // приглушённая (TAB, CAPS, модификаторы, стрелки)
    case emphasis   // акцентная (SHIFT — важная клавиша)
    case strong     // яркая (ТИПОГРАФ, ⓘ)
    case highlight  // выделенная белым (правый ⌥ — активатор)
}

private enum KeyWidth { case unit, wide, flex }

private struct DKey: Identifiable {
    let id = UUID()
    let role: KeyRole
    let width: KeyWidth
    var align: Alignment = .center   // прибитие подписи к углу (для декор-клавиш)
}

private func mk(_ w3c: String, _ width: KeyWidth = .unit) -> DKey {
    DKey(role: .mappable(KeyDefinitions.byW3CName[w3c]!), width: width)
}
private func dec(_ label: String, _ style: DecorStyle = .dim,
                 _ width: KeyWidth = .unit, _ align: Alignment = .center) -> DKey {
    DKey(role: .decor(label, style), width: width, align: align)
}

// углы для «прибития» подписей, как на настоящей клавиатуре
private let BL: Alignment = .bottomLeading
private let BR: Alignment = .bottomTrailing

// MARK: - Ряды (физическая мак-раскладка)

private let designRows: [[DKey]] = [
    // Верхний: ` 1..0 - =  + ТИПОГРАФ
    [mk("Backquote"), mk("Digit1"), mk("Digit2"), mk("Digit3"), mk("Digit4"),
     mk("Digit5"), mk("Digit6"), mk("Digit7"), mk("Digit8"), mk("Digit9"),
     mk("Digit0"), mk("Minus"), mk("Equal"), DKey(role: .typograph, width: .wide)],

    // QWERTY: Tab(⇥) + Q..] \
    [dec("⇥", .dim, .wide, BL), mk("KeyQ"), mk("KeyW"), mk("KeyE"), mk("KeyR"), mk("KeyT"),
     mk("KeyY"), mk("KeyU"), mk("KeyI"), mk("KeyO"), mk("KeyP"),
     mk("BracketLeft"), mk("BracketRight"), mk("Backslash")],

    // ASDF: Caps(⇪) + A..; ' + Enter(↩)
    [dec("⇪", .dim, .flex, BL), mk("KeyA"), mk("KeyS"), mk("KeyD"), mk("KeyF"), mk("KeyG"),
     mk("KeyH"), mk("KeyJ"), mk("KeyK"), mk("KeyL"), mk("Semicolon"),
     mk("Quote"), dec("↩", .dim, .flex, BR)],

    // ZXCV: SHIFT(словом, акцент) + Z../ + SHIFT
    [dec("SHIFT", .emphasis, .flex, BL), mk("KeyZ"), mk("KeyX"), mk("KeyC"), mk("KeyV"),
     mk("KeyB"), mk("KeyN"), mk("KeyM"), mk("Comma"), mk("Period"), mk("Slash"),
     dec("SHIFT", .emphasis, .flex, BR)],

    // Нижний: ⓘ ⌃ ⌥ ⌘ [Space] ⌘ ⌥(правый — подсвечен) + стрелки (каждая 72px)
    [dec("ⓘ", .strong, .unit, BL), dec("⌃", .dim, .unit, BL), dec("⌥", .dim, .unit, BL),
     dec("⌘", .dim, .unit, BL), mk("Space", .flex), dec("⌘", .dim, .unit, BR),
     dec("⌥", .highlight, .unit, BR),
     DKey(role: .arrows, width: .unit)],
]

// MARK: - Корневой вью

struct KeyboardEditorView2: View {
    /// Текущая раскладка пользователя (macKeyCode → symbols), живьём из config.ini.
    @State private var mappings: [Int: (normal: String, shift: String)] = LayoutStore.shared.loadMappings()
    /// Клавиша, которую сейчас редактируем (nil — попап закрыт).
    @State private var editingKey: KeyInfo?

    var body: some View {
        VStack(spacing: kGap) {
            ForEach(Array(designRows.enumerated()), id: \.offset) { _, row in
                rowView(row)
            }
        }
        .padding(20)
        .background(kBoard)
        .frame(width: kBoardWidth + 40)
        .sheet(item: $editingKey) { ki in
            KeyEditSheet(keyInfo: ki, onSave: { normal, shift in
                save(ki, normal: normal, shift: shift)
            })
        }
    }

    /// Открыть редактирование клавиши с её текущими значениями.
    private func beginEdit(_ def: KeyDef, _ normal: String, _ shift: String) {
        let ki = KeyInfo(keyCode: def.macKeyCode,
                         label: def.w3cName == "Space" ? "Space" : def.displayLabel)
        ki.normalSymbol = normal
        ki.shiftSymbol = shift
        editingKey = ki
    }

    /// Сохранить изменения: в память, в config.ini и уведомить движок ввода.
    private func save(_ ki: KeyInfo, normal: String, shift: String) {
        mappings[ki.keyCode] = (normal, shift)
        LayoutStore.shared.saveMappings(mappings)
        NotificationCenter.default.post(name: .mappingsDidChange, object: nil)
    }

    private func rowView(_ keys: [DKey]) -> some View {
        HStack(spacing: kGap) {
            ForEach(keys) { key in
                keyView(key)
            }
        }
        .frame(width: kBoardWidth)
    }

    @ViewBuilder
    private func keyView(_ key: DKey) -> some View {
        let cap = Group {
            switch key.role {
            case .mappable(let def):
                let normal = mappings[def.macKeyCode]?.normal ?? def.defaultNormal
                let shift = mappings[def.macKeyCode]?.shift ?? def.defaultShift
                MappableCap(def: def, normal: normal, shift: shift) {
                    beginEdit(def, normal, shift)
                }
            case .decor(let label, let style): DecorCap(label: label, style: style, align: key.align)
            case .arrows: ArrowsCluster()
            case .typograph: TypographCap()
            }
        }
        if case .arrows = key.role {
            // Кластер занимает три квадрата (◀ + ▲/▼ + ▶).
            cap.frame(width: 3 * kUnit + 2 * kGap, height: kUnit)
        } else {
            switch key.width {
            case .unit: cap.frame(width: kUnit, height: kUnit)
            case .wide: cap.frame(width: kWide, height: kUnit)
            case .flex: cap.frame(maxWidth: .infinity).frame(height: kUnit)
            }
        }
    }
}

// MARK: - Клавиши

/// Настраиваемая клавиша. Сетка как в макете:
/// левый-низ — физ. буква (бледная), правый-низ — обычный глиф,
/// правый-верх — Shift-глиф (фиолетовый). Все одного размера.
private struct MappableCap: View {
    let def: KeyDef
    let normal: String   // текущий символ (⌥) из конфига
    let shift: String    // текущий символ (⌥⇧) из конфига
    let onTap: () -> Void

    private var bottomLabel: String {
        def.w3cName == "Space" ? "SPACE" : def.displayLabel
    }

    /// Один слот клавиши: обычный глиф текстом, либо плашка-ширины для символов
    /// без начертания (разные пробелы, невидимые управляющие/форматные).
    @ViewBuilder
    private func slot(_ value: String, color: Color) -> some View {
        if isSingleBarGlyph(value) {
            BlankBar(value: value, color: color)
        } else {
            Text(displayGlyph(value))
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.5)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                slot(shift, color: kAccent)
            }
            Spacer(minLength: 0)
            HStack {
                Text(bottomLabel)
                    .foregroundStyle(.white.opacity(0.35))
                Spacer(minLength: 0)
                slot(normal, color: .white)
            }
        }
        .font(.system(size: kGlyphFont))
        .padding(7)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(kCapMappable)
        .clipShape(RoundedRectangle(cornerRadius: kRadius))
        .overlay(RoundedRectangle(cornerRadius: kRadius).strokeBorder(kBorder, lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

/// Декоративная клавиша: подпись прибита к нужному углу.
private struct DecorCap: View {
    let label: String
    let style: DecorStyle
    let align: Alignment

    var body: some View {
        Text(label)
            .font(.system(size: label.count > 2 ? 11 : 15, design: .monospaced))
            .foregroundStyle(textColor)
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: align)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: kRadius))
            .overlay(RoundedRectangle(cornerRadius: kRadius).strokeBorder(kBorder.opacity(0.6), lineWidth: 1))
    }

    private var textColor: Color {
        switch style {
        case .dim:       return .white.opacity(0.30)
        case .emphasis:  return kAccent
        case .strong:    return .white.opacity(0.90)
        case .highlight: return .black
        }
    }
    private var bgColor: Color {
        switch style {
        case .highlight: return .white
        default:         return kCapDecor
        }
    }
}

/// Клавиша ТИПОГРАФ (физически — Backspace): «ТИПОГРАФ» сверху-справа (белым) +
/// иконка ⌫ снизу-справа (приглушённая).
private struct TypographCap: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                Text("ТИПОГРАФ")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.90))
            }
            Spacer(minLength: 0)
            HStack {
                Spacer(minLength: 0)
                Text("⌫")
                    .font(.system(size: 17))
                    .foregroundStyle(.white.opacity(0.30))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(kCapDecor)
        .clipShape(RoundedRectangle(cornerRadius: kRadius))
        .overlay(RoundedRectangle(cornerRadius: kRadius).strokeBorder(kBorder.opacity(0.6), lineWidth: 1))
    }
}

/// Кластер стрелок «перевёрнутая Т»: ◀ ▼ ▶ в нижней половине, ▲ в верхней —
/// все половинной высоты, треугольники одного маленького размера (как на маке).
private struct ArrowsCluster: View {
    private let miniH = (kUnit - 2) / 2   // высота половинки (учитывая зазор 2)

    var body: some View {
        HStack(spacing: kGap) {
            bottomOnly("◀")                                  // левая: пусто сверху, ◀ снизу
            VStack(spacing: 2) { tri("▲"); tri("▼") }        // средняя: ▲ / ▼
            bottomOnly("▶")                                  // правая: пусто сверху, ▶ снизу
        }
    }

    private func bottomOnly(_ s: String) -> some View {
        VStack(spacing: 2) {
            Color.clear.frame(maxWidth: .infinity).frame(height: miniH)
            tri(s)
        }
    }

    private func tri(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.30))
            .frame(maxWidth: .infinity).frame(height: miniH)
            .background(kCapDecor)
            .clipShape(RoundedRectangle(cornerRadius: kRadius * 0.6))
            .overlay(RoundedRectangle(cornerRadius: kRadius * 0.6).strokeBorder(kBorder.opacity(0.6), lineWidth: 1))
    }
}

// MARK: - Хелпер глифа

private let kSpaceCarrier = "\u{25CC}"   // носитель для комбинирующей диакритики (◌)

/// Символ без начертания (разные пробелы, форматные, управляющие, разделители).
private func isInvisibleScalar(_ u: Unicode.Scalar) -> Bool {
    switch u.properties.generalCategory {
    case .spaceSeparator, .format, .control, .lineSeparator, .paragraphSeparator:
        return true
    default:
        return false
    }
}

/// Показать значение плашкой-ширины? Только если это ОДИН невидимый символ
/// без собственного значка — обычный пробел (␣) и неразрывный (⍽) исключены.
private func isSingleBarGlyph(_ s: String) -> Bool {
    let scalars = Array(s.unicodeScalars)
    guard scalars.count == 1, let u = scalars.first else { return false }
    if u.value == 0x20 || u.value == 0xA0 { return false }   // у них есть значки
    if GlyphRenderer.isCombiningDiacritic(u) { return false }
    return isInvisibleScalar(u)
}

/// Текстовое представление значения для клавиши:
/// ␣ — обычный пробел, ⍽ — неразрывный, диакритика — на кружке,
/// прочие невидимые символы опускаются (в смеси показываем только видимое).
private func displayGlyph(_ s: String) -> String {
    var out = ""
    for u in s.unicodeScalars {
        switch u.value {
        case 0x20: out += "␣"
        case 0xA0: out += "⍽"
        default:
            if GlyphRenderer.isCombiningDiacritic(u) {
                out += kSpaceCarrier + String(u)
            } else if isInvisibleScalar(u) {
                continue   // невидимое без значка — не показываем
            } else {
                out.unicodeScalars.append(u)
            }
        }
    }
    return out
}

/// Плашка шириной с сам невидимый символ: наглядно показывает вид пробела
/// (волосяной — тонкая, Em — широкая) без кодов U+XXXX. Универсально для любого
/// символа без начертания.
private struct BlankBar: View {
    let value: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color.opacity(0.75))
            .frame(width: barWidth, height: 13)
    }

    /// Реальная ширина символа в шрифте (замер при увеличенном кегле — чтобы
    /// разница между пробелами читалась), с минимумом и максимумом.
    private var barWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: 30)
        let w = (value as NSString).size(withAttributes: [.font: font]).width
        return min(max(w, 3), 42)
    }
}

// MARK: - Preview

#Preview {
    KeyboardEditorView2()
}
