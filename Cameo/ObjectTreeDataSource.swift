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
        var classID = CMIOClassID.object
        if case .classID(let v) = ObjectProperty.class.value(in: objectID) {
            classID = v
        }

        let name = ObjectProperty.name.description(in: objectID) ?? "<untitled @\(objectID)>"
        return Properties(classID: classID, name: name)
    }
}

final class ObjectTreeDataSource {
    
    private static func cmioChildren(for objectID: CMIOObjectID) -> [CMIOObjectID] {
        if case .arrayOfObjectIDs(let ownedObjects) = ObjectProperty.ownedObjects.value(in: objectID) {
            return ownedObjects
        }
        else if case .classID(let classID) = ObjectProperty.class.value(in: objectID),
            classID.isSubclass(of: .device),
            case .arrayOfObjectIDs(let streams) = DeviceProperty.streams.value(in: objectID) {
            return streams
        }
        return []
    }
    
    let tree = CMIONode(objectID: .systemObject,
                        properties: Properties(classID: .system, name: "System"),
                        hierarchy: .custom(ObjectTreeDataSource.cmioChildren))
}
