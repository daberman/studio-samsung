//
//  HueBulbViewController.swift
//  SmartTable
//
//  Created by Dan Berman on 12/13/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit

class HueBulbViewController: UIViewController, HSBColorPickerDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var colorPicker: HSBColorPicker!
    @IBOutlet weak var redValueLabel: UILabel!
    @IBOutlet weak var greenValueLabel: UILabel!
    @IBOutlet weak var blueValueLabel: UILabel!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var rainbowSwitch: UISwitch!
    
    // MARK: ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        colorPicker.delegate = self
        updateColorLabels(255, 255, 255)
        
        brightnessSlider.value = 100
        updateBrightness()
        
        onOffSwitch.isOn = false
        rainbowSwitch.isOn = false
    }
    
    // MARK: HSBColorPickerDelegate
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint,
                                    state: UIGestureRecognizer.State) {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        color.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: nil)
        
        let uintColors = [UInt8(fRed * 255), UInt8(fGreen * 255), UInt8(fBlue * 255)]
        
        updateColorLabels(Int(uintColors[0]), Int(uintColors[1]), Int(uintColors[2]))
        
        HueBulb.color(uintColors[0], uintColors[1], uintColors[2])
    }
    
    // MARK: Actions
    
    @IBAction func brightnessChanged(_ sender: Any) {
        
        updateBrightness()
        
        HueBulb.brightness(brightness: UInt8(brightnessSlider.value))
    }
    
    @IBAction func onOffChanged(_ sender: Any) {
        if onOffSwitch.isOn {
            HueBulb.on()
        } else {
            HueBulb.off()
        }
    }
    
    @IBAction func rainbowChanged(_ sender: Any) {
        HueBulb.rainbowMode(is: rainbowSwitch.isOn)
    }
    
    // MARK: Private Functions
    
    private func updateColorLabels(_ red: Int, _ green: Int, _ blue: Int) {
        redValueLabel.text = "Red: \(red)"
        greenValueLabel.text = "Green: \(green)"
        blueValueLabel.text = "Blue: \(blue)"
    }
    
    private func updateBrightness() {
        brightnessLabel.text = "\(Int(brightnessSlider.value))"
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
