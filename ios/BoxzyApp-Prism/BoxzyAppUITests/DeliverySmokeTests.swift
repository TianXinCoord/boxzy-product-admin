import XCTest

final class DeliverySmokeTests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws { continueAfterFailure = false }
    private func launch(account: Bool = false, balance: String = "304", box: String = "starter", authenticated: Bool = true) {
        app = XCUIApplication()
        app.launchArguments = ["-boxzy.isAuthenticated", authenticated ? "YES" : "NO", "-boxzy.balance", balance,
            "-boxzy.didSeedAccountDemoData", "YES", "-boxzy.selectedBoxID", box, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if account { app.launchArguments += ["-BoxzyAccount"] }
        app.launch()
    }
    private func shot(_ name: String) {
        Thread.sleep(forTimeInterval: 0.6)
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    private func amount(_ value: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts["funds.amount"].waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(app.staticTexts["funds.amount"].label, "Amount $\(value)", file: file, line: line)
    }
    func testNavigationAndVisiblePurchase() {
        launch()
        XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["home.buy"].isHittable)
        shot("01-home")
        app.buttons["Collection"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Vault'")).firstMatch.waitForExistence(timeout: 5))
        shot("02-collection")
        app.buttons["Rankings"].tap()
        XCTAssertTrue(app.staticTexts["Rankings"].waitForExistence(timeout: 5))
        app.buttons["Account"].tap()
        XCTAssertTrue(app.buttons["Deposit"].waitForExistence(timeout: 5))
    }
    func testHomeFitsWithoutVerticalScrolling() {
        launch(balance: "450")
        let buy = app.buttons["home.buy"]
        XCTAssertTrue(buy.waitForExistence(timeout: 8))
        let title = app.staticTexts["home.title"]
        let initialTitle = title.frame
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'home.prize.'"))
        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(app.scrollViews.count, 0)
        for card in cards.allElementsBoundByIndex {
            XCTAssertTrue(card.isHittable)
            XCTAssertLessThanOrEqual(card.frame.maxY, buy.frame.minY - 28)
            XCTAssertGreaterThanOrEqual(card.frame.minX, 0)
            XCTAssertLessThanOrEqual(card.frame.maxX, app.frame.maxX)
        }
        XCTAssertLessThan(buy.frame.maxY, app.buttons["Boxes"].frame.minY)
        shot("09-home-no-scroll")
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.64))
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        XCTAssertEqual(title.frame.minY, initialTitle.minY, accuracy: 1)
        app.buttons["home.view-all"].tap()
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))
    }
    func testSpaciousSelectionForAllBoxTypes() {
        for (box, startingBalance) in [("starter", "450"), ("super", "450"), ("elite", "450"), ("ultra", "450")] {
            launch(balance: startingBalance, box: box)
            XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 8))
            app.buttons["home.buy"].tap() // Original local demo purchase, no backend.
            let confirm = app.buttons["selection.confirm"]
            let later = app.buttons["selection.later"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            XCTAssertEqual(confirm.label, "Open Box 07")
            XCTAssertEqual(app.scrollViews.count, 0)
            XCTAssertTrue(confirm.isHittable)
            XCTAssertTrue(later.isHittable)
            XCTAssertLessThan(confirm.frame.maxY, later.frame.minY)
            XCTAssertLessThan(later.frame.maxY, app.frame.maxY - 20)
            XCTAssertTrue(app.staticTexts["Ready to open"].exists)
            shot("selection-\(box)")
            if box == "starter" {
                let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.50))
                from.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.50)))
                XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier == 'selection.confirm' AND label == 'Open Box 08'")).firstMatch.waitForExistence(timeout: 3))
            }
            later.tap()
            XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 5))
        }
    }
    func testDepositKeypadAndRetryPreservesAmount() {
        launch(account: true)
        app.buttons["Deposit"].tap()
        amount("100.00")
        XCTAssertEqual(app.staticTexts["funds.balance"].label, "$304.00")
        app.buttons["funds.preset.250"].tap()
        amount("250.00")
        for key in ["1","2","3","delete","0"] { app.buttons["funds.key.\(key)"].tap() }
        amount("120.00")
        shot("03-deposit-keypad")
        XCTAssertTrue(app.buttons["funds.submit"].isEnabled)
        app.buttons["funds.submit"].tap() // Supplied offline mock, no payment API.
        XCTAssertTrue(app.staticTexts["Payment failed"].waitForExistence(timeout: 8))
        shot("audit-deposit-status")
        app.buttons["TRY AGAIN"].tap()
        amount("120.00")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Deposit"].waitForExistence(timeout: 5))
    }
    func testWithdrawalMaximumDecimalAndReview() {
        launch(account: true)
        app.buttons["Withdraw"].tap()
        amount("100.00")
        XCTAssertFalse(app.buttons["funds.preset.500"].isEnabled)
        app.buttons["funds.max"].tap()
        amount("304.00")
        for key in ["6","decimal","2","5","9"] { app.buttons["funds.key.\(key)"].tap() }
        amount("6.25") // Extra decimal digit rejected.
        XCTAssertTrue(app.buttons["funds.submit"].isEnabled)
        shot("04-withdraw-keypad")
        app.buttons["funds.submit"].tap()
        XCTAssertTrue(app.staticTexts["Review withdrawal"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["$5.00"].exists)
        shot("05-withdraw-review") // Stop before confirmation.
    }
    func testWithdrawalValidation() {
        launch(account: true)
        app.buttons["Withdraw"].tap()
        XCTAssertTrue(app.buttons["funds.key.5"].waitForExistence(timeout: 5))
        app.buttons["funds.key.5"].tap()
        XCTAssertFalse(app.buttons["funds.submit"].isEnabled)
        app.buttons["funds.key.delete"].tap()
        for _ in 0..<3 { app.buttons["funds.key.9"].tap() }
        amount("999.00")
        XCTAssertFalse(app.buttons["funds.submit"].isEnabled)
        shot("06-withdraw-invalid")
    }
    func testPurchaseTopupUsesActualShortfall() {
        launch(balance: "20", box: "ultra")
        XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 8))
        app.buttons["home.buy"].tap()
        amount("80.00")
        app.buttons["funds.preset.25"].tap()
        XCTAssertFalse(app.buttons["funds.submit"].isEnabled)
        app.buttons["funds.preset.250"].tap()
        XCTAssertTrue(app.buttons["funds.submit"].isEnabled)
        shot("07-purchase-topup") // No mock purchase completed.
    }
    func testWelcomeRemainsRealEntry() {
        launch(authenticated: false)
        XCTAssertTrue(app.buttons["Continue with Google"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["funds.submit"].exists)
        shot("08-welcome")
    }
    func testUpdatedDetailsNavigation() {
        launch(box: "super")
        app.buttons["home.view-all"].tap()
        XCTAssertTrue(app.buttons["details.buy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Elite"].exists)
        shot("updated-details")
        app.buttons["Close box details"].tap()
        XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 5))
        app.buttons["home.view-all"].tap()
        app.buttons["details.buy"].tap()
        XCTAssertTrue(app.buttons["selection.confirm"].waitForExistence(timeout: 5))
    }
    func testUpdatedScreenCoverage() {
        let cases: [(String, [String], String)] = [
            ("product", ["-BoxzyProductPreview"], "Product details"),
            ("unopened", ["-BoxzyCollection", "-BoxzyUnopened", "-boxzy.poolUpdating.super", "YES"], "New prizes on the way. Open once the update is complete."),
            ("vault", ["-BoxzyCollection"], "Vault"),
            ("shipped", ["-BoxzyCollection", "-BoxzyShipped", "-BoxzyTrackingAvailable", "-BoxzyShippedDemo"], "Tracking number"),
            ("item", ["-BoxzyCollection", "-BoxzyItemPreview"], "Current value"),
            ("shipping", ["-BoxzyCollection", "-BoxzyShippingPreview"], "Tax"),
            ("result", ["-BoxzyPrizeResultPreview"], "YOU PULLED"),
            ("opening-updating", ["-BoxzyOpeningUpdating"], "New prizes on the way."),
            ("opening-failed", ["-BoxzyOpeningFailure"], "Unable to open your box"),
            ("opening-loading", ["-BoxzyOpeningLoading"], "Revealing your prize…")
        ]
        for (name, flags, expected) in cases {
            app = XCUIApplication()
            app.launchArguments = ["-boxzy.isAuthenticated", "YES", "-boxzy.balance", "304", "-boxzy.selectedBoxID", "super", "-boxzy.returnToUnopened", "NO", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + flags
            app.launch()
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", expected)).firstMatch.waitForExistence(timeout: 8), name)
            if name == "unopened" { XCTAssertFalse(app.buttons.matching(identifier: "unopened.open.super").firstMatch.isEnabled) }
            if name == "shipped" { XCTAssertFalse(app.buttons["Copy"].exists) }
            if name == "shipping" { XCTAssertTrue(app.buttons["Pay $12.00 and Ship"].exists) }
            shot("updated-" + name)
        }
    }

    func testEliteRevealAndErrorReturn() {
        launch(balance: "450", box: "elite")
        app.buttons["home.buy"].tap()
        XCTAssertTrue(app.buttons["selection.confirm"].waitForExistence(timeout: 5))
        app.buttons["selection.confirm"].tap()
        XCTAssertTrue(app.staticTexts["YOU PULLED"].waitForExistence(timeout: 8))
        shot("elite-result")
        app.buttons["Keep in my collection"].tap()
        XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments += ["-BoxzyOpeningFailure"]
        app.launch()
        XCTAssertTrue(app.buttons["Back to My Collection"].waitForExistence(timeout: 8))
        app.buttons["Back to My Collection"].tap()
        XCTAssertTrue(app.staticTexts["Your boxes stay here until you open them."].waitForExistence(timeout: 5))
        shot("failure-return-unopened")
    }
    func testAddressAndSellReferenceScreens() {
        launch(account: true)
        app.terminate()
        app.launchArguments += ["-BoxzyEmptyAddresses"]
        app.launch()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Shipping'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Shipping addresses"].waitForExistence(timeout: 5))
        shot("updated-empty-addresses")
        app.terminate()
        app.launchArguments = ["-boxzy.isAuthenticated", "YES", "-boxzy.balance", "304", "-BoxzyCollection", "-BoxzyItemPreview", "-AppleLanguages", "(en)"]
        app.launch()
        let sell = app.buttons["Sell for $62.10"]
        XCTAssertTrue(sell.waitForExistence(timeout: 8))
        sell.tap()
        XCTAssertTrue(app.staticTexts["Instant sell offer"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.8) // Capture the settled presentation, after its transition.
        shot("updated-sell-offer")
    }

    func testApprovedAuditCoverage() {
        let cases: [(String, [String])] = [
            ("post-sale", ["-BoxzyPostSalePreview"]),
            ("account", ["-BoxzyAccount"]),
            ("profile", ["-BoxzyAccount", "-BoxzyProfilePreview"]),
            ("signout", ["-BoxzyAccount", "-BoxzySignOutPreview"]),
            ("delete", ["-BoxzyAccount", "-BoxzyDeleteAccountPreview"]),
            ("addresses", ["-BoxzyAccount", "-BoxzyAddressesPreview"]),
            ("transactions", ["-BoxzyAccount", "-BoxzyTransactionsPreview"]),
            ("support", ["-BoxzyAccount", "-BoxzySupportPreview"]),
            ("rankings", ["-BoxzyRankings"]),
            ("withdraw-requested", ["-BoxzyAccount", "-BoxzyWithdrawalRequestedPreview"]),
            ("withdraw-processing", ["-BoxzyAccount", "-BoxzyWithdrawalProcessingPreview"]),
            ("withdraw-failed", ["-BoxzyAccount", "-BoxzyWithdrawalFailedPreview"])
        ]
        for (name, flags) in cases {
            app = XCUIApplication()
            app.launchArguments = ["-boxzy.isAuthenticated", "YES", "-boxzy.balance", "304", "-boxzy.didSeedAccountDemoData", "YES", "-boxzy.selectedBoxID", "starter", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + flags
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
            shot("audit-" + name)
            if name == "rankings" { app.buttons["How rankings work"].tap(); shot("audit-ranking-rules") }
            if name == "post-sale" {
                XCTAssertTrue(app.buttons["sale.done"].isHittable)
                XCTAssertTrue(app.buttons["sale.again"].isHittable)
                XCTAssertLessThanOrEqual(app.buttons["sale.again"].frame.minY - app.buttons["sale.done"].frame.maxY, 16)
                app.buttons["sale.done"].tap()
                XCTAssertTrue(app.buttons["home.buy"].waitForExistence(timeout: 5))
            }
        }
    }

    func testRemainingModuleCoverage() {
        let cases: [(String, [String], Bool)] = [
            ("guest", ["-BoxzyAccount", "-BoxzyGuestPreview"], true),
            ("phone", ["-BoxzyPhonePreview"], false),
            ("legal", ["-BoxzyLegalPreview"], false),
            ("collection-empty", ["-BoxzyCollection", "-BoxzyEmptyCollection"], true),
            ("addresses-empty", ["-BoxzyAccount", "-BoxzyAddressesPreview", "-BoxzyEmptyAddresses"], true),
            ("address-form", ["-BoxzyAccount", "-BoxzyAddressesPreview", "-BoxzyAddressFormPreview"], true),
            ("transactions-empty", ["-BoxzyAccount", "-BoxzyTransactionsPreview", "-BoxzyEmptyTransactions"], true),
            ("transaction-detail", ["-BoxzyAccount", "-BoxzyTransactionsPreview", "-BoxzyTransactionDetailPreview"], true),
            ("support-topic", ["-BoxzyAccount", "-BoxzySupportPreview", "-BoxzySupportTopic"], true),
            ("support-article", ["-BoxzyAccount", "-BoxzySupportPreview", "-BoxzySupportArticle"], true)
        ]
        for (name, flags, authenticated) in cases {
            app = XCUIApplication()
            app.launchArguments = ["-boxzy.isAuthenticated", authenticated ? "YES" : "NO", "-boxzy.balance", "304", "-boxzy.didSeedAccountDemoData", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + flags
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
            shot("audit-" + name)
        }
    }
    func testLargeTextLayout() {
        for (name, flags) in [("home", [String]()), ("details", ["-BoxzyDetailsPreview"]), ("result", ["-BoxzyPrizeResultPreview"]), ("collection", ["-BoxzyCollection"])] {
            app = XCUIApplication()
            app.launchArguments = ["-boxzy.isAuthenticated", "YES", "-boxzy.balance", "304", "-boxzy.selectedBoxID", "super", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-AppleLanguages", "(en)"] + flags
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
            shot("large-" + name)
            if name == "home" {
                app.swipeUp(); app.swipeUp()
                XCTAssertTrue(app.buttons["home.buy"].isHittable)
                app.buttons["home.buy"].tap()
                XCTAssertTrue(app.buttons["selection.confirm"].waitForExistence(timeout: 5))
                app.swipeUp(); app.swipeUp()
                XCTAssertTrue(app.buttons["selection.later"].isHittable)
                shot("large-selection")
            }
            if name == "result" {
                app.swipeUp(); app.swipeUp()
                XCTAssertTrue(app.buttons["Keep in my collection"].isHittable)
                shot("large-result-actions")
            }
        }
    }

}
