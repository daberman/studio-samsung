//
//  ViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/7/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate,
CBPeripheralDelegate, HSBColorPickerDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var btTableView: UITableView!
    @IBOutlet weak var btStatusLabel: UILabel!
    @IBOutlet weak var refreshBTButton: UIButton!
    @IBOutlet weak var bulbPowerSwitch: UISwitch!
    @IBOutlet weak var bulbColorPicker: HSBColorPicker!
    
    let SCAN_TIMEOUT = 5.0
    
    var btManager : CBCentralManager!
    var availableBT = [CBPeripheral]()
    var timer = Timer()
    var txCharacteristic : CBCharacteristic!
    var hueBulb : (CBPeripheral, CBCharacteristic)!
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btTableView.delegate = self
        btTableView.dataSource = self
        
        bulbPowerSwitch.isOn = false
        bulbColorPicker.delegate = self
        
        btStatusLabel.text = "Please refresh list"
        
        btManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : true])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelScan()
    }
    
    // MARK: TableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableBT.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "BTPeripheralTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BTPeripheralTableViewCell
            else {
                fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let peripheral = availableBT[indexPath.row]
        
        cell.peripheralNameLabel.text = peripheral.name
        
        return cell
    }
    
    // Connect to the peripheral the user selects
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let peripheral = availableBT[indexPath.row]
        print("Attempting a connection")
        btStatusLabel.text = "Connecting to \(String(describing: peripheral.name))"
        btManager.connect(peripheral, options: nil)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // nothing to do here since scanning is controlled by button action
    }
    
    // Called when a peripheral is discovered while scanning
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if peripheral.name != nil { // Check periphal has a name
            // Confirm peripheral isn't already in our discovered list
            var newPeripheral = true
            for p in availableBT {
                if p.identifier == peripheral.identifier {
                    newPeripheral = false
                    break
                }
            }
            // Add peripheral to list of available peripherals if it is new
            if newPeripheral {
                self.availableBT.append(peripheral)
                self.btTableView.reloadData()
                print("**********************************")
                print("Found new pheripheral devices with services")
                print("Peripheral name: \(String(describing: peripheral.name))")
                print("Advertisement Data : \(advertisementData)")
                print("UUID: \(peripheral.identifier)")
                print("**********************************\n")
                
                // Auto connect to Hue?
                if peripheral.identifier.uuidString == BLE_Hue_UUID.uuidString {
                    central.connect(peripheral, options: nil)
                }
            }
        }
    }
    
    // Called when successfully connected to a peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connection Successful:")
        print("\(String(describing: peripheral))\n")
        btStatusLabel.text = "Successfully connected to \(String(describing: peripheral.name))"
        
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID])
    }
    
    // Called when a connection attempt fails
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connection failed\n")
        if let error = error {
            print(error.localizedDescription)
        }
        btStatusLabel.text = "Connection attempt to \(String(describing: peripheral.name)) failed"
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("\(String(describing: error))")
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        print("Discovered services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("")
        
        if error != nil {
            print("\(String(describing: error))")
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
//                rxCharacteristic = characteristic
//
//                //Once found, subscribe to the this particular characteristic...
//                peripheral.setNotifyValue(true, for: rxCharacteristic!)
//                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
//                // didUpdateNotificationStateForCharacteristic method will be called automatically
//                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
                hueBulb = (peripheral, characteristic)
            }
            //peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // MARK: HSBColorPickerDelegate
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        var red : CGFloat = 0
        var green : CGFloat = 0
        var blue : CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        print("RGB: \(red) \(green) \(blue)")
    }

    // MARK: Actions
    
    @IBAction func refreshBTPressed(_ sender: Any) {
        availableBT = [] // Clear list
        startScan()
    }
    
    @IBAction func bulbPowerToggled(_ sender: Any) {
        let (peripheral, characteristic) = hueBulb
        var cmd : NSString?
        if bulbPowerSwitch.isOn {
            cmd = "on"
        } else {
            cmd = "off"
        }
        let data = cmd!.data(using: String.Encoding.utf8.rawValue)
        peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    // MARK: Private functions
    
    private func startScan() {
        print("Now Scanning...\n")
        btStatusLabel.text = "Scanning"
        self.timer.invalidate()
        btManager?.scanForPeripherals(withServices: [BLEService_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        Timer.scheduledTimer(timeInterval: SCAN_TIMEOUT, target: self, selector: #selector(self.cancelScan),
                             userInfo: nil, repeats: false)
    }
    
    @objc private func cancelScan() {
        self.btManager?.stopScan()
        self.timer.invalidate()
        print("\nScan Stopped\n")
        btStatusLabel.text = "Scan stopped"
    }
    
}

