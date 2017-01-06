//
//  AppDelegate.swift
//  Coffeefy
//
//  Created by Taegon Kim on 03/01/2017.
//  Copyright © 2017 Taegon Kim. All rights reserved.
//

import Cocoa
import MASPreferences
import ReachabilitySwift
import CoreWLAN

public let StopAnimationNotification = NSNotification.Name("StopAnimationNotification")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    var statusItem: NSStatusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)

    var _prefWindowController: NSWindowController?
    var prefWindowController: NSWindowController! {
        get {
            if self._prefWindowController == nil {
                let generalPreferences = GeneralPreferencesViewController()
                let aboutPreferences = AboutPreferencesViewController()
                
                let title = NSLocalizedString("Preferences", comment: "Common title for Preferences window")
                self._prefWindowController = MASPreferencesWindowController(viewControllers: [ generalPreferences, aboutPreferences ], title: title)
                self._prefWindowController!.window!.styleMask.update(with: .resizable)
            }
            
            return self._prefWindowController
        }
    }
    
    var currentIconIndex = 3
    var animTimer: Timer?
    
    let reachability = Reachability()!
    let bot = LoginBot()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.menu = statusMenu
        loadStatusImage(name: "coffeefy3")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.stopAnimation), name: StopAnimationNotification, object: nil)
        
        // start watching wifi connection status
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            NSLog("Could not start reachability notifier")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func reachabilityChanged(note: NSNotification) {
        if !reachability.isReachableViaWiFi {
            return
        }
        
        // 스타벅스 SSID일 때만 반응
        let ssid = CWWiFiClient()?.interface(withName: nil)?.ssid() ?? ""
        if ssid.lowercased().contains("starbucks") {
            startAnimatingStatusImage()
            bot.login()
        } else {
            NSLog("This application works only with Starbucks Wifi network")
        }
    }
    
    func stopAnimation(note: NSNotification) {
        stopAnimatingStatusImage()
    }
    
    func loadStatusImage(name: String) {
        if let button = statusItem.button {
            let size = NSMakeSize(18.0, 18.0)
            button.image = NSImage(named: name)
            button.image!.size = size
        }
    }
    
    func startAnimatingStatusImage() {
        currentIconIndex = 0
        updateStatusImage(index: currentIconIndex)

        if #available(OSX 10.12, *) {
            animTimer = Timer.scheduledTimer(withTimeInterval: 4.0/15.0, repeats: true){ timer in
                self.currentIconIndex = ( self.currentIconIndex + 1 ) % 4
                self.updateStatusImage(index: self.currentIconIndex)
            }
        }
    }
    
    func stopAnimatingStatusImage() {
        animTimer?.invalidate()
        animTimer = nil

        updateStatusImage(index: 3)
    }
    
    func updateStatusImage(index: Int) {
        loadStatusImage(name: "coffeefy\(index)")
    }

    @IBAction func openPreference(sender: AnyObject?) {
        prefWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func quitApplication(sender: AnyObject?) {
        NSApplication.shared().terminate(self)
    }
}

