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
    private var previewWindowController: PreviewWindowController!
    private var adjustControlPanelController: AdjustControlPanelController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.contentViewController = ListViewController()
        window.makeKeyAndOrderFront(nil)
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction private func showLookupWindow(_ sender: Any?) {
        if lookupWindowController == nil {
            lookupWindowController = LookupWindowController(window: nil)
        }
        lookupWindowController.showWindow(nil)
    }
    
    func showLookupWindow(for fourCC: UInt32) {
        showLookupWindow(nil)
        lookupWindowController.show(for: fourCC)
    }
    
    @IBAction private func showCameraPreviewWindow(_ sender: Any?) {
        if previewWindowController == nil {
            previewWindowController = PreviewWindowController(window: nil)
            previewWindowController.delegate = self
        }
        previewWindowController.showWindow(nil)
    }
    
    func showAdjustControlPanel(for controlID: UInt32) {
        guard adjustControlPanelController == nil else {
            return
        }

        adjustControlPanelController = AdjustControlPanelController(controlID: controlID)
        adjustControlPanelController.delegate = self
        window.beginSheet(adjustControlPanelController.window!) { _ in
            self.adjustControlPanelController = nil
        }
    }
}

extension AppDelegate: PreviewWindowControllerDelegate {
    func previewWindowWillClose() {
        previewWindowController = nil
    }
}

extension AppDelegate: AdjustControlPanelControllerDelegate {
    func adjustControlPanelDidDismiss() {
        window.endSheet(adjustControlPanelController.window!)
    }
}


