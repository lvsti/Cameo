//
//  PropertyDescription.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 19..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
import CameoSDK

func fourCC(from value: UInt32) -> String? {
    let chars: [UInt8] = [
        UInt8((value >> 24) & 0xff),
        UInt8((value >> 16) & 0xff),
        UInt8((value >> 8) & 0xff),
        UInt8(value & 0xff)
    ]
    return String(bytes: chars, encoding: .ascii)
}

func fourCCDescription(from value: UInt32) -> String? {
    guard let fcc = fourCC(from: value) else {
        return nil
    }
    
    if let entry = FourCCDatabase.shared.entry(forValue: Int(value)) {
        return "'\(fcc)' (\(entry.constantName))"
    }
    
    return "'\(fcc)'"
}


extension Property {
    func description(scope: CMIOObjectPropertyScope = .anyScope,
                     element: CMIOObjectPropertyElement = .anyElement,
                     qualifiedBy qualifier: QualifierProtocol? = nil,
                     in objectID: CMIOObjectID) -> String? {

        func getValue<T>() -> T? {
            return value(scope: scope, element: element, qualifiedBy: qualifier, in: objectID)
        }

        func getArrayValue<T>() -> [T]? {
            return arrayValue(scope: scope, element: element, qualifiedBy: qualifier, in: objectID)
        }

        switch type {
        case .boolean:
            if let value: DarwinBoolean = getValue() {
                return "\(value)"
            }
        case .boolean32:
            if let value: UInt32 = getValue() {
                return value != 0 ? "true (\(value))" : "false (0)"
            }
        case .int32, .uint32:
            if let value: UInt32 = getValue() {
                return "\(value)"
            }
        case .uint64:
            if let value: UInt64 = getValue() {
                return "\(value)"
            }
        case .float32:
            if let value: Float32 = getValue() {
                return "\(value)"
            }
        case .float64:
            if let value: Float64 = getValue() {
                return "\(value)"
            }
        case .fourCC, .classID:
            if let value: CMIOClassID = getValue() {
                if let fcc = fourCCDescription(from: value) {
                    return "\(fcc)"
                }
                return "\(value)"
            }
        case .objectID, .deviceID:
            if let value: CMIOObjectID = getValue() {
                return value != kCMIOObjectUnknown ? "@\(value)" : "<null>"
            }
        case .audioValueTranslation:
            if case .translation(let srcType, let dstType) = readSemantics {
                return "<function: (\(srcType)) -> \(dstType)>"
            }
            return "<function>"
        case .audioValueRange:
            if let value: AudioValueRange = getValue() {
                return "AudioValueRange {\(value.mMinimum), \(value.mMaximum)}"
            }
        case .propertyAddress:
            if let value: CMIOObjectPropertyAddress = getValue() {
                return "CMIOObjectPropertyAddress {\(fourCCDescription(from: value.mSelector)!), " +
                "\(fourCCDescription(from: value.mScope)!), \(fourCCDescription(from: value.mElement)!)"
            }
        case .streamConfiguration:
            if let value: [UInt32] = getArrayValue() {
                return "[" + value.dropFirst().map { "\($0)" }.joined(separator: ", ") + "]"
            }
        case .pid:
            if let value: pid_t = getValue() {
                return "\(value)"
            }
//    case .componentDescription:
//        if let value: ComponentDescription = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
//            return "\(value)"
//        }
        case .time:
            if let value: CMTime = getValue() {
                return "CMTime {\(value.value) / \(value.timescale)}"
            }
        case .cgRect:
            if let value: CGRect = getValue() {
                return "CGRect {{\(value.origin.x), \(value.origin.y)}, {\(value.size.width), \(value.size.height)}}"
            }
        case .streamDeck:
            if let value: CMIOStreamDeck = getValue() {
                return "CMIOStreamDeck {\(value.mStatus), \(value.mState), \(value.mState2)}"
            }
        case .smpteCallback:
            if let value: CMIODeviceSMPTETimeCallback = getValue() {
                if value.mGetSMPTETimeProc != nil {
                    let ctx = value.mRefCon != nil ? "\(value.mRefCon!)" : "0x0"
                    return "CMIODeviceSMPTETimeCallback {proc=\(value.mGetSMPTETimeProc!), ctx=\(ctx)}"
                }
                else {
                    return "<null>"
                }
            }
        case .scheduledOutputCallback:
            if let value: CMIOStreamScheduledOutputNotificationProcAndRefCon = getValue() {
                if value.scheduledOutputNotificationProc != nil {
                    let ctx = value.scheduledOutputNotificationRefCon != nil ? "\(value.scheduledOutputNotificationRefCon!)" : "0x0"
                    return "CMIOStreamScheduledOutputNotificationProcAndRefCon {proc=\(value.scheduledOutputNotificationProc!), ctx=\(ctx)"
                }
                else {
                    return "<null>"
                }
            }
            
        case .arrayOfUInt32s:
            if let value: [UInt32] = getArrayValue() {
                return "\(value)"
            }
        case .arrayOfFloat64s:
            if let value: [Float64] = getArrayValue() {
                return "\(value)"
            }
        case .arrayOfDeviceIDs, .arrayOfObjectIDs, .arrayOfStreamIDs:
            if let value: [CMIOObjectID] = getArrayValue() {
                return "[" + value.map { $0 != kCMIOObjectUnknown ? "@\($0)" : "<null>" }.joined(separator: ", ") + "]"
            }
        case .arrayOfAudioValueRanges:
            if let value: [AudioValueRange] = getArrayValue() {
                return "[" + value.map { "AudioValueRange {\($0.mMinimum), \($0.mMaximum)}" }.joined(separator: ", ") + "]"
            }
            
        case .string:
            if let value: CFString = getValue() {
                return "\(value)"
            }
        case .formatDescription:
            if let value: CMFormatDescription = getValue() {
                return "\(value)"
            }
        case .sampleBuffer:
            if let value: CMSampleBuffer = getValue() {
                return "\(value)"
            }
        case .clock:
            if let value: CFTypeRef = getValue() {
                return "\(value)"
            }
            
        case .arrayOfFormatDescriptions:
            if let value: [CMFormatDescription] = getArrayValue() {
                return "[" + value.map { "\($0)" }.joined(separator: ", ") + "]"
            }
            
        default:
            break
        }
        
        return nil
    }
    
    func descriptionForTranslating<T>(_ value: T,
                                      scope: CMIOObjectPropertyScope = .anyScope,
                                      element: CMIOObjectPropertyElement = .anyElement,
                                      in objectID: CMIOObjectID) -> String? {
        guard case .translation(let fromType, let toType) = readSemantics else {
            return nil
        }
        
        func getTranslatedValue<U>() -> U? {
            switch fromType {
            case .string:
                return translateValue(value as! CFString,
                                      scope: scope,
                                      element: element,
                                      in: objectID)
            default:
                break
            }
            return nil
        }

        switch toType {
        case .objectID, .deviceID:
            if let value: CMIOObjectID = getTranslatedValue() {
                return value != kCMIOObjectUnknown ? "@\(value)" : "<null>"
            }
        default:
            break
        }

        return nil
    }
}
