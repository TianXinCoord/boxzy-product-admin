import SwiftUI

enum BoxzyTheme {
    // Obsidian Gold: neutral structure, one restrained brand accent.
    static let background = Color(white: 9.0 / 255)
    static let surface = Color(white: 20.0 / 255)
    static let stroke = Color(white: 48.0 / 255)
    static let goldDeep = Color(red: 0.659, green: 0.451, blue: 0.094)
    static let gold = Color(red: 242.0 / 255, green: 196.0 / 255, blue: 77.0 / 255)
    static let goldLight = Color(red: 255.0 / 255, green: 214.0 / 255, blue: 102.0 / 255)
    static let muted = Color(white: 184.0 / 255)

    // Compatibility aliases keep every existing screen on the single gold accent.
    static let cyan = goldLight
    static let blue = gold
    static let violet = goldDeep
    static let lavender = goldLight
    static let starter = gold
    static let superTier = gold
    static let ultra = gold

    static let primaryGradient = LinearGradient(
        colors: [goldLight, gold],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    func boxzyCard(cornerRadius: CGFloat = 16) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(BoxzyTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(BoxzyTheme.stroke, lineWidth: 1)
                }
        )
    }
}

// Approved 2026-10-13 UI contract. All sizes are default Dynamic Type points.
enum BoxzyMetrics {
    static let pageInset: CGFloat = 20
    static let cardRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 52
    static let touchTarget: CGFloat = 44
    static let actionGap: CGFloat = 12
}

private struct BoxzyScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
        self.weight = weight
        self.design = design
    }
    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    func boxzyFont(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(BoxzyScaledFont(size: size, weight: weight, design: design))
    }
}

struct BoxzySecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.boxzyFont(16, weight: .medium)
            .foregroundStyle(isEnabled ? Color.white : BoxzyTheme.muted)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: BoxzyMetrics.buttonHeight)
            .background(BoxzyTheme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.45), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct BoxzyAdaptiveScroll<Content: View>: View {
    let enabled: Bool
    @ViewBuilder var content: () -> Content
    var body: some View {
        if enabled { ScrollView { content() } } else { content() }
    }
}
