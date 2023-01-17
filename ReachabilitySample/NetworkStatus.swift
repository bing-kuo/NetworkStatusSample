//
//  NetworkStatus.swift
//  ReachabilitySample
//
//  Created by Bing Guo on 2023/1/15.
//

import Foundation
import SystemConfiguration

class NetworkStatus {
    static let shared = NetworkStatus()

    private(set) var isReachable: Bool = false
    private var isRunning = false
    private var reachability: SCNetworkReachability?
    private let reachabilitySerialQueue = DispatchQueue(label: "reachability_queue")

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
                print("SCNetworkReachability get flags")
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
    }

    private func setFlags(_ flags: SCNetworkReachabilityFlags) {
        isReachable = flags.contains(.reachable)

        if isReachable {
            NotificationCenter.default.post(Notification(name: Notification.Name.networkReachable))
        } else {
            NotificationCenter.default.post(Notification(name: Notification.Name.networkUnreachable))
        }
    }
}

extension Notification.Name {
    static let networkReachable = Notification.Name("networkReachable")
    static let networkUnreachable = Notification.Name("networkUnreachable")
}
