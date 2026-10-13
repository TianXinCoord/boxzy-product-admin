import SwiftUI

struct ContentView: View {
    @AppStorage("boxzy.isAuthenticated") private var isAuthenticated = false
    @State private var selection: BoxzyTab
    @State private var restrictedDestination: BoxzyTab?

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let initialSelection: BoxzyTab
        if arguments.contains("-BoxzyAccount") {
            initialSelection = .account
        } else if arguments.contains("-BoxzyRankings") {
            initialSelection = .rankings
        } else if arguments.contains("-BoxzyCollection") {
            initialSelection = .collection
        } else {
            initialSelection = .boxes
        }
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        Group {
            if isAuthenticated {
                ZStack {
                    BoxzyTheme.background.ignoresSafeArea()

                    Group {
                        switch selection {
                        case .boxes:
                            NavigationStack { HomeView() }
                        case .collection:
                            CollectionView {
                                withAnimation(.snappy(duration: 0.22)) {
                                    selection = .boxes
                                }
                            }
                        case .rankings:
                            LeaderboardView {
                                withAnimation(.snappy(duration: 0.22)) {
                                    selection = .boxes
                                }
                            }
                        case .account:
                            AccountTabView(isAuthenticated: $isAuthenticated)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    BoxzyBottomNavigation(selection: guardedSelection)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        .background {
                            ZStack(alignment: .top) {
                                BoxzyTheme.background

                                LinearGradient(
                                    colors: [.black.opacity(0.46), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 28)
                            }
                            .ignoresSafeArea(edges: .bottom)
                        }
                }
                .fullScreenCover(item: $restrictedDestination) { destination in
                    WelcomeSignInView(
                        authenticated: {
                            isAuthenticated = true
                            selection = destination
                            restrictedDestination = nil
                        },
                        headline: "Sign in to continue",
                        supportingMessage: "Sign in to continue your BOXZY experience.",
                        close: {
                            restrictedDestination = nil
                        }
                    )
                }
                .transition(.opacity)
            } else {
                WelcomeSignInView(
                    authenticated: {
                        isAuthenticated = true
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: isAuthenticated)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("boxzy.openCollection"))) { _ in selection = .collection }
    }

    private var guardedSelection: Binding<BoxzyTab> {
        Binding(
            get: { selection },
            set: { requestedTab in
                if !isAuthenticated && requestedTab == .collection {
                    restrictedDestination = requestedTab
                } else {
                    selection = requestedTab
                }
            }
        )
    }
}

enum BoxzyTab: String, CaseIterable, Identifiable {
    case boxes = "Boxes"
    case collection = "Collection"
    case rankings = "Rankings"
    case account = "Account"

    var id: Self { self }
}

struct BoxzyBottomNavigation: View {
    @Binding var selection: BoxzyTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BoxzyTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        TabBarIcon(
                            tab: tab,
                            color: selection == tab ? BoxzyTheme.blue : BoxzyTheme.muted
                        )
                        .frame(width: 24, height: 24)

                        Text(tab.rawValue)
                            .boxzyFont(12, weight: selection == tab ? .semibold : .medium)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == tab ? BoxzyTheme.blue : BoxzyTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background {
                        if selection == tab {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            BoxzyTheme.gold.opacity(0.11),
                                            BoxzyTheme.goldDeep.opacity(0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BoxzyTheme.surface.opacity(0.98),
                            BoxzyTheme.background.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [BoxzyTheme.goldLight.opacity(0.48), BoxzyTheme.goldDeep.opacity(0.46)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 0.9
                        )
                }
        }
        .shadow(color: BoxzyTheme.gold.opacity(0.08), radius: 14, y: 4)
        .shadow(color: .black.opacity(0.48), radius: 18, y: 8)
    }
}

struct TabBarIcon: View {
    let tab: BoxzyTab
    let color: Color

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 24
            context.scaleBy(x: scale, y: scale)

            let style = StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
            context.stroke(path(for: tab), with: .color(color), style: style)
        }
        .accessibilityHidden(true)
    }

    private func path(for tab: BoxzyTab) -> Path {
        switch tab {
        case .boxes:
            return Path { path in
                path.move(to: CGPoint(x: 3.5, y: 7))
                path.addLine(to: CGPoint(x: 12, y: 2.7))
                path.addLine(to: CGPoint(x: 20.5, y: 7))
                path.addLine(to: CGPoint(x: 20.5, y: 17))
                path.addLine(to: CGPoint(x: 12, y: 21.4))
                path.addLine(to: CGPoint(x: 3.5, y: 17))
                path.closeSubpath()
                path.move(to: CGPoint(x: 3.5, y: 7))
                path.addLine(to: CGPoint(x: 12, y: 11.5))
                path.addLine(to: CGPoint(x: 20.5, y: 7))
                path.move(to: CGPoint(x: 12, y: 11.5))
                path.addLine(to: CGPoint(x: 12, y: 21.4))
            }

        case .collection:
            return Path { path in
                path.addRoundedRect(
                    in: CGRect(x: 3, y: 5, width: 14, height: 16),
                    cornerSize: CGSize(width: 2.2, height: 2.2)
                )
                path.addRoundedRect(
                    in: CGRect(x: 7, y: 2.5, width: 14, height: 16),
                    cornerSize: CGSize(width: 2.2, height: 2.2)
                )
                path.move(to: CGPoint(x: 14, y: 7))
                path.addLine(to: CGPoint(x: 15.5, y: 9.2))
                path.addLine(to: CGPoint(x: 14, y: 11.4))
                path.addLine(to: CGPoint(x: 12.5, y: 9.2))
                path.closeSubpath()
            }

        case .rankings:
            return Path { path in
                path.move(to: CGPoint(x: 7, y: 3.5))
                path.addLine(to: CGPoint(x: 17, y: 3.5))
                path.addLine(to: CGPoint(x: 16.2, y: 10))
                path.addQuadCurve(to: CGPoint(x: 12, y: 14.7), control: CGPoint(x: 15.8, y: 14))
                path.addQuadCurve(to: CGPoint(x: 7.8, y: 10), control: CGPoint(x: 8.2, y: 14))
                path.closeSubpath()
                path.move(to: CGPoint(x: 7.4, y: 6))
                path.addLine(to: CGPoint(x: 4, y: 6))
                path.addLine(to: CGPoint(x: 4.5, y: 9.8))
                path.addQuadCurve(to: CGPoint(x: 8.1, y: 12), control: CGPoint(x: 5.2, y: 11.8))
                path.move(to: CGPoint(x: 16.6, y: 6))
                path.addLine(to: CGPoint(x: 20, y: 6))
                path.addLine(to: CGPoint(x: 19.5, y: 9.8))
                path.addQuadCurve(to: CGPoint(x: 15.9, y: 12), control: CGPoint(x: 18.8, y: 11.8))
                path.move(to: CGPoint(x: 12, y: 14.7))
                path.addLine(to: CGPoint(x: 12, y: 19))
                path.move(to: CGPoint(x: 8, y: 21))
                path.addLine(to: CGPoint(x: 16, y: 21))
            }

        case .account:
            return AccountGlyph().path(in: CGRect(x: 0, y: 0, width: 24, height: 24))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 402, height: 874)
            .previewDisplayName("iPhone 17 Pro · 402 × 874")
    }
}

// Shared account silhouette: same geometry for the guest state and tab bar.
struct AccountGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let glyph = Path { path in
            path.addEllipse(in: CGRect(x: 8, y: 2.5, width: 8, height: 8))
            path.move(to: CGPoint(x: 4, y: 21))
            path.addCurve(to: CGPoint(x: 12, y: 13.5), control1: CGPoint(x: 4, y: 16.5), control2: CGPoint(x: 7, y: 13.5))
            path.addCurve(to: CGPoint(x: 20, y: 21), control1: CGPoint(x: 17, y: 13.5), control2: CGPoint(x: 20, y: 16.5))
            path.closeSubpath()
        }
        let scale = min(rect.width, rect.height) / 24
        return glyph.applying(CGAffineTransform(scaleX: scale, y: scale))
            .offsetBy(dx: rect.midX - 12 * scale, dy: rect.midY - 12 * scale)
    }
}
