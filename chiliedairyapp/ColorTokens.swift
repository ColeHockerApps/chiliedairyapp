import Combine
import SwiftUI
import Foundation

// MARK: - Color Tokens

public struct ColorTokens {
    // Basic surfaces
    public static func cardBackground(_ palette: AppTheme.Palette, elevated: Bool = false) -> Color {
        elevated ? palette.surfaceAlt : palette.surface
    }

    public static func listRowBackground(_ palette: AppTheme.Palette) -> Color {
        palette.surface
    }

    public static func separator(_ palette: AppTheme.Palette) -> Color {
        palette.border
    }

    public static func overlay(_ palette: AppTheme.Palette, level: Int = 1) -> Color {
        let clamped = max(0, min(level, 3))
        let base = palette.textPrimary
        switch clamped {
        case 0: return base.opacity(0.02)
        case 1: return base.opacity(0.06)
        case 2: return base.opacity(0.12)
        default: return base.opacity(0.18)
        }
    }

    // Chips / Pills
    public static func chipBackground(selected: Bool, palette: AppTheme.Palette) -> Color {
        selected ? palette.accent.opacity(0.18) : palette.surfaceAlt
    }

    public static func chipBorder(selected: Bool, palette: AppTheme.Palette) -> Color {
        selected ? palette.accent.opacity(0.55) : palette.border.opacity(0.6)
    }

    public static func chipText(selected: Bool, palette: AppTheme.Palette) -> Color {
        selected ? palette.accent : palette.textPrimary
    }

    // Tabs tint
    public static func dayTabTint(_ palette: AppTheme.Palette) -> Color { palette.dayTab }
    public static func habitsTabTint(_ palette: AppTheme.Palette) -> Color { palette.habitsTab }
    public static func flavorTabTint(_ palette: AppTheme.Palette) -> Color { palette.flavorTab }
    public static func insightsTabTint(_ palette: AppTheme.Palette) -> Color { palette.insightsTab }

    // Flavor tags
    public static func flavorFill(_ key: String, palette: AppTheme.Palette) -> Color {
        palette.flavorColor(key).opacity(0.35)
    }

    public static func flavorStroke(_ key: String, palette: AppTheme.Palette) -> Color {
        palette.flavorColor(key)
    }

    public static func flavorGradient(_ key: String, palette: AppTheme.Palette) -> LinearGradient {
        palette.flavorGradient(key)
    }

    public static func flavorLegendOrder() -> [String] {
        ["Sweet", "Salty", "Spicy", "Sour", "Bitter"]
    }

    public static func flavorLegendColors(_ palette: AppTheme.Palette) -> [Color] {
        flavorLegendOrder().map { palette.flavorColor($0) }
    }

    // Energy meter
    public static func energyFill(_ key: String, palette: AppTheme.Palette) -> Color {
        palette.energyColor(key)
    }

    public static func energyBackground(_ palette: AppTheme.Palette) -> Color {
        palette.chartGrid
    }

    // Satiety meter
    public static func satietyFill(level: Int, palette: AppTheme.Palette) -> Color {
        palette.satietyColor(level: level)
    }

    public static func satietyBackground(_ palette: AppTheme.Palette) -> Color {
        palette.chartGrid
    }

    public static func satietyGradient(level: Int, palette: AppTheme.Palette) -> LinearGradient {
        palette.satietyGradient(level: level)
    }

    // Snack reasons
    public static func reasonBadgeBackground(_ key: String, palette: AppTheme.Palette) -> Color {
        palette.reasonColor(key).opacity(0.18)
    }

    public static func reasonBadgeText(_ key: String, palette: AppTheme.Palette) -> Color {
        palette.reasonColor(key)
    }

    // Charts
    public static func chartAxis(_ palette: AppTheme.Palette) -> Color { palette.chartAxis }
    public static func chartGrid(_ palette: AppTheme.Palette) -> Color { palette.chartGrid }

    // Accent
    public static func accent(_ palette: AppTheme.Palette) -> Color { palette.accent }
    public static func accentGradient(_ palette: AppTheme.Palette) -> LinearGradient { palette.accentGradient }
}

// MARK: - View Helpers

public extension View {
    func cardStyle(_ palette: AppTheme.Palette, elevated: Bool = false, radius: CGFloat = LayoutTokens.cornerRadius) -> some View {
        self
            .padding(LayoutTokens.cardPadding)
            .background(ColorTokens.cardBackground(palette, elevated: elevated))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func chipStyle(selected: Bool, palette: AppTheme.Palette) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ColorTokens.chipBackground(selected: selected, palette: palette))
            .overlay(
                RoundedRectangle(cornerRadius: LayoutTokens.chipRadius)
                    .stroke(ColorTokens.chipBorder(selected: selected, palette: palette), lineWidth: 1)
            )
            .clipShape(Capsule(style: .circular))
    }

    func sectionHeaderStyle(_ palette: AppTheme.Palette) -> some View {
        self
            .foregroundStyle(palette.textSecondary)
            .font(FontTokens.section)
            .textCase(nil)
    }
}
