//
//  Control.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 06..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

struct BooleanControlModel {
    var controlID: CMIOObjectID = CMIOObjectID(kCMIOObjectUnknown)
    var name: String = ""
    var value: Bool = false
}

struct SelectorControlModel {
    var controlID: CMIOObjectID = CMIOObjectID(kCMIOObjectUnknown)
    var name: String = ""
    var items: [(UInt32, String)] = []
    var currentItemID: UInt32 = 0
    var currentItemIndex: Int? {
        return items.firstIndex(where: { $0.0 == currentItemID })
    }
}

struct FeatureControlModel {
    var controlID: CMIOObjectID = CMIOObjectID(kCMIOObjectUnknown)
    var name: String = ""
    var isEnabled: Bool = false
    var isAutomatic: Bool = false
    var isTuning: Bool = false
    var isInAbsoluteUnits: Bool = false
    var minValue: Float = 0
    var maxValue: Float = 0
    var currentValue: Float = 0
    var unitName: String?
}

enum ControlModel {
    case boolean(BooleanControlModel)
    case selector(SelectorControlModel)
    case feature(FeatureControlModel)
}

enum CMIOError: Error {
    case unknown
}

enum Control {
    static func model(for controlID: CMIOObjectID) -> ControlModel? {
        guard
            let classID: CMIOClassID = Property.value(of: ObjectProperty.class, in: controlID),
            let name: String = Property.value(of: ObjectProperty.name, in: controlID)
        else {
            return nil
        }
        
        if classID.isSubclass(of: CMIOClassID(kCMIOBooleanControlClassID)) {
            guard
                let value: UInt32 = Property.value(of: BooleanControlProperty.value, in: controlID)
            else {
                return nil
            }
            
            return .boolean(BooleanControlModel(controlID: controlID, name: name, value: value != 0))
        }
        else if classID.isSubclass(of: CMIOClassID(kCMIOSelectorControlClassID)) {
            guard
                let itemIDs: [UInt32] = Property.arrayValue(of: SelectorControlProperty.availableItems, in: controlID),
                let items: [(UInt32, String)] = try? itemIDs.map({
                    guard let itemName: String = Property.value(of: SelectorControlProperty.itemName,
                                                                qualifiedBy: Qualifier(from: $0),
                                                                in: controlID)
                    else {
                        throw CMIOError.unknown
                    }
                    return ($0, itemName)
                }),
                let currentItemID: UInt32 = Property.value(of: SelectorControlProperty.currentItem, in: controlID)
            else {
                return nil
            }

            return .selector(SelectorControlModel(controlID: controlID,
                                                  name: name,
                                                  items: items,
                                                  currentItemID: currentItemID))
        }
        else if classID.isSubclass(of: CMIOClassID(kCMIOFeatureControlClassID)) {
            guard
                let isEnabled: UInt32 = Property.value(of: FeatureControlProperty.onOff, in: controlID),
                let isAutomatic: UInt32 = Property.value(of: FeatureControlProperty.automaticManual, in: controlID),
                let isInAbsoluteUnits: UInt32 = Property.value(of: FeatureControlProperty.absoluteNative, in: controlID),
                let isTuning: UInt32 = Property.value(of: FeatureControlProperty.tune, in: controlID)
            else {
                return nil
            }
            
            var model = FeatureControlModel()
            model.controlID = controlID
            model.name = name
            model.isEnabled = isEnabled != 0
            model.isAutomatic = isAutomatic != 0
            model.isInAbsoluteUnits = isInAbsoluteUnits != 0
            model.isTuning = isTuning != 0
            
            if isInAbsoluteUnits != 0 {
                guard
                    let unitName: String = Property.value(of: FeatureControlProperty.absoluteUnitName, in: controlID),
                    let range: AudioValueRange = Property.value(of: FeatureControlProperty.absoluteRange, in: controlID),
                    let currentValue: Float = Property.value(of: FeatureControlProperty.absoluteValue, in: controlID)
                else {
                    return nil
                }
                model.unitName = unitName
                model.minValue = Float(range.mMinimum)
                model.maxValue = Float(range.mMaximum)
                model.currentValue = currentValue
            }
            else {
                guard
                    let range: AudioValueRange = Property.value(of: FeatureControlProperty.nativeRange, in: controlID),
                    let currentValue: Float = Property.value(of: FeatureControlProperty.nativeValue, in: controlID)
                else {
                    return nil
                }
                model.minValue = Float(range.mMinimum)
                model.maxValue = Float(range.mMaximum)
                model.currentValue = currentValue
            }

            return .feature(model)
        }
        else {
            return nil
        }
    }
}

