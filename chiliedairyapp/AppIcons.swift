import Combine
import SwiftUI
import Foundation

// MARK: - App Icons Mapping

public struct AppIcons {
    // Tab bar icons
    public static let dayLogTab = "list.bullet.rectangle"
    public static let habitsTab = "chart.bar.doc.horizontal"
    public static let flavorTab = "circle.grid.3x3.fill"
    public static let insightsTab = "bolt.circle"
    public static let settingsTab = "gearshape"

    // Meals
    public static let breakfast = "sunrise.fill"
    public static let lunch = "fork.knife"
    public static let dinner = "moon.stars.fill"
    public static let snack = "takeoutbag.and.cup.and.straw.fill"

    // Flavors
    public static let sweet = "cube.fill"
    public static let salty = "drop.fill"
    public static let spicy = "flame.fill"
    public static let sour = "leaf.fill"
    public static let bitter = "circle.grid.2x1.left.filled"

    // Energy
    public static let energyHigh = "bolt.fill"
    public static let energyMid = "bolt"
    public static let energyLow = "zzz"

    // Satiety
    public static let satietyLow = "circle.lefthalf.filled"
    public static let satietyMid = "circle"
    public static let satietyHigh = "circle.fill"

    // Snack reasons
    public static let reasonHunger = "fork.knife.circle"
    public static let reasonStress = "exclamationmark.bubble"
    public static let reasonRoutine = "clock"
    public static let reasonCraveSweet = "cup.and.saucer.fill"

    // Feedback & insights
    public static let check = "checkmark.seal.fill"
    public static let idea = "lightbulb"
    public static let warning = "exclamationmark.triangle.fill"
    public static let info = "info.circle"
    public static let trendUp = "chart.line.uptrend.xyaxis"
    public static let trendDown = "chart.line.downtrend.xyaxis"

    // Settings
    public static let theme = "circle.lefthalf.fill"
    public static let privacy = "hand.raised.fill"
    public static let reset = "trash"
    public static let export = "square.and.arrow.up"
    public static let about = "questionmark.circle"

    // MARK: - Utility

    public static func flavorIcon(for key: String) -> String {
        switch key.lowercased() {
        case "sweet":  return sweet
        case "salty":  return salty
        case "spicy":  return spicy
        case "sour":   return sour
        case "bitter": return bitter
        default:       return flavorTab
        }
    }

    public static func energyIcon(for key: String) -> String {
        switch key.lowercased() {
        case "high": return energyHigh
        case "mid", "medium": return energyMid
        case "low": return energyLow
        default: return energyMid
        }
    }

    public static func reasonIcon(for key: String) -> String {
        switch key.lowercased() {
        case "hunger":        return reasonHunger
        case "stress":        return reasonStress
        case "routine":       return reasonRoutine
        case "crave sweet",
             "cravesweet",
             "sweet":        return reasonCraveSweet
        default:              return habitsTab
        }
    }

    public static func satietyIcon(level: Int) -> String {
        if level <= 2 { return satietyLow }
        if level == 3 { return satietyMid }
        return satietyHigh
    }

    public static func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return dayLogTab
        case 1: return habitsTab
        case 2: return flavorTab
        case 3: return insightsTab
        case 4: return settingsTab
        default: return "circle"
        }
    }
}
