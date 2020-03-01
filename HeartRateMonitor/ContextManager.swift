//
//  ContextManager.swift
//  HeartRateMonitor
//
//  Created by Luther Stanton on 3/1/20.
//  Copyright © 2020 MiM Development. All rights reserved.
//

import UIKit
import CoreBluetooth

class ContextManager {
    
    static let shared = ContextManager()
    
    var centralManager: CBCentralManager?
    var selectedPeripheral: CBPeripheral?
    
    
    private init() {
        // NO-OP
    }

}
