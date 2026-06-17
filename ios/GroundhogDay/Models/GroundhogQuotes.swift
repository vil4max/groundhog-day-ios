import Foundation

enum GroundhogQuotes {
    static let localizationKeys = [
        "countdown.quote.1",
        "countdown.quote.2",
        "countdown.quote.3",
        "countdown.quote.4",
        "countdown.quote.6",
        "countdown.quote.7",
        "countdown.quote.8"
    ]

    static let sessionLocalizationKey: String = {
        localizationKeys.randomElement() ?? localizationKeys[0]
    }()
}
