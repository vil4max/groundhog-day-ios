import UIKit

@MainActor
final class FeedbackService {
    enum Event: Sendable {
        case rowSettled
        case revealCompleted
        case saved
        case toggle
        case warning
    }

    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    init() {
        prepareGenerators()
    }

    func play(_ event: Event) {
        AppLog.feedback.debug("Feedback event: \(String(describing: event), privacy: .public)")
        switch event {
        case .rowSettled:
            mediumImpact.impactOccurred()
        case .revealCompleted:
            notification.notificationOccurred(.success)
        case .saved:
            notification.notificationOccurred(.success)
        case .toggle:
            selection.selectionChanged()
        case .warning:
            notification.notificationOccurred(.warning)
        }
    }

    private func prepareGenerators() {
        mediumImpact.prepare()
        notification.prepare()
        selection.prepare()
    }
}
