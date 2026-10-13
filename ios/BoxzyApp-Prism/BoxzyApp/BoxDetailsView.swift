import SwiftUI

struct BoxDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selectedBoxID: MysteryBox.ID
    @State private var expandedTiers: Set<String> = ["grail", "legendary"]
    @State private var selectedPrize: PullPrize?
    @AppStorage("boxzy.selectedBoxID") private var storedBox = "starter"
    let onBuy: (MysteryBox) -> Void

    private let boxes: [MysteryBox]
    private let tiers = PrizeTier.samples

    init(initialBoxID: MysteryBox.ID = "starter", onBuy: @escaping (MysteryBox) -> Void = { _ in }) {
        self.onBuy = onBuy
        let allBoxes = MysteryBox.samples
        boxes = ["starter", "super", "elite", "ultra"].compactMap { id in
            allBoxes.first(where: { $0.id == id })
        }
        _selectedBoxID = State(initialValue: initialBoxID)
    }

    private var selectedBox: MysteryBox {
        boxes.first(where: { $0.id == selectedBoxID }) ?? boxes[0]
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    sheetHeader
                    boxSelector
                    valueSummary
                    Text("SAMPLE ARTWORK, VALUES & ODDS")
                        .font(.caption).foregroundStyle(BoxzyTheme.muted)

                    ForEach(tiers) { tier in
                        PrizeTierSection(
                            tier: tier,
                            isExpanded: expandedTiers.contains(tier.id),
                            toggle: { toggle(tier.id) },
                            selectPrize: { selectedPrize = $0 }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 12)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: buySelectedBox) {
                Text("Buy now · \(selectedBox.price.usd)")
            }
            .font(.headline)
            .buttonStyle(BoxzyPrimaryButtonStyle(height: 52))
            .accessibilityIdentifier("details.buy")
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [.clear, BoxzyTheme.background.opacity(0.98)],
                    startPoint: .top,
                    endPoint: .center
                )
            )
        }
        .sheet(item: $selectedPrize) { prize in
            PrizeDetailsView(prize: prize, boxes: boxes) { box in
                selectedPrize = nil
                selectedBoxID = box.id
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .presentationBackground(BoxzyTheme.background)
        }
        .onChange(of: selectedBoxID) { _, id in storedBox = id }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var sheetHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Box details")
                    .font(.title2.weight(.bold))

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.surface.opacity(0.78), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close box details")
            }
        }
    }

    @ViewBuilder private var boxSelector: some View {
        if typeSize.isAccessibilitySize {
            ScrollView(.horizontal, showsIndicators: false) { boxOptions }
        } else { boxOptions }
    }
    private var boxOptions: some View {
        HStack(spacing: 8) {
            ForEach(boxes) { box in
                Button {
                    withAnimation(.snappy) { selectedBoxID = box.id }
                } label: {
                    DetailBoxOption(box: box, isSelected: box.id == selectedBoxID)
                        .frame(width: typeSize.isAccessibilitySize ? 190 : nil)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            LinearGradient(
                colors: [BoxzyTheme.surface.opacity(0.84), BoxzyTheme.surface.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .sensoryFeedback(.selection, trigger: selectedBoxID)
    }

    private var valueSummary: some View {
        (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 16)) : AnyLayout(HStackLayout(spacing: 0))) {
            DetailValueCell(title: "MIN VALUE", value: selectedBox.minimumLabel)

            if !typeSize.isAccessibilitySize {
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 46)
            }

            DetailValueCell(title: "MAX VALUE", value: selectedBox.maximumLabel)
        }
        .frame(minHeight: 64)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [BoxzyTheme.surface, BoxzyTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func toggle(_ tierID: String) {
        withAnimation(.snappy) {
            if expandedTiers.contains(tierID) {
                expandedTiers.remove(tierID)
            } else {
                expandedTiers.insert(tierID)
            }
        }
    }

    private func buySelectedBox() {
        storedBox = selectedBox.id
        onBuy(selectedBox)
        dismiss()
    }
}

private struct DetailBoxOption: View {
    let box: MysteryBox
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(box.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 64)

            Text(box.name.capitalized)
                .boxzyFont(13, weight: .semibold)
                .foregroundStyle(isSelected ? BoxzyTheme.blue : Color.primary.opacity(0.72))

            Text(box.price.usd)
                .boxzyFont(12, weight: .bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? BoxzyTheme.blue.opacity(0.11) : .clear)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? BoxzyTheme.blue.opacity(0.72) : .clear, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct DetailValueCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(BoxzyTheme.muted)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(BoxzyTheme.blue)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PrizeTierSection: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let tier: PrizeTier
    let isExpanded: Bool
    let toggle: () -> Void
    let selectPrize: (PullPrize) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: toggle) {
                (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))) {
                    Text("\(tier.name)  \(tier.chance)")
                        .boxzyFont(12, weight: .bold)
                        .foregroundStyle(tier.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8).frame(minHeight: 32)
                        .background(tier.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tier.tint, lineWidth: 1)
                        }

                    Text(tier.valueRange)
                        .boxzyFont(12)
                        .foregroundStyle(BoxzyTheme.muted)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.down")
                        .boxzyFont(12, weight: .bold)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.surface.opacity(0.82), in: Circle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(tier.prizes) { prize in
                            Button {
                                selectPrize(prize)
                            } label: {
                                DetailPrizeCard(prize: prize, tint: tier.tint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 1)
                }
                .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct DetailPrizeCard: View {
    let prize: PullPrize
    let tint: Color
    @ScaledMetric(relativeTo: .body) private var cardWidth = 130.0

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(prize.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 108)

            Text(prize.value.usd)
                .font(.headline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(tint)

            Text(prize.name)
                .boxzyFont(15, weight: .medium)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
        }
        .padding(11)
        .frame(width: cardWidth)
        .frame(minHeight: 184, alignment: .top)
        .background(
            LinearGradient(
                colors: [BoxzyTheme.surface.opacity(0.74), BoxzyTheme.surface.opacity(0.44)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )

    }
}

private struct PrizeTier: Identifiable {
    let id: String
    let name: String
    let chance: String
    let valueRange: String
    let tint: Color
    let prizes: [PullPrize]
}

private extension PrizeTier {
    static let samples: [PrizeTier] = [
        .init(
            id: "grail",
            name: "GRAIL",
            chance: "0.4%",
            valueRange: "$700 – $1,175",
            tint: BoxzyTheme.goldLight,
            prizes: [
                .init(name: "151 Center ETB", value: 1_175, imageName: "prize-151-etb"),
                .init(name: "151 Booster Bundle", value: 950, imageName: "prize-151-bundle"),
                .init(name: "Legendary Treasures", value: 700, imageName: "prize-legendary-pack")
            ]
        ),
        .init(
            id: "legendary",
            name: "LEGENDARY",
            chance: "1.8%",
            valueRange: "$295 – $699",
            tint: BoxzyTheme.gold,
            prizes: [
                .init(name: "151 Center ETB", value: 699, imageName: "prize-151-etb"),
                .init(name: "151 Booster Bundle", value: 550, imageName: "prize-151-bundle"),
                .init(name: "Legendary Treasures", value: 299, imageName: "prize-legendary-pack")
            ]
        ),
        .init(
            id: "epic",
            name: "EPIC",
            chance: "6.2%",
            valueRange: "$149 – $294",
            tint: BoxzyTheme.gold,
            prizes: [PullPrize.samples[2]]
        ),
        .init(
            id: "rare",
            name: "RARE",
            chance: "20.1%",
            valueRange: "$69 – $148",
            tint: BoxzyTheme.blue,
            prizes: Array(PullPrize.samples.prefix(2))
        )
    ]
}
