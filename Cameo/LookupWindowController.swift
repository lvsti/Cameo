//
//  LookupWindowController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 30..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa

final class LookupWindowController: NSWindowController {
    
    @IBOutlet private weak var tableView: NSTableView!
    
    private var matches: [FourCCEntry] = []
    private var observer: NSObjectProtocol?
    
    override var windowNibName: NSNib.Name? {
        return "LookupWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        observer = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification,
                                                          object: window!,
                                                          queue: nil, using: { [weak self] _ in
            self?.window?.close()
        })
    }
    
    override func cancelOperation(_ sender: Any?) {
        window?.close()
    }
    
}

extension LookupWindowController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if let searchTerm = (obj.object as? NSTextField)?.stringValue, !searchTerm.isEmpty {
            matches = FourCCDatabase.shared.entriesMatching(searchTerm)
        }
        else {
            matches = []
        }
        
        tableView.reloadData()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(cancelOperation(_:)) {
            window?.close()
            return true
        }
        return false
    }
    
}

extension LookupWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return matches.count
    }
}

extension LookupWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn else {
            return nil
        }
        
        if column.identifier.rawValue == "FourCCColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FourCCCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = "'\(matches[row].fourCC)'"
            return view
        }
        else if column.identifier.rawValue == "DecColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DecCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = "\(matches[row].rawValue)"
            return view
        }
        else if column.identifier.rawValue == "HexColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HexCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = String(matches[row].rawValue, radix: 16, uppercase: false)
            return view
        }
        else if column.identifier.rawValue == "ConstantColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ConstantCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = matches[row].constantName
            return view
        }
        
        return nil
    }
}

