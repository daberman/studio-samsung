//
//  HueBulb.swift
//  SmartTable
//
//  Created by Dan Berman on 12/14/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import Foundation

class HueBulb: NSObject {
    
    static func on() {
        let _ = BTManager.shared.write("on", to: .bulb)
    }
    
    static func off() {
        let _ = BTManager.shared.write("off", to: .bulb)
    }
    
    static func brightness(brightness level: UInt8) {
        
        var b = level
        if b > 100 { b = 100 }
        
        var msg = Data("b".utf8)
        msg.append(b)
        
        let _ = BTManager.shared.write(msg, to: .bulb)
    }
    
    static func color(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        
        var r = red
        var g = green
        var b = blue
        
        if r > 255 { r = 255 }
        if g > 255 { g = 255 }
        if b > 255 { b = 255 }
        
        var msg = Data("c".utf8)
        msg.append(r)
        msg.append(g)
        msg.append(b)
        
        let _ = BTManager.shared.write(msg, to: .bulb)
    }
    
    static func rainbowMode(is enabled: Bool) {
        if enabled {
            let _ = BTManager.shared.write("ron", to: .bulb)
        } else {
            let _ = BTManager.shared.write("roff", to: .bulb)
        }
    }
}
