import SwiftUI
import UIKit

struct SignedInAccountView: View {
    private enum Sheet: Identifiable {
        case editProfile, withdraw, signOut, delete
        var id: Self { self }
    }

    @Binding var isAuthenticated: Bool
    @AppStorage("boxzy.hasEnteredApp") private var hasEnteredApp = true
    @AppStorage("boxzy.balance") private var balance = 100.0
    @AppStorage("boxzy.username") private var username = "user_2b4fae55"
    @AppStorage("boxzy.hasShippingAddress") private var hasShippingAddress = false
    @AppStorage("boxzy.hasBoundPhone") private var hasBoundPhone = false
    @AppStorage("boxzy.phoneNumber") private var phoneNumber = ""
    @AppStorage("boxzy.didSeedAccountDemoData") private var didSeedAccountDemoData = false
    @State private var activeSheet: Sheet?
    @State private var isPresentingAddFunds = false
    @State private var isPresentingShippingAddresses = false
    @State private var isPresentingTransactionHistory = false
    @State private var isPresentingSupport = false

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.54, y: 0.22))
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    BoxzyHeaderView(balance: balance) { isPresentingAddFunds = true }
                    profile.padding(.top, 22)
                    balancePanel.padding(.top, 18)

                    quickAction(
                        icon: "location.fill",
                        title: "Shipping",
                        subtitle: hasShippingAddress ? "Home · Default" : "No address saved",
                        trailingIcon: "chevron.right"
                    ) { isPresentingShippingAddresses = true }
                    .frame(height: 82)
                    .background(BoxzyAccountSurface(cornerRadius: 20))
                    .padding(.top, 14)

                    VStack(spacing: 0) {
                        accountAction(icon: "clock", title: "Transaction history") { isPresentingTransactionHistory = true }

                        Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 54)

                        accountAction(icon: "headphones", title: "Customer Support") { isPresentingSupport = true }

                        Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 54)

                        accountAction(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out") { activeSheet = .signOut }
                    }
                    .padding(.horizontal, 14)
                    .background(BoxzyAccountSurface(cornerRadius: 20))
                    .padding(.top, 16)

                    Button("Delete Account") { activeSheet = .delete }
                        .frame(minHeight: 44)
                        .font(.caption.weight(.medium)).foregroundStyle(BoxzyTheme.danger)
                        .padding(.top, 14).padding(.bottom, 12)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $isPresentingAddFunds) {
            AddFundsFlowView(isAuthenticated: $isAuthenticated)
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
                .presentationCornerRadius(28).presentationBackground(BoxzyTheme.background)
        }
        .fullScreenCover(isPresented: $isPresentingShippingAddresses) {
            ShippingAddressesView(hasAddress: $hasShippingAddress)
        }
        .fullScreenCover(isPresented: $isPresentingTransactionHistory) {
            TransactionHistoryView()
        }
        .fullScreenCover(isPresented: $isPresentingSupport) {
            CustomerSupportSheet()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editProfile: EditUsernameView(username: $username)
            case .withdraw: WithdrawView(balance: $balance)
            case .signOut:
                SignOutSheet {
                    activeSheet = nil
                    isAuthenticated = false
                    hasEnteredApp = false
                }
            case .delete:
                DeleteAccountSheet(balance: balance) {
                    balance = 0
                    username = "user_2b4fae55"
                    AddressBookStore.clear()
                    hasShippingAddress = false
                    hasBoundPhone = false
                    phoneNumber = ""
                    activeSheet = nil
                    isAuthenticated = false
                    hasEnteredApp = false
                }
            }
        }
        .onAppear {
#if DEBUG
            if !didSeedAccountDemoData {
                balance = 450
                hasShippingAddress = true
                didSeedAccountDemoData = true
            }
#endif
#if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-BoxzyWithdrawPreview") ||
                arguments.contains("-BoxzyWithdrawalInvalidPreview") ||
                arguments.contains("-BoxzyWithdrawalReviewPreview") ||
                arguments.contains("-BoxzyWithdrawalSubmittingPreview") ||
                arguments.contains("-BoxzyWithdrawalRequestedPreview") ||
                arguments.contains("-BoxzyWithdrawalProcessingPreview") ||
                arguments.contains("-BoxzyWithdrawalFailedPreview") {
                activeSheet = .withdraw
            } else if arguments.contains("-BoxzyDeleteAccountPreview") {
                activeSheet = .delete
            } else if arguments.contains("-BoxzyProfilePreview") { activeSheet = .editProfile
            } else if arguments.contains("-BoxzySignOutPreview") { activeSheet = .signOut
            } else if arguments.contains("-BoxzyAddressesPreview") { isPresentingShippingAddresses = true
            } else if arguments.contains("-BoxzyTransactionsPreview") { isPresentingTransactionHistory = true
            } else if arguments.contains("-BoxzySupportPreview") { isPresentingSupport = true
            } else if arguments.contains("-BoxzyDepositPreview") { isPresentingAddFunds = true
            }
#endif
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var profile: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .boxzyFont(18, weight: .medium)
                .foregroundStyle(BoxzyTheme.blue)
                .frame(width: 44, height: 44)
                .background(BoxzyTheme.deepSurface.opacity(0.72), in: Circle())
                .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.75), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(username)
                    .boxzyFont(14, weight: .semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Member since Sep 2026")
                    .boxzyFont(12)
                    .foregroundStyle(BoxzyTheme.muted)
            }

            Spacer()

            Button("Edit") { activeSheet = .editProfile }
                .frame(minWidth: 44, minHeight: 44)
                .boxzyFont(13, weight: .medium)
                .foregroundStyle(BoxzyTheme.blue)
            .buttonStyle(.plain)
        }
        .frame(height: 46)
    }

    private var balancePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("AVAILABLE BALANCE")
                .boxzyFont(12, weight: .bold)
                .tracking(2.2)
                .foregroundStyle(BoxzyTheme.blue)

            Text("$\(balance, specifier: "%.2f")")
                .boxzyFont(36, weight: .bold, design: .rounded)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .padding(.top, 5)

            HStack(spacing: 10) {
                Button { isPresentingAddFunds = true } label: {
                    Text("Deposit")
                        .boxzyFont(15, weight: .semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 15))

                Button("Withdraw") { activeSheet = .withdraw }
                    .buttonStyle(BoxzySecondaryButtonStyle())
            }
            .padding(.top, 26)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 21)
        .frame(minHeight: 202, alignment: .topLeading)
        .background(AccountWalletSurface())
    }

    private func quickAction(
        icon: String,
        title: String,
        subtitle: String,
        trailingIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .boxzyFont(18, weight: .medium)
                    .foregroundStyle(BoxzyTheme.blue)
                    .frame(width: 38, height: 38)
                    .background(BoxzyTheme.blue.opacity(0.08), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .boxzyFont(13, weight: .semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text(subtitle)
                        .boxzyFont(12)
                        .foregroundStyle(BoxzyTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }

                Spacer(minLength: 2)

                Image(systemName: trailingIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BoxzyTheme.muted)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 82)
        }
        .buttonStyle(.plain)
    }

    private func accountAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .boxzyFont(16, weight: .medium)
                    .foregroundStyle(title == "Sign Out" ? BoxzyTheme.muted : BoxzyTheme.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title).boxzyFont(14, weight: .medium).foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(BoxzyTheme.muted)
            }
            .contentShape(Rectangle()).frame(height: 53)
        }
        .buttonStyle(.plain)
    }
}

private struct EditUsernameView: View {
    private enum ValidationState: Equatable {
        case checking
        case available
        case invalid
        case taken
        case saveFailed
    }

    @Binding var username: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @State private var validationState: ValidationState = .available
    @State private var isSaving = false
    @FocusState private var isFieldFocused: Bool

    init(username: Binding<String>) {
        _username = username
        _draft = State(initialValue: username.wrappedValue)
    }

    private var hasValidFormat: Bool {
        (3...20).contains(draft.count) && draft.unicodeScalars.allSatisfy { scalar in
            (65...90).contains(scalar.value) ||
            (97...122).contains(scalar.value) ||
            (48...57).contains(scalar.value) ||
            scalar.value == 95
        }
    }

    private var hasChanged: Bool {
        draft.caseInsensitiveCompare(username) != .orderedSame
    }

    private var canSave: Bool {
        validationState == .available && hasChanged && !isSaving
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.55, y: 0.22))

            VStack(spacing: 0) {
                editUsernameHeader

                VStack(alignment: .leading, spacing: 0) {
                    Text("USERNAME")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(BoxzyTheme.blue)

                    HStack(spacing: 12) {
                        TextField("Username", text: $draft)
                            .focused($isFieldFocused)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .boxzyFont(20, weight: .regular)
                            .submitLabel(.done)

                        if !draft.isEmpty {
                            Button { draft = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .boxzyFont(20)
                                    .foregroundStyle(BoxzyTheme.muted.opacity(0.72))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(BoxzyTheme.blue.opacity(isFieldFocused ? 1 : 0.72), lineWidth: 1)
                    }
                    .padding(.top, 10)

                    HStack(spacing: 8) {
                        Text("3–20 characters · Letters, numbers, and underscores only")
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer(minLength: 8)
                        Text("\(draft.count) / 20")
                            .monospacedDigit()
                    }
                    .font(.caption)
                    .foregroundStyle(BoxzyTheme.muted)
                    .padding(.top, 10)

                    validationMessage
                        .padding(.top, 21)

                    Text("Usernames are checked without case sensitivity.")
                        .font(.caption)
                        .foregroundStyle(BoxzyTheme.muted)
                        .padding(.top, 22)

                    Spacer(minLength: 30)

                    HStack(spacing: 12) {
                        Button("CANCEL") { dismiss() }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .buttonStyle(.plain)

                        Button(action: saveUsername) {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(validationState == .saveFailed ? "TRY AGAIN" : "SAVE CHANGES")
                                }
                            }
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(BoxzyPrimaryButtonStyle(height: 54, cornerRadius: 16))
                        .disabled(!canSave && validationState != .saveFailed)
                        .opacity(canSave || validationState == .saveFailed ? 1 : 0.38)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
            }
        }
        .task(id: draft) {
            await validateUsername()
        }
        .presentationDetents([.large]).presentationDragIndicator(.hidden)
        .presentationCornerRadius(28).presentationBackground(BoxzyTheme.background)
    }

    private var editUsernameHeader: some View {
        ZStack {
            Text("Edit username")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .boxzyFont(17, weight: .semibold)
                        .foregroundStyle(BoxzyTheme.blue)
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.deepSurface.opacity(0.9), in: Circle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .overlay(alignment: .bottom) {
            Rectangle().fill(BoxzyTheme.stroke.opacity(0.35)).frame(height: 0.5)
        }
    }

    @ViewBuilder
    private var validationMessage: some View {
        switch validationState {
        case .checking:
            HStack(spacing: 10) {
                ProgressView().tint(BoxzyTheme.blue).scaleEffect(0.82)
                Text("Checking availability…")
            }
            .font(.subheadline)
            .foregroundStyle(BoxzyTheme.muted)
        case .available:
            Label("Username is available", systemImage: "checkmark.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BoxzyTheme.success)
        case .invalid:
            Label("Use 3–20 valid characters", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BoxzyTheme.danger)
        case .taken:
            Label("Username is already taken", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BoxzyTheme.danger)
        case .saveFailed:
            Label("Couldn't save changes. Please try again.", systemImage: "exclamationmark.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BoxzyTheme.danger)
        }
    }

    @MainActor
    private func validateUsername() async {
        if draft.count > 20 {
            draft = String(draft.prefix(20))
            return
        }

        guard hasValidFormat else {
            validationState = .invalid
            return
        }

        if !hasChanged {
            validationState = .available
            return
        }

        validationState = .checking
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        let unavailableNames = ["pikachase22", "boxzy", "admin"]
        validationState = unavailableNames.contains(draft.lowercased()) ? .taken : .available
    }

    private func saveUsername() {
        guard canSave || validationState == .saveFailed else { return }
        isFieldFocused = false
        isSaving = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))

            // This deterministic preview case exercises the real save-error UI until
            // the profile API replaces the local persistence used by this prototype.
            if draft.caseInsensitiveCompare("save_error") == .orderedSame {
                isSaving = false
                validationState = .saveFailed
                return
            }

            username = draft
            isSaving = false
            dismiss()
        }
    }
}

private enum PayoutMethod: String, CaseIterable, Identifiable {
    case coinflow = "Coinflow"

    var id: Self { self }
    var caption: String { "1–3 business days · $1.25 fee" }
    var fee: (Double) -> Double { { _ in 1.25 } }
    var reviewName: String { "Coinflow" }
    var arrival: String { "1–3 business days" }
}

private let withdrawalCurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.locale = Locale(identifier: "en_US")
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
}()

private func withdrawalCurrency(_ value: Double) -> String {
    withdrawalCurrencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
}

private struct WithdrawView: View {
    private enum AmountState: Equatable {
        case empty
        case belowMinimum
        case overAvailableBalance
        case overDailyLimit
        case valid
    }

    @Binding var balance: Double
    @Environment(\.dismiss) private var dismiss
    @State private var amount = "100"
    @State private var method: PayoutMethod = .coinflow
    private struct ReviewDraft: Identifiable {
        let id = UUID()
        let amount: Double
        let method: PayoutMethod
    }
    @State private var reviewDraft: ReviewDraft?
    @FocusState private var amountIsFocused: Bool

    private let dailyLimit = 2_500.0
    private let minimumAmount = 6.0

    private var amountValue: Double { Double(amount) ?? 0 }
    private var fee: Double { method.fee(amountValue) }
    private var received: Double { max(0, amountValue - fee) }
    private var available: Double { balance }
    private var amountState: AmountState {
        guard !amount.isEmpty, amountValue > 0 else { return .empty }
        guard amountValue >= minimumAmount else { return .belowMinimum }

        let effectiveLimit = min(available, dailyLimit)
        guard amountValue <= effectiveLimit else {
            return available <= dailyLimit ? .overAvailableBalance : .overDailyLimit
        }
        return .valid
    }
    private var isValid: Bool { amountState == .valid }
    private var validationMessage: String {
        switch amountState {
        case .empty: "Enter a withdrawal amount"
        case .belowMinimum: "Minimum withdrawal is $6.00"
        case .overAvailableBalance: "Amount exceeds your available balance of \(withdrawalCurrency(available))"
        case .overDailyLimit: "Amount exceeds your remaining daily limit of \(withdrawalCurrency(dailyLimit))"
        case .valid: "Minimum withdrawal $6.00"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            withdrawHeader.padding(.horizontal, 20).padding(.bottom, 8)
            GoldMoneyEntry(amount: $amount, balance: balance, minimum: 6, withdrawal: true) { value in reviewDraft = ReviewDraft(amount: value, method: method) }
        }
        .background(BoxzyTheme.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .presentationBackground(BoxzyTheme.background)
        .fullScreenCover(item: $reviewDraft) { draft in
            WithdrawalReviewView(amount: draft.amount, method: draft.method, submitted: { balance = max(0, balance - draft.amount) }, complete: { reviewDraft = nil; dismiss() })
        }
    }

    private var withdrawHeader: some View {
        ZStack(alignment: .topTrailing) {
            Text("Withdraw funds")
                .boxzyFont(24, weight: .bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .boxzyFont(17, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(BoxzyTheme.deepSurface, in: Circle())
                    .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 18)
    }

    private var summaryCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "wallet.bifold")
                .boxzyFont(23, weight: .medium)
                .foregroundStyle(BoxzyTheme.blue)
                .frame(width: 44, height: 44)
                .background(BoxzyTheme.deepSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text("AVAILABLE BALANCE")
                    .font(.caption.weight(.bold))
                    .tracking(1.7)
                    .foregroundStyle(BoxzyTheme.muted)

                Text(withdrawalCurrency(available))
                    .boxzyFont(34, weight: .bold, design: .rounded)

                Text("Daily limit \(withdrawalCurrency(dailyLimit))")
                    .font(.caption)
                    .foregroundStyle(BoxzyTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(height: 126)
        .background(BoxzyAccountSurface(cornerRadius: 20))
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AMOUNT").boxzyFieldLabel().tracking(2)

            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("$")
                        .boxzyFont(34, weight: .medium, design: .rounded)
                        .foregroundStyle(BoxzyTheme.muted)

                TextField("0.00", text: $amount)
                        .boxzyFont(58, weight: .bold, design: .rounded)
                        .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                        .focused($amountIsFocused)
                        .frame(width: 210)
                        .onChange(of: amount) { _, newValue in
                            let filtered = sanitizeAmount(newValue)
                            if filtered != newValue { amount = filtered }
                        }
                        .accessibilityLabel("Withdrawal amount")
                }

                Capsule()
                    .fill(isValid || amountState == .empty ? BoxzyTheme.blue : BoxzyTheme.danger)
                    .frame(width: 184, height: 3)
                    .shadow(color: (isValid ? BoxzyTheme.blue : BoxzyTheme.danger).opacity(0.45), radius: 6)

                Text(validationMessage)
                    .font(.footnote)
                    .foregroundStyle(isValid ? BoxzyTheme.muted : amountState == .empty ? BoxzyTheme.muted : BoxzyTheme.danger)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var payoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAYOUT METHOD").boxzyFieldLabel().tracking(2)
            ForEach(PayoutMethod.allCases) { option in payoutRow(option) }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUMMARY").boxzyFieldLabel().tracking(2)

            VStack(spacing: 13) {
                summaryRow("Withdrawal amount", value: withdrawalCurrency(amountValue))
                summaryRow("Processing fee", value: withdrawalCurrency(fee))

                Divider().overlay(BoxzyTheme.stroke.opacity(0.52))

                HStack {
                    Text("You receive").font(.body.weight(.medium))
                    Spacer()
                    Text(withdrawalCurrency(received))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isValid ? BoxzyTheme.blue : amountState == .empty ? BoxzyTheme.muted : BoxzyTheme.danger)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(BoxzyAccountSurface(cornerRadius: 18))
        }
    }

    private var securityNote: some View {
        Label("Transfers are encrypted and securely processed.", systemImage: "lock.shield")
            .font(.caption)
            .foregroundStyle(BoxzyTheme.muted)
            .frame(maxWidth: .infinity)
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(BoxzyTheme.muted)
            Spacer()
            Text(value).font(.body.weight(.medium))
        }
    }

    private func payoutRow(_ option: PayoutMethod) -> some View {
        Button { method = option } label: {
            HStack(spacing: 14) {
                payoutIcon
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.rawValue).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(option.caption).font(.caption).foregroundStyle(BoxzyTheme.muted)
                }
                Spacer(minLength: 6)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(BoxzyTheme.blue)
            }
            .padding(.horizontal, 12)
            .frame(height: 72)
            .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(option == method ? BoxzyTheme.blue : BoxzyTheme.stroke.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var payoutIcon: some View {
        CoinflowMark()
            .frame(width: 44, height: 44)
    }

    private func sanitizeAmount(_ value: String) -> String {
        var result = ""
        var hasDecimal = false
        var decimalCount = 0

        for character in value {
            if character.isNumber {
                if hasDecimal {
                    guard decimalCount < 2 else { continue }
                    decimalCount += 1
                }
                result.append(character)
            } else if character == ".", !hasDecimal {
                hasDecimal = true
                result.append(character)
            }
        }
        return result
    }

}

private struct WithdrawalReviewView: View {
    private enum ResultStatus: String, Identifiable {
        case requested = "REQUESTED"
        case processing = "PROCESSING"
        case failed = "FAILED"

        var id: Self { self }
    }

    let amount: Double
    let method: PayoutMethod
    let submitted: () -> Void
    let complete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var resultStatus: ResultStatus?

    private var fee: Double { method.fee(amount) }
    private var received: Double { max(0, amount - fee) }

    var body: some View {
        Group {
            if let resultStatus {
                WithdrawalResultView(
                    status: resultStatus.rawValue,
                    amount: amount,
                    method: method,
                    done: complete,
                    retry: {
                        self.resultStatus = nil
                        isSubmitting = false
                    }
                )
            } else {
                ZStack {
                    BoxzyTheme.background.ignoresSafeArea()
                    BoxzyAccountGlow(center: UnitPoint(x: 0.52, y: 0.32))
                    VStack(spacing: 0) {
                        reviewHeader
                        ScrollView {
                            VStack(spacing: 0) {
                                reviewRow("Withdrawal amount", value: withdrawalCurrency(amount))
                                Divider()
                                reviewRow("Method", value: method.reviewName)
                                Divider()
                                reviewRow("Processing fee", value: withdrawalCurrency(fee))
                                Divider()
                                HStack {
                                    Text("You receive").font(.headline)
                                    Spacer()
                                    Text(withdrawalCurrency(received)).boxzyFont(32, weight: .semibold).foregroundStyle(BoxzyTheme.gold)
                                }.padding(.vertical, 20)
                                Divider()
                                reviewRow("Estimated arrival", value: method.arrival)
                            }.padding(.horizontal, 20).boxzyCard().padding(20)
                        }
                        VStack(spacing: 16) {
                            Label("Withdrawals cannot be canceled after confirmation.", systemImage: "checkmark.shield")
                                .boxzyFont(13).foregroundStyle(BoxzyTheme.muted).fixedSize(horizontal: false, vertical: true)
                            Button(action: submitWithdrawal) {
                                HStack(spacing: 8) {
                                    if isSubmitting { ProgressView().tint(.black) }
                                    Text(isSubmitting ? "Submitting…" : "Confirm withdrawal · \(withdrawalCurrency(amount))")
                                }
                            }.buttonStyle(BoxzyPrimaryButtonStyle()).disabled(isSubmitting)
                            .accessibilityIdentifier("withdraw.confirm")
                        }.padding(.horizontal, 20).padding(.bottom, 12)

                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: configurePreviewState)
    }

    private var reviewHeader: some View {
        ZStack {
            Text("Review withdrawal").font(.headline)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(BoxzyTheme.deepSurface, in: Circle())
                        .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
                }.buttonStyle(.plain).disabled(isSubmitting)
                Spacer()
            }
        }
        .padding(.horizontal, 16).frame(height: 64)
    }

    private func reviewRow(_ title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Text(title).foregroundStyle(BoxzyTheme.muted)
            Spacer()
            Text(value).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 60)
    }

    private func submitWithdrawal() {
        guard !isSubmitting else { return }
        isSubmitting = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            submitted()
            withAnimation(.easeInOut(duration: 0.24)) {
                resultStatus = .requested
            }
        }
    }

    private func configurePreviewState() {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-BoxzyWithdrawalSubmittingPreview") {
            isSubmitting = true
        } else if arguments.contains("-BoxzyWithdrawalRequestedPreview") {
            resultStatus = .requested
        } else if arguments.contains("-BoxzyWithdrawalProcessingPreview") {
            resultStatus = .processing
        } else if arguments.contains("-BoxzyWithdrawalFailedPreview") {
            resultStatus = .failed
        }
#endif
    }
}

private struct WithdrawalResultView: View {
    let status: String
    let amount: Double
    let method: PayoutMethod
    let done: () -> Void
    let retry: () -> Void

    private var isFailed: Bool { status == "FAILED" }
    private var isProcessing: Bool { status == "PROCESSING" }
    private var statusColor: Color { isFailed ? BoxzyTheme.danger : BoxzyTheme.blue }
    private var icon: String {
        if isFailed { return "xmark" }
        if isProcessing { return "clock" }
        return "checkmark"
    }
    private var title: String {
        if isFailed { return "Withdrawal failed" }
        if isProcessing { return "Withdrawal processing" }
        return "Withdrawal requested"
    }
    private var message: String {
        if isFailed { return "We couldn't verify your payout method." }
        if isProcessing { return "Your withdrawal is being reviewed.\nWe'll notify you when the status changes." }
        return "Your withdrawal request has been submitted."
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.50, y: 0.28))

            VStack(spacing: 0) {
                Text("Withdrawal status")
                    .font(.headline)
                    .padding(.top, 20)

                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.08))
                        .frame(width: isFailed ? 112 : 148, height: isFailed ? 112 : 148)
                        .overlay(Circle().stroke(statusColor.opacity(0.65), lineWidth: 1))
                        .shadow(color: statusColor.opacity(0.34), radius: 24)

                    Image(systemName: icon)
                        .font(.system(size: isFailed ? 43 : 54, weight: .medium))
                        .foregroundStyle(statusColor)
                }
                .padding(.top, isFailed ? 22 : 45)

                Text(title)
                    .font(.system(size: isFailed ? 26 : 28, weight: .bold))
                    .padding(.top, isFailed ? 18 : 28)

                Text(withdrawalCurrency(amount))
                    .boxzyFont(36, weight: .bold, design: .rounded)
                    .padding(.top, 12)

                Text(status)
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 15)
                    .frame(height: 30)
                    .background(statusColor.opacity(0.11), in: Capsule())
                    .overlay(Capsule().stroke(statusColor.opacity(0.32), lineWidth: 1))
                    .padding(.top, 10)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(BoxzyTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, isFailed ? 12 : 18)

                if isFailed {
                    Label("Your balance was not charged.", systemImage: "checkmark.shield")
                        .font(.body.weight(.medium))
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                        .background(BoxzyAccountSurface(cornerRadius: 18))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }

                detailsCard
                    .padding(.horizontal, 20)
                    .padding(.top, isFailed ? 12 : 28)

                Spacer(minLength: 20)

                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, isFailed ? 8 : 18)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            resultRow("Payout method", value: method.reviewName)
            Divider().overlay(BoxzyTheme.stroke.opacity(0.5))

            if isProcessing {
                resultRow("Submitted", value: "Sep 2, 2026 · 9:41 AM")
                Divider().overlay(BoxzyTheme.stroke.opacity(0.5))
            } else if !isFailed {
                resultRow("Estimated arrival", value: method.arrival)
                Divider().overlay(BoxzyTheme.stroke.opacity(0.5))
            }

            resultRow("Transaction ID", value: "WD-83920471")
        }
        .padding(.horizontal, 18)
        .background(BoxzyAccountSurface(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(BoxzyTheme.stroke.opacity(0.65), lineWidth: 1))
    }

    @ViewBuilder
    private var actionButtons: some View {
        if isFailed {
            VStack(spacing: 10) {
                Button("TRY AGAIN", action: retry)
                    .font(.headline).tracking(1.5)
                    .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 14))

                Link("CONTACT SUPPORT", destination: URL(string: "mailto:support@boxzy.com")!)
                    .font(.headline).tracking(1.4)
                    .foregroundStyle(BoxzyTheme.blue)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BoxzyTheme.blue, lineWidth: 1))

                Button("DONE", action: done)
                    .font(.subheadline.bold()).tracking(1.4)
                    .foregroundStyle(BoxzyTheme.blue)
                    .frame(height: 34)
                    .buttonStyle(.plain)
            }
        } else {
            VStack(spacing: 12) {
                Button("DONE", action: done)
                    .font(.headline).tracking(1.5)
                    .buttonStyle(BoxzyPrimaryButtonStyle(height: 56, cornerRadius: 14))

                Text(isProcessing ? "Most reviews are completed within 1 business day." : "We'll notify you when your withdrawal status changes.")
                    .font(.caption)
                    .foregroundStyle(BoxzyTheme.muted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func resultRow(_ title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Text(title).foregroundStyle(BoxzyTheme.muted)
            Spacer(minLength: 10)
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(minHeight: isFailed ? 54 : 60)
    }
}

private enum AccountTransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case deposits = "Deposits"
    case withdrawals = "Withdrawals"

    var id: Self { self }
}

private enum AccountTransactionKind: String, Hashable {
    case deposit = "Deposit"
    case withdrawal = "Withdrawal"
}

private enum AccountTransactionStatus: String, Hashable {
    case completed = "Completed"
    case processing = "Processing"
    case failed = "Failed"
    case canceled = "Canceled"

    var color: Color {
        switch self {
        case .completed: BoxzyTheme.success
        case .processing: BoxzyTheme.blue
        case .failed: BoxzyTheme.danger
        case .canceled: BoxzyTheme.muted
        }
    }
}

private struct AccountTransaction: Identifiable, Hashable {
    let id: String
    let kind: AccountTransactionKind
    let amount: Double
    let fee: Double
    let method: String
    let date: String
    let createdAt: String
    let status: AccountTransactionStatus
    let failureReason: String?
    let estimatedCompletion: String?

    var netAmount: Double { max(0, amount - fee) }
    var signedAmount: String { "\(kind == .deposit ? "+" : "−")$\(amount.formatted(.number.precision(.fractionLength(2))))" }

    static let samples = [
        AccountTransaction(id: "BX-DEP-090126-8A41", kind: .deposit, amount: 100, fee: 0, method: "Coinflow", date: "Sep 1, 2026", createdAt: "Sep 1, 2026 · 9:42 AM", status: .completed, failureReason: nil, estimatedCompletion: nil),
        AccountTransaction(id: "BX-WD-082826-3F19", kind: .withdrawal, amount: 80, fee: 1.25, method: "Coinflow", date: "Aug 28, 2026", createdAt: "Aug 28, 2026 · 2:18 PM", status: .processing, failureReason: nil, estimatedCompletion: "Expected by Sep 4, 2026"),
        AccountTransaction(id: "BX-DEP-082226-5C72", kind: .deposit, amount: 250, fee: 0, method: "Coinflow", date: "Aug 22, 2026", createdAt: "Aug 22, 2026 · 11:06 AM", status: .completed, failureReason: nil, estimatedCompletion: nil),
        AccountTransaction(id: "BX-WD-081626-1D04", kind: .withdrawal, amount: 50, fee: 1.25, method: "Coinflow", date: "Aug 16, 2026", createdAt: "Aug 16, 2026 · 4:35 PM", status: .failed, failureReason: "The payout provider rejected this transfer. Verify your payout details and try again.", estimatedCompletion: nil),
        AccountTransaction(id: "BX-WD-080926-7B63", kind: .withdrawal, amount: 120, fee: 1.25, method: "Coinflow", date: "Aug 9, 2026", createdAt: "Aug 9, 2026 · 10:14 AM", status: .canceled, failureReason: nil, estimatedCompletion: nil)
    ]
}

private struct TransactionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var filter: AccountTransactionFilter = .all
    @State private var selectedRecord: AccountTransaction?

    private var records: [AccountTransaction] {
        ProcessInfo.processInfo.arguments.contains("-BoxzyEmptyTransactions") ? [] : AccountTransaction.samples
    }

    private var filteredRecords: [AccountTransaction] {
        switch filter {
        case .all: records
        case .deposits: records.filter { $0.kind == .deposit }
        case .withdrawals: records.filter { $0.kind == .withdrawal }
        }
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.54, y: 0.20))

            VStack(spacing: 0) {
                header
                filterBar.padding(.top, 22)

                if filteredRecords.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                                Button { selectedRecord = record } label: {
                                    recordRow(record)
                                }
                                .buttonStyle(.plain)

                                if index < filteredRecords.count - 1 {
                                    Divider()
                                        .overlay(BoxzyTheme.stroke.opacity(0.28))
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .background(BoxzyTheme.deepSurface.opacity(0.50), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(BoxzyTheme.stroke.opacity(0.52), lineWidth: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 22)
                    }
                }

                if !records.isEmpty {
                    Label("Check each withdrawal for its estimated completion.", systemImage: "info.circle")
                        .boxzyFont(12, weight: .regular)
                        .foregroundStyle(BoxzyTheme.muted.opacity(0.74))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                        .background(BoxzyTheme.deepSurface.opacity(0.40), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(BoxzyTheme.stroke.opacity(0.34), lineWidth: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
            }
        }
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BoxzyTransactionDetailPreview") { selectedRecord = records.first }
#endif
        }
        .fullScreenCover(item: $selectedRecord) { record in
            TransactionDetailView(transaction: record)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .boxzyFont(18, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(BoxzyTheme.deepSurface, in: Circle())
                    .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("Transaction history")
                .boxzyFont(30, weight: .bold)
                .padding(.top, 16)

            Text("Deposits and withdrawals")
                .font(.body)
                .foregroundStyle(BoxzyTheme.muted)
                .padding(.top, 5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var filterBar: some View {
        HStack(spacing: 0) {
            ForEach(AccountTransactionFilter.allCases) { option in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { filter = option }
                } label: {
                    Text(option.rawValue)
                        .font(.system(size: 15, weight: filter == option ? .semibold : .medium))
                        .foregroundStyle(filter == option ? BoxzyTheme.background : BoxzyTheme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if filter == option {
                                Capsule()
                                    .fill(BoxzyTheme.primaryGradient)
                                    .overlay(Capsule().stroke(BoxzyTheme.cyan.opacity(0.78), lineWidth: 1))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(BoxzyTheme.deepSurface.opacity(0.56), in: Capsule())
        .overlay(Capsule().stroke(BoxzyTheme.stroke.opacity(0.82), lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 13) {
            Spacer().frame(height: 88)
            Image(systemName: "clock.arrow.circlepath")
                .boxzyFont(36, weight: .light)
                .foregroundStyle(BoxzyTheme.blue)
            Text("No transactions yet")
                .font(.title3.weight(.semibold))
            Text("Your deposits and withdrawals will appear here.")
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 34)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func recordRow(_ record: AccountTransaction) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(record.kind.rawValue, systemImage: record.kind == .deposit ? "arrow.down.left" : "arrow.up.right")
                    .boxzyFont(16, weight: .semibold)
                Spacer()
                Text(record.signedAmount).boxzyFont(19, weight: .semibold).monospacedDigit()
            }
            HStack {
                Text("\(record.method) · \(record.date)").boxzyFont(13).foregroundStyle(BoxzyTheme.muted)
                Spacer(minLength: 6)
                Text(record.status.rawValue).boxzyFont(12, weight: .semibold)
                    .foregroundStyle(record.status.color)
            }
        }.padding(.vertical, 18).contentShape(Rectangle())
    }

    private func recordColor(_ record: AccountTransaction) -> Color {
        if record.status == .failed { return BoxzyTheme.danger }
        return record.kind == .deposit ? BoxzyTheme.success : BoxzyTheme.blue
    }
}

private struct TransactionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsSupport = false
    let transaction: AccountTransaction

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.52, y: 0.18))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    detailHeader
                    amountSummary.padding(.top, 28)
                    detailCard.padding(.top, 26)

                    if let failureReason = transaction.failureReason {
                        statusMessage(
                            title: "Why it failed",
                            message: failureReason,
                            icon: "exclamationmark.triangle.fill",
                            color: BoxzyTheme.danger
                        )
                        .padding(.top, 16)
                    }

                    if let estimatedCompletion = transaction.estimatedCompletion {
                        statusMessage(
                            title: "Estimated processing time",
                            message: estimatedCompletion,
                            icon: "clock.fill",
                            color: BoxzyTheme.blue
                        )
                        .padding(.top, 16)
                    }

                    Button { showsSupport = true } label: {
                        Label("Contact Support", systemImage: "headphones")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(BoxzyTheme.blue)
                    .background(BoxzyTheme.deepSurface.opacity(0.52), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(BoxzyTheme.blue.opacity(0.64), lineWidth: 1))
                    .padding(.top, 22)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .fullScreenCover(isPresented: $showsSupport) {
            CustomerSupportSheet(transactionID: transaction.id)
        }
        .preferredColorScheme(.dark)
    }

    private var detailHeader: some View {
        ZStack {
            Text("Transaction details")
                .font(.headline)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .boxzyFont(18, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.deepSurface, in: Circle())
                        .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.9), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 64)
        .padding(.top, 6)
    }

    private var amountSummary: some View {
        VStack(spacing: 10) {
            Image(systemName: transaction.kind == .deposit ? "arrow.down" : "arrow.up")
                .boxzyFont(24, weight: .semibold)
                .foregroundStyle(transaction.status.color)
                .frame(width: 58, height: 58)
                .background(transaction.status.color.opacity(0.12), in: Circle())
                .overlay(Circle().stroke(transaction.status.color.opacity(0.52), lineWidth: 1))

            Text(transaction.signedAmount)
                .boxzyFont(36, weight: .bold, design: .rounded)

            Text(transaction.status.rawValue)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.status.color)
                .padding(.horizontal, 13)
                .frame(height: 28)
                .background(transaction.status.color.opacity(0.11), in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            detailRow("Transaction ID", transaction.id, monospaced: true)
            divider
            detailRow("Amount", String(format: "$%.2f", transaction.amount))
            divider
            detailRow("Fee", String(format: "$%.2f", transaction.fee))
            divider
            detailRow(
                transaction.kind == .deposit ? "Amount credited" : "Amount received",
                String(format: "$%.2f", transaction.netAmount)
            )
            divider
            detailRow("Method", transaction.method)
            divider
            detailRow("Created", transaction.createdAt)
            divider
            detailRow("Status", transaction.status.rawValue, color: transaction.status.color)
        }
        .padding(.horizontal, 18)
        .background(BoxzyAccountSurface(cornerRadius: 22))
    }

    private var divider: some View {
        Divider().overlay(BoxzyTheme.stroke.opacity(0.34))
    }

    private func detailRow(_ label: String, _ value: String, monospaced: Bool = false, color: Color = .white) -> some View {
        HStack(spacing: 16) {
            Text(label).foregroundStyle(BoxzyTheme.muted)
            Spacer(minLength: 12)
            Text(value)
                .font(monospaced ? .system(size: 13, weight: .medium, design: .monospaced) : .subheadline.weight(.medium))
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
        }
        .frame(minHeight: 56)
    }

    private func statusMessage(title: String, message: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: icon)
                .boxzyFont(17, weight: .semibold)
                .foregroundStyle(color)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message).font(.subheadline).foregroundStyle(BoxzyTheme.muted)
            }
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(color.opacity(0.28), lineWidth: 1))
    }
}

private extension Double {
    var currency: String {
        String(format: "$%.2f", self)
    }
}



struct AccountAddress: Identifiable, Equatable, Codable {
    let id: UUID
    var label: String
    var firstName: String
    var lastName: String
    var street: String
    var apartment: String
    var city: String
    var state: String
    var zip: String
    var phone: String
    var email: String
    var isDefault: Bool

    var fullName: String { "\(firstName) \(lastName)" }
    var streetLine: String { apartment.isEmpty ? street : "\(street), \(apartment)" }
    var cityLine: String { "\(city), \(state) \(zip)" }

    static let samples = [
        AccountAddress(id: UUID(), label: "Home", firstName: "Alex", lastName: "Morgan", street: "245 Hudson Street", apartment: "Apt 4B", city: "New York", state: "NY", zip: "10013", phone: "(555) 123-4567", email: "alex@example.com", isDefault: true),
        AccountAddress(id: UUID(), label: "Office", firstName: "Alex", lastName: "Morgan", street: "85 Broad Street", apartment: "Floor 12", city: "New York", state: "NY", zip: "10004", phone: "(555) 867-5309", email: "alex.morgan@boxzy.test", isDefault: false),
        AccountAddress(id: UUID(), label: "Parents", firstName: "Jamie", lastName: "Morgan", street: "1600 Pennsylvania Avenue", apartment: "", city: "Washington", state: "DC", zip: "20500", phone: "(202) 555-0184", email: "jamie@example.com", isDefault: false),
        AccountAddress(id: UUID(), label: "Warehouse", firstName: "Alex", lastName: "Morgan", street: "Pier 39", apartment: "Suite 210", city: "San Francisco", state: "CA", zip: "94133", phone: "(415) 555-0138", email: "shipping@boxzy.test", isDefault: false)
    ]
}

enum AddressBookStore {
    private static let addressesKey = "boxzy.shippingAddresses.v1"
    private static let hasAddressKey = "boxzy.hasShippingAddress"

    static func load() -> [AccountAddress] {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: addressesKey),
           let addresses = try? JSONDecoder().decode([AccountAddress].self, from: data) {
            return addresses
        }

        guard defaults.bool(forKey: hasAddressKey) else { return [] }
        let migrated = AccountAddress.samples
        save(migrated)
        return migrated
    }

    static func save(_ addresses: [AccountAddress]) {
        if let data = try? JSONEncoder().encode(addresses) {
            UserDefaults.standard.set(data, forKey: addressesKey)
        }
        UserDefaults.standard.set(!addresses.isEmpty, forKey: hasAddressKey)
    }

    @discardableResult
    static func upsert(_ address: AccountAddress) -> AccountAddress {
        var addresses = load()
        if address.isDefault {
            for index in addresses.indices { addresses[index].isDefault = false }
        }
        if let index = addresses.firstIndex(where: { $0.id == address.id }) {
            addresses[index] = address
        } else {
            addresses.append(address)
        }
        save(addresses)
        return address
    }

    static func defaultAddress() -> AccountAddress? {
        let addresses = load()
        return addresses.first(where: \.isDefault) ?? addresses.first
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: addressesKey)
        UserDefaults.standard.set(false, forKey: hasAddressKey)
    }
}

private enum AddressEditorRoute: Identifiable {
    case add
    case edit(AccountAddress)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let address): address.id.uuidString
        }
    }

    var address: AccountAddress? {
        if case .edit(let address) = self { address } else { nil }
    }
}

struct ShippingAddressesView: View {
    @Binding var hasAddress: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var addresses: [AccountAddress]
    @State private var editorRoute: AddressEditorRoute?

    init(hasAddress: Binding<Bool>) {
        _hasAddress = hasAddress
        let showsEmptyPreview = ProcessInfo.processInfo.arguments.contains("-BoxzyEmptyAddresses")
        _addresses = State(initialValue: showsEmptyPreview ? [] : AddressBookStore.load())
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()


            if addresses.isEmpty {
                emptyState
            } else {
                addressList
            }
        }
        .fullScreenCover(item: $editorRoute) { route in
            AddAddressView(address: route.address) { savedAddress in
                save(savedAddress)
                editorRoute = nil
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hasAddress = !addresses.isEmpty
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BoxzyAddressFormPreview") { editorRoute = .add }
#endif
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            centeredHeader

            Spacer().frame(height: 104)

            Image("shipping-empty-parcel")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            Text("No saved addresses")
                .boxzyFont(25, weight: .bold)
                .padding(.top, 2)

            Text("Add an address to use\nwhen shipping items.")
                .boxzyFont(17)
                .foregroundStyle(BoxzyTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 10)

            Button("ADD ADDRESS") { editorRoute = .add }
                .boxzyFont(17, weight: .semibold)
                .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 13))
                .frame(width: 164)
                .padding(.top, 22)

            Label("Your address is used only for delivery.", systemImage: "checkmark.shield")
                .boxzyFont(14)
                .foregroundStyle(BoxzyTheme.muted)
                .symbolRenderingMode(.hierarchical)
                .padding(.top, 52)

            Spacer(minLength: 44)
        }
    }

    private var centeredHeader: some View {
        ZStack {
            Text("Shipping addresses")
                .boxzyFont(18, weight: .semibold)

            HStack {
                circleBackButton
                Spacer()
                Button { editorRoute = .add } label: {
                    Image(systemName: "plus")
                        .boxzyFont(23, weight: .medium)
                        .foregroundStyle(BoxzyTheme.background)
                        .frame(width: 44, height: 44)
                        .background(
                            BoxzyTheme.primaryGradient,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }

    private var addressList: some View {
        VStack(spacing: 0) {
            centeredHeader

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(addresses) { address in
                        addressCard(address)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private func addressCard(_ address: AccountAddress) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: addressIcon(for: address.label))
                    Text(address.label.uppercased())
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(address.isDefault ? BoxzyTheme.blue : BoxzyTheme.muted)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background((address.isDefault ? BoxzyTheme.blue : BoxzyTheme.muted).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                if address.isDefault {
                    Label("DEFAULT", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BoxzyTheme.blue)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(BoxzyTheme.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                        .overlay { RoundedRectangle(cornerRadius: 8).stroke(BoxzyTheme.blue.opacity(0.4), lineWidth: 1) }
                }

                Spacer()

            }

            Text(address.fullName)
                .font(.title3.weight(.semibold))
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(address.streetLine)
                Text(address.cityLine)
                Text("United States")
            }
            .font(.body)
            .foregroundStyle(BoxzyTheme.muted)
            .padding(.top, 12)

            if !address.phone.isEmpty || !address.email.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    if !address.phone.isEmpty { Label(address.phone, systemImage: "phone") }
                    if !address.email.isEmpty { Label(address.email, systemImage: "envelope") }
                }
                .font(.subheadline)
                .foregroundStyle(BoxzyTheme.muted)
                .tint(BoxzyTheme.blue)
                .padding(.top, 18)
            }

            HStack(spacing: 18) {
                Spacer()
                if !address.isDefault {
                    Button("Set as default") { makeDefault(address) }.frame(minHeight: 44)
                        .foregroundStyle(BoxzyTheme.muted)
                }
                Button("Edit") { editorRoute = .edit(address) }.frame(minWidth: 44, minHeight: 44)
                    .foregroundStyle(BoxzyTheme.blue)
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.plain)
            .padding(.top, 22)
        }
        .padding(18)
        .background(BoxzyAccountSurface(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(BoxzyTheme.stroke.opacity(0.72), lineWidth: 1) }
    }

    private var circleBackButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .boxzyFont(16, weight: .semibold)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }

    private func makeDefault(_ selected: AccountAddress) {
        for index in addresses.indices {
            addresses[index].isDefault = addresses[index].id == selected.id
        }
        AddressBookStore.save(addresses)
        hasAddress = !addresses.isEmpty
    }

    private func addressIcon(for label: String) -> String {
        switch label.lowercased() {
        case "home": "house.fill"
        case "office": "briefcase.fill"
        case "parents": "person.2.fill"
        case "warehouse": "shippingbox.fill"
        default: "mappin.and.ellipse"
        }
    }

    private func save(_ savedAddress: AccountAddress) {
        if savedAddress.isDefault {
            for index in addresses.indices { addresses[index].isDefault = false }
        }
        if let index = addresses.firstIndex(where: { $0.id == savedAddress.id }) {
            addresses[index] = savedAddress
        } else {
            addresses.append(savedAddress)
        }
        AddressBookStore.save(addresses)
        hasAddress = !addresses.isEmpty
    }
}

struct AddAddressView: View {
    let save: (AccountAddress) -> Void
    private let addressFormTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var id: UUID
    @State private var label: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var street: String
    @State private var apartment: String
    @State private var city: String
    @State private var state: String
    @State private var zip: String
    @State private var phone: String
    @State private var email: String
    @State private var isDefault: Bool

    init(address: AccountAddress? = nil, save: @escaping (AccountAddress) -> Void) {
        self.save = save
        self.addressFormTitle = address == nil ? "Add address" : "Edit address"
        _id = State(initialValue: address?.id ?? UUID())
        _label = State(initialValue: address?.label ?? "Home")
        _firstName = State(initialValue: address?.firstName ?? "")
        _lastName = State(initialValue: address?.lastName ?? "")
        _street = State(initialValue: address?.street ?? "")
        _apartment = State(initialValue: address?.apartment ?? "")
        _city = State(initialValue: address?.city ?? "")
        _state = State(initialValue: address?.state ?? "")
        _zip = State(initialValue: address?.zip ?? "")
        _phone = State(initialValue: address?.phone ?? "")
        _email = State(initialValue: address?.email ?? "")
        _isDefault = State(initialValue: address?.isDefault ?? true)
    }

    private var isValid: Bool {
        !label.isEmpty && !firstName.isEmpty && !lastName.isEmpty && !street.isEmpty && !city.isEmpty && !state.isEmpty && !zip.isEmpty && !phone.isEmpty && email.contains("@")
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.52, y: 0.30))

            VStack(spacing: 0) {
                formHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact").boxzyFont(20, weight: .semibold)
                        HStack(alignment: .top, spacing: 12) {
                            field("First name", "First name", text: $firstName)
                            field("Last name", "Last name", text: $lastName)
                        }
                        field("Phone", "(555) 123-4567", text: $phone, keyboard: .phonePad)
                        field("Email", "you@example.com", text: $email, keyboard: .emailAddress)
                        Text("Address").boxzyFont(20, weight: .semibold).padding(.top, 12)
                        field("Address label", "Home", text: $label)
                        pickerField("Country", value: "United States", required: true)
                        field("Street address", "Street address", text: $street)
                        field("Apartment, suite, etc. (optional)", "Apartment, suite…", text: $apartment, required: false)
                        field("City", "City", text: $city)
                        HStack(alignment: .top, spacing: 12) {
                            field("State", "State", text: $state)
                            field("ZIP code", "ZIP code", text: $zip, keyboard: .numberPad)
                        }
                        Toggle("Set as default address", isOn: $isDefault)
                            .boxzyFont(16).tint(BoxzyTheme.gold).frame(minHeight: 44)
                        Text("Use this address as my default for future orders.")
                            .boxzyFont(13).foregroundStyle(BoxzyTheme.muted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Complete the required fields to save.")
                            .font(.caption).foregroundStyle(BoxzyTheme.muted)
                        Button("Save address") { saveAddress() }
                            .boxzyFont(15, weight: .semibold)
                            .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 11))
                            .disabled(!isValid)
                            .opacity(isValid ? 1 : 0.46)
                    }.padding(.horizontal, 20).padding(.vertical, 10).background(BoxzyTheme.background)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var formHeader: some View {
        ZStack {
            Text(addressFormTitle)
                .boxzyFont(18, weight: .semibold)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .boxzyFont(16, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(BoxzyTheme.deepSurface.opacity(0.78), in: Circle())
                        .overlay { Circle().stroke(BoxzyTheme.blue.opacity(0.62), lineWidth: 1) }
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
    }

    private func requiredLabel(_ title: String, required: Bool = true) -> some View {
        HStack(spacing: 7) {
            Text(title)
                .boxzyFont(13, weight: .semibold)
                .foregroundStyle(BoxzyTheme.muted)
            if required {
                Circle().fill(BoxzyTheme.gold).frame(width: 4, height: 4)
            }
        }
    }

    private func input(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, trailingChevron: Bool = false) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text)
                .boxzyFont(16)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
            if trailingChevron {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 48)
        .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 11))
        .overlay { RoundedRectangle(cornerRadius: 11).stroke(BoxzyTheme.stroke.opacity(0.72), lineWidth: 1) }
    }

    private func field(_ title: String, _ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, required: Bool = true, trailingChevron: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            requiredLabel(title, required: required)
            input(placeholder, text: text, keyboard: keyboard, trailingChevron: trailingChevron)
                .overlay {
                    if title == "ZIP code" && !street.isEmpty && zip.isEmpty {
                        RoundedRectangle(cornerRadius: 11).stroke(BoxzyTheme.danger, lineWidth: 1)
                    }
                }
            if title == "ZIP code" && !street.isEmpty && zip.isEmpty {
                Text("Enter ZIP code").boxzyFont(13).foregroundStyle(BoxzyTheme.danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pickerField(_ title: String, value: String, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            requiredLabel(title, required: required)
            HStack {
                Text(value)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .boxzyFont(16)
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 11))
            .overlay { RoundedRectangle(cornerRadius: 11).stroke(BoxzyTheme.stroke.opacity(0.72), lineWidth: 1) }
        }
    }

    private func saveAddress() {
        guard isValid else { return }
        save(AccountAddress(id: id, label: label, firstName: firstName, lastName: lastName, street: street, apartment: apartment, city: city, state: state, zip: zip, phone: phone, email: email, isDefault: isDefault))
    }
}

private struct SignOutSheet: View {
    let confirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ConfirmationSheetLayout(icon: "rectangle.portrait.and.arrow.right", iconColor: BoxzyTheme.blue, title: "Sign out?", message: "You can browse as a guest and sign back in at any time.") {
            Button("Sign out", action: confirm).boxzyFont(16, weight: .semibold).buttonStyle(BoxzyPrimaryButtonStyle())
            Button("CANCEL") { dismiss() }
                .font(.headline).foregroundStyle(BoxzyTheme.blue).frame(maxWidth: .infinity).frame(height: 44)
                .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 15)).buttonStyle(.plain)
        }
        .presentationDetents([.fraction(0.48)]).presentationCornerRadius(28).presentationBackground(BoxzyTheme.background)
    }
}

private struct DeleteAccountSheet: View {
    let balance: Double
    let confirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("boxzy.pendingWithdrawals") private var pendingWithdrawals = 1
    @AppStorage("boxzy.pendingShipments") private var pendingShipments = 0
    @AppStorage("boxzy.unfinishedOrders") private var unfinishedOrders = 0
    @State private var confirmationText = ""

    private var hasBlockers: Bool { pendingWithdrawals > 0 || pendingShipments > 0 || unfinishedOrders > 0 }
    private var canDelete: Bool { confirmationText == "DELETE" && !hasBlockers }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: .top)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Capsule().fill(BoxzyTheme.muted.opacity(0.62)).frame(width: 42, height: 5).padding(.top, 10)
                    Image(systemName: "trash")
                        .boxzyFont(27, weight: .medium).foregroundStyle(BoxzyTheme.danger)
                        .frame(width: 62, height: 62).background(BoxzyTheme.danger.opacity(0.1), in: Circle())
                        .overlay(Circle().stroke(BoxzyTheme.danger.opacity(0.5), lineWidth: 1)).padding(.top, 20)
                    Text("Delete account?").font(.title2.bold()).padding(.top, 15)
                    Text("This permanently removes your account, collection,\naddresses, and history. This action cannot be undone.")
                        .font(.subheadline).foregroundStyle(BoxzyTheme.muted).multilineTextAlignment(.center).lineSpacing(3).padding(.top, 8)

                    HStack(spacing: 16) {
                        Image(systemName: "wallet.bifold").font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remaining balance: $\(balance, specifier: "%.2f")").font(.subheadline.weight(.semibold))
                            Text("Any remaining promotional balance is forfeited.").font(.caption)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(BoxzyTheme.danger).padding(.horizontal, 18).frame(height: 76)
                    .background(BoxzyTheme.danger.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BoxzyTheme.danger.opacity(0.46), lineWidth: 1))
                    .padding(.top, 18)

                    VStack(spacing: 0) {
                        blockerRow("Pending withdrawals", count: pendingWithdrawals, unit: "processing")
                        Divider().overlay(BoxzyTheme.stroke.opacity(0.55))
                        blockerRow("Items awaiting shipment", count: pendingShipments, unit: "waiting")
                        Divider().overlay(BoxzyTheme.stroke.opacity(0.55))
                        blockerRow("Unfinished orders", count: unfinishedOrders, unit: "open")
                    }
                    .padding(.horizontal, 16)
                    .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(BoxzyTheme.stroke.opacity(0.72), lineWidth: 1))
                    .padding(.top, 10)

                    if hasBlockers {
                        Text("Finish all pending activity before deleting your account.")
                            .font(.caption).foregroundStyle(BoxzyTheme.danger).padding(.top, 10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TYPE DELETE TO CONFIRM").boxzyFieldLabel().tracking(1.4)
                        TextField("DELETE", text: $confirmationText)
                            .textInputAutocapitalization(.characters).autocorrectionDisabled()
                            .padding(.horizontal, 16).frame(height: 50)
                            .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(BoxzyTheme.stroke.opacity(0.85), lineWidth: 1))
                    }
                    .padding(.top, 16)

                    Button("DELETE ACCOUNT", action: confirm)
                        .font(.headline).tracking(1.5).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(BoxzyTheme.danger, in: RoundedRectangle(cornerRadius: 13)).buttonStyle(.plain)
                        .disabled(!canDelete).opacity(canDelete ? 1 : 0.36).padding(.top, 12)
                    Button("CANCEL") { dismiss() }
                        .font(.headline).tracking(1.5).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(minHeight: 48)
                        .background(BoxzyTheme.inputSurface, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(BoxzyTheme.stroke.opacity(0.7), lineWidth: 1))
                        .buttonStyle(.plain).padding(.top, 8)
                    Label("Apple or Google verification is required before final deletion.", systemImage: "lock")
                        .font(.caption).foregroundStyle(BoxzyTheme.muted).padding(.top, 15).padding(.bottom, 12)
                }
                .padding(.horizontal, 20)
            }
        }
        .presentationDetents([.fraction(0.84)]).presentationDragIndicator(.hidden)
        .presentationCornerRadius(28).presentationBackground(BoxzyTheme.background)
    }

    private func blockerRow(_ title: String, count: Int, unit: String = "") -> some View {
        HStack(spacing: 12) {
            Image(systemName: count > 0 ? "exclamationmark.circle" : "checkmark.circle")
                .font(.title3).foregroundStyle(count > 0 ? BoxzyTheme.danger : BoxzyTheme.success)
            Text(title).font(.subheadline)
            Spacer()
            Text(count > 0 ? "\(count) \(unit)" : "None")
                .font(.subheadline).foregroundStyle(count > 0 ? BoxzyTheme.danger : BoxzyTheme.muted)
        }
        .frame(height: 54)
    }

}

private struct ConfirmationSheetLayout<Actions: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    @ViewBuilder let actions: Actions

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: .top)
            VStack(spacing: 0) {
                Capsule().fill(BoxzyTheme.muted.opacity(0.55)).frame(width: 42, height: 5).padding(.top, 10)
                Image(systemName: icon).boxzyFont(27, weight: .medium).foregroundStyle(iconColor)
                    .frame(width: 64, height: 64).background(iconColor.opacity(0.1), in: Circle())
                    .overlay(Circle().stroke(iconColor.opacity(0.55), lineWidth: 1)).padding(.top, 28)
                Text(title).font(.title2.bold()).padding(.top, 20)
                Text(message).font(.subheadline).foregroundStyle(BoxzyTheme.muted).multilineTextAlignment(.center)
                    .lineSpacing(3).padding(.horizontal, 24).padding(.top, 9)
                VStack(spacing: 12) { actions }.padding(.horizontal, 20).padding(.top, 24)
                Spacer(minLength: 12)
            }
        }
    }
}

private struct BoxzyChildScreen<Content: View, Trailing: View>: View {
    let title: String
    let dismiss: () -> Void
    let trailing: Trailing
    let content: Content

    init(title: String, dismiss: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content) {
        self.title = title
        self.dismiss = dismiss
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()
            BoxzyAccountGlow(center: UnitPoint(x: 0.5, y: 0.35))
            VStack(spacing: 0) {
                ZStack {
                    Text(title).font(.headline)
                    HStack {
                        Button(action: dismiss) { Image(systemName: "chevron.left") }.buttonStyle(.bordered)
                        Spacer()
                        trailing
                    }
                }
                .padding(.horizontal, 20).frame(height: 60)
                content
            }
        }
    }
}

private extension BoxzyChildScreen where Trailing == EmptyView {
    init(title: String, dismiss: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.init(title: title, dismiss: dismiss, trailing: { EmptyView() }, content: content)
    }
}

private struct ShippingAddressMark: View {
    var body: some View {
        ZStack {
            BoxzyBoxMark()
            Image(systemName: "location.fill").boxzyFont(19, weight: .bold)
                .foregroundStyle(BoxzyTheme.surface).offset(y: 8)
        }
    }
}

private struct BoxzyAccountGlow: View {
    let center: UnitPoint
    var body: some View { Color.clear.allowsHitTesting(false).accessibilityHidden(true) }
}
private struct AccountWalletSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16).fill(BoxzyTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(BoxzyTheme.stroke, lineWidth: 1))
    }
}

private struct BoxzyAccountSurface: View {
    let cornerRadius: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(BoxzyTheme.surface)
    }
}

private extension Text {
    func boxzyFieldLabel() -> some View {
        font(.caption.weight(.semibold)).tracking(0.5).foregroundStyle(BoxzyTheme.muted)
    }
}

private extension BoxzyTheme {
    static let deepSurface = BoxzyTheme.surface
    static let inputSurface = BoxzyTheme.background
    static let success = BoxzyTheme.gold
    static let danger = Color(red: 1.0, green: 0.24, blue: 0.30)
}

private struct AccountMessageSheet: View {
    let title: String
    let icon: String
    let message: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: icon, description: Text(message))
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .presentationDetents([.medium]).presentationCornerRadius(28).presentationBackground(BoxzyTheme.background)
    }
}

struct SignedInAccountView_Previews: PreviewProvider {
    static var previews: some View {
        SignedInAccountView(isAuthenticated: .constant(true)).frame(width: 402, height: 874).preferredColorScheme(.dark)
    }
}
