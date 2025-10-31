import Combine
import SwiftUI
import Foundation

public struct HabitsScreen: View {
    @StateObject private var vm = HabitsViewModel()
    @Environment(\.colorScheme) private var scheme

    @State private var showEditor = false
    @State private var editing: SnackEvent? = nil
    @State private var query: String = ""

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.top, 8)

                    quickControls
                        .cardStyle(palette, elevated: true)

                    filters
                        .cardStyle(palette)

                    weeklyOverview
                        .cardStyle(palette, elevated: true)

                    listSection
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Habits")
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
                Text("Snacks: \(vm.snacksForDay.count) • Avg hunger \(NumberFormatters.string(from: vm.avgHungerForDay, format: .decimal1))")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                vm.nextDay()
                HapticsManager.shared.selection()
            } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.plain)
        }
    }

    // MARK: - Quick controls

    private var quickControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hunger").font(.subheadline)
                    Spacer()
                    HungerDots(level: vm.draftHunger, palette: palette)
                }
                Slider(
                    value: Binding(
                        get: { Double(vm.draftHunger) },
                        set: { vm.setHunger(Int($0.rounded())) }
                    ),
                    in: 1...5, step: 1
                )
                .tint(ColorTokens.habitsTabTint(palette))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SnackReason.allCases, id: \.self) { r in
                        let selected = vm.draftReason == r
                        Button {
                            vm.quickSelect(reason: r)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: AppIcons.reasonIcon(for: r.rawValue))
                                Text(r.label)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selected ? ColorTokens.reasonBadgeBackground(r.rawValue, palette: palette) : palette.surfaceAlt)
                            .overlay(
                                Capsule().stroke(ColorTokens.reasonBadgeText(r.rawValue, palette: palette),
                                                 lineWidth: selected ? 1 : 0.5)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Button {
                editing = nil
                showEditor = true
                HapticsManager.shared.tap()
            } label: {
                Label("Add Snack", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTokens.habitsTabTint(palette).opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    // MARK: - Filters

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Menu {
                    Button("Any Hunger") { vm.minHunger = nil }
                    Divider()
                    ForEach(1...5, id: \.self) { lvl in
                        Button("≥ \(lvl)") { vm.minHunger = lvl }
                    }
                } label: {
                    pill(
                        text: vm.minHunger == nil ? "Hunger: Any" : "Hunger: ≥ \(vm.minHunger!)",
                        color: ColorTokens.satietyFill(level: vm.minHunger ?? 3, palette: palette)
                    )
                }

                Menu {
                    ForEach(SnackReason.allCases, id: \.self) { r in
                        let contains = vm.reasonIn.contains(r)
                        Button((contains ? "✓ " : "") + r.label) { toggleReason(r) }
                    }
                    Divider()
                    Button("Clear") { vm.reasonIn.removeAll() }
                } label: {
                    pill(
                        text: vm.reasonIn.isEmpty ? "Reason: Any" : "Reason: \(vm.reasonIn.count)",
                        color: ColorTokens.reasonBadgeText("hunger", palette: palette).opacity(0.25)
                    )
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search notes", text: $query).textFieldStyle(.plain)
                if !query.isEmpty {
                    Button {
                        query = ""
                        HapticsManager.shared.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(palette.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(12)
    }

    // MARK: - Weekly overview

    private var weeklyOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Week").font(.headline)
                Spacer()
                Menu {
                    Button("This Week") { vm.weeklyRange = .thisWeek }
                    Button("Last 7 Days") { vm.weeklyRange = .last7 }
                    Button("This Month") { vm.weeklyRange = .thisMonth }
                } label: { Image(systemName: "calendar") }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                StatChip(
                    title: "Avg hunger",
                    value: NumberFormatters.string(from: vm.weeklyAvgHunger, format: .decimal1),
                    color: ColorTokens.habitsTabTint(palette)
                )
                Spacer(minLength: 0)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.weeklyReasonStats) { s in
                        ReasonStatChip(stat: s, palette: palette)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
    }

    // MARK: - List

    private var listSection: some View {
        let items = vm.filteredSnacks()
        return Group {
            if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No snacks")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .padding(.vertical, 12)
                .cardStyle(palette)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { s in
                        row(s)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    private func row(_ s: SnackEvent) -> some View {
        Button {
            editing = s
            vm.loadDraft(from: s)
            showEditor = true
        } label: {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 6) {
                    Image(systemName: AppIcons.reasonIcon(for: s.reason.rawValue))
                        .foregroundStyle(ColorTokens.reasonBadgeText(s.reason.rawValue, palette: palette))
                        .font(.title3)
                    Text(DateFormatters.string(from: s.date, style: .timeShort))
                        .font(.caption2).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ReasonBadge(reason: s.reason, palette: palette)
                        HungerDots(level: s.hungerLevel, palette: palette)
                    }
                    if let note = s.note, !note.isEmpty {
                        Text(note)
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
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
    }

    // MARK: - Editor Sheet

    private var editorSheet: some View {
        SnackInlineEditorSheet(
            isPresented: $showEditor,
            vm: vm,
            editing: editing != nil
        )
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

    private func toggleReason(_ r: SnackReason) {
        if vm.reasonIn.contains(r) { vm.reasonIn.remove(r) } else { vm.reasonIn.insert(r) }
        HapticsManager.shared.selection()
    }
}

// MARK: - Subviews

fileprivate struct HungerDots: View {
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
        .accessibilityLabel("Hunger \(level) of 5")
    }
}

fileprivate struct ReasonBadge: View {
    let reason: SnackReason
    let palette: AppTheme.Palette
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: AppIcons.reasonIcon(for: reason.rawValue))
            Text(reason.label)
        }
        .font(.caption)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(ColorTokens.reasonBadgeBackground(reason.rawValue, palette: palette))
        .clipShape(Capsule())
    }
}

fileprivate struct StatChip: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.headline).monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

fileprivate struct ReasonStatChip: View {
    let stat: HabitsViewModel.ReasonStat
    let palette: AppTheme.Palette
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: AppIcons.reasonIcon(for: stat.reason.rawValue))
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.reason.label).font(.caption)
                Text("\(stat.count) • \(NumberFormatters.string(from: stat.ratio, format: .percent0))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(ColorTokens.reasonBadgeBackground(stat.reason.rawValue, palette: palette))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Inline snack editor sheet

fileprivate struct SnackInlineEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @ObservedObject var vm: HabitsViewModel
    let editing: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Reason", selection: $vm.draftReason) {
                        ForEach(SnackReason.allCases, id: \.self) { r in
                            Text(r.label).tag(r)
                        }
                    }
                }
                Section("Hunger") {
                    Stepper(value: $vm.draftHunger, in: 1...5) {
                        HStack {
                            Text("Level \(vm.draftHunger)")
                            Spacer()
                            HungerDots(level: vm.draftHunger, palette: .init(isDark: UITraitCollection.current.userInterfaceStyle == .dark))
                        }
                    }
                }
                Section("Note") {
                    TextEditor(text: Binding(
                        get: { vm.draftNote },
                        set: { vm.draftNote = $0 }
                    ))
                    .frame(minHeight: 90)
                }
            }
            .navigationTitle(editing ? "Edit Snack" : "Add Snack")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false; dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        do {
                            if editing { try vm.updateFromDraft() } else { _ = try vm.addFromDraft() }
                            isPresented = false
                            dismiss()
                        } catch {
                            HapticsManager.shared.error()
                        }
                    }
                }
            }
        }
    }
}
