//
//  ViewController.swift
//  HeartRateMonitor
//
//  Created by Luther Stanton on 2/29/20.
//  Copyright © 2020 MiM Development. All rights reserved.
//

import UIKit
import CoreBluetooth

private struct MonitorViewControllerConstants {
    
    static let HeartRateMeasurementSizeMask: UInt8 = 0x01
    
}

class MonitorViewController: UIViewController {
    
    var centralManager: CBCentralManager?
    var targetService: CBService?
    
    @IBOutlet weak var connectionButton: UIButton!
    
    @IBOutlet weak var heartRateDisplay: UILabel!
    
    @IBOutlet weak var sensorPositionDisplay: UILabel!
    
    @IBAction func connectionButtonTouched(_ sender: Any) {
        
        if let selectedPeripheral = ContextManager.shared.selectedPeripheral {
            if selectedPeripheral.state == .connected {
                connectionButton.isEnabled = false
                centralManager?.cancelPeripheralConnection(selectedPeripheral)
            } else {
                pushToHeartRateMonitorPeripheralSelectionVC()
            }
        } else {
            pushToHeartRateMonitorPeripheralSelectionVC()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Heart Rate Monitor"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let centralManager = ContextManager.shared.centralManager {
            self.centralManager = centralManager
            centralManager.delegate = self
            
            if let selectedPeripheral = ContextManager.shared.selectedPeripheral {
                connectionButton.isEnabled = false
                self.centralManager?.connect(selectedPeripheral, options: nil)
            }
        }
    }
    
    private func pushToHeartRateMonitorPeripheralSelectionVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let selectHeartRateMonitorViewController = storyboard.instantiateViewController(withIdentifier: "SelectHeartRateMonitor")
        
        let backItem = UIBarButtonItem()
        backItem.title = "cancel"
        navigationItem.backBarButtonItem = backItem
        
        navigationController?.pushViewController(selectHeartRateMonitorViewController, animated: true)
    }
    
    func discoverHeartRateMonintorServices() {
        
        if let selectedPeripheral = ContextManager.shared.selectedPeripheral {
            selectedPeripheral.delegate = self
            selectedPeripheral.discoverServices([HeartRateMonitorServiceUtil.ServiceUUID])
        }
    }
    
    func processDiscoveredCharacteristics(targetCharacteristics:[CBCharacteristic]) {
        
        guard let selectedPeripheral = ContextManager.shared.selectedPeripheral else {
            return
        }
        
        for targetCharacterictic in targetCharacteristics {
            
            if targetCharacterictic.properties.contains(.read) {
                selectedPeripheral.readValue(for: targetCharacterictic)
            }
            
            if targetCharacterictic.properties.contains(.notify) {
                selectedPeripheral.setNotifyValue(true, for: targetCharacterictic)
            }
        }
    }
    
    func processBodySensorLocation(characteristic: CBCharacteristic) {
        
        guard characteristic.uuid == HeartRateMonitorServiceCharacteristicsUtil.BodySensorLocationCharacteristicUUID else {
            return
        }
        
        guard let sensorLocationData = characteristic.value else {
            return
        }
        
        var sensorPosition: String
        let sensorLocationValue = sensorLocationData.first ?? 0
        
        switch sensorLocationValue as UInt8 {
        case 0:
            sensorPosition = "Other"
        case 1:
            sensorPosition = "Chest"
        case 2:
            sensorPosition = "Wrist"
        case 3:
            sensorPosition = "Finger"
        case 4:
            sensorPosition = "Hand"
        case 5:
            sensorPosition = "Ear Lobe"
        case 6:
            sensorPosition = "Foot"
        default:
            sensorPosition = "RFU"
        }
        
        if Thread.isMainThread {
            self.sensorPositionDisplay.text = sensorPosition
        } else {
            DispatchQueue.main.async {
                self.sensorPositionDisplay.text = sensorPosition
            }
        }
    }
    
    func processHeartRateMeasurementUpdate(characteristic: CBCharacteristic) {
        
        guard characteristic.uuid == HeartRateMonitorServiceCharacteristicsUtil.HeartRateMeasurementCharacteristicUUID else {
            return
        }
        
        guard let heartRateMeasurementData = (characteristic.value as Data?) else {
            return
        }
        
        let heartRateMeasurementBytes = [UInt8](heartRateMeasurementData)
        
        guard heartRateMeasurementBytes.count > 1 else {
            return
        }
        
        let firstBitValue = heartRateMeasurementBytes[0] & 0x01
        var heartRateMeasurementValue: Int
        
        if firstBitValue == 0 {
            heartRateMeasurementValue =  Int(heartRateMeasurementBytes[1])
        } else {
            guard heartRateMeasurementBytes.count > 2 else {
                return
            }
            heartRateMeasurementValue =  Int(heartRateMeasurementBytes[1] << 8) + Int(heartRateMeasurementBytes[2])
        }
        
        if Thread.isMainThread {
            self.heartRateDisplay.text = String(heartRateMeasurementValue)
        } else {
            DispatchQueue.main.async {
                self.heartRateDisplay.text = String(heartRateMeasurementValue)
            }
        }
    }
}

extension MonitorViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        print("CBPeripheral has reported discovered service(s)")
        
        guard peripheral == ContextManager.shared.selectedPeripheral  else {
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            print(service)
            if service.uuid == HeartRateMonitorServiceUtil.ServiceUUID {
                
                let targetCharacteristics = [HeartRateMonitorServiceCharacteristicsUtil.HeartRateMeasurementCharacteristicUUID,
                                             HeartRateMonitorServiceCharacteristicsUtil.BodySensorLocationCharacteristicUUID]
                
                DispatchQueue.main.async {
                    self.targetService = service
                    peripheral.discoverCharacteristics(targetCharacteristics, for:service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard error == nil else  {
            print("error encountered updating characteristic value.  Error says:[\((error! as NSError).description)]")
            return
        }
        
        if targetService == service {
            
            // print what we see to the console
            if let characterstics = service.characteristics {
                for characterstic in characterstics {
                    print(characterstic)
                }
            }
            
            let discoveredCharacteristicsCount = targetService?.characteristics?.count ?? 0
            
            if discoveredCharacteristicsCount > 0 {
                let targetCharacteristic = targetService!.characteristics!
                DispatchQueue.main.async {
                    self.processDiscoveredCharacteristics(targetCharacteristics: targetCharacteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else  {
            print("error encountered updating characteristic value.  Error says:[\((error! as NSError).description)]")
            return
        }
        
        if characteristic.uuid == HeartRateMonitorServiceCharacteristicsUtil.BodySensorLocationCharacteristicUUID {
            DispatchQueue.main.async {
                self.processBodySensorLocation(characteristic: characteristic)
            }
        } else if characteristic.uuid == HeartRateMonitorServiceCharacteristicsUtil.HeartRateMeasurementCharacteristicUUID {
            DispatchQueue.main.async {
                self.processHeartRateMeasurementUpdate(characteristic: characteristic)
            }
        } else {
            print("unhandled characteristic:\(characteristic)")
        }
    }
}

extension MonitorViewController: CBCentralManagerDelegate {
    
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
        @unknown default:
            print("CBCentralManager has reported state change to '??'")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("CBCentralManager has reported a peripheral connected")
        
        if peripheral == ContextManager.shared.selectedPeripheral {
            
            DispatchQueue.main.async {
                self.connectionButton.setTitle("disconnect", for: .normal)
                self.connectionButton.isEnabled = true
                self.discoverHeartRateMonintorServices()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("CBCentralManager has reported peripheral disconnected")

        DispatchQueue.main.async {
            self.connectionButton.setTitle("connect", for: .normal)
            self.connectionButton.isEnabled = true
            self.heartRateDisplay.text = "--"
            self.sensorPositionDisplay.text = "--"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("CBCentralManager has reported peripheral failed to connect, error:[%@]", ((error as NSError?).debugDescription))
        
        DispatchQueue.main.async {
            // TODO: alert the user to what just happened
            self.connectionButton.isEnabled = true
        }
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        print("CBCentralManager has reported peripheral connection event")
    }
}
