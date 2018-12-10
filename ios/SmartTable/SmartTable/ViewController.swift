//
//  ViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/7/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CBCentralManagerDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var btTableView: UITableView!
    @IBOutlet weak var btStatusLabel: UILabel!
    @IBOutlet weak var refreshBTButton: UIButton!
    @IBOutlet weak var bulbPowerSwitch: UISwitch!
    
    let SCAN_TIMEOUT = 5.0
    
    var availableBT = [CBPeripheral]()
    var timer = Timer()
    
    var btManager : CBCentralManager!
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btTableView.delegate = self
        btTableView.dataSource = self
        
        bulbPowerSwitch.isOn = false
        
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
                print("Found new pheripheral devices with services")
                print("Peripheral name: \(String(describing: peripheral.name))")
                print("**********************************")
                print("Advertisement Data : \(advertisementData)")
                print("UUID: \(peripheral.identifier)\n")
            }
        }
    }

    // MARK: Actions
    
    @IBAction func refreshBTPressed(_ sender: Any) {
        availableBT = []
        startScan()
    }
    
    @IBAction func bulbPowerToggled(_ sender: Any) {
    }
    
    // MARK: Private functions
    
    private func startScan() {
        print("Now Scanning...")
        btStatusLabel.text = "Scanning"
        self.timer.invalidate()
        btManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
        Timer.scheduledTimer(timeInterval: SCAN_TIMEOUT, target: self, selector: #selector(self.cancelScan),
                             userInfo: nil, repeats: false)
    }
    
    @objc private func cancelScan() {
        self.btManager?.stopScan()
        self.timer.invalidate()
        print("Scan Stopped")
        btStatusLabel.text = "Scan stopped"
    }
    
}

