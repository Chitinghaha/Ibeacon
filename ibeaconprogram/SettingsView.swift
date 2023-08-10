//
//  SettingsView.swift
//  ibeaconprogram
//
//  Created by Chi Ting on 2023/8/8.
//

import SwiftUI

struct SettingsView: View {
    @Binding var beacons: [Beacon]
    @State private var inputUUID = ""
    @ObservedObject var beaconManager = BeaconManager()  // 1. 在 SettingsView 中添加 BeaconManager 的屬性。
    
    var body: some View {
        VStack {
            TextField("輸入iBeacon的UUID", text: $inputUUID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("新增") {
                if let uuid = UUID(uuidString: inputUUID) {
                    beaconManager.addBeacon(with: uuid)  // Modify this line.
                    inputUUID = ""
                    // No need to call saveBeacons() here, because it's already called inside addBeacon()
                }
            }
            
            List(beacons) { beacon in
                Text(beacon.uuid.uuidString)
            }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var sampleBeacons = [Beacon]()
    
    static var previews: some View {
        SettingsView(beacons: .constant(sampleBeacons))
    }
}


