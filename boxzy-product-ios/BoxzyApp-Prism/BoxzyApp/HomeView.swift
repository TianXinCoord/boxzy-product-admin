import SwiftUI

struct HomeView: View {
    @AppStorage("boxzy.isAuthenticated") private var isAuthenticated = false
    @AppStorage("boxzy.balance") private var balance = 100.0
    @AppStorage("boxzy.selectedBoxID") private var storedSelectedBoxID = "starter"
    @State private var isPresentingAddFunds = false
    @State private var isPresentingAddFundsSignIn = false
    @State private var isShowingBoxDetails = false
    @State private var isShowingPurchaseFlow = false
    @State private var selectedPrize: PullPrize?
    @Environment(\.dynamicTypeSize) private var typeSize

    private let boxes = MysteryBox.samples
    private let prizes = PullPrize.samples

    private var selectedBox: MysteryBox {
        boxes.first(where: { $0.id == storedSelectedBoxID }) ?? boxes[1]
    }

    private var selectedBoxID: Binding<MysteryBox.ID?> {
        Binding(
            get: { storedSelectedBoxID },
            set: { storedSelectedBoxID = $0 ?? "starter" }
        )
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            HomeScrollContainer(enabled: typeSize.isAccessibilitySize) {
            GeometryReader { geometry in
                // The navigation container overlays the custom bottom bar.
                // Give artwork the remaining height instead of scrolling the page.
                let cardHeight = typeSize.isAccessibilitySize ? 260.0 : 180.0
                VStack(spacing: 0) {
                    BoxzyHeaderView(balance: balance) {
                        if isAuthenticated {
                            isPresentingAddFunds = true
                        } else {
                            isPresentingAddFundsSignIn = true
                        }
                    }
                    .padding(.horizontal, 20)

                    LivePullTicker()
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                    sectionTitle
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    BoxCarousel(boxes: boxes, selectedBoxID: selectedBoxID)
                        .frame(maxHeight: .infinity)
                        .layoutPriority(-1)
                        .accessibilityIdentifier("home.carousel")

                    PageDots(boxes: boxes, selectedBoxID: $storedSelectedBoxID)
                        .frame(height: 44)

                    prizeSection(cardHeight: cardHeight)
                        .padding(.top, 4)

                    PurchasePanel(box: selectedBox, action: buySelectedBox)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(height: typeSize.isAccessibilitySize ? 1100 : nil)
            .padding(.bottom, 76)
            }
        }
        .sheet(isPresented: $isPresentingAddFunds) {
            AddFundsFlowView(isAuthenticated: $isAuthenticated)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .presentationBackground(BoxzyTheme.background)
        }
        .fullScreenCover(isPresented: $isPresentingAddFundsSignIn) {
            WelcomeSignInView(
                authenticated: {
                    isAuthenticated = true
                    isPresentingAddFundsSignIn = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        isPresentingAddFunds = true
                    }
                },
                headline: "Sign in to continue",
                supportingMessage: "Sign in to continue your BOXZY experience.",
                close: {
                    isPresentingAddFundsSignIn = false
                }
            )
        }
        .sheet(item: $selectedPrize) { prize in
            PrizeDetailsView(
                prize: prize,
                boxes: boxes
            ) { box in
                selectedPrize = nil
                storedSelectedBoxID = box.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isShowingBoxDetails = true
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .presentationBackground(BoxzyTheme.background)
        }
        .fullScreenCover(isPresented: $isShowingBoxDetails) {
            BoxDetailsView(initialBoxID: selectedBox.id) { box in
                storedSelectedBoxID = box.id
                isShowingBoxDetails = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isShowingPurchaseFlow = true }
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .presentationBackground(BoxzyTheme.background)
        }
        .fullScreenCover(isPresented: $isShowingPurchaseFlow) {
            PurchaseFlowView(
                box: selectedBox,
                isAuthenticated: $isAuthenticated,
                balance: $balance
            )
        }
#if DEBUG
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
#if DEBUG
            if arguments.contains("-BoxzyDetailsPreview") { isShowingBoxDetails = true }
            if arguments.contains("-BoxzyProductPreview") { selectedPrize = PullPrize.samples[0] }
#endif
            if arguments.contains("-BoxzyPrizeResultPreview") ||
                arguments.contains("-BoxzyPostSalePreview") || arguments.contains("-BoxzyOpeningUpdating") || arguments.contains("-BoxzyOpeningFailure") || arguments.contains("-BoxzyOpeningLoading") {
                isShowingPurchaseFlow = true
            }
        }
#endif
        .toolbar(.hidden, for: .navigationBar)
    }

    private var sectionTitle: some View {
        Text("Choose from 4 boxes.")
            .boxzyFont(27, weight: .bold, design: .default)
            .fontWidth(.condensed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 34)
            .accessibilityIdentifier("home.title")
    }

    private func prizeSection(cardHeight: CGFloat) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("POSSIBLE PULLS")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isShowingBoxDetails = true
                } label: {
                    HStack(spacing: 5) {
                        Text("View all")
                        Image(systemName: "chevron.right")
                            .boxzyFont(12, weight: .semibold)
                    }
                    .boxzyFont(15, weight: .regular)
                    .foregroundStyle(BoxzyTheme.blue)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("home.view-all")
            }
            .padding(.horizontal, 20)

            HStack(spacing: 8) {
                ForEach(prizes.prefix(3)) { prize in
                    Button {
                        selectedPrize = prize
                    } label: {
                        PrizeCard(prize: prize, height: cardHeight)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("home.prize.\(prize.id)")
                    .accessibilityLabel("View details for \(prize.name), estimated value \(prize.value.usd)")
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func buySelectedBox() {
        isShowingPurchaseFlow = true
    }
}

struct BoxzyPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var height: CGFloat = 52
    var cornerRadius: CGFloat = 15

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .boxzyFont(16, weight: .semibold)
            .padding(.horizontal, 12).padding(.vertical, 12)
            .foregroundStyle(isEnabled ? BoxzyTheme.background : Color(white: 0.65))
            .frame(maxWidth: .infinity)
            .frame(minHeight: height)
            .background {
                if isEnabled { BoxzyTheme.primaryGradient } else { Color(white: 0.20) }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isEnabled ? Color.clear : BoxzyTheme.stroke, lineWidth: 0.75)
            }
            
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct BoxzyHeaderView: View {
    let balance: Double
    var isBalanceLoading = false
    let addFunds: () -> Void

    var body: some View {
        HStack {
            Image("boxzy-logo-white")
                .resizable()
                .scaledToFit()
                .frame(width: 134, height: 36, alignment: .leading)
                .accessibilityLabel("BOXZY")

            Spacer()

            HStack(spacing: 8) {
                if isBalanceLoading {
                    Capsule()
                        .fill(Color.white.opacity(0.13))
                        .frame(width: 58, height: 13)
                        .accessibilityLabel("Loading balance")
                } else {
                    Text(verbatim: String(format: "$%.2f", balance))
                        .boxzyFont(15, weight: .semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Button(action: addFunds) {
                    Image(systemName: "plus")
                        .boxzyFont(18, weight: .medium)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(BoxzyTheme.gold, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add funds")
            }
            .padding(.leading, 11)
            .padding(.trailing, 3)
            .frame(minWidth: 130, minHeight: 44)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                BoxzyTheme.surface,
                                BoxzyTheme.background
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .frame(minHeight: 44)
    }
}

private struct LivePullTicker: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(BoxzyTheme.blue)
                .frame(width: 7, height: 7)

            Text("LIVE PULLS")
                .boxzyFont(12, weight: .semibold)
                .lineLimit(1)

            Image("prize-legendary-pack")
                .resizable()
                .scaledToFill()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text("PikaChase22 pulled Legendary Treasures")
                .boxzyFont(13, weight: .regular)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .layoutPriority(-1)

            Spacer(minLength: 0)

            Text("$89")
                .boxzyFont(13, weight: .semibold)
                .foregroundStyle(BoxzyTheme.blue)
        }
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(BoxzyTheme.surface.opacity(0.52))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live pulls. PikaChase22 pulled Legendary Treasures worth 89 dollars")
    }
}

private struct BoxCarousel: View {
    let boxes: [MysteryBox]
    @Binding var selectedBoxID: MysteryBox.ID?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let selectedIndex = boxes.firstIndex(where: { $0.id == selectedBoxID }) ?? 0
            let pageWidth = min(136.0, proxy.size.width * 0.34)
            let itemHeight = min(212.0, proxy.size.height)
            let progress = -dragOffset / pageWidth

            ZStack {


                // Exactly three products remain visible: the selected box in the
                // center and one adjacent option on either side.
                ForEach(-1...1, id: \.self) { position in
                    let distance = abs(CGFloat(position) - progress)
                    let prominence = max(0, 1 - min(distance, 1))
                    let index = wrappedIndex(selectedIndex + position)

                    carouselItem(boxes[index], prominence: prominence, height: itemHeight)
                        .scaleEffect(0.72 + prominence * 0.28)
                        .position(
                            x: proxy.size.width / 2 + CGFloat(position) * pageWidth + dragOffset,
                            y: proxy.size.height / 2
                        )
                        .opacity(max(0.34, 1 - distance * 0.32))
                        .zIndex(10 - Double(distance))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 14)
                    .onChanged { value in
                        dragOffset = max(-pageWidth, min(pageWidth, value.translation.width))
                    }
                    .onEnded { value in
                        let projected = value.predictedEndTranslation.width
                        if projected < -44 {
                            commitPage(index: wrappedIndex(selectedIndex + 1), finishingAt: -pageWidth)
                        } else if projected > 44 {
                            commitPage(index: wrappedIndex(selectedIndex - 1), finishingAt: pageWidth)
                        } else {
                            withAnimation(.snappy(duration: 0.30)) { dragOffset = 0 }
                        }
                    }
            )
        }
        .clipped()
        .sensoryFeedback(.selection, trigger: selectedBoxID)
    }

    private func carouselItem(_ box: MysteryBox, prominence: CGFloat, height: CGFloat) -> some View {
        Button {
            guard let index = boxes.firstIndex(where: { $0.id == box.id }) else { return }
            let selectedIndex = boxes.firstIndex(where: { $0.id == selectedBoxID }) ?? 0
            if index == wrappedIndex(selectedIndex - 1) {
                commitPage(index: index, finishingAt: 136)
            } else if index == wrappedIndex(selectedIndex + 1) {
                commitPage(index: index, finishingAt: -136)
            }
        } label: {
            VStack(spacing: 4) {
                Image(box.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(180, max(80, height - 56) * 1.18), height: max(50, height - 56))
                    .brightness(-0.08 * (1 - prominence))
                    .saturation(0.78 + prominence * 0.22)
                    

                Text(box.name)
                    .boxzyFont(13, weight: .bold)
                    .tracking(1.1)
                    .foregroundStyle(BoxzyTheme.gold)

                Text(box.price.usd)
                    .boxzyFont(20, weight: .bold)
                    .foregroundStyle(.white)
            }
            .frame(width: 194, height: height)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(box.name) box for \(box.price.usd)")
    }

    private func wrappedIndex(_ index: Int) -> Int {
        (index % boxes.count + boxes.count) % boxes.count
    }

    private func commitPage(index: Int, finishingAt offset: CGFloat) {
        withAnimation(.easeOut(duration: 0.16)) { dragOffset = offset }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                selectedBoxID = boxes[index].id
                dragOffset = 0
            }
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

private struct BoxzyStageBackdrop: View {
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [accent.opacity(0.10), accent.opacity(0.025), .clear],
                    center: UnitPoint(x: 0.5, y: 0.56),
                    startRadius: 12,
                    endRadius: proxy.size.width * 0.52
                )

                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height * 0.46)
                    let motifColor = Color.white.opacity(0.045)
                    let floorColor = accent.opacity(0.075)

                    for index in 0..<5 {
                        let width = CGFloat(76 + index * 42)
                        let height = width * 0.66
                        var diamond = Path()
                        diamond.move(to: CGPoint(x: center.x, y: center.y - height / 2))
                        diamond.addLine(to: CGPoint(x: center.x + width / 2, y: center.y))
                        diamond.addLine(to: CGPoint(x: center.x, y: center.y + height / 2))
                        diamond.addLine(to: CGPoint(x: center.x - width / 2, y: center.y))
                        diamond.closeSubpath()
                        context.stroke(diamond, with: .color(motifColor), lineWidth: 0.7)
                    }

                    let horizonY = size.height * 0.70
                    for index in 0...8 {
                        let targetX = size.width * CGFloat(index) / 8
                        var ray = Path()
                        ray.move(to: CGPoint(x: center.x, y: horizonY))
                        ray.addLine(to: CGPoint(x: targetX, y: size.height))
                        context.stroke(ray, with: .color(floorColor), lineWidth: 0.55)
                    }

                    for index in 0..<4 {
                        let progress = CGFloat(index + 1) / 4
                        let y = horizonY + (size.height - horizonY) * progress * progress
                        var floorLine = Path()
                        floorLine.move(to: CGPoint(x: size.width * 0.08, y: y))
                        floorLine.addLine(to: CGPoint(x: size.width * 0.92, y: y))
                        context.stroke(floorLine, with: .color(floorColor), lineWidth: 0.5)
                    }
                }
                .mask {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.86), .white, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct PageDots: View {
    let boxes: [MysteryBox]
    @Binding var selectedBoxID: MysteryBox.ID
    private var index: Int { boxes.firstIndex(where: { $0.id == selectedBoxID }) ?? 0 }
    var body: some View {
        HStack(spacing: 12) {
            Button { selectedBoxID = boxes[(index + boxes.count - 1) % boxes.count].id } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }.accessibilityLabel("Previous box")
            Text("\(index + 1) / \(boxes.count)").font(.headline).monospacedDigit()
            Button { selectedBoxID = boxes[(index + 1) % boxes.count].id } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }.accessibilityLabel("Next box")
        }.foregroundStyle(BoxzyTheme.gold).buttonStyle(.plain)
    }
}

private struct PrizeCard: View {
    let prize: PullPrize
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(prize.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: max(38, height - 70))

            Text(prize.shortName)
                .boxzyFont(15, weight: .medium)
                .lineLimit(2, reservesSpace: true)
                .fixedSize(horizontal: false, vertical: true)

            Text(prize.value.usd)
                .boxzyFont(17, weight: .semibold)
                .foregroundStyle(BoxzyTheme.blue)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.07), BoxzyTheme.surface.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BoxzyTheme.stroke.opacity(0.58), lineWidth: 0.8)
                }
        }
    }
}

private struct PurchasePanel: View {
    let box: MysteryBox
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                valueCell(title: "MIN VALUE", value: box.minimumLabel)

                Rectangle()
                    .fill(Color(.separator).opacity(0.7))
                    .frame(width: 1, height: 28)

                valueCell(title: "MAX VALUE", value: box.maximumLabel)
            }
            .frame(height: 28)

            Button(action: action) {
                Text("Buy now · \(box.price.usd)")
                    .boxzyFont(16, weight: .semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 14))
            .accessibilityIdentifier("home.buy")
        }
        .padding(8)
        .frame(minHeight: 104)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BoxzyTheme.surface,
                            BoxzyTheme.surface.opacity(0.76)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BoxzyTheme.stroke.opacity(0.68), lineWidth: 0.8)
                }
        }
    }

    private func valueCell(title: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .boxzyFont(12, weight: .medium)
                .foregroundStyle(BoxzyTheme.muted)
            Text(value)
                .boxzyFont(16, weight: .bold)
                .monospacedDigit()
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity)
    }
}

private struct HomeScrollContainer<Content: View>: View {
    let enabled: Bool
    @ViewBuilder var content: () -> Content
    var body: some View {
        if enabled { ScrollView { content() } } else { content() }
    }
}
