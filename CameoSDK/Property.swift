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

public enum PropertyReadSemantics {
    case read, translation(PropertyType, PropertyType), optionallyQualifiedRead(PropertyType), qualifiedRead(PropertyType)
}

public enum PropertyType {
    public enum Kind {
        case pod, podArray, cf, cfArray
    }
    
    case boolean, boolean32, int32, uint32, uint64, float32, float64, fourCC,
        classID, objectID, deviceID,
        audioValueRange, propertyAddress, streamConfiguration, streamDeck,
        pid,
        smpteCallback, scheduledOutputCallback,
        componentDescription, time, cgRect
    case arrayOfDeviceIDs, arrayOfObjectIDs, arrayOfClassIDs, arrayOfStreamIDs,
        arrayOfUInt32s, arrayOfFloat64s, arrayOfAudioValueRanges
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
             .componentDescription, .time, .cgRect,
             .audioValueTranslation:
            return .pod
        case .arrayOfDeviceIDs, .arrayOfObjectIDs, .arrayOfClassIDs, .arrayOfStreamIDs,
             .arrayOfUInt32s, .arrayOfFloat64s, .arrayOfAudioValueRanges:
            return .podArray
        case .string, .formatDescription, .sampleBuffer, .clock:
            return .cf
        case .arrayOfFormatDescriptions:
            return .cfArray
        }
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
    var readSemantics: PropertyReadSemantics { get }
    
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

public protocol PropertyListener {}


public enum Property {
    
    public static func value<S, T>(of property: S,
                                   scope: CMIOObjectPropertyScope = .anyScope,
                                   element: CMIOObjectPropertyElement = .anyElement,
                                   qualifiedBy qualifier: QualifierProtocol? = nil,
                                   in objectID: CMIOObjectID) -> T? where S: PropertySet {
        var address = CMIOObjectPropertyAddress(property.selector, scope, element)
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

    public static func arrayValue<S, T>(of property: S,
                                        scope: CMIOObjectPropertyScope = .anyScope,
                                        element: CMIOObjectPropertyElement = .anyElement,
                                        qualifiedBy qualifier: QualifierProtocol? = nil,
                                        in objectID: CMIOObjectID) -> [T]? where S: PropertySet {
        var address = CMIOObjectPropertyAddress(property.selector, scope, element)
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
        var address = CMIOObjectPropertyAddress(property.selector, scope, element)
        let dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var value = value
        
        let status = CMIOObjectSetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &value)
        return status == kCMIOHardwareNoError
    }
    
    public static func addListener<S>(for property: S,
                                      scope: CMIOObjectPropertyScope = .anyScope,
                                      element: CMIOObjectPropertyElement = .anyElement,
                                      in objectID: CMIOObjectID,
                                      queue: DispatchQueue? = nil,
                                      block: @escaping ([CMIOObjectPropertyAddress]) -> Void) -> PropertyListener? where S: PropertySet {
        let address = CMIOObjectPropertyAddress(property.selector, scope, element)
        
        return Listener(objectID: objectID, address: address, queue: queue) { addressCount, addressPtr in
            guard addressCount > 0, let array = addressPtr else { return }
            block(UnsafeBufferPointer(start: array, count: Int(addressCount)).map { $0 })
        }
    }
    
    public static func removeListener(_ listener: PropertyListener) -> Bool {
        guard let listener = listener as? Listener else {
            return false
        }
        
        return listener.deactivate()
    }
    
    class Listener: PropertyListener {
        private let objectID: CMIOObjectID
        private let address: CMIOObjectPropertyAddress
        private let queue: DispatchQueue?
        private let block: CMIOObjectPropertyListenerBlock
        private var isActive: Bool
        
        init?(objectID: CMIOObjectID,
              address: CMIOObjectPropertyAddress,
              queue: DispatchQueue?,
              block: @escaping CMIOObjectPropertyListenerBlock) {
            self.objectID = objectID
            self.address = address
            self.queue = queue
            self.block = block
            
            var address = address
            let status = CMIOObjectAddPropertyListenerBlock(objectID, &address, queue, block)
            guard status == kCMIOHardwareNoError else {
                return nil
            }
            
            isActive = true
        }
        
        @discardableResult
        func deactivate() -> Bool {
            guard isActive else { return true }
            
            var address = self.address
            let status = CMIOObjectRemovePropertyListenerBlock(objectID, &address, queue, block)
            guard status == kCMIOHardwareNoError else {
                return false
            }
            
            isActive = false
            return true
        }
        
        deinit {
            if isActive {
                deactivate()
            }
        }
    }
}
