import SwiftUI

struct AddFundsFlowView: View {
    private enum Screen {
        case signIn
        case deposit
        case depositProcessing
        case depositFailed
    }

    @Binding private var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var screen: Screen
    @State private var depositAmount = 100

    init(isAuthenticated: Binding<Bool>) {
        _isAuthenticated = isAuthenticated
        _screen = State(initialValue: isAuthenticated.wrappedValue ? .deposit : .signIn)
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()

            Group {
                switch screen {
                case .signIn:
                    WelcomeSignInView(
                        authenticated: completeAuthentication,
                        headline: "Sign in to continue",
                        supportingMessage: "Sign in to continue your BOXZY experience.",
                        close: { dismiss() }
                    )
                default:
                    VStack(spacing: 0) {
                        sheetHeader

                        switch screen {
                    case .deposit:
                        DepositFundsView(amount: $depositAmount) { _ in
                            withAnimation(.snappy) {
                                screen = .depositProcessing
                            }
                        }
                    case .depositProcessing:
                        DepositProcessingView(
                            amount: depositAmount,
                            checkPaymentStatus: resolvePaymentStatus
                        )
                    case .depositFailed:
                        DepositFailedView(
                            amount: depositAmount,
                            tryAgain: {
                                withAnimation(.snappy) {
                                    screen = .deposit
                                }
                            },
                            backToAccount: { dismiss() }
                        )
                    case .signIn:
                        EmptyView()
                    }
                }
            }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var sheetHeader: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(Color.white.opacity(0.34))
                .frame(width: 36, height: 5)

            HStack {
                Text(sheetTitle)
                    .boxzyFont(22, weight: .bold)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .boxzyFont(16, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.surface.opacity(0.78), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var sheetTitle: String {
        switch screen {
        case .signIn: "Sign in"
        case .deposit: "Deposit funds"
        case .depositProcessing: "Deposit processing"
        case .depositFailed: "Deposit failed"
        }
    }

    private func completeAuthentication() {
        isAuthenticated = true
        withAnimation(.snappy) {
            screen = .deposit
        }
    }

    private func resolvePaymentStatus() {
        // Replace this demo result with the Coinflow order-status response.
        withAnimation(.snappy) {
            screen = .depositFailed
        }
    }

}

struct CoinflowMark: View {
    private let coinflowBlue = Color(red: 0.10, green: 0.46, blue: 1.0)

    var body: some View {
        ZStack {
            Circle()
                .fill(coinflowBlue)

            Image(systemName: "arrow.triangle.2.circlepath")
                .boxzyFont(18, weight: .semibold)
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}

private struct DepositFundsView: View {
    @AppStorage("boxzy.balance") private var balance = 100.0
    @Binding var amount: Int
    let submit: (Int) -> Void
    private var enteredAmount: Binding<String> {
        Binding(get: { amount == 0 ? "" : String(amount) }, set: { amount = Int($0) ?? 0 })
    }
    var body: some View {
        GoldMoneyEntry(amount: enteredAmount, balance: balance, minimum: 5, withdrawal: false) { value in
            submit(Int(value))
        }
    }
}

private struct DepositProcessingView: View {
    let amount: Int
    let checkPaymentStatus: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                processingSymbol
                    .padding(.top, 36)

                Text("Payment is processing")
                    .boxzyFont(27, weight: .bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)

                Text("We’re checking your payment with Coinflow.\nThis may take a moment.")
                    .font(.body)
                    .foregroundStyle(BoxzyTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.top, 14)

                paymentDetails
                    .padding(.top, 30)

                informationCard
                    .padding(.top, 18)

                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(BoxzyTheme.blue)

                    Text("Checking payment status…")
                        .font(.subheadline)
                        .foregroundStyle(BoxzyTheme.muted)
                }
                .padding(.top, 34)
                .padding(.bottom, 44)
            }
            .padding(.horizontal, 22)
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            checkPaymentStatus()
        }
    }

    private var processingSymbol: some View {
        ZStack {
            Circle()
                .stroke(BoxzyTheme.blue.opacity(0.36), lineWidth: 4)

            Circle()
                .trim(from: 0.03, to: 0.70)
                .stroke(
                    BoxzyTheme.blue,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-62))

            Image(systemName: "arrow.triangle.2.circlepath")
                .boxzyFont(38, weight: .semibold)
                .foregroundStyle(BoxzyTheme.blue)
        }
        .frame(width: 116, height: 116)
        .accessibilityHidden(true)
    }

    private var paymentDetails: some View {
        VStack(spacing: 0) {
            PaymentStatusRow(label: "Amount", value: amount.currency)
            PaymentStatusRow(label: "Payment method", value: "Coinflow")
            PaymentStatusRow(label: "Status") {
                Text("Processing")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BoxzyTheme.blue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(BoxzyTheme.blue.opacity(0.08), in: Capsule())
                    .overlay { Capsule().stroke(BoxzyTheme.blue, lineWidth: 1) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(
            statusCardBackground,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var informationCard: some View {
        HStack(spacing: 18) {
            Image(systemName: "info.circle")
                .boxzyFont(34, weight: .medium)
                .foregroundStyle(BoxzyTheme.blue)

            Text("You can leave this screen. Your balance will update automatically when payment is confirmed.")
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
                .lineSpacing(4)

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            statusCardBackground,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var statusCardBackground: some ShapeStyle {
        LinearGradient(
            colors: [BoxzyTheme.surface.opacity(0.82), BoxzyTheme.surface.opacity(0.48)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct DepositFailedView: View {
    let amount: Int
    let tryAgain: () -> Void
    let backToAccount: () -> Void

    private let failureTint = Color(red: 1.0, green: 0.34, blue: 0.31)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                failureSymbol
                    .padding(.top, 34)

                Text("Payment failed")
                    .boxzyFont(27, weight: .bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)

                Text("We couldn’t complete your payment.\nYour account was not charged.")
                    .font(.body)
                    .foregroundStyle(BoxzyTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.top, 14)

                failureDetails
                    .padding(.top, 30)

                failureMessage
                    .padding(.top, 18)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 126)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                Button("TRY AGAIN", action: tryAgain)
                    .font(.headline)
                    .buttonStyle(BoxzyPrimaryButtonStyle())

                Button("BACK TO ACCOUNT", action: backToAccount)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BoxzyTheme.blue)
                    .buttonStyle(.plain)
                    .frame(height: 34)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                LinearGradient(
                    colors: [.clear, BoxzyTheme.background.opacity(0.98)],
                    startPoint: .top,
                    endPoint: .center
                )
            )
        }
    }

    private var failureSymbol: some View {
        Image(systemName: "xmark")
            .boxzyFont(42, weight: .medium)
            .foregroundStyle(failureTint)
            .frame(width: 112, height: 112)
            .background(failureTint.opacity(0.05), in: Circle())
            .overlay { Circle().stroke(failureTint, lineWidth: 4) }
            .accessibilityHidden(true)
    }

    private var failureDetails: some View {
        VStack(spacing: 0) {
            PaymentStatusRow(label: "Amount", value: amount.currency)
            PaymentStatusRow(label: "Payment method", value: "Coinflow")
            PaymentStatusRow(label: "Status") {
                Text("Failed")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(failureTint)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(failureTint.opacity(0.08), in: Capsule())
                    .overlay { Capsule().stroke(failureTint, lineWidth: 1) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [BoxzyTheme.surface.opacity(0.82), BoxzyTheme.surface.opacity(0.48)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private var failureMessage: some View {
        HStack(spacing: 18) {
            Image(systemName: "exclamationmark.circle")
                .boxzyFont(34, weight: .medium)
                .foregroundStyle(failureTint)

            Text("The payment was declined. Check your payment details or try again.")
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
                .lineSpacing(4)

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [BoxzyTheme.surface.opacity(0.82), BoxzyTheme.surface.opacity(0.48)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

private struct PaymentStatusRow<Value: View>: View {
    let label: String
    @ViewBuilder let value: () -> Value

    init(label: String, @ViewBuilder value: @escaping () -> Value) {
        self.label = label
        self.value = value
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(BoxzyTheme.muted)

            Spacer()

            value()
        }
        .font(.body)
        .frame(minHeight: 62)
    }
}

private extension PaymentStatusRow where Value == Text {
    init(label: String, value: String) {
        self.init(label: label) {
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary)
        }
    }
}

private extension Int {
    var currency: String {
        "$" + formatted(.number.precision(.fractionLength(2)))
    }
}

struct AddFundsFlowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddFundsFlowView(isAuthenticated: .constant(false))
                .previewDisplayName("Logged out · Sign in")

            AddFundsFlowView(isAuthenticated: .constant(true))
                .previewDisplayName("Logged in · Deposit")
        }
        .frame(width: 402, height: 874)
        .preferredColorScheme(.dark)
    }
}

// Shared native amount entry. Business rules match the supplied offline prototype.
struct GoldMoneyEntry: View {
    @Binding var amount: String
    let balance: Double
    let minimum: Double
    let withdrawal: Bool
    var context: String? = nil
    var isSubmitting = false
    var continuesPurchase = false
    let submit: (Double) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var replaceOnNextDigit = true
    private var value: Double { Double(amount) ?? 0 }
    private var fee: Double { withdrawal ? 1.25 : 0 }
    private var valid: Bool { value >= minimum && (!withdrawal || value <= min(balance, 2500)) }
    private var currency: String { value.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US"))) }
    private var keys: [String] { ["1","2","3","4","5","6","7","8","9",withdrawal ? "." : "00","0","⌫"] }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if let context { Text(context).font(.subheadline).foregroundStyle(BoxzyTheme.muted) }
                HStack {
                    Text(withdrawal ? "Available balance" : "Current balance").foregroundStyle(BoxzyTheme.muted)
                    Spacer()
                    Text(balance.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))).accessibilityIdentifier("funds.balance").fontWeight(.semibold).foregroundStyle(BoxzyTheme.goldLight)
                    if withdrawal {
                        Button("MAX") { amount = String(format: "%.2f", min(balance, 2500)); replaceOnNextDigit = true }
                            .font(.caption.weight(.bold)).foregroundStyle(BoxzyTheme.goldLight)
                            .frame(minWidth: 44, minHeight: 44).accessibilityLabel("Use maximum withdrawal amount").accessibilityIdentifier("funds.max")
                    }
                }.boxzyFont(14).padding(.horizontal, 14).frame(minHeight: 44)
                    .background(BoxzyTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("$").boxzyFont(28).foregroundStyle(BoxzyTheme.muted)
                        Text(amount.isEmpty ? "0" : amount).boxzyFont(48, weight: .medium, design: .rounded)
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                    }.accessibilityElement(children: .combine).accessibilityLabel("Amount \(currency)").accessibilityIdentifier("funds.amount")
                    Text(withdrawal && value > min(balance, 2500) ? "Amount exceeds your available limit" : "Minimum \(withdrawal ? "withdrawal" : "deposit") \(minimum.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US"))))")
                        .boxzyFont(12).foregroundStyle(valid || value == 0 ? BoxzyTheme.muted : .red)
                }
                HStack(spacing: 8) {
                    ForEach([25,50,100,250,500], id: \.self) { preset in
                        Button("$\(preset)") { amount = String(preset); replaceOnNextDigit = true }
                            .boxzyFont(14, weight: .semibold).frame(maxWidth: .infinity).frame(height: 44)
                            .foregroundStyle(value == Double(preset) ? BoxzyTheme.background : .white)
                            .background(value == Double(preset) ? AnyShapeStyle(BoxzyTheme.primaryGradient) : AnyShapeStyle(BoxzyTheme.surface), in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).stroke(BoxzyTheme.stroke, lineWidth: 0.7))
                            .accessibilityIdentifier("funds.preset.\(preset)")
                            .disabled(withdrawal && Double(preset) > min(balance, 2500))
                            .opacity(withdrawal && Double(preset) > min(balance, 2500) ? 0.32 : 1)
                    }
                }.buttonStyle(.plain)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(keys, id: \.self) { key in
                        Button { press(key) } label: {
                            Group {
                                if key == "⌫" { Image(systemName: "delete.left").boxzyFont(22) }
                                else { Text(key).boxzyFont(24, weight: .medium) }
                            }.frame(maxWidth: .infinity).frame(height: 48)
                                .background(BoxzyTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                                
                        }.buttonStyle(.plain).accessibilityLabel(key == "⌫" ? "Delete last digit" : key)
                         .accessibilityIdentifier("funds.key.\(key == "⌫" ? "delete" : key == "." ? "decimal" : key)")
                    }
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text(withdrawal ? "Payout method" : "Payment method").boxzyFont(13).foregroundStyle(BoxzyTheme.muted)
                    HStack(spacing: 10) {
                        CoinflowMark().frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Coinflow").boxzyFont(16, weight: .semibold)
                            if withdrawal { Text("1–3 business days").boxzyFont(12).foregroundStyle(BoxzyTheme.muted) }
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(BoxzyTheme.goldLight).font(.title3)
                    }.padding(.horizontal, 14).frame(height: 56)
                        .background(BoxzyTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                        
                }
                if withdrawal { Text("Daily remaining: $2,500.00").boxzyFont(12).foregroundStyle(BoxzyTheme.muted) }
            }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12).disabled(isSubmitting)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout())) {
                    Text("Fee \(fee.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US"))))").foregroundStyle(BoxzyTheme.muted)
                    Spacer()
                    Text("\(withdrawal ? "You receive" : "New balance") \((withdrawal ? max(0, value-fee) : balance+value).formatted(.currency(code: "USD").locale(Locale(identifier: "en_US"))))")
                }.boxzyFont(13).monospacedDigit()

                Button(isSubmitting ? "Processing…" : withdrawal ? "Review withdrawal" : continuesPurchase ? "Deposit \(currency) & continue" : "Deposit \(currency)") { guard valid && !isSubmitting else { return }; submit(value) }
                    .boxzyFont(16, weight: .semibold).buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 14))
                    .accessibilityIdentifier("funds.submit")
                    .disabled(!valid || isSubmitting).opacity(valid ? 1 : 0.4)
                Label("Secure \(withdrawal ? "payout" : "checkout")", systemImage: "lock")
                    .boxzyFont(12).foregroundStyle(BoxzyTheme.muted)
            }.padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 8).background(BoxzyTheme.background)
        }
    }
    private func press(_ key: String) {
        guard !isSubmitting else { return }
        if key == "⌫" { if !amount.isEmpty { amount.removeLast() }; replaceOnNextDigit = false; return }
        if key == "." {
            if replaceOnNextDigit { amount = "0" }
            if !amount.contains(".") { amount += "." }
            replaceOnNextDigit = false; return
        }
        if replaceOnNextDigit { amount = ""; replaceOnNextDigit = false }
        if let decimal = amount.firstIndex(of: "."), amount.distance(from: decimal, to: amount.endIndex) > 2 { return }
        guard amount.count < 9 else { return }
        if amount == "0" { amount = "" }
        amount += key
        if amount == "00" { amount = "0" }
    }
}
