import Combine
import SwiftUI
import Foundation

public struct FlavorStatsScreen: View {
    @StateObject private var vm = FlavorStatsViewModel()
    @Environment(\.colorScheme) private var scheme

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    flavorFilters
                    distributionSection
                    trendSection
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Flavor")
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
                    Button("Last 7 Days") { vm.setRange(.last7);  HapticsManager.shared.selection() }
                    Button("This Month") { vm.setRange(.thisMonth); HapticsManager.shared.selection() }
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
                Text("Meals in range")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(vm.totalMeals)")
                    .font(.headline)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Flavor Filters

    private var flavorFilters: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flavors")
                .font(.headline)

            Wrap(spacing: 8) {
                ForEach(FlavorTag.allCases, id: \.self) { f in
                    let selected = vm.includedFlavors.contains(f)
                    Button {
                        vm.toggleFlavor(f)
                        HapticsManager.shared.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(ColorTokens.flavorStroke(f.rawValue, palette: palette))
                                .frame(width: 8, height: 8)
                            Text(f.title)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(selected ? ColorTokens.flavorFill(f.rawValue, palette: palette) : palette.surfaceAlt)
                        .overlay(
                            Capsule().stroke(ColorTokens.flavorStroke(f.rawValue, palette: palette), lineWidth: selected ? 1 : 0.5)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    vm.selectAllFlavors()
                    HapticsManager.shared.selection()
                } label: {
                    Text("All")
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(palette.surfaceAlt)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Distribution Section

    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Distribution")
                    .font(.headline)
                Spacer()
                Text(vm.balanceText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if vm.slices.allSatisfy({ $0.count == 0 }) {
                EmptyStateView(text: "No flavor data")
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.slices) { s in
                        FlavorBarRow(slice: s, palette: palette)
                    }
                }
                .cardStyle(palette, elevated: true)
            }
        }
    }

    // MARK: - Trend Section

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Trend")
                .font(.headline)

            if vm.dailyTrend.isEmpty {
                EmptyStateView(text: "No trend yet")
            } else {
                LineChartView(points: vm.dailyTrend.map { CGPoint(x: $0.day.timeIntervalSince1970, y: Double($0.count)) },
                              xLabels: vm.dailyTrend.map { DateFormatters.string(from: $0.day, style: .weekdayShort) },
                              stroke: ColorTokens.flavorTabTint(palette),
                              grid: palette.chartGrid,
                              axis: palette.chartAxis)
                .frame(height: 160)
                .cardStyle(palette, elevated: true)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                vm.selectAllFlavors()
                HapticsManager.shared.tap()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
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

// MARK: - Flavor Bar Row

fileprivate struct FlavorBarRow: View {
    let slice: FlavorStatsViewModel.FlavorSlice
    let palette: AppTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(slice.title)
                    .font(.subheadline)
                Spacer()
                Text(slice.percentText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(palette.chartGrid)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorTokens.flavorStroke(slice.tag.rawValue, palette: palette))
                        .frame(width: max(4, CGFloat(slice.ratio) * geo.size.width))
                        .animation(Anim.springSoft, value: slice.ratio)
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Line Chart (lightweight)

fileprivate struct LineChartView: View {
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

                // Path
                Path { p in
                    for (i, pt) in points.enumerated() {
                        let x = CGFloat((pt.x - minX) / (maxX - minX)) * geo.size.width
                        let y = geo.size.height - CGFloat((pt.y - minY) / (maxY - minY)) * geo.size.height
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Points
                ForEach(Array(points.enumerated()), id: \.offset) { (_, pt) in
                    let x = CGFloat((pt.x - minX) / (maxX - minX)) * geo.size.width
                    let y = geo.size.height - CGFloat((pt.y - minY) / (maxY - minY)) * geo.size.height
                    Circle()
                        .fill(stroke.opacity(0.9))
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Empty State

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
        .frame(maxWidth: .infinity, minHeight: 140)
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
