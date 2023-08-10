//
//  BeaconManager.swift
//  ibeaconprogram
//
//  Created by Chi Ting on 2023/8/8.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine


class BeaconManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private var locationManager = CLLocationManager()
    
    private var cancellables: Set<AnyCancellable> = []

        
    @Published var beacons: [Beacon] = []
    @Published var isMonitoring = false
    


    
    func addBeacon(with uuid: UUID) {
        if !beacons.contains(where: { $0.uuid == uuid }) {
            let beacon = Beacon(uuid: uuid)
            beacons.append(beacon)
            saveBeacons() // Save beacons whenever a new one is added
            print("已添加 Beacon: \(uuid.uuidString)")
        } else {
            print("該 Beacon 已存在")
        }
    }
    
    func updateBeacon(with rangedBeacon: CLBeacon) {
        if let beacon = self.beacons.first(where: { $0.uuid == rangedBeacon.uuid }) {
            beacon.update(with: rangedBeacon)
            objectWillChange.send()  // Explicitly notify about the change
        }
    }



    func loadBeacons() {
        if let savedUUIDStrings = UserDefaults.standard.array(forKey: "savedBeacons") as? [String] {
            let newBeacons = savedUUIDStrings.compactMap { UUID(uuidString: $0) }.map { Beacon(uuid: $0) }
            for beacon in newBeacons {
                if !beacons.contains(where: { $0.uuid == beacon.uuid }) {
                    beacons.append(beacon)
                }
            }
        }
    }


    private func subscribeToChanges(for beacon: Beacon) {
        beacon.objectWillChange.sink {
            self.objectWillChange.send()
        }.store(in: &cancellables)
    }

    
    func setup() {
        loadBeacons()  // 加載beacons

        locationManager.delegate = self
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            print("Beacon監控是可用的")
            if locationManager.authorizationStatus != .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            }
        }else {
            print("Beacon監控不可用")
        }
    }

    
    func toggleMonitoring() {
        for beacon in beacons {
            let region = CLBeaconRegion(beaconIdentityConstraint: CLBeaconIdentityConstraint(uuid: beacon.uuid), identifier: beacon.uuid.uuidString)
            if isMonitoring {
                locationManager.stopMonitoring(for: region)
                locationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: beacon.uuid))
                beacon.backgroundColor = .white
                beacon.information = "Beacon狀態"
                beacon.stateInformation = "是否在region內?"
            } else {
                locationManager.startMonitoring(for: region)
            }
        }
        isMonitoring.toggle()
        print("監控狀態切換為: \(isMonitoring ? "開始" : "停止")")
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        manager.requestState(for: region)
        print("開始監控: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside {
            if CLLocationManager.isRangingAvailable() {
                manager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID(uuidString: region.identifier)!))
                beacons.first(where: { $0.uuid.uuidString == region.identifier })?.stateInformation = "已在region中"
            } else {
                print("不支援ranging")
            }
        } else {
            manager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID(uuidString: region.identifier)!))
            beacons.first(where: { $0.uuid.uuidString == region.identifier })?.backgroundColor = .white
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if CLLocationManager.isRangingAvailable() {
            print("進入 Beacon Region: \(region.identifier)")
            manager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID(uuidString: region.identifier)!))
        } else {
            print("不支援ranging")
        }
        beacons.first(where: { $0.uuid.uuidString == region.identifier })?.stateInformation = "進入region"
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        manager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID(uuidString: region.identifier)!))
        beacons.first(where: { $0.uuid.uuidString == region.identifier })?.backgroundColor = .white
        beacons.first(where: { $0.uuid.uuidString == region.identifier })?.stateInformation = "離開region"
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons rangedBeacons: [CLBeacon], in region: CLBeaconRegion) {
        for rangedBeacon in rangedBeacons {
            print("在範圍內的 Beacon: \(rangedBeacon.uuid.uuidString)")
            if let beacon = self.beacons.first(where: { $0.uuid == rangedBeacon.uuid }) {
                beacon.update(with: rangedBeacon)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(error.localizedDescription)
    }

    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error.localizedDescription)
    }
    
    //save
    func saveBeacons() {
        let uuidStrings = beacons.map { $0.uuid.uuidString }
        UserDefaults.standard.set(uuidStrings, forKey: "savedBeacons")
    }



}

class Beacon: Identifiable, ObservableObject {
    var uuid: UUID
    @Published var information = "Beacon狀態"
    @Published var stateInformation = "是否在region內?"
    @Published var backgroundColor = Color.white

    init(uuid: UUID) {
        self.uuid = uuid
    }
    
    func update(with beacon: CLBeacon) {
        var proximity = ""
        switch beacon.proximity {
        case .immediate:
            proximity = "非常近"
        case .near:
            proximity = "近"
        case .far:
            proximity = "遠"
        default:
            proximity = "未知"
        }
        self.information = "接近性: \(proximity)\n估計距離: \(String(format: "%.2f", beacon.accuracy)) 米\nRSSI: \(beacon.rssi)"
        self.backgroundColor = .red
    }
}

