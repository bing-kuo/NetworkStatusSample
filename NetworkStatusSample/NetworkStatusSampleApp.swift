//
//  NetworkStatusSampleApp.swift
//  NetworkStatusSample
//
//  Created by Bing Guo on 2023/1/15.
//

import SwiftUI

@main
struct NetworkStatusSampleApp: App {
    let networkStatus = NetworkStatus()

    init() {
        networkStatus.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkStatus)
        }
    }
}
