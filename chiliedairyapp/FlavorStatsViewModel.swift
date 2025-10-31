import Combine
import SwiftUI
import Foundation

@MainActor
public final class FlavorStatsViewModel: ObservableObject {
    // Store & deps
    private let store: PersistenceStore
    private let calendar: Calendar

    // Scope
    @Published public var rangeKind: DateRangeKind = .thisWeek

    // Filters
    @Published public var includedFlavors: Set<FlavorTag> = Set(FlavorTag.allCases)

    // Outputs
    @Published public private(set) var totalMeals: Int = 0
    @Published public private(set) var slices: [FlavorSlice] = []
    @Published public private(set) var topFlavor: FlavorTag? = nil
    @Published public private(set) var balanceText: String = "—"
    @Published public private(set) var dailyTrend: [DailyFlavorPoint] = []

    private var bag = Set<AnyCancellable>()

    public init(store: PersistenceStore = .shared, calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar
        bind()
        recompute()
    }

    // MARK: - Bindings

    private func bind() {
        Publishers.CombineLatest3(store.$meals, $rangeKind, $includedFlavors)
            .sink { [weak self] _,_,_ in self?.recompute() }
            .store(in: &bag)
    }

    // MARK: - Public API

    public func setRange(_ kind: DateRangeKind) {
        rangeKind = kind
    }

    public func toggleFlavor(_ tag: FlavorTag) {
        if includedFlavors.contains(tag) {
            includedFlavors.remove(tag)
        } else {
            includedFlavors.insert(tag)
        }
    }

    public func selectOnly(_ tag: FlavorTag) {
        includedFlavors = [tag]
    }

    public func selectAllFlavors() {
        includedFlavors = Set(FlavorTag.allCases)
    }

    // MARK: - Compute

    private func recompute() {
        let range = rangeKind.resolve(calendar: calendar)
        let meals = store.meals(in: range.start...range.end, calendar: calendar)
        totalMeals = meals.count

        // Distribution for selected flavors
        var counts: [FlavorTag: Int] = [:]
        for m in meals {
            let tags = Set(m.flavorTags).intersection(includedFlavors)
            for t in tags { counts[t, default: 0] += 1 }
        }
        let total = max(1, counts.values.reduce(0, +))
        slices = FlavorTag.allCases
            .filter { includedFlavors.contains($0) }
            .map { tag in
                let c = counts[tag] ?? 0
                let r = Double(c) / Double(total)
                return FlavorSlice(tag: tag, count: c, ratio: r)
            }
            .sorted { $0.count > $1.count }

        topFlavor = slices.first?.tag

        // Balance text
        let nonZero = slices.filter { $0.count > 0 }.count
        if nonZero == 0 { balanceText = "No data" }
        else if nonZero < 3 { balanceText = "Low variety" }
        else if nonZero == 3 { balanceText = "Balanced" }
        else { balanceText = "Rich variety" }

        // Trend: per-day occurrences (sum of selected flavors)
        dailyTrend = makeDailyTrend(range: range, meals: meals)
    }

    private func makeDailyTrend(range: DateRange, meals: [MealEntry]) -> [DailyFlavorPoint] {
        var points: [DailyFlavorPoint] = []
        var day = calendar.startOfDay(for: range.start)
        let end = calendar.startOfDay(for: range.end)

        while day <= end {
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let dayMeals = meals.filter { $0.date >= day && $0.date < next }
            var dayCount = 0
            for m in dayMeals {
                if !Set(m.flavorTags).intersection(includedFlavors).isEmpty {
                    dayCount += 1
                }
            }
            points.append(.init(day: day, count: dayCount))
            day = next
        }
        return points
    }

    // MARK: - Models

    public struct FlavorSlice: Identifiable, Hashable {
        public var id: String { tag.rawValue }
        public let tag: FlavorTag
        public let count: Int
        public let ratio: Double

        public var title: String { tag.title }
        public var percentText: String {
            NumberFormatters.string(from: ratio, format: .percent0)
        }
    }

    public struct DailyFlavorPoint: Identifiable, Hashable {
        public let id = UUID()
        public let day: Date
        public let count: Int

        public var label: String { DateFormatters.string(from: day, style: .weekdayShort) }
    }
}
