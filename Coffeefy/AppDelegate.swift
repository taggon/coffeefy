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
import Alamofire
import CocoaLumberjack

public let PostResultNotification = NSNotification.Name("PostResultNotification")
public let ddLogLevel: DDLogLevel = DDLogLevel.info

let keyIgnoreVersion = "Ignore Version"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    var statusItem: NSStatusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)

    lazy var prefWindowController: NSWindowController! = {
        
        let generalPreferences = GeneralPreferencesViewController()
        let aboutPreferences = AboutPreferencesViewController()
        
        let title = NSLocalizedString("Preferences", comment: "Common title for Preferences window")
        let controller = MASPreferencesWindowController(viewControllers: [ generalPreferences, aboutPreferences ], title: title)
        
        return controller
    }()
    
    var currentIconIndex = 3
    var animTimer: Timer?
    
    let reachability = Reachability()!
    let bot = LoginBot()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // initiate logger
        #if DEBUG
            DDLog.add(DDTTYLogger.sharedInstance())
        #else
            let fileLogger = DDFileLogger()
            fileLogger?.rollingFrequency = 7 * 60 * 60 * 24 // a week
            fileLogger?.logFileManager.maximumNumberOfLogFiles = 1
            DDLog.add(fileLogger)
        #endif
        
        // status menu
        statusItem.menu = statusMenu
        loadStatusImage(name: "coffeefy3")
        
        // show version string in the first menu item
        statusMenu.items[0].title = "Coffeefy v\(self.version)"

        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveResult), name: PostResultNotification, object: nil)
        
        // start watching wifi connection status
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            DDLogWarn("Could not start reachability notifier")
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
        let ssid = CWWiFiClient()?.interface(withName: nil)?.ssid() ?? "[Empty SSID]"
        if ssid.lowercased().contains("starbucks") {
            startAnimatingStatusImage()
            bot.login()
        } else {
            DDLogWarn("Unknown SSID - \(ssid) is not Starbucks Wifi network")
        }
    }
    
    func receiveResult(note: NSNotification) {
        stopAnimatingStatusImage()
        
        let success = note.object as? Bool ?? false
        
        if success {
            updateCheck(manual: false)
        }
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
    
    func updateCheck(manual: Bool) {
        guard let urls = Bundle.main.object(forInfoDictionaryKey: "URLs") as? Dictionary<String, String> else {
            return
        }

        Alamofire.request(urls["API:Latest"]!).responseJSON { response in
            if let json = response.result.value as? [String: Any], let tag = json["tag_name"] as? String {
                let versionString = "v\(self.version)"
                
                let popup = NSAlert()
                popup.window.title = "업데이트 확인"
                popup.messageText = "Coffeefy \(versionString) (Build \(self.buildNumber))"
                popup.alertStyle = .informational

                
                let ignoreVersion = UserDefaults.standard.string(forKey: keyIgnoreVersion) ?? ""
                
                if tag == versionString {
                    if manual {
                        popup.informativeText = "현재 사용중인 애플리케이션이 최신 버전입니다."
                        popup.addButton(withTitle: "확인")
                        popup.runModal()
                    }
                } else if manual || tag != ignoreVersion {
                    popup.informativeText = "최신 버전은 \(tag)입니다. [다운로드] 버튼을 눌러 새 버전을 다운로드하세요."
                    popup.addButton(withTitle: "다운로드")
                    popup.addButton(withTitle: "닫기")
                    popup.addButton(withTitle: "이 버전 무시")
                    
                    let result = popup.runModal()

                    if result == NSAlertFirstButtonReturn {
                        NSWorkspace.shared().open(URL(string: urls["Releases"]!)!)
                    } else if result == NSAlertThirdButtonReturn {
                        UserDefaults.standard.set(tag, forKey: keyIgnoreVersion)
                    }
                }
            }
        }
    }

    @IBAction func openPreference(sender: AnyObject?) {
        prefWindowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func quitApplication(sender: AnyObject?) {
        NSApplication.shared().terminate(self)
    }
    
    @IBAction func updateLatestVersion(sender: AnyObject?) {
        updateCheck(manual: true)
    }
}

