//
//  LoginBot.swift
//  Coffeefy
//
//  Created by Taegon Kim on 04/01/2017.
//  Copyright © 2017 Taegon Kim. All rights reserved.
//

import Cocoa
import WebKit
import Alamofire
import CocoaLumberjack

let messageHandlerKey = "coffeefy"
let firstURL = "http://first.wifi.olleh.com/starbucks/index_en_new.html"

class LoginBot: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    
    lazy var panel: NSPanel! = {
        let p = NSPanel()
        p.contentView = self.webview
        p.level = Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow))
        return p
    }()
    lazy var webview: WKWebView! = {
        let wv = WKWebView()
        self.initWebview(wv)
        return wv
    }()

    var branch = ""

    func initWebview(_ webView: WKWebView) {
        let contentController = webView.configuration.userContentController

        contentController.add(self, name: messageHandlerKey)
        
        let mainScript = WKUserScript(source: loadTextBundle(forResource: "coffeefy", ofType: "js"), injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(mainScript)

        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36"
        // webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    }
    
    func login() {
        DDLogInfo("Checking if in Startbucks network")

        Alamofire.request(firstURL).responseString { response in
            guard let content = response.result.value else {
                DDLogWarn("Could not get content from the network.")
                return
            }

//            if !content.hasPrefix("<script") {
                DDLogInfo("Moving to Google...")
                // 다른 사이트로 먼저 이동해야 접속이 이루어짐 HTTP 프로토콜 필수
                self.webview.load( URLRequest(url: URL(string: "http://google.com")!) )
                // self.webview.load( URLRequest(url: URL(string: firstURL)!) ) // 에러가 발생하는 사례
                
                return;
//            } else {
//              DDLogWarn("This application works only with Startbucks Wifi network.")
//            }

//            self.postResult(success: false)
        }
    }
    
    func loadTextBundle(forResource: String?, ofType: String?) -> String {
        let path = Bundle.main.path(forResource: forResource, ofType: ofType)
        
        do {
            let content = try String(contentsOfFile: path!, encoding: .utf8)
            return content
        } catch let error {
            DDLogError("Error loading contentsOf url \(path)")
            DDLogError(error.localizedDescription)
        }
        
        return ""
    }
    
    func notify(title: String, subtitle: String, informativeText: String?) {
        let noti = NSUserNotification()
        noti.title = title
        noti.subtitle = subtitle
        if informativeText != nil {
            noti.informativeText = informativeText
        }
        noti.soundName = NSUserNotificationDefaultSoundName
        noti.deliveryDate = Date(timeIntervalSinceNow: 1)
        NSUserNotificationCenter.default.scheduleNotification(noti)
    }
    
    func postResult(success: Bool) {
        NotificationCenter.default.post(name: PostResultNotification, object: success)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let body = message.body as! String

        if body == "try-login" {
            let name = UserDefaults.standard.string(forKey: "name") ?? ""
            let email = UserDefaults.standard.string(forKey: "email") ?? ""
            let phone = UserDefaults.standard.string(forKey: "phone") ?? ""

            webview.evaluateJavaScript("coffeefy({name:'\(name)', email:'\(email)', phone: '\(phone)', branch: '\(self.branch)'})", completionHandler: nil)
            DDLogInfo("Trying to sign in... (name=\(name), email=\(email))")
        } else if body.hasPrefix("alert:") {
            let errorMessage = body.substring(from: body.characters.index(body.characters.startIndex, offsetBy: 6))
            notify(title: "인증 에러", subtitle: errorMessage, informativeText: nil)
            postResult(success: false)
            
            DDLogError("Authorization failed: \(errorMessage)")
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let host = webview.url?.host else {
            // 호스트가 없는 경우는 다루지 않음
            return
        }

        if host == "www.istarbucks.co.kr" || host.hasPrefix("www.google.") {
            webView.stopLoading()
            notify(title: "접속 성공", subtitle: "이제 스타벅스 와이파이를 사용할 수 있습니다.", informativeText: nil)
            DDLogInfo("Successfully connected!")
            postResult(success: true)
        }
    }
}

