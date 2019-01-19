//
//  ListViewController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 25..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa
import CoreMediaIO
import Carbon.HIToolbox

struct CMIONode {
    var objectID: CMIOObjectID
    var classID: CMIOClassID
    var name: String
    var children: [CMIONode]
}

struct CMIOPropertyItem {
    var selector: CMIOObjectPropertySelector
    var name: String
    var isSettable: Bool
    var value: String
    var fourCC: UInt32?
}

func cmioChildren(of objectID: CMIOObjectID) -> [CMIONode] {
    var nodes: [CMIONode] = []

    if let children: [CMIOObjectID] = Property.arrayValue(of: ObjectProperty.ownedObjects, in: objectID) {
        for child in children {
            let subtree = cmioChildren(of: child)
            let name: String = Property.value(of: ObjectProperty.name, in: child) ?? "<untitled @\(child)>"
            let classID: CMIOClassID = Property.value(of: ObjectProperty.class, in: child) ?? .object
            nodes.append(CMIONode(objectID: child, classID: classID, name: name, children: subtree))
        }
    }
    else if let classID: CMIOClassID = Property.value(of: ObjectProperty.class, in: objectID),
        classID.isSubclass(of: .device),
        let streams: [CMIOStreamID] = Property.arrayValue(of: DeviceProperty.streams, in: objectID) {
        
        for child in streams {
            let subtree = cmioChildren(of: child)
            let name: String = Property.value(of: ObjectProperty.name, in: child) ?? "<untitled @\(child)>"
            let classID: CMIOClassID = Property.value(of: ObjectProperty.class, in: child) ?? .object
            nodes.append(CMIONode(objectID: child, classID: classID, name: name, children: subtree))
        }
    }
    
    return nodes
}

func properties<S>(from type: S.Type,
                   scope: CMIOObjectPropertyScope,
                   in objectID: CMIOObjectID) -> [CMIOPropertyItem] where S: PropertySet {
    var propertyList: [CMIOPropertyItem] = []
    let props = S.allExisting(scope: scope,
                              element: .anyElement,
                              in: objectID)
    for prop in props {
        let isFourCC = S.descriptors[prop]!.type == .fourCC || S.descriptors[prop]!.type == .classID
        let item = CMIOPropertyItem(selector: S.descriptors[prop]!.selector,
                                    name: "\(prop)",
                                    isSettable: Property.isSettable(prop, scope: scope, in: objectID),
                                    value: Property.description(of: prop, scope: scope, in: objectID) ?? "#ERROR",
                                    fourCC: isFourCC ? Property.value(of: prop, scope: scope, in: objectID) : nil)
        propertyList.append(item)
    }
    return propertyList
}

final class ListViewController: NSViewController {
    
    @IBOutlet private weak var outlineView: NSOutlineView!
    @IBOutlet private weak var tableView: NSTableView!
    @IBOutlet private var toolbar: NSToolbar!
    @IBOutlet private weak var adjustControlToolbarItem: NSToolbarItem!
    @IBOutlet private var scopeSelector: NSSegmentedControl!
    
    private let scopeToolbarItemID = NSToolbarItem.Identifier(rawValue: "scopeItem")
    
    private var tree = CMIONode(objectID: CMIOObjectID(kCMIOObjectSystemObject),
                                classID: .systemObject,
                                name: "System",
                                children: [])
    private var propertyList: [CMIOPropertyItem] = []
    private var currentScope: CMIOObjectPropertyScope = .global

    override var nibName: NSNib.Name? {
        return "ListView"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (NSApp.delegate as? AppDelegate)?.window.toolbar = toolbar
        
        reloadTree()
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
        
        tableView.reloadData()
        
        adjustControlToolbarItem.isEnabled = false
        toolbar.insertItem(withItemIdentifier: scopeToolbarItemID, at: 2)
    }
    
    private func reloadTree() {
        tree = CMIONode(objectID: CMIOObjectID(kCMIOObjectSystemObject),
                        classID: .systemObject,
                        name: "System",
                        children: cmioChildren(of: CMIOObjectID(kCMIOObjectSystemObject)))
        print(tree)
    }
    
    private func reloadPropertyList(for node: CMIONode) {
        propertyList.removeAll()
        
        propertyList.append(CMIOPropertyItem(selector: CMIOObjectPropertySelector(kCMIOObjectPropertyScopeWildcard),
                                             name: "objectID",
                                             isSettable: false,
                                             value: "@\(node.objectID)",
                                             fourCC: nil))
        
        propertyList.append(contentsOf: properties(from: ObjectProperty.self, scope: currentScope, in: node.objectID))

        if node.classID.isSubclass(of: .device) {
            propertyList.append(contentsOf: properties(from: DeviceProperty.self, scope: currentScope, in: node.objectID))
        }
        else if node.classID.isSubclass(of: .stream) {
            propertyList.append(contentsOf: properties(from: StreamProperty.self, scope: currentScope, in: node.objectID))
        }
        else if node.classID.isSubclass(of: .control) {
            propertyList.append(contentsOf: properties(from: ControlProperty.self, scope: currentScope, in: node.objectID))
            
            if node.classID.isSubclass(of: .booleanControl) {
                propertyList.append(contentsOf: properties(from: BooleanControlProperty.self, scope: currentScope, in: node.objectID))
            }
            else if node.classID.isSubclass(of: .selectorControl) {
                propertyList.append(contentsOf: properties(from: SelectorControlProperty.self, scope: currentScope, in: node.objectID))
            }
            else if node.classID.isSubclass(of: .featureControl) {
                propertyList.append(contentsOf: properties(from: FeatureControlProperty.self, scope: currentScope, in: node.objectID))
                
                if node.classID.isSubclass(of: .exposureControl) {
                    propertyList.append(contentsOf: properties(from: ExposureControlProperty.self, scope: currentScope, in: node.objectID))
                }
            }
        }
        else if node.classID == .systemObject {
            propertyList.append(contentsOf: properties(from: SystemProperty.self, scope: currentScope, in: node.objectID))
        }
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
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode
        reloadPropertyList(for: node)
        tableView.reloadData()
    }
    
    @IBAction private func adjustControlClicked(_ sender: Any) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode
        guard node.classID.isSubclass(of: .control) else {
            return
        }
        
        (NSApp.delegate as! AppDelegate).showAdjustControlPanel(for: node.objectID)
    }
    
    @IBAction private func scopeSelectorChanged(_ sender: Any) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode

        let scopes: [CMIOObjectPropertyScope] = [
            .global,
            .deviceInput,
            .deviceOutput,
            .devicePlayThrough
        ]
        currentScope = CMIOObjectPropertyScope(scopes[scopeSelector.selectedSegment])
        reloadPropertyList(for: node)
        tableView.reloadData()
    }
}

extension ListViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard outlineView.selectedRow >= 0 else {
            return
        }
        
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode
        
        reloadPropertyList(for: node)
        tableView.reloadData()
        
        adjustControlToolbarItem.isEnabled = node.classID.isSubclass(of: .control)
        
        let index = toolbar.items.firstIndex(where: { $0.itemIdentifier == scopeToolbarItemID })!
        toolbar.removeItem(at: index)
        toolbar.insertItem(withItemIdentifier: scopeToolbarItemID, at: index)
    }
}

extension ListViewController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let previousScopeIndex = scopeSelector.selectedSegment
        
        if outlineView.selectedRow >= 0,
           let node = outlineView.item(atRow: outlineView.selectedRow) as? CMIONode,
           node.classID.isSubclass(of: .device) {
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
        
        return (item as! CMIONode).children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item else {
            return tree
        }
        
        return (item as! CMIONode).children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return !(item as! CMIONode).children.isEmpty
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return "foobar"
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"),
                                        owner: nil) as! NSTableCellView
        let node = item as! CMIONode
        view.textField?.stringValue = node.name
        
        var image: NSImage?
        switch node.classID {
        case .systemObject: image = NSImage(named: NSImage.networkName)
        case .plugIn: image = NSImage(named: NSImage.shareTemplateName)
        case .device: image = NSImage(named: NSImage.computerName)
        case .stream: image = NSImage(named: NSImage.slideshowTemplateName)
        case _ where node.classID.isSubclass(of: .control):
            image = NSImage(named: NSImage.preferencesGeneralName)
        default: image = NSImage(named: NSImage.touchBarIconViewTemplateName)
        }
        
        view.imageView?.image = image
        
        return view
    }
}

extension ListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return propertyList.count
    }
}

extension ListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn else {
            return nil
        }
        
        if column.identifier.rawValue == "propertyColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PropertyCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = propertyList[row].name
            return view
        }
        else if column.identifier.rawValue == "valueColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ValueCell"),
                                          owner: nil) as! ValueCellView
            view.textField?.stringValue = propertyList[row].value
            view.showsLinkButton = propertyList[row].fourCC != nil
            view.delegate = self
            return view
        }
        else if column.identifier.rawValue == "fourccColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FourCCCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = "'\(fourCC(from: propertyList[row].selector)!)'"
            return view
        }
        else if column.identifier.rawValue == "settableColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SettableCell"),
                                          owner: nil) as! NSTableCellView
            let checkbox = view.viewWithTag(1000) as! NSButton
            checkbox.state = propertyList[row].isSettable ? .on : .off
            
            return view
        }

        return nil
    }
}

extension ListViewController: ValueCellDelegate {
    func valueCellDidClickLinkButton(_ sender: ValueCellView) {
        let clickedRow = tableView.row(for: sender)
        guard clickedRow >= 0, let fourCC = propertyList[clickedRow].fourCC else {
            return
        }
        
        (NSApp.delegate as? AppDelegate)?.showLookupWindow(for: fourCC)
    }
}
