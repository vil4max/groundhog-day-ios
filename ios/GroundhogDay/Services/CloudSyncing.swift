import Foundation

protocol CloudSyncing: Sendable {
    func push(snapshot: EventSnapshot) async
    func pull() async -> EventSnapshot?
    func startObserving(onChange: @escaping @Sendable () -> Void)
}

struct NoOpCloudSync: CloudSyncing {
    func push(snapshot: EventSnapshot) async {}

    func pull() async -> EventSnapshot? {
        nil
    }

    func startObserving(onChange: @escaping @Sendable () -> Void) {}
}
