//
//  KeyboardEditorView.swift
//  hypetype
//
//  Визуальный редактор клавиатуры
//

import SwiftUI
import Combine

struct KeyboardEditorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = KeyboardEditorViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Клавиатура
            VStack(spacing: 8) {
                // Цифровой ряд
                keyboardRow(keys: viewModel.numberRow)
                
                // QWERTY ряд
                keyboardRow(keys: viewModel.qwertyRow)
                
                // ASDF ряд
                keyboardRow(keys: viewModel.asdfRow)
                
                // ZXCV ряд (включая пробел и тильду)
                keyboardRow(keys: viewModel.zxcvRow)
            }
            .padding(20)
            
            // Подсказка внизу
            VStack(alignment: .leading, spacing: 4) {
                Text("Символы вводятся с нажатым правым Option, например ⌥ + < и ⌥ + > дадут «кавычки».")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text("Если символ нарисован в верхней части кнопки, значит нужно нажать ещё и Shift, например ⌥ + ⇧ + С даст ¢")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 950, height: 530)
        .sheet(item: $viewModel.editingKey) { keyInfo in
            KeyEditSheet(
                keyInfo: keyInfo,
                onSave: { normal, shift in
                    viewModel.saveMapping(for: keyInfo, normal: normal, shift: shift)
                }
            )
        }
    }
    
    private func keyboardRow(keys: [KeyInfo]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys) { keyInfo in
                KeyButton(keyInfo: keyInfo) {
                    viewModel.editingKey = keyInfo
                }
            }
        }
    }
}

// MARK: - Key Button

struct KeyButton: View {
    let keyInfo: KeyInfo
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Название клавиши (вверху)
                Text(keyInfo.label)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Shift символ (посередине)
                Text(keyInfo.shiftSymbol.isEmpty ? " " : keyInfo.shiftSymbol)
                    .font(.system(size: 32))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                // Normal символ (внизу)
                Text(keyInfo.normalSymbol.isEmpty ? " " : keyInfo.normalSymbol)
                    .font(.system(size: 32))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(12)
            .frame(width: 65)
            .frame(minHeight: 80)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Key Edit Sheet

struct KeyEditSheet: View {
    let keyInfo: KeyInfo
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var normalSymbol: String
    @State private var shiftSymbol: String
    
    init(keyInfo: KeyInfo, onSave: @escaping (String, String) -> Void) {
        self.keyInfo = keyInfo
        self.onSave = onSave
        _normalSymbol = State(initialValue: keyInfo.normalSymbol)
        _shiftSymbol = State(initialValue: keyInfo.shiftSymbol)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Редактирование: \(keyInfo.label)")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                // Shift символ
                VStack(alignment: .leading, spacing: 8) {
                    Text("Right Option + Shift + \(keyInfo.label)")
                        .font(.headline)
                    
                    TextField("Символ с Shift", text: $shiftSymbol)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 24))
                    
                    Text("Вставьте символ из буфера (⌘V)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Normal символ
                VStack(alignment: .leading, spacing: 8) {
                    Text("Right Option + \(keyInfo.label)")
                        .font(.headline)
                    
                    TextField("Обычный символ", text: $normalSymbol)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 24))
                    
                    Text("Вставьте символ из буфера (⌘V)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Сохранить") {
                    onSave(normalSymbol, shiftSymbol)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500)
    }
}

// MARK: - View Model

class KeyboardEditorViewModel: ObservableObject {
    @Published var editingKey: KeyInfo?
    @Published var mappings: [Int: (normal: String, shift: String)] = [:]

    let numberRow: [KeyInfo]
    let qwertyRow: [KeyInfo]
    let asdfRow: [KeyInfo]
    let zxcvRow: [KeyInfo]

    init() {
        mappings = MappingManager.shared.loadMappings()

        func makeRow(_ slice: ArraySlice<KeyDef>) -> [KeyInfo] {
            slice.map { KeyInfo(keyCode: $0.macKeyCode, label: $0.displayLabel) }
        }

        numberRow = makeRow(KeyDefinitions.numberRow)
        qwertyRow = makeRow(KeyDefinitions.qwertyRow)
        asdfRow   = makeRow(KeyDefinitions.asdfRow)
        zxcvRow   = makeRow(KeyDefinitions.zxcvRow)

        updateSymbols()
    }
    
    private func updateSymbols() {
        for keyInfo in numberRow + qwertyRow + asdfRow + zxcvRow {
            if let mapping = mappings[keyInfo.keyCode] {
                keyInfo.normalSymbol = mapping.normal
                keyInfo.shiftSymbol = mapping.shift
            }
        }
    }
    
    func saveMapping(for keyInfo: KeyInfo, normal: String, shift: String) {
        // Обновляем маппинг
        mappings[keyInfo.keyCode] = (normal, shift)
        
        // Обновляем символы в UI
        keyInfo.normalSymbol = normal
        keyInfo.shiftSymbol = shift
        
        // Сохраняем в файл
        MappingManager.shared.saveMappings(mappings)
        
        // Перезагружаем в EventTapManager
        NotificationCenter.default.post(name: .mappingsDidChange, object: nil)
        
        print("✅ Маппинг сохранён: \(keyInfo.label) → Normal: \(normal), Shift: \(shift)")
    }
}

// MARK: - Key Info Model

class KeyInfo: Identifiable, ObservableObject {
    let id = UUID()
    let keyCode: Int
    let label: String
    @Published var normalSymbol: String = ""
    @Published var shiftSymbol: String = ""
    
    init(keyCode: Int, label: String) {
        self.keyCode = keyCode
        self.label = label
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let mappingsDidChange = Notification.Name("mappingsDidChange")
}
