//
//  PropertyType.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 05..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO


protocol QualifierProtocol {
    var data: UnsafeMutableRawPointer { get }
    var size: Int { get }
}

class Qualifier<T>: QualifierProtocol {
    let data: UnsafeMutableRawPointer
    let size: Int
    
    init(from scalar: T) {
        size = MemoryLayout<T>.size
        data = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<T>.alignment)
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        typedData.pointee = scalar
    }
    
    deinit {
        data.deallocate()
    }
}

enum PropertyType {
    enum Kind {
        case pod, podArray, cf, cfArray, function
    }
    
    case boolean, boolean32, int32, uint32, uint64, float32, float64, fourCC,
        classID, objectID, deviceID,
        audioValueRange, propertyAddress, streamConfiguration, streamDeck,
        pid,
        smpteCallback, scheduledOutputCallback,
        componentDescription, time, cgRect
    case arrayOfDeviceIDs, arrayOfObjectIDs, arrayOfStreamIDs, arrayOfUInt32s, arrayOfFloat64s, arrayOfAudioValueRanges
    case string, formatDescription, sampleBuffer, clock
    case arrayOfFormatDescriptions
    case audioValueTranslation

    var kind: Kind {
        switch self {
        case .boolean, .boolean32, .int32, .uint32, .uint64, .float32, .float64, .fourCC,
             .classID, .objectID, .deviceID,
             .audioValueRange, .propertyAddress, .streamConfiguration, .streamDeck,
             .pid,
             .smpteCallback, .scheduledOutputCallback,
             .componentDescription, .time, .cgRect:
            return .pod
        case .arrayOfDeviceIDs, .arrayOfObjectIDs, .arrayOfStreamIDs, .arrayOfUInt32s, .arrayOfFloat64s, .arrayOfAudioValueRanges:
            return .podArray
        case .string, .formatDescription, .sampleBuffer, .clock:
            return .cf
        case .arrayOfFormatDescriptions:
            return .cfArray
        case .audioValueTranslation:
            return .function
        }
    }
    
    static func podTypeValue<T>(for selector: CMIOObjectPropertySelector,
                                qualifiedBy qualifier: QualifierProtocol? = nil,
                                in objectID: CMIOObjectID) -> T? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        
        let status = CMIOObjectGetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        return typedData.pointee
    }

    static func podArrayTypeValue<T>(for selector: CMIOObjectPropertySelector,
                                     qualifiedBy qualifier: QualifierProtocol? = nil,
                                     in objectID: CMIOObjectID) -> [T]? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address,
                                                   UInt32(qualifier?.size ?? 0), qualifier?.data,
                                                   &dataSize)
        guard status == 0 else {
            return nil
        }
        
        let count = Int(dataSize) / MemoryLayout<T>.size
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        
        status = CMIOObjectGetPropertyData(objectID, &address,
                                           UInt32(qualifier?.size ?? 0), qualifier?.data,
                                           dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: T.self, capacity: count)
        return UnsafeBufferPointer<T>(start: typedData, count: count).map { $0 }
    }

    static func cfTypeValue<T>(for selector: CMIOObjectPropertySelector,
                               qualifiedBy qualifier: QualifierProtocol? = nil,
                               in objectID: CMIOObjectID) -> T? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = UInt32(MemoryLayout<CFTypeRef>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFTypeRef>.alignment)
        defer { data.deallocate() }
        
        let status = CMIOObjectGetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: CFTypeRef.self, capacity: 1)
        return typedData.pointee as? T
    }

    static func cfArrayTypeValue<T>(for selector: CMIOObjectPropertySelector,
                                    qualifiedBy qualifier: QualifierProtocol? = nil,
                                    in objectID: CMIOObjectID) -> [T]? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address,
                                                   UInt32(qualifier?.size ?? 0), qualifier?.data,
                                                   &dataSize)
        guard status == 0 else {
            return nil
        }
        
        let count = Int(dataSize) / MemoryLayout<CFTypeRef>.size
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFTypeRef>.alignment)
        defer { data.deallocate() }
        
        status = CMIOObjectGetPropertyData(objectID, &address,
                                           UInt32(qualifier?.size ?? 0), qualifier?.data,
                                           dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: CFTypeRef.self, capacity: count)
        return UnsafeBufferPointer<CFTypeRef>(start: typedData, count: count).compactMap { $0 as? T }
    }

}


extension CMIOObjectPropertyAddress {
    init(_ selector: CMIOObjectPropertySelector) {
        self.init(mSelector: selector,
                  mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                  mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster))
    }
}

struct PropertyDescriptor {
    var selector: CMIOObjectPropertySelector
    var type: PropertyType
    
    init(_ selector: Int, _ type: PropertyType) {
        self.selector = CMIOObjectPropertySelector(selector)
        self.type = type
    }
}


protocol PropertySet: CaseIterable, Hashable {
    static var descriptors: [Self: PropertyDescriptor] { get }
    static func allExisting(in objectID: CMIOObjectID) -> [Self]
}

extension PropertySet {
    static func allExisting(in objectID: CMIOObjectID) -> [Self] {
        return allCases.filter { Property.exists($0, in: objectID) }
    }
}


enum Property {
    static func value<S, T>(of property: S,
                            qualifiedBy qualifier: QualifierProtocol? = nil,
                            in objectID: CMIOObjectID) -> T? where S: PropertySet {
        let desc = S.descriptors[property]!
        switch desc.type.kind {
        case .pod: return PropertyType.podTypeValue(for: desc.selector, qualifiedBy: qualifier, in: objectID)
        case .cf: return PropertyType.cfTypeValue(for: desc.selector, qualifiedBy: qualifier, in: objectID)
        default: return nil
        }
    }

    static func arrayValue<S, T>(of property: S,
                                 qualifiedBy qualifier: QualifierProtocol? = nil,
                                 in objectID: CMIOObjectID) -> [T]? where S: PropertySet {
        let desc = S.descriptors[property]!
        switch desc.type.kind {
        case .podArray: return PropertyType.podArrayTypeValue(for: desc.selector, qualifiedBy: qualifier, in: objectID)
        case .cfArray: return PropertyType.cfArrayTypeValue(for: desc.selector, qualifiedBy: qualifier, in: objectID)
        default: return nil
        }
    }
    
    static func description<S>(of property: S,
                               qualifiedBy qualifier: QualifierProtocol? = nil,
                               in objectID: CMIOObjectID) -> String? where S: PropertySet {
        let desc = S.descriptors[property]!
        return propertyDescription(for: desc.selector, ofType: desc.type, qualifiedBy: qualifier, in: objectID)
    }
    
    static func isSettable<S>(_ property: S, in objectID: CMIOObjectID) -> Bool where S: PropertySet {
        let desc = S.descriptors[property]!
        
        var isSettable: DarwinBoolean = false
        var address = CMIOObjectPropertyAddress(desc.selector)
        
        let status = CMIOObjectIsPropertySettable(objectID, &address, &isSettable)
        guard status == 0 else {
            return false
        }
        
        return isSettable.boolValue
    }
    
    static func exists<S>(_ property: S, in objectID: CMIOObjectID) -> Bool where S: PropertySet {
        let desc = S.descriptors[property]!
        var address = CMIOObjectPropertyAddress(desc.selector)
        
        return CMIOObjectHasProperty(objectID, &address)
    }
}


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


func propertyDescription(for selector: CMIOObjectPropertySelector,
                         ofType type: PropertyType,
                         qualifiedBy qualifier: QualifierProtocol? = nil,
                         in objectID: CMIOObjectID) -> String? {
    switch type {
    case .boolean:
        if let value: DarwinBoolean = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .boolean32:
        if let value: UInt32 = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return value != 0 ? "true (\(value))" : "false (0)"
        }
    case .int32, .uint32:
        if let value: UInt32 = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .uint64:
        if let value: UInt64 = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .float32:
        if let value: Float32 = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .float64:
        if let value: Float64 = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .fourCC, .classID:
        if let value: CMIOClassID = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            if let fcc = fourCCDescription(from: value) {
                return "\(fcc)"
            }
            return "\(value)"
        }
    case .objectID, .deviceID:
        if let value: CMIOObjectID = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return value != kCMIOObjectUnknown ? "@\(value)" : "<null>"
        }
    case .audioValueTranslation:
        return "<function>"
    case .audioValueRange:
        if let value: AudioValueRange = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "AudioValueRange {\(value.mMinimum), \(value.mMaximum)}"
        }
    case .propertyAddress:
        if let value: CMIOObjectPropertyAddress = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "CMIOObjectPropertyAddress {\(fourCCDescription(from: value.mSelector)!), " +
            "\(fourCCDescription(from: value.mScope)!), \(fourCCDescription(from: value.mElement)!)"
        }
    case .streamConfiguration:
        if let value: CMIODeviceStreamConfiguration = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "CMIODeviceStreamConfiguration {\(value.mNumberStreams)}"
        }
    case .pid:
        if let value: pid_t = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
//    case .componentDescription:
//        if let value: ComponentDescription = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
//            return "\(value)"
//        }
    case .time:
        if let value: CMTime = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "CMTime {\(value.value) / \(value.timescale)}"
        }
    case .cgRect:
        if let value: CGRect = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "CGRect {{\(value.origin.x), \(value.origin.y)}, {\(value.size.width), \(value.size.height)}}"
        }
    case .streamDeck:
        if let value: CMIOStreamDeck = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "CMIOStreamDeck {\(value.mStatus), \(value.mState), \(value.mState2)}"
        }
    case .smpteCallback:
        if let value: CMIODeviceSMPTETimeCallback = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            if value.mGetSMPTETimeProc != nil {
                let ctx = value.mRefCon != nil ? "\(value.mRefCon!)" : "0x0"
                return "CMIODeviceSMPTETimeCallback {proc=\(value.mGetSMPTETimeProc!), ctx=\(ctx)}"
            }
            else {
                return "<null>"
            }
        }
    case .scheduledOutputCallback:
        if let value: CMIOStreamScheduledOutputNotificationProcAndRefCon = PropertyType.podTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            if value.scheduledOutputNotificationProc != nil {
                let ctx = value.scheduledOutputNotificationRefCon != nil ? "\(value.scheduledOutputNotificationRefCon!)" : "0x0"
                return "CMIOStreamScheduledOutputNotificationProcAndRefCon {proc=\(value.scheduledOutputNotificationProc!), ctx=\(ctx)"
            }
            else {
                return "<null>"
            }
        }
        
    case .arrayOfUInt32s:
        if let value: [UInt32] = PropertyType.podArrayTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .arrayOfFloat64s:
        if let value: [Float64] = PropertyType.podArrayTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .arrayOfDeviceIDs, .arrayOfObjectIDs, .arrayOfStreamIDs:
        if let value: [CMIOObjectID] = PropertyType.podArrayTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "[" + value.map { $0 != kCMIOObjectUnknown ? "@\($0)" : "<null>" }.joined(separator: ", ") + "]"
        }
    case .arrayOfAudioValueRanges:
        if let value: [AudioValueRange] = PropertyType.podArrayTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "[" + value.map { "AudioValueRange {\($0.mMinimum), \($0.mMaximum)}" }.joined(separator: ", ") + "]"
        }
        
    case .string:
        if let value: CFString = PropertyType.cfTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .formatDescription:
        if let value: CMFormatDescription = PropertyType.cfTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .sampleBuffer:
        if let value: CMSampleBuffer = PropertyType.cfTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
    case .clock:
        if let value: CFTypeRef = PropertyType.cfTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "\(value)"
        }
        
    case .arrayOfFormatDescriptions:
        if let value: [CMFormatDescription] = PropertyType.cfArrayTypeValue(for: selector, qualifiedBy: qualifier, in: objectID) {
            return "[" + value.map { "\($0)" }.joined(separator: ", ") + "]"
        }
        
    default:
        break
    }
    return nil
}
