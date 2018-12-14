//
//  BTViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/12/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit
import CoreBluetooth

class BTViewController: UIViewController {
    
    // MARK: Constants
    
    let STATUS_TIMEOUT = 1.0
    let REFRESH_AVAILABLE = 1.0

    // MARK: Properties
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var deviceTable: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var availablePeripherals = [CBPeripheral]()
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deviceTable.delegate = self
        deviceTable.dataSource = self
        
        BTManager.shared.delegate = self
    }
    
    // MARK: Actions
    
    @IBAction func refreshButtonPressed(_ sender: Any) {
        BTManager.shared.stop()
        BTManager.shared.resume()
    }
    
    // MARK: Private Functions
}

// MARK: BTManagerDelegate
extension BTViewController : BTManagerDelegate {
    func btManager(didUpdatePeripherals peripherals: [CBPeripheral]) {
        
        availablePeripherals = peripherals
        deviceTable.reloadData()
    }
    
    func btManager(didUpdateState state: CBManagerState) {
        statusLabel.text = "Current Bluetooth Status: \(state.rawValue)"
    }   
}

// MARK: TableView
extension BTViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //refreshAvailable()
        return availablePeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "BTPeripheralTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? BTPeripheralTableViewCell
            else {
                fatalError("The dequeued cell is not an instance of \(cellIdentifier).")
        }
        
        // Fetches the appropriate peripheral for the data source layout.
        let peripheral = availablePeripherals[indexPath.row]
        
        cell.name.text = peripheral.name
        cell.uuid.text = "UUID:\n" + peripheral.identifier.uuidString
        
        switch peripheral.state {
        case .connected:
            cell.connStatus.text = "Connected"
        case .connecting:
            cell.connStatus.text = "Connecting"
        case .disconnecting:
            cell.connStatus.text = "Disconnecting"
        case .disconnected:
            cell.connStatus.text = "Disconnected"
        }
        
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        let peripheral = availablePeripherals[indexPath.row]
//
//        switch CBUUID(nsuuid: peripheral.identifier) {
//        case BLE_Hue_UUID:
//            performSegue(withIdentifier: "HueBulbSegue", sender: self)
//        case BLE_Lock_UUID:
//            performSegue(withIdentifier: "SmartLockSegue", sender: self)
//        default:
//            break
//        }
//    }
}
