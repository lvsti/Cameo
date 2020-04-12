//
//  Control.swift
//  CMIOKit
//
//  Created by Tamás Lustyik on 2019. 01. 06..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

public struct BooleanControlModel {
    public var controlID: CMIOObjectID = .unknown
    public var name: String = ""
    public var value: Bool = false
}

public struct SelectorControlModel {
    public var controlID: CMIOObjectID = .unknown
    public var name: String = ""
    public var items: [(UInt32, String)] = []
    public var currentItemID: UInt32 = 0
    public var currentItemIndex: Int? {
        return items.firstIndex(where: { $0.0 == currentItemID })
    }
}

public struct FeatureControlModel {
    public var controlID: CMIOObjectID = .unknown
    public var name: String = ""
    public var isEnabled: Bool = false
    public var isAutomatic: Bool = false
    public var isTuning: Bool = false
    public var isInAbsoluteUnits: Bool = false
    public var minValue: Float = 0
    public var maxValue: Float = 0
    public var currentValue: Float = 0
    public var unitName: String?
}

public enum ControlModel {
    case boolean(BooleanControlModel)
    case selector(SelectorControlModel)
    case feature(FeatureControlModel)
}

enum CMIOError: Error {
    case unknown
}

public enum Control {
    public static func model(for controlID: CMIOObjectID) -> ControlModel? {
        guard
            case .classID(let classID) = ObjectProperty.class.value(in: controlID),
            case .string(let name) = ObjectProperty.name.value(in: controlID)
        else {
            return nil
        }
        
        if classID.isSubclass(of: .booleanControl) {
            guard case .boolean(let value) = BooleanControlProperty.value.value(in: controlID) else {
                return nil
            }
            
            return .boolean(BooleanControlModel(controlID: controlID, name: name, value: value))
        }
        else if classID.isSubclass(of: .selectorControl) {
            guard
                case .arrayOfUInt32s(let itemIDs) = SelectorControlProperty.availableItems.value(in: controlID),
                let items: [(UInt32, String)] = try? itemIDs.map({
                    guard case .string(let itemName) = SelectorControlProperty.itemName.value(qualifiedBy: Qualifier(from: $0),
                                                                                              in: controlID)
                    else {
                        throw CMIOError.unknown
                    }
                    return ($0, itemName)
                }),
                case .uint32(let currentItemID) = SelectorControlProperty.currentItem.value(in: controlID)
            else {
                return nil
            }

            return .selector(SelectorControlModel(controlID: controlID,
                                                  name: name,
                                                  items: items,
                                                  currentItemID: currentItemID))
        }
        else if classID.isSubclass(of: .featureControl) {
            guard
                case .boolean(let isEnabled) = FeatureControlProperty.onOff.value(in: controlID),
                case .boolean(let isAutomatic) = FeatureControlProperty.automaticManual.value(in: controlID),
                case .boolean(let isInAbsoluteUnits) = FeatureControlProperty.absoluteNative.value(in: controlID),
                case .boolean(let isTuning) = FeatureControlProperty.tune.value(in: controlID)
            else {
                return nil
            }
            
            var model = FeatureControlModel()
            model.controlID = controlID
            model.name = name
            model.isEnabled = isEnabled
            model.isAutomatic = isAutomatic
            model.isInAbsoluteUnits = isInAbsoluteUnits
            model.isTuning = isTuning
            
            if isInAbsoluteUnits {
                guard
                    case .string(let unitName) = FeatureControlProperty.absoluteUnitName.value(in: controlID),
                    case .audioValueRange(let range) = FeatureControlProperty.absoluteRange.value(in: controlID),
                    case .float32(let currentValue) = FeatureControlProperty.absoluteValue.value(in: controlID)
                else {
                    return nil
                }
                model.unitName = unitName
                model.minValue = Float(range.mMinimum)
                model.maxValue = Float(range.mMaximum)
                model.currentValue = Float(currentValue)
            }
            else {
                guard
                    case .audioValueRange(let range) = FeatureControlProperty.nativeRange.value(in: controlID),
                    case .float32(let currentValue) = FeatureControlProperty.nativeValue.value(in: controlID)
                else {
                    return nil
                }
                model.minValue = Float(range.mMinimum)
                model.maxValue = Float(range.mMaximum)
                model.currentValue = Float(currentValue)
            }

            return .feature(model)
        }
        else {
            return nil
        }
    }
}
