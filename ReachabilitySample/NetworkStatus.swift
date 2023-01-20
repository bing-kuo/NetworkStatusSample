//
//  NetworkStatus.swift
//  ReachabilitySample
//
//  Created by Bing Guo on 2023/1/15.
//

import Foundation
import SystemConfiguration

extension NetworkStatus {
    enum InterfaceType {
        case unknown
        case wifi
        case cellular
    }
}

class NetworkStatus {
    static let shared = NetworkStatus()

    var isReachable: Bool { flags?.contains(.reachable) ?? false }
    var isWWAN: Bool { flags?.contains(.isWWAN) ?? false }

    private let reachabilitySerialQueue = DispatchQueue(label: "reachability_queue")
    private var flags: SCNetworkReachabilityFlags?
    private var reachability: SCNetworkReachability?
    private var isRunning = false
    private(set) var status: InterfaceType = .unknown {
        didSet {
            NotificationCenter.default.post(name: .networkStatusChanged, object: self)
        }
    }

    private init() {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)

        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else { return }
        reachability = ref
    }

    func start() {
        guard let reachability = reachability, !isRunning else { return }

        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            guard let info = info else { return }
            Unmanaged<NetworkStatus>.fromOpaque(info).takeUnretainedValue().setFlags(flags)
        }

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged<NetworkStatus>.passUnretained(self).toOpaque(),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedReachability = Unmanaged<NetworkStatus>.fromOpaque(info)
                _ = unmanagedReachability.retain()
                return UnsafeRawPointer(unmanagedReachability.toOpaque())
            },
            release: { (info: UnsafeRawPointer) -> Void in
                Unmanaged<NetworkStatus>.fromOpaque(info).release()
            },
            copyDescription: nil
        )

        guard SCNetworkReachabilitySetCallback(reachability, callback, &context) else {
            stop()
            return
        }

        guard SCNetworkReachabilitySetDispatchQueue(reachability, reachabilitySerialQueue) else {
            stop()
            return
        }

        reachabilitySerialQueue.sync { [unowned self] in
            guard let reachability = self.reachability else { return }

            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(reachability, &flags) {
                self.stop()
                return
            }

            self.setFlags(flags)
        }

        isRunning = true
    }

    func stop() {
        defer { isRunning = false }
        guard let reachability = reachability, isRunning else { return }

        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        self.reachability = nil
    }

    private func setFlags(_ flags: SCNetworkReachabilityFlags) {
        self.flags = flags

        guard isReachable else {
            status = .unknown
            return
        }

        #if targetEnvironment(simulator)
            status = .wifi
        #else
            if isReachable && !isWWAN {
                status = .wifi
            } else if isWWAN {
                status = .cellular
            } else {
                status = .unknown
            }
        #endif
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}
