//
//  QuickLookPopover.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 27..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa
import Carbon.HIToolbox.Events

final class QuickLookViewController: NSViewController {
    
    @IBOutlet private var textView: NSTextView!
    
    var content: String = "" {
        didSet {
            guard isViewLoaded else { return }
            textView.string = content
        }
    }

    override var nibName: NSNib.Name? {
        return "QuickLookView"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let desc = NSFontDescriptor(name: "Monaco", size: 11)
        textView.font = NSFont(descriptor: desc, size: 11)
        
        preferredContentSize = NSSize(width: 500, height: 250)
        textView.string = content
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == kVK_Space {
            dismiss(nil)
            return
        }
        super.keyDown(with: event)
    }
    
}
