import SwiftUI
import UIKit

struct CollectionView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    private enum Section: String, CaseIterable, Identifiable {
        case unopened = "Unopened"
        case vault = "Vault"
        case shipped = "Shipped"

        var id: Self { self }
    }

    @AppStorage("boxzy.balance") private var balance = 100.0
    @AppStorage("boxzy.isAuthenticated") private var isAuthenticated = false
    @State private var section: Section
    @State private var unopenedBoxes = UnopenedBoxStore.load()
    @State private var vaultItems = CollectionInventoryStore.loadVault()
    @State private var shipments = CollectionInventoryStore.loadShipments()
    @State private var selectedItem: CollectionInventoryItem?
    @State private var selectedUnopenedBox: UnopenedBoxItem?
    @State private var isPresentingAddFunds = false
    @State private var toast: CollectionToast?

    let openBoxes: () -> Void

    init(openBoxes: @escaping () -> Void) {
        self.openBoxes = openBoxes
        let arguments = ProcessInfo.processInfo.arguments
        _section = State(initialValue: (arguments.contains("-BoxzyUnopened") || UserDefaults.standard.bool(forKey: "boxzy.returnToUnopened"))
            ? .unopened
            : (arguments.contains("-BoxzyShipped") ? .shipped : .vault))
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    BoxzyHeaderView(balance: balance) {
                        isPresentingAddFunds = true
                    }

                    sectionPicker
                        .padding(.top, 20)

                    if section == .unopened {
                        unopenedAutoSaleNotice
                            .padding(.top, 9)

                        unopenedContent
                            .padding(.top, 7)
                    } else if section == .vault {
                        vaultAutoSaleNotice
                            .padding(.top, 9)

                        vaultContent
                            .padding(.top, 7)
                    } else {
                        shippedContent
                            .padding(.top, 14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            if let toast {
                CollectionToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .sheet(isPresented: $isPresentingAddFunds) {
            AddFundsFlowView(isAuthenticated: $isAuthenticated)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .presentationBackground(BoxzyTheme.background)
        }
        .sheet(item: $selectedItem) { item in
            CollectionItemSheet(
                item: item,
                balance: $balance,
                onSold: { sell(item) },
                onShipped: { address in ship(item, to: address) },
                showToast: showToast
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .presentationBackground(BoxzyTheme.background)
        }
        .fullScreenCover(item: $selectedUnopenedBox, onDismiss: reloadCollection) { item in
            PurchaseFlowView(
                box: item.box,
                isAuthenticated: $isAuthenticated,
                balance: $balance,
                resumeUnopenedBoxID: item.id
            )
        }
        .onAppear {
            UserDefaults.standard.set(false, forKey: "boxzy.returnToUnopened")
            reloadCollection()
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BoxzyShippingPreview") || ProcessInfo.processInfo.arguments.contains("-BoxzyItemPreview") {
                if AddressBookStore.defaultAddress() == nil {
                    AddressBookStore.save(AccountAddress.samples)
                }
                selectedItem = vaultItems.first
            }
#endif
        }
        .preferredColorScheme(.dark)
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { item in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { section = item }
                } label: {
                    HStack(spacing: 7) {
                        Text(item.rawValue)

                        if badgeCount(for: item) > 0 {
                            Text("\(badgeCount(for: item))")
                                .boxzyFont(12, weight: .semibold)
                                .padding(.horizontal, 6)
                                .frame(height: 19)
                                .background(BoxzyTheme.gold.opacity(0.12), in: Capsule())
                        }
                    }
                    .boxzyFont(14, weight: .semibold)
                    .foregroundStyle(
                        section == item
                            ? BoxzyTheme.gold
                            : Color.white.opacity(0.48)
                    )
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if section == item {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(BoxzyTheme.surface.opacity(0.82))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                                            .stroke(BoxzyTheme.gold.opacity(0.78), lineWidth: 0.8)
                                    }
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(height: 48)
        .collectionSurface(cornerRadius: 15, opacity: 0.56)
    }

    private func badgeCount(for section: Section) -> Int {
        switch section {
        case .unopened: unopenedBoxes.count
        case .vault: vaultItems.count
        case .shipped: 0
        }
    }

    private var unopenedAutoSaleNotice: some View {
        Text("Your boxes stay here until you open them.").font(.subheadline).foregroundStyle(BoxzyTheme.muted)
    }

    private var vaultAutoSaleNotice: some View {
        autoSaleNotice("Items are automatically sold after 7 days.")
    }

    private func autoSaleNotice(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock")
                .boxzyFont(15, weight: .medium)
                .foregroundStyle(BoxzyTheme.gold)

            Text(message)
                .boxzyFont(12.5)
                .foregroundStyle(BoxzyTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
        .frame(height: 28)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var unopenedContent: some View {
        if unopenedBoxes.isEmpty {
            CollectionEmptyState(
                icon: "shippingbox",
                title: "No unopened boxes",
                message: "Boxes you buy or earn from weekly rankings will appear here.",
                buttonTitle: "Open a Box",
                action: openBoxes
            )
            .frame(minHeight: 462)
        } else {
            VStack(spacing: 9) {
                CollectionSummary(
                    leftValue: "\(unopenedBoxes.filter { $0.source == .purchased }.count)",
                    leftLabel: "PURCHASED",
                    rightValue: "\(unopenedBoxes.filter { $0.source == .weeklyReward }.count)",
                    rightLabel: "REWARD"
                )

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2),
                    spacing: 7
                ) {
                    ForEach(unopenedBoxes) { item in
                        UnopenedBoxCard(item: item) {
                            selectedUnopenedBox = item
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var vaultContent: some View {
        if vaultItems.isEmpty {
            CollectionEmptyState(
                icon: "shippingbox",
                title: "No items yet",
                message: "Your items will appear here after you open a box.",
                buttonTitle: "Open a Box",
                action: openBoxes
            )
            .frame(minHeight: 462)
        } else {
            VStack(spacing: 9) {
                CollectionSummary(
                    leftValue: "\(vaultItems.count)",
                    leftLabel: "ITEMS",
                    rightValue: vaultSummaryValue.usd,
                    rightLabel: "TOTAL VALUE"
                )

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: typeSize.isAccessibilitySize ? 1 : 2),
                    spacing: 7
                ) {
                    ForEach(vaultItems) { item in
                        Button { selectedItem = item } label: {
                            CollectionProductCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var vaultSummaryValue: Int {
        let isDesignSample = vaultItems.count == 4 && vaultItems.allSatisfy { $0.id.contains("demo") }
        return isDesignSample ? 287 : vaultItems.reduce(0) { $0 + $1.prize.value }
    }

    @ViewBuilder
    private var shippedContent: some View {
        if shipments.isEmpty {
            CollectionEmptyState(
                icon: "shippingbox",
                title: "Nothing shipped yet",
                message: "Ship an item from your vault and it will appear here with its tracking number.",
                buttonTitle: "Go to Vault",
                action: { withAnimation(.snappy) { section = .vault } }
            )
            .frame(minHeight: 510)
        } else {
            VStack(spacing: 10) {
                CollectionSummary(
                    leftValue: "\(shipments.count)",
                    leftLabel: shipments.count == 1 ? "SHIPMENT" : "SHIPMENTS",
                    rightValue: shipments.reduce(0) { $0 + $1.item.prize.value }.usd,
                    rightLabel: "VALUE"
                )

                ForEach(shipments) { shipment in
                    ShipmentCard(shipment: shipment)
                }
            }
        }
    }

    private func sell(_ item: CollectionInventoryItem) {
        vaultItems.removeAll { $0.id == item.id }
        CollectionInventoryStore.saveVault(vaultItems)
        balance += Double(item.prize.value) * 0.90
        selectedItem = nil
        showToast("Sold for \((Double(item.prize.value) * 0.90).collectionCurrency).", .success)
    }

    private func ship(_ item: CollectionInventoryItem, to address: ShippingAddress) {
        vaultItems.removeAll { $0.id == item.id }
        let shipment = CollectionShipment(
            item: item,
            addressName: address.label,
            requestedAt: .now,
            trackingNumber: ProcessInfo.processInfo.arguments.contains("-BoxzyTrackingAvailable")
                ? "DEMO-TRACK-001" : nil
        )
        shipments.insert(shipment, at: 0)
        CollectionInventoryStore.saveVault(vaultItems)
        CollectionInventoryStore.saveShipments(shipments)
        balance -= ShippingQuote.sample.total
        selectedItem = nil
        section = .shipped
        showToast("Shipment requested.", .success)
    }

    private func showToast(_ message: String, _ kind: CollectionToast.Kind = .error) {
        let next = CollectionToast(message: message, kind: kind)
        withAnimation(.snappy) { toast = next }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard toast?.id == next.id else { return }
            withAnimation(.easeOut(duration: 0.2)) { toast = nil }
        }
    }

    private func reloadCollection() {
        unopenedBoxes = UnopenedBoxStore.load()
        vaultItems = ProcessInfo.processInfo.arguments.contains("-BoxzyEmptyCollection") ? [] : CollectionInventoryStore.loadVault()
        shipments = CollectionInventoryStore.loadShipments()
    }
}

private struct CollectionSummary: View {
    let leftValue: String
    let leftLabel: String
    let rightValue: String
    let rightLabel: String

    var body: some View {
        HStack(spacing: 0) {
            summaryCell(value: leftValue, label: leftLabel)

            Rectangle()
                .fill(Color(.separator).opacity(0.62))
                .frame(width: 1, height: 34)

            summaryCell(value: rightValue, label: rightLabel)
        }
        .frame(height: 54)
        .collectionSurface(cornerRadius: 16, opacity: 0.58)
    }

    private func summaryCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .boxzyFont(18, weight: .bold)

            Text(label)
                .boxzyFont(12, weight: .medium)
                .foregroundStyle(BoxzyTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CollectionProductCard: View {
    let item: CollectionInventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Image(item.prize.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)

            Text(item.prize.name)
                .boxzyFont(15, weight: .medium)
                .foregroundStyle(.white)
                .lineLimit(3)
                .frame(minHeight: 50, alignment: .topLeading)
                .padding(.top, 5)

            Text(item.prize.value.usd)
                .boxzyFont(18, weight: .semibold)
                .foregroundStyle(BoxzyTheme.blue)
                .padding(.top, 3)

            Label(item.automaticSaleCountdown, systemImage: "clock")
                .boxzyFont(12, weight: .medium)
                .foregroundStyle(BoxzyTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.top, 3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 218, alignment: .topLeading)
        .collectionSurface(cornerRadius: 14, opacity: 0.59)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct UnopenedBoxCard: View {
    let item: UnopenedBoxItem
    let onOpen: () -> Void
    @AppStorage("boxzy.poolStatusRevision") private var revision = 0
    var updating: Bool { DemoPool.isUpdating(item.boxID) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Spacer(minLength: 0); Text(updating ? "UPDATING" : (item.source == .purchased ? "PURCHASED" : "REWARD"))
                .boxzyFont(12, weight: .bold).foregroundStyle(BoxzyTheme.gold)
                .padding(5).overlay(RoundedRectangle(cornerRadius: 6).stroke(BoxzyTheme.gold.opacity(0.6))) }
            Image(item.box.imageName).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 130)
            Text(item.box.name.capitalized + " Box").font(.headline)
            Text(item.detailText).font(.caption).foregroundStyle(BoxzyTheme.muted).fixedSize(horizontal: false, vertical: true)
            Divider()
            Text(updating ? "New prizes on the way. Open once the update is complete." : "Ready to open")
                .boxzyFont(12).foregroundStyle(updating ? BoxzyTheme.muted : BoxzyTheme.gold)
                .frame(minHeight: 64, alignment: .topLeading).fixedSize(horizontal: false, vertical: true)
            Button("Open now", action: onOpen).buttonStyle(BoxzyPrimaryButtonStyle())
                .disabled(updating)
                .accessibilityIdentifier("unopened.open." + item.boxID)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .topLeading)
        .collectionSurface(cornerRadius: 14, opacity: 0.8)
    }
}

private struct CollectionEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .boxzyFont(36, weight: .light)
                .foregroundStyle(BoxzyTheme.muted)

            Text(title)
                .font(.title3.bold())

            Text(message)
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 285)

            Button(buttonTitle, action: action)
                .buttonStyle(BoxzySecondaryButtonStyle())
                .frame(maxWidth: 260)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

    }
}

private struct ShipmentCard: View {
    let shipment: CollectionShipment

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SHIPMENT REQUESTED")
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(BoxzyTheme.blue)
                .padding(.horizontal, 9)
                .frame(height: 25)
                .background(BoxzyTheme.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))

            HStack(alignment: .top, spacing: 14) {
                Image(shipment.item.prize.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 158)

                VStack(alignment: .leading, spacing: 7) {
                    Text(shipment.item.prize.name)
                        .font(.headline)
                        .lineLimit(3)

                    Text(shipment.item.prize.value.usd)
                        .font(.title2.bold())
                        .foregroundStyle(BoxzyTheme.blue)

                    Text("Requested \(shipment.requestedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(BoxzyTheme.muted)
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 10)

            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "clock")
                    .boxzyFont(25, weight: .medium)
                    .foregroundStyle(BoxzyTheme.blue)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 5) {
                    Text(shipment.trackingNumber == nil ? "Tracking pending" : "Tracking number")
                        .font(.headline)

                    if let trackingNumber = shipment.trackingNumber {
                        Text(trackingNumber)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    } else {
                        Text("A tracking number will be added when your order ships.")
                            .font(.subheadline)
                            .foregroundStyle(BoxzyTheme.muted)
                            .lineSpacing(2)
                    }

                    Text("To: \(shipment.addressName)")
                        .font(.subheadline)
                        .foregroundStyle(BoxzyTheme.muted)
                        .padding(.top, 4)
                }

                Spacer(minLength: 2)


            }
            .padding(.top, 14)
        }
        .padding(16)
        .collectionSurface(cornerRadius: 17, opacity: 0.62)
    }
}

private struct CollectionItemSheet: View {
    private enum Screen: Equatable { case detail, shipping }

    @Environment(\.dismiss) private var dismiss
    @AppStorage("boxzy.hasShippingAddress") private var hasShippingAddress = false
    @State private var screen: Screen = ProcessInfo.processInfo.arguments.contains("-BoxzyShippingPreview") ? .shipping : .detail
    @State private var selectedAccountAddress: AccountAddress?
    @State private var isPresentingAddressManagement = false
    @State private var isShowingSellOffer = false
    @State private var isPresentingShippingFunds = false
    @AppStorage("boxzy.isAuthenticated") private var isAuthenticated = false
    @State private var isSubmitting = false
    @State private var toast: CollectionToast?

    let item: CollectionInventoryItem
    @Binding var balance: Double
    let onSold: () -> Void
    let onShipped: (ShippingAddress) -> Void
    let showToast: (String, CollectionToast.Kind) -> Void

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                switch screen {
                case .detail: itemDetail
                case .shipping: shippingConfirmation
                }
            }

            if isShowingSellOffer {
                SellOfferPresentation(
                    isSubmitting: isSubmitting,
                    onDismiss: dismissSellOffer
                ) {
                    InstantSellOfferView(
                        prize: item.prize,
                        isSubmitting: isSubmitting,
                        onSell: submitSale,
                        onKeep: dismissSellOffer
                    )
                }
                .transition(.opacity)
                .zIndex(15)
            }

            if let toast {
                CollectionToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .sheet(isPresented: $isPresentingShippingFunds) {
            AddFundsFlowView(isAuthenticated: $isAuthenticated)
                .presentationDetents([.large])
        }
        .interactiveDismissDisabled(isSubmitting)
        .onAppear { reloadAddressBook() }
        .onChange(of: screen) { _, newScreen in
            if newScreen == .shipping { reloadAddressBook() }
        }
        .fullScreenCover(isPresented: $isPresentingAddressManagement, onDismiss: reloadAddressBook) {
            ShippingAddressesView(hasAddress: $hasShippingAddress)
        }
    }

    private var sheetHeader: some View {
        VStack(spacing: 8) {
            if screen == .detail {
                Capsule().fill(Color.white.opacity(0.30)).frame(width: 38, height: 5)
            }
            HStack {
                if screen == .shipping {
                    Button { withAnimation(.snappy) { screen = .detail } } label: {
                        Image(systemName: "chevron.left").font(.headline)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }.buttonStyle(.plain).accessibilityLabel("Back to product details")
                    Spacer()
                }
                Text(screen == .detail ? "Product details" : "Ship to me").font(.title2.bold())
                Spacer()
                if screen == .detail {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }.buttonStyle(.plain).accessibilityLabel("Close product details")
                } else { Color.clear.frame(width: 44, height: 44) }
            }
        }
        .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 12)
    }

    private var itemDetail: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Image(item.prize.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)

                Text("POKÉMON TCG")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(BoxzyTheme.muted)

                Text(item.prize.name)
                    .boxzyFont(27, weight: .bold)
                    .fontWidth(.condensed)

                HStack {
                    Text("Current value")
                        .foregroundStyle(BoxzyTheme.muted)
                    Spacer()
                    Text(item.prize.value.usd)
                        .font(.title2.bold())
                }
                .font(.body)
                .padding(.vertical, 14)

                detailFact("checkmark.shield", "Factory sealed")
                detailFact("checkmark.circle", "Authenticity guaranteed")
                detailFact("shippingbox", "From: \(item.sourceBoxName)")
                detailFact("clock", "Auto-sells in \(item.automaticSaleCountdown.replacingOccurrences(of: " left", with: ""))")

                Button("Sell for \((Double(item.prize.value) * 0.90).collectionCurrency)") {
                    withAnimation(.snappy) { isShowingSellOffer = true }
                }
                .boxzyFont(16, weight: .semibold)
                .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 16))
                .padding(.top, 8)

                Button("Ship to Me") {
                    withAnimation(.snappy) { screen = .shipping }
                }
                .buttonStyle(BoxzySecondaryButtonStyle())
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 28)
        }
    }

    private func detailFact(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(BoxzyTheme.muted)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
        }
    }

    private var shippingConfirmation: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(item.prize.imageName).resizable().scaledToFit().frame(width: 102, height: 112)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.prize.name).font(.headline).fixedSize(horizontal: false, vertical: true)
                        Text("1 sealed item").font(.subheadline).foregroundStyle(BoxzyTheme.muted)
                    }
                    Spacer(minLength: 0)
                }.padding(.vertical, 8)
                if let selectedAccountAddress {
                    addressCard(ShippingAddress(selectedAccountAddress))
                } else {
                    VStack(spacing: 10) {
                        Text("No saved address").font(.headline)
                        Button("Add shipping address") { isPresentingAddressManagement = true }
                            .buttonStyle(BoxzyPrimaryButtonStyle())
                    }.padding(18).collectionSurface(cornerRadius: 16, opacity: 0.7)
                }
                feeCard
                Text("Payment source: BOXZY balance").font(.footnote).foregroundStyle(BoxzyTheme.muted)
                if balance < ShippingQuote.sample.total {
                    Text("Add \((ShippingQuote.sample.total - balance).collectionCurrency) to cover shipping.")
                        .boxzyFont(15).foregroundStyle(BoxzyTheme.muted)
                }
            }.padding(.horizontal, 22).padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                if balance < ShippingQuote.sample.total { isPresentingShippingFunds = true } else { submitShipment() }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting { ProgressView().tint(.black) }
                    Text(isSubmitting ? "Processing…" : (balance < ShippingQuote.sample.total ? "Add funds to ship" : "Pay $12.00 and Ship"))
                }.boxzyFont(16, weight: .semibold)
            }
            .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 16))
            .disabled(isSubmitting || selectedAccountAddress == nil)
            .padding(.horizontal, 22).padding(.vertical, 12).background(BoxzyTheme.background)
        }
    }

    private func addressCard(_ address: ShippingAddress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Shipping address").font(.headline).foregroundStyle(.white)
                Spacer(minLength: 4)
                Button("Change") { isPresentingAddressManagement = true }
                    .font(.subheadline.weight(.semibold)).foregroundStyle(BoxzyTheme.gold)
                    .frame(minWidth: 44, minHeight: 44).buttonStyle(.plain)
            }
            Text(address.name)
            Text(address.street)
            Text(address.city)
        }
        .font(.subheadline).foregroundStyle(BoxzyTheme.muted)
        .frame(maxWidth: .infinity, alignment: .leading).padding(18)
        .collectionSurface(cornerRadius: 16, opacity: 0.7)
    }

    private var feeCard: some View {
        VStack(spacing: 16) {
            Text("Example fees").font(.subheadline).foregroundStyle(BoxzyTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            feeRow("Shipping", "$9.00")
            feeRow("Handling fee", "$2.00")
            feeRow("Tax", "$1.00")
            Divider().overlay(Color.white.opacity(0.09))
            feeRow("Total", String(format: "$%.2f", ShippingQuote.sample.total), emphasized: true)
                .foregroundStyle(BoxzyTheme.gold)
        }.padding(18).collectionSurface(cornerRadius: 16, opacity: 0.7)
    }

    private func feeRow(_ label: String, _ value: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
        }
        .font(emphasized ? .headline : .body)
    }

    private func dismissSellOffer() {
        guard !isSubmitting else { return }
        withAnimation(.snappy) {
            isShowingSellOffer = false
        }
    }

    private func submitSale() {
        guard !isSubmitting else { return }
        isSubmitting = true
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            if ProcessInfo.processInfo.arguments.contains("-BoxzyForceSellFailure") {
                isSubmitting = false
                showLocalToast("Sale failed. Please try again.")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                onSold()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func submitShipment() {
        guard !isSubmitting else { return }
        guard let selectedAccountAddress else {
            isPresentingAddressManagement = true
            return
        }
        let address = ShippingAddress(selectedAccountAddress)
        guard balance >= ShippingQuote.sample.total else {
            showLocalToast("Insufficient balance for shipping.")
            return
        }
        isSubmitting = true
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            if ProcessInfo.processInfo.arguments.contains("-BoxzyForceShipFailure") {
                isSubmitting = false
                showLocalToast("Shipment failed. Please try again.")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                onShipped(address)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func reloadAddressBook() {
        selectedAccountAddress = AddressBookStore.defaultAddress()
    }

    private func showLocalToast(_ message: String) {
        let next = CollectionToast(message: message, kind: .error)
        withAnimation(.snappy) { toast = next }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard toast?.id == next.id else { return }
            withAnimation(.easeOut(duration: 0.2)) { toast = nil }
        }
    }
}

struct CollectionInventoryItem: Identifiable, Hashable {
    let id: String
    let prize: PullPrize
    let acquiredAt: Date
    var sourceBoxName: String {
        let source = UserDefaults.standard.string(forKey: "boxzy.inventory.source." + id)
        return MysteryBox.samples.first { $0.id == source }?.name ?? "Super Box"
    }

    var automaticSaleCountdown: String {
        let remaining = max(0, acquiredAt.addingTimeInterval(7 * 24 * 60 * 60).timeIntervalSinceNow)
        let days = Int(remaining) / 86_400
        let hours = (Int(remaining) % 86_400) / 3_600
        return days > 0 ? "\(days)d \(hours)h left" : "\(hours)h left"
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct UnopenedBoxItem: Identifiable, Codable, Hashable {
    enum Source: String, Codable {
        case purchased
        case weeklyReward
    }

    let id: String
    let boxID: String
    let source: Source
    let acquiredAt: Date
    let rankingPlace: Int?
    var paidAmount: Double? = nil
    var originalPaid: Double { paidAmount ?? (source == .weeklyReward ? 0 : ["starter":39.0,"super":89.0,"ultra":179.0][boxID] ?? 0) }

    var box: MysteryBox {
        MysteryBox.samples.first(where: { $0.id == boxID }) ?? MysteryBox.samples[1]
    }

    var detailText: String {
        switch source {
        case .purchased:
            "Purchased \(acquiredAt.formatted(date: .abbreviated, time: .omitted))\nPaid \(String(format: "$%.2f", originalPaid))"
        case .weeklyReward:
            "Sent to you for placing #\(rankingPlace ?? 3)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct CollectionShipment: Identifiable {
    let id: String
    let item: CollectionInventoryItem
    let addressName: String
    let requestedAt: Date
    let trackingNumber: String?

    init(
        id: String = UUID().uuidString,
        item: CollectionInventoryItem,
        addressName: String,
        requestedAt: Date,
        trackingNumber: String?
    ) {
        self.id = id
        self.item = item
        self.addressName = addressName
        self.requestedAt = requestedAt
        self.trackingNumber = trackingNumber
    }
}

struct ShippingAddress {
    var label: String
    var name: String
    var street: String
    var city: String
    var phone: String
    var email: String
    var isDefault: Bool

    init(_ accountAddress: AccountAddress) {
        label = accountAddress.label
        name = accountAddress.fullName
        street = accountAddress.streetLine
        city = accountAddress.cityLine
        phone = accountAddress.phone
        email = accountAddress.email
        isDefault = accountAddress.isDefault
    }

    init(label: String, name: String, street: String, city: String, phone: String, email: String, isDefault: Bool) {
        self.label = label
        self.name = name
        self.street = street
        self.city = city
        self.phone = phone
        self.email = email
        self.isDefault = isDefault
    }
}

enum UnopenedBoxStore {
    private static let storageKey = "boxzy.unopenedBoxes.v1"

    static func load() -> [UnopenedBoxItem] {
        if ProcessInfo.processInfo.arguments.contains("-BoxzyEmptyUnopened") { return [] }

        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: storageKey),
           let items = try? JSONDecoder().decode([UnopenedBoxItem].self, from: data) {
            return items
        }

        let acquiredAt = Date().addingTimeInterval(-3_600)
        let samples = [
            UnopenedBoxItem(
                id: "starter-purchased-demo",
                boxID: "starter",
                source: .purchased,
                acquiredAt: acquiredAt,
                rankingPlace: nil
            ),
            UnopenedBoxItem(
                id: "super-purchased-demo",
                boxID: "super",
                source: .purchased,
                acquiredAt: acquiredAt,
                rankingPlace: nil
            ),
            UnopenedBoxItem(
                id: "ultra-reward-demo",
                boxID: "ultra",
                source: .weeklyReward,
                acquiredAt: acquiredAt,
                rankingPlace: 3
            )
        ]
        save(samples)
        return samples
    }

    @discardableResult
    static func addPurchased(boxID: String) -> String {
        var items = load()
        let item = UnopenedBoxItem(
            id: "\(boxID)-purchased-\(UUID().uuidString)",
            boxID: boxID,
            source: .purchased,
            acquiredAt: .now,
            rankingPlace: nil,
            paidAmount: Double(MysteryBox.samples.first(where: { $0.id == boxID })?.price ?? 0)
        )
        items.insert(item, at: 0)
        save(items)
        return item.id
    }

    static func addWeeklyReward(boxID: String, placing: Int) {
        var items = load()
        items.insert(
            UnopenedBoxItem(
                id: "\(boxID)-reward-\(UUID().uuidString)",
                boxID: boxID,
                source: .weeklyReward,
                acquiredAt: .now,
                rankingPlace: placing
            ),
            at: 0
        )
        save(items)
    }

    static func remove(id: String) {
        var items = load()
        items.removeAll { $0.id == id }
        save(items)
    }

    static func save(_ items: [UnopenedBoxItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

enum CollectionInventoryStore {
    private static let vaultKey = "boxzy.collectionInventoryIDs"
    private static let shipmentKey = "boxzy.collectionShipmentIDs"
    private static let legacyDemoIDs = [
        "prismatic-demo-1", "celebrations-demo-1",
        "prismatic-demo-2", "celebrations-demo-2"
    ]
    private static let demoIDs = [
        "prismatic-demo-1", "celebrations-demo-1", "shining-demo-1",
        "prismatic-demo-2", "celebrations-demo-2", "shining-demo-2",
        "prismatic-demo-3", "celebrations-demo-3", "shining-demo-3"
    ]

    static func loadVault() -> [CollectionInventoryItem] {
        let defaults = UserDefaults.standard
        if ProcessInfo.processInfo.arguments.contains("-BoxzyEmptyCollection") { return [] }

        let ids: [String]
        if let stored = defaults.stringArray(forKey: vaultKey) {
            if stored == legacyDemoIDs {
                ids = demoIDs
                defaults.set(ids, forKey: vaultKey)
            } else {
                ids = stored
            }
        } else {
            ids = demoIDs
            defaults.set(ids, forKey: vaultKey)
        }
        return ids.compactMap(item(for:))
    }

    static func saveVault(_ items: [CollectionInventoryItem]) {
        UserDefaults.standard.set(items.map(\.id), forKey: vaultKey)
    }

    @discardableResult
    static func add(prizeID: String, receiptID: String = UUID().uuidString, sourceBoxID: String = "super") -> String {
        var ids = UserDefaults.standard.stringArray(forKey: vaultKey) ?? []
        let id = "\(prizeID)-\(receiptID)"
        guard !ids.contains(id) else { return id }
        ids.insert(id, at: 0)
        UserDefaults.standard.set(sourceBoxID, forKey: "boxzy.inventory.source." + id)
        UserDefaults.standard.set(Date(), forKey: "boxzy.inventory.acquired." + id)
        UserDefaults.standard.set(ids, forKey: vaultKey)
        return id
    }

    static func removePrize(id: String) {
        var ids = UserDefaults.standard.stringArray(forKey: vaultKey) ?? []
        ids.removeAll { $0 == id }
        UserDefaults.standard.set(ids, forKey: vaultKey)
    }

    static func loadShipments() -> [CollectionShipment] {
        guard !ProcessInfo.processInfo.arguments.contains("-BoxzyEmptyShipments") else { return [] }
        let storedIDs = UserDefaults.standard.stringArray(forKey: shipmentKey) ?? []
        let ids = storedIDs.isEmpty && ProcessInfo.processInfo.arguments.contains("-BoxzyShippedDemo")
            ? ["prismatic-shipment-demo"]
            : storedIDs
        return ids.compactMap { id in
            guard let item = item(for: id) else { return nil }
            let tracking = ProcessInfo.processInfo.arguments.contains("-BoxzyTrackingAvailable")
                ? "DEMO-TRACK-001" : nil
            return CollectionShipment(id: id, item: item, addressName: "Home", requestedAt: .now, trackingNumber: tracking)
        }
    }

    static func saveShipments(_ shipments: [CollectionShipment]) {
        UserDefaults.standard.set(shipments.map { $0.item.id }, forKey: shipmentKey)
    }

    private static func item(for id: String) -> CollectionInventoryItem? {
        let prize: PullPrize
        if let current = PullPrize.samples.first(where: { $0.id == id || id.hasPrefix($0.id + "-") }) {
            prize = current
        } else if id.contains("celebrations") {
            prize = PullPrize.samples[1]
        } else if id.contains("prismatic") {
            prize = PullPrize(
                id: "prismatic-evolutions-reveal",
                name: "151 Booster Bundle",
                value: id.contains("demo") ? 69 : 69,
                imageName: "prize-151-bundle",
                category: "BOOSTER BUNDLE",
                rarity: "RARE",
                boxID: "starter"
            )
        } else if id.contains("shining") {
            prize = PullPrize.samples[0]
        } else {
            prize = PullPrize.samples[2]
        }
        let key = "boxzy.inventory.acquired." + id
        let date = UserDefaults.standard.object(forKey: key) as? Date ?? Date().addingTimeInterval(-3600)
        UserDefaults.standard.set(date, forKey: key)
        return CollectionInventoryItem(id: id, prize: prize, acquiredAt: date)
    }
}

struct CollectionToast: Identifiable, Equatable {
    enum Kind { case success, error }
    let id = UUID()
    let message: String
    let kind: Kind
}

private struct CollectionToastView: View {
    let toast: CollectionToast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.kind == .error ? "xmark" : "checkmark")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(toast.kind == .error ? Color.red : BoxzyTheme.blue, in: Circle())

            Text(toast.message)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: 340)
        .frame(minHeight: 58)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
}

private extension View {
    func collectionSurface(cornerRadius: CGFloat = 16, opacity: Double = 0.62) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(BoxzyTheme.surface.opacity(max(0.72, opacity)))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                }
        )
    }
}

private extension Double {
    var collectionCurrency: String { String(format: "$%.2f", self) }
}

struct CollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionView(openBoxes: {})
            .frame(width: 402, height: 874)
            .preferredColorScheme(.dark)
            .previewDisplayName("Collection · iPhone 17 Pro")
    }
}
