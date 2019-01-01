//
//  LookupWindowController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 30..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa

final class LookupWindowController: NSWindowController {
    
    @IBOutlet private weak var searchField: NSTextField!
    @IBOutlet private weak var tableView: NSTableView!
    
    private var matches: [FourCCEntry] = []
    private var observers: [NSObjectProtocol] = []
    
    override var windowNibName: NSNib.Name? {
        return "LookupWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        observers.append(NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification,
                                                                object: window!,
                                                                queue: nil,
                                                                using: { [weak self] _ in
            self?.window?.close()
        }))
        observers.append(NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification,
                                                                object: window!,
                                                                queue: nil,
                                                                using: { [weak self] _ in
            self?.window?.makeFirstResponder(self?.searchField)
        }))
    }
    
    override func cancelOperation(_ sender: Any?) {
        window?.close()
    }
    
    private func showResults(matching searchTerm: String?) {
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            matches = FourCCDatabase.shared.entriesMatching(searchTerm)
        }
        else {
            matches = []
        }
        
        tableView.reloadData()
    }

    func show(for fourCCValue: UInt32) {
        searchField.stringValue = fourCC(from: fourCCValue) ?? ""
        
        if let match = FourCCDatabase.shared.entry(forValue: Int(fourCCValue)) {
            matches = [match]
        }
        else {
            matches = []
        }
        
        tableView.reloadData()
    }

}

extension LookupWindowController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        showResults(matching: (obj.object as? NSTextField)?.stringValue)
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

