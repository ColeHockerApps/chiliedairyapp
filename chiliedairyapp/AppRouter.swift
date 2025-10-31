import Combine
import SwiftUI
import Foundation

public struct AppRouter: View {
    @Environment(\.colorScheme) private var scheme
    @State private var tab: Tab = .day

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            DayLogScreen()
                .tabItem { tabLabel(title: "Day", system: "calendar") }
                .tag(Tab.day)

            HabitsScreen()
                .tabItem { tabLabel(title: "Habits", system: "hand.tap") }
                .tag(Tab.habits)

            FlavorStatsScreen()
                .tabItem { tabLabel(title: "Flavor", system: "chart.pie") }
                .tag(Tab.flavor)

            InsightsScreen()
                .tabItem { tabLabel(title: "Insights", system: "lightbulb") }
                .tag(Tab.insights)

            SettingsScreen()
                .tabItem { tabLabel(title: "Settings", system: "gear") }
                .tag(Tab.settings)
        }
        .tint(tintFor(tab))
        .onChange(of: tab) { _ in HapticsManager.shared.selection() }
        .background(palette.background.ignoresSafeArea())
    }

    private func tabLabel(title: String, system: String) -> some View {
        Label(title, systemImage: system)
    }

    private func tintFor(_ tab: Tab) -> Color {
        switch tab {
        case .day:      return ColorTokens.dayTabTint(palette)
        case .habits:   return ColorTokens.habitsTabTint(palette)
        case .flavor:   return ColorTokens.flavorTabTint(palette)
        case .insights: return ColorTokens.insightsTabTint(palette)
        case .settings: return palette.accent
        }
    }

    private enum Tab: Hashable {
        case day, habits, flavor, insights, settings
    }
}
