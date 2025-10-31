import Combine
import SwiftUI
import Foundation

public struct InsightsScreen: View {
    @StateObject private var vm = InsightsViewModel()
    @Environment(\.colorScheme) private var scheme

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    weeklySummary
                    trendsSection
                    highlightsSection
                    insightsSection
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Insights")
            .toolbar { toolbar }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Range")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Menu {
                    Button("This Week") { vm.setRange(.thisWeek); HapticsManager.shared.selection() }
                    Button("Last 7 Days") { vm.setRange(.last7); HapticsManager.shared.selection() }
                    Button("This Month")  { vm.setRange(.thisMonth); HapticsManager.shared.selection() }
                } label: {
                    HStack {
                        Text(rangeLabel(vm.rangeKind))
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(palette.surfaceAlt)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("Overview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(vm.insightSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Weekly Summary

    private var weeklySummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Summary")
                .font(.headline)

            HStack(spacing: 10) {
                StatChip(title: "Meals", value: "\(vm.weekly.totalMeals)", tint: ColorTokens.dayTabTint(palette))
                StatChip(title: "Snacks", value: "\(vm.weekly.totalSnacks)", tint: ColorTokens.habitsTabTint(palette))
            }

            HStack(spacing: 10) {
                StatChip(title: "Satiety", value: NumberFormatters.string(from: vm.weekly.avgSatiety, format: .decimal1), tint: palette.chartAxis)
                StatChip(title: "Energy",  value: MealFormatters.energyString(vm.weekly.avgEnergy), tint: ColorTokens.insightsTabTint(palette))
                StatChip(title: "Hunger",  value: NumberFormatters.string(from: vm.weekly.avgHunger, format: .decimal1), tint: palette.chartGrid)
            }
        }
    }

    // MARK: - Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(.headline)

            VStack(spacing: 12) {
                TrendCard(title: "Satiety", icon: AppIcons.trendUp,
                          points: vm.satietyTrend.map { CGPoint(x: $0.day.timeIntervalSince1970, y: $0.value) },
                          labels: vm.satietyTrend.map { DateFormatters.string(from: $0.day, style: .weekdayShort) },
                          stroke: ColorTokens.dayTabTint(palette),
                          palette: palette)

                // FIX: use a valid icon string (no chained .circle on a string constant)
                TrendCard(title: "Energy", icon: "bolt.circle",
                          points: vm.energyTrend.map { CGPoint(x: $0.day.timeIntervalSince1970, y: $0.value) },
                          labels: vm.energyTrend.map { DateFormatters.string(from: $0.day, style: .weekdayShort) },
                          stroke: ColorTokens.insightsTabTint(palette),
                          palette: palette)

                TrendCard(title: "Hunger", icon: AppIcons.warning,
                          points: vm.hungerTrend.map { CGPoint(x: $0.day.timeIntervalSince1970, y: $0.value) },
                          labels: vm.hungerTrend.map { DateFormatters.string(from: $0.day, style: .weekdayShort) },
                          stroke: ColorTokens.habitsTabTint(palette),
                          palette: palette)
            }
        }
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Highlights")
                .font(.headline)

            if vm.topEnergizingMeals.isEmpty && vm.topHeavyMeals.isEmpty && vm.topSnackReasons.isEmpty {
                EmptyStateView(text: "No highlights yet")
            } else {
                VStack(spacing: 10) {
                    if !vm.topEnergizingMeals.isEmpty {
                        HighlightList(
                            title: "Energizing Meals",
                            icon: AppIcons.energyHigh,
                            items: vm.topEnergizingMeals.map { ($0.name, "\($0.count)x") },
                            tint: ColorTokens.insightsTabTint(palette),
                            palette: palette
                        )
                    }
                    if !vm.topHeavyMeals.isEmpty {
                        HighlightList(
                            title: "Heavy Meals",
                            icon: AppIcons.satietyHigh,
                            items: vm.topHeavyMeals.map { ($0.name, "\($0.count)x") },
                            tint: palette.chartAxis,
                            palette: palette
                        )
                    }
                    if !vm.topSnackReasons.isEmpty {
                        HighlightList(
                            title: "Snack Reasons",
                            icon: AppIcons.info,
                            items: vm.topSnackReasons.map { ($0.label, $0.ratioText) },
                            tint: ColorTokens.habitsTabTint(palette),
                            palette: palette
                        )
                    }
                }
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generated Insights")
                .font(.headline)

            if vm.insights.isEmpty {
                EmptyStateView(text: "No insights yet")
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.insights) { item in
                        InsightRow(item: item, palette: palette)
                            .transition(.fadeScale)
                    }
                }
                .cardStyle(palette, elevated: true)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.refresh()
                HapticsManager.shared.tap()
            } label: { Image(systemName: "arrow.clockwise") }
        }
    }

    // MARK: - Helpers

    private func rangeLabel(_ kind: DateRangeKind) -> String {
        switch kind {
        case .today: return "Today"
        case .last7: return "Last 7 Days"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Components

fileprivate struct StatChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.headline).monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

fileprivate struct TrendCard: View {
    let title: String
    let icon: String
    let points: [CGPoint]
    let labels: [String]
    let stroke: Color
    let palette: AppTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline)
                Spacer()
                if let last = points.last?.y {
                    Text(NumberFormatters.string(from: Double(last), format: .decimal1))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if points.isEmpty {
                EmptyStateView(text: "No data")
            } else {
                LineChart(points: points, xLabels: labels, stroke: stroke, grid: palette.chartGrid, axis: palette.chartAxis)
                    .frame(height: 150)
            }
        }
        .cardStyle(palette, elevated: true)
    }
}

fileprivate struct HighlightList: View {
    let title: String
    let icon: String
    let items: [(String, String)]
    let tint: Color
    let palette: AppTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title).font(.subheadline)
                Spacer()
            }
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                HStack {
                    Text(it.0)
                        .font(.subheadline)
                    Spacer()
                    Text(it.1)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                Divider().opacity(0.4)
            }
        }
        .padding(10)
        .background(palette.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 0.8)
        )
    }
}

fileprivate struct InsightRow: View {
    let item: InsightItem
    let palette: AppTheme.Palette

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(InsightFormatters.categoryEmoji(item.category))
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.subheadline)
                Text(item.description).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(palette.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

fileprivate struct EmptyStateView: View {
    let text: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }
}

// MARK: - Lightweight Line Chart

fileprivate struct LineChart: View {
    let points: [CGPoint]         // x: timestamp, y: value
    let xLabels: [String]
    let stroke: Color
    let grid: Color
    let axis: Color

    var body: some View {
        GeometryReader { geo in
            let xs = points.map { $0.x }
            let ys = points.map { $0.y }
            let minX = xs.min() ?? 0
            let maxX = xs.max() ?? 1
            let minY = ys.min() ?? 0
            let maxY = max(ys.max() ?? 1, minY + 1)

            ZStack {
                // Grid
                VStack {
                    Divider().background(grid)
                    Spacer()
                    Divider().background(grid)
                    Spacer()
                    Divider().background(grid)
                }

                // Axis baseline
                Rectangle()
                    .fill(axis.opacity(0.6))
                    .frame(height: 1)
                    .offset(y: geo.size.height - 1)

                // Path
                Path { p in
                    for (i, pt) in points.enumerated() {
                        let x = map(pt.x, minX, maxX, 0, geo.size.width)
                        let y = geo.size.height - map(pt.y, minY, maxY, 0, geo.size.height)
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                // FIX: StrokeStyle argument order (lineCap precedes lineJoin)
                .stroke(stroke, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Points
                ForEach(Array(points.enumerated()), id: \.offset) { (_, pt) in
                    let x = map(pt.x, minX, maxX, 0, geo.size.width)
                    let y = geo.size.height - map(pt.y, minY, maxY, 0, geo.size.height)
                    Circle()
                        .fill(stroke.opacity(0.9))
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                        .transition(.scale)
                }
            }
            .animation(Anim.springSoft, value: points)
        }
    }

    private func map(_ v: CGFloat, _ inMin: CGFloat, _ inMax: CGFloat, _ outMin: CGFloat, _ outMax: CGFloat) -> CGFloat {
        guard inMax > inMin else { return outMin }
        let t = (v - inMin) / (inMax - inMin)
        return outMin + t * (outMax - outMin)
    }
}
