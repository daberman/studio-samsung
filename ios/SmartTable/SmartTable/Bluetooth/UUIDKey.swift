//
//  UUIDKey.swift
//  Basic Chat
//
//  Created by Trevor Beaton on 12/3/16.
//  Copyright © 2016 Vanguard Logic LLC. All rights reserved.
//

import CoreBluetooth
//Uart Service uuid


let kBLEService_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
let kBLE_Characteristic_uuid_Tx = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
let kBLE_Characteristic_uuid_Rx = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
let MaxCharacters = 20

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_uuid_Tx = CBUUID(string: kBLE_Characteristic_uuid_Tx)//(Property = Write without response)
let BLE_Characteristic_uuid_Rx = CBUUID(string: kBLE_Characteristic_uuid_Rx)// (Property = Read/Notify)

//let kAdafruitFeather_Hue_UUID = "FBC6F9D3-B50E-01A4-C33B-F2449A145D55" // Dan's iPhone
let kAdafruitFeather_Hue_UUID = "8E39EC79-95D3-E59B-967E-A2BC679BB749" // Dan's iPad
let BLE_Hue_UUID = CBUUID(string: kAdafruitFeather_Hue_UUID)

//let kAdafruitFeather_Lock_UUID = "CCBF604D-00BE-FA04-2A3C-9D85AD13067E" // Dan's iPhone
let kAdafruitFeather_Lock_UUID = "5557679A-13C9-9BE9-DDF6-66C7313DF065" // Dan's iPad
let BLE_Lock_UUID = CBUUID(string: kAdafruitFeather_Lock_UUID)


