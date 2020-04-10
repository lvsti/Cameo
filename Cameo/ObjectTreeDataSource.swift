//
//  ObjectTreeDataSource.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 19..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
import CMIOKit

struct Properties: CMIOPropertySource {
    let classID: CMIOClassID
    let name: String

    static func properties(for objectID: CMIOObjectID) -> Properties {
        let classID: CMIOClassID = ObjectProperty.class.value(in: objectID) ?? .object
        let name = ObjectProperty.name.description(in: objectID) ?? "<untitled @\(objectID)>"
        return Properties(classID: classID, name: name)
    }
}

final class ObjectTreeDataSource {
    
    private static func cmioChildren(for objectID: CMIOObjectID) -> [CMIOObjectID] {
        if let ownedObjects: [CMIOObjectID] = ObjectProperty.ownedObjects.arrayValue(in: objectID) {
            return ownedObjects
        }
        else if let classID: CMIOClassID = ObjectProperty.class.value(in: objectID),
            classID.isSubclass(of: .device),
            let streams: [CMIOStreamID] = DeviceProperty.streams.arrayValue(in: objectID) {
            return streams as [CMIOObjectID]
        }
        return []
    }
    
    let tree = CMIONode(objectID: .systemObject,
                        properties: Properties(classID: .system, name: "System"),
                        hierarchy: .custom(ObjectTreeDataSource.cmioChildren))
}
