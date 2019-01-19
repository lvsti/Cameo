//
//  PropertyListDataSource.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 19..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
import CameoSDK

struct PropertyListItem {
    var selector: CMIOObjectPropertySelector
    var name: String
    var isSettable: Bool
    var value: String
    var fourCC: UInt32?
}

class PropertyListDataSource {
    private(set) var items: [PropertyListItem] = []
    
    func reload(forNode node: CMIONode?, scope: CMIOObjectPropertyScope) {
        items.removeAll()
        
        guard let node = node else {
            return
        }
        
        items.append(PropertyListItem(selector: CMIOObjectPropertySelector(kCMIOObjectPropertyScopeWildcard),
                                      name: "objectID",
                                      isSettable: false,
                                      value: "@\(node.objectID)",
                                      fourCC: nil))

        items.append(contentsOf: properties(from: ObjectProperty.self, scope: scope, in: node.objectID))

        if node.classID.isSubclass(of: .device) {
            items.append(contentsOf: properties(from: DeviceProperty.self, scope: scope, in: node.objectID))
        }
        else if node.classID.isSubclass(of: .stream) {
            items.append(contentsOf: properties(from: StreamProperty.self, scope: scope, in: node.objectID))
        }
        else if node.classID.isSubclass(of: .control) {
            items.append(contentsOf: properties(from: ControlProperty.self, scope: scope, in: node.objectID))
            
            if node.classID.isSubclass(of: .booleanControl) {
                items.append(contentsOf: properties(from: BooleanControlProperty.self, scope: scope, in: node.objectID))
            }
            else if node.classID.isSubclass(of: .selectorControl) {
                items.append(contentsOf: properties(from: SelectorControlProperty.self, scope: scope, in: node.objectID))
            }
            else if node.classID.isSubclass(of: .featureControl) {
                items.append(contentsOf: properties(from: FeatureControlProperty.self, scope: scope, in: node.objectID))
                
                if node.classID.isSubclass(of: .exposureControl) {
                    items.append(contentsOf: properties(from: ExposureControlProperty.self, scope: scope, in: node.objectID))
                }
            }
        }
        else if node.classID == .systemObject {
            items.append(contentsOf: properties(from: SystemProperty.self, scope: scope, in: node.objectID))
        }
    }
    
    private func properties<S>(from type: S.Type,
                               scope: CMIOObjectPropertyScope,
                               in objectID: CMIOObjectID) -> [PropertyListItem] where S: PropertySet {
        var propertyList: [PropertyListItem] = []
        let props = S.allExisting(scope: scope,
                                  element: .anyElement,
                                  in: objectID)
        for prop in props {
            let isFourCC = prop.type == .fourCC || prop.type == .classID
            let item = PropertyListItem(selector: prop.selector,
                                        name: "\(prop)",
                                        isSettable: Property.isSettable(prop, scope: scope, in: objectID),
                                        value: Property.description(of: prop, scope: scope, in: objectID) ?? "#ERROR",
                                        fourCC: isFourCC ? Property.value(of: prop, scope: scope, in: objectID) : nil)
            propertyList.append(item)
        }
        return propertyList
    }
    
}
