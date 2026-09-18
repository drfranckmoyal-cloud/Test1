import Foundation
import Network

/// Surveille la connexion. Le dossier demande une chose simple : quand le
/// réseau tombe, la séance se met en pause proprement, elle ne bricole pas.
@MainActor
final class NetworkMonitor: ObservableObject {

    @Published private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.franckmoyal.Shuo.network")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
