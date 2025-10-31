import Combine
import SwiftUI
import Foundation

public struct MealEditorView: View {
    @ObservedObject private var vm: DayLogViewModel
    @Binding private var isPresented: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init(vm: DayLogViewModel, isPresented: Binding<Bool>) {
        self._vm = ObservedObject(initialValue: vm)
        self._isPresented = isPresented
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Name", text: $vm.draftName)
                        .textInputAutocapitalization(.sentences)
                        .onSubmit { HapticsManager.shared.selection() }

                    Picker("Type", selection: $vm.draftType) {
                        ForEach(MealType.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }
                }

                Section("Satiety") {
                    Stepper(value: $vm.draftSatiety, in: 1...5) {
                        HStack {
                            Text("Level \(vm.draftSatiety)")
                            Spacer()
                            SatietyDots(level: vm.draftSatiety, palette: palette)
                        }
                    }
                }

                Section("Energy After") {
                    Picker("Energy", selection: $vm.draftEnergy) {
                        ForEach(EnergyLevel.allCases, id: \.self) { e in
                            Text(e.label).tag(e)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Flavors") {
                    Wrap(spacing: 8) {
                        ForEach(FlavorTag.allCases, id: \.self) { f in
                            let selected = vm.draftFlavors.contains(f)
                            Button {
                                vm.toggleFlavor(f)
                                HapticsManager.shared.selection()
                            } label: {
                                Text(f.title)
                                    .font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(selected
                                                ? ColorTokens.flavorFill(f.rawValue, palette: palette)
                                                : palette.surfaceAlt)
                                    .overlay(
                                        Capsule().stroke(
                                            ColorTokens.flavorStroke(f.rawValue, palette: palette),
                                            lineWidth: selected ? 1 : 0.5
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section("Notes") {
                    TextEditor(text: $vm.draftNotes)
                        .frame(minHeight: 90)
                }
            }
            .navigationTitle(vm.isEditing ? "Edit Meal" : "Add Meal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(vm.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        } catch {
            HapticsManager.shared.error()
        }
    }
}

// MARK: - Satiety Dots (local)

fileprivate struct SatietyDots: View {
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
        .accessibilityLabel("Satiety \(level) of 5")
    }
}

// MARK: - Wrap Layout (iOS 16+)

fileprivate struct WrapLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 6) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            sub.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

fileprivate struct Wrap<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content

    init(spacing: CGFloat = 6, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        WrapLayout(spacing: spacing) {
            content
        }
    }
}
