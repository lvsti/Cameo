//
//  ListViewController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 25..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa
import CoreMediaIO
import CMIOKit
import Carbon.HIToolbox


final class ListViewController: NSViewController {
    
    @IBOutlet private weak var outlineView: NSOutlineView!
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private var toolbar: NSToolbar!
    @IBOutlet private weak var adjustControlToolbarItem: NSToolbarItem!
    @IBOutlet private var scopeSelector: NSSegmentedControl!
    
    private let scopeToolbarItemID = NSToolbarItem.Identifier(rawValue: "scopeItem")
    
    private let objectTreeDataSource = ObjectTreeDataSource()
    private let propertyListDataSource = PropertyListDataSource()
    private var currentScope: CMIOObjectPropertyScope = .global

    override var nibName: NSNib.Name? {
        return "ListView"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (NSApp.delegate as? AppDelegate)?.window.toolbar = toolbar
        
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
        
        tableView.reloadData()
        
        adjustControlToolbarItem.isEnabled = false
        toolbar.insertItem(withItemIdentifier: scopeToolbarItemID, at: 2)
    }
    
    override func keyDown(with event: NSEvent) {
        guard event.keyCode == kVK_Space, tableView.selectedRow >= 0 else {
            super.keyDown(with: event)
            return
        }

        let rowRect = tableView.rect(ofRow: tableView.selectedRow)
        let cellView = tableView.view(atColumn: 3, row: tableView.selectedRow, makeIfNecessary: false) as! NSTableCellView
        let qlvc = QuickLookViewController()
        qlvc.content = cellView.textField?.stringValue ?? ""
        
        present(qlvc, asPopoverRelativeTo: rowRect, of: tableView, preferredEdge: .maxY, behavior: .transient)
        view.window?.makeFirstResponder(qlvc)
    }
    
    @IBAction private func reloadClicked(_ sender: Any) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode<Properties>
        
        propertyListDataSource.reload(forNode: node, scope: currentScope)
        tableView.reloadData()
    }
    
    @IBAction private func adjustControlClicked(_ sender: Any) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode<Properties>
        guard node.properties.classID.isSubclass(of: .control) else {
            return
        }
        
        (NSApp.delegate as! AppDelegate).showAdjustControlPanel(for: node.objectID)
    }
    
    @IBAction private func scopeSelectorChanged(_ sender: Any) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode<Properties>

        let scopes: [CMIOObjectPropertyScope] = [
            .global,
            .deviceInput,
            .deviceOutput,
            .devicePlayThrough
        ]
        currentScope = CMIOObjectPropertyScope(scopes[scopeSelector.selectedSegment])
        
        propertyListDataSource.reload(forNode: node, scope: currentScope)
        tableView.reloadData()
    }
    
    @IBAction private func tableRowDoubleClicked(_ sender: Any) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode<Properties>
        let item = propertyListDataSource.items[tableView.selectedRow]
        
        switch item.property.readSemantics {
        case .translation:
            (NSApp.delegate as? AppDelegate)?.showTranslationPanel(for: item.property, in: node.objectID)
            break
        default:
            return
        }
    }
}

extension ListViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode<Properties>
        
        adjustControlToolbarItem.isEnabled = node.properties.classID.isSubclass(of: .control)
        
        let index = toolbar.items.firstIndex(where: { $0.itemIdentifier == scopeToolbarItemID })!
        toolbar.removeItem(at: index)
        toolbar.insertItem(withItemIdentifier: scopeToolbarItemID, at: index)
        
        let scopes: [CMIOObjectPropertyScope] = [
            .global,
            .deviceInput,
            .deviceOutput,
            .devicePlayThrough
        ]
        currentScope = CMIOObjectPropertyScope(scopes[scopeSelector.selectedSegment])

        propertyListDataSource.reload(forNode: node, scope: currentScope)
        tableView.reloadData()
    }
}

extension ListViewController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let previousScopeIndex = scopeSelector.selectedSegment
        
        if outlineView.selectedRow >= 0,
           let node = outlineView.item(atRow: outlineView.selectedRow) as? CMIONode<Properties>,
           node.properties.classID.isSubclass(of: .device) {
            scopeSelector.segmentCount = 4
            
            ["Global", "Input", "Output", "Play-thru"].enumerated().forEach { tuple in
                scopeSelector.setLabel(tuple.element, forSegment: tuple.offset)
                let width = tuple.element.size(withAttributes: [.font: scopeSelector.font!]).width
                scopeSelector.setWidth(width + 10, forSegment: tuple.offset)
            }
        }
        else {
            scopeSelector.segmentCount = 1
            scopeSelector.setLabel("Global", forSegment: 0)
        }

        scopeSelector.sizeToFit()
        scopeSelector.selectedSegment = min(previousScopeIndex, scopeSelector.segmentCount - 1)
        
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = "Scope"
        item.paletteLabel = "Scope"
        item.isEnabled = scopeSelector.segmentCount > 1
        item.view = scopeSelector
        
        return item
    }
}

extension ListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item else {
            return 1
        }
        
        return (item as! CMIONode<Properties>).children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item else {
            return objectTreeDataSource.tree
        }
        
        return (item as! CMIONode<Properties>).children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return !(item as! CMIONode<Properties>).children.isEmpty
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return "foobar"
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"),
                                        owner: nil) as! NSTableCellView
        let node = item as! CMIONode<Properties>
        view.textField?.stringValue = node.properties.name
        
        var image: NSImage?
        switch node.properties.classID {
        case .system: image = NSImage(named: NSImage.networkName)
        case .plugIn: image = NSImage(named: NSImage.shareTemplateName)
        case .device: image = NSImage(named: NSImage.computerName)
        case .stream: image = NSImage(named: NSImage.slideshowTemplateName)
        case _ where node.properties.classID.isSubclass(of: .control):
            image = NSImage(named: NSImage.preferencesGeneralName)
        default: image = NSImage(named: NSImage.touchBarIconViewTemplateName)
        }
        
        view.imageView?.image = image
        
        return view
    }
}

extension ListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return propertyListDataSource.items.count
    }
}

extension ListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn else {
            return nil
        }
        
        let item = propertyListDataSource.items[row]
        
        if column.identifier.rawValue == "propertyColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PropertyCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = item.name
            switch item.property.readSemantics {
            case .read: view.imageView?.image = #imageLiteral(resourceName: "read")
            case .translation: view.imageView?.image = #imageLiteral(resourceName: "translation")
            case .qualifiedRead: view.imageView?.image = #imageLiteral(resourceName: "qualified")
            case .optionallyQualifiedRead: view.imageView?.image = #imageLiteral(resourceName: "qualified_opt")
            }
            
            return view
        }
        else if column.identifier.rawValue == "valueColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ValueCell"),
                                          owner: nil) as! ValueCellView
            view.textField?.stringValue = item.value
            view.showsLinkButton = item.fourCC != nil
            view.delegate = self
            return view
        }
        else if column.identifier.rawValue == "fourccColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FourCCCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = "'\(fourCC(from: item.property.selector)!)'"
            return view
        }
        else if column.identifier.rawValue == "settableColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SettableCell"),
                                          owner: nil) as! NSTableCellView
            let checkbox = view.viewWithTag(1000) as! NSButton
            checkbox.state = item.isSettable ? .on : .off
            
            return view
        }

        return nil
    }
}

extension ListViewController: ValueCellDelegate {
    func valueCellDidClickLinkButton(_ sender: ValueCellView) {
        let clickedRow = tableView.row(for: sender)
        guard clickedRow >= 0, let fourCC = propertyListDataSource.items[clickedRow].fourCC else {
            return
        }
        
        (NSApp.delegate as? AppDelegate)?.showLookupWindow(for: fourCC)
    }
}
