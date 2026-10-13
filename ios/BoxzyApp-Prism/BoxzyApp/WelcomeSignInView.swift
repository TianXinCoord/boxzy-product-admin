import SwiftUI

struct WelcomeSignInView: View {
    private enum Provider {
        case google
    }

    private enum LegalDocument: String, Identifiable {
        case terms = "Terms of Service"
        case privacy = "Privacy Policy"

        var id: Self { self }
    }

    let authenticated: () -> Void
    let headline: String
    let supportingMessage: String
    let close: (() -> Void)?

    @AppStorage("boxzy.hasBoundPhone") private var hasBoundPhone = false
    @AppStorage("boxzy.phoneNumber") private var phoneNumber = ""
    @State private var errorMessage: String?
    @State private var activeProvider: Provider?
    @State private var lastAttemptedProvider: Provider?
    @State private var legalDocument: LegalDocument?
    @State private var isPresentingPhoneVerification = false

    init(
        authenticated: @escaping () -> Void,
        headline: String = "Open boxes. Keep what you pull.",
        supportingMessage: String = "Sign in to start pulling and track your collection.",
        close: (() -> Void)? = nil
    ) {
        self.authenticated = authenticated
        self.headline = headline
        self.supportingMessage = supportingMessage
        self.close = close
    }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()


            VStack(spacing: 0) {
                Spacer(minLength: 28)

                hero

                Spacer(minLength: 28)

                actions

                legalCopy
                    .padding(.top, 24)
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 28)

            if let close {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .boxzyFont(16, weight: .semibold)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(BoxzyTheme.surface.opacity(0.88), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close")
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .overlay(alignment: .top) {
            if let errorMessage {
                signInErrorBanner(errorMessage)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(item: $legalDocument) { document in
            LegalDocumentView(title: document.rawValue)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(BoxzyTheme.background)
        }
        .fullScreenCover(isPresented: $isPresentingPhoneVerification) {
            PhoneVerificationFlowView(
                verified: { verifiedPhoneNumber in
                    phoneNumber = verifiedPhoneNumber
                    hasBoundPhone = true
                    isPresentingPhoneVerification = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        authenticated()
                    }
                },
                useDifferentAccount: {
                    activeProvider = nil
                    isPresentingPhoneVerification = false
                }
            )
            .interactiveDismissDisabled()
        }
        .onAppear {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BoxzyPhonePreview") { isPresentingPhoneVerification = true }
            if ProcessInfo.processInfo.arguments.contains("-BoxzyLegalPreview") { legalDocument = .terms }
#endif
        }
        .preferredColorScheme(.dark)
        .animation(.easeOut(duration: 0.22), value: errorMessage)
    }

    private var hero: some View {
        VStack(spacing: 22) {
            ZStack {
                PrismaticDiamond()
                    .stroke(BoxzyTheme.gold.opacity(0.20), lineWidth: 1)
                    .frame(width: 210, height: 250)
                    .shadow(color: BoxzyTheme.gold.opacity(0.18), radius: 24)

                Image("boxzy-logo-white")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 230)
                    .shadow(color: BoxzyTheme.gold.opacity(0.18), radius: 26)
                    .accessibilityLabel("BOXZY")
            }
            .frame(height: 250)

            Text(headline)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if !supportingMessage.isEmpty {
                Text(supportingMessage)
                    .font(.subheadline)
                    .foregroundStyle(BoxzyTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, -8)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 18) {
            Button(action: beginGoogleSignIn) {
                SignInActionLabel(
                    title: activeProvider == .google ? "Connecting…" : "Continue with Google",
                    foregroundColor: .black,
                    isLoading: activeProvider == .google
                ) {
                    GoogleSignInMark()
                }
            }
            .buttonStyle(.plain)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            .disabled(activeProvider != nil)

            HStack(spacing: 7) {
                Image(systemName: "lock")
                    .font(.caption.weight(.medium))
                Text("Secure sign-in powered by Google")
                    .font(.caption)
            }
            .foregroundStyle(BoxzyTheme.muted)
            .accessibilityElement(children: .combine)
        }
    }

    private struct SignInActionLabel<Icon: View>: View {
        let title: String
        let foregroundColor: Color
        var isLoading = false
        @ViewBuilder let icon: () -> Icon

        var body: some View {
            HStack(spacing: 12) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(foregroundColor)
                    } else {
                        icon()
                    }
                }
                .frame(width: 24, height: 24)

                Text(title)
                    .boxzyFont(16, weight: .semibold)
                    .lineLimit(1)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
    }

    private func signInErrorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .boxzyFont(19, weight: .semibold)
                .foregroundStyle(signInErrorColor)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Retry", action: retryLastSignIn)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BoxzyTheme.blue)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.055, blue: 0.075), BoxzyTheme.surface.opacity(0.96)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(signInErrorColor.opacity(0.42), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.34), radius: 16, y: 7)
        .accessibilityElement(children: .combine)
    }

    private var legalCopy: some View {
        VStack(spacing: 5) {
            Text("By continuing, you agree to our")
                .foregroundStyle(BoxzyTheme.muted)

            HStack(spacing: 14) {
                Button("Terms of Service") {
                    legalDocument = .terms
                }
                Button("Privacy Policy") {
                    legalDocument = .privacy
                }
            }
            .foregroundStyle(Color(.systemGray3))
            .underline()
        }
        .font(.caption)
        .multilineTextAlignment(.center)
    }

    private func beginGoogleSignIn() {
        beginAuthorization(with: .google)

        Task { @MainActor in
            // Replace this deterministic prototype callback with GIDSignIn when the
            // Google client ID and URL scheme are added to the app target.
            try? await Task.sleep(for: .milliseconds(450))
            guard activeProvider == .google else { return }
            activeProvider = nil

            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-BoxzyCancelGoogleSignIn") {
                return
            }
            if arguments.contains("-BoxzyGoogleNetworkFailure") {
                errorMessage = "Check your connection and try again."
                return
            }
            if arguments.contains("-BoxzyGoogleAccountUnavailable") {
                errorMessage = "This Google account is unavailable."
                return
            }
            if arguments.contains("-BoxzyGoogleSignInFailure") {
                errorMessage = "Google sign-in failed. Please try again."
                return
            }

            completeProviderAuthentication()
        }
    }

    private func completeProviderAuthentication() {
        let forcesPhoneVerification = ProcessInfo.processInfo.arguments.contains("-BoxzyRequiresPhoneVerification")
        if hasBoundPhone && !forcesPhoneVerification {
            authenticated()
        } else {
            isPresentingPhoneVerification = true
        }
    }

    private func beginAuthorization(with provider: Provider) {
        errorMessage = nil
        lastAttemptedProvider = provider
        activeProvider = provider
    }

    private func retryLastSignIn() {
        guard activeProvider == nil else { return }
        if lastAttemptedProvider == .google {
            beginGoogleSignIn()
        } else {
            errorMessage = nil
        }
    }

    private var signInErrorColor: Color {
        Color(red: 1.0, green: 0.24, blue: 0.30)
    }
}

private struct PhoneVerificationFlowView: View {
    private enum Step {
        case phone
        case code
    }

    private enum FocusedField {
        case phone
        case code
    }

    let verified: (String) -> Void
    let useDifferentAccount: () -> Void

    @State private var step: Step = .phone
    @State private var phoneDigits = ""
    @State private var verificationCode = ""
    @State private var verificationError: String?
    @State private var isSendingCode = false
    @State private var isVerifying = false
    @State private var resendSeconds = 60
    @State private var resendGeneration = 0
    @FocusState private var focusedField: FocusedField?

    private var isPhoneValid: Bool {
#if DEBUG
        !phoneDigits.isEmpty
#else
        phoneDigits.count == 10
#endif
    }

    private var isCodeComplete: Bool {
#if DEBUG
        !verificationCode.isEmpty
#else
        verificationCode.count == 6
#endif
    }
    private var fullPhoneNumber: String { "+1" + phoneDigits }

    var body: some View {
        ZStack {
            BoxzyTheme.background.ignoresSafeArea()


            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    verificationHeader

                    securityMark
                        .padding(.top, 28)

                    Text("SECURE ACCOUNT")
                        .font(.subheadline.weight(.bold))
                        .tracking(0.7)
                        .foregroundStyle(BoxzyTheme.blue)
                        .padding(.top, 22)

                    Group {
                        switch step {
                        case .phone:
                            phoneStep
                        case .code:
                            codeStep
                        }
                    }
                    .padding(.top, 12)

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: 560)
                
                .padding(.horizontal, 26)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .task(id: resendGeneration) {
            guard step == .code else { return }
            while resendSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                resendSeconds -= 1
            }
        }
    }

    private var verificationHeader: some View {
        HStack(spacing: 12) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.075), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step == .phone ? "Use a different account" : "Back to phone number")

            Spacer()

            Text("Verify phone")
                .font(.title3.weight(.semibold))

            Spacer()

            Color.clear
                .frame(width: 46, height: 46)
        }
        .padding(.top, 10)
    }

    private var securityMark: some View {
        ZStack {
            Image(systemName: "shield")
                .boxzyFont(84, weight: .medium)
                .foregroundStyle(BoxzyTheme.blue)


            Image(systemName: step == .phone ? "iphone" : "ellipsis")
                .font(.system(size: step == .phone ? 36 : 30, weight: .semibold))
                .foregroundStyle(BoxzyTheme.goldLight)
        }
        .frame(width: 112, height: 112)
        .accessibilityHidden(true)
    }

    private var phoneStep: some View {
        VStack(spacing: 0) {
            Text("Add your phone number")
                .boxzyFont(28, weight: .bold)
                .multilineTextAlignment(.center)

            Text("We’ll send a verification code to confirm it’s you.")
                .font(.body)
                .foregroundStyle(BoxzyTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            VStack(alignment: .leading, spacing: 10) {
                Text("PHONE NUMBER")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(BoxzyTheme.muted)

                HStack(spacing: 0) {
                    Text("+1")
                        .font(.title3.weight(.bold))
                        .frame(width: 76)
                        .accessibilityLabel("Country code plus one")

                    Rectangle()
                        .fill(BoxzyTheme.stroke)
                        .frame(width: 1)

                    TextField("(555) 123-4567", text: phoneBinding)
                        .font(.title3)
                        .keyboardType(.numberPad)
                        .textContentType(.telephoneNumber)
                        .focused($focusedField, equals: .phone)
                        .padding(.horizontal, 18)
                        .accessibilityLabel("Phone number")
                }
                .frame(height: 58)
                .background(BoxzyTheme.surface.opacity(0.60), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(focusedField == .phone ? BoxzyTheme.blue : BoxzyTheme.stroke, lineWidth: 1)
                }
            }
            .padding(.top, 24)

            Button(action: sendCode) {
                Group {
                    if isSendingCode {
                        ProgressView().tint(.white)
                    } else {
                        Text("Send code")
                            .boxzyFont(16, weight: .semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BoxzyPrimaryButtonStyle())
            .disabled(!isPhoneValid || isSendingCode)

            .padding(.top, 18)

            Text("Standard messaging rates may apply. We’ll only use this number for account security and delivery updates.")
                .font(.footnote)
                .foregroundStyle(BoxzyTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 22)
                .padding(.top, 20)

            Button("Use a different account", action: useDifferentAccount)
                .font(.body.weight(.medium))
                .foregroundStyle(BoxzyTheme.blue)
                .buttonStyle(.plain)
                .padding(.top, 27)
        }
    }

    private var codeStep: some View {
        VStack(spacing: 0) {
            Text("Enter verification code")
                .boxzyFont(28, weight: .bold)
                .multilineTextAlignment(.center)

            Text("We sent a 6-digit code to \(formattedFullPhoneNumber).")
                .font(.body)
                .foregroundStyle(BoxzyTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            ZStack {
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        Text(codeDigit(at: index))
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(codeCellColor(at: index), lineWidth: verificationError == nil ? 1 : 1.5)
                            }
                    }
                }

                TextField("Verification code", text: codeBinding)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .code)
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .opacity(0.02)
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .code }
            .padding(.top, 40)

            if let verificationError {
                Text(verificationError)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(phoneErrorColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            Button(action: verifyCode) {
                Group {
                    if isVerifying {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify")
                            .boxzyFont(16, weight: .semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BoxzyPrimaryButtonStyle())
            .disabled(!isCodeComplete || isVerifying)

            .padding(.top, verificationError == nil ? 28 : 20)

            Group {
                if resendSeconds > 0 {
                    Text("Didn’t receive a code? Resend in \(resendSeconds)s")
                        .foregroundStyle(BoxzyTheme.muted)
                } else {
                    Button("Didn’t receive a code? Resend") {
                        resendCode()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(BoxzyTheme.blue)
                }
            }
            .font(.subheadline)
            .padding(.top, 22)

            Button("Change phone number") {
                withAnimation(.snappy(duration: 0.24)) {
                    step = .phone
                    verificationCode = ""
                    verificationError = nil
                }
            }
            .font(.body.weight(.medium))
            .foregroundStyle(BoxzyTheme.blue)
            .buttonStyle(.plain)
            .padding(.top, 22)
        }
    }

    private var phoneBinding: Binding<String> {
        Binding(
            get: { formattedPhoneDigits },
            set: { value in
                phoneDigits = String(value.filter(\.isNumber).prefix(10))
            }
        )
    }

    private var codeBinding: Binding<String> {
        Binding(
            get: { verificationCode },
            set: { value in
                verificationCode = String(value.filter(\.isNumber).prefix(6))
                verificationError = nil
            }
        )
    }

    private var formattedPhoneDigits: String {
        let digits = Array(phoneDigits)
        switch digits.count {
        case 0:
            return ""
        case 1...3:
            return "(" + String(digits) + (digits.count == 3 ? ")" : "")
        case 4...6:
            return "(" + String(digits[0..<3]) + ") " + String(digits[3..<digits.count])
        default:
            return "(" + String(digits[0..<3]) + ") " + String(digits[3..<6]) + "-" + String(digits[6..<digits.count])
        }
    }

    private var formattedFullPhoneNumber: String {
        "+1 " + formattedPhoneDigits
    }

    private func codeDigit(at index: Int) -> String {
        guard verificationCode.indices.contains(verificationCode.index(verificationCode.startIndex, offsetBy: index, limitedBy: verificationCode.endIndex) ?? verificationCode.endIndex) else {
            return ""
        }
        return String(verificationCode[verificationCode.index(verificationCode.startIndex, offsetBy: index)])
    }

    private func codeCellColor(at index: Int) -> Color {
        if verificationError != nil {
            return phoneErrorColor
        }
        if focusedField == .code && index == min(verificationCode.count, 5) {
            return BoxzyTheme.blue
        }
        return BoxzyTheme.stroke
    }

    private func goBack() {
        focusedField = nil
        if step == .phone {
            useDifferentAccount()
        } else {
            withAnimation(.snappy(duration: 0.24)) {
                step = .phone
                verificationCode = ""
                verificationError = nil
            }
        }
    }

    private func sendCode() {
        guard isPhoneValid, !isSendingCode else { return }
        focusedField = nil
        isSendingCode = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            isSendingCode = false
            resendSeconds = 60
            resendGeneration += 1
            withAnimation(.snappy(duration: 0.24)) {
                step = .code
            }
            try? await Task.sleep(for: .milliseconds(260))
            focusedField = .code
        }
    }

    private func verifyCode() {
        guard isCodeComplete, !isVerifying else { return }
        focusedField = nil
        verificationError = nil
        isVerifying = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
            isVerifying = false

            // Debug builds accept any non-empty code to keep the whole app testable.
#if DEBUG
            let isAccepted = !verificationCode.isEmpty
#else
            let isAccepted = verificationCode == "123456"
#endif
            if isAccepted {
                verified(fullPhoneNumber)
            } else {
                verificationError = "The code is incorrect. Check it and try again."
                focusedField = .code
            }
        }
    }

    private func resendCode() {
        verificationCode = ""
        verificationError = nil
        resendSeconds = 60
        resendGeneration += 1
        focusedField = .code
    }

    private var phoneErrorColor: Color {
        Color(red: 1.0, green: 0.24, blue: 0.30)
    }
}

private struct PrismaticDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

private struct GoogleSignInMark: View {
    var body: some View {
        Image("google-g")
            .resizable()
            .scaledToFit()
        .accessibilityHidden(true)
    }
}

private struct LegalDocumentView: View {
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

struct WelcomeSignInView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeSignInView(authenticated: {})
            .frame(width: 402, height: 874)
            .previewDisplayName("Sign in · iPhone 17 Pro")
    }
}
