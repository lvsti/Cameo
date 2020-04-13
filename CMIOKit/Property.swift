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


public enum PropertyReadSemantics {
    /// value is written into provided buffer
    case read
    
    /// value in provided buffer is used, result is written back to buffer (in/out types are the same)
    case mutatingRead
    
    /// special case of `mutatingRead`: an AudioValueTranslation object is provided with the input
    /// and returned in place with the output
    case translation(PropertyType, PropertyType)
    
    /// data in the qualifier is used, result is written into provided buffer
    case qualifiedRead(PropertyType)
    
    /// data in the qualifier is used if any, result is written into provided buffer
    case optionallyQualifiedRead(PropertyType)
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
        time(CMTime), rect(CGRect),
        propertyScope(CMIOObjectPropertyScope), propertyElement(CMIOObjectPropertyElement)
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
    /// The CMIOObjectPropertyScope for properties that apply to the object as a whole.
    /// All CMIOObjects have a global scope and for some it is their only scope.
    static let global = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
    
    /// The wildcard value for CMIOObjectPropertyScopes.
    static let anyScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard)
    
    /// The CMIOObjectPropertyScope for properties that apply to the input signal paths of the CMIODevice.
    static let deviceInput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeInput)
    
    /// The CMIOObjectPropertyScope for properties that apply to the output signal paths of the CMIODevice.
    static let deviceOutput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeOutput)
    
    /// The CMIOObjectPropertyScope for properties that apply to the play through signal paths of the CMIODevice.
    static let devicePlayThrough = CMIOObjectPropertyScope(kCMIODevicePropertyScopePlayThrough)
}

public extension CMIOObjectPropertyElement {
    /// The CMIOObjectPropertyElement value for properties that apply to the master element or to the entire scope.
    static let master = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
    
    /// The wildcard value for CMIOObjectPropertyElements.
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
    /// Returns all properties from the current set that are defined in the given object
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
    /// Checks whether the property is defined in the given object
    func exists(scope: CMIOObjectPropertyScope = .anyScope,
                element: CMIOObjectPropertyElement = .anyElement,
                in objectID: CMIOObjectID) -> Bool {
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        
        return CMIOObjectHasProperty(objectID, &address)
    }
    
    /// Checks whether the property can be written in the given object
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
    
    /// Gets the value of the property in the given object
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
        case .propertyScope:
            if let value: CMIOObjectPropertyScope = getValue() {
                return .propertyScope(value)
            }
        case .propertyElement:
            if let value: CMIOObjectPropertyElement = getValue() {
                return .propertyElement(value)
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
                if let value: CFArray = getValue(), let array = value as? [CMFormatDescription] {
                    return .arrayOfFormatDescriptions(array)
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
    
    /// Sets the value of the property in the given object
    @discardableResult
    func setValue(_ value: PropertyValue,
                  scope: CMIOObjectPropertyScope = .anyScope,
                  element: CMIOObjectPropertyElement = .anyElement,
                  qualifiedBy qualifier: QualifierProtocol? = nil,
                  in objectID: CMIOObjectID) -> Bool {
        func setRawValue<T>(_ rawValue: T) -> Bool {
            return setValue(rawValue, scope: scope, element: element, qualifiedBy: qualifier, in: objectID)
        }
        
        switch type {
        case .boolean:
            if case .boolean(let v) = value { return setRawValue(DarwinBoolean(booleanLiteral: v)) }
        case .boolean32:
            if case .boolean(let v) = value { return setRawValue(UInt32(v ? 1 : 0)) }
            if case .uint32(let v) = value { return setRawValue(v) }
        case .uint32:
            if case .uint32(let v) = value { return setRawValue(v) }
        case .int32:
            if case .int32(let v) = value { return setRawValue(v) }
        case .uint64:
            if case .uint64(let v) = value { return setRawValue(v) }
        case .float32:
            if case .float32(let v) = value { return setRawValue(v) }
        case .float64:
            if case .float64(let v) = value { return setRawValue(v) }
        case .classID:
            if case .classID(let v) = value { return setRawValue(v) }
        case .objectID:
            if case .objectID(let v) = value { return setRawValue(v) }
        case .fourCC:
            if case .fourCC(let v) = value { return setRawValue(v) }
        case .audioValueTranslation:
            // handled by translateValue()
            return false
        case .audioValueRange:
            if case .audioValueRange(let v) = value { return setRawValue(v) }
        case .propertyAddress:
            if case .propertyAddress(let v) = value { return setRawValue(v) }
        case .streamConfiguration:
            assertionFailure("not implemented")
            return false
        case .pid:
            if case .pid(let v) = value { return setRawValue(v) }
        case .time:
            if case .time(let v) = value { return setRawValue(v) }
        case .rect:
            if case .rect(let v) = value { return setRawValue(v) }
        case .streamDeck:
            if case .streamDeck(let v) = value { return setRawValue(v) }
        case .smpteCallback:
            if case .smpteCallback(let v) = value { return setRawValue(v) }
        case .scheduledOutputCallback:
            if case .scheduledOutputCallback(let v) = value { return setRawValue(v) }
        case .array:
            assertionFailure("not implemented")
            return false
        case .string:
            if case .string(let v) = value { return setRawValue(v as CFString) }
        case .formatDescription:
            if case .formatDescription(let v) = value { return setRawValue(v) }
        case .sampleBuffer:
            if case .sampleBuffer(let v) = value { return setRawValue(v) }
        case .clock:
            if case .clock(let v) = value { return setRawValue(v) }
        default:
            assertionFailure("unhandled property type: \(type)")
        }
        
        return false
    }
    
    private func setValue<T>(_ value: T,
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
    
    /// Performs a value translation using the property in the given object
    func translateValue(_ value: PropertyValue,
                        scope: CMIOObjectPropertyScope = .anyScope,
                        element: CMIOObjectPropertyElement = .anyElement,
                        qualifiedBy qualifier: QualifierProtocol? = nil,
                        in objectID: CMIOObjectID) -> PropertyValue? {
        func getTranslatedValue<U>(fromType: PropertyType) -> U? {
            switch fromType {
            case .string:
                if case .string(let v) = value {
                    return translateValue(v as CFString, scope: scope, element: element, in: objectID)
                }
            default: break
            }
            return nil
        }

        func getMutatedValue<U>() -> U? {
            switch type {
            case .string:
                if case .string(let v) = value {
                    return translateValue(v as CFString, scope: scope, element: element, in: objectID)
                }
            default: break
            }
            return nil
        }

        switch readSemantics {
        case .translation(let fromType, let toType):
            switch toType {
            case .objectID:
                if let newValue: CMIOObjectID = getTranslatedValue(fromType: fromType) {
                    return .objectID(newValue)
                }
            default:
                break
            }
        case .mutatingRead:
            switch type {
            case .float32:
                if case .float32(let v) = value,
                   let newValue: Float32 = mutateValue(v, scope: scope, element: element, qualifiedBy: qualifier, in: objectID) {
                    return .float32(newValue)
                }
            default:
                break
            }
        default:
            break
        }
        
        return nil
    }
    
    private func translateValue<T, U>(_ value: T,
                                      scope: CMIOObjectPropertyScope = .anyScope,
                                      element: CMIOObjectPropertyElement = .anyElement,
                                      qualifiedBy qualifier: QualifierProtocol? = nil,
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
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               UInt32(MemoryLayout<AudioValueTranslation>.size), &dataUsed,
                                               &translation)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        return translatedValue.pointee
    }
    
    private func mutateValue<T>(_ value: T,
                                scope: CMIOObjectPropertyScope = .anyScope,
                                element: CMIOObjectPropertyElement = .anyElement,
                                qualifiedBy qualifier: QualifierProtocol? = nil,
                                in objectID: CMIOObjectID) -> T? {
        guard case .mutatingRead = readSemantics else {
            return nil
        }
        
        var address = CMIOObjectPropertyAddress(selector, scope, element)
        var dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        typedData.pointee = value

        let status = CMIOObjectGetPropertyData(objectID, &address,
                                               UInt32(qualifier?.size ?? 0), qualifier?.data,
                                               dataSize, &dataUsed, data)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        return typedData.pointee
    }
}

