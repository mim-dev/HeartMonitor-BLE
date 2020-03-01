//
//  HeartRateMonitorServiceCharacteristicsUtil.swift
//  HeartRateMonitor
//
//  Created by Luther Stanton on 3/1/20.
//  Copyright © 2020 MiM Development. All rights reserved.
//

import Foundation
import CoreBluetooth

struct HeartRateMonitorServiceCharacteristicsUtil {
    
    static let HeartRateMeasurementCharacteristicUUID = CBUUID(data:NSData(bytes:[0x2A, 0x37] as [UInt8], length: 2) as Data)
    
    static let BodySensorLocationCharacteristicUUID = CBUUID(data:NSData(bytes:[0x2A, 0x38] as [UInt8], length: 2) as Data)
    
}
