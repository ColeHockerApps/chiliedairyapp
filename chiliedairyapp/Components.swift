import Combine
import SwiftUI
import Foundation

// MARK: - Card Style

public struct CardStyleModifier: ViewModifier {
    public let palette: AppTheme.Palette
    public let elevated: Bool

    public func body(content: Content) -> some View {
        content
            .padding(12)
            .background(palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.surfaceAlt.opacity(0.65), lineWidth: 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: elevated ? Color.black.opacity(0.18) : .clear,
                radius: elevated ? 10 : 0,
                x: 0,
                y: elevated ? 6 : 0
            )
            .animation(.default, value: elevated)
    }
}

public extension View {
    func cardStyle(_ palette: AppTheme.Palette, elevated: Bool = false) -> some View {
        self.modifier(CardStyleModifier(palette: palette, elevated: elevated))
    }
}

// MARK: - Chips

public struct ChipView: View {
    public let title: String
    public let icon: String?
    public let background: Color
    public let border: Color?
    public let text: Color

    public init(title: String, icon: String? = nil, background: Color, border: Color? = nil, text: Color = .primary) {
        self.title = title
        self.icon = icon
        self.background = background
        self.border = border
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon) }
            Text(title)
        }
        .font(.caption)
        .foregroundStyle(text)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(background)
        .overlay(
            Capsule().stroke((border ?? .clear), lineWidth: border == nil ? 0 : 0.8)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Section Header

public struct SectionHeader: View {
    public let title: String
    public let subtitle: String?
    public let icon: String?

    public init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - AnyTransition helpers

public extension AnyTransition {
    static func slideAndFade(_ edge: Edge = .bottom) -> AnyTransition {
        .move(edge: edge).combined(with: .opacity)
    }
}

// MARK: - Compact Info Row

public struct InfoRow: View {
    public let title: String
    public let value: String
    public let icon: String?
    public let tint: Color?

    public init(title: String, value: String, icon: String? = nil, tint: Color? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon).foregroundStyle(tint ?? .secondary)
            }
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.subheadline)
    }
}

// MARK: - Progress Bar (lightweight)

public struct ProgressBar: View {
    public let progress: Double
    public let height: CGFloat
    public let fill: Color
    public let background: Color

    public init(progress: Double, height: CGFloat = 8, fill: Color, background: Color) {
        self.progress = max(0, min(progress, 1))
        self.height = height
        self.fill = fill
        self.background = background
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height/2).fill(background)
                RoundedRectangle(cornerRadius: height/2)
                    .fill(fill)
                    .frame(width: max(2, CGFloat(progress) * geo.size.width))
                    .animation(Anim.springSoft, value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Pill Button

public struct PillButtonStyle: ButtonStyle {
    public let background: Color
    public let foreground: Color

    public init(background: Color, foreground: Color = .primary) {
        self.background = background
        self.foreground = foreground
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(background.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundStyle(foreground)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Small utilities

public extension View {
    func roundedStroke(_ color: Color, radius: CGFloat = 12, lineWidth: CGFloat = 0.6) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(color, lineWidth: lineWidth))
    }

    func listRowBackground(_ palette: AppTheme.Palette) -> some View {
        background(palette.surface)
    }
}
