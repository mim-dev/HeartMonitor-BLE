//
//  PeripheralConnectViewController.swift
//  HeartRateMonitor
//
//  Created by Luther Stanton on 2/29/20.
//  Copyright © 2020 MiM Development. All rights reserved.
//

import UIKit
import CoreBluetooth

internal struct PeripheralConnectViewControllerConstants {
    static let CellReuseIdentifier = "com.mim-development.mobile.heartratemonitor.discoveredPeripheralCellIdentifier"
}


class PeripheralConnectViewController: UIViewController {
    
    private var advertisingPeripherals = [(adverisedName: String, peripheral:CBPeripheral)]()
    
    @IBOutlet weak var adevrtisingPeripheralTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adevrtisingPeripheralTableView.delegate = self
        adevrtisingPeripheralTableView.dataSource = self
        
        ContextManager.shared.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        self.title = "Peripheral Select"
        self.navigationController?.navigationBar.tintColor = ColorUtil.RoyalPurple
    }
}

extension PeripheralConnectViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let centralManager = ContextManager.shared.centralManager {
            if centralManager.isScanning {
                centralManager.stopScan()
            }
        }
        
        ContextManager.shared.selectedPeripheral = advertisingPeripherals[indexPath.row].peripheral
        
        self.navigationController?.popViewController(animated: true)
    }
}

extension PeripheralConnectViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return advertisingPeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell!
        cell = tableView.dequeueReusableCell(withIdentifier: PeripheralConnectViewControllerConstants.CellReuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: PeripheralConnectViewControllerConstants.CellReuseIdentifier)
        }
        
        cell.textLabel?.text = advertisingPeripherals[indexPath.row].adverisedName
        cell.textLabel?.textColor = ColorUtil.RoyalPurple
        
        return cell
    }
}

extension PeripheralConnectViewController: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        print("CBCentralManager has reported discovery of potential peripheral...")
        
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "-- ?? --"
        advertisingPeripherals.append((advertisedName, peripheral))
        
        adevrtisingPeripheralTableView.reloadData()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("CBCentralManager has reported state change to 'unknown'")
        case .resetting:
            print("CBCentralManager has reported state change to 'resetting'")
        case .unsupported:
            print("CBCentralManager has reported state change to 'unsupported'")
        case .unauthorized:
            print("CBCentralManager has reported state change to 'unauthorized'")
        case .poweredOff:
            print("CBCentralManager has reported state change to 'poweredOff'")
        case .poweredOn:
            print("CBCentralManager has reported state change to 'poweredOn', commencing scan")
            if central == ContextManager.shared.centralManager {
                central.scanForPeripherals(withServices:[HeartRateMonitorServiceUtil.ServiceUUID], options: nil)
            }
        @unknown default:
            print("CBCentralManager has reported state change to '??'")
        }
    }
}
