//
//  CMIO.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 25..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO


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
    
    static func podTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> T? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = UInt32(MemoryLayout<T>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        
        let status = CMIOObjectGetPropertyData(objectID, &address, 0, nil, dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        return typedData.pointee
    }

    static func podArrayTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> [T]? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address, 0, nil, &dataSize)
        guard status == 0 else {
            return nil
        }
        
        let count = Int(dataSize) / MemoryLayout<T>.size
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<T>.alignment)
        defer { data.deallocate() }
        
        status = CMIOObjectGetPropertyData(objectID, &address, 0, nil, dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: T.self, capacity: count)
        return UnsafeBufferPointer<T>(start: typedData, count: count).map { $0 }
    }

    static func cfTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> T? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = UInt32(MemoryLayout<CFTypeRef>.size)
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFTypeRef>.alignment)
        defer { data.deallocate() }
        
        let status = CMIOObjectGetPropertyData(objectID, &address, 0, nil, dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: CFTypeRef.self, capacity: 1)
        return typedData.pointee as? T
    }

    static func cfArrayTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> [T]? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address, 0, nil, &dataSize)
        guard status == 0 else {
            return nil
        }
        
        let count = Int(dataSize) / MemoryLayout<CFTypeRef>.size
        var dataUsed: UInt32 = 0
        var data = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<CFTypeRef>.alignment)
        defer { data.deallocate() }
        
        status = CMIOObjectGetPropertyData(objectID, &address, 0, nil, dataSize, &dataUsed, data)
        guard status == 0 else {
            return nil
        }
        
        let typedData = data.bindMemory(to: CFTypeRef.self, capacity: count)
        return UnsafeBufferPointer<CFTypeRef>(start: typedData, count: count).compactMap { $0 as? T }
    }

}

enum CMIOError: Error {
    case osStatus(OSStatus)
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
    static func value<S, T>(of property: S, in objectID: CMIOObjectID) -> T? where S: PropertySet {
        let desc = S.descriptors[property]!
        switch desc.type.kind {
        case .pod: return PropertyType.podTypeValue(for: desc.selector, in: objectID)
        case .cf: return PropertyType.cfTypeValue(for: desc.selector, in: objectID)
        default: return nil
        }
    }

    static func arrayValue<S, T>(of property: S, in objectID: CMIOObjectID) -> [T]? where S: PropertySet {
        let desc = S.descriptors[property]!
        switch desc.type.kind {
        case .podArray: return PropertyType.podArrayTypeValue(for: desc.selector, in: objectID)
        case .cfArray: return PropertyType.cfArrayTypeValue(for: desc.selector, in: objectID)
        default: return nil
        }
    }

    static func description<S>(of property: S, in objectID: CMIOObjectID) -> String? where S: PropertySet {
        let desc = S.descriptors[property]!
        return propertyDescription(for: desc.selector, ofType: desc.type, in: objectID)
    }

    static func isSettable<S>(_ property: S, in objectID: CMIOObjectID) -> Bool where S: PropertySet {
        let desc = S.descriptors[property]!
        
        var isSettable: DarwinBoolean = false
        var address = CMIOObjectPropertyAddress(desc.selector)
        
        let status = CMIOObjectIsPropertySettable(objectID, &address, &isSettable)
        guard status == 0 else {
            //throw CMIOError.osStatus(status)
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

enum ObjectProperty: PropertySet {
    case `class`, owner, creator, name, manufacturer, elementName, elementCategoryName, elementNumberName, ownedObjects
    
    static let descriptors: [ObjectProperty: PropertyDescriptor] = [
        .class: PropertyDescriptor(kCMIOObjectPropertyClass, .classID),
        .owner: PropertyDescriptor(kCMIOObjectPropertyOwner, .objectID),
        .creator: PropertyDescriptor(kCMIOObjectPropertyCreator, .string),
        .name: PropertyDescriptor(kCMIOObjectPropertyName, .string),
        .manufacturer: PropertyDescriptor(kCMIOObjectPropertyManufacturer, .string),
        .elementName: PropertyDescriptor(kCMIOObjectPropertyElementName, .string),
        .elementCategoryName: PropertyDescriptor(kCMIOObjectPropertyElementCategoryName, .string),
        .elementNumberName: PropertyDescriptor(kCMIOObjectPropertyElementNumberName, .string),
        .ownedObjects: PropertyDescriptor(kCMIOObjectPropertyOwnedObjects, .arrayOfObjectIDs)
    ]
}

enum SystemProperty: PropertySet {
    case processIsMaster, isInitingOrExiting, devices, defaultInputDevice, defaultOutputDevice,
        deviceForUID, sleepingIsAllowed, unloadingIsAllowed, plugInForBundleID,
        userSessionIsActiveOrHeadless, suspendedBySystem, allowScreenCaptureDevices,
        allowWirelessScreenCaptureDevices
    
    static let descriptors: [SystemProperty: PropertyDescriptor] = [
        .processIsMaster: PropertyDescriptor(kCMIOHardwarePropertyProcessIsMaster, .boolean32),
        .isInitingOrExiting: PropertyDescriptor(kCMIOHardwarePropertyIsInitingOrExiting, .boolean32),
        .devices: PropertyDescriptor(kCMIOHardwarePropertyDevices, .arrayOfDeviceIDs),
        .defaultInputDevice: PropertyDescriptor(kCMIOHardwarePropertyDefaultInputDevice, .deviceID),
        .defaultOutputDevice: PropertyDescriptor(kCMIOHardwarePropertyDefaultOutputDevice, .deviceID),
        .deviceForUID: PropertyDescriptor(kCMIOHardwarePropertyDeviceForUID, .audioValueTranslation),
        .sleepingIsAllowed: PropertyDescriptor(kCMIOHardwarePropertySleepingIsAllowed, .boolean32),
        .unloadingIsAllowed: PropertyDescriptor(kCMIOHardwarePropertyUnloadingIsAllowed, .boolean32),
        .plugInForBundleID: PropertyDescriptor(kCMIOHardwarePropertyPlugInForBundleID, .audioValueTranslation),
        .userSessionIsActiveOrHeadless: PropertyDescriptor(kCMIOHardwarePropertyUserSessionIsActiveOrHeadless, .boolean32),
        .suspendedBySystem: PropertyDescriptor(kCMIOHardwarePropertySuspendedBySystem, .boolean32),
        .allowScreenCaptureDevices: PropertyDescriptor(kCMIOHardwarePropertyAllowScreenCaptureDevices, .boolean32),
        .allowWirelessScreenCaptureDevices: PropertyDescriptor(kCMIOHardwarePropertyAllowWirelessScreenCaptureDevices, .boolean32)
    ]
}

enum DeviceProperty: PropertySet {
    case plugIn, deviceUID, modelUID, transportType, deviceIsAlive, deviceHasChanged, deviceIsRunning,
        deviceIsRunningSomewhere, deviceCanBeDefaultDevice, hogMode, latency, streams,
        streamConfiguration, deviceMaster, excludeNonDALAccess, clientSyncDiscontinuity, smpteTimeCallback,
        canProcessAVCCommand, avcDeviceType, avcDeviceSignalMode, canProcessRS422Command, linkedCoreAudioDeviceUID,
        videoDigitizerComponents, suspendedByUser, linkedAndSyncedCoreAudioDeviceUID, iidcInitialUnitSpace,
        iidcCSRData, canSwitchFrameRatesWithoutFrameDrops, location

    static let descriptors: [DeviceProperty: PropertyDescriptor] = [
        .plugIn: PropertyDescriptor(kCMIODevicePropertyPlugIn, .objectID),
        .deviceUID: PropertyDescriptor(kCMIODevicePropertyDeviceUID, .string),
        .modelUID: PropertyDescriptor(kCMIODevicePropertyModelUID, .string),
        .transportType: PropertyDescriptor(kCMIODevicePropertyTransportType, .fourCC),
        .deviceIsAlive: PropertyDescriptor(kCMIODevicePropertyDeviceIsAlive, .boolean32),
        .deviceHasChanged: PropertyDescriptor(kCMIODevicePropertyDeviceHasChanged, .boolean32),
        .deviceIsRunning: PropertyDescriptor(kCMIODevicePropertyDeviceIsRunning, .boolean32),
        .deviceIsRunningSomewhere: PropertyDescriptor(kCMIODevicePropertyDeviceIsRunningSomewhere, .boolean32),
        .deviceCanBeDefaultDevice: PropertyDescriptor(kCMIODevicePropertyDeviceCanBeDefaultDevice, .boolean32),
        .hogMode: PropertyDescriptor(kCMIODevicePropertyHogMode, .pid),
        .latency: PropertyDescriptor(kCMIODevicePropertyLatency, .uint32),
        .streams: PropertyDescriptor(kCMIODevicePropertyStreams, .arrayOfStreamIDs),
        .streamConfiguration: PropertyDescriptor(kCMIODevicePropertyStreamConfiguration, .streamConfiguration),
        .deviceMaster: PropertyDescriptor(kCMIODevicePropertyDeviceMaster, .pid),
        .excludeNonDALAccess: PropertyDescriptor(kCMIODevicePropertyExcludeNonDALAccess, .boolean32),
        .clientSyncDiscontinuity: PropertyDescriptor(kCMIODevicePropertyClientSyncDiscontinuity, .boolean),
        .smpteTimeCallback: PropertyDescriptor(kCMIODevicePropertySMPTETimeCallback, .smpteCallback),
        .canProcessAVCCommand: PropertyDescriptor(kCMIODevicePropertyCanProcessAVCCommand, .boolean),
        .avcDeviceType: PropertyDescriptor(kCMIODevicePropertyAVCDeviceType, .uint32),
        .avcDeviceSignalMode: PropertyDescriptor(kCMIODevicePropertyAVCDeviceSignalMode, .uint32),
        .canProcessRS422Command: PropertyDescriptor(kCMIODevicePropertyCanProcessRS422Command, .boolean),
        .linkedCoreAudioDeviceUID: PropertyDescriptor(kCMIODevicePropertyLinkedCoreAudioDeviceUID, .string),
        .videoDigitizerComponents: PropertyDescriptor(kCMIODevicePropertyVideoDigitizerComponents, .componentDescription),
        .suspendedByUser: PropertyDescriptor(kCMIODevicePropertySuspendedByUser, .boolean32),
        .linkedAndSyncedCoreAudioDeviceUID: PropertyDescriptor(kCMIODevicePropertyLinkedAndSyncedCoreAudioDeviceUID, .string),
        .iidcInitialUnitSpace: PropertyDescriptor(kCMIODevicePropertyIIDCInitialUnitSpace, .uint32),
        .iidcCSRData: PropertyDescriptor(kCMIODevicePropertyIIDCCSRData, .uint32),
        .canSwitchFrameRatesWithoutFrameDrops: PropertyDescriptor(kCMIODevicePropertyCanSwitchFrameRatesWithoutFrameDrops, .boolean),
        .location: PropertyDescriptor(kCMIODevicePropertyLocation, .uint32)
    ]
}

enum StreamProperty: PropertySet {
    case direction, terminalType, startingChannel, latency, formatDescription, formatDescriptions,
        stillImage, stillImageFormatDescriptions, frameRate, minimumFrameRate, frameRates,
        frameRateRanges, noDataTimeoutInMSec, deviceSyncTimeoutInMSec, noDataEventCount,
        outputBufferUnderrunCount, outputBufferRepeatCount, outputBufferQueueSize,
        outputBuffersRequiredForStartup, outputBuffersNeededForThrottledPlayback,
        firstOutputPresentationTimeStamp, endOfData, clock, canProcessDeckCommand,
        deck, deckFrameNumber, deckDropness, deckThreaded, deckLocal, deckCueing,
        initialPresentationTimeStampForLinkedAndSyncedAudio, scheduledOutputNotificationProc,
        preferredFormatDescription, preferredFrameRate
    
    static let descriptors: [StreamProperty: PropertyDescriptor] = [
        .direction: PropertyDescriptor(kCMIOStreamPropertyDirection, .uint32),
        .terminalType: PropertyDescriptor(kCMIOStreamPropertyTerminalType, .uint32),
        .startingChannel: PropertyDescriptor(kCMIOStreamPropertyStartingChannel, .uint32),
        .latency: PropertyDescriptor(kCMIOStreamPropertyLatency, .uint32),
        .formatDescription: PropertyDescriptor(kCMIOStreamPropertyFormatDescription, .formatDescription),
        .formatDescriptions: PropertyDescriptor(kCMIOStreamPropertyFormatDescriptions, .arrayOfFormatDescriptions),
        .stillImage: PropertyDescriptor(kCMIOStreamPropertyStillImage, .sampleBuffer),
        .stillImageFormatDescriptions: PropertyDescriptor(kCMIOStreamPropertyStillImageFormatDescriptions, .arrayOfFormatDescriptions),
        .frameRate: PropertyDescriptor(kCMIOStreamPropertyFrameRate, .float64),
        .minimumFrameRate: PropertyDescriptor(kCMIOStreamPropertyMinimumFrameRate, .float64),
        .frameRates: PropertyDescriptor(kCMIOStreamPropertyFrameRates, .arrayOfFloat64s),
        .frameRateRanges: PropertyDescriptor(kCMIOStreamPropertyFrameRateRanges, .arrayOfAudioValueRanges),
        .noDataTimeoutInMSec: PropertyDescriptor(kCMIOStreamPropertyNoDataTimeoutInMSec, .uint32),
        .deviceSyncTimeoutInMSec: PropertyDescriptor(kCMIOStreamPropertyDeviceSyncTimeoutInMSec, .uint32),
        .noDataEventCount: PropertyDescriptor(kCMIOStreamPropertyNoDataEventCount, .uint32),
        .outputBufferUnderrunCount: PropertyDescriptor(kCMIOStreamPropertyOutputBufferUnderrunCount, .uint32),
        .outputBufferRepeatCount: PropertyDescriptor(kCMIOStreamPropertyOutputBufferRepeatCount, .uint32),
        .outputBufferQueueSize: PropertyDescriptor(kCMIOStreamPropertyOutputBufferQueueSize, .uint32),
        .outputBuffersRequiredForStartup: PropertyDescriptor(kCMIOStreamPropertyOutputBuffersRequiredForStartup, .uint32),
        .outputBuffersNeededForThrottledPlayback: PropertyDescriptor(kCMIOStreamPropertyOutputBuffersNeededForThrottledPlayback, .uint32),
        .firstOutputPresentationTimeStamp: PropertyDescriptor(kCMIOStreamPropertyFirstOutputPresentationTimeStamp, .time),
        .endOfData: PropertyDescriptor(kCMIOStreamPropertyEndOfData, .boolean32),
        .clock: PropertyDescriptor(kCMIOStreamPropertyClock, .clock),
        .canProcessDeckCommand: PropertyDescriptor(kCMIOStreamPropertyCanProcessDeckCommand, .boolean),
        .deck: PropertyDescriptor(kCMIOStreamPropertyDeck, .streamDeck),
        .deckFrameNumber: PropertyDescriptor(kCMIOStreamPropertyDeckFrameNumber, .uint64),
        .deckDropness: PropertyDescriptor(kCMIOStreamPropertyDeckDropness, .boolean32),
        .deckThreaded: PropertyDescriptor(kCMIOStreamPropertyDeckThreaded, .boolean32),
        .deckLocal: PropertyDescriptor(kCMIOStreamPropertyDeckLocal, .boolean32),
        .deckCueing: PropertyDescriptor(kCMIOStreamPropertyDeckCueing, .int32),
        .initialPresentationTimeStampForLinkedAndSyncedAudio: PropertyDescriptor(kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio, .time),
        .scheduledOutputNotificationProc: PropertyDescriptor(kCMIOStreamPropertyScheduledOutputNotificationProc, .scheduledOutputCallback),
        .preferredFormatDescription: PropertyDescriptor(kCMIOStreamPropertyPreferredFormatDescription, .formatDescription),
        .preferredFrameRate: PropertyDescriptor(kCMIOStreamPropertyPreferredFrameRate, .float64)
    ]
}

enum ControlProperty: PropertySet {
    case scope, element, variant
    
    static let descriptors: [ControlProperty: PropertyDescriptor] = [
        .scope: PropertyDescriptor(kCMIOControlPropertyScope, .fourCC),
        .element: PropertyDescriptor(kCMIOControlPropertyScope, .fourCC),
        .variant: PropertyDescriptor(kCMIOControlPropertyScope, .fourCC)
    ]
}

enum BooleanControlProperty: PropertySet {
    case value
    
    static let descriptors: [BooleanControlProperty: PropertyDescriptor] = [
        .value: PropertyDescriptor(kCMIOBooleanControlPropertyValue, .boolean32)
    ]
}

enum SelectorControlProperty: PropertySet {
    case currentItem, availableItems, itemName
    
    static let descriptors: [SelectorControlProperty: PropertyDescriptor] = [
        .currentItem: PropertyDescriptor(kCMIOSelectorControlPropertyCurrentItem, .uint32),
        .availableItems: PropertyDescriptor(kCMIOSelectorControlPropertyAvailableItems, .arrayOfUInt32s),
        .itemName: PropertyDescriptor(kCMIOSelectorControlPropertyItemName, .string),
    ]
}

enum FeatureControlProperty: PropertySet {
    case onOff, automaticManual, absoluteNative, tune, nativeValue, absoluteValue,
        nativeRange, absoluteRange, convertNativeToAbsolute, convertAbsoluteToNative,
        absoluteUnitName
    
    static let descriptors: [FeatureControlProperty: PropertyDescriptor] = [
        .onOff: PropertyDescriptor(kCMIOFeatureControlPropertyOnOff, .boolean32),
        .automaticManual: PropertyDescriptor(kCMIOFeatureControlPropertyAutomaticManual, .boolean32),
        .absoluteNative: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteNative, .boolean32),
        .tune: PropertyDescriptor(kCMIOFeatureControlPropertyTune, .boolean32),
        .nativeValue: PropertyDescriptor(kCMIOFeatureControlPropertyNativeValue, .float32),
        .absoluteValue: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteValue, .float32),
        .nativeRange: PropertyDescriptor(kCMIOFeatureControlPropertyNativeRange, .audioValueRange),
        .absoluteRange: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteRange, .audioValueRange),
        .convertNativeToAbsolute: PropertyDescriptor(kCMIOFeatureControlPropertyConvertNativeToAbsolute, .float32),
        .convertAbsoluteToNative: PropertyDescriptor(kCMIOFeatureControlPropertyConvertAbsoluteToNative, .float32),
        .absoluteUnitName: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteUnitName, .string)
    ]
}

enum ExposureControlProperty: PropertySet {
    case regionOfInterest, lockThreshold, unlockThreshold, target, convergenceSpeed,
        stability, stable, integrationTime, maximumGain
    
    static let descriptors: [ExposureControlProperty: PropertyDescriptor] = [
        .regionOfInterest: PropertyDescriptor(kCMIOExposureControlPropertyRegionOfInterest, .cgRect),
        .lockThreshold: PropertyDescriptor(kCMIOExposureControlPropertyLockThreshold, .float32),
        .unlockThreshold: PropertyDescriptor(kCMIOExposureControlPropertyUnlockThreshold, .float32),
        .target: PropertyDescriptor(kCMIOExposureControlPropertyTarget, .float32),
        .convergenceSpeed: PropertyDescriptor(kCMIOExposureControlPropertyConvergenceSpeed, .float32),
        .stability: PropertyDescriptor(kCMIOExposureControlPropertyStability, .float32),
        .stable: PropertyDescriptor(kCMIOExposureControlPropertyStable, .boolean),
        .integrationTime: PropertyDescriptor(kCMIOExposureControlPropertyIntegrationTime, .float32),
        .maximumGain: PropertyDescriptor(kCMIOExposureControlPropertyMaximumGain, .float32)
    ]
}

extension CMIOClassID {
    private static let booleanControlClassIDs: Set<Int> = [
        kCMIOJackControlClassID,
        kCMIODirectionControlClassID
    ]

    private static let selectorControlClassIDs: Set<Int> = [
        kCMIODataSourceControlClassID,
        kCMIODataDestinationControlClassID
    ]

    private static let featureControlClassIDs: Set<Int> = [
        kCMIOBlackLevelControlClassID,
        kCMIOWhiteLevelControlClassID,
        kCMIOHueControlClassID,
        kCMIOSaturationControlClassID,
        kCMIOContrastControlClassID,
        kCMIOSharpnessControlClassID,
        kCMIOBrightnessControlClassID,
        kCMIOGainControlClassID,
        kCMIOIrisControlClassID,
        kCMIOShutterControlClassID,
        kCMIOExposureControlClassID,
        kCMIOWhiteBalanceUControlClassID,
        kCMIOWhiteBalanceVControlClassID,
        kCMIOWhiteBalanceControlClassID,
        kCMIOGammaControlClassID,
        kCMIOTemperatureControlClassID,
        kCMIOZoomControlClassID,
        kCMIOFocusControlClassID,
        kCMIOPanControlClassID,
        kCMIOTiltControlClassID,
        kCMIOOpticalFilterClassID,
        kCMIOBacklightCompensationControlClassID,
        kCMIOPowerLineFrequencyControlClassID,
        kCMIONoiseReductionControlClassID,
        kCMIOPanTiltAbsoluteControlClassID,
        kCMIOPanTiltRelativeControlClassID,
        kCMIOZoomRelativeControlClassID
    ]

    func isSubclass(of baseClassID: CMIOClassID) -> Bool {
        switch Int(baseClassID) {
        case kCMIOObjectClassID: return true
        case kCMIOControlClassID:
            switch Int(self) {
            case kCMIOControlClassID,
                kCMIOBooleanControlClassID,
                kCMIOSelectorControlClassID,
                kCMIOFeatureControlClassID:
                return true
            case _ where CMIOClassID.booleanControlClassIDs.contains(Int(self)):
                return true
            case _ where CMIOClassID.selectorControlClassIDs.contains(Int(self)):
                return true
            case _ where CMIOClassID.featureControlClassIDs.contains(Int(self)):
                return true
            default:
                return false
            }
            
        case kCMIOBooleanControlClassID:
            return Int(self) == kCMIOBooleanControlClassID || CMIOClassID.booleanControlClassIDs.contains(Int(self))
            
        case kCMIOSelectorControlClassID:
            return Int(self) == kCMIOSelectorControlClassID || CMIOClassID.selectorControlClassIDs.contains(Int(self))
            
        case kCMIOFeatureControlClassID:
            return Int(self) == kCMIOFeatureControlClassID || CMIOClassID.featureControlClassIDs.contains(Int(self))
            
        default:
            return Int(self) == baseClassID
        }
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


func propertyDescription(for selector: CMIOObjectPropertySelector, ofType type: PropertyType, in objectID: CMIOObjectID) -> String? {
    switch type {
    case .boolean:
        if let value: DarwinBoolean = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .boolean32:
        if let value: UInt32 = PropertyType.podTypeValue(for: selector, in: objectID) {
            return value != 0 ? "true (\(value))" : "false (0)"
        }
    case .int32, .uint32:
        if let value: UInt32 = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .uint64:
        if let value: UInt64 = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .float32:
        if let value: Float32 = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .float64:
        if let value: Float64 = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .fourCC, .classID:
        if let value: CMIOClassID = PropertyType.podTypeValue(for: selector, in: objectID) {
            if let fcc = fourCCDescription(from: value) {
                return "\(fcc)"
            }
            return "\(value)"
        }
    case .objectID, .deviceID:
        if let value: CMIOObjectID = PropertyType.podTypeValue(for: selector, in: objectID) {
            return value != kCMIOObjectUnknown ? "@\(value)" : "<null>"
        }
    case .audioValueTranslation:
        return "<function>"
    case .audioValueRange:
        if let value: AudioValueRange = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "AudioValueRange {\(value.mMinimum), \(value.mMaximum)}"
        }
    case .propertyAddress:
        if let value: CMIOObjectPropertyAddress = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "CMIOObjectPropertyAddress {\(fourCCDescription(from: value.mSelector)!), " +
                "\(fourCCDescription(from: value.mScope)!), \(fourCCDescription(from: value.mElement)!)"
        }
    case .streamConfiguration:
        if let value: CMIODeviceStreamConfiguration = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .pid:
        if let value: pid_t = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
//    case .componentDescription:
//        if let value: ComponentDescription = PropertyType.podTypeValue(for: selector, in: objectID) {
//            return "\(value)"
//        }
    case .time:
        if let value: CMTime = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "CMTime {\(value.value) / \(value.timescale)}"
        }
    case .cgRect:
        if let value: CGRect = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "CGRect {{\(value.origin.x), \(value.origin.y)}, {\(value.size.width), \(value.size.height)}}"
        }
    case .streamDeck:
        if let value: CMIOStreamDeck = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .smpteCallback:
        if let value: CMIODeviceSMPTETimeCallback = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .scheduledOutputCallback:
        if let value: CMIOStreamScheduledOutputNotificationProcAndRefCon = PropertyType.podTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
        
    case .arrayOfUInt32s:
        if let value: [UInt32] = PropertyType.podArrayTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .arrayOfFloat64s:
        if let value: [Float64] = PropertyType.podArrayTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .arrayOfDeviceIDs, .arrayOfObjectIDs, .arrayOfStreamIDs:
        if let value: [CMIOObjectID] = PropertyType.podArrayTypeValue(for: selector, in: objectID) {
            return "[" + value.map { $0 != kCMIOObjectUnknown ? "@\($0)" : "<null>" }.joined(separator: ", ") + "]"
        }
    case .arrayOfAudioValueRanges:
        if let value: [AudioValueRange] = PropertyType.podArrayTypeValue(for: selector, in: objectID) {
            return "[" + value.map { "AudioValueRange {\($0.mMinimum), \($0.mMaximum)}" }.joined(separator: ", ") + "]"
        }
        
    case .string:
        if let value: CFString = PropertyType.cfTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .formatDescription:
        if let value: CMFormatDescription = PropertyType.cfTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .sampleBuffer:
        if let value: CMSampleBuffer = PropertyType.cfTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }
    case .clock:
        if let value: CFTypeRef = PropertyType.cfTypeValue(for: selector, in: objectID) {
            return "\(value)"
        }

    case .arrayOfFormatDescriptions:
        if let value: [CMFormatDescription] = PropertyType.cfArrayTypeValue(for: selector, in: objectID) {
            return "[" + value.map { "\($0)" }.joined(separator: ", ") + "]"
        }

    default:
        break
    }
    return nil
}
