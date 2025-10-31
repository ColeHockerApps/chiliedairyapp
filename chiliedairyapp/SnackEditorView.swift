import Combine
import SwiftUI
import Foundation

public struct SnackEditorView: View {
    @ObservedObject private var vm: HabitsViewModel
    @Binding private var isPresented: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init(vm: HabitsViewModel, isPresented: Binding<Bool>) {
        self._vm = ObservedObject(initialValue: vm)
        self._isPresented = isPresented
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Reason", selection: $vm.draftReason) {
                        ForEach(SnackReason.allCases, id: \.self) { r in
                            HStack(spacing: 8) {
                                Image(systemName: AppIcons.reasonIcon(for: r.rawValue))
                                Text(r.label)
                            }
                            .tag(r)
                        }
                    }
                }

                Section("Hunger") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Level \(vm.draftHunger)")
                            Spacer()
                            HungerDots(level: vm.draftHunger, palette: palette)
                        }
                        Slider(value: Binding(
                            get: { Double(vm.draftHunger) },
                            set: { vm.setHunger(Int($0.rounded())) }
                        ), in: 1...5, step: 1)
                        .tint(ColorTokens.habitsTabTint(palette))
                    }
                }

                Section("Note") {
                    TextEditor(text: $vm.draftNote)
                        .frame(minHeight: 90)
                }
            }
            .navigationTitle(vm.isEditing ? "Edit Snack" : "Add Snack")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        do {
            if vm.isEditing {
                try vm.updateFromDraft()
            } else {
                _ = try vm.addFromDraft()
            }
            isPresented = false
            dismiss()
            HapticsManager.shared.confirm()
        } catch {
            HapticsManager.shared.error()
        }
    }
}

// MARK: - Local dots

fileprivate struct HungerDots: View {
    let level: Int
    let palette: AppTheme.Palette
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? ColorTokens.satietyFill(level: level, palette: palette) : palette.chartGrid)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityLabel("Hunger \(level) of 5")
    }
}
