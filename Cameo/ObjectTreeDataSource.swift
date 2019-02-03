//
//  ObjectTreeDataSource.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 19..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
import CameoSDK

struct CMIONode {
    var objectID: CMIOObjectID
    var classID: CMIOClassID
    var name: String
    var children: [CMIONode]
}

final class ObjectTreeDataSource {
    
    private(set) var tree = CMIONode(objectID: .systemObject,
                                     classID: .system,
                                     name: "System",
                                     children: [])
    
    func reload() {
        tree = CMIONode(objectID: .systemObject,
                        classID: .system,
                        name: "System",
                        children: cmioChildren(of: .systemObject))
    }
    
    private func cmioChildren(of objectID: CMIOObjectID) -> [CMIONode] {
        var nodes: [CMIONode] = []
        
        if let children: [CMIOObjectID] = ObjectProperty.ownedObjects.arrayValue(in: objectID) {
            for child in children {
                let subtree = cmioChildren(of: child)
                let name = ObjectProperty.name.description(in: child) ?? "<untitled @\(child)>"
                let classID: CMIOClassID = ObjectProperty.class.value(in: child) ?? .object
                nodes.append(CMIONode(objectID: child, classID: classID, name: name, children: subtree))
            }
        }
        else if let classID: CMIOClassID = ObjectProperty.class.value(in: objectID),
            classID.isSubclass(of: .device),
            let streams: [CMIOStreamID] = DeviceProperty.streams.arrayValue(in: objectID) {
            
            for child in streams {
                let subtree = cmioChildren(of: child)
                let name = ObjectProperty.name.description(in: child) ?? "<untitled @\(child)>"
                let classID: CMIOClassID = ObjectProperty.class.value(in: child) ?? .object
                nodes.append(CMIONode(objectID: child, classID: classID, name: name, children: subtree))
            }
        }
        
        return nodes
    }

}
