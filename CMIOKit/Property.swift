//
//  Property.swift
//  CMIOKit
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

public protocol Property {
    var selector: CMIOObjectPropertySelector { get }
    var type: PropertyType { get }
    var readSemantics: PropertyReadSemantics { get }
}

public protocol PropertySet: Property, CaseIterable {
    static func allExisting(scope: CMIOObjectPropertyScope,
                            element: CMIOObjectPropertyElement,
                            in objectID: CMIOObjectID) -> [Self]
}

public extension PropertySet {
    static func allExisting(scope: CMIOObjectPropertyScope = .anyScope,
                            element: CMIOObjectPropertyElement = .anyElement,
                            in objectID: CMIOObjectID) -> [Self] {
        return allCases.filter { $0.exists(scope: scope, element: element, in: objectID) }
    }
}

public extension Property {
    public func exists(scope: CMIOObjectPropertyScope = .anyScope,
                       element: CMIOObjectPropertyElement = .anyElement,
                       in objectID: CMIOObjectID) -> Bool {
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        
        return CMIOObjectHasProperty(objectID, &address)
    }
    
    public func isSettable(scope: CMIOObjectPropertyScope = .anyScope,
                           element: CMIOObjectPropertyElement = .anyElement,
                           in objectID: CMIOObjectID) -> Bool {
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        
        var isSettable: DarwinBoolean = false
        
        let status = CMIOObjectIsPropertySettable(objectID, &address, &isSettable)
        guard status == kCMIOHardwareNoError else {
            return false
        }
        
        return isSettable.boolValue
    }

    public func value<T>(scope: CMIOObjectPropertyScope = .anyScope,
                         element: CMIOObjectPropertyElement = .anyElement,
                         qualifiedBy qualifier: QualifierProtocol? = nil,
                         in objectID: CMIOObjectID) -> T? {
        switch readSemantics {
        case .qualifiedRead where qualifier == nil: return nil
        default: break
        }
        
        var address = CMIOObjectPropertyAddress(selector, scope, element)
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
    
    public func arrayValue<T>(scope: CMIOObjectPropertyScope = .anyScope,
                              element: CMIOObjectPropertyElement = .anyElement,
                              qualifiedBy qualifier: QualifierProtocol? = nil,
                              in objectID: CMIOObjectID) -> [T]? {
        switch readSemantics {
        case .qualifiedRead where qualifier == nil: return nil
        default: break
        }
        
        var address = CMIOObjectPropertyAddress(selector, scope, element)
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
    
    @discardableResult
    public func setValue<T>(_ value: T,
                            scope: CMIOObjectPropertyScope = .anyScope,
                            element: CMIOObjectPropertyElement = .anyElement,
                            qualifiedBy qualifier: QualifierProtocol? = nil,
                            in objectID: CMIOObjectID) -> Bool {
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        let dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var value = value
        
        let status = CMIOObjectSetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &value)
        return status == kCMIOHardwareNoError
    }
    
    public func translateValue<T, U>(_ value: T,
                                     scope: CMIOObjectPropertyScope = .anyScope,
                                     element: CMIOObjectPropertyElement = .anyElement,
                                     in objectID: CMIOObjectID) -> U? {
        guard case .translation = readSemantics else {
            return nil
        }
        
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        var value = value
        var translatedValue = UnsafeMutablePointer<U>.allocate(capacity: 1)
        defer { translatedValue.deallocate() }
        
        var translation = AudioValueTranslation(mInputData: &value,
                                                mInputDataSize: UInt32(MemoryLayout<T>.size),
                                                mOutputData: translatedValue,
                                                mOutputDataSize: UInt32(MemoryLayout<U>.size))
        
        var dataUsed: UInt32 = 0
        
        let status = CMIOObjectGetPropertyData(objectID, &address,
                                               0, nil,
                                               UInt32(MemoryLayout<AudioValueTranslation>.size), &dataUsed,
                                               &translation)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        return translatedValue.pointee
    }

    public func addListener(scope: CMIOObjectPropertyScope = .anyScope,
                            element: CMIOObjectPropertyElement = .anyElement,
                            in objectID: CMIOObjectID,
                            queue: DispatchQueue? = nil,
                            block: @escaping ([CMIOObjectPropertyAddress]) -> Void) -> PropertyListener? {
        let address = CMIOObjectPropertyAddress(selector, scope, element)
        
        return PropertyListenerImpl(objectID: objectID, address: address, queue: queue) { addressCount, addressPtr in
            guard addressCount > 0, let array = addressPtr else { return }
            block(UnsafeBufferPointer(start: array, count: Int(addressCount)).map { $0 })
        }
    }
    
    public func removeListener(_ listener: PropertyListener) -> Bool {
        guard let listener = listener as? PropertyListenerImpl else {
            return false
        }
        
        return listener.deactivate()
    }
}

public protocol PropertyListener {}

class PropertyListenerImpl: PropertyListener {
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
