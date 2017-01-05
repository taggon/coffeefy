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
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let buildNum = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
            versionField.stringValue = "Version \(version).\(buildNum)"
        }
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
