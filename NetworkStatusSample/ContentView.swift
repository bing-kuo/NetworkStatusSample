//
//  ContentView.swift
//  NetworkStatusSample
//
//  Created by Bing Guo on 2023/1/15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var networkStatus: NetworkStatus

    var body: some View {
        VStack(spacing: 16) {
            itemView(title: "WiFi", image: "wifi", type: .wifi)

            itemView(title: "Cellular", image: "antenna.radiowaves.left.and.right", type: .cellular)

            itemView(title: "Localhost", image: "house", type: .localhost)

            itemView(title: "Ethernet", image: "app.connected.to.app.below.fill", type: .ethernet)

            itemView(title: "No Conncect", image: "xmark.octagon", type: .unknown)
        }
    }

    @ViewBuilder
    func itemView(title: String, image: String, type: NetworkStatus.InterfaceType) -> some View {
        let isSelected = (networkStatus.interfaceType == type)
        HStack {
            Image(systemName: image)
                .font(.title2.weight(.bold))
                .foregroundColor(isSelected ? .accentColor : .gray)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(isSelected ? .accentColor : .gray)
        }
        .scaleEffect(isSelected ? 1.2 : 1)
        .animation(.default, value: isSelected)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NetworkStatus())
    }
}
