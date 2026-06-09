import SwiftUI

enum GlassProminence {
    case capsule
    case popover
    case control
}

struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let prominence: GlassProminence

    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.3)
        if #available(macOS 26.0, *) {
            nativeGlass(content)
        } else {
            fallbackGlass(content)
        }
        #else
        fallbackGlass(content)
        #endif
    }

    @ViewBuilder
    private func fallbackGlass(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .background(.ultraThinMaterial)
            .background(tintColor)
            .overlay(
                shape
                    .stroke(borderColor, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                if showsTopHighlight {
                    shape
                        .fill(topHighlight)
                        .frame(height: 1)
                        .padding(.horizontal, prominence == .capsule ? 9 : 14)
                }
            }
            .clipShape(shape)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }

    #if compiler(>=6.3)
    @available(macOS 26.0, *)
    @ViewBuilder
    private func nativeGlass(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .glassEffect(.regular.interactive(), in: shape)
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }
    #endif

    private var tintColor: Color {
        switch (colorScheme, prominence) {
        case (.light, .capsule):
            return Color.white.opacity(0.22)
        case (.light, .popover):
            return Color.white.opacity(0.30)
        case (.light, .control):
            return Color.white.opacity(0.18)
        case (.dark, .capsule):
            return Color.white.opacity(0.10)
        case (.dark, .popover):
            return Color.white.opacity(0.12)
        case (.dark, .control):
            return Color.white.opacity(0.09)
        @unknown default:
            return Color.white.opacity(0.12)
        }
    }

    private var borderColor: Color {
        colorScheme == .light ? Color.white.opacity(0.42) : Color.white.opacity(0.20)
    }

    private var topHighlight: Color {
        colorScheme == .light ? Color.white.opacity(0.72) : Color.white.opacity(0.52)
    }

    private var showsTopHighlight: Bool {
        prominence != .popover
    }

    private var shadowColor: Color {
        colorScheme == .light ? Color.black.opacity(0.14) : Color.black.opacity(0.38)
    }

    private var shadowRadius: CGFloat {
        prominence == .capsule ? 18 : 36
    }

    private var shadowY: CGFloat {
        prominence == .capsule ? 6 : 18
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat, prominence: GlassProminence) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, prominence: prominence))
    }

    @ViewBuilder
    func nativeGlassEffectContainer(spacing: CGFloat? = nil) -> some View {
        #if compiler(>=6.3)
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                self
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
}
