//
//  SmartLockViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/13/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit

class SmartLockViewController: UIViewController {
    
    // MARK: Properties

    @IBOutlet weak var lockSwitch: UISwitch!
    
    // MARK: ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lockSwitch.isOn = false
        lockSwitch.onTintColor = UIColor.red
        lockSwitch.tintColor = UIColor.green
    }
    
    // MARK: Actions
    
    @IBAction func lockToggled(_ sender: Any) {
        if lockSwitch.isOn {
            let _ = BTManager.shared.write("l", to: .lock)
        } else {
            let _ = BTManager.shared.write("u", to: .lock)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
