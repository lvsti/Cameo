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
    
    private(set) var tree = CMIONode(objectID: .system,
                                     classID: .systemObject,
                                     name: "System",
                                     children: [])
    
    func reload() {
        tree = CMIONode(objectID: .system,
                        classID: .systemObject,
                        name: "System",
                        children: cmioChildren(of: .system))
    }
    
    private func cmioChildren(of objectID: CMIOObjectID) -> [CMIONode] {
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

}