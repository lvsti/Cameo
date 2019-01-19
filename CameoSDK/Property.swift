//
//  PropertyType.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 05..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO


public protocol QualifierProtocol {
    var data: UnsafeMutableRawPointer { get }
    var size: Int { get }
}

public class Qualifier<T>: QualifierProtocol {
    public let data: UnsafeMutableRawPointer
    public let size: Int
    
    public init(from scalar: T) {
        size = MemoryLayout<T>.size
        data = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<T>.alignment)
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        typedData.pointee = scalar
    }
    
    deinit {
        data.deallocate()
    }
}

public enum PropertyType {
    public enum Kind {
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

    public var kind: Kind {
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
    
    static func podTypeValue<T>(for address: CMIOObjectPropertyAddress,
                                qualifiedBy qualifier: QualifierProtocol? = nil,
                                in objectID: CMIOObjectID) -> T? {
        var address = address
        var dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        
        let status = CMIOObjectGetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &dataUsed, data)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        return typedData.pointee
    }

    static func podArrayTypeValue<T>(for address: CMIOObjectPropertyAddress,
                                     qualifiedBy qualifier: QualifierProtocol? = nil,
                                     in objectID: CMIOObjectID) -> [T]? {
        var address = address
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address,
                                                   UInt32(qualifier?.size ?? 0), qualifier?.data,
                                                   &dataSize)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        let count = Int(dataSize) / MemoryLayout<T>.size
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        
        status = CMIOObjectGetPropertyData(objectID, &address,
                                           UInt32(qualifier?.size ?? 0), qualifier?.data,
                                           dataSize, &dataUsed, data)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        let typedData = data.bindMemory(to: T.self, capacity: count)
        return UnsafeBufferPointer<T>(start: typedData, count: count).map { $0 }
    }

    static func cfTypeValue<T>(for address: CMIOObjectPropertyAddress,
                               qualifiedBy qualifier: QualifierProtocol? = nil,
                               in objectID: CMIOObjectID) -> T? {
        var address = address
        var dataSize: UInt32 = UInt32(MemoryLayout<CFTypeRef>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFTypeRef>.alignment)
        defer { data.deallocate() }
        
        let status = CMIOObjectGetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &dataUsed, data)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        let typedData = data.bindMemory(to: CFTypeRef.self, capacity: 1)
        return typedData.pointee as? T
    }

    static func cfArrayTypeValue<T>(for address: CMIOObjectPropertyAddress,
                                    qualifiedBy qualifier: QualifierProtocol? = nil,
                                    in objectID: CMIOObjectID) -> [T]? {
        var address = address
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address,
                                                   UInt32(qualifier?.size ?? 0), qualifier?.data,
                                                   &dataSize)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        let count = Int(dataSize) / MemoryLayout<CFTypeRef>.size
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFTypeRef>.alignment)
        defer { data.deallocate() }
        
        status = CMIOObjectGetPropertyData(objectID, &address,
                                           UInt32(qualifier?.size ?? 0), qualifier?.data,
                                           dataSize, &dataUsed, data)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        let typedData = data.bindMemory(to: CFTypeRef.self, capacity: count)
        return UnsafeBufferPointer<CFTypeRef>(start: typedData, count: count).compactMap { $0 as? T }
    }

    static func setPODTypeValue<T>(_ value: T,
                                   for address: CMIOObjectPropertyAddress,
                                   qualifiedBy qualifier: QualifierProtocol? = nil,
                                   in objectID: CMIOObjectID) -> Bool {
        var address = address
        let dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var value = value
        
        let status = CMIOObjectSetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &value)
        return status == kCMIOHardwareNoError
    }

    static func setCFTypeValue<T>(_ value: T,
                                  for address: CMIOObjectPropertyAddress,
                                  qualifiedBy qualifier: QualifierProtocol? = nil,
                                  in objectID: CMIOObjectID) -> Bool {
        var address = address
        let dataSize: UInt32 = UInt32(MemoryLayout<CFTypeRef>.size)
        var value = value as CFTypeRef
        
        let status = CMIOObjectSetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &value)
        return status == kCMIOHardwareNoError
    }

}

public extension CMIOObjectPropertyScope {
    static let global = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
    static let anyScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard)
    static let deviceInput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeInput)
    static let deviceOutput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeOutput)
    static let devicePlayThrough = CMIOObjectPropertyScope(kCMIODevicePropertyScopePlayThrough)
}

public extension CMIOObjectPropertyElement {
    static let master = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
    static let anyElement = CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
}


public extension CMIOObjectPropertyAddress {
    init(_ selector: CMIOObjectPropertySelector,
         _ scope: CMIOObjectPropertyScope = .anyScope,
         _ element: CMIOObjectPropertyElement = .anyElement) {
        self.init(mSelector: selector, mScope: scope, mElement: element)
    }
}

public protocol PropertySet {
    var selector: CMIOObjectPropertySelector { get }
    var type: PropertyType { get }
    
    static func allExisting(scope: CMIOObjectPropertyScope,
                            element: CMIOObjectPropertyElement,
                            in objectID: CMIOObjectID) -> [Self]
}

public extension PropertySet where Self : CaseIterable {
    static func allExisting(scope: CMIOObjectPropertyScope = .anyScope,
                            element: CMIOObjectPropertyElement = .anyElement,
                            in objectID: CMIOObjectID) -> [Self] {
        return allCases.filter { Property.exists($0, scope: scope, element: element, in: objectID) }
    }
}

public enum Property {
    public static func value<S, T>(of property: S,
                                   scope: CMIOObjectPropertyScope = .anyScope,
                                   element: CMIOObjectPropertyElement = .anyElement,
                                   qualifiedBy qualifier: QualifierProtocol? = nil,
                                   in objectID: CMIOObjectID) -> T? where S: PropertySet {
        let address = CMIOObjectPropertyAddress(property.selector, scope, element)
        
        switch property.type.kind {
        case .pod: return PropertyType.podTypeValue(for: address, qualifiedBy: qualifier, in: objectID)
        case .cf: return PropertyType.cfTypeValue(for: address, qualifiedBy: qualifier, in: objectID)
        default: return nil
        }
    }

    public static func arrayValue<S, T>(of property: S,
                                        scope: CMIOObjectPropertyScope = .anyScope,
                                        element: CMIOObjectPropertyElement = .anyElement,
                                        qualifiedBy qualifier: QualifierProtocol? = nil,
                                        in objectID: CMIOObjectID) -> [T]? where S: PropertySet {
        let address = CMIOObjectPropertyAddress(property.selector, scope, element)

        switch property.type.kind {
        case .podArray: return PropertyType.podArrayTypeValue(for: address, qualifiedBy: qualifier, in: objectID)
        case .cfArray: return PropertyType.cfArrayTypeValue(for: address, qualifiedBy: qualifier, in: objectID)
        default: return nil
        }
    }
    
    public static func isSettable<S>(_ property: S,
                                     scope: CMIOObjectPropertyScope = .anyScope,
                                     element: CMIOObjectPropertyElement = .anyElement,
                                     in objectID: CMIOObjectID) -> Bool where S: PropertySet {
        var address = CMIOObjectPropertyAddress(property.selector, scope, element)

        var isSettable: DarwinBoolean = false
        
        let status = CMIOObjectIsPropertySettable(objectID, &address, &isSettable)
        guard status == kCMIOHardwareNoError else {
            return false
        }
        
        return isSettable.boolValue
    }
    
    public static func exists<S>(_ property: S,
                                 scope: CMIOObjectPropertyScope = .anyScope,
                                 element: CMIOObjectPropertyElement = .anyElement,
                                 in objectID: CMIOObjectID) -> Bool where S: PropertySet {
        var address = CMIOObjectPropertyAddress(property.selector, scope, element)

        return CMIOObjectHasProperty(objectID, &address)
    }
    
    public static func setValue<S, T>(_ value: T,
                                      for property: S,
                                      scope: CMIOObjectPropertyScope = .anyScope,
                                      element: CMIOObjectPropertyElement = .anyElement,
                                      qualifiedBy qualifier: QualifierProtocol? = nil,
                                      in objectID: CMIOObjectID) -> Bool where S: PropertySet {
        let address = CMIOObjectPropertyAddress(property.selector, scope, element)

        switch property.type.kind {
        case .pod: return PropertyType.setPODTypeValue(value, for: address, qualifiedBy: qualifier, in: objectID)
        case .cf: return PropertyType.setCFTypeValue(value, for: address, qualifiedBy: qualifier, in: objectID)
        default: return false
        }
    }
}
