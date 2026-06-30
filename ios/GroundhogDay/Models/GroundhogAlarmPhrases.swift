import Foundation

enum GroundhogAlarmPhrases {
    static let localizationKey = "push.alarm.title"

    static var title: String {
        String(localized: String.LocalizationValue(localizationKey))
    }
}
