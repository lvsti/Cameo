//
//  Properties.swift
//  CMIOKit
//
//  Created by Tamás Lustyik on 2018. 12. 25..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO


public enum ObjectProperty: PropertySetInternal {
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
        .ownedObjects: PropertyDescriptor(kCMIOObjectPropertyOwnedObjects, .array(.objectID), .optionallyQualifiedRead(.array(.classID)))
    ]
}

public enum SystemProperty: PropertySetInternal {
    case processIsMaster, isInitingOrExiting, devices, defaultInputDevice, defaultOutputDevice,
        deviceForUID, sleepingIsAllowed, unloadingIsAllowed, plugInForBundleID,
        userSessionIsActiveOrHeadless, suspendedBySystem, allowScreenCaptureDevices,
        allowWirelessScreenCaptureDevices
    
    static let descriptors: [SystemProperty: PropertyDescriptor] = [
        .processIsMaster: PropertyDescriptor(kCMIOHardwarePropertyProcessIsMaster, .boolean32),
        .isInitingOrExiting: PropertyDescriptor(kCMIOHardwarePropertyIsInitingOrExiting, .boolean32),
        .devices: PropertyDescriptor(kCMIOHardwarePropertyDevices, .array(.objectID)),
        .defaultInputDevice: PropertyDescriptor(kCMIOHardwarePropertyDefaultInputDevice, .objectID),
        .defaultOutputDevice: PropertyDescriptor(kCMIOHardwarePropertyDefaultOutputDevice, .objectID),
        .deviceForUID: PropertyDescriptor(kCMIOHardwarePropertyDeviceForUID, .audioValueTranslation, .translation(.string, .objectID)),
        .sleepingIsAllowed: PropertyDescriptor(kCMIOHardwarePropertySleepingIsAllowed, .boolean32),
        .unloadingIsAllowed: PropertyDescriptor(kCMIOHardwarePropertyUnloadingIsAllowed, .boolean32),
        .plugInForBundleID: PropertyDescriptor(kCMIOHardwarePropertyPlugInForBundleID, .audioValueTranslation, .translation(.string, .objectID)),
        .userSessionIsActiveOrHeadless: PropertyDescriptor(kCMIOHardwarePropertyUserSessionIsActiveOrHeadless, .boolean32),
        .suspendedBySystem: PropertyDescriptor(kCMIOHardwarePropertySuspendedBySystem, .boolean32),
        .allowScreenCaptureDevices: PropertyDescriptor(kCMIOHardwarePropertyAllowScreenCaptureDevices, .boolean32),
        .allowWirelessScreenCaptureDevices: PropertyDescriptor(kCMIOHardwarePropertyAllowWirelessScreenCaptureDevices, .boolean32)
    ]
}

public enum DeviceProperty: PropertySetInternal {
    case plugIn, deviceUID, modelUID, transportType, deviceIsAlive, deviceHasChanged, deviceIsRunning,
        deviceIsRunningSomewhere, deviceCanBeDefaultDevice, hogMode, latency, streams,
        streamConfiguration, deviceMaster, excludeNonDALAccess, clientSyncDiscontinuity, smpteTimeCallback,
        canProcessAVCCommand, avcDeviceType, avcDeviceSignalMode, canProcessRS422Command, linkedCoreAudioDeviceUID,
        videoDigitizerComponents, suspendedByUser, linkedAndSyncedCoreAudioDeviceUID, iidcInitialUnitSpace,
        iidcCSRData, canSwitchFrameRatesWithoutFrameDrops, location, hasStreamingError

    static let descriptors: [DeviceProperty: PropertyDescriptor] = [
        .plugIn: PropertyDescriptor(kCMIODevicePropertyPlugIn, .objectID),
        .deviceUID: PropertyDescriptor(kCMIODevicePropertyDeviceUID, .string),
        .modelUID: PropertyDescriptor(kCMIODevicePropertyModelUID, .string),
        .transportType: PropertyDescriptor(kCMIODevicePropertyTransportType, .uint32),
        .deviceIsAlive: PropertyDescriptor(kCMIODevicePropertyDeviceIsAlive, .boolean32),
        .deviceHasChanged: PropertyDescriptor(kCMIODevicePropertyDeviceHasChanged, .boolean32),
        .deviceIsRunning: PropertyDescriptor(kCMIODevicePropertyDeviceIsRunning, .boolean32),
        .deviceIsRunningSomewhere: PropertyDescriptor(kCMIODevicePropertyDeviceIsRunningSomewhere, .boolean32),
        .deviceCanBeDefaultDevice: PropertyDescriptor(kCMIODevicePropertyDeviceCanBeDefaultDevice, .boolean32),
        .hogMode: PropertyDescriptor(kCMIODevicePropertyHogMode, .pid),
        .latency: PropertyDescriptor(kCMIODevicePropertyLatency, .uint32),
        .streams: PropertyDescriptor(kCMIODevicePropertyStreams, .array(.objectID)),
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
        .videoDigitizerComponents: PropertyDescriptor(kCMIODevicePropertyVideoDigitizerComponents, .array(.componentDescription)),
        .suspendedByUser: PropertyDescriptor(kCMIODevicePropertySuspendedByUser, .boolean32),
        .linkedAndSyncedCoreAudioDeviceUID: PropertyDescriptor(kCMIODevicePropertyLinkedAndSyncedCoreAudioDeviceUID, .string),
        .iidcInitialUnitSpace: PropertyDescriptor(kCMIODevicePropertyIIDCInitialUnitSpace, .uint32),
        .iidcCSRData: PropertyDescriptor(kCMIODevicePropertyIIDCCSRData, .uint32, .qualifiedRead(.uint32)),
        .canSwitchFrameRatesWithoutFrameDrops: PropertyDescriptor(kCMIODevicePropertyCanSwitchFrameRatesWithoutFrameDrops, .boolean),
        .location: PropertyDescriptor(kCMIODevicePropertyLocation, .uint32),
        
        // macOS 10.15+
        .hasStreamingError: PropertyDescriptor(0x73657272, .uint32), // kCMIODevicePropertyDeviceHasStreamingError
    ]
}

public enum StreamProperty: PropertySetInternal {
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
        .formatDescriptions: PropertyDescriptor(kCMIOStreamPropertyFormatDescriptions, .array(.formatDescription)),
        .stillImage: PropertyDescriptor(kCMIOStreamPropertyStillImage, .sampleBuffer, .qualifiedRead(.formatDescription)),
        .stillImageFormatDescriptions: PropertyDescriptor(kCMIOStreamPropertyStillImageFormatDescriptions, .array(.formatDescription)),
        .frameRate: PropertyDescriptor(kCMIOStreamPropertyFrameRate, .float64),
        .minimumFrameRate: PropertyDescriptor(kCMIOStreamPropertyMinimumFrameRate, .float64),
        .frameRates: PropertyDescriptor(kCMIOStreamPropertyFrameRates, .array(.float64), .optionallyQualifiedRead(.formatDescription)),
        .frameRateRanges: PropertyDescriptor(kCMIOStreamPropertyFrameRateRanges, .array(.audioValueRange), .optionallyQualifiedRead(.formatDescription)),
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
        .initialPresentationTimeStampForLinkedAndSyncedAudio: PropertyDescriptor(kCMIOStreamPropertyInitialPresentationTimeStampForLinkedAndSyncedAudio, .time, .qualifiedRead(.time)),
        .scheduledOutputNotificationProc: PropertyDescriptor(kCMIOStreamPropertyScheduledOutputNotificationProc, .scheduledOutputCallback),
        .preferredFormatDescription: PropertyDescriptor(kCMIOStreamPropertyPreferredFormatDescription, .formatDescription),
        .preferredFrameRate: PropertyDescriptor(kCMIOStreamPropertyPreferredFrameRate, .float64)
    ]
}

public enum ControlProperty: PropertySetInternal {
    case scope, element, variant
    
    static let descriptors: [ControlProperty: PropertyDescriptor] = [
        .scope: PropertyDescriptor(kCMIOControlPropertyScope, .propertyScope),
        .element: PropertyDescriptor(kCMIOControlPropertyElement, .propertyElement),
        .variant: PropertyDescriptor(kCMIOControlPropertyVariant, .uint32)
    ]
}

public enum BooleanControlProperty: PropertySetInternal {
    case value
    
    static let descriptors: [BooleanControlProperty: PropertyDescriptor] = [
        .value: PropertyDescriptor(kCMIOBooleanControlPropertyValue, .boolean32)
    ]
}

public enum SelectorControlProperty: PropertySetInternal {
    case currentItem, availableItems, itemName
    
    static let descriptors: [SelectorControlProperty: PropertyDescriptor] = [
        .currentItem: PropertyDescriptor(kCMIOSelectorControlPropertyCurrentItem, .uint32),
        .availableItems: PropertyDescriptor(kCMIOSelectorControlPropertyAvailableItems, .array(.uint32)),
        .itemName: PropertyDescriptor(kCMIOSelectorControlPropertyItemName, .string, .qualifiedRead(.uint32)),
    ]
}

public enum FeatureControlProperty: PropertySetInternal {
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

public enum ExposureControlProperty: PropertySetInternal {
    case regionOfInterest, lockThreshold, unlockThreshold, target, convergenceSpeed,
        stability, stable, integrationTime, maximumGain
    
    static let descriptors: [ExposureControlProperty: PropertyDescriptor] = [
        .regionOfInterest: PropertyDescriptor(kCMIOExposureControlPropertyRegionOfInterest, .rect),
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

struct PropertyDescriptor: Property {
    let selector: CMIOObjectPropertySelector
    let type: PropertyType
    let readSemantics: PropertyReadSemantics
    
    init(_ selector: Int, _ type: PropertyType, _ readSemantics: PropertyReadSemantics = .read) {
        self.selector = CMIOObjectPropertySelector(selector)
        self.type = type
        self.readSemantics = readSemantics
    }
}

protocol PropertySetInternal: PropertySet, Hashable {
    static var descriptors: [Self: PropertyDescriptor] { get }
}

extension PropertySetInternal {
    public var selector: CMIOObjectPropertySelector {
        return Self.descriptors[self]!.selector
    }
    
    public var type: PropertyType {
        return Self.descriptors[self]!.type
    }

    public var readSemantics: PropertyReadSemantics {
        return Self.descriptors[self]!.readSemantics
    }
}
