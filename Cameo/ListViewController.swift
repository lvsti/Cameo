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

func cmioChildren(of objectID: CMIOObjectID) -> [CMIONode] {
    var nodes: [CMIONode] = []

    if let children: [CMIOObjectID] = Property.arrayValue(of: ObjectProperty.ownedObjects, in: objectID) {
        for child in children {
            let subtree = cmioChildren(of: child)
            let name: String = Property.value(of: ObjectProperty.name, in: child) ?? "<untitled #\(child)>"
            let classID: CMIOClassID = Property.value(of: ObjectProperty.class, in: child) ?? CMIOClassID(kCMIOObjectClassID)
            nodes.append(CMIONode(objectID: child, classID: classID, name: name, children: subtree))
        }
    }
    
    return nodes
}

final class ListViewController: NSViewController {
    
    @IBOutlet private weak var outlineView: NSOutlineView!
    
    var tree = CMIONode(objectID: CMIOObjectID(kCMIOObjectSystemObject),
                        classID: CMIOClassID(kCMIOSystemObjectClassID),
                        name: "System",
                        children: [])

    override var nibName: NSNib.Name? {
        return "ListView"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reload()
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }
    
    private func reload() {
        tree = CMIONode(objectID: CMIOObjectID(kCMIOObjectSystemObject),
                        classID: CMIOClassID(kCMIOSystemObjectClassID),
                        name: "System",
                        children: cmioChildren(of: CMIOObjectID(kCMIOObjectSystemObject)))
        print(tree)
    }
}

extension ListViewController: NSOutlineViewDelegate {
    
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
    
}

