import Foundation
import Network

extension NetworkStatus {
    enum InterfaceType {
        case unknown
        case wifi
        case cellular
        case ethernet
        case localhost
    }
}

class NetworkStatus: ObservableObject {
    private let monitor = NWPathMonitor()
    @Published private(set) var interfaceType: InterfaceType?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.interfaceType = self.checkInterfaceType(path)
                print(self.interfaceType!)
            }
        }
    }

    func start(queue: DispatchQueue = DispatchQueue.global()) {
        monitor.start(queue: queue)
    }

    func cancel() {
        monitor.cancel()
    }

    private func checkInterfaceType(_ path: NWPath) -> InterfaceType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.loopback) {
            return .localhost
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}
