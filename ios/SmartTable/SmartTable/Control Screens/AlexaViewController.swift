//
//  AlexaViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/14/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit
import CoreBluetooth

class AlexaViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var lightsOffButton: UIButton!
    @IBOutlet weak var partyButton: UIButton!
    @IBOutlet weak var morningButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var nightButton: UIButton!
    
    private var bulbEnabled = false
    private var lockEnabled = false
    
    private var timer : Timer?
    private var morningBrightness : UInt8 = 0
    
    // ViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        updateButtons()
        
        BTManager.shared.delegate = self
    }
    
    // When returning back to Main, need to return it to being the delegate for BTManager
    override func viewWillDisappear(_ animated: Bool) {
        
        if let navController = parent as? UINavigationController {
            let n = navController.viewControllers.count
            if let controller = navController.viewControllers[n-1] as? MainScreenCollectionViewController {
                BTManager.shared.delegate = controller
            }
        }
        
        timer?.invalidate()
    }
    
    // MARK: Actions
    
    @IBAction func lightsOffPressed(_ sender: Any) {
        HueBulb.off()
    }
    
    @IBAction func partyPressed(_ sender: Any) {
        HueBulb.on()
        HueBulb.brightness(brightness: 100)
        HueBulb.rainbowMode(is: true)
    }
    
    @IBAction func morningPressed(_ sender: Any) {
        HueBulb.on()
        HueBulb.color(255, 255, 255)
        HueBulb.brightness(brightness: 0)
        HueBulb.rainbowMode(is: false)
        
        morningBrightness = 0
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(morningRoutine), userInfo: nil, repeats: true)
    }
    
    @IBAction func lockPressed(_ sender: Any) {
        SmartLock.lock()
    }
    
    @IBAction func unlockPressed(_ sender: Any) {
        SmartLock.unlock()
    }
    
    @IBAction func nightPressed(_ sender: Any) {
        if !lockEnabled || !bulbEnabled {
            let title = "Missing Device"
            var msg = ""
            if !lockEnabled { msg = "Connect a smart lock for full functionality"}
            if !bulbEnabled { msg = "Connect a Philips Hue for full functionality"}
            let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            let yes = UIAlertAction(title: "Continue", style: .default, handler: nightRoutine)
            let no = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(yes)
            alert.addAction(no)
            present(alert, animated: true)
        } else {
            nightRoutine(nil)
        }
    }
    
    // MARK: Private Functions
    
    private func updateButtons() {
        updateBulbButtons()
        updateLockButtons()
        updateMultiButtons()
    }
    
    private func updateBulbButtons() {
        lightsOffButton.isEnabled = bulbEnabled
        partyButton.isEnabled = bulbEnabled
        morningButton.isEnabled = bulbEnabled
    }

    
    private func updateLockButtons() {
        lockButton.isEnabled = lockEnabled
        unlockButton.isEnabled = lockEnabled
    }
    
    private func updateMultiButtons() {
        nightButton.isEnabled = bulbEnabled || lockEnabled
    }
    
    @objc private func morningRoutine() {
        morningBrightness += 1
        HueBulb.brightness(brightness: morningBrightness)
        if morningBrightness >= 100 { timer?.invalidate() }
    }
    
    private func nightRoutine(_ action: UIAlertAction?) {
        HueBulb.off()
        SmartLock.lock()
    }

}

// MARK: BTManagerDelegate
extension AlexaViewController : BTManagerDelegate {
    func btManager(didUpdatePeripherals peripherals: [CBPeripheral]) {
        
        bulbEnabled = false
        lockEnabled = false
        
        for p in peripherals {
            switch CBUUID(nsuuid: p.identifier) {
            case BLE_Hue_UUID:
                bulbEnabled = p.state == .connected
            case BLE_Lock_UUID:
                lockEnabled = p.state == .connected
            default:
                break
            }
        }
        
        updateButtons()
    }
    
    func btManager(didUpdateState state: CBManagerState) {
        // Nothing to do here
    }
    
    
}
