import Combine
import SwiftUI
import Foundation

// MARK: - Animation Tokens
  
public enum Anim {
    public static let fast: Animation = .easeInOut(duration: 0.18)
    public static let regular: Animation = .easeInOut(duration: 0.32)
    public static let slow: Animation = .easeInOut(duration: 0.6)
    public static let springSoft: Animation = .spring(response: 0.35, dampingFraction: 0.82, blendDuration: 0.12)
    public static let springFirm: Animation = .spring(response: 0.28, dampingFraction: 0.7, blendDuration: 0.1)
}

// MARK: - Scale On Tap

public struct ScaleOnTap: ViewModifier {
    @GestureState private var isPressed = false
    public var minScale: CGFloat

    public func body(content: Content) -> some View {
        let press = DragGesture(minimumDistance: 0)
            .updating($isPressed) { _, s, _ in s = true }
        content
            .scaleEffect(isPressed ? minScale : 1.0)
            .animation(Anim.springSoft, value: isPressed)
            .gesture(press)
    }
}

public extension View {
    func scaleOnTap(_ minScale: CGFloat = 0.96) -> some View {
        modifier(ScaleOnTap(minScale: minScale))
    }
}

// MARK: - Pulse

public struct PulseEffect: ViewModifier, Animatable {
    public var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    private var color: Color
    private var baseOpacity: Double
    private var maxRadius: CGFloat
    private var repeatForever: Bool

    private var phase: CGFloat

    public init(color: Color = .accentColor,
                baseOpacity: Double = 0.15,
                maxRadius: CGFloat = 18,
                repeatForever: Bool = true,
                phase: CGFloat = 0) {
        self.color = color
        self.baseOpacity = baseOpacity
        self.maxRadius = maxRadius
        self.repeatForever = repeatForever
        self.phase = phase
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(baseOpacity), lineWidth: 2)
                    .scaleEffect(1 + 0.25 * sin(phase))
                    .blur(radius: 0.5)
            )
            .onAppear {
                guard repeatForever else { return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    _ = phase + maxRadius
                }
            }
    }
}

public extension View {
    func pulse(color: Color = .accentColor,
               baseOpacity: Double = 0.15,
               maxRadius: CGFloat = 18,
               repeatForever: Bool = true) -> some View {
        modifier(PulseEffect(color: color,
                             baseOpacity: baseOpacity,
                             maxRadius: maxRadius,
                             repeatForever: repeatForever))
    }
}

// MARK: - Shimmer

public struct Shimmer: ViewModifier {
    @State private var move: CGFloat = -1

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear, .white.opacity(0.35), .clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(20))
                        .offset(x: move * geo.size.width * 1.6)
                        .blendMode(.plusLighter)
                }
                .allowsHitTesting(false)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    move = 1
                }
            }
    }
}

public extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

// MARK: - Wiggle

public struct Wiggle: ViewModifier {
    @State private var angle: CGFloat = 0
    public var amplitude: CGFloat
    public var duration: Double

    public func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(Double(angle)))
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    angle = amplitude
                }
            }
    }
}

public extension View {
    func wiggle(amplitude: CGFloat = 2.5, duration: Double = 0.18) -> some View {
        modifier(Wiggle(amplitude: amplitude, duration: duration))
    }
}

// MARK: - Transitions

public extension AnyTransition {
    static var fadeScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        )
    }

    static var slideUpFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        )
    }

    static var slideDownFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
    }
}

// MARK: - Animated Number

public struct AnimatedNumberText: View {
    public let value: Double
    public var format: String = "%.0f"
    public var font: Font = .system(.headline, design: .rounded)

    @State private var animated: Double = 0

    public init(value: Double, format: String = "%.0f", font: Font = .system(.headline, design: .rounded)) {
        self.value = value
        self.format = format
        self.font = font
    }

    public var body: some View {
        Text(String(format: format, animated))
            .font(font)
            .monospacedDigit()
            .onAppear {
                animated = 0
                withAnimation(Anim.springFirm) {
                    animated = value
                }
            }
            .onChange(of: value) { new in
                withAnimation(Anim.springFirm) {
                    animated = new
                }
            }
    }
}

// MARK: - Press Feedback (opacity)

public struct PressOpacity: ViewModifier {
    @GestureState private var pressed = false
    public func body(content: Content) -> some View {
        let g = DragGesture(minimumDistance: 0)
            .updating($pressed) { _, s, _ in s = true }
        content
            .opacity(pressed ? 0.6 : 1.0)
            .animation(Anim.fast, value: pressed)
            .gesture(g)
    }
}

public extension View {
    func pressOpacity() -> some View { modifier(PressOpacity()) }
}
