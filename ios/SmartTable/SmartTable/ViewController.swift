//
//  ViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/7/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var btTableView: UITableView!
    @IBOutlet weak var btStatusLabel: UILabel!
    @IBOutlet weak var refreshBTButton: UIButton!
    @IBOutlet weak var bulbPowerSwitch: UISwitch!
    
    var availableBT = [CBPeripheral]()
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        btTableView.delegate = self
        bulbPowerSwitch.isOn = false
        btStatusLabel.text = "Please refresh list"
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

    // MARK: Actions
    
    @IBAction func refreshBTPressed(_ sender: Any) {
    }
    
    @IBAction func bulbPowerToggled(_ sender: Any) {
    }
    
}

