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
        case pod, podArray, cf, cfArray
    }
    
    case boolean, int32, uint32, uint64, float64,
        classID, objectID, deviceID,
        audioValueTranslation, propertyAddress, streamConfiguration, streamDeck,
        pid,
        smpteCallback, scheduledOutputCallback,
        componentDescription, time
    case arrayOfDeviceIDs, arrayOfObjectIDs, arrayOfStreamIDs, arrayOfFloat64s, arrayOfAudioValueRanges
    case string, formatDescription, sampleBuffer, clock
    case arrayOfFormatDescriptions

    var kind: Kind {
        switch self {
        case .boolean, .int32, .uint32, .uint64, .float64,
             .classID, .objectID, .deviceID,
             .audioValueTranslation, .propertyAddress, .streamConfiguration, .streamDeck,
             .pid,
             .smpteCallback, .scheduledOutputCallback,
             .componentDescription, .time:
            return .pod
        case .arrayOfDeviceIDs, .arrayOfObjectIDs, .arrayOfStreamIDs, .arrayOfFloat64s, .arrayOfAudioValueRanges:
            return .podArray
        case .string, .formatDescription, .sampleBuffer, .clock:
            return .cf
        case .arrayOfFormatDescriptions:
            return .cfArray
        }
    }
    
    static func podTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> T? {
        return podArrayTypeValue(for: selector, in: objectID)?.first
    }

    static func podArrayTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> [T]? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address, 0, nil, &dataSize)
        guard status == 0 else {
//            throw CMIOError.osStatus(status)
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
        return cfArrayTypeValue(for: selector, in: objectID)?.first
    }

    static func cfArrayTypeValue<T>(for selector: CMIOObjectPropertySelector, in objectID: CMIOObjectID) -> [T]? {
        var address = CMIOObjectPropertyAddress(selector)
        var dataSize: UInt32 = 0
        
        var status = CMIOObjectGetPropertyDataSize(objectID, &address, 0, nil, &dataSize)
        guard status == 0 else {
//            throw CMIOError.osStatus(status)
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
        .processIsMaster: PropertyDescriptor(kCMIOHardwarePropertyProcessIsMaster, .boolean),
        .isInitingOrExiting: PropertyDescriptor(kCMIOHardwarePropertyIsInitingOrExiting, .boolean),
        .devices: PropertyDescriptor(kCMIOHardwarePropertyDevices, .arrayOfDeviceIDs),
        .defaultInputDevice: PropertyDescriptor(kCMIOHardwarePropertyDefaultInputDevice, .deviceID),
        .defaultOutputDevice: PropertyDescriptor(kCMIOHardwarePropertyDefaultOutputDevice, .deviceID),
        .deviceForUID: PropertyDescriptor(kCMIOHardwarePropertyDeviceForUID, .audioValueTranslation),
        .sleepingIsAllowed: PropertyDescriptor(kCMIOHardwarePropertySleepingIsAllowed, .boolean),
        .unloadingIsAllowed: PropertyDescriptor(kCMIOHardwarePropertyUnloadingIsAllowed, .boolean),
        .plugInForBundleID: PropertyDescriptor(kCMIOHardwarePropertyPlugInForBundleID, .audioValueTranslation),
        .userSessionIsActiveOrHeadless: PropertyDescriptor(kCMIOHardwarePropertyUserSessionIsActiveOrHeadless, .boolean),
        .suspendedBySystem: PropertyDescriptor(kCMIOHardwarePropertySuspendedBySystem, .boolean),
        .allowScreenCaptureDevices: PropertyDescriptor(kCMIOHardwarePropertyAllowScreenCaptureDevices, .boolean),
        .allowWirelessScreenCaptureDevices: PropertyDescriptor(kCMIOHardwarePropertyAllowWirelessScreenCaptureDevices, .boolean)
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
        .transportType: PropertyDescriptor(kCMIODevicePropertyTransportType, .uint32),
        .deviceIsAlive: PropertyDescriptor(kCMIODevicePropertyDeviceIsAlive, .boolean),
        .deviceHasChanged: PropertyDescriptor(kCMIODevicePropertyDeviceHasChanged, .boolean),
        .deviceIsRunning: PropertyDescriptor(kCMIODevicePropertyDeviceIsRunning, .boolean),
        .deviceIsRunningSomewhere: PropertyDescriptor(kCMIODevicePropertyDeviceIsRunningSomewhere, .boolean),
        .deviceCanBeDefaultDevice: PropertyDescriptor(kCMIODevicePropertyDeviceCanBeDefaultDevice, .boolean),
        .hogMode: PropertyDescriptor(kCMIODevicePropertyHogMode, .boolean),
        .latency: PropertyDescriptor(kCMIODevicePropertyLatency, .uint32),
        .streams: PropertyDescriptor(kCMIODevicePropertyStreams, .arrayOfStreamIDs),
        .streamConfiguration: PropertyDescriptor(kCMIODevicePropertyStreamConfiguration, .streamConfiguration),
        .deviceMaster: PropertyDescriptor(kCMIODevicePropertyDeviceMaster, .pid),
        .excludeNonDALAccess: PropertyDescriptor(kCMIODevicePropertyExcludeNonDALAccess, .boolean),
        .clientSyncDiscontinuity: PropertyDescriptor(kCMIODevicePropertyClientSyncDiscontinuity, .boolean),
        .smpteTimeCallback: PropertyDescriptor(kCMIODevicePropertySMPTETimeCallback, .smpteCallback),
        .canProcessAVCCommand: PropertyDescriptor(kCMIODevicePropertyCanProcessAVCCommand, .boolean),
        .avcDeviceType: PropertyDescriptor(kCMIODevicePropertyAVCDeviceType, .uint32),
        .avcDeviceSignalMode: PropertyDescriptor(kCMIODevicePropertyAVCDeviceSignalMode, .uint32),
        .canProcessRS422Command: PropertyDescriptor(kCMIODevicePropertyCanProcessRS422Command, .boolean),
        .linkedCoreAudioDeviceUID: PropertyDescriptor(kCMIODevicePropertyLinkedCoreAudioDeviceUID, .string),
        .videoDigitizerComponents: PropertyDescriptor(kCMIODevicePropertyVideoDigitizerComponents, .componentDescription),
        .suspendedByUser: PropertyDescriptor(kCMIODevicePropertySuspendedByUser, .boolean),
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
        .endOfData: PropertyDescriptor(kCMIOStreamPropertyEndOfData, .boolean),
        .clock: PropertyDescriptor(kCMIOStreamPropertyClock, .clock),
        .canProcessDeckCommand: PropertyDescriptor(kCMIOStreamPropertyCanProcessDeckCommand, .boolean),
        .deck: PropertyDescriptor(kCMIOStreamPropertyDeck, .streamDeck),
        .deckFrameNumber: PropertyDescriptor(kCMIOStreamPropertyDeckFrameNumber, .uint64),
        .deckDropness: PropertyDescriptor(kCMIOStreamPropertyDeckDropness, .boolean),
        .deckThreaded: PropertyDescriptor(kCMIOStreamPropertyDeckThreaded, .boolean),
        .deckLocal: PropertyDescriptor(kCMIOStreamPropertyDeckLocal, .boolean),
        .deckCueing: PropertyDescriptor(kCMIOStreamPropertyDeckCueing, .int32),
        .initialPresentationTimeStampForLinkedAndSyncedAudio: PropertyDescriptor(kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio, .time),
        .scheduledOutputNotificationProc: PropertyDescriptor(kCMIOStreamPropertyScheduledOutputNotificationProc, .scheduledOutputCallback),
        .preferredFormatDescription: PropertyDescriptor(kCMIOStreamPropertyPreferredFormatDescription, .formatDescription),
        .preferredFrameRate: PropertyDescriptor(kCMIOStreamPropertyPreferredFrameRate, .float64)
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


