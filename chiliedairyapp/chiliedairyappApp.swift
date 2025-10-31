import Combine
import SwiftUI
import Foundation

@main
struct ChilieDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

/// Root tab container only. Screens are defined in their own files.
struct RootTabView: View {
    @State private var selected = 0

    var body: some View {
        TabView(selection: $selected) {
            // Day Log
            DayLogScreen()
                .tabItem { Label("Day Log", systemImage: "list.bullet.rectangle") }
                .tag(0)

            // Habits & Hunger
            HabitsScreen()
                .tabItem { Label("Habits", systemImage: "chart.bar.doc.horizontal") }
                .tag(1)

            // Flavor Stats
            FlavorStatsScreen()
                .tabItem { Label("Flavor", systemImage: "circle.grid.3x3.fill") }
                .tag(2)

            // Insights
            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "bolt.circle") }
                .tag(3)

            // Settings (privacy logic inside SettingsScreen)
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
    }
}
