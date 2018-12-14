//
//  BTManager.swift
//  SmartTable
//
//  Created by Dan Berman on 12/12/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import CoreBluetooth

protocol BTManagerDelegate : AnyObject {
    func btManager(didUpdatePeripherals peripherals: [CBPeripheral])
    func btManager(didUpdateState state: CBManagerState)
}

class BTManager: NSObject {
    
    // MARK: Configuration Constants
    
    let SCAN_TIMEOUT = 1.0
    let SCAN_REPEAT = 4.0
    let SCAN_MAX_DEVICES = 2
    
    enum BTManagerPeripheral {
        case bulb
        case lock
    }
    
    // MARK: Properties
    
    // Create a static instance so it is accessible by all
    static let shared = BTManager()
    
    // Protocol Delegate
    weak var delegate : BTManagerDelegate?
    
    // Array of all peripherals that could be connected to
    var availablePeripherals : [CBPeripheral] {
        get {return unconnectedPeriphs + connectedPeriphs}
    }
    
    var managerStatus : CBManagerState {
        get {return btManager.state}
    }
    
    // Private variables accessible only by the class
    private var btManager : CBCentralManager!
    private var unconnectedPeriphs = [CBPeripheral]()
    private var connectedPeriphs = [CBPeripheral]()
    
    
    private var timeoutTimer : Timer!
    private var repeatTimer : Timer!
    
    private var hueBulb : (CBPeripheral, CBCharacteristic)!
    private var smartLock : (CBPeripheral, CBCharacteristic)!
    
    // MARK: Init
    override init() {
        super.init()
        
        btManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : true])
        
        startScan()
    }
    
    // MARK: Public control functions
    func stop() {
        cancelScan()
        timeoutTimer?.invalidate()
        repeatTimer?.invalidate()
    }
    
    func resume() {
        startScan()
    }
    
    // MARK: Write
    func write(_ msg: String, to destination: BTManagerPeripheral) -> Bool {
        return write(Data(msg.utf8), to: destination)
    }
    func write(_ data: Data, to destination: BTManagerPeripheral) -> Bool {

        var destPeripheral : CBPeripheral
        var txCharacteristic : CBCharacteristic
        
        switch destination {
        case .bulb:
            if let (dest, tx) = hueBulb {
                destPeripheral = dest
                txCharacteristic = tx
            } else { return false }
        case .lock:
            if let (dest, tx) = smartLock {
                destPeripheral = dest
                txCharacteristic = tx
            } else { return false }
        }
        
        destPeripheral.writeValue(data, for: txCharacteristic, type: CBCharacteristicWriteType.withoutResponse)
        
        return true
    }
    
    // MARK: Private Functions
    
    @objc private func startScan() {
        
        guard let btManager = btManager, btManager.state == .poweredOn else {
            print("Scan failed to start")
            return
        }
        
        // Clear list of available peripherals
        unconnectedPeriphs = []
        
        print("Scanning")
        btManager.scanForPeripherals(withServices: [BLEService_UUID],
                                     options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        
        // Set timeout timer
        timeoutTimer?.invalidate()
        repeatTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(timeInterval: SCAN_TIMEOUT, target: self,
                                            selector: #selector(cancelScan), userInfo: nil, repeats: false)
    }
    
    @objc private func cancelScan() {
        
        btManager?.stopScan()
        
        // If we haven't connected to all the peripherals we want to schedule the repeat scan timer
        timeoutTimer?.invalidate()
        repeatTimer?.invalidate()
        if connectedPeriphs.count < SCAN_MAX_DEVICES {
            repeatTimer = Timer.scheduledTimer(timeInterval: SCAN_REPEAT, target: self,
                                               selector: #selector(startScan), userInfo: nil, repeats: false)
        } else { // Schedule a timer to keep calling this in case the count changes (but the disconnect/restart is missed)
            repeatTimer = Timer.scheduledTimer(timeInterval: SCAN_REPEAT, target: self,
                                               selector: #selector(cancelScan), userInfo: nil, repeats: false)
        }
        
        delegate?.btManager(didUpdatePeripherals: availablePeripherals)
        
        print("Scan stopped")
    }
}

// MARK: CBCentralManagerDelegate
extension BTManager : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        stop()
        
        if central.state == .poweredOn {
            startScan()
        }
        
        delegate?.btManager(didUpdateState: central.state)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Guard against unnamed peripherals
        guard let _ = peripheral.name else {
            return
        }
        
        // Check if peripheral already exists in the list of discovered peripherals
        if !unconnectedPeriphs.contains(peripheral) {
            print("Adding to available list")
            unconnectedPeriphs.append(peripheral)
        }
        
        // Check if peripheral is already connected to
        if peripheral.state != .connected {
            print("Connecting")
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("\nSuccessfully connected to \(String(describing: peripheral.name))")
        
        if isDesiredPeripheral(peripheral) {
            connectedPeriphs.append(peripheral)
            if let idx = unconnectedPeriphs.firstIndex(of: peripheral) {
                unconnectedPeriphs.remove(at: idx)
            }
            peripheral.delegate = self
            peripheral.discoverServices([BLEService_UUID])
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        print("\n******************************")
        print("Failed to connect to \(String(describing: peripheral.name))")
        print("\(String(describing: error))")
        print("******************************\n")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        print("\nDisconnected from \(String(describing: peripheral.name))")
        
        if let idx = connectedPeriphs.firstIndex(of: peripheral) {
            connectedPeriphs.remove(at: idx)
            // Stop current scan/cancelScan cycle and start a scan to see if we can pick it back up
            // (or a different peripheral)
            stop()
            startScan()
        }
    }
    
}

// MARK: CBPeripheralDelegate
extension BTManager : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let err = error {
            print("\(String(describing: err))")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found for \(String(describing: peripheral.name))")
            return
        }
        
        print("Discovered services: \(services)")
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let err = error {
            print("\(String(describing: err))")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Discovered characteristics: \(characteristics)")
        
        for characteristic in characteristics {
            if characteristic.uuid == BLE_Characteristic_uuid_Tx && isDesiredPeripheral(peripheral){
                switch CBUUID(nsuuid: peripheral.identifier) {
                case BLE_Hue_UUID:
                    hueBulb = (peripheral, characteristic)
                case BLE_Lock_UUID:
                    smartLock = (peripheral, characteristic)
                default:
                    print("\n*******************")
                    print("Missing assignment for a desired peripheral!")
                    print("*******************\n")
                }
            }
        }
    }
    
    private func isDesiredPeripheral(_ peripheral: CBPeripheral) -> Bool {
        switch CBUUID(nsuuid: peripheral.identifier) {
        case BLE_Hue_UUID, BLE_Lock_UUID: // List all UUIDs here
            return true
        default:
            return false
        }
    }
}
