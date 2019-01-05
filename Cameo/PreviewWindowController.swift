//
//  PreviewWindowController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 05..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Cocoa
import AVFoundation

protocol PreviewWindowControllerDelegate: class {
    func previewWindowWillClose()
}

final class PreviewWindowController: NSWindowController {
    @IBOutlet private weak var cameraView: NSView!
    @IBOutlet private weak var deviceDropdown: NSPopUpButton!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private var frameObserver: NSObjectProtocol?
    private var sessionObserver: NSObjectProtocol?

    private var captureDevices: [AVCaptureDevice] = []
    private let captureSession = AVCaptureSession()
    private var currentDevice: AVCaptureDevice? {
        didSet {
            guard currentDevice != oldValue else { return }
            
            let newTitle: String
            if let name = currentDevice?.localizedName {
                newTitle = "\(name) - Camera Preview"
            }
            else {
                newTitle = "Camera Preview"
            }
            
            window?.title = newTitle
        }
    }
    
    weak var delegate: PreviewWindowControllerDelegate?
    
    override var windowNibName: NSNib.Name? {
        return "PreviewWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        cameraView.wantsLayer = true
        cameraView.layer?.backgroundColor = NSColor(deviceWhite: 0.2, alpha: 1.0).cgColor
        cameraView.layer?.contentsGravity = .resize

        frameObserver = NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification,
                                                               object: cameraView,
                                                               queue: nil,
                                                               using: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.previewLayer.frame = strongSelf.cameraView.bounds
        })
        
        sessionObserver = NotificationCenter.default.addObserver(forName: .AVCaptureSessionDidStartRunning,
                                                                 object: captureSession,
                                                                 queue: nil,
                                                                 using: { [weak self] _ in
            guard let strongSelf = self else { return }
            if strongSelf.previewLayer != nil {
                strongSelf.previewLayer.removeFromSuperlayer()
            }
            strongSelf.previewLayer = AVCaptureVideoPreviewLayer(session: strongSelf.captureSession)
            strongSelf.previewLayer.frame = strongSelf.cameraView.bounds
            strongSelf.previewLayer.videoGravity = .resizeAspect

            strongSelf.cameraView.layer?.addSublayer(strongSelf.previewLayer)
        })
        
        reloadDevices()
    }
    
    private func reloadDevices() {
        captureDevices = AVCaptureDevice.devices(for: .video)
        let devicesMenu = NSMenu(title: "Capture devices")

        for device in captureDevices {
            let item = NSMenuItem(title: device.localizedName, action: #selector(deviceSelected(_:)), keyEquivalent: "")
            item.representedObject = device
            devicesMenu.addItem(item)
        }
        
        deviceDropdown.menu = devicesMenu
        
        if let device = currentDevice, let menuItem = devicesMenu.items.first(where: { $0.representedObject as? AVCaptureDevice == device }) {
            deviceDropdown.select(menuItem)
        }
        else if !devicesMenu.items.isEmpty {
            deviceDropdown.select(devicesMenu.items.first!)
        }

        if let selectedDevice = deviceDropdown.selectedItem?.representedObject as? AVCaptureDevice {
            activateDevice(selectedDevice)
        }
    }
    
    private func activateDevice(_ device: AVCaptureDevice) {
        guard device != currentDevice else {
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            self.captureSession.inputs.forEach(self.captureSession.removeInput)

            try! self.captureSession.addInput(AVCaptureDeviceInput(device: device))
            self.captureSession.startRunning()

            DispatchQueue.main.async {
                self.currentDevice = device
            }
        }
    }
    
    @IBAction private func reloadDevicesClicked(_ sender: Any?) {
        reloadDevices()
    }
    
    @IBAction private func deviceSelected(_ sender: Any?) {
        guard let device = (sender as? NSMenuItem)?.representedObject as? AVCaptureDevice else {
            return
        }
        
        activateDevice(device)
    }
    
}

extension PreviewWindowController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        delegate?.previewWindowWillClose()
        return true
    }
}
