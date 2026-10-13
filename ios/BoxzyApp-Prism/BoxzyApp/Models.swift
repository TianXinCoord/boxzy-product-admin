import SwiftUI

struct MysteryBox: Identifiable, Hashable {
    let id: String
    let name: String
    let price: Int
    let minValue: Int
    let maxValue: Int
    let imageName: String
    let color: Color
}

struct PrizeBoxAvailability: Identifiable, Hashable {
    let boxID: MysteryBox.ID
    let dropChance: String

    var id: MysteryBox.ID { boxID }
}

struct PullPrize: Identifiable {
    let id: String
    let name: String
    let value: Int
    let imageName: String
    let category: String
    let rarity: String
    let availabilities: [PrizeBoxAvailability]

    init(
        id: String? = nil,
        name: String,
        value: Int,
        imageName: String,
        category: String = "SEALED COLLECTIBLE",
        rarity: String = "RARE",
        dropChance: String = "—",
        boxID: MysteryBox.ID = "starter",
        availabilities: [PrizeBoxAvailability] = []
    ) {
        self.id = id ?? name.lowercased().replacingOccurrences(of: " ", with: "-")
        self.name = name
        self.value = value
        self.imageName = imageName
        self.category = category
        self.rarity = rarity
        self.availabilities = availabilities.isEmpty
            ? [.init(boxID: boxID, dropChance: dropChance)]
            : availabilities
    }
}

extension MysteryBox {
    static let samples: [MysteryBox] = [
        .init(id: "starter", name: "STARTER", price: 5, minValue: 20, maxValue: 1175, imageName: "starter-box", color: BoxzyTheme.gold),
        .init(id: "super", name: "SUPER", price: 10, minValue: 45, maxValue: 2250, imageName: "super-box", color: .pink),
        .init(id: "elite", name: "ELITE", price: 20, minValue: 0, maxValue: 0, imageName: "elite-box", color: .purple),
        .init(id: "ultra", name: "ULTRA", price: 100, minValue: 90, maxValue: 4500, imageName: "ultra-box", color: BoxzyTheme.goldLight)
    ]
    var minimumLabel: String { id == "super" ? minValue.usd : "—" }
    var maximumLabel: String { id == "super" ? maxValue.usd : "—" }
}

extension PullPrize {
    var shortName: String {
        switch imageName {
        case "prize-151-bundle": "151 Bundle"
        case "prize-151-etb": "151 Center ETB"
        case "prize-legendary-pack": "Legendary Treasures"
        default: name
        }
    }
    static let samples: [PullPrize] = [
        .init(id: "151-bundle", name: "151 Booster Bundle", value: 69, imageName: "prize-151-bundle", category: "BOOSTER BUNDLE", rarity: "RARE", boxID: "ultra"),
        .init(id: "legendary-treasures", name: "Legendary Treasures Booster Pack", value: 89, imageName: "prize-legendary-pack", category: "BOOSTER PACK", rarity: "RARE", boxID: "super"),
        .init(id: "151-etb", name: "Pokémon Center 151 ETB", value: 150, imageName: "prize-151-etb", category: "ELITE TRAINER BOX", rarity: "EPIC", boxID: "super")
    ]
}

// Local demo adapter. Production must supply pool state and a signed shipping quote.
enum DemoPool {
    static func isUpdating(_ id: String) -> Bool {
        UserDefaults.standard.bool(forKey: "boxzy.poolUpdating." + id)
    }
}
struct ShippingQuote {
    let shippingCents: Int
    let handlingCents: Int
    let taxCents: Int
    var totalCents: Int { shippingCents + handlingCents + taxCents }
    var total: Double { Double(totalCents) / 100 }
    static let sample = ShippingQuote(shippingCents: 900, handlingCents: 200, taxCents: 100)
}

extension Int {
    var usd: String {
        "$" + formatted(.number.grouping(.automatic))
    }
}
