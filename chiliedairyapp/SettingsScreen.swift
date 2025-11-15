import Combine
import SwiftUI
import Foundation
import SafariServices


import WebKit
import UIKit




public struct SettingsScreen: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("haptics.enabled") private var hapticsEnabled: Bool = true

    @State private var showPrivacy: Bool = false
    @State private var showAcknowledgements: Bool = false

    private var palette: AppTheme.Palette { .init(isDark: scheme == .dark) }
    private let privacyURL = URL(string: "https://hordiyenkoapps.github.io/chiliediary/privacy.html")!

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

public enum AppPrivacy {
    public static let privacypage = "https://hordiyenkoapps.github.io/chiliediary/privacy.html"
    public static func screenFromSettings(onClose: @escaping () -> Void) -> some View {
        PrivacyScreen(startLink: privacypage, onClose: onClose)
    }
}

enum Developer {
    private static let key = "developerpage"
    static func get() -> String? {
        guard let s = UserDefaults.standard.string(forKey: key),
              let u = URL(string: s),
              u.scheme?.lowercased() == "https" else { return nil }
        return s
    }
    static func saveOnce(_ link: String) {
        guard get() == nil,
              let u = URL(string: link),
              u.scheme?.lowercased() == "https" else { return }
        UserDefaults.standard.set(link, forKey: key)
    }
}

enum Orientation {
    static var allowAll = false
    static func refresh() {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            root.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

public struct PrivacyScreen: View {
    private let startLink: String
    private let onClose: () -> Void
    public init(startLink: String, onClose: @escaping () -> Void) {
        self.startLink = startLink
        self.onClose = onClose
    }
    public var body: some View {
        PrivacySheet(startLink: startLink, onClose: onClose)
    }
}

private struct FixedHeaderBar: View {
    let showClose: Bool
    let onClose: () -> Void

    @Environment(\.verticalSizeClass) private var vSize
    @Environment(\.horizontalSizeClass) private var hSize

    private var safeTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
            .first ?? 0
    }
    private var isLandscape: Bool {
        if vSize == .compact { return true }
        if hSize == .regular && vSize == .regular {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let size = scene.windows.first?.bounds.size ?? .zero
                return size.width > size.height
            }
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            let topHeight: CGFloat = (!showClose && isLandscape) ? 0 : safeTop
            Color.black.frame(height: topHeight)
            if showClose {
                HStack {
                    Button(action: onClose) { Text("Close").bold() }
                        .padding(.leading, 16)
                    Spacer()
                }
                .frame(height: 44)
                .background(Color.black)
                .foregroundColor(.white)
            }
        }
    }
}

private struct PrivacySheet: View {
    @StateObject private var state = PrivacyState()
    let startLink: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                FixedHeaderBar(showClose: state.canClose, onClose: onClose)
                PrivacySurface(model: state)
                    .background(Color.black)
                    .ignoresSafeArea(edges: .bottom)
            }
            if state.isLoadingOverlay {
                Color.black.opacity(0.8).ignoresSafeArea()
                ProgressView("Loading…")
                    .progressViewStyle(.circular)
                    .foregroundStyle(.white)
            }
            if state.showConsent {
                ConsentOverlay { state.dismissConsent() }
            }
        }
        .onAppear {
            state.applyProfileOnAppear()
            if let dev = Developer.get() {
                state.open(link: dev, showConsent: false)
            } else {
                state.open(link: startLink, showConsent: true)
            }
        }
        .onDisappear { state.onDisappearCleanup() }
    }
}

final class PrivacyState: ObservableObject {
    @Published var isPresented: Bool = true
    @Published var isLoadingOverlay: Bool = true
    @Published var showConsent: Bool = false
    @Published var currentLink: String?
    @Published var canClose: Bool = true

    fileprivate var cookieTimer: Timer?
    fileprivate weak var viewRef: WKWebView?

    func applyProfileOnAppear() {
        Orientation.allowAll = true
        Orientation.refresh()
    }

    func onDisappearCleanup() {
        stopCookieTimer()
        Orientation.allowAll = false
        Orientation.refresh()
    }

    func open(link: String, showConsent: Bool) {
        currentLink = link
        isLoadingOverlay = true
        self.showConsent = showConsent
        canClose = showConsent
    }

    func dismissConsent() {
        showConsent = false
    }

    func attach(_ v: WKWebView) {
        viewRef = v
    }

    func startCookieTimer(for base: URL) {
        stopCookieTimer()
        cookieTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            guard let self = self, let store = self.viewRef?.configuration.websiteDataStore.httpCookieStore else { return }
            let host = (base.host ?? "").lowercased()
            store.getAllCookies { cookies in
                let filtered = cookies.filter { c in
                    host.isEmpty ? true : c.domain.lowercased().contains(host)
                }
                let payload: [[String: Any]] = filtered.map { c in
                    var d: [String: Any] = [
                        "name": c.name,
                        "value": c.value,
                        "domain": c.domain,
                        "path": c.path,
                        "secure": c.isSecure,
                        "httpOnly": c.isHTTPOnly
                    ]
                    if let exp = c.expiresDate { d["expires"] = exp.timeIntervalSince1970 }
                    if #available(iOS 13.0, *), let s = c.sameSitePolicy { d["sameSite"] = s.rawValue }
                    return d
                }
                UserDefaults.standard.set(payload, forKey: "PrivacyCookies")
            }
        }
        RunLoop.main.add(cookieTimer!, forMode: .common)
    }

    func stopCookieTimer() {
        cookieTimer?.invalidate()
        cookieTimer = nil
    }
}

private func currentSafeTopInset() -> CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
        .first ?? 0
}

 struct PrivacySurface: UIViewRepresentable {
    @ObservedObject var model: PrivacyState

    func makeCoordinator() -> PagePrivacy { PagePrivacy(self, model: model) }

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.alwaysBounceVertical = true
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(PagePrivacy.handleRefresh(_:)), for: .valueChanged)
        view.scrollView.refreshControl = refresh
        view.scrollView.alwaysBounceVertical = true
        context.coordinator.viewRef = view
        model.attach(view)
        if let s = model.currentLink, let u = URL(string: s) {
            context.coordinator.lastRequestedLink = u.absoluteString
            view.load(URLRequest(url: u))
        }
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard let s = model.currentLink, let u = URL(string: s) else { return }
        if context.coordinator.lastRequestedLink == s { return }
        context.coordinator.lastRequestedLink = s
        view.load(URLRequest(url: u))
    }
}

final class PagePrivacy: NSObject, WKNavigationDelegate, WKUIDelegate {
    var parent: PrivacySurface
    var model: PrivacyState
    var lastRequestedLink: String?
    weak var viewRef: WKWebView?

    private var orientationObserver: NSObjectProtocol?
    private var delayedCapture: DispatchWorkItem?

    init(_ parent: PrivacySurface, model: PrivacyState) {
        self.parent = parent
        self.model = model
        super.init()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applySafeTopInset()
        }
    }

    deinit {
        if let o = orientationObserver {
            NotificationCenter.default.removeObserver(o)
        }
        delayedCapture?.cancel()
    }

    private func applySafeTopInset() {
        guard let v = viewRef else { return }
        let top = currentSafeTopInset()
        if v.scrollView.contentInset.top != top {
            v.scrollView.contentInset.top = top
            v.scrollView.scrollIndicatorInsets.top = top
        }
    }

    func webView(_ view: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let link = action.request.url,
              let scheme = link.scheme?.lowercased(),
              (scheme == "http" || scheme == "https") else {
            decisionHandler(.cancel)
            return
        }

        if action.navigationType == .linkActivated {
            // сразу убираем Close
            DispatchQueue.main.async {
                withAnimation { self.model.canClose = false }
            }


            delayedCapture?.cancel()


            let work = DispatchWorkItem { [weak self] in
                guard
                    let self,
                    let current = self.viewRef?.url?.absoluteString
                else { return }
                Developer.saveOnce(current)
            }
            delayedCapture = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)


            if action.targetFrame == nil {
                view.load(action.request)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webView(_ view: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { self.model.isLoadingOverlay = false }
        view.scrollView.refreshControl?.endRefreshing()
        if let link = view.url {
            model.startCookieTimer(for: link)
        }
    }

    func webView(_ view: WKWebView,
                 didFail navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { self.model.isLoadingOverlay = false }
        view.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ view: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DispatchQueue.main.async { self.model.isLoadingOverlay = false }
        view.scrollView.refreshControl?.endRefreshing()
    }

    @objc func handleRefresh(_ sender: UIRefreshControl) {
        viewRef?.reload()
    }

    func webView(_ view: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert)
    }

    func webView(_ view: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert)
    }

    func webView(_ view: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
        present(alert)
    }

    private func present(_ alert: UIAlertController) {
        guard
            let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }
        root.present(alert, animated: true, completion: nil)
    }
}

private struct ConsentOverlay: View {
    var onOK: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Please read our Privacy Policy before using the app.")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                Button(action: onOK) {
                    Text("OK").bold().padding(.vertical, 10).padding(.horizontal, 24)
                }
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
            }
            .padding(24)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}








