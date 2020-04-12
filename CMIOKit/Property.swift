//
//  Property.swift
//  CMIOKit
//
//  Created by Tamás Lustyik on 2019. 01. 05..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO
#if NEEDS_VIDEO_DIGITIZER_COMPONENTS
import CoreServices.CarbonCore.Components
#endif


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
    case boolean, boolean32, int32, uint32, uint64, float32, float64,
        classID, objectID, fourCC,
        audioValueRange, propertyAddress, streamConfiguration, streamDeck,
        pid,
        smpteCallback, scheduledOutputCallback,
        componentDescription, time, rect,
        propertyScope, propertyElement
    case string, formatDescription, sampleBuffer, clock
    case audioValueTranslation
    indirect case array(PropertyType)
}

public enum PropertyValue {
    case boolean(Bool), int32(Int32), uint32(UInt32), uint64(UInt64),
        float32(Float32), float64(Float64),
        classID(CMIOClassID), objectID(CMIOObjectID), fourCC(UInt32),
        audioValueRange(AudioValueRange), propertyAddress(CMIOObjectPropertyAddress),
        streamConfiguration(channelCounts: [UInt32]), streamDeck(CMIOStreamDeck),
        pid(pid_t),
        smpteCallback(CMIODeviceSMPTETimeCallback),
        scheduledOutputCallback(CMIOStreamScheduledOutputNotificationProcAndRefCon),
        time(CMTime), rect(CGRect)
    case string(String), formatDescription(CMFormatDescription), sampleBuffer(CMSampleBuffer), clock(CFTypeRef)
    case arrayOfUInt32s([UInt32])
    case arrayOfFloat64s([Float64])
    case arrayOfObjectIDs([CMIOObjectID])
    case arrayOfAudioValueRanges([AudioValueRange])
    case arrayOfFormatDescriptions([CMFormatDescription])

#if NEEDS_VIDEO_DIGITIZER_COMPONENTS
    case arrayOfComponentDescriptions([ComponentDescription])
#endif
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
    func exists(scope: CMIOObjectPropertyScope = .anyScope,
                element: CMIOObjectPropertyElement = .anyElement,
                in objectID: CMIOObjectID) -> Bool {
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        
        return CMIOObjectHasProperty(objectID, &address)
    }
    
    func isSettable(scope: CMIOObjectPropertyScope = .anyScope,
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
    
    func value(scope: CMIOObjectPropertyScope = .anyScope,
               element: CMIOObjectPropertyElement = .anyElement,
               qualifiedBy qualifier: QualifierProtocol? = nil,
               in objectID: CMIOObjectID) -> PropertyValue? {
        func getValue<T>() -> T? {
            return value(scope: scope, element: element, qualifiedBy: qualifier, in: objectID)
        }
        
        func getArrayValue<T>() -> [T]? {
            return arrayValue(scope: scope, element: element, qualifiedBy: qualifier, in: objectID)
        }

        switch type {
        case .boolean:
            if let value: DarwinBoolean = getValue() {
                return .boolean(value.boolValue)
            }
        case .boolean32:
            if let value: UInt32 = getValue() {
                return .boolean(value != 0)
            }
        case .uint32:
            if let value: UInt32 = getValue() {
                return .uint32(value)
            }
        case .int32:
            if let value: Int32 = getValue() {
                return .int32(value)
            }
        case .uint64:
            if let value: UInt64 = getValue() {
                return .uint64(value)
            }
        case .float32:
            if let value: Float32 = getValue() {
                return .float32(value)
            }
        case .float64:
            if let value: Float64 = getValue() {
                return .float64(value)
            }
        case .classID:
            if let value: CMIOClassID = getValue() {
                return .classID(value)
            }
        case .objectID:
            if let value: CMIOObjectID = getValue() {
                return .objectID(value)
            }
        case .fourCC:
            if let value: UInt32 = getValue() {
                return .fourCC(value)
            }
        case .audioValueTranslation:
            // handled by translateValue()
            return nil
        case .audioValueRange:
            if let value: AudioValueRange = getValue() {
                return .audioValueRange(value)
            }
        case .propertyAddress:
            if let value: CMIOObjectPropertyAddress = getValue() {
                return .propertyAddress(value)
            }
        case .streamConfiguration:
            if let value: [UInt32] = getArrayValue() {
                return .streamConfiguration(channelCounts: Array(value.dropFirst()))
            }
        case .pid:
            if let value: pid_t = getValue() {
                return .pid(value)
            }
        case .time:
            if let value: CMTime = getValue() {
                return .time(value)
            }
        case .rect:
            if let value: CGRect = getValue() {
                return .rect(value)
            }
        case .streamDeck:
            if let value: CMIOStreamDeck = getValue() {
                return .streamDeck(value)
            }
        case .smpteCallback:
            if let value: CMIODeviceSMPTETimeCallback = getValue() {
                return .smpteCallback(value)
            }
        case .scheduledOutputCallback:
            if let value: CMIOStreamScheduledOutputNotificationProcAndRefCon = getValue() {
                return .scheduledOutputCallback(value)
            }
        case .array(let elemType):
            switch elemType {
            case .uint32:
                if let value: [UInt32] = getArrayValue() {
                    return .arrayOfUInt32s(value)
                }
            case .float64:
                if let value: [Float64] = getArrayValue() {
                    return .arrayOfFloat64s(value)
                }
            case .objectID:
                if let value: [CMIOObjectID] = getArrayValue() {
                    return .arrayOfObjectIDs(value)
                }
            case .audioValueRange:
                if let value: [AudioValueRange] = getArrayValue() {
                    return .arrayOfAudioValueRanges(value)
                }
            case .formatDescription:
                if let value: [CMFormatDescription] = getArrayValue() {
                    return .arrayOfFormatDescriptions(value)
                }
#if NEEDS_VIDEO_DIGITIZER_COMPONENTS
            case .componentDescription:
                if let value: [ComponentDescription] = getArrayValue() {
                    return .arrayOfComponentDescriptions(value)
                }
#endif
            default:
                assertionFailure("unhandled array element type: \(elemType)")
            }
        case .string:
            if let value: CFString = getValue() {
                return .string(value as String)
            }
        case .formatDescription:
            if let value: CMFormatDescription = getValue() {
                return .formatDescription(value)
            }
        case .sampleBuffer:
            if let value: CMSampleBuffer = getValue() {
                return .sampleBuffer(value)
            }
        case .clock:
            if let value: CFTypeRef = getValue() {
                return .clock(value)
            }
        default:
            assertionFailure("unhandled property type: \(type)")
        }
        
        return nil
    }

    private func value<T>(scope: CMIOObjectPropertyScope = .anyScope,
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
    
    private func arrayValue<T>(scope: CMIOObjectPropertyScope = .anyScope,
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
    func setValue<T>(_ value: T,
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
    
    func translateValue<T, U>(_ value: T,
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

    func addListener(scope: CMIOObjectPropertyScope = .anyScope,
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
    
    func removeListener(_ listener: PropertyListener) -> Bool {
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
