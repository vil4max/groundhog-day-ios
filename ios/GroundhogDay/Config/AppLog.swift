import Foundation
import os

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.vil4max.groundhogday"

    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let countdown = Logger(subsystem: subsystem, category: "countdown")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let feedback = Logger(subsystem: subsystem, category: "feedback")
}
