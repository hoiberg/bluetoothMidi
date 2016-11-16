//
//  AboutViewController.swift
//  BluetoothMIDI
//
//  Created by Alex on 16/11/2016.
//  Copyright © 2016 Hangar42. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBAction func hangar42(_ sender: Any) {
        UIApplication.shared.openURL(URL(string: "http://hangar42.nl")!)
    }
    
    @IBAction func sourceCode(_ sender: Any) {
        UIApplication.shared.openURL(URL(string: "http://www.github.com/hoiberg/bluetoothMidi")!)
    }
    
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true)
    }
}
