//
//  MainScreenCollectionViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/14/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit
import CoreBluetooth

private let reuseIdentifier = "MainScreenCell"

class MainScreenCollectionViewController: UICollectionViewController {
    
    // MARK: Properties
    var connectedPeripherals = [CBPeripheral]()
    
    
    // MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        BTManager.shared.delegate = self
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation

    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return connectedPeripherals.count + 1 // +1 for the alexa cell
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            as? MainScreenCollectionViewCell else {
            fatalError("The dequeued cell is not an instance of \(reuseIdentifier).")
        }
    
        // Configure the cell
        
        if indexPath.row == connectedPeripherals.count {
            // Configure cell for alexa
            cell.name.text = "Amazon Echo Dot"
            cell.name.textAlignment = .center
            cell.image.image = UIImage(named: "EchoIcon")
        } else {
            let peripheral = connectedPeripherals[indexPath.row]
            switch CBUUID(nsuuid: peripheral.identifier) {
            case BLE_Hue_UUID:
                cell.name.text = "Philips Hue Bulb"
                cell.name.textAlignment = .center
                cell.image.image = UIImage(named: "BulbIcon")
            case BLE_Lock_UUID:
                cell.name.text = "      Smart Lock"
                cell.name.textAlignment = .left
                cell.image.image = UIImage(named: "LockIcon")
            default:
                fatalError("Attempted to load unknown peripheral")
            }
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == connectedPeripherals.count {
            // Alexa
            performSegue(withIdentifier: "LockSegue", sender: self)
        } else {

            let peripheral = connectedPeripherals[indexPath.row]

            switch CBUUID(nsuuid: peripheral.identifier) {
            case BLE_Hue_UUID:
                performSegue(withIdentifier: "BulbSegue", sender: self)
            case BLE_Lock_UUID:
                performSegue(withIdentifier: "LockSegue", sender: self)
            default:
                break
            }
        }
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

// MARK: BTManagerDelegate
extension MainScreenCollectionViewController : BTManagerDelegate {
    func btManager(didUpdatePeripherals peripherals: [CBPeripheral]) {
        
        connectedPeripherals = []
        
        for p in peripherals {
            if p.state == .connected { connectedPeripherals.append(p) }
        }
        
        self.collectionView.reloadData()
    }
    
    func btManager(didUpdateState state: CBManagerState) {
        // Nothing to do here
    }
}
