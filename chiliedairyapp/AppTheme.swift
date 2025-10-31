import Combine
import SwiftUI
import Foundation

// MARK: - Theme Variant

public enum ThemeVariant: String, CaseIterable, Equatable {
    case system
    case light
    case dark
}

// MARK: - AppTheme

@MainActor
public final class AppTheme: ObservableObject {
    // Published state
    @Published public private(set) var variant: ThemeVariant = .system
    @Published public private(set) var palette: Palette

    public init(variant: ThemeVariant = .system) {
        self.variant = variant
        self.palette = Palette(isDark: AppTheme.resolveIsDark(variant: variant))
    }

    public func setVariant(_ newValue: ThemeVariant) {
        guard newValue != variant else { return }
        variant = newValue
        palette = Palette(isDark: AppTheme.resolveIsDark(variant: newValue))
    }

    public var colorScheme: ColorScheme? {
        switch variant {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    private static func resolveIsDark(variant: ThemeVariant) -> Bool {
        switch variant {
        case .system: return UITraitCollection.current.userInterfaceStyle == .dark
        case .light:  return false
        case .dark:   return true
        }
    }
}

// MARK: - Palette

public extension AppTheme {
    struct Palette: Sendable {
        // Surfaces
        public let background: Color
        public let surface: Color
        public let surfaceAlt: Color
        public let border: Color

        // Text
        public let textPrimary: Color
        public let textSecondary: Color
        public let textMuted: Color

        // Accents
        public let accent: Color
        public let success: Color
        public let warning: Color
        public let danger: Color

        // Tabs coloring (semantic)
        public let dayTab: Color
        public let habitsTab: Color
        public let flavorTab: Color
        public let insightsTab: Color

        // Flavor tags
        public let flavorSweet: Color
        public let flavorSalty: Color
        public let flavorSpicy: Color
        public let flavorSour: Color
        public let flavorBitter: Color

        // Energy
        public let energyHigh: Color
        public let energyMid: Color
        public let energyLow: Color

        // Satiety
        public let satietyLow: Color
        public let satietyMid: Color
        public let satietyHigh: Color

        // Snack reasons
        public let reasonHunger: Color
        public let reasonStress: Color
        public let reasonRoutine: Color
        public let reasonCraveSweet: Color

        // Charts
        public let chartAxis: Color
        public let chartGrid: Color

        public init(isDark: Bool) {
            // Base
            background   = Color(isDark ? .black : .systemBackground)
            surface      = Color(isDark ? .secondarySystemBackground : .secondarySystemBackground)
            surfaceAlt   = Color(isDark ? UIColor(red: 0.11, green: 0.12, blue: 0.13, alpha: 1) :
                                         UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1))
            border       = Color(isDark ? .darkGray : .lightGray)

            textPrimary   = Color.primary
            textSecondary = Color.secondary
            textMuted     = Color.gray

            // Accents
            accent  = Color(red: 0.95, green: 0.27, blue: 0.18)
            success = Color.green
            warning = Color.orange
            danger  = Color.red

            // Tabs semantic
            dayTab      = Color.orange
            habitsTab   = Color.blue
            flavorTab   = Color.purple
            insightsTab = Color.green

            // Flavor tags
            flavorSweet  = Color.pink
            flavorSalty  = Color.blue
            flavorSpicy  = Color.red
            flavorSour   = Color.yellow
            flavorBitter = Color.brown

            // Energy
            energyHigh = Color.green
            energyMid  = Color.orange
            energyLow  = Color(red: 0.70, green: 0.20, blue: 0.25)

            // Satiety
            satietyLow  = Color(red: 0.98, green: 0.60, blue: 0.20)
            satietyMid  = Color(red: 0.95, green: 0.78, blue: 0.20)
            satietyHigh = Color(red: 0.25, green: 0.70, blue: 0.35)

            // Reasons
            reasonHunger     = Color.cyan
            reasonStress     = Color(red: 0.95, green: 0.45, blue: 0.30)
            reasonRoutine    = Color.indigo
            reasonCraveSweet = Color.pink

            // Charts
            chartAxis = Color.gray.opacity(isDark ? 0.6 : 0.4)
            chartGrid = Color.gray.opacity(isDark ? 0.25 : 0.18)
        }

        // Gradients
        public var accentGradient: LinearGradient {
            LinearGradient(colors: [accent, accent.opacity(0.6)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        public func satietyGradient(level: Int) -> LinearGradient {
            let c = satietyColor(level: level)
            return LinearGradient(colors: [c.opacity(0.85), c.opacity(0.45)],
                                  startPoint: .top, endPoint: .bottom)
        }

        public func flavorGradient(_ key: String) -> LinearGradient {
            let c = flavorColor(key)
            return LinearGradient(colors: [c.opacity(0.9), c.opacity(0.5)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        // Mapping helpers
        public func flavorColor(_ key: String) -> Color {
            switch key.lowercased() {
            case "sweet":  return flavorSweet
            case "salty":  return flavorSalty
            case "spicy":  return flavorSpicy
            case "sour":   return flavorSour
            case "bitter": return flavorBitter
            default:       return flavorTab
            }
        }

        public func energyColor(_ key: String) -> Color {
            switch key.lowercased() {
            case "high": return energyHigh
            case "mid", "medium": return energyMid
            case "low":  return energyLow
            default:     return insightsTab
            }
        }

        public func satietyColor(level: Int) -> Color {
            if level <= 2 { return satietyLow }
            if level == 3 { return satietyMid }
            return satietyHigh
        }

        public func reasonColor(_ key: String) -> Color {
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
    }
}

// MARK: - Typography

public struct FontTokens {
    public static let title: Font = .system(.title3, design: .rounded).weight(.semibold)
    public static let section: Font = .system(.headline, design: .rounded)
    public static let body: Font = .system(.body, design: .rounded)
    public static let small: Font = .system(.footnote, design: .rounded)
}

// MARK: - Layout Tokens

public struct LayoutTokens {
    public static let cornerRadius: CGFloat = 14
    public static let chipRadius: CGFloat = 18
    public static let cardPadding: CGFloat = 12
    public static let sectionSpacing: CGFloat = 12
    public static let gridSpacing: CGFloat = 8

    public static let shadowRegular: (Color, CGFloat, CGFloat) = (Color.black.opacity(0.08), 10, 0.5)
}
