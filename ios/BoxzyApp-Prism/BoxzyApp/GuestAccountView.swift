import SwiftUI
import UIKit

struct AccountTabView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-BoxzyGuestPreview") {
            GuestAccountView(isAuthenticated: .constant(false))
        } else { accountBody }
#else
        accountBody
#endif
    }
    @ViewBuilder private var accountBody: some View {
        if isAuthenticated {
            SignedInAccountView(isAuthenticated: $isAuthenticated)
        } else {
            GuestAccountView(isAuthenticated: $isAuthenticated)
        }
    }
}

private struct GuestAccountView: View {
    private enum PresentedSheet: Identifiable {
        case terms
        case privacy

        var id: Self { self }
    }

    @Binding var isAuthenticated: Bool
    @State private var isPresentingSignIn = false
    @State private var isPresentingAddFunds = false
    @State private var continuesToAddFundsAfterSignIn = false
    @State private var presentedSheet: PresentedSheet?
    @State private var isPresentingSupport = false

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()


            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        BoxzyHeaderView(balance: 0) {
                            continuesToAddFundsAfterSignIn = true
                            isPresentingSignIn = true
                        }

                        Text("Account")
                            .boxzyFont(30, weight: .bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 32)

                        Spacer(minLength: 0)

                        AccountGlyph()
                            .stroke(BoxzyTheme.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            .frame(width: 64, height: 64)
                            .frame(width: 118, height: 118)
                            .accessibilityHidden(true)

                        Text("Sign in to continue.")
                            .boxzyFont(27, weight: .bold)
                            .padding(.top, 31)

                        Text("Manage your balance, collection,\nshipping, and rewards.")
                            .font(.subheadline)
                            .foregroundStyle(Color(red: 0.76, green: 0.75, blue: 0.75))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.top, 11)

                        Button {
                            continuesToAddFundsAfterSignIn = false
                            isPresentingSignIn = true
                        } label: {
                            Text("SIGN IN")
                                .font(.subheadline.weight(.semibold))
                                .tracking(0.4)
                                .foregroundStyle(BoxzyTheme.background)
                                .frame(width: 136, height: 45)
                                .background(
                                    BoxzyTheme.primaryGradient,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                                .shadow(color: BoxzyTheme.blue.opacity(0.24), radius: 12, y: 5)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 25)

                        Button {
                            isPresentingSupport = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "headphones")
                                    .boxzyFont(21, weight: .medium)
                                    .foregroundStyle(BoxzyTheme.gold)
                                    .frame(width: 28)

                                Text("Customer Support")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .boxzyFont(15, weight: .semibold)
                                    .foregroundStyle(Color(red: 0.55, green: 0.54, blue: 0.53))
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 62)
                            .background {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [BoxzyTheme.surface, BoxzyTheme.background],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 42)

                        Spacer(minLength: 26)
                    }
                    .frame(minHeight: geometry.size.height)
                    .padding(.horizontal, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentingSignIn) {
            WelcomeSignInView(
                authenticated: {
                    isAuthenticated = true
                    isPresentingSignIn = false
                    if continuesToAddFundsAfterSignIn {
                        continuesToAddFundsAfterSignIn = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            isPresentingAddFunds = true
                        }
                    }
                },
                headline: "Sign in to continue",
                supportingMessage: "Sign in to continue your BOXZY experience.",
                close: {
                    continuesToAddFundsAfterSignIn = false
                    isPresentingSignIn = false
                }
            )
        }
        .sheet(isPresented: $isPresentingAddFunds) {
            AddFundsFlowView(isAuthenticated: $isAuthenticated)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
                .presentationBackground(BoxzyTheme.background)
        }
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .terms:
                AccountLegalSheet(title: "Terms of Service")
            case .privacy:
                AccountLegalSheet(title: "Privacy Policy")
            }
        }
        .fullScreenCover(isPresented: $isPresentingSupport) {
            CustomerSupportSheet()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct BoxzyBoxMark: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(BoxzyTheme.blue.opacity(0.20))
                .frame(width: 86, height: 32)
                .blur(radius: 18)
                .offset(y: 31)

            Canvas { context, size in
                let width = size.width
                let height = size.height

                var top = Path()
                top.move(to: CGPoint(x: width * 0.14, y: height * 0.30))
                top.addLine(to: CGPoint(x: width * 0.50, y: height * 0.10))
                top.addLine(to: CGPoint(x: width * 0.86, y: height * 0.30))
                top.addLine(to: CGPoint(x: width * 0.50, y: height * 0.51))
                top.closeSubpath()
                context.fill(top, with: .linearGradient(
                    Gradient(colors: [BoxzyTheme.goldLight, BoxzyTheme.gold]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: width, y: height)
                ))

                var left = Path()
                left.move(to: CGPoint(x: width * 0.14, y: height * 0.30))
                left.addLine(to: CGPoint(x: width * 0.50, y: height * 0.51))
                left.addLine(to: CGPoint(x: width * 0.50, y: height * 0.90))
                left.addLine(to: CGPoint(x: width * 0.14, y: height * 0.69))
                left.closeSubpath()
                context.fill(left, with: .color(BoxzyTheme.goldDeep))

                var right = Path()
                right.move(to: CGPoint(x: width * 0.50, y: height * 0.51))
                right.addLine(to: CGPoint(x: width * 0.86, y: height * 0.30))
                right.addLine(to: CGPoint(x: width * 0.86, y: height * 0.69))
                right.addLine(to: CGPoint(x: width * 0.50, y: height * 0.90))
                right.closeSubpath()
                context.fill(right, with: .color(BoxzyTheme.gold))

                var tape = Path()
                tape.move(to: CGPoint(x: width * 0.38, y: height * 0.17))
                tape.addLine(to: CGPoint(x: width * 0.53, y: height * 0.09))
                tape.addLine(to: CGPoint(x: width * 0.68, y: height * 0.18))
                tape.addLine(to: CGPoint(x: width * 0.53, y: height * 0.26))
                tape.closeSubpath()
                context.fill(tape, with: .color(BoxzyTheme.goldLight))

                var frontTape = Path()
                frontTape.move(to: CGPoint(x: width * 0.50, y: height * 0.51))
                frontTape.addLine(to: CGPoint(x: width * 0.64, y: height * 0.43))
                frontTape.addLine(to: CGPoint(x: width * 0.64, y: height * 0.63))
                frontTape.addLine(to: CGPoint(x: width * 0.58, y: height * 0.60))
                frontTape.addLine(to: CGPoint(x: width * 0.50, y: height * 0.66))
                frontTape.closeSubpath()
                context.fill(frontTape, with: .color(BoxzyTheme.gold))
            }
            .shadow(color: .black.opacity(0.34), radius: 4, y: 3)
        }
        .accessibilityHidden(true)
    }
}

private struct LegacyCustomerSupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    var transactionID: String?

    init(transactionID: String? = nil) {
        self.transactionID = transactionID
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(BoxzyTheme.muted.opacity(0.55))
                    .frame(width: 42, height: 5)
                    .padding(.top, 10)

                HStack {
                    Text("Customer Support")
                        .boxzyFont(23, weight: .bold)
                        .foregroundStyle(.white)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .boxzyFont(17, weight: .semibold)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(BoxzyTheme.surface, in: Circle())
                            .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.55), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.top, 10)

                Image(systemName: "headphones")
                    .boxzyFont(27, weight: .medium)
                    .foregroundStyle(BoxzyTheme.blue)
                    .frame(width: 58, height: 58)
                    .background(BoxzyTheme.blue.opacity(0.12), in: Circle())
                    .overlay(Circle().stroke(BoxzyTheme.blue.opacity(0.24), lineWidth: 1))
                    .padding(.top, 10)

                Text(supportingCopy)
                    .boxzyFont(14)
                    .foregroundStyle(BoxzyTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .boxzyFont(15, weight: .semibold)
                        .foregroundStyle(BoxzyTheme.blue)
                        .frame(width: 38, height: 38)
                        .background(BoxzyTheme.blue.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("EMAIL SUPPORT")
                            .boxzyFont(12, weight: .bold)
                            .tracking(1.3)
                            .foregroundStyle(BoxzyTheme.muted)
                        Text("support@boxzy.com")
                            .boxzyFont(15, weight: .semibold)
                            .foregroundStyle(BoxzyTheme.gold)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .boxzyFont(13, weight: .semibold)
                        .foregroundStyle(BoxzyTheme.blue)
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                .background(BoxzyTheme.surface.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BoxzyTheme.stroke.opacity(0.48), lineWidth: 1)
                }
                .padding(.top, 16)

                Button {
                    openSupportEmail()
                } label: {
                    Label("EMAIL SUPPORT", systemImage: "paperplane.fill")
                        .boxzyFont(15, weight: .bold)
                        .tracking(0.6)
                }
                .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 15))
                .padding(.top, 14)

                Text("Typical response time: within 24 hours")
                    .boxzyFont(12)
                    .foregroundStyle(BoxzyTheme.muted.opacity(0.72))
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .presentationDetents([.fraction(0.50)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(BoxzyTheme.background)
    }

    private var supportingCopy: String {
        if let transactionID {
            return "Our support team will receive transaction \(transactionID) with your message."
        }
        return "Questions about an order, withdrawal, shipping, or your account? We’re here to help."
    }

    private func openSupportEmail() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "support@boxzy.com"
        if let transactionID {
            components.queryItems = [
                URLQueryItem(name: "subject", value: "Transaction support · \(transactionID)"),
                URLQueryItem(name: "body", value: "Transaction ID: \(transactionID)\n\nPlease describe how we can help:")
            ]
        }
        if let url = components.url { openURL(url) }
    }
}

private struct HelpArticleSection: Hashable, Identifiable {
    let id: String
    let label: String
    let title: String
    let body: String

    init(label: String, title: String, body: String) {
        self.id = label
        self.label = label
        self.title = title
        self.body = body
    }
}

private struct HelpArticle: Hashable, Identifiable {
    let id: String
    let question: String
    let summary: String
    let sections: [HelpArticleSection]

    init(id: String, question: String, summary: String, sections: [HelpArticleSection] = []) {
        self.id = id
        self.question = question
        self.summary = summary
        self.sections = sections
    }
}

private struct HelpTopic: Hashable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let articles: [HelpArticle]
}

private enum HelpContent {
    static let topics: [HelpTopic] = [
        HelpTopic(
            id: "boxes",
            title: "Boxes & Unboxing",
            subtitle: "How boxes work, odds, and opening.",
            icon: "cube",
            articles: [
                HelpArticle(
                    id: "box-how-it-works",
                    question: "How do mystery boxes work?",
                    summary: "Before buying, tap a box to see its pull odds and prize value range. After purchase, swipe to choose a box number, then tap Open Box to reveal your prize. Use Open later to keep it in Collection → Unopened."
                ),
                HelpArticle(
                    id: "box-odds",
                    question: "Can I see the odds before buying?",
                    summary: "Yes. Each box details page shows the pull odds for its prize tiers and the possible value range before you purchase."
                )
            ]
        ),
        HelpTopic(
            id: "items",
            title: "Items & Collection",
            subtitle: "Keep, sell, or ship items from your collection.",
            icon: "tag",
            articles: [
                HelpArticle(
                    id: "item-actions",
                    question: "What can I do after receiving an item?",
                    summary: "Eligible items can be kept, sold, or shipped.",
                    sections: [
                        HelpArticleSection(label: "KEEP", title: "Keep it in your collection", body: "Your item stays safely stored in your Collection."),
                        HelpArticleSection(label: "SELL", title: "Convert it to balance", body: "Sell instantly and add the proceeds to your available balance."),
                        HelpArticleSection(label: "SHIP", title: "Have it delivered", body: "Send the physical item to your default shipping address.")
                    ]
                ),
                HelpArticle(
                    id: "vault-period",
                    question: "How does the 7-day Vault period work?",
                    summary: "An item can remain in your Vault for up to 7 days. If you do not request shipping during that time, it is automatically sold for 90% of its listed value."
                ),
                HelpArticle(
                    id: "undo-sale",
                    question: "Can I undo a sale?",
                    summary: "No. A sale takes effect immediately and cannot be reversed. The proceeds are added to your available balance right away."
                )
            ]
        ),
        HelpTopic(
            id: "payments",
            title: "Payments & Balance",
            subtitle: "Deposits, withdrawals, and payout timing.",
            icon: "creditcard",
            articles: [
                HelpArticle(
                    id: "balance-types",
                    question: "What is my Available Balance?",
                    summary: "Your Available Balance can be used to open boxes or withdrawn through Coinflow."
                ),
                HelpArticle(
                    id: "deposit",
                    question: "How do I add funds?",
                    summary: "Tap your balance at the top of the app. You can then choose an available payment method and enter the amount you want to add."
                ),
                HelpArticle(
                    id: "withdraw",
                    question: "How do I withdraw funds?",
                    summary: "Go to Account, tap Withdraw, and enter at least $6.00. Withdrawals are securely processed through Coinflow."
                ),
                HelpArticle(
                    id: "payout-time",
                    question: "When will my withdrawal arrive?",
                    summary: "Coinflow withdrawals usually arrive within 1–3 business days."
                )
            ]
        ),
        HelpTopic(
            id: "shipping",
            title: "Shipping",
            subtitle: "Costs, delivery times, and addresses.",
            icon: "truck.box",
            articles: [
                HelpArticle(
                    id: "shipping-cost",
                    question: "How is shipping calculated?",
                    summary: "Shipping depends on the item type and destination. Items valued at $500 or more require shipping insurance. You will see the full cost before confirming."
                ),
                HelpArticle(
                    id: "shipping-time",
                    question: "How long does shipping take?",
                    summary: "Orders usually leave the fulfillment center within 15–20 business days. Delivery time then depends on the carrier and destination. A tracking number is provided after shipment."
                ),
                HelpArticle(
                    id: "shipping-address",
                    question: "How do I update my shipping address?",
                    summary: "Go to Account and open Shipping to add, edit, remove, or choose your default delivery address."
                )
            ]
        ),
        HelpTopic(
            id: "account",
            title: "Account",
            subtitle: "Profile settings and customer support.",
            icon: "person",
            articles: [
                HelpArticle(id: "username", question: "How do I change my username?", summary: "Go to Account and tap Edit beside your profile to update your username."),
                HelpArticle(id: "contact", question: "How do I contact support?", summary: "Open Account, choose Customer Support, then copy our support email address.")
            ]
        )
    ]
}

struct CustomerSupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var previewPath = NavigationPath()
    @State private var showsCopiedToast = false
    let transactionID: String?

    init(transactionID: String? = nil) {
        self.transactionID = transactionID
    }

    var body: some View {
        NavigationStack(path: $previewPath) {
            ZStack {
                BoxzyTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        helpHeader(title: "Help Center", backAction: { dismiss() })

                        searchField.padding(.top, 26)

                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            topicList.padding(.top, 34)
                            contactSection.padding(.top, 34)
                        } else {
                            searchResults.padding(.top, 32)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
            }
            .navigationDestination(for: HelpTopic.self) { topic in
                HelpTopicScreen(topic: topic)
            }
            .navigationDestination(for: HelpArticle.self) { article in
                HelpArticleScreen(article: article, topicTitle: topicTitle(for: article))
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
#if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if previewPath.isEmpty && (args.contains("-BoxzySupportTopic") || args.contains("-BoxzySupportArticle")) {
                previewPath.append(HelpContent.topics[0])
                if args.contains("-BoxzySupportArticle") { previewPath.append(HelpContent.topics[0].articles[0]) }
            }
#endif
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) {
            if showsCopiedToast {
                Label("Email copied", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(BoxzyTheme.surface, in: Capsule())
                    .overlay(Capsule().stroke(BoxzyTheme.gold.opacity(0.55), lineWidth: 1))
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 13) {
            Image(systemName: "magnifyingglass")
                .boxzyFont(20, weight: .medium)
                .foregroundStyle(BoxzyTheme.muted)
            TextField("Search help articles", text: $searchText)
                .boxzyFont(16)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(BoxzyTheme.surface.opacity(0.58), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
    }

    private var topicList: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("BROWSE BY TOPIC")
            ForEach(HelpContent.topics) { topic in
                NavigationLink(value: topic) {
                    HStack(spacing: 14) {
                        Image(systemName: topic.icon)
                            .boxzyFont(20, weight: .medium)
                            .foregroundStyle(BoxzyTheme.gold)
                            .frame(width: 44, height: 44)
                            .background(BoxzyTheme.background.opacity(0.65), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(BoxzyTheme.gold.opacity(0.32), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(topic.title)
                                .boxzyFont(16, weight: .semibold)
                                .foregroundStyle(.white)
                            Text(topic.subtitle)
                                .boxzyFont(13)
                                .lineLimit(2)
                                .foregroundStyle(BoxzyTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .boxzyFont(14, weight: .bold)
                            .foregroundStyle(BoxzyTheme.gold)
                    }
                    .padding(.horizontal, 13)
                    .frame(minHeight: 82)
                    .background(BoxzyTheme.surface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchResults: some View {
        let results = HelpContent.topics.flatMap(\.articles).filter {
            $0.question.localizedCaseInsensitiveContains(searchText) || $0.summary.localizedCaseInsensitiveContains(searchText)
        }
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("SEARCH RESULTS")
            if results.isEmpty {
                Text("No matching answers")
                    .boxzyFont(16)
                    .foregroundStyle(BoxzyTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 44)
            } else {
                ForEach(results) { article in
                    NavigationLink(value: article) {
                        questionRow(title: article.question)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("STILL NEED HELP?")
            HStack {
                Text("support@boxzy.com")
                    .boxzyFont(15, weight: .medium)
                    .foregroundStyle(.white)
                Spacer()
                Button(action: copySupportEmail) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .boxzyFont(14, weight: .medium)
                        .foregroundStyle(BoxzyTheme.gold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 15)
            .frame(height: 54)
            .background(BoxzyTheme.surface.opacity(0.50), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))

        }
    }

    private func topicTitle(for article: HelpArticle) -> String {
        HelpContent.topics.first(where: { $0.articles.contains(article) })?.title ?? "Help"
    }

    private func copySupportEmail() {
        UIPasteboard.general.string = "support@boxzy.com"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.snappy(duration: 0.22)) { showsCopiedToast = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeOut(duration: 0.18)) { showsCopiedToast = false }
        }
    }

}

private struct HelpTopicScreen: View {
    @Environment(\.dismiss) private var dismiss
    let topic: HelpTopic

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    helpHeader(title: "Help Center", backAction: { dismiss() })

                    Text(topic.title)
                        .boxzyFont(30, weight: .bold)
                        .foregroundStyle(.white)
                        .padding(.top, 26)
                    Text(topic.subtitle)
                        .boxzyFont(16)
                        .foregroundStyle(BoxzyTheme.muted)
                        .padding(.top, 7)

                    sectionLabel("\(topic.articles.count) ANSWERS")
                        .padding(.top, 34)

                    VStack(spacing: 10) {
                        ForEach(Array(topic.articles.enumerated()), id: \.element.id) { index, article in
                            NavigationLink(value: article) {
                                HStack(spacing: 14) {
                                    Text(article.question)
                                        .boxzyFont(15, weight: .medium)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right")
                                        .boxzyFont(14, weight: .bold)
                                        .foregroundStyle(BoxzyTheme.gold)
                                }
                                .padding(.horizontal, 14)
                                .frame(minHeight: 76)
                                .background(BoxzyTheme.surface.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct HelpArticleScreen: View {
    @Environment(\.dismiss) private var dismiss
    let article: HelpArticle
    let topicTitle: String

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    helpHeader(title: "Help Center", backAction: { dismiss() })

                    Text(topicTitle.uppercased())
                        .boxzyFont(12, weight: .semibold)
                        .tracking(1.6)
                        .foregroundStyle(BoxzyTheme.gold)
                        .padding(.top, 28)

                    Text(article.question)
                        .boxzyFont(31, weight: .bold)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)

                    Text(article.summary)
                        .boxzyFont(16)
                        .foregroundStyle(BoxzyTheme.muted)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)

                    if !article.sections.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(article.sections.enumerated()), id: \.element.id) { index, section in
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(section.label)
                                        .boxzyFont(12, weight: .semibold)
                                        .tracking(1.2)
                                        .foregroundStyle(BoxzyTheme.gold)
                                    Text(section.title)
                                        .boxzyFont(19, weight: .semibold)
                                        .foregroundStyle(.white)
                                    Text(section.body)
                                        .boxzyFont(15)
                                        .foregroundStyle(BoxzyTheme.muted)
                                        .lineSpacing(4)
                                }
                                .padding(.vertical, 22)

                                if index < article.sections.count - 1 {
                                    Divider().overlay(BoxzyTheme.stroke.opacity(0.9))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .background(BoxzyTheme.surface.opacity(0.52), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
                        .padding(.top, 28)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private func helpHeader(title: String, backAction: @escaping () -> Void) -> some View {
    ZStack {
        Text(title)
            .boxzyFont(17, weight: .semibold)
            .foregroundStyle(.white)
        HStack {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .boxzyFont(18, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(BoxzyTheme.surface.opacity(0.9), in: Circle())
                    .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    .frame(height: 56)
    .padding(.top, 4)
}

private func sectionLabel(_ title: String) -> some View {
    Text(title)
        .boxzyFont(12, weight: .semibold)
        .tracking(1.6)
        .foregroundStyle(BoxzyTheme.gold)
}

private func questionRow(title: String) -> some View {
    HStack(spacing: 12) {
        Text(title)
            .boxzyFont(15, weight: .medium)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
        Spacer(minLength: 8)
        Image(systemName: "chevron.right")
            .boxzyFont(14, weight: .bold)
            .foregroundStyle(BoxzyTheme.gold)
    }
    .padding(.horizontal, 16)
    .frame(minHeight: 66)
    .background(BoxzyTheme.surface.opacity(0.58), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
}

private struct AccountLegalSheet: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: "doc.text",
                description: Text("The latest \(title.lowercased()) will appear here.")
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GuestAccountView_Previews: PreviewProvider {
    static var previews: some View {
        GuestAccountView(isAuthenticated: .constant(false))
            .frame(width: 402, height: 874)
            .preferredColorScheme(.dark)
            .previewDisplayName("Guest Account · iPhone 17 Pro")
    }
}
