import SwiftUI

struct PrizeDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let prize: PullPrize
    let boxes: [MysteryBox]
    let viewBox: (MysteryBox) -> Void

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    productImage.padding(.top, 2)
                    prizeInformation.padding(.top, 4)
                    availableSection.padding(.top, 16)
                    sealedNote.padding(.top, 16).padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { sheetHeader }
        .preferredColorScheme(.dark)
        .statusBarHidden(false)
    }

    private var sheetHeader: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color.white.opacity(0.38))
                .frame(width: 36, height: 5)

            HStack {
                Text("Product details")
                    .font(.title2.weight(.bold))

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.surface.opacity(0.78), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close product details")
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 7)
        .padding(.bottom, 6)
        .background(BoxzyTheme.background.opacity(0.94))
    }

    private var productImage: some View {
        Image(prize.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 224)
            .accessibilityLabel(prize.name)
    }

    private var prizeInformation: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(prize.rarity)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(BoxzyTheme.blue)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(BoxzyTheme.blue, lineWidth: 1)
                }

            Text(prize.category)
                .font(.footnote.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(BoxzyTheme.muted)

            Text(prize.name)
                .boxzyFont(26, weight: .bold)
                .fontWidth(.condensed)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(prize.value.usd)
                .boxzyFont(38, weight: .bold, design: .rounded)

            Text("Estimated market value")
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
        }
    }

    private var availableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available in")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(validAvailabilities.enumerated()), id: \.element.availability.id) { index, item in
                    Button { viewBox(item.box) } label: {
                        AvailabilityRow(box: item.box, dropChance: item.availability.dropChance)
                    }
                    .buttonStyle(.plain)

                    if index < validAvailabilities.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.07))
                            .padding(.leading, 78)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [BoxzyTheme.surface.opacity(0.82), BoxzyTheme.surface.opacity(0.46)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
    }

    private var validAvailabilities: [(availability: PrizeBoxAvailability, box: MysteryBox)] {
        prize.availabilities.compactMap { availability in
            boxes.first(where: { $0.id == availability.boxID }).map {
                (availability: availability, box: $0)
            }
        }
    }

    private var sealedNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield")
                .font(.title3.weight(.medium))
                .foregroundStyle(BoxzyTheme.blue)

            Text("100% Sealed product")
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AvailabilityRow: View {
    let box: MysteryBox
    let dropChance: String

    var body: some View {
        HStack(spacing: 12) {
            Image(box.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(box.name.capitalized + " Box")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)

                Text("SAMPLE ODDS")
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(BoxzyTheme.starter)
                    .padding(.horizontal, 8)
                    .frame(height: 23)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(BoxzyTheme.starter.opacity(0.68), lineWidth: 1)
                    }
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            Text("View")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BoxzyTheme.blue)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BoxzyTheme.muted)
        }
        .padding(.horizontal, 12)
        .frame(height: 76)
        .contentShape(Rectangle())
    }
}

struct PrizeDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        PrizeDetailsView(
            prize: PullPrize.samples[0],
            boxes: MysteryBox.samples,
            viewBox: { _ in }
        )
        .frame(width: 402, height: 874)
    }
}
