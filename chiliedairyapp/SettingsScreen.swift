import Combine
import SwiftUI
import Foundation
import SafariServices

public struct SettingsScreen: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("haptics.enabled") private var hapticsEnabled: Bool = true

    @State private var showPrivacy: Bool = false
    @State private var showAcknowledgements: Bool = false

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }
    private let privacyURL = URL(string: "https://www.termsfeed.com/live/3961723a-b9a4-4460-ba7f-c2ad67349e7b")!

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptics", systemImage: AppIcons.haptics)
                    }
                    .onChange(of: hapticsEnabled) { HapticsManager.shared.setEnabled($0) }

                    Button {
                        showPrivacy = true
                        HapticsManager.shared.selection()
                    } label: {
                        Label("Privacy Policy", systemImage: AppIcons.privacy)
                    }

//                    Button {
//                        showAcknowledgements = true
//                        HapticsManager.shared.selection()
//                    } label: {
//                        Label("Acknowledgements", systemImage: AppIcons.info)
//                    }
                }

                Section("About") {
                    HStack {
                        Label("App", systemImage: AppIcons.appBadge)
                        Spacer()
                        Text("Chilie Diary").foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Version", systemImage: AppIcons.tag)
                        Spacer()
                        Text(appVersionString()).foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPrivacy) {
                SafariSheet(url: privacyURL)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showAcknowledgements) {
                AcksSheet()
                    .presentationDetents([.medium, .large])
            }
            .tint(ColorTokens.insightsTabTint(palette))
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
        }
    }

    private func appVersionString() -> String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// MARK: - Safari (privacy)

fileprivate struct SafariSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let c = SFSafariViewController(url: url)
        c.preferredControlTintColor = UIColor.label
        return c
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Simple acks

fileprivate struct AcksSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Thanks for using Chilie Diary.")
                        .font(.headline)
                    Text("This app uses Apple frameworks (SwiftUI, Combine) and standard SF Symbols. All data is stored locally on your device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("Acknowledgements")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - AppIcons (local fallbacks if needed)

extension AppIcons {
    //public static let privacy = "lock.shield"
    public static let haptics = "waveform"
    public static let appBadge = "app.badge"
    public static let tag = "tag"
   // public static let info = "info.circle"
}
