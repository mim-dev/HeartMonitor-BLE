//
//  HeartRateMonitorServiceUtil.swift
//  HeartRateMonitor
//
//  Created by Luther Stanton on 3/1/20.
//  Copyright © 2020 MiM Development. All rights reserved.
//

import Foundation
import CoreBluetooth

struct HeartRateMonitorServiceUtil {
    
    static let ServiceUUID = CBUUID(data:NSData(bytes:[0x18, 0x0D] as [UInt8], length: 2) as Data)
    
}
