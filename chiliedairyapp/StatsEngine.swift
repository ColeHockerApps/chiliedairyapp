import Combine
import SwiftUI
import Foundation

@MainActor
public final class StatsEngine: ObservableObject {
    public static let shared = StatsEngine()
    private init() {}

    // MARK: - Daily Summary

    public func makeDailySummary(for day: Date, store: PersistenceStore, calendar: Calendar = .current) -> DailySummary {
        let meals = store.meals(on: day, calendar: calendar)
        let total = meals.count
        let avgSatiety = meals.averageSatiety()
        let avgEnergy = meals.averageEnergy()
        let favFlavor = meals.mostFrequentFlavor()

        return DailySummary(date: day,
                            totalMeals: total,
                            avgSatiety: avgSatiety,
                            avgEnergy: avgEnergy,
                            favoriteFlavor: favFlavor)
    }

    // MARK: - Weekly Stats

    public struct WeeklyStats {
        public let range: DateRange
        public let totalMeals: Int
        public let totalSnacks: Int
        public let avgSatiety: Double
        public let avgEnergy: Double
        public let avgHunger: Double
        public let flavorDist: [FlavorTag: Double]
        public let reasonDist: [SnackReason: Double]
    }

    public func makeWeeklyStats(for range: DateRangeKind, store: PersistenceStore, calendar: Calendar = .current) -> WeeklyStats {
        let r = range.resolve(calendar: calendar)
        let meals = store.meals(in: r.start...r.end, calendar: calendar)
        let snacks = store.snacks(in: r.start...r.end, calendar: calendar)

        let totalMeals = meals.count
        let totalSnacks = snacks.count
        let avgSatiety = meals.averageSatiety()
        let avgEnergy = meals.averageEnergy()
        let avgHunger = snacks.averageHunger()

        let flavorCounts = flavorDistribution(from: meals)
        var flavorRatios: [FlavorTag: Double] = [:]
        for t in FlavorTag.allCases {
            flavorRatios[t] = flavorCounts.ratio(t)
        }

        let reasonCounts = snacks.reasonDistribution()
        let totalReason = max(1, reasonCounts.values.reduce(0, +))
        let reasonRatios = reasonCounts.mapValues { Double($0) / Double(totalReason) }

        return WeeklyStats(range: r,
                           totalMeals: totalMeals,
                           totalSnacks: totalSnacks,
                           avgSatiety: avgSatiety,
                           avgEnergy: avgEnergy,
                           avgHunger: avgHunger,
                           flavorDist: flavorRatios,
                           reasonDist: reasonRatios)
    }

    // MARK: - Trends

    public struct TrendPoint: Identifiable {
        public let id = UUID()
        public let day: Date
        public let value: Double
    }

    public func satietyTrend(for range: DateRangeKind, store: PersistenceStore, calendar: Calendar = .current) -> [TrendPoint] {
        let r = range.resolve(calendar: calendar)
        let days = stride(from: r.start, through: r.end, by: 60 * 60 * 24)
        return days.map { day in
            let meals = store.meals(on: day, calendar: calendar)
            let avg = meals.averageSatiety()
            return TrendPoint(day: day, value: avg)
        }
    }

    public func energyTrend(for range: DateRangeKind, store: PersistenceStore, calendar: Calendar = .current) -> [TrendPoint] {
        let r = range.resolve(calendar: calendar)
        let days = stride(from: r.start, through: r.end, by: 60 * 60 * 24)
        return days.map { day in
            let meals = store.meals(on: day, calendar: calendar)
            let avg = meals.averageEnergy()
            return TrendPoint(day: day, value: avg)
        }
    }

    public func hungerTrend(for range: DateRangeKind, store: PersistenceStore, calendar: Calendar = .current) -> [TrendPoint] {
        let r = range.resolve(calendar: calendar)
        let days = stride(from: r.start, through: r.end, by: 60 * 60 * 24)
        return days.map { day in
            let snacks = store.snacks(on: day, calendar: calendar)
            let avg = snacks.averageHunger()
            return TrendPoint(day: day, value: avg)
        }
    }

    // MARK: - Insights Generation

    public func generateInsights(for week: WeeklyStats) -> [InsightItem] {
        var insights: [InsightItem] = []

        // Flavor balance
        if let maxFlavor = week.flavorDist.max(by: { $0.value < $1.value }) {
            let title = "Your week tastes like \(maxFlavor.key.title)"
            let desc = "Most of your meals leaned toward \(maxFlavor.key.title.lowercased()) flavor."
            insights.append(InsightItem(title: title, description: desc, category: .flavor))
        }

        // Energy correlation
        if week.avgEnergy < 1.5 {
            insights.append(
                InsightItem(title: "Low Energy",
                            description: "Meals this week may have been too heavy or unbalanced.",
                            category: .energy)
            )
        } else if week.avgEnergy > 2.5 {
            insights.append(
                InsightItem(title: "High Energy",
                            description: "You seem to respond well to recent meals.",
                            category: .energy)
            )
        }

        // Satiety pattern
        if week.avgSatiety < 2 {
            insights.append(
                InsightItem(title: "Light meals",
                            description: "Most meals left you not fully satisfied.",
                            category: .satiety)
            )
        } else if week.avgSatiety > 4 {
            insights.append(
                InsightItem(title: "Heavy eating",
                            description: "Satiety scores are high; portion size could be reduced.",
                            category: .satiety)
            )
        }

        // Snack habits
        if let topReason = week.reasonDist.max(by: { $0.value < $1.value }) {
            let reasonLabel = topReason.key.label.lowercased()
            let desc = "Most snacks were triggered by \(reasonLabel)."
            insights.append(
                InsightItem(title: "Snack Trigger", description: desc, category: .habits)
            )
        }

        // Balance hint
        if week.flavorDist.values.filter({ $0 > 0 }).count < 3 {
            insights.append(
                InsightItem(title: "Limited Variety",
                            description: "Try exploring more flavor profiles for better balance.",
                            category: .balance)
            )
        }

        return insights
    }

    // MARK: - Utility

    private func stride(from start: Date, through end: Date, by seconds: TimeInterval) -> [Date] {
        var result: [Date] = []
        var current = start
        while current <= end {
            result.append(current)
            guard let next = Calendar.current.date(byAdding: .second, value: Int(seconds), to: current) else { break }
            current = next
        }
        return result
    }
}
