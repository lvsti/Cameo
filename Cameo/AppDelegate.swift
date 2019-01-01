//
//  AppDelegate.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 25..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    private var lookupWindowController: LookupWindowController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.contentViewController = ListViewController()
        window.makeKeyAndOrderFront(nil)
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func showLookupWindow(_ sender: Any?) {
        if lookupWindowController == nil {
            lookupWindowController = LookupWindowController(window: nil)
        }
        lookupWindowController.window?.makeKeyAndOrderFront(nil)
    }
    
    func showLookupWindow(for fourCC: UInt32) {
        showLookupWindow(nil)
        lookupWindowController.show(for: fourCC)
    }
    
}

