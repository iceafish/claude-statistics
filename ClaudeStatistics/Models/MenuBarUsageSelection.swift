import Foundation

enum ClaudeAuthMode: Equatable {
    case apiKey
    case oauth
    case unknown
}

struct MenuBarUsageItem: Equatable {
    let providerLabel: String
    let percentText: String
}

enum MenuBarUsageSelection {
    static func items(
        claudeFiveHourPercent: Double?,
        zaiFiveHourPercent: Double?,
        zaiEnabled: Bool
    ) -> [MenuBarUsageItem] {
        [
            item(providerLabel: "C", percent: claudeFiveHourPercent),
            zaiEnabled ? item(providerLabel: "Z", percent: zaiFiveHourPercent) : nil
        ].compactMap { $0 }
    }

    static func compactText(from items: [MenuBarUsageItem]) -> String? {
        guard !items.isEmpty else { return nil }
        return items
            .flatMap { [$0.providerLabel, $0.percentText] }
            .joined(separator: " ")
    }

    private static func item(providerLabel: String, percent: Double?) -> MenuBarUsageItem? {
        guard let percent else { return nil }
        return MenuBarUsageItem(
            providerLabel: providerLabel,
            percentText: "\(Int(percent))%"
        )
    }
}
