import Foundation

final class ICloudKeyValueSync: CloudSyncing, @unchecked Sendable {
    private let store = NSUbiquitousKeyValueStore.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var observer: NSObjectProtocol?

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func push(snapshot: EventSnapshot) async {
        guard let data = try? encoder.encode(snapshot) else { return }
        store.set(data, forKey: Keys.snapshot)
        store.synchronize()
    }

    func pull() async -> EventSnapshot? {
        guard let data = store.data(forKey: Keys.snapshot) else { return nil }
        return try? decoder.decode(EventSnapshot.self, from: data)
    }

    func startObserving(onChange: @escaping @Sendable () -> Void) {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in
            onChange()
        }
    }

    private enum Keys {
        static let snapshot = "eventSnapshot"
    }
}
