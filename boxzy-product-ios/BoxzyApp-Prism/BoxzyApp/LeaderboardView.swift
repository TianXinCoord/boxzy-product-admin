import SwiftUI

struct LeaderboardView: View {
    private enum Period: String, CaseIterable, Identifiable {
        case thisWeek = "This Week"
        case lastWeek = "Prior Week"
        var id: Self { self }
    }

    @State private var period: Period = .thisWeek
    @State private var showsRules = false
    let openBoxes: () -> Void

    init(openBoxes: @escaping () -> Void = {}) {
        self.openBoxes = openBoxes
    }

    private var snapshot: LeaderboardSnapshot {
        period == .thisWeek ? .thisWeek : .lastWeek
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    periodPicker.padding(.top, 12)
                    periodStatus.padding(.top, 9)
                    LeaderboardPodium(entries: snapshot.leaders).padding(.top, 12)
                    MyRankCard(entry: snapshot.me, openBoxes: openBoxes).padding(.top, 10)

                    Text("LEADERBOARD")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundStyle(BoxzyTheme.gold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                        .padding(.bottom, 5)

                    VStack(spacing: 0) {
                        ForEach(snapshot.rankings) { RankingRow(entry: $0) }
                    }
                    .padding(.horizontal, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.028))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                            }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
        .sheet(isPresented: $showsRules) {
            RankingRulesSheet()
                .presentationDetents([.fraction(0.72)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .presentationBackground(BoxzyTheme.background)
        }
        .sensoryFeedback(.selection, trigger: period)
        .animation(.snappy(duration: 0.28), value: period)
    }

    private var header: some View {
        HStack {
            Text("Rankings").boxzyFont(28, weight: .bold)
            Spacer()
            Button("Rules") { showsRules = true }
                .boxzyFont(16).foregroundStyle(BoxzyTheme.gold)
                .frame(minWidth: 44, minHeight: 44).buttonStyle(.plain)
                .accessibilityLabel("How rankings work")
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 4) {
            ForEach(Period.allCases) { option in
                Button { period = option } label: {
                    Text(option.rawValue).boxzyFont(15, weight: .semibold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(period == option ? BoxzyTheme.background : BoxzyTheme.muted)
                        .background(period == option ? BoxzyTheme.gold : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain)
                .accessibilityAddTraits(period == option ? .isSelected : [])
            }
        }.padding(4).background(BoxzyTheme.surface, in: RoundedRectangle(cornerRadius: 14))

    }

    @ViewBuilder private var periodStatus: some View {
        if period == .thisWeek {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 7) {
                    Image(systemName: "clock")
                    Text("Resets in").foregroundStyle(BoxzyTheme.muted)
                    Text(resetText(at: context.date)).fontWeight(.semibold).monospacedDigit()
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 0.8)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        } else {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.circle")
                Text("Final results").foregroundStyle(BoxzyTheme.muted)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 0.8)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func resetText(at date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysUntilMonday = (9 - weekday) % 7
        let target = calendar.date(
            byAdding: .day,
            value: daysUntilMonday == 0 ? 7 : daysUntilMonday,
            to: calendar.startOfDay(for: date)
        ) ?? date
        let remaining = max(0, Int(target.timeIntervalSince(date)))
        return String(
            format: "%dd · %02dh · %02dm · %02ds",
            remaining / 86_400,
            (remaining % 86_400) / 3_600,
            (remaining % 3_600) / 60,
            remaining % 60
        )
    }
}

private struct RankingRulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let rules = [
        RankingRule(place: "1ST", boxName: "Ultra Box", imageName: "ultra-box", points: 650),
        RankingRule(place: "2ND", boxName: "Super Box", imageName: "super-box", points: 300),
        RankingRule(place: "3RD", boxName: "Starter Box", imageName: "starter-box", points: 50)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.28))
                .frame(width: 38, height: 5)
                .padding(.top, 10)

            HStack(alignment: .center) {
                Text("How Rankings Work")
                    .boxzyFont(24, weight: .bold)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .boxzyFont(17, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.07), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.top, 18)

            Text("Open boxes to earn points. Weekly top 3 receive rewards.")
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

            sheetSectionTitle("POINTS PER BOX")
                .padding(.top, 18)

            VStack(spacing: 0) {
                ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                    HStack(spacing: 12) {
                        Image(rule.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                        Text(rule.boxName)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(rule.points) PTS")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(BoxzyTheme.goldLight)
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 58)
                    .overlay(alignment: .bottom) {
                        if index < rules.count - 1 {
                            Rectangle().fill(BoxzyTheme.stroke.opacity(0.55)).frame(height: 0.5)
                                .padding(.leading, 55)
                        }
                    }
                }
            }
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 0.8)
            }
            .padding(.top, 9)

            sheetSectionTitle("WEEKLY REWARDS")
                .padding(.top, 16)

            HStack(spacing: 0) {
                ForEach(rules) { rule in
                    VStack(spacing: 4) {
                        Text(rule.place)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BoxzyTheme.goldLight)
                        Image(rule.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 50)
                        Text(rule.boxName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 0.8)
            }
            .padding(.top, 9)

            HStack(alignment: .top, spacing: 9) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(BoxzyTheme.goldLight)
                Text("Rewards are sent automatically to Collection · Unopened after weekly settlement.")
                    .font(.caption)
                    .foregroundStyle(BoxzyTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 13)

            Spacer(minLength: 10)

            Button { dismiss() } label: {
                Text("Got it")
                    .font(.headline)
                    .foregroundStyle(BoxzyTheme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(BoxzyTheme.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .background {
            LinearGradient(
                colors: [Color.white.opacity(0.035), BoxzyTheme.background],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        }
        .overlay(alignment: .top) {
            Rectangle().fill(BoxzyTheme.gold.opacity(0.55)).frame(height: 0.7)
        }
        .preferredColorScheme(.dark)
        }
    }

    private func sheetSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .tracking(1.7)
            .foregroundStyle(BoxzyTheme.goldLight)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RankingRule: Identifiable {
    let place: String
    let boxName: String
    let imageName: String
    let points: Int
    var id: String { imageName }
}

private struct LeaderboardPodium: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            PodiumSpot(entry: entries[1], size: 72).padding(.top, 28)
            PodiumSpot(entry: entries[0], size: 90).frame(maxWidth: .infinity)
            PodiumSpot(entry: entries[2], size: 72).padding(.top, 28)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.top, 17)
        .padding(.bottom, 12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 0.75)
                }
        }
    }
}

private struct PodiumSpot: View {
    let entry: LeaderboardEntry
    let size: CGFloat

    var body: some View {
        VStack(spacing: 5) {
            GeneratedRankingMedalBadge(rank: entry.rank, medal: entry.medal)
            .frame(width: size, height: size)

            Text(entry.username)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text("\(entry.points.formatted()) pts")
                .font(.system(size: entry.rank == 1 ? 18 : 16, weight: .bold))
                .foregroundStyle(BoxzyTheme.gold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct GeneratedRankingMedalBadge: View {
    let rank: Int
    let medal: LeaderboardMedal

    var body: some View {
        ZStack {
            Image("rank-\(rank)-medal")
                .resizable()
                .scaledToFit()
                .shadow(color: medal.color.opacity(rank == 1 ? 0.32 : 0.16), radius: rank == 1 ? 11 : 7)

            Text("\(rank)")
                .font(.system(size: rank == 1 ? 27 : 23, weight: .black, design: .rounded))
                .foregroundStyle(rank == 1 ? BoxzyTheme.background : Color.white.opacity(0.94))
                .shadow(color: rank == 1 ? .clear : .black.opacity(0.45), radius: 2, y: 1)
                .offset(y: rank == 1 ? 3 : -5)
        }
    }
}

private struct RankingMedalBadge: View {
    let rank: Int
    let medal: LeaderboardMedal

    var body: some View {
        ZStack {
            if rank == 1 {
                HexagonShape()
                    .fill(
                        LinearGradient(
                            colors: [BoxzyTheme.goldLight, BoxzyTheme.gold, BoxzyTheme.goldDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay { HexagonShape().stroke(Color.white.opacity(0.35), lineWidth: 0.8) }
                    .shadow(color: BoxzyTheme.gold.opacity(0.38), radius: 12)

                HexagonShape()
                    .inset(by: 9)
                    .stroke(BoxzyTheme.background.opacity(0.65), lineWidth: 1)

                Text("1")
                    .boxzyFont(30, weight: .black, design: .rounded)
                    .foregroundStyle(BoxzyTheme.background)

                Image(systemName: "crown.fill")
                    .boxzyFont(18, weight: .bold)
                    .foregroundStyle(BoxzyTheme.goldLight)
                    .offset(y: -50)

                HStack(spacing: 28) {
                    LaurelSprig().stroke(BoxzyTheme.goldLight, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    LaurelSprig().stroke(BoxzyTheme.goldLight, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)).scaleEffect(x: -1)
                }
                .frame(width: 82, height: 32)
                .offset(y: 37)
            } else {
                RibbonTailShape()
                    .fill(medal.color.opacity(0.62))
                    .frame(width: 56, height: 34)
                    .offset(y: 33)

                ShieldShape()
                    .fill(
                        LinearGradient(
                            colors: [medal.color.opacity(0.92), medal.color.opacity(0.48), Color.black.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay { ShieldShape().stroke(medal.color, lineWidth: 1.35) }
                    .shadow(color: medal.color.opacity(0.22), radius: 8)

                ShieldShape()
                    .inset(by: 7)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.7)

                Text("\(rank)")
                    .boxzyFont(24, weight: .black, design: .rounded)
                    .foregroundStyle(.white.opacity(0.92))
                    .offset(y: -3)
            }
        }
    }
}

private struct HexagonShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let points = [
            CGPoint(x: r.midX, y: r.minY), CGPoint(x: r.maxX, y: r.minY + r.height * 0.25),
            CGPoint(x: r.maxX, y: r.maxY - r.height * 0.25), CGPoint(x: r.midX, y: r.maxY),
            CGPoint(x: r.minX, y: r.maxY - r.height * 0.25), CGPoint(x: r.minX, y: r.minY + r.height * 0.25)
        ]
        var path = Path()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> HexagonShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

private struct ShieldShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        path.move(to: CGPoint(x: r.midX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.16))
        path.addLine(to: CGPoint(x: r.maxX * 0.96, y: r.maxY - r.height * 0.3))
        path.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY), control: CGPoint(x: r.maxX * 0.8, y: r.maxY * 0.9))
        path.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.04, y: r.maxY - r.height * 0.3), control: CGPoint(x: r.minX + r.width * 0.2, y: r.maxY * 0.9))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.16))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> ShieldShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

private struct RibbonTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.33))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.82, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct LaurelSprig: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY), control: CGPoint(x: rect.width * 0.25, y: rect.height * 0.82))
        for step in 0..<4 {
            let t = CGFloat(step) / 4
            let x = rect.maxX - rect.width * (0.16 + 0.2 * t)
            let y = rect.maxY - rect.height * (0.18 + 0.19 * t)
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 7, y: y - 5))
        }
        return path
    }
}

private struct MyRankCard: View {
    let entry: LeaderboardEntry
    let openBoxes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
            Text("ME")
                .font(.headline.weight(.bold))
                .foregroundStyle(BoxzyTheme.goldLight)
                .frame(width: 48, height: 48)
                .overlay { Circle().stroke(BoxzyTheme.gold, lineWidth: 1.3) }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("#\(entry.rank)").font(.subheadline.weight(.bold))
                    Text("·").foregroundStyle(BoxzyTheme.muted)
                    Text(entry.username)
                        .font(.subheadline)
                        .foregroundStyle(BoxzyTheme.muted)
                        .lineLimit(1)
                }
                HStack(spacing: 5) {
                    Text("\(entry.points.formatted()) pts")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(BoxzyTheme.gold)
                }
            }
            Spacer(minLength: 3)
        }
            Button(action: openBoxes) {
                HStack(spacing: 5) {
                    Text("Open more boxes")
                    Image(systemName: "arrow.right")
                }
                .boxzyFont(16, weight: .medium)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .buttonStyle(.plain)
            .foregroundStyle(BoxzyTheme.goldLight)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BoxzyTheme.stroke, lineWidth: 1)
                }
        }
    }
}

private struct RankingRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 10) {
            Text("#\(entry.rank)")
                .foregroundStyle(BoxzyTheme.muted)
                .frame(width: 38, alignment: .leading)
            Text(entry.username).font(.subheadline.weight(.semibold)).lineLimit(1)
            Spacer(minLength: 6)
            Text("\(entry.points.formatted()) pts")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BoxzyTheme.stroke.opacity(0.58)).frame(height: 0.5)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LeaderboardEntry: Identifiable {
    let rank: Int
    let username: String
    let points: Int
    let medal: LeaderboardMedal
    var id: Int { rank }
}

private struct LeaderboardSnapshot {
    let leaders: [LeaderboardEntry]
    let me: LeaderboardEntry
    let rankings: [LeaderboardEntry]

    static let thisWeek = LeaderboardSnapshot(
        leaders: [
            .init(rank: 1, username: "VaultRunner", points: 7_840, medal: .gold),
            .init(rank: 2, username: "PikaChase22", points: 6_530, medal: .silver),
            .init(rank: 3, username: "TrainerMia", points: 5_288, medal: .bronze)
        ],
        me: .init(rank: 243, username: "user_2b4fae55", points: 241, medal: .standard),
        rankings: [
            .init(rank: 4, username: "RareFinds90", points: 4_906, medal: .standard),
            .init(rank: 5, username: "GottaPullEmAll", points: 4_522, medal: .standard),
            .init(rank: 6, username: "CardKing_USA", points: 4_188, medal: .standard),
            .init(rank: 7, username: "TCG_Hunter", points: 3_764, medal: .standard),
            .init(rank: 8, username: "RareHunter", points: 3_421, medal: .standard)
        ]
    )

    static let lastWeek = LeaderboardSnapshot(
        leaders: [
            .init(rank: 1, username: "PikaChase22", points: 9_350, medal: .gold),
            .init(rank: 2, username: "RareFinds90", points: 8_100, medal: .silver),
            .init(rank: 3, username: "GottaPullEmAll", points: 7_450, medal: .bronze)
        ],
        me: .init(rank: 198, username: "user_2b4fae55", points: 350, medal: .standard),
        rankings: [
            .init(rank: 4, username: "VaultRunner", points: 6_920, medal: .standard),
            .init(rank: 5, username: "TrainerMia", points: 6_350, medal: .standard),
            .init(rank: 6, username: "CardKing_USA", points: 5_880, medal: .standard),
            .init(rank: 7, username: "TCG_Hunter", points: 5_410, medal: .standard),
            .init(rank: 8, username: "RareHunter", points: 4_990, medal: .standard)
        ]
    )
}

private enum LeaderboardMedal {
    case gold, silver, bronze, standard
    var color: Color {
        switch self {
        case .gold: BoxzyTheme.goldLight
        case .silver: Color(red: 0.72, green: 0.72, blue: 0.70)
        case .bronze: Color(red: 0.72, green: 0.43, blue: 0.20)
        case .standard: BoxzyTheme.gold
        }
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
            .frame(width: 402, height: 874)
            .preferredColorScheme(.dark)
    }
}
