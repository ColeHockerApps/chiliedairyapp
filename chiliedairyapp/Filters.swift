import Combine
import SwiftUI
import Foundation

// MARK: - Date Range

public struct DateRange: Equatable, Hashable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = min(start, end)
        self.end = max(start, end)
    }

    public func contains(_ date: Date) -> Bool {
        (start ... end).contains(date)
    }

    public func clamp(_ date: Date) -> Date {
        if date < start { return start }
        if date > end { return end }
        return date
    }

    public func shifted(days: Int, calendar: Calendar = .current) -> DateRange {
        let s = calendar.date(byAdding: .day, value: days, to: start) ?? start
        let e = calendar.date(byAdding: .day, value: days, to: end) ?? end
        return DateRange(start: s, end: e)
    }
}

// MARK: - Date Range Presets

public enum DateRangeKind: Equatable {
    case today
    case last7
    case thisWeek
    case thisMonth
    case custom(DateRange)

    public func resolve(calendar: Calendar = .current) -> DateRange {
        let now = Date()
        switch self {
        case .today:
            let s = calendar.startOfDay(for: now)
            let e = calendar.date(byAdding: .day, value: 1, to: s)!.addingTimeInterval(-1)
            return .init(start: s, end: e)
        case .last7:
            let startOfToday = calendar.startOfDay(for: now)
            let e = calendar.date(byAdding: .second, value: (24 * 60 * 60) - 1, to: startOfToday)!
            let s = calendar.date(byAdding: .day, value: -6, to: startOfToday)!
            return .init(start: s, end: e)
        case .thisWeek:
            let s = calendar.startOfWeek(for: now)
            let e = calendar.date(byAdding: .day, value: 7, to: s)!.addingTimeInterval(-1)
            return .init(start: s, end: e)
        case .thisMonth:
            let (s, e) = calendar.monthBounds(for: now)
            return .init(start: s, end: e)
        case .custom(let r):
            return r
        }
    }
}

// MARK: - Calendar helpers

public extension Calendar {
    func startOfWeek(for at: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: at)
        return self.date(from: comps) ?? startOfDay(for: at)
    }

    func monthBounds(for at: Date) -> (Date, Date) {
        let s = dateInterval(of: .month, for: at)?.start ?? startOfDay(for: at)
        let e = self.date(byAdding: DateComponents(month: 1, second: -1), to: s) ?? s
        return (s, e)
    }

    func dayInterval(for at: Date) -> DateRange {
        let s = startOfDay(for: at)
        let e = self.date(byAdding: .day, value: 1, to: s)!.addingTimeInterval(-1)
        return DateRange(start: s, end: e)
    }
}

// MARK: - Sort Keys

public enum MealSortKey {
    case byTimeAsc
    case byTimeDesc
    case bySatietyDesc
    case byEnergyDesc
    case byName
}

public enum SnackSortKey {
    case byTimeAsc
    case byTimeDesc
    case byHungerDesc
    case byReason
}

// MARK: - Time Of Day

public enum TimeBucket: String, CaseIterable {
    case morning    // 05:00-11:59
    case afternoon  // 12:00-16:59
    case evening    // 17:00-21:59
    case night      // 22:00-04:59

    public static func bucket(for date: Date, calendar: Calendar = .current) -> TimeBucket {
        let h = calendar.component(.hour, from: date)
        switch h {
        case 5...11: return .morning
        case 12...16: return .afternoon
        case 17...21: return .evening
        default: return .night
        }
    }
}

// MARK: - Filters (Meals)

public struct MealFilters {
    public var rangeKind: DateRangeKind = .today
    public var flavors: Set<FlavorTag> = []
    public var types: Set<MealType> = []
    public var minSatiety: Int? = nil
    public var energyIn: Set<EnergyLevel> = []
    public var search: String = ""

    public init() {}
}

public func filterMeals(
    _ source: [MealEntry],
    filters: MealFilters,
    calendar: Calendar = .current
) -> [MealEntry] {
    let range = filters.rangeKind.resolve(calendar: calendar)
    let needle = filters.search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    return source.filter { m in
        guard range.contains(m.date) else { return false }
        if !filters.flavors.isEmpty && filters.flavors.isDisjoint(with: Set(m.flavorTags)) { return false }
        if !filters.types.isEmpty && !filters.types.contains(m.type) { return false }
        if let minS = filters.minSatiety, m.satietyLevel < minS { return false }
        if !filters.energyIn.isEmpty && !filters.energyIn.contains(m.energyAfter) { return false }
        if !needle.isEmpty {
            let hay = "\(m.name) \(m.notes ?? "")".lowercased()
            if !hay.contains(needle) { return false }
        }
        return true
    }
}

public func sortMeals(_ arr: [MealEntry], by key: MealSortKey) -> [MealEntry] {
    switch key {
    case .byTimeAsc:   return arr.sorted { $0.date < $1.date }
    case .byTimeDesc:  return arr.sorted { $0.date > $1.date }
    case .bySatietyDesc:
        return arr.sorted { ($0.satietyLevel, $0.date) > ($1.satietyLevel, $1.date) }
    case .byEnergyDesc:
        let map: [EnergyLevel: Int] = [.low: 1, .medium: 2, .high: 3]
        return arr.sorted { (map[$0.energyAfter] ?? 0, $0.date) > (map[$1.energyAfter] ?? 0, $1.date) }
    case .byName:
        return arr.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Filters (Snacks)

public struct SnackFilters {
    public var rangeKind: DateRangeKind = .today
    public var reasons: Set<SnackReason> = []
    public var minHunger: Int? = nil
    public var search: String = ""

    public init() {}
}

public func filterSnacks(
    _ source: [SnackEvent],
    filters: SnackFilters,
    calendar: Calendar = .current
) -> [SnackEvent] {
    let range = filters.rangeKind.resolve(calendar: calendar)
    let needle = filters.search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    return source.filter { s in
        guard range.contains(s.date) else { return false }
        if !filters.reasons.isEmpty && !filters.reasons.contains(s.reason) { return false }
        if let minH = filters.minHunger, s.hungerLevel < minH { return false }
        if !needle.isEmpty {
            let hay = (s.note ?? "").lowercased()
            if !hay.contains(needle) { return false }
        }
        return true
    }
}

public func sortSnacks(_ arr: [SnackEvent], by key: SnackSortKey) -> [SnackEvent] {
    switch key {
    case .byTimeAsc:   return arr.sorted { $0.date < $1.date }
    case .byTimeDesc:  return arr.sorted { $0.date > $1.date }
    case .byHungerDesc:
        return arr.sorted { ($0.hungerLevel, $0.date) > ($1.hungerLevel, $1.date) }
    case .byReason:
        return arr.sorted { $0.reason.rawValue < $1.reason.rawValue }
    }
}

// MARK: - Grouping

public func groupMealsByDay(
    _ meals: [MealEntry],
    calendar: Calendar = .current
) -> [(day: Date, items: [MealEntry])] {
    let groups = Dictionary(grouping: meals) { calendar.startOfDay(for: $0.date) }
    let sortedDays = groups.keys.sorted()
    return sortedDays.map { d in
        (day: d, items: groups[d]!.sorted { $0.date < $1.date })
    }
}

public func groupSnacksByDay(
    _ snacks: [SnackEvent],
    calendar: Calendar = .current
) -> [(day: Date, items: [SnackEvent])] {
    let groups = Dictionary(grouping: snacks) { calendar.startOfDay(for: $0.date) }
    let sortedDays = groups.keys.sorted()
    return sortedDays.map { d in
        (day: d, items: groups[d]!.sorted { $0.date < $1.date })
    }
}

// MARK: - Aggregations (lightweight)

public struct FlavorDistribution {
    public let counts: [FlavorTag: Int]
    public let total: Int
    public init(counts: [FlavorTag: Int]) {
        self.counts = counts
        self.total = counts.values.reduce(0, +)
    }
    public func ratio(_ tag: FlavorTag) -> Double {
        guard total > 0 else { return 0 }
        return Double(counts[tag] ?? 0) / Double(total)
    }
}

public func flavorDistribution(from meals: [MealEntry]) -> FlavorDistribution {
    var bucket: [FlavorTag: Int] = [:]
    for m in meals {
        for t in Set(m.flavorTags) {
            bucket[t, default: 0] += 1
        }
    }
    return FlavorDistribution(counts: bucket)
}

public struct EnergyAverages {
    public let low: Double
    public let medium: Double
    public let high: Double
}

public func energyAverages(by bucket: TimeBucket, meals: [MealEntry], calendar: Calendar = .current) -> EnergyAverages {
    let subset = meals.filter { TimeBucket.bucket(for: $0.date, calendar: calendar) == bucket }
    let map: [EnergyLevel: Double] = [.low: 1, .medium: 2, .high: 3]
    func avg(_ level: EnergyLevel) -> Double {
        let vals = subset.filter { $0.energyAfter == level }.map { map[$0.energyAfter] ?? 0 }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0,+) / Double(vals.count)
    }
    return .init(low: avg(.low), medium: avg(.medium), high: avg(.high))
}
