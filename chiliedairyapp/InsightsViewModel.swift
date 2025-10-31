import Combine
import SwiftUI
import Foundation

@MainActor
public final class InsightsViewModel: ObservableObject {
    // Deps
    private let store: PersistenceStore
    private let stats: StatsEngine
    private let calendar: Calendar

    // Scope
    @Published public var rangeKind: DateRangeKind = .thisWeek

    // Outputs
    @Published public private(set) var weekly: StatsEngine.WeeklyStats = .init(
        range: DateRange(start: Date(), end: Date()),
        totalMeals: 0, totalSnacks: 0,
        avgSatiety: 0, avgEnergy: 0, avgHunger: 0,
        flavorDist: [:], reasonDist: [:]
    )
    @Published public private(set) var insights: [InsightItem] = []
    @Published public private(set) var satietyTrend: [StatsEngine.TrendPoint] = []
    @Published public private(set) var energyTrend: [StatsEngine.TrendPoint] = []
    @Published public private(set) var hungerTrend: [StatsEngine.TrendPoint] = []

    // Highlights
    @Published public private(set) var topEnergizingMeals: [NameCount] = []
    @Published public private(set) var topHeavyMeals: [NameCount] = []
    @Published public private(set) var topSnackReasons: [ReasonRatio] = []

    // Summaries
    @Published public private(set) var balanceSummary: String = "—"
    @Published public private(set) var insightSummary: String = "No insights yet"

    private var bag = Set<AnyCancellable>()

    public init(
        store: PersistenceStore = .shared,
        stats: StatsEngine = .shared,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.stats = stats
        self.calendar = calendar
        self.rangeKind = .thisWeek

        bind()
        recomputeAll()
    }

    // MARK: - Bindings

    private func bind() {
        Publishers.CombineLatest3(store.$meals, store.$snacks, $rangeKind)
            .sink { [weak self] _,_,_ in self?.recomputeAll() }
            .store(in: &bag)
    }

    // MARK: - Public API

    public func setRange(_ kind: DateRangeKind) {
        rangeKind = kind
    }

    public func refresh() {
        recomputeAll()
    }

    // MARK: - Compute

    private func recomputeAll() {
        weekly = stats.makeWeeklyStats(for: rangeKind, store: store, calendar: calendar)
        insights = stats.generateInsights(for: weekly)

        satietyTrend = stats.satietyTrend(for: rangeKind, store: store, calendar: calendar)
        energyTrend  = stats.energyTrend(for: rangeKind, store: store, calendar: calendar)
        hungerTrend  = stats.hungerTrend(for: rangeKind, store: store, calendar: calendar)

        computeHighlights()
        computeSummaries()
    }

    private func computeHighlights() {
        let r = rangeKind.resolve(calendar: calendar)
        let meals = store.meals(in: r.start...r.end, calendar: calendar)

        topEnergizingMeals = topNames(in: meals.filter { $0.energyAfter == .high })

        let heavyCandidates = meals.filter { $0.satietyLevel >= 4 && $0.energyAfter == .low }
        topHeavyMeals = topNames(in: heavyCandidates)

        let snacks = store.snacks(in: r.start...r.end, calendar: calendar)
        let counts = snacks.reasonDistribution()
        let total = max(1, counts.values.reduce(0, +))
        topSnackReasons = SnackReason.allCases
            .map { rsn in
                ReasonRatio(reason: rsn, count: counts[rsn] ?? 0, ratio: Double(counts[rsn] ?? 0) / Double(total))
            }
            .sorted { $0.count > $1.count }
    }

    private func computeSummaries() {
        balanceSummary = FlavorFormatters.balanceSummary(weekly.flavorDist)
        insightSummary = InsightFormatters.summary(for: insights)
    }

    // MARK: - Helpers

    private func topNames(in meals: [MealEntry], limit: Int = 5) -> [NameCount] {
        let freq = Dictionary(grouping: meals.map { $0.name.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }) { $0 }
            .mapValues { $0.count }
        return freq
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { NameCount(name: $0.key, count: $0.value) }
    }

    // MARK: - Models

    public struct NameCount: Identifiable, Hashable {
        public let id = UUID()
        public let name: String
        public let count: Int
    }

    public struct ReasonRatio: Identifiable, Hashable {
        public let id = UUID()
        public let reason: SnackReason
        public let count: Int
        public let ratio: Double

        public var label: String { reason.label }
        public var ratioText: String { NumberFormatters.string(from: ratio, format: .percent0) }
    }
}
