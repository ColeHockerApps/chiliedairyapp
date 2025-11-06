import Combine
import SwiftUI
import Foundation

@main
struct ChilieDiaryApp: App {
    
    @State private var showPrivacyGate = true
    @State private var showBootOverlay = true

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            Orientation.allowAll
            ? [.portrait, .landscapeLeft, .landscapeRight]
            : [.portrait]
        }
    }
    
    
    
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showBootOverlay = false
                        }
                    }
                }
                .fullScreenCover(isPresented: $showPrivacyGate) {
                    PrivacyScreen(
                        startLink: AppPrivacy.privacypage,
                        onClose: { showPrivacyGate = false }
                    )
                    .ignoresSafeArea()
                }
                .overlay {
                    if showBootOverlay { BootOverlay() }
                }
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





private struct BootOverlay: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().progressViewStyle(.circular)
                Text("Loading")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(0.9)
            }
        }
        .transition(.opacity)
    }
}
