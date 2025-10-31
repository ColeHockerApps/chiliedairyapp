import Combine
import SwiftUI
import Foundation

public struct DayLogScreen: View {
    @StateObject private var vm = DayLogViewModel()
    @Environment(\.colorScheme) private var scheme

    @State private var showEditor = false
    @State private var editing: MealEntry? = nil
    @State private var query: String = ""

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.top, 8)

                    summaryChips
                        .cardStyle(palette)

                    filters
                        .cardStyle(palette, elevated: true)

                    listSection
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Day Log")
            .toolbar { toolbar }
            .sheet(isPresented: $showEditor) { editorSheet }
            .onChange(of: query) { vm.search = query }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                vm.previousDay()
                HapticsManager.shared.selection()
            } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.plain)

            VStack(spacing: 4) {
                Text(DateFormatters.string(from: vm.selectedDate, style: .dayFull))
                    .font(.title3).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                Text("Quick view of today")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                vm.nextDay()
                HapticsManager.shared.selection()
            } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.plain)
        }
    }

    // MARK: - Summary chips

    private var summaryChips: some View {
        HStack(spacing: 12) {
            StatChipLarge(
                title: "Meals",
                value: "\(vm.mealsForDay.count)",
                tint: ColorTokens.dayTabTint(palette)
            )
            StatChipLarge(
                title: "Satiety",
                value: NumberFormatters.string(from: vm.summary.avgSatiety, format: .decimal1),
                tint: palette.chartAxis
            )
            StatChipLarge(
                title: "Energy",
                value: MealFormatters.energyString(vm.summary.avgEnergy),
                tint: ColorTokens.insightsTabTint(palette)
            )
        }
    }

    // MARK: - Filters

    private var filters: some View {
        VStack(alignment: .leading, spacing: 14) {
            // верхняя строка фильтров-меню
            HStack(spacing: 10) {
                Menu {
                    Button("Any Satiety") { vm.minSatiety = nil }
                    Divider()
                    ForEach(1...5, id: \.self) { lvl in
                        Button("≥ \(lvl)") { vm.minSatiety = lvl }
                    }
                } label: {
                    pill(
                        text: vm.minSatiety == nil ? "Satiety: Any" : "Satiety: ≥ \(vm.minSatiety!)",
                        color: ColorTokens.satietyFill(level: vm.minSatiety ?? 3, palette: palette)
                    )
                }

                Menu {
                    ForEach(EnergyLevel.allCases, id: \.self) { e in
                        let on = vm.energyIn.contains(e)
                        Button((on ? "✓ " : "") + e.label) { toggleEnergy(e) }
                    }
                    Divider()
                    Button("Clear") { vm.energyIn.removeAll() }
                } label: {
                    pill(
                        text: vm.energyIn.isEmpty ? "Energy: Any" : "Energy: \(vm.energyIn.count)",
                        color: ColorTokens.energyFill("high", palette: palette).opacity(0.25)
                    )
                }
            }

            // чипсы вкусов (wrap)
            Wrap(spacing: 8) {
                ForEach(FlavorTag.allCases, id: \.self) { tag in
                    let selected = vm.flavorIn.contains(tag)
                    Button {
                        toggleFlavor(tag)
                    } label: {
                        Text(tag.title)
                            .font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selected
                                        ? ColorTokens.flavorFill(tag.rawValue, palette: palette)
                                        : palette.surfaceAlt)
                            .overlay(
                                Capsule().stroke(
                                    ColorTokens.flavorStroke(tag.rawValue, palette: palette),
                                    lineWidth: selected ? 1 : 0.5
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // поиск
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .textFieldStyle(.plain)
                    .font(.body)
                if !query.isEmpty {
                    Button {
                        query = ""
                        HapticsManager.shared.selection()
                    } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(palette.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(12)
    }

    // MARK: - List

    private var listSection: some View {
        let items = vm.filteredMeals()
        return Group {
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No entries")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .padding(.vertical, 12)
                .cardStyle(palette)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { meal in
                        row(meal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    private func row(_ m: MealEntry) -> some View {
        Button {
            editing = m
            vm.loadDraft(from: m)
            showEditor = true
        } label: {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .center, spacing: 6) {
                    Image(systemName: iconFor(mealType: m.type))
                        .foregroundStyle(ColorTokens.dayTabTint(palette))
                        .font(.title3)
                    Text(DateFormatters.string(from: m.date, style: .timeShort))
                        .font(.caption2).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(m.name)
                        .font(.body)
                    HStack(spacing: 10) {
                        SatietyDotsView(level: m.satietyLevel, palette: palette)
                        Divider().frame(height: 12)
                        Label(
                            m.energyAfter.label,
                            systemImage: AppIcons.energyIcon(for: m.energyAfter.rawValue)
                        )
                        .font(.caption)
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(ColorTokens.energyFill(m.energyAfter.rawValue, palette: palette))
                    }
                    FlavorChipsView(tags: m.flavorTags, palette: palette)
                    if let notes = m.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Today") { vm.goToToday(); HapticsManager.shared.selection() }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                editing = nil
                vm.resetDraft()
                showEditor = true
                HapticsManager.shared.tap()
            } label: { Image(systemName: "plus.circle.fill") }
        }
    }

    // MARK: - Editor Sheet
//
//    private var editorSheet: some View {
//        DayMealEditorView(
//            isPresented: $showEditor,
//            editing: editing != nil,
//            saveAction: { _ in editing = nil }
//        )
//        .presentationDetents([.medium, .large])
//    }

    // MARK: - Editor Sheet
    private var editorSheet: some View {
        MealEditorView(vm: vm, isPresented: $showEditor)
            .presentationDetents([.medium, .large])
    }
    
    
    
    // MARK: - Helpers

    private func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(color.opacity(0.25))
            .clipShape(Capsule())
    }

    private func toggleFlavor(_ tag: FlavorTag) {
        if vm.flavorIn.contains(tag) { vm.flavorIn.remove(tag) } else { vm.flavorIn.insert(tag) }
        HapticsManager.shared.selection()
    }

    private func toggleEnergy(_ e: EnergyLevel) {
        if vm.energyIn.contains(e) { vm.energyIn.remove(e) } else { vm.energyIn.insert(e) }
        HapticsManager.shared.selection()
    }

    private func iconFor(mealType: MealType) -> String {
        switch mealType {
        case .breakfast: return AppIcons.breakfast
        case .lunch:     return AppIcons.lunch
        case .dinner:    return AppIcons.dinner
        case .snack:     return AppIcons.snack
        default:         return "fork.knife"
        }
    }
}

// MARK: - Subviews

fileprivate struct StatChipLarge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.headline).monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

fileprivate struct SatietyDotsView: View {
    let level: Int
    let palette: AppTheme.Palette

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= level ? ColorTokens.satietyFill(level: level, palette: palette) : palette.chartGrid)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

fileprivate struct FlavorChipsView: View {
    let tags: [FlavorTag]
    let palette: AppTheme.Palette

    var body: some View {
        Wrap(spacing: 8) {
            ForEach(Array(Set(tags)), id: \.self) { t in
                Text(t.title)
                    .font(.caption2)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(ColorTokens.flavorFill(t.rawValue, palette: palette))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Inline Editor

fileprivate struct DayMealEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    let editing: Bool
    let saveAction: (MealEntry) -> Void

    @State private var name: String = ""
    @State private var type: MealType = .meal
    @State private var satiety: Int = 3
    @State private var energy: EnergyLevel = .medium
    @State private var flavors: Set<FlavorTag> = []
    @State private var notes: String = ""

    @Environment(\.colorScheme) private var scheme
    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(MealType.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }
                }
                Section("Satiety") {
                    Stepper(value: $satiety, in: 1...5) {
                        HStack {
                            Text("Level \(satiety)")
                            SatietyDotsView(level: satiety, palette: palette)
                        }
                    }
                }
                Section("Energy After") {
                    Picker("Energy", selection: $energy) {
                        ForEach(EnergyLevel.allCases, id: \.self) { e in
                            Text(e.label).tag(e)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Flavors") {
                    Wrap(spacing: 8) {
                        ForEach(FlavorTag.allCases, id: \.self) { f in
                            let selected = flavors.contains(f)
                            Button {
                                if selected { flavors.remove(f) } else { flavors.insert(f) }
                                HapticsManager.shared.selection()
                            } label: {
                                Text(f.title)
                                    .font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(selected ? ColorTokens.flavorFill(f.rawValue, palette: palette) : palette.surfaceAlt)
                                    .overlay(
                                        Capsule().stroke(ColorTokens.flavorStroke(f.rawValue, palette: palette),
                                                         lineWidth: selected ? 1 : 0.5)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle(editing ? "Edit Meal" : "Add Meal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false; dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let entry = MealEntry(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: type,
                            satietyLevel: satiety,
                            energyAfter: energy,
                            flavorTags: Array(flavors),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
                        )
                        saveAction(entry)
                        isPresented = false
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Wrap Layout (iOS 16+)

fileprivate struct WrapLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 6) { self.spacing = spacing }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > maxWidth {
                x = 0; y += lineH + spacing; lineH = 0
            }
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
        }
        return CGSize(width: maxWidth, height: y + lineH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > maxWidth {
                x = 0; y += lineH + spacing; lineH = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                      proposal: ProposedViewSize(width: sz.width, height: sz.height))
            x += sz.width + spacing
            lineH = max(lineH, sz.height)
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
    var body: some View { WrapLayout(spacing: spacing) { content } }
}
