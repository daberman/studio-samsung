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
    let REFRESH_AVAILABLE = 5.0

    // MARK: Properties
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var deviceTable: UITableView!
    @IBOutlet weak var scanButton: UIButton!
    
    var availablePeripherals = [CBPeripheral]()
    var statusTimer : Timer?
    var refreshTimer : Timer?
    
    // MARK: ViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateStatusLabel()
        
        deviceTable.delegate = self
        deviceTable.dataSource = self
        
        refreshAvailable()
        
        startTimers()
    }
    
    func stopTimers() {
        refreshTimer?.invalidate()
        statusTimer?.invalidate()
    }
    
    func startTimers() {
        // Schedule a timer to regularly update the status label
        statusTimer = Timer.scheduledTimer(timeInterval: STATUS_TIMEOUT, target: self, selector: #selector(updateStatusLabel), userInfo: nil, repeats: true)
        
        // Schedule a timer to regularly refresh the table
        refreshTimer = Timer.scheduledTimer(timeInterval: REFRESH_AVAILABLE, target: self, selector: #selector(refreshAvailable), userInfo: nil, repeats: true)
    }
    
    // MARK: Actions
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        BTManager.shared.stop()
        BTManager.shared.resume()
        
        Timer.scheduledTimer(timeInterval: REFRESH_AVAILABLE, target: self, selector: #selector(refreshAvailable),
                             userInfo: nil, repeats: false)
    }
    
    // MARK: Private Functions
    
    @objc private func updateStatusLabel () {
        if let status = BTManager.shared.managerStatus {
            statusLabel.text = "Current Bluetooth Status: \(status.rawValue)"
        } else {
            statusLabel.text = "Unable to obtain bluetooth status"
        }
    }
    
    @objc private func refreshAvailable() {
        availablePeripherals = BTManager.shared.availablePeripherals
        deviceTable.reloadData()
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let peripheral = availablePeripherals[indexPath.row]
        
        switch CBUUID(nsuuid: peripheral.identifier) {
        case BLE_Hue_UUID:
            performSegue(withIdentifier: "HueBulbSegue", sender: self)
            print("Successful Segue")
        default:
            break
        }
    }
}
