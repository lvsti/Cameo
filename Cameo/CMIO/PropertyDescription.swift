//
//  PropertyDescription.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 19..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
import CMIOKit

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

        if case .audioValueTranslation = type {
            if case .translation(let srcType, let dstType) = readSemantics {
                return "<function: (\(srcType)) -> \(dstType)>"
            }
            return "<function>"
        }
        guard let propertyValue = value(scope: scope, element: element, qualifiedBy: qualifier, in: objectID) else {
            return nil
        }
        
        switch propertyValue {
        case .boolean(let v): return "\(v)"
        case .int32(let v): return "\(v)"
        case .uint32(let v): return "\(v)"
        case .uint64(let v): return "\(v)"
        case .float32(let v): return "\(v)"
        case .float64(let v): return "\(v)"
        case .pid(let v): return "\(v)"
        case .arrayOfUInt32s(let v): return "\(v)"
        case .arrayOfFloat64s(let v): return "\(v)"
        case .string(let v): return "\(v)"
        case .formatDescription(let v): return "\(v)"
        case .sampleBuffer(let v): return "\(v)"
        case .clock(let v): return "\(v)"
        case .boolean32(let v): return v != 0 ? "true (\(v))" : "false (0)"
        case .classID(let v), .fourCC(let v), .propertyScope(let v), .propertyElement(let v):
            if let fcc = fourCCDescription(from: v) {
                return fcc
            }
            return "\(v)"
        case .objectID(let v): return v != .unknown ? "@\(v)" : "<null>"
        case .audioValueRange(let v):
            return "AudioValueRange {\(v.mMinimum), \(v.mMaximum)}"
        case .propertyAddress(let v):
            return "CMIOObjectPropertyAddress {\(fourCCDescription(from: v.mSelector)!), " +
                "\(fourCCDescription(from: v.mScope)!), \(fourCCDescription(from: v.mElement)!)"
        case .streamConfiguration(let v):
            return "[" + v.map { "\($0)" }.joined(separator: ", ") + "]"
        case .time(let v):
            return "CMTime {\(v.value) / \(v.timescale)}"
        case .rect(let v):
            return "CGRect {{\(v.minX), \(v.minY)}, {\(v.width), \(v.height)}}"
        case .streamDeck(let v):
            return "CMIOStreamDeck {\(v.mStatus), \(v.mState), \(v.mState2)}"
        case .smpteCallback(let v):
            if v.mGetSMPTETimeProc != nil {
                let ctx = v.mRefCon != nil ? "\(v.mRefCon!)" : "0x0"
                return "CMIODeviceSMPTETimeCallback {proc=\(v.mGetSMPTETimeProc!), ctx=\(ctx)}"
            }
            else {
                return "<null>"
            }
        case .scheduledOutputCallback(let v):
            if v.scheduledOutputNotificationProc != nil {
                let ctx = v.scheduledOutputNotificationRefCon != nil ? "\(v.scheduledOutputNotificationRefCon!)" : "0x0"
                return "CMIOStreamScheduledOutputNotificationProcAndRefCon {proc=\(v.scheduledOutputNotificationProc!), ctx=\(ctx)"
            }
            else {
                return "<null>"
            }
        case .arrayOfObjectIDs(let v):
            return "[" + v.map { $0 != .unknown ? "@\($0)" : "<null>" }.joined(separator: ", ") + "]"
        case .arrayOfAudioValueRanges(let v):
            return "[" + v.map { "AudioValueRange {\($0.mMinimum), \($0.mMaximum)}" }.joined(separator: ", ") + "]"
        case .arrayOfFormatDescriptions(let v):
            return "[" + v.map { "\($0)" }.joined(separator: ", ") + "]"
#if NEEDS_VIDEO_DIGITIZER_COMPONENTS
        case .arrayOfComponentDescriptions:
            return "\(value)"
#endif
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
        case .objectID:
            if let value: CMIOObjectID = getTranslatedValue() {
                return value != .unknown ? "@\(value)" : "<null>"
            }
        default:
            break
        }

        return nil
    }
}
