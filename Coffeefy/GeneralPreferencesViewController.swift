//
//  GeneralPreferencesViewController.swift
//  Coffeefy
//
//  Created by Taegon Kim on 03/01/2017.
//  Copyright © 2017 Taegon Kim. All rights reserved.
//

import Cocoa
import MASPreferences

class GeneralPreferencesViewController: NSViewController, MASPreferencesViewController {
    
    @IBOutlet var vendor1: NSButton!
    @IBOutlet var vendor2: NSButton!
    @IBOutlet var vendor3: NSButton!
    
    var vendorCollection: [NSButton]! {
        return [vendor1, vendor2, vendor3]
    }
    
    // 이건 왜 안되는 걸까
    // @IBOutlet var vendorCollection: [NSButton]!

    public var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNamePreferencesGeneral)
    }
    
    public var toolbarItemLabel: String! {
        return NSLocalizedString("General", comment: "Toolbar item name for the General preference pane")
    }
    
    init() {
        super.init(nibName: "GeneralPreferencesView", bundle: nil)!
        self.identifier = "GeneralPreferences"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let vendorIndex = UserDefaults.standard.integer(forKey: "vendor")
        for item in vendorCollection {
            item.state = ( item.tag == vendorIndex ) ? NSOnState : NSOffState
        }
    }
    
    @IBAction func vendorDidChange(sender: AnyObject) {
        let radio = sender as! NSButton
        UserDefaults.standard.set(radio.tag, forKey: "vendor")
    }
}
