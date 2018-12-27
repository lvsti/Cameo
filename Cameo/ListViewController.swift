//
//  ListViewController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 25..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Cocoa
import CoreMediaIO

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
}

func cmioChildren(of objectID: CMIOObjectID) -> [CMIONode] {
    var nodes: [CMIONode] = []

    if let children: [CMIOObjectID] = Property.arrayValue(of: ObjectProperty.ownedObjects, in: objectID) {
        for child in children {
            let subtree = cmioChildren(of: child)
            let name: String = Property.value(of: ObjectProperty.name, in: child) ?? "<untitled @\(child)>"
            let classID: CMIOClassID = Property.value(of: ObjectProperty.class, in: child) ?? CMIOClassID(kCMIOObjectClassID)
            nodes.append(CMIONode(objectID: child, classID: classID, name: name, children: subtree))
        }
    }
    
    return nodes
}

func properties<S>(from type: S.Type, in objectID: CMIOObjectID) -> [CMIOPropertyItem] where S: PropertySet {
    var propertyList: [CMIOPropertyItem] = []
    let props = S.allExisting(in: objectID)
    for prop in props {
        let item = CMIOPropertyItem(selector: S.descriptors[prop]!.selector,
                                    name: "\(prop)",
            isSettable: Property.isSettable(prop, in: objectID),
            value: Property.description(of: prop, in: objectID) ?? "<undefined>")
        propertyList.append(item)
    }
    return propertyList
}

final class ListViewController: NSViewController {
    
    @IBOutlet private weak var outlineView: NSOutlineView!
    @IBOutlet private weak var tableView: NSTableView!
    
    var tree = CMIONode(objectID: CMIOObjectID(kCMIOObjectSystemObject),
                        classID: CMIOClassID(kCMIOSystemObjectClassID),
                        name: "System",
                        children: [])
    var propertyList: [CMIOPropertyItem] = []

    override var nibName: NSNib.Name? {
        return "ListView"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadTree()
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
        
        tableView.reloadData()
    }
    
    private func reloadTree() {
        tree = CMIONode(objectID: CMIOObjectID(kCMIOObjectSystemObject),
                        classID: CMIOClassID(kCMIOSystemObjectClassID),
                        name: "System",
                        children: cmioChildren(of: CMIOObjectID(kCMIOObjectSystemObject)))
        print(tree)
    }
    
    private func reloadPropertyList(for node: CMIONode) {
        propertyList.removeAll()
        
        propertyList.append(contentsOf: properties(from: ObjectProperty.self, in: node.objectID))

        if node.classID.isSubclass(of: CMIOClassID(kCMIODeviceClassID)) {
            propertyList.append(contentsOf: properties(from: DeviceProperty.self, in: node.objectID))
        }
        else if node.classID.isSubclass(of: CMIOClassID(kCMIOStreamClassID)) {
            propertyList.append(contentsOf: properties(from: StreamProperty.self, in: node.objectID))
        }
        else if node.classID.isSubclass(of: CMIOClassID(kCMIOControlClassID)) {
            propertyList.append(contentsOf: properties(from: ControlProperty.self, in: node.objectID))
            
            if node.classID.isSubclass(of: CMIOClassID(kCMIOBooleanControlClassID)) {
                propertyList.append(contentsOf: properties(from: BooleanControlProperty.self, in: node.objectID))
            }
            else if node.classID.isSubclass(of: CMIOClassID(kCMIOSelectorControlClassID)) {
                propertyList.append(contentsOf: properties(from: SelectorControlProperty.self, in: node.objectID))
            }
            else if node.classID.isSubclass(of: CMIOClassID(kCMIOFeatureControlClassID)) {
                propertyList.append(contentsOf: properties(from: FeatureControlProperty.self, in: node.objectID))
                
                if node.classID.isSubclass(of: CMIOClassID(kCMIOExposureControlClassID)) {
                    propertyList.append(contentsOf: properties(from: ExposureControlProperty.self, in: node.objectID))
                }
            }
        }
    }
}

extension ListViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let node = outlineView.item(atRow: outlineView.selectedRow) as! CMIONode
        
        reloadPropertyList(for: node)
        tableView.reloadData()
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
        switch Int(node.classID) {
        case kCMIOSystemObjectClassID: image = NSImage(named: NSImage.networkName)
        case kCMIOPlugInClassID: image = NSImage(named: NSImage.shareTemplateName)
        case kCMIODeviceClassID: image = NSImage(named: NSImage.computerName)
        case kCMIOStreamClassID: image = NSImage(named: NSImage.slideshowTemplateName)
        case _ where node.classID.isSubclass(of: CMIOClassID(kCMIOControlClassID)):
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
            view.textField?.alignment = .left
            return view
        }
        else if column.identifier.rawValue == "valueColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ValueCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = propertyList[row].value
            return view
        }
        else if column.identifier.rawValue == "fourccColumn" {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FourCCCell"),
                                          owner: nil) as! NSTableCellView
            view.textField?.stringValue = "'\(fourCC(from: propertyList[row].selector)!)'"
            return view
        }
        
        return nil
    }
}

