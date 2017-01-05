//
//  AboutPreferencesViewController.swift
//  Coffeefy
//
//  Created by Taegon Kim on 03/01/2017.
//  Copyright © 2017 Taegon Kim. All rights reserved.
//

import Cocoa
import MASPreferences

class AboutPreferencesViewController: NSViewController, MASPreferencesViewController {
    
    public var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameInfo)
    }
    
    public var toolbarItemLabel: String! {
        return NSLocalizedString("About", comment: "About this application")
    }
    
    init() {
        super.init(nibName: "AboutPreferencesView", bundle: nil)!
        self.identifier = "AboutPreferences"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
