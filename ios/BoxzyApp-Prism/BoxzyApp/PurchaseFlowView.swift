import AVFAudio
import AVFoundation
import AudioToolbox
import AuthenticationServices
import SwiftUI
import UIKit

struct PurchaseFlowView: View {
  private enum Stage: Equatable {
    case preflight
    case signIn
    case addFunds
    case chooseBox
    case cinematic
    case locked
    case unfolding
    case revealing
    case result
    case waiting, failed, updating
    case soldUpsell
  }

  let box: MysteryBox
  @Binding var isAuthenticated: Bool
  @Binding var balance: Double
  let resumeUnopenedBoxID: String?

  @Environment(\.dismiss) private var dismiss
  @StateObject private var audioGate = AudioGatePlayer()
  @State private var stage: Stage = .preflight
  @State private var selectedNumber = 7
  @State private var purchaseCharged = false
  @State private var activeUnopenedBoxID: String?
  @State private var toast: FlowToast?
  @State private var isShowingSellOffer = false
  @State private var isSubmittingSale = false
  @State private var sellToast: FlowToast?
  @State private var earnedItemID: String?

  private let prize = PullPrize(
    id: "prismatic-evolutions-reveal",
    name: "151 Booster Bundle",
    value: 69,
    imageName: "prize-151-bundle",
    category: "BOOSTER BUNDLE",
    rarity: "RARE",
    dropChance: "—",
    boxID: "starter"
  )

  init(
    box: MysteryBox,
    isAuthenticated: Binding<Bool>,
    balance: Binding<Double>,
    resumeUnopenedBoxID: String? = nil
  ) {
    self.box = box
    _isAuthenticated = isAuthenticated
    _balance = balance
    self.resumeUnopenedBoxID = resumeUnopenedBoxID
    _activeUnopenedBoxID = State(initialValue: resumeUnopenedBoxID)
  }

  var body: some View {
    ZStack {
      BoxzyTheme.background.ignoresSafeArea()
      if stage == .waiting { Image("reveal-static").resizable().scaledToFill().ignoresSafeArea() }

      Group {
        switch stage {
        case .preflight:
          ProgressView()
            .tint(BoxzyTheme.blue)
        case .signIn:
          PurchaseSignInView(
            onSuccess: authenticationSucceeded,
            onFailure: cancelPurchase
          )
        case .addFunds:
          PurchaseAddFundsView(
            box: box,
            balance: balance,
            requiredAmount: max(5, Double(box.price) - balance),
            onSuccess: depositSucceeded,
            onFailure: cancelPurchase
          )
        case .chooseBox:
          BoxNumberSelectionView(
            box: box,
            balance: balance,
            selectedNumber: $selectedNumber,
            onBack: cancelPurchase,
            onChoose: lockSelectedBox,
            onCancel: cancelPurchase
          )
        case .cinematic:
          if box.id == "elite" {
            VStack(spacing: 24) {
              Image(box.imageName).resizable().scaledToFit().frame(maxWidth: 280, maxHeight: 300)
              ProgressView().tint(BoxzyTheme.gold)
              Text("Revealing your prize…").font(.subheadline).foregroundStyle(BoxzyTheme.muted)
            }
              .task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                completeDemoReveal()
              }
          } else {
          OpeningCinematicView(resourceName: openingVideoResourceName) {
            withAnimation(.easeInOut(duration: 0.35)) {
              completeDemoReveal()
            }
          }
          }
        case .locked:
          LockedBoxView(
            box: box,
            boxNumber: selectedNumber,
            balance: balance,
            onBack: cancelPurchase,
            onStart: startUnfolding,
            onChooseAnother: chooseAnotherBox
          )
        case .unfolding:
          UnfoldingBoxView(box: box, boxNumber: selectedNumber)
        case .revealing:
          PrizeRevealTransitionView(prize: prize, duration: max(audioGate.duration, 1.8))
        case .result:
          PrizeResultView(
            prize: prize,
            boxPrice: box.price,
            onKeep: keepPrize,
            onSell: { isShowingSellOffer = true },
            onOpenAnother: openAnotherBox
          )
        case .waiting:
          VStack(spacing: 12) { ProgressView().tint(BoxzyTheme.gold); Text("Revealing your prize…").font(.subheadline) }
        case .failed, .updating:
          openingMessage
        case .soldUpsell:
          PostSaleUpsellView(
            box: box,
            credit: Double(prize.value) * 0.90,
            onOpenAgain: openSameBoxAfterSale,
            onMaybeLater: dismiss.callAsFunction
          )
        }
      }

      if isShowingSellOffer {
        SellOfferPresentation(
          isSubmitting: isSubmittingSale,
          onDismiss: dismissSellOffer
        ) {
          InstantSellOfferView(
            prize: prize,
            isSubmitting: isSubmittingSale,
            onSell: submitInstantSale,
            onKeep: keepFromSellOffer
          )
        }
        .transition(.opacity)
        .zIndex(15)
      }

      if let toast {
        FlowToastView(toast: toast)
          .transition(.move(edge: .top).combined(with: .opacity))
          .zIndex(20)
      }

      if let sellToast {
        FlowToastView(toast: sellToast)
          .transition(.move(edge: .top).combined(with: .opacity))
          .zIndex(30)
      }
    }
    .preferredColorScheme(.dark)
    .interactiveDismissDisabled(stage != .signIn && stage != .addFunds && stage != .chooseBox)
    .task {
#if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-BoxzyOpeningUpdating") { stage = .updating; return }
      if ProcessInfo.processInfo.arguments.contains("-BoxzyOpeningFailure") { stage = .failed; return }
      if ProcessInfo.processInfo.arguments.contains("-BoxzyOpeningLoading") { stage = .waiting; return }
      if ProcessInfo.processInfo.arguments.contains("-BoxzyPostSalePreview") {
        stage = .soldUpsell
        return
      }
      if ProcessInfo.processInfo.arguments.contains("-BoxzyPrizeResultPreview") {
        stage = .result
        return
      }
#endif
      guard stage == .preflight else { return }
      if DemoPool.isUpdating(box.id) { stage = .updating; return }
      if resumeUnopenedBoxID != nil {
        selectedNumber = 7
        stage = .chooseBox
        return
      }
      routeFromPreflight()
    }
    .onDisappear {
      audioGate.stop()
    }
  }

  private var flowBackground: some View {
    RadialGradient(
      colors: [BoxzyTheme.violet.opacity(0.16), BoxzyTheme.blue.opacity(0.08), .clear],
      center: .center,
      startRadius: 18,
      endRadius: 420
    )
    .ignoresSafeArea()
  }

  private var openingVideoResourceName: String {
    switch box.id {
    case "super": "super-box-opening-final"
    case "ultra": "ultra-box-opening-final"
    default: "box-opening-final"
    }
  }

  private func routeFromPreflight() {
    if !isAuthenticated {
      stage = .signIn
    } else {
      continueAfterAuthentication()
    }
  }

  private func authenticationSucceeded() {
    isAuthenticated = true
    continueAfterAuthentication()
  }

  private func continueAfterAuthentication() {
    if balance < Double(box.price) {
      stage = .addFunds
    } else {
      chargeAndShowSelection()
    }
  }

  private func depositSucceeded(_ amount: Double) {
    balance += amount
    guard balance >= Double(box.price) else {
      showToast("The balance is still insufficient.", kind: .error)
      return
    }
    chargeAndShowSelection()
  }

  private func chargeAndShowSelection() {
    guard !DemoPool.isUpdating(box.id) else { stage = .updating; return }
    if !purchaseCharged {
      balance -= Double(box.price)
      purchaseCharged = true
      earnedItemID = nil
      activeUnopenedBoxID = UnopenedBoxStore.addPurchased(boxID: box.id)
    }
    selectedNumber = 7
    withAnimation(.easeInOut(duration: 0.28)) {
      stage = .chooseBox
    }
  }

  private func lockSelectedBox() {
    audioGate.stop()
    guard !DemoPool.isUpdating(box.id) else { stage = .updating; return }
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    withAnimation(.easeInOut(duration: 0.30)) {
      stage = .cinematic
    }
  }

  private func chooseAnotherBox() {
    audioGate.stop()
    withAnimation(.easeInOut(duration: 0.25)) {
      stage = .chooseBox
    }
  }

  private func startUnfolding() {
    // The lock sound is atmospheric, not a gate. Opening interrupts it.
    audioGate.stop()
    guard !DemoPool.isUpdating(box.id) else { stage = .updating; return }
    withAnimation(.easeInOut(duration: 0.25)) {
      stage = .unfolding
    }
    audioGate.play(resource: "box-unfold", extension: "mp3") {
      startReveal()
    }
  }

  private func startReveal() {
    withAnimation(.easeInOut(duration: 0.25)) {
      stage = .revealing
    }
    audioGate.play(resource: "final-reveal", extension: "mp3") {
      withAnimation(.easeInOut(duration: 0.35)) {
        completeDemoReveal()
      }
    }
  }

  // Only the successful local result consumes an entitlement. API integration must use an idempotent server operation.
  private func completeDemoReveal() {
    guard !DemoPool.isUpdating(box.id) else { stage = .updating; return }
    if ProcessInfo.processInfo.arguments.contains("-BoxzyForceOpeningFailure") { stage = .failed; return }
    if let id = activeUnopenedBoxID {
      earnedItemID = CollectionInventoryStore.add(prizeID: prize.id, receiptID: id, sourceBoxID: box.id)
      UnopenedBoxStore.remove(id: id); activeUnopenedBoxID = nil
    }
    stage = .result
  }

  private var openingMessage: some View {
    ScrollView {
      VStack(spacing: 24) {
        Image(systemName: stage == .updating ? "arrow.triangle.2.circlepath" : "exclamationmark.circle")
          .boxzyFont(36).foregroundStyle(BoxzyTheme.gold)
        Text(stage == .updating ? "New prizes on the way." : "Unable to open your box")
          .font(.title2.bold()).multilineTextAlignment(.center)
        Text(stage == .updating ? "Your box is safe in My Collection. Open once the update is complete." : "Your box is still in My Collection → Unopened. Please try again later.")
          .font(.body).foregroundStyle(BoxzyTheme.muted).multilineTextAlignment(.center)
        Button("Back to My Collection") {
          UserDefaults.standard.set(true, forKey: "boxzy.returnToUnopened")
          dismiss()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { NotificationCenter.default.post(name: Notification.Name("boxzy.openCollection"), object: nil) }
        }.buttonStyle(BoxzyPrimaryButtonStyle())
      }.padding(24).padding(.top, 160)
    }
  }

  private func keepPrize() {
    keepPrizeInCollection()
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    dismiss()
  }

  private func keepPrizeInCollection() {
    var ids = UserDefaults.standard.stringArray(forKey: "boxzy.keptPrizeIDs") ?? []
    if !ids.contains(prize.id) { ids.append(prize.id) }
    UserDefaults.standard.set(ids, forKey: "boxzy.keptPrizeIDs")
    if earnedItemID == nil { earnedItemID = CollectionInventoryStore.add(prizeID: prize.id, sourceBoxID: box.id) }
  }

  private func openAnotherBox() {
    keepPrizeInCollection()
    purchaseCharged = false
    UINotificationFeedbackGenerator().notificationOccurred(.success)

    withAnimation(.easeInOut(duration: 0.28)) {
      if balance < Double(box.price) {
        stage = .addFunds
      } else {
        chargeAndShowSelection()
      }
    }
  }

  private func openSameBoxAfterSale() {
    purchaseCharged = false
    UINotificationFeedbackGenerator().notificationOccurred(.success)

    withAnimation(.easeInOut(duration: 0.28)) {
      if balance < Double(box.price) {
        stage = .addFunds
      } else {
        chargeAndShowSelection()
      }
    }
  }

  private func keepFromSellOffer() {
    isShowingSellOffer = false
    Task {
      try? await Task.sleep(for: .milliseconds(260))
      keepPrize()
    }
  }

  private func dismissSellOffer() {
    guard !isSubmittingSale else { return }
    withAnimation(.easeOut(duration: 0.22)) {
      isShowingSellOffer = false
      sellToast = nil
    }
  }

  private func submitInstantSale() {
    guard !isSubmittingSale else { return }
    isSubmittingSale = true
    sellToast = nil

    Task {
      do {
        try await performInstantSaleRequest()
        let credit = Double(prize.value) * 0.90
        if let id = earnedItemID { CollectionInventoryStore.removePrize(id: id); earnedItemID = nil }
        balance += credit
        purchaseCharged = false
        isSubmittingSale = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isShowingSellOffer = false
        try? await Task.sleep(for: .milliseconds(320))
        withAnimation(.easeInOut(duration: 0.30)) {
          stage = .soldUpsell
        }
      } catch {
        isSubmittingSale = false
        showSellToast("Sale failed. Please try again.")
        UINotificationFeedbackGenerator().notificationOccurred(.error)
      }
    }
  }

  /// Replace this request body with the production sell endpoint. The launch
  /// argument keeps the failure state deterministic for UI and QA testing.
  private func performInstantSaleRequest() async throws {
    try await Task.sleep(for: .milliseconds(650))
    if ProcessInfo.processInfo.arguments.contains("-BoxzyForceSellFailure") {
      throw InstantSaleError.rejected
    }
  }

  private func showSellToast(_ message: String) {
    let next = FlowToast(message: message, kind: .error)
    withAnimation(.snappy) { sellToast = next }
    Task {
      try? await Task.sleep(for: .seconds(2.6))
      guard sellToast?.id == next.id else { return }
      withAnimation(.easeOut(duration: 0.2)) { sellToast = nil }
    }
  }

  private func cancelPurchase() {
    // A charged box stays in Collection > Unopened, so leaving this flow never
    // loses the purchase. The user can come back and open it before auto-sale.
    purchaseCharged = false
    audioGate.stop()
    dismiss()
  }

  private func showToast(_ message: String, kind: FlowToast.Kind) {
    let next = FlowToast(message: message, kind: kind)
    withAnimation(.snappy) { toast = next }
    Task {
      try? await Task.sleep(for: .seconds(2.6))
      guard toast?.id == next.id else { return }
      withAnimation(.easeOut(duration: 0.2)) { toast = nil }
    }
  }
}

private struct OpeningCinematicView: View {
  let resourceName: String
  let onFinished: () -> Void
  @StateObject private var playback = OpeningCinematicPlayer()

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      if let player = playback.player {
        OpeningCinematicSurface(player: player)
          .ignoresSafeArea()
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      } else {
        ProgressView()
          .tint(BoxzyTheme.blue)
      }

      if playback.hasStartedPlayback {
        VStack {
          HStack {
            Spacer()

            Button("Reveal now") {
              playback.revealNow()
            }
            .buttonStyle(CinematicRevealButtonStyle())
            .accessibilityHint("Skips the opening video and reveals your prize")
          }

          Spacer()
        }
        .padding(.top, 8)
        .padding(.trailing, 14)
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
      }
    }
    .animation(.easeOut(duration: 0.18), value: playback.hasStartedPlayback)
    .onAppear {
      playback.play(resourceName: resourceName, completion: onFinished)
    }
    .onDisappear {
      playback.stop()
    }
  }
}

private final class OpeningCinematicPlayer: ObservableObject {
  @Published private(set) var player: AVPlayer?
  @Published private(set) var hasStartedPlayback = false

  private var observers: [NSObjectProtocol] = []
  private var timeControlObservation: NSKeyValueObservation?
  private var completion: (() -> Void)?
  private var didFinish = false

  func play(resourceName: String, completion: @escaping () -> Void) {
    guard player == nil else { return }
    self.completion = completion
    didFinish = false
    hasStartedPlayback = false

    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mp4") else {
      assertionFailure("Missing bundled video: \(resourceName).mp4")
      DispatchQueue.main.async { [weak self] in self?.finishPlayback() }
      return
    }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Video playback can still continue if the audio session cannot be changed.
    }

    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.actionAtItemEnd = .pause
    self.player = player
    timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) {
      [weak self] player, _ in
      guard player.timeControlStatus == .playing else { return }
      DispatchQueue.main.async {
        self?.hasStartedPlayback = true
      }
    }

    let center = NotificationCenter.default
    observers.append(
      center.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: item,
        queue: .main
      ) { [weak self] _ in
        self?.finishPlayback()
      }
    )
    observers.append(
      center.addObserver(
        forName: .AVPlayerItemFailedToPlayToEndTime,
        object: item,
        queue: .main
      ) { [weak self] _ in
        self?.finishPlayback()
      }
    )

    player.play()
  }

  func revealNow() {
    finishPlayback()
  }

  func stop() {
    player?.pause()
    timeControlObservation?.invalidate()
    timeControlObservation = nil
    removeObservers()
    player = nil
    hasStartedPlayback = false
    completion = nil
  }

  private func finishPlayback() {
    guard !didFinish else { return }
    didFinish = true
    player?.pause()
    timeControlObservation?.invalidate()
    timeControlObservation = nil
    removeObservers()
    let callback = completion
    completion = nil
    callback?()
  }

  private func removeObservers() {
    let center = NotificationCenter.default
    observers.forEach(center.removeObserver)
    observers.removeAll()
  }

  deinit {
    timeControlObservation?.invalidate()
    removeObservers()
  }
}

private struct CinematicRevealButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.caption.weight(.semibold))
      .tracking(0.25)
      .foregroundStyle(BoxzyTheme.goldLight.opacity(0.86))
      .padding(.horizontal, 11)
      .frame(height: 32)
      .background {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .fill(Color.black.opacity(configuration.isPressed ? 0.52 : 0.30))
      }
      .overlay {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .stroke(BoxzyTheme.gold.opacity(0.42), lineWidth: 0.7)
      }
      .padding(.vertical, 6)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
  }
}

private struct OpeningCinematicSurface: UIViewRepresentable {
  let player: AVPlayer

  func makeUIView(context: Context) -> OpeningCinematicPlayerView {
    let view = OpeningCinematicPlayerView()
    view.playerLayer.videoGravity = .resizeAspectFill
    view.playerLayer.player = player
    return view
  }

  func updateUIView(_ uiView: OpeningCinematicPlayerView, context: Context) {
    uiView.playerLayer.player = player
  }
}

private final class OpeningCinematicPlayerView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

private final class AudioGatePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
  @Published private(set) var duration: TimeInterval = 0
  private var player: AVAudioPlayer?
  private var completion: (() -> Void)?

  func play(resource: String, extension fileExtension: String, completion: @escaping () -> Void) {
    stop()
    guard let url = Bundle.main.url(forResource: resource, withExtension: fileExtension) else {
      assertionFailure("Missing bundled audio: \(resource).\(fileExtension)")
      return
    }

    do {
      try AVAudioSession.sharedInstance().setCategory(
        .ambient, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: url)
      self.player = player
      self.completion = completion
      duration = player.duration
      player.delegate = self
      player.prepareToPlay()
      player.play()
    } catch {
      assertionFailure("Unable to play gated audio: \(error.localizedDescription)")
    }
  }

  func stop() {
    player?.stop()
    player = nil
    completion = nil
    duration = 0
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    guard flag else { return }
    let callback = completion
    self.player = nil
    completion = nil
    callback?()
  }
}

private struct PurchaseTopBar: View {
  let balance: Double?
  let onBack: (() -> Void)?

  var body: some View {
    HStack {
      if let onBack {
        Button(action: onBack) {
          Image(systemName: "chevron.left")
            .boxzyFont(16, weight: .semibold)
            .foregroundStyle(.white.opacity(0.92))
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.025), in: Circle())
            .overlay(Circle().stroke(BoxzyTheme.stroke.opacity(0.86), lineWidth: 1))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
      } else {
        Color.clear.frame(width: 44, height: 44)
      }

      Spacer()

      if let balance {
        Text("$\(balance, specifier: "%.2f")")
          .boxzyFont(16, weight: .semibold, design: .rounded)
          .padding(.horizontal, 16)
          .frame(minWidth: 96, minHeight: 40, maxHeight: 40)
          .background(
            LinearGradient(
              colors: [Color.white.opacity(0.085), Color.white.opacity(0.035)],
              startPoint: .top,
              endPoint: .bottom
            ),
            in: Capsule()
          )
          .overlay(Capsule().stroke(BoxzyTheme.stroke.opacity(0.90), lineWidth: 1))
      }
    }
    .padding(.horizontal, 20)
  }
}

private struct PurchaseSignInView: View {
  let onSuccess: () -> Void
  let onFailure: () -> Void

  var body: some View {
    WelcomeSignInView(
      authenticated: onSuccess,
      headline: "Sign in to continue",
      supportingMessage: "Sign in to continue your BOXZY experience.",
      close: onFailure
    )
  }
}

private struct PurchaseAddFundsView: View {
  let box: MysteryBox
  let balance: Double
  let requiredAmount: Double
  let onSuccess: (Double) -> Void
  let onFailure: () -> Void
  @State private var isProcessing = false
  @State private var enteredAmount: String

  init(box: MysteryBox, balance: Double, requiredAmount: Double, onSuccess: @escaping (Double) -> Void, onFailure: @escaping () -> Void) {
    self.box = box
    self.balance = balance
    self.requiredAmount = requiredAmount
    self.onSuccess = onSuccess
    self.onFailure = onFailure
    _enteredAmount = State(initialValue: String(Int(ceil(max(5, requiredAmount)))))
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack { Button(action: onFailure) { Image(systemName: "chevron.left").foregroundStyle(.white).frame(width: 44, height: 44) }.accessibilityLabel("Back"); Spacer() }.padding(.horizontal, 20)
      Text("Complete your purchase").boxzyFont(24, weight: .bold).padding(.top, 12)
      Text("\(box.name.capitalized) Box · \(box.price.usd)").boxzyFont(17).foregroundStyle(BoxzyTheme.muted).padding(.top, 8)
      GoldMoneyEntry(amount: $enteredAmount, balance: balance, minimum: ceil(max(5, requiredAmount)), withdrawal: false,
        context: "Add at least \(requiredAmount.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))) to continue.",
        isSubmitting: isProcessing, continuesPurchase: true) { value in
          guard !isProcessing else { return }
          isProcessing = true
          Task { @MainActor in
            do { try await Task.sleep(for: .seconds(1.1)) } catch { isProcessing = false; return }
            isProcessing = false
            onSuccess(value)
          }
      }
    }
  }
}

private struct BoxNumberSelectionView: View {
  let box: MysteryBox
  let balance: Double
  @Binding var selectedNumber: Int
  let onBack: () -> Void
  let onChoose: () -> Void
  let onCancel: () -> Void

  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var dragOffset: CGFloat = 0

  var body: some View {
    GeometryReader { geometry in
      let compact = geometry.size.height < 740
      BoxzyAdaptiveScroll(enabled: typeSize.isAccessibilitySize) {
      VStack(spacing: 0) {
        PurchaseTopBar(balance: balance, onBack: onBack)

        VStack(alignment: .leading, spacing: 12) {
          Text("Ready to open")
            .boxzyFont(28, weight: .bold)
            .accessibilityIdentifier("selection.title")
          Text("Your \(box.name.capitalized) Box is purchased.\nSwipe to choose a box number.")
            .boxzyFont(16).foregroundStyle(BoxzyTheme.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, compact ? 24 : 32)

        carousel
          .frame(minHeight: typeSize.isAccessibilitySize ? 300 : nil, maxHeight: typeSize.isAccessibilitySize ? 300 : .infinity)
          .padding(.top, compact ? 12 : 20)
          .accessibilityIdentifier("selection.carousel")

        boxCount
          .padding(.top, compact ? 16 : 24)
          .padding(.bottom, compact ? 24 : 32)

        VStack(spacing: 16) {
          Button(action: onChoose) {
            Text("Open Box \(twoDigit(selectedNumber))")
              .boxzyFont(16, weight: .semibold)
          }
          .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 15))
          .accessibilityIdentifier("selection.confirm")

          Button("Open later", action: onCancel)
            .boxzyFont(16)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityIdentifier("selection.later")
          Text("Saved in Collection · Unopened").boxzyFont(13).foregroundStyle(BoxzyTheme.muted)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
      }
      .frame(width: geometry.size.width)
      .frame(minHeight: geometry.size.height)
      }
    }
  }

  private var carousel: some View {
    GeometryReader { proxy in
      let centerX = proxy.size.width / 2
      let pageWidth = min(134.0, proxy.size.width * 0.333)
      let progress = -dragOffset / pageWidth
      ZStack {
        ForEach(-2...2, id: \.self) { position in
          let distance = abs(CGFloat(position) - progress)
          let prominence = max(0, 1 - min(distance, 1))
          let scale = 0.56 + prominence * 0.44
          numberedBox(
            number: wrappedNumber(selectedNumber + position),
            width: min(218, proxy.size.height * 0.80),
            prominence: prominence
          )
          .scaleEffect(scale)
          .position(
            x: centerX + CGFloat(position) * pageWidth + dragOffset,
            y: proxy.size.height / 2
          )
          .opacity(max(0.20, 1 - distance * 0.35))
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
              commitPage(nextNumber, finishingAt: -pageWidth)
            } else if projected > 44 {
              commitPage(previousNumber, finishingAt: pageWidth)
            } else {
              withAnimation(.snappy(duration: 0.30)) { dragOffset = 0 }
            }
          }
      )
    }
    .clipped()
  }

  private func numberedBox(number: Int, width: CGFloat, prominence: CGFloat) -> some View {
    ZStack(alignment: .bottom) {

      Image(box.imageName)
        .resizable()
        .scaledToFit()
        .frame(width: width, height: width * 1.10)
        .offset(y: -width * 0.19)
        .brightness(-0.16 * (1 - prominence))
        .saturation(0.72 + prominence * 0.28)

    }
    .frame(width: width, height: width * 1.30)
    .accessibilityHidden(true)
  }

  private var boxCount: some View {
    HStack(spacing: 8) {
      Text("BOX")
      Text(twoDigit(selectedNumber)).foregroundStyle(BoxzyTheme.blue)
      Text("OF 24")
    }
    .boxzyFont(17, weight: .semibold)
    .tracking(3.2)
    .foregroundStyle(BoxzyTheme.muted)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Box \(twoDigit(selectedNumber)) of 24")
    .accessibilityIdentifier("selection.count")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: selectedNumber = nextNumber
      case .decrement: selectedNumber = previousNumber
      @unknown default: break
      }
    }
  }

  private var previousNumber: Int { selectedNumber == 1 ? 24 : selectedNumber - 1 }
  private var nextNumber: Int { selectedNumber == 24 ? 1 : selectedNumber + 1 }

  private func wrappedNumber(_ number: Int) -> Int {
    ((number - 1 + 24) % 24) + 1
  }

  private func commitPage(_ number: Int, finishingAt offset: CGFloat) {
    withAnimation(.easeOut(duration: 0.16)) { dragOffset = offset }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        selectedNumber = number
        dragOffset = 0
      }
      UISelectionFeedbackGenerator().selectionChanged()
      AudioServicesPlaySystemSound(1104)
    }
  }
}

private struct LockedBoxView: View {
  let box: MysteryBox
  let boxNumber: Int
  let balance: Double
  let onBack: () -> Void
  let onStart: () -> Void
  let onChooseAnother: () -> Void

  @State private var floating = false
  @State private var breathing = false

  var body: some View {
    VStack(spacing: 0) {
      PurchaseTopBar(balance: balance, onBack: onBack)
      VStack(spacing: 0) {
        Text("SELECTION LOCKED")
          .font(.caption.weight(.bold))
          .tracking(3.4)
          .foregroundStyle(BoxzyTheme.blue)
          .padding(.top, 44)
        Text("Box \(twoDigit(boxNumber)) is yours.")
          .boxzyFont(40, weight: .bold)
          .padding(.top, 12)
        Text("Ready to reveal what’s sealed inside?")
          .font(.body)
          .foregroundStyle(BoxzyTheme.muted)
          .padding(.top, 10)

        ZStack(alignment: .bottom) {
          StageGlowRing(intensity: breathing ? 0.66 : 1)
            .frame(width: 316, height: 72)
            .scaleEffect(breathing ? 1.10 : 0.95)
            .offset(y: -6)

          Image(box.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 278, height: 278)
            .offset(y: floating ? -48 : -37)
            .shadow(color: BoxzyTheme.blue.opacity(0.55), radius: 30)
        }
        .frame(height: 374)
        .padding(.top, 12)

        Spacer()

        Button(action: onStart) {
          Text("OPEN BOX")
            .font(.headline)
            .tracking(0.8)
        }
        .buttonStyle(BoxzyPrimaryButtonStyle())
        .accessibilityHint("Stops the lock sound and begins opening Box \(twoDigit(boxNumber))")

        Button("Choose another box", action: onChooseAnother)
          .font(.body)
          .foregroundStyle(BoxzyTheme.blue)
          .padding(.vertical, 18)
      }
      .padding(.horizontal, 40)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
        floating = true
      }
      withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
        breathing = true
      }
    }
  }
}

private struct UnfoldingBoxView: View {
  let box: MysteryBox
  let boxNumber: Int
  @State private var progress: CGFloat = 0
  @State private var light = false

  private func fragmentAsset(_ part: String) -> String {
    switch box.id {
    case "super": "super-unfold-\(part)"
    case "ultra": "ultra-unfold-\(part)"
    default: "box-unfold-\(part)"
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        LinearGradient(
          colors: [.clear, BoxzyTheme.blue.opacity(light ? 0.22 : 0.08), .clear],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(width: 170)
        .blur(radius: 18)

        StageGlowRing(intensity: light ? 1 : 0.66)
          .frame(width: 354, height: 78)
          .position(x: proxy.size.width / 2, y: proxy.size.height * 0.80)

        Image(fragmentAsset("top"))
          .resizable()
          .scaledToFit()
          .frame(width: 246, height: 246)
          .scaleEffect(0.48 + progress * 0.52)
          .rotation3DEffect(
            .degrees(72 * (1 - progress)),
            axis: (x: 1, y: 0, z: 0),
            anchor: .bottom,
            perspective: 0.68
          )
          .offset(y: -220 * progress)
          .opacity(min(1, progress * 7))
          .shadow(color: BoxzyTheme.blue.opacity(0.72), radius: 17)

        Image(fragmentAsset("left"))
          .resizable()
          .scaledToFit()
          .frame(width: 168, height: 220)
          .scaleEffect(0.48 + progress * 0.52)
          .rotation3DEffect(
            .degrees(-76 * (1 - progress)),
            axis: (x: 0, y: 1, z: 0),
            anchor: .trailing,
            perspective: 0.72
          )
          .offset(x: -128 * progress)
          .opacity(min(1, progress * 7))
          .shadow(color: BoxzyTheme.blue.opacity(0.72), radius: 17)

        Image(fragmentAsset("right"))
          .resizable()
          .scaledToFit()
          .frame(width: 168, height: 220)
          .scaleEffect(0.48 + progress * 0.52)
          .rotation3DEffect(
            .degrees(76 * (1 - progress)),
            axis: (x: 0, y: 1, z: 0),
            anchor: .leading,
            perspective: 0.72
          )
          .offset(x: 128 * progress)
          .opacity(min(1, progress * 7))
          .shadow(color: BoxzyTheme.blue.opacity(0.72), radius: 17)

        Image(fragmentAsset("base"))
          .resizable()
          .scaledToFit()
          .frame(width: 276, height: 205)
          .scaleEffect(0.48 + progress * 0.52)
          .rotation3DEffect(
            .degrees(-64 * (1 - progress)),
            axis: (x: 1, y: 0, z: 0),
            anchor: .top,
            perspective: 0.65
          )
          .offset(y: 232 * progress)
          .opacity(min(1, progress * 7))
          .shadow(color: BoxzyTheme.blue.opacity(0.72), radius: 17)

        Image("unfold-card-v2")
          .resizable()
          .scaledToFit()
          .frame(width: 118)
          .scaleEffect(0.76 + progress * 0.24)
          .opacity(max(0, min(1, (progress - 0.28) / 0.30)))
          .shadow(color: BoxzyTheme.blue.opacity(0.70), radius: light ? 28 : 12)

        Image(box.imageName)
          .resizable()
          .scaledToFit()
          .frame(width: 286, height: 286)
          .scaleEffect(1 + progress * 0.04)
          .opacity(max(0, 1 - progress * 6.5))
          .shadow(color: BoxzyTheme.blue.opacity(0.60), radius: 28)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      withAnimation(.timingCurve(0.18, 0.78, 0.22, 1, duration: 1.90)) {
        progress = 1
      }
      withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) { light = true }
    }
  }

}

private struct PrizeRevealTransitionView: View {
  let prize: PullPrize
  let duration: TimeInterval
  @State private var phase: CGFloat = 0

  var body: some View {
    VStack(spacing: 0) {
      Text("REVEAL")
        .font(.caption.weight(.bold))
        .tracking(4)
        .foregroundStyle(BoxzyTheme.blue)
        .padding(.top, 70)
      Spacer()
      ZStack {
        Image(prize.imageName)
          .resizable()
          .scaledToFit()
          .frame(width: 300, height: 430)
          .saturation(phase < 0.58 ? 0 : 1)
          .brightness(phase < 0.58 ? 0.75 : 0)
          .blur(radius: max(0, 24 * (1 - phase)))
          .opacity(0.25 + 0.75 * phase)
          .scaleEffect(1.08 - 0.08 * phase)

        RoundedRectangle(cornerRadius: 40)
          .fill(Color.white.opacity(max(0, 0.88 - phase * 1.1)))
          .frame(width: 260, height: 390)
          .blur(radius: 24)
      }
      .shadow(color: BoxzyTheme.blue.opacity(0.58), radius: 42)
      Spacer()
      Text("Bringing your pull into focus")
        .font(.body)
        .foregroundStyle(BoxzyTheme.muted)
        .padding(.bottom, 58)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: duration)) { phase = 1 }
    }
  }
}

private struct LoopingResultBackgroundView: View {
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var playback = LoopingResultBackgroundPlayer()

  var body: some View {
    Group {
      if let player = playback.player {
        OpeningCinematicSurface(player: player)
          .allowsHitTesting(false)
      } else {
        Color.black
      }
    }
    .onAppear {
      playback.play()
    }
    .onDisappear {
      playback.stop()
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active {
        playback.resume()
      } else {
        playback.pause()
      }
    }
    .accessibilityHidden(true)
  }
}

private final class LoopingResultBackgroundPlayer: ObservableObject {
  @Published private(set) var player: AVQueuePlayer?
  private var looper: AVPlayerLooper?

  func play() {
    if let player {
      player.play()
      return
    }

    guard let url = Bundle.main.url(forResource: "result-background", withExtension: "mp4") else {
      assertionFailure("Missing bundled video: result-background.mp4")
      return
    }

    let item = AVPlayerItem(url: url)
    let queue = AVQueuePlayer()
    queue.isMuted = true
    looper = AVPlayerLooper(player: queue, templateItem: item)
    player = queue
    queue.play()
  }

  func pause() {
    player?.pause()
  }

  func resume() {
    player?.play()
  }

  func stop() {
    player?.pause()
    looper?.disableLooping()
    looper = nil
    player = nil
  }
}

private struct PrizeResultView: View {
  let prize: PullPrize
  @Environment(\.dynamicTypeSize) private var typeSize
  let boxPrice: Int
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let onKeep: () -> Void
  let onSell: () -> Void
  let onOpenAnother: () -> Void

  var body: some View {
    ZStack {
      Group {
        if reduceMotion { Image("reveal-static").resizable().scaledToFill() }
        else { LoopingResultBackgroundView() }
      }.ignoresSafeArea()

      LinearGradient(
        colors: [
          Color.black.opacity(0.58),
          Color.black.opacity(0.30),
          Color.black.opacity(0.48),
          Color.black.opacity(0.82),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      .allowsHitTesting(false)

      GeometryReader { proxy in
        BoxzyAdaptiveScroll(enabled: typeSize.isAccessibilitySize) {
        VStack(spacing: 0) {
          Text("YOU PULLED")
            .font(.caption.weight(.bold))
            .tracking(3.5)
            .foregroundStyle(BoxzyTheme.goldLight)
            .padding(.top, max(32, proxy.size.height * 0.042))

          Text(prize.name)
            .boxzyFont(28, weight: .bold)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.horizontal, 28)
            .padding(.top, 15)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)

          HStack(spacing: 16) {
            Text(prize.value.usd)
              .boxzyFont(31, weight: .bold)

            Rectangle()
              .fill(Color.white.opacity(0.24))
              .frame(width: 1, height: 28)

            Text(prize.rarity)
              .font(.caption.weight(.bold))
              .tracking(2.5)
              .foregroundStyle(BoxzyTheme.goldLight)
              .padding(.horizontal, 18)
              .frame(height: 32)
              .overlay {
                Capsule()
                  .stroke(BoxzyTheme.goldLight.opacity(0.88), lineWidth: 1)
              }
          }
          .padding(.top, 16)

          Image(prize.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 310, maxHeight: min(390, proxy.size.height * 0.43))
            .shadow(color: Color.black.opacity(0.55), radius: 22, y: 14)

            .frame(height: typeSize.isAccessibilitySize ? 240 : min(400, proxy.size.height * 0.44))
            .padding(.top, 4)

          Spacer(minLength: 0)

          VStack(spacing: 12) {
            Button("Sell for " + (Double(prize.value) * 0.9).currency, action: onSell)
              .buttonStyle(ResultActionButtonStyle(primary: true))

            Button("Open again · " + boxPrice.usd, action: onOpenAnother)
              .buttonStyle(ResultActionButtonStyle(primary: false))
              .accessibilityHint("Keeps this prize in your collection, then starts another purchase")

            Button("Keep in my collection", action: onKeep)
              .boxzyFont(15, weight: .regular)
              .foregroundStyle(.white)
              .frame(minHeight: 44)
          }
          .padding(.horizontal, 24)
          .padding(.top, 36)
          .padding(.bottom, 10)
          .background {
            LinearGradient(
              colors: [.clear, Color.black.opacity(0.84), Color.black.opacity(0.96)],
              startPoint: .top,
              endPoint: .bottom
            )
            .padding(.top, -74)
            .ignoresSafeArea(edges: .bottom)
          }
        }.frame(minHeight: proxy.size.height)
        }
      }
    }
  }
}

private struct StageGlowRing: View {
  let intensity: CGFloat
  @State private var radiating = false

  var body: some View {
    ZStack {
      Ellipse()
        .fill(
          RadialGradient(
            colors: [
              Color.white.opacity(0.16 * intensity),
              BoxzyTheme.cyan.opacity(0.26 * intensity),
              BoxzyTheme.violet.opacity(0.24 * intensity),
              .clear
            ],
            center: .center,
            startRadius: 1,
            endRadius: 150
          )
        )
        .blur(radius: 12)

      Ellipse()
        .stroke(
          LinearGradient(
            colors: [BoxzyTheme.cyan.opacity(0.36 * intensity), BoxzyTheme.violet.opacity(0.42 * intensity)],
            startPoint: .leading,
            endPoint: .trailing
          ),
          lineWidth: 15
        )
        .blur(radius: 16)
        .scaleEffect(radiating ? 1.18 : 0.92)
        .opacity(radiating ? 0.08 : 0.72)

      Ellipse()
        .stroke(
          LinearGradient(
            colors: [BoxzyTheme.cyan.opacity(0.48 * intensity), BoxzyTheme.violet.opacity(0.52 * intensity)],
            startPoint: .leading,
            endPoint: .trailing
          ),
          lineWidth: 5
        )
        .blur(radius: 7)
        .scaleEffect(radiating ? 1.07 : 0.98)

      Ellipse()
        .stroke(
          LinearGradient(
            colors: [
              BoxzyTheme.cyan.opacity(0.98 * intensity),
              BoxzyTheme.blue.opacity(0.88 * intensity),
              BoxzyTheme.violet.opacity(0.96 * intensity)
            ],
            startPoint: .leading,
            endPoint: .trailing
          ),
          lineWidth: 1.8
        )
        .shadow(color: Color.white.opacity(0.52 * intensity), radius: 3)
        .shadow(color: BoxzyTheme.violet.opacity(0.82 * intensity), radius: 14)
    }
    .accessibilityHidden(true)
    .onAppear {
      withAnimation(.easeOut(duration: 1.45).repeatForever(autoreverses: false)) {
        radiating = true
      }
    }
  }
}

private struct PostSaleUpsellView: View {
  let box: MysteryBox
  let credit: Double
  let onOpenAgain: () -> Void
  let onMaybeLater: () -> Void
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        Image(systemName: "checkmark").boxzyFont(28, weight: .medium)
          .foregroundStyle(BoxzyTheme.gold).frame(width: 64, height: 64)
          .overlay(Circle().stroke(BoxzyTheme.gold, lineWidth: 1.5)).padding(.top, 36)
        Text("SOLD").boxzyFont(17, weight: .semibold).tracking(2).padding(.top, 16)
        Text("+\(credit.currency)").boxzyFont(36, weight: .bold).padding(.top, 12)
        Text("Added to your BOXZY balance").boxzyFont(15).foregroundStyle(BoxzyTheme.muted).padding(.top, 8)
        Image(box.imageName).resizable().scaledToFit().frame(width: 160, height: 180).padding(.top, 28)
        Text("\(box.name.capitalized) Box").boxzyFont(20, weight: .semibold).padding(.top, 12)
        Text(box.price.usd).boxzyFont(17).foregroundStyle(BoxzyTheme.muted).padding(.top, 4)
        VStack(spacing: 12) {
          Button("Done", action: onMaybeLater).buttonStyle(BoxzyPrimaryButtonStyle())
            .accessibilityIdentifier("sale.done")
          Button("Open again · \(box.price.usd)", action: onOpenAgain).buttonStyle(BoxzySecondaryButtonStyle())
            .accessibilityIdentifier("sale.again")
        }.padding(.top, 24)
      }.padding(.horizontal, 24).padding(.bottom, 24).frame(maxWidth: .infinity)
    }.accessibilityElement(children: .contain)
  }
}

private struct SameBoxUpsellHero: View {
  let box: MysteryBox
  @State private var floating = false

  var body: some View {
    ZStack(alignment: .bottom) {
      Ellipse()
        .fill(
          RadialGradient(
            colors: [
              BoxzyTheme.gold.opacity(0.30),
              BoxzyTheme.goldDeep.opacity(0.12),
              .clear
            ],
            center: .center,
            startRadius: 5,
            endRadius: 145
          )
        )
        .frame(width: 310, height: 82)
        .blur(radius: 8)
        .offset(y: 3)

      Ellipse()
        .stroke(BoxzyTheme.goldLight.opacity(0.72), lineWidth: 1.5)
        .frame(width: 292, height: 66)
        .shadow(color: BoxzyTheme.gold.opacity(0.50), radius: 12)

      Image(box.imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 270, height: 270)
        .offset(y: floating ? -36 : -26)
        .shadow(color: BoxzyTheme.gold.opacity(0.23), radius: 28, y: 10)
    }
    .onAppear {
      withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
        floating = true
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(box.name.capitalized) Box")
  }
}

struct InstantSellOfferView: View {
  let prize: PullPrize
  let isSubmitting: Bool
  let onSell: () -> Void
  let onKeep: () -> Void

  private var marketValue: Double { Double(prize.value) }
  private var credit: Double { marketValue * 0.90 }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Instant sell offer")
          .font(.title2.bold())

        Text("Sell for instant BOXZY account credit.")
          .font(.subheadline)
          .foregroundStyle(BoxzyTheme.muted)
          .lineSpacing(3)
          .padding(.top, 8)

        productCard
          .padding(.top, 20)

        offerCard
          .padding(.top, 14)

        Text("\(credit.currency) will be added to your BOXZY balance immediately.")
          .font(.footnote)
          .foregroundStyle(BoxzyTheme.muted)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 8)
          .padding(.top, 12)

        Button(action: onSell) {
          HStack(spacing: 9) {
            if isSubmitting {
              ProgressView()
                .tint(.white)
            }
            Text(isSubmitting ? "Processing sale…" : "Sell for \(credit.currency)")
              .font(.headline)
          }
        }
        .buttonStyle(BoxzyPrimaryButtonStyle(height: 52, cornerRadius: 15))
        .disabled(isSubmitting)
        .padding(.top, 18)

        Button(action: onKeep) {
          Text("Keep in collection")
            .font(.body)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .padding(.top, 10)
        .padding(.bottom, 18)
      }
      .padding(.horizontal, 22)
      .padding(.top, 42)
    }
    .background(BoxzyTheme.background.ignoresSafeArea())
    .accessibilityElement(children: .contain)
  }

  private var productCard: some View {
    HStack(spacing: 14) {
      Image(prize.imageName)
        .resizable()
        .scaledToFit()
        .frame(width: 68, height: 82)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 7) {
        Text(prize.name)
          .font(.headline)
          .lineLimit(2)
          .minimumScaleFactor(0.82)

        Text("\(prize.rarity)  ·  MARKET VALUE \(marketValue.currency)")
          .font(.caption.weight(.bold))
          .tracking(1.0)
          .foregroundStyle(BoxzyTheme.muted)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .frame(height: 112)
    .boxzyCard(cornerRadius: 16)
    .accessibilityElement(children: .combine)
  }

  private var offerCard: some View {
    VStack(spacing: 13) {
      offerRow("Market value", value: marketValue.currency)
      offerRow("Instant buyback", value: "90%")

      Divider()
        .overlay(Color.white.opacity(0.09))

      HStack {
        Text("You receive")
          .font(.headline)

        Spacer()

        Text(credit.currency)
          .font(.title2.bold())
          .foregroundStyle(BoxzyTheme.gold)
      }
    }
    .padding(16)

    .accessibilityElement(children: .combine)
  }

  private func offerRow(_ label: String, value: String) -> some View {
    HStack {
      Text(label)
        .foregroundStyle(BoxzyTheme.muted)
      Spacer()
      Text(value)
        .fontWeight(.semibold)
    }
    .font(.body)
  }
}

struct SellOfferPresentation<Content: View>: View {
  let isSubmitting: Bool
  let onDismiss: () -> Void
  @ViewBuilder let content: () -> Content

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottom) {
        Color.black.opacity(0.62)
          .ignoresSafeArea()
          .contentShape(Rectangle())
          .onTapGesture {
            guard !isSubmitting else { return }
            onDismiss()
          }

        content()
          .frame(height: proxy.size.height * 0.69 + proxy.safeAreaInsets.bottom)
          .clipShape(sheetShape)
          .overlay(alignment: .top) {
            Capsule()
              .fill(Color.white.opacity(0.30))
              .frame(width: 56, height: 5)
              .padding(.top, 12)
          }
          .overlay {
            sheetShape
              .stroke(BoxzyTheme.stroke, lineWidth: 1)
          }
          .transition(.move(edge: .bottom))
      }
      .ignoresSafeArea(edges: .bottom)
    }
  }

  private var sheetShape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      topLeadingRadius: 30,
      bottomLeadingRadius: 0,
      bottomTrailingRadius: 0,
      topTrailingRadius: 30,
      style: .continuous
    )
  }
}

private struct ResultActionButtonStyle: ButtonStyle {
  let primary: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .boxzyFont(16, weight: .semibold)
      .padding(.horizontal, 16).padding(.vertical, 12)
      .foregroundStyle(primary ? BoxzyTheme.background : Color.white)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 52)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(
            primary
              ? AnyShapeStyle(BoxzyTheme.primaryGradient)
              : AnyShapeStyle(BoxzyTheme.surface.opacity(0.65))
          )
      }
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(primary ? Color.clear : Color(white: 0.6), lineWidth: primary ? 0.5 : 1.25)
      }

      .scaleEffect(configuration.isPressed ? 0.98 : 1)
  }
}

private enum InstantSaleError: Error {
  case rejected
}

private struct FlowToast: Identifiable, Equatable {
  enum Kind { case info, error }
  let id = UUID()
  let message: String
  let kind: Kind
}

private struct FlowToastView: View {
  let toast: FlowToast

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: toast.kind == .error ? "xmark" : "info")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(.white)
        .frame(width: 30, height: 30)
        .background(
          toast.kind == .error ? Color.red : BoxzyTheme.blue,
          in: Circle()
        )

      Text(toast.message)
        .font(.subheadline.weight(.semibold))

      Spacer(minLength: 2)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 14)
    .frame(maxWidth: 340)
    .frame(minHeight: 58)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(
          toast.kind == .error ? Color.red.opacity(0.86) : BoxzyTheme.blue.opacity(0.76),
          lineWidth: 1
        )
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 24)
    .padding(.top, 10)
  }
}

private func twoDigit(_ number: Int) -> String {
  String(format: "%02d", number)
}

extension Double {
  fileprivate var currency: String {
    String(format: "$%.2f", self)
  }
}

struct PurchaseFlowView_Previews: PreviewProvider {
  static var previews: some View {
    PurchaseFlowView(
      box: MysteryBox.samples[1],
      isAuthenticated: .constant(true),
      balance: .constant(100)
    )
    .frame(width: 402, height: 874)
  }
}
