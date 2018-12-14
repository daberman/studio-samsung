//
//  SmartLock.swift
//  SmartTable
//
//  Created by Dan Berman on 12/14/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import Foundation

class SmartLock: NSObject {
    
    static func lock() {
        let _ = BTManager.shared.write("l", to: .lock)
    }
    
    static func unlock() {
        let _ = BTManager.shared.write("u", to: .lock)
    }
}
