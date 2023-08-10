//
//  ContentView.swift
//  ibeaconprogram
//
//  Created by Chi Ting on 2023/8/8.
//

import SwiftUI
import CoreLocation


import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var beaconManager = BeaconManager()
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: SettingsView(beacons: $beaconManager.beacons, beaconManager: beaconManager)) {
                    Text("設定")
                }
                .padding()
                
                ScrollView {
                    ForEach(beaconManager.beacons, id: \.uuid) { beacon in
                        BeaconRow(beacon: beacon)
                    }
                }
                
                Button(action: {
                    beaconManager.toggleMonitoring()
                }) {
                    Text(beaconManager.isMonitoring ? "暫停" : "搜尋")
                }
                .padding(.top, 20)
            }
            .onAppear {
                beaconManager.setup()
            }
        }
    }
}

struct BeaconRow: View {
    @ObservedObject var beacon: Beacon
    
    var body: some View {
        VStack {
            Text(beacon.information)
            Text(beacon.stateInformation)
        }
        .background(beacon.backgroundColor)
        .padding(.horizontal)
        .padding(.vertical, 5)
        .cornerRadius(8)
    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
