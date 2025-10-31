import Combine
import SwiftUI
import Foundation

// MARK: - Meal Entry

public struct MealEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public var date: Date
    public var name: String
    public var type: MealType
    public var satietyLevel: Int
    public var energyAfter: EnergyLevel
    public var flavorTags: [FlavorTag]
    public var notes: String?

    public init(
        id: UUID = UUID(),
        date: Date = .now,
        name: String,
        type: MealType = .meal,
        satietyLevel: Int = 3,
        energyAfter: EnergyLevel = .medium,
        flavorTags: [FlavorTag] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.type = type
        self.satietyLevel = max(1, min(satietyLevel, 5))
        self.energyAfter = energyAfter
        self.flavorTags = flavorTags
        self.notes = notes
    }
}

// MARK: - Snack Event

public struct SnackEvent: Identifiable, Codable, Hashable {
    public let id: UUID
    public var date: Date
    public var reason: SnackReason
    public var hungerLevel: Int
    public var note: String?

    public init(
        id: UUID = UUID(),
        date: Date = .now,
        reason: SnackReason,
        hungerLevel: Int = 3,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.reason = reason
        self.hungerLevel = max(1, min(hungerLevel, 5))
        self.note = note
    }
}

// MARK: - MealType

public enum MealType: String, Codable, CaseIterable, Hashable {
    case meal
    case breakfast
    case lunch
    case dinner
    case snack

    public var title: String {
        switch self {
        case .meal: return "Meal"
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
}

// MARK: - EnergyLevel

public enum EnergyLevel: String, Codable, CaseIterable, Hashable {
    case low
    case medium
    case high

    public var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// MARK: - FlavorTag

public enum FlavorTag: String, Codable, CaseIterable, Hashable {
    case sweet
    case salty
    case spicy
    case sour
    case bitter

    public var title: String {
        rawValue.capitalized
    }
}

// MARK: - SnackReason

public enum SnackReason: String, Codable, CaseIterable, Hashable {
    case hunger
    case stress
    case routine
    case craveSweet

    public var label: String {
        switch self {
        case .hunger: return "Hunger"
        case .stress: return "Stress"
        case .routine: return "Routine"
        case .craveSweet: return "Crave Sweet"
        }
    }
}

// MARK: - DailySummary

public struct DailySummary: Identifiable, Codable, Hashable {
    public let id: UUID
    public var date: Date
    public var totalMeals: Int
    public var avgSatiety: Double
    public var avgEnergy: Double
    public var favoriteFlavor: FlavorTag?

    public init(
        id: UUID = UUID(),
        date: Date,
        totalMeals: Int,
        avgSatiety: Double,
        avgEnergy: Double,
        favoriteFlavor: FlavorTag? = nil
    ) {
        self.id = id
        self.date = date
        self.totalMeals = totalMeals
        self.avgSatiety = avgSatiety
        self.avgEnergy = avgEnergy
        self.favoriteFlavor = favoriteFlavor
    }
}

// MARK: - Insight Model

public struct InsightItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var date: Date
    public var title: String
    public var description: String
    public var category: InsightCategory

    public init(
        id: UUID = UUID(),
        date: Date = .now,
        title: String,
        description: String,
        category: InsightCategory
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.category = category
    }
}

public enum InsightCategory: String, Codable, CaseIterable, Hashable {
    case balance
    case energy
    case satiety
    case habits
    case flavor

    public var label: String { rawValue.capitalized }
}

// MARK: - Codable Helpers

public extension Array where Element == MealEntry {
    func averageSatiety() -> Double {
        guard !isEmpty else { return 0 }
        return Double(map { $0.satietyLevel }.reduce(0, +)) / Double(count)
    }

    func averageEnergy() -> Double {
        guard !isEmpty else { return 0 }
        let mapVal: [EnergyLevel: Double] = [.low: 1, .medium: 2, .high: 3]
        let vals = map { mapVal[$0.energyAfter] ?? 2 }
        return vals.reduce(0, +) / Double(vals.count)
    }

    func mostFrequentFlavor() -> FlavorTag? {
        let counts = Dictionary(grouping: flatMap { $0.flavorTags }, by: { $0 })
            .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

public extension Array where Element == SnackEvent {
    func averageHunger() -> Double {
        guard !isEmpty else { return 0 }
        return Double(map { $0.hungerLevel }.reduce(0, +)) / Double(count)
    }

    func reasonDistribution() -> [SnackReason: Int] {
        Dictionary(grouping: self, by: { $0.reason })
            .mapValues { $0.count }
    }
}
