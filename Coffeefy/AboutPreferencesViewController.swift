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
    
    @IBOutlet weak var versionField: NSTextField!
    
    public var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameInfo)
    }
    
    public var toolbarItemLabel: String! {
        return NSLocalizedString("About", comment: "About this application")
    }
    
    override var identifier: String? { get {return "AboutPreferences"} set { super.identifier = newValue} }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        versionField.stringValue = "Version \(appDelegate.version) (Build \(appDelegate.buildNumber))"
    }
    
    func openURLwithDefaultBrowser(urlKey: String) {
        guard let urls = Bundle.main.object(forInfoDictionaryKey: "URLs") as? Dictionary<String, String> else {
            return
        }
        if let urlString = urls[urlKey] {
            NSWorkspace.shared().open(URL(string: urlString)!)
        }
    }
    
    @IBAction func openHomepage(_ sender: AnyObject) {
        openURLwithDefaultBrowser(urlKey: "Homepage")
    }
    
    @IBAction func openIssueTracker(_ sender: AnyObject) {
        openURLwithDefaultBrowser(urlKey: "Issue Tracker")
    }
    
    @IBAction func openAuthorPage(_ sender: AnyObject) {
        openURLwithDefaultBrowser(urlKey: "Author")
    }
}
