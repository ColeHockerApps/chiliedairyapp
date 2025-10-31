import Combine
import SwiftUI
import Foundation
import UIKit

@MainActor
public final class HapticsManager: ObservableObject {
    public static let shared = HapticsManager()

    @AppStorage("haptics.enabled") public var isEnabled: Bool = true
    @Published public private(set) var lastEvent: HapticEvent? = nil

    private var lastImpactAt: TimeInterval = 0
    private let minInterval: TimeInterval = 0.04

    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGen = UIImpactFeedbackGenerator(style: .rigid)
    private let softGen = UIImpactFeedbackGenerator(style: .soft)

    private let notifyGen = UINotificationFeedbackGenerator()
    private let selectGen = UISelectionFeedbackGenerator()

    private init() {
        prepareAll()
    }

    // MARK: - Public API

    public func setEnabled(_ flag: Bool) { isEnabled = flag }

    public func play(_ event: HapticEvent) {
        guard shouldFire() else { return }
        lastEvent = event
        switch event {
        case .tap: tap()
        case .select: selection()
        case .confirm: confirm()
        case .warn: warning()
        case .error: error()
        case .impactLight: light()
        case .impactMedium: medium()
        case .impactHeavy: heavy()
        case .impactSoft: soft()
        case .impactRigid: rigid()
        case .burst(let count, let spacing): burst(count: count, spacing: spacing)
        }
    }

    // Convenience aliases used across the app
    public func tap()      { light() }
    public func confirm()  { success() }

    public func light()  { impact(lightGen) }
    public func medium() { impact(mediumGen) }
    public func heavy()  { impact(heavyGen) }
    public func soft()   { impact(softGen) }
    public func rigid()  { impact(rigidGen) }

    public func success() { notify(.success) }
    public func warning() { notify(.warning) }
    public func error()   { notify(.error) }

    public func selection() {
        guard gate() else { return }
        selectGen.selectionChanged()
    }

    public func burst(count: Int = 3, spacing: TimeInterval = 0.06) {
        guard isEnabled, count > 0 else { return }
        Task { [weak self] in
            guard let self else { return }
            for i in 0..<count {
                if i % 2 == 0 { self.light() } else { self.medium() }
                try? await Task.sleep(nanoseconds: UInt64(max(spacing, minInterval) * 1_000_000_000))
            }
        }
    }

    public func prepareAll() {
        lightGen.prepare()
        mediumGen.prepare()
        heavyGen.prepare()
        softGen.prepare()
        rigidGen.prepare()
        notifyGen.prepare()
        selectGen.prepare()
    }

    // MARK: - Internals

    private func impact(_ gen: UIImpactFeedbackGenerator) {
        guard gate() else { return }
        gen.impactOccurred()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard gate() else { return }
        notifyGen.notificationOccurred(type)
    }

    private func gate() -> Bool {
        guard isEnabled else { return false }
        return shouldFire()
    }

    private func shouldFire() -> Bool {
        let now = CACurrentMediaTime()
        if now - lastImpactAt >= minInterval {
            lastImpactAt = now
            return true
        }
        return false
    }
}

// MARK: - Event

public enum HapticEvent: Equatable {
    case tap
    case select
    case confirm
    case warn
    case error
    case impactLight
    case impactMedium
    case impactHeavy
    case impactSoft
    case impactRigid
    case burst(count: Int = 3, spacing: TimeInterval = 0.06)
}
