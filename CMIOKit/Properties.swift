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
    /// A CMIOClassID that identifies the class of the CMIOObject.
    /// Value type: `.classID`
    case `class`
    
    /// A CMIOObjectID that identifies the the CMIOObject that owns the given CMIOObject.
    /// Note that all CMIOObjects are owned by some other CMIOObject. The only exception is
    /// the CMIOSystemObject, for which the value of this property is `kCMIOObjectUnknown`.
    /// Value type: `.objectID`
    case owner
    
    /// A CFString that contains the bundle ID of the plug-in that instantiated the object.
    /// The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case creator
    
    /// A CFString that contains the human readable name of the object. The caller
    /// is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case name
    
    /// A CFString that contains the human readable name of the manufacturer of the hardware
    /// the CMIOObject is a part of. The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case manufacturer
    
    /// A CFString that contains a human readable name for the given element in the given scope.
    /// The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case elementName
    
    /// A CFString that contains a human readable name for the category of the given element
    /// in the given scope. The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case elementCategoryName
    
    /// A CFString that contains a human readable name for the number of the given element
    /// in the given scope. The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case elementNumberName
    
    /// An array of CMIOObjectIDs that represent all the CMIOObjects owned by the given object.
    /// The qualifier is an array of CMIOClassIDs. If it is non-empty, the returned array
    /// of CMIOObjectIDs will only refer to objects whose class is in the qualifier array
    /// or whose is a subclass of one in the qualifier array.
    /// Qualifier type: `[CMIOClassID]`
    /// Value type: `.arrayOfObjectIDs`
    case ownedObjects
    
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
    /// A UInt32 where 1 means that the current process contains the master instance of the DAL.
    /// The master instance of the DAL is the only instance in which plug-ins should
    /// save/restore their devices' settings.
    /// Value type: `.boolean`
    case processIsMaster
    
    /// A UInt32 whose value will be non-zero if the DAL is either in the midst of initializing
    /// or in the midst of exiting the process.
    /// Value type: `.boolean`
    case isInitingOrExiting
    
    /// An array of the CMIODeviceIDs that represent all the devices currently available to the system.
    /// Value type: `.arrayOfObjectIDs`
    case devices
    
    /// The CMIODeviceID of the default input CMIODevice.
    /// Value type: `.objectID`
    case defaultInputDevice
    
    /// The CMIODeviceID of the default output CMIODevice.
    /// Value type: `.objectID`
    case defaultOutputDevice
    
    /// Using a AudioValueTranslation structure, this property translates the input CFStringRef
    /// containing a UID into the CMIODeviceID that refers to the CMIODevice with that UID.
    /// This property will return kCMIODeviceUnknown if the given UID does not match any
    /// currently available CMIODevice.
    /// Translation type: `.string` to `.objectID``
    case deviceForUID
    
    /// A UInt32 where 1 means that the process will allow the CPU to idle sleep even if
    /// there is IO in progress. A 0 means that the CPU will not be allowed to idle
    /// sleep. Note that this property won't affect when the CPU is forced to sleep.
    /// Value type: `.boolean`
    case sleepingIsAllowed
    
    /// A UInt32 where 1 means that this process wants the DAL to unload itself after
    /// a period of inactivity where there are no streams active and no listeners registered
    /// with any CMIOObject.
    /// Value type: `.boolean`
    case unloadingIsAllowed
    
    /// Using a AudioValueTranslation structure, this property translates the input CFString
    /// containing a bundle ID into the CMIOObjectID of the CMIOPlugIn that corresponds to it.
    /// This property will return kCMIOObjectUnkown if the given bundle ID doesn't match any CMIOPlugIns.
    /// Translation type: `.string` to `.objectID``
    case plugInForBundleID
    
    /// A UInt32 where a value other than 0 indicates that the login session of the user
    /// of the process is either an active console session or a headless session.
    /// Value type: `.boolean`
    case userSessionIsActiveOrHeadless
    
    /// A UInt32 where a value of 0 indicates the hardware is not suspended due to a system action,
    /// and a value of 1 means that it is. For example, if a fast user switch occurs, the system
    /// will suspend all devices. While suspended, no operartions can be performed on any devices.
    /// This property is never settable.
    /// Value type: `.boolean`
    case suspendedBySystem
    
    /// A UInt32 where 1 means that screen capture devices will be presented to the process.
    /// A 0 means screen capture devices will be ignored. By default, this property is 1.
    /// Value type: `.boolean`
    case allowScreenCaptureDevices
    
    /// A UInt32 where 1 means that wireless screen capture devices will be presented to the process.
    /// A 0 means wireless screen capture devices will be ignored. By default, this property is 0.
    /// Value type: `.boolean`
    case allowWirelessScreenCaptureDevices
    
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
    /// The CMIOObjectID of the CMIOPlugIn that is hosting the device.
    /// Value type: `.objectID`
    case plugIn
    
    /// A CFString that contains a persistent identifier for the CMIODevice. A CMIODevice's UID is
    /// persistent across boots. The content of the UID string is a black box and may contain
    /// information that is unique to a particular instance of a CMIODevice's hardware or unique
    /// to the CPU. Therefore they are not suitable for passing between CPUs or for identifying
    /// similar models of hardware. The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case deviceUID
    
    /// A CFString that contains a persistent identifier for the model of a CMIODevice. The identifier
    /// is unique such that the identifier from two CMIODevices are equal if and only if the
    /// two CMIODevices are the exact same model from the same manufacturer. Further, the identifier
    /// has to be the same no matter on what machine the CMIODevice appears. The caller is responsible
    /// for releasing the returned CFObject.
    /// Value type: `.string`
    case modelUID
    
    /// A UInt32 whose value indicates how the CMIODevice is connected to the CPU. Constants for
    /// some of the values for this property can be found in <IOKit/audio/IOAudioTypes.h>.
    /// Value type: `.fourCC`
    case transportType
    
    /// A UInt32 where a value of 1 means the device is ready and available and 0 means
    /// the device is unusable and will most likely go away shortly.
    /// Value type: `.boolean`
    case deviceIsAlive
    
    /// The type of this property is a UInt32, but it's value has no meaning. This property exists
    /// so that clients can listen to it and be told when the configuration of the CMIODevice has changed
    /// in ways that cannot otherwise be conveyed through other notifications. In response to
    /// this notification, clients should re-evaluate everything they need to know about the device,
    /// particularly the layout and values of the controls.
    /// Value type: `.boolean`
    case deviceHasChanged
    
    /// A UInt32 where a value of 0 means the CMIODevice is not performing IO and
    /// a value of 1 means that it is.
    /// Value type: `.boolean`
    case deviceIsRunning
    
    /// A UInt32 where 1 means that the CMIODevice is running in at least one process on the system
    /// and 0 means that it isn't running at all.
    /// Value type: `.boolean`
    case deviceIsRunningSomewhere
    
    /// A UInt32 where 1 means that the CMIODevice is a possible selection for
    /// `kCMIOHardwarePropertyDefaultInputDevice` or `kCMIOHardwarePropertyDefaultOutputDevice`
    /// depending on the scope.
    /// Value type: `.boolean`
    case deviceCanBeDefaultDevice
    
    /// A `pid_t` indicating the process that currently owns exclusive access to the CMIODevice
    /// or a value of -1 indicating that the device is currently available to all processes.
    /// Value type: `.pid`
    case hogMode
    
    /// A UInt32 containing the number of frames of latency in the CMIODevice. Note that
    /// input and output latency may differ. Further, the CMIODevice's CMIOStreams may have
    /// additional latency so they should be queried as well. If both the device and
    /// the stream say they have latency, then the total latency for the stream is the
    /// device latency summed with the stream latency.
    /// Value type: `.uint32`
    case latency
    
    /// An array of CMIOStreamIDs that represent the CMIOStreams of the CMIODevice. Note that
    /// if a notification is received for this property, any cached CMIOStreamIDs for the device
    /// become invalid and need to be re-fetched.
    case streams
    /// Value type: `.arrayOfObjectIDs`

    /// This property returns the stream configuration of the device in a `CMIODeviceStreamConfiguration`
    /// which describes the list of streams and the number of channels in each stream.
    /// Value type: `.streamConfiguration`
    case streamConfiguration
    
    /// A `pid_t` indicating the process that currently owns exclusive rights to change
    /// operating properties of the device. A value of -1 indicating that the device is not
    /// currently under the control of a master.
    /// Value type: `.pid`
    case deviceMaster
    
    /// A UInt32 where a value of 0 means the CMIODevice can be accessed by means other than the DAL,
    /// and a value of 1 means that it can't. For example, this could be set to 1 to prevent
    /// a QuickTime video digitizer component from accessing the device even when the DAL is not
    /// actively using it. This property is ONLY present for devices whose `kCMIODevicePropertyHogMode`
    /// is NOT settable.
    /// IMPORTANT NOTE: If there are multiple CMIOPlugIns which support a given device, setting
    /// this property to 1 might exclude it being accessed by the other CMIOPlugIns as well.
    /// Value type: `.boolean`
    case excludeNonDALAccess
    
    /// A Boolean that may be set by a client to direct the driver to flush its internal state.
    /// Some devices (such as HDV devices) require the driver's internal state to be built up in order to
    /// start delivering buffers. A client manipulating a device in preparation for a task may build up
    /// internal state that is not to be a part of the task. For example, moving an HDV device transport
    /// to queue up to a known SMPTE timecode in order to capture data from after that point;
    /// the internal state built-up during the queing is not to be used in the actual capture session.
    /// In this case, the client would set this property to TRUE after the device has been queued
    /// and then set to play.
    /// Value type: `.boolean`
    case clientSyncDiscontinuity
    
    /// A `CMIODeviceSMPTETimeCallback` structure that specifies a routine for the driver to call
    /// when it needs SMPTE timecode information. Some devices require external means known only to
    /// their client to provide SMPTE timecode information (for example, devices conforming
    /// to the HDV-1 standard do not provide SMPTE timecode information in the HDV datastream);
    /// the HDV device driver may call a provided SMPTE timecode callback when it needs the data.
    /// Value type: `.smpteTimeCallback`
    case smpteTimeCallback
    
    /// A Boolean that indicates whether or not the device can process AVC commands.
    /// This property is never settable.
    /// Value type: `.boolean`
    case canProcessAVCCommand
    
    /// A UInt32 that reports the AVC device type. This propery is only present for devices
    /// which conform to the AVC class.
    /// Value type: `.uint32`
    case avcDeviceType
    
    /// A UInt32 that reports the streaming modes of the AVC device. This propery is only present
    /// for devices which conform to the AVC class.
    /// Value type: `.uint32`
    case avcDeviceSignalMode
    
    /// A Boolean that indicates whether or not the device can process RS422 commands.
    /// This property is never settable.
    /// Value type: `.boolean`
    case canProcessRS422Command
    
    /// Some CMIODevices implement an audio engine as a separate device (such as the FireWire iSight).
    /// This property allows a CMIODevice to identify a linked CoreAudio device by UID (CFStringRef)
    /// Value type: `.string`
    case linkedCoreAudioDeviceUID
    
    /// An array of `ComponentDescription`s of the video digitizers which control the device.
    /// A client which is using QuickTime's Sequence Grabber & CMIO's DAL can examine this property
    /// to prune the list of video digitizers used, thus avoiding having a device represented
    /// in both domains. (Most devices which implement this property will only report a single
    /// video digitizer, but it is possible that more than one might be reported.)
    /// Value type: `.arrayOfComponentDescriptions`
    case videoDigitizerComponents
    
    /// A UInt32 where a value of 0 indicates the device is not suspended due to a user action,
    /// and a value of 1 means that it is. For example, the user might close the FireWire iSight's
    /// privacy iris or close the clamshell on a Mac Book or Mac Book Pro. While suspended
    /// the device still responds to all requests just as if it was active, but the stream(s)
    /// will not provide/accept any data. This property is never settable.
    /// Value type: `.boolean`
    case suspendedByUser
    
    /// Identical to `kCMIODevicePropertyLinkedCoreAudioDeviceUID`, except that it only returns
    /// a UID if the linked CoreAudio device shares the same hardware clock (CFStringRef)
    /// Value type: `.string`
    case linkedAndSyncedCoreAudioDeviceUID
    
    /// A UInt32 which specifies the initial unit space for IIDC cameras as described in
    /// "IIDC 1394-based Digital Camera Specification Version 1.31" (1394 Trade Association
    /// Document 2003017)." This property is never settable.
    /// Value type: `.uint32`
    case iidcInitialUnitSpace
    
    /// A UInt32 which provides access to control and status registers for IIDC cameras.
    /// The qualifier contains a UInt32 that specifies the register to access. If the register's
    /// offset is relative to the initial unit space, then the qualifier should be the value
    /// returned by `kCMIODevicePropertyIIDCInitialUnitSpace` + offset. If the register's offset
    /// is relative to the initial register space, then the qualifier should be $F0000000 + offset.
    /// Changes in this property never result in a property changed notification.
    /// Qualifier type: `UInt32`
    /// Value type: `.uint32`
    case iidcCSRData
    
    /// A UInt32 where a value of 0 indicates the device's streams will drop frames when altering
    /// frame rates, and a value of 1 means that they won't.
    /// Value type: `.boolean`
    case canSwitchFrameRatesWithoutFrameDrops
    
    /// A UInt32 indicating the location of the device (for values see
    /// `kCMIODevicePropertyLocationUnknown`, etc., below).
    /// Value type: `.fourCC`
    case location
    
    /// A UInt32 where 1 means that the CMIODevice failed to stream.
    /// Value type: `.boolean`
    case hasStreamingError

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
        .location: PropertyDescriptor(kCMIODevicePropertyLocation, .fourCC),
        
        // macOS 10.15+
        .hasStreamingError: PropertyDescriptor(0x73657272, .uint32), // kCMIODevicePropertyDeviceHasStreamingError
    ]
}

public enum StreamProperty: PropertySetInternal {
    /// A UInt32 where a value of 0 means that this CMIOStream is an output stream and
    /// a value of 1 means that it is an input stream.
    /// Value type: `.uint32`
    case direction
    
    /// A UInt32 whose value describes the general kind of functionality attached to the CMIOStream.
    /// Constants that describe some of the values of this property are defined
    /// in <IOKit/audio/IOAudioTypes.h>
    /// Value type: `.boolean`
    case terminalType
    
    /// A UInt32 that specifies the first element in the owning device that corresponds to
    /// element one of this stream.
    /// Value type: `.uint32`
    case startingChannel
    
    /// A UInt32 containing the number of frames of latency in the CMIOStream. Note that
    /// the owning CMIODevice may have additional latency so it should be queried as well.
    /// If both the device and the stream say they have latency, then the total latency
    /// for the stream is the device latency summed with the stream latency.
    /// Value type: `.uint32`
    case latency
    
    /// A `CMFormatDescriptionRef` that describes the current format for the CMIOStream.
    /// When getting this property, the client must release the `CMFormatDescriptionRef`
    /// when done with it. If settable, either one of the `CMFormatDescriptionRef`s obtained
    /// by getting the `kCMIOStreamPropertyFormatDescriptions` property can be used, or a new
    /// `CMFormatDescriptionRef` can be provided. In the event of the latter, the
    /// `CMFormatDescriptionEquals()` routine will be used to see if the stream can support
    /// the provided `CMFormatDescriptionRef`.
    /// Value type: `.formatDescription`
    case formatDescription
    
    /// A `CFArray` of `CMFormatDescriptionRef`s that describe the available data formats for the CMIOStream.
    /// The client must release the CFArray when done with it. This property is never settable,
    /// and is not present for streams whose `kCMIOStreamPropertyFormatDescription` property is not settable.
    /// Value type: `.arrayOfFormatDescriptions`
    case formatDescriptions
    
    /// A `CMSampleBufferRef` which holds a still image that is generated as soon as possible
    /// when getting this property. The client must release the `CMSampleBufferRef` when done with it.
    /// The qualifier contains the desired `CMFormatDescriptionRef` of the still. The description can be
    /// one of those obtained by getting the `kCMIOStreamPropertyStillImageFormatDescriptions` property,
    /// or a new `CMFormatDescriptionRef` can be provided. In the event of the latter, the `CMFormatDescriptionEquals()`
    /// routine will be used to see if the stream can support the provided `CMFormatDescriptionRef`.
    /// Getting this property might inject a discontinuity into the stream if it currently running,
    /// depending on the underlying hardware. The returned image might not have the same `CMFormatDescriptionRef`
    /// that was requested. This property is never settable, and is not present for streams
    /// which are unable to produce still images.
    /// Qualifier type: `CMFormatDescriptionRef`
    /// Value type: `.sampleBuffer`
    case stillImage
    
    /// A `CFArray` of `CMFormatDescriptionRef`s that describe the available still image data formats
    /// for the CMIOStream. The client must release the `CFArray` when done with it. This property
    /// is never settable, and is not present for streams which are unable to produce still images.
    /// Value type: `.arrayOfFormatDescriptions`
    case stillImageFormatDescriptions
    
    /// A `Float64` that indicates the current video frame rate of the CMIOStream. The frame rate
    /// might fall below this, but it will not exceed it. This property is only present for muxed or
    /// video streams which can determine their rate.
    /// Value type: `.float64`
    case frameRate
    
    /// A `Float64` that indicates the minumum video frame rate of the CMIOStream. This property
    /// is only present for muxed or video streams which can determine their rate and guarantee a minimum rate.
    /// Value type: `.float64`
    case minimumFrameRate
    
    /// An array of `Float64`s that indicates the valid values for the video frame rate of the CMIOStream.
    /// This property is only present for muxed or video streams which can determine their rate.
    /// Moreover, it is limited to the rates that correspond to a single `CMFormatDescriptionRef`,
    /// as opposed to the super set of rates that would be associated with the full set of available
    /// `CMFormatDescriptionRef`s. If no qualifier is used, the rates of the current format (as reported
    /// via `kCMIOStreamPropertyFormatDescription`) will be returned. If a qualifier is present, it contains
    /// the `CMFormatDescriptionRef` whose frame rates are desired. The description can be one of those
    /// obtained by getting the `kCMIOStreamPropertyFormatDescriptions` property, or a new `CMFormatDescriptionRef`
    /// can be provided. In the event of the latter, the `CMFormatDescriptionEquals()` routine will be used
    /// to see if the stream can support the provided `CMFormatDescriptionRef`.
    /// Qualifier type: `CMFormatDescriptionRef`
    /// Value type: `.arrayOfFloat64s`
    case frameRates
    
    /// An array of `AudioValueRange`s that contains the minimum and maximum ranges for the video frame rate
    /// of the CMIOStream. If no qualifier is used, the frame rate ranges of the current format
    /// (as reported via `kCMIOStreamPropertyFormatDescription`) will be returned. If a qualifier is present,
    /// it contains the `CMFormatDescriptionRef` whose frame rate ranges are desired. The description
    /// can be one of those obtained by getting the `kCMIOStreamPropertyFormatDescriptions` property,
    /// or a new `CMFormatDescriptionRef` can be provided. In the event of the latter, the
    /// `CMFormatDescriptionEquals()` routine will be used to see if the stream can support
    /// the provided `CMFormatDescriptionRef`.
    /// Qualifier type: `CMFormatDescriptionRef`
    /// Value type: `.arrayOfAudioValueRanges`
    case frameRateRanges
    
    /// A `UInt32` that allows a client to specify how much time (in milliseconds) that a device
    /// should allow to go by without seeing data before it determines that it is experiencing
    /// a period of "no data." The default value is device dependent.
    /// Value type: `.uint32`
    case noDataTimeoutInMSec
    
    /// A `UInt32` that allows a client to specify how much time (in milliseconds) that a device
    /// should allow to go by without seeing data before it determines that there is a serious problem,
    /// and will never see data. A value of 0 means to ignore checking for the condition. When non-zero,
    /// the value takes precedence over `kCMIOStreamPropertyNoDataTimeoutInMSec`. This property is set
    /// by a client when it starts a device and knows by apriori means that data is present;
    /// once the client starts seeing data, this value should be reset to 0 by the client.
    /// When setting the value, the client should use a value that is long enough to take into account
    /// the amount of time the device may need to start up (including, if it has one, starting a transport).
    /// A time of 10000ms (10 seconds) is reasonable.
    /// Value type: `.uint32`
    case deviceSyncTimeoutInMSec
    
    /// A `UInt32` that is incremented every time a period of no data is determined (via the
    /// previous two properties). A client can listen to this property to get notifications
    /// that no-data events have occured.
    /// Value type: `.uint32`
    case noDataEventCount
    
    /// A `UInt32` that is incremented every time a stream's buffers are not being serviced fast enough
    /// (such as a DCL overrun when transmitting to a FireWire device).
    /// Value type: `.uint32`
    case outputBufferUnderrunCount
    
    /// A `UInt32` indicating how many times the last output buffer is re-presented to the device
    /// when no fresh output buffers are available.
    /// Value type: `.uint32`
    case outputBufferRepeatCount
    
    /// A `UInt32` property that allows a client to control how large a queue to hold buffers
    /// that are to be sent to the stream; the larger the queue, the more latency until a
    /// buffer reaches the stream, but the less likelyhood that data will have to be repeated
    /// (or that the stream will run dry). Default value depends on the stream.
    /// Value type: `.uint32`
    case outputBufferQueueSize
    
    /// A `UInt32` that allows a client to control how many buffers should be accumulated
    /// before actually starting to pass them onto the stream. Default value is to use
    /// 1/2 of the `kCMIOStreamPropertyOutputBufferQueueSize`.
    /// Value type: `.uint32`
    case outputBuffersRequiredForStartup
    
    /// A `UInt32` indicating the minimum number of buffers required for the stream to maintain
    /// throttled playback without dropping frames. Interested clients can use this to throttle
    /// the number of buffers in flight to avoid sending out more frames than necessary, thus
    /// helping with memory usage and responsiveness.
    /// Value type: `.uint32`
    case outputBuffersNeededForThrottledPlayback
    
    /// A `CMTime` that specifies the presentation timestamp for the first buffer sent to a device;
    /// used for startup sync. This property is never settable.
    /// Value type: `.time`
    case firstOutputPresentationTimeStamp
    
    /// A `UInt32` where a value of 1 means that the stream has reached the end of its data
    /// and a value of 0 means that more data is available.
    /// Value type: `.boolean`
    case endOfData
    
    /// A `CFTypeRef` that encapsulates a clock abstraction for a device's stream. The clock
    /// can be created with `CMIOStreamClockCreate`.
    /// Value type: `.clock`
    case clock
    
    /// A Boolean that indicates whether or not the stream can process deck commands.
    /// This property is never settable.
    /// Value type: `.boolean`
    case canProcessDeckCommand
    
    /// A `CMIOStreamDeck` that represents the current status of a deck associated with a CMIO stream.
    /// The definitions of the values in the structure are defined by the deck being controlled.
    /// This property is never settable.
    /// Value type: `.streamDeck`
    case deck
    
    /// A `UInt64` that represents the current frame number read from a deck associated with a stream.
    /// Value type: `.uint64`
    case deckFrameNumber
    
    /// A `UInt32` value that represents the current drop frame state of the deck being controlled.
    /// 1 is dropframe, 0 is non-dropframe. This property is never settable.
    /// Value type: `.boolean`
    case deckDropness
    
    /// A `UInt32` value that represents the deck being controlled's current tape threaded state.
    /// 1 deck is threaded, 0 deck is not threaded. This property is never settable.
    /// Value type: `.boolean`
    case deckThreaded
    
    /// A `UInt32` value that indicates whether the deck is being controlled locally or remotely.
    /// 1 indicates local mode, 0 indicates remote mode. This property is never settable.
    /// Value type: `.boolean`
    case deckLocal
    
    /// A `SInt32` value that represents the current cueing status of the deck being controlled.
    /// 0 = cueing, 1 = cue complete, -1 = cue failed. This property is never settable.
    /// Value type: `.int32`
    case deckCueing
    
    /// A presentation timestamp to be used for a given `AudioTimeStamp` that was received
    /// for audio from the linked and synced CoreAudio audio device that is specified
    /// by `kCMIOStreamPropertyLinkedAndSyncedCoreAudioDeviceUID`. The `AudioTimeStamp` is passed
    /// as the qualifier data. If the DAL device isn't yet read to return a valid time,
    /// it should return `kCMTimeInvalid`. (CMTime)
    /// Qualifier type: `AudioTimeStamp`
    /// Value type: `.time`
    case initialPresentationTimeStampForLinkedAndSyncedAudio
    
    /// A procedure to be called when the stream determines when a buffer was output.
    /// The procedure and a reference constant are specified by a
    /// `CMIOStreamScheduledOutputNotificationProcAndRefCon` structure.
    /// Value type: `.scheduledOutputCallback`
    case scheduledOutputNotificationProc
    
    /// A `CMFormatDescriptionRef` that describes the preferred format for the CMIOStream.
    /// When getting this property, the client must release the `CMFormatDescriptionRef` when
    /// done with it. Either one of the `CMFormatDescriptionRef`s obtained by getting the
    /// `kCMIOStreamPropertyFormatDescriptions` property can be used, or a new `CMFormatDescriptionRef`
    /// can be provided. In the event of the latter, the `FigFormatDescriptionEquals()` routine
    /// will be used to see if the stream can support the provided `CMFormatDescriptionRef`.
    /// Setting this property is not a guarantee that the CMIOStream will provide data in this format;
    /// when possible, the CMIOStream will examine all of the values specified by the various clients
    /// sharing it, and select the most appropriate configuration. Typically, the value
    /// set for this property will only have an effect when the stream is active (unlike
    /// `kCMIOStreamPropertyFormatDescription`, which takes place immediately). Note that if the client
    /// is the device master (set using `kCMIODevicePropertyDeviceMaster`), setting the value
    /// of this property *will* directly affect the device, as if `kCMIOStreamPropertyFormatDescription` were used.
    /// Value type: `.formatDescription`
    case preferredFormatDescription
    
    /// A `Float64` that indicates the current preferred video frame rate of the CMIOStream.
    /// Setting this property is not a guarantee that the CMIOStream will operate at that
    /// framerate; when possible, the CMIOStream will examine all of the values specified by
    /// the various clients sharing it, and select the most appropriate configuration.
    /// Typically, the value set for this property will only have an effect when the stream is active
    /// (unlike `kCMIOStreamPropertyFormatDescription`, which takes place immediately).
    /// Note that if the client is the device master (set using `kCMIODevicePropertyDeviceMaster`),
    /// setting the value of this property will directly affect the device, as if
    /// `kCMIOStreamPropertyFormatDescription` were used.
    /// Value type: `.float64`
    case preferredFrameRate
    
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
    /// The `CMIOObjectPropertyScope` in the owning CMIOObject that contains the CMIOControl.
    /// Value type: `.propertyScope`
    case scope
    
    /// The `CMIOObjectPropertyElement` in the owning CMIOObject that contains the CMIOControl.
    /// Value type: `.propertyElement`
    case element
    
    /// A `UInt32` that identifies the specific variant of a CMIOControl. This allows the owning CMIOObject
    /// to support controls that are of the same basic class (that is, the values of `kCMIOObjectPropertyClass`
    /// are the same) but may control a part of the object for which the standard controls do not control.
    /// Value type: `.uint32`
    case variant
    
    static let descriptors: [ControlProperty: PropertyDescriptor] = [
        .scope: PropertyDescriptor(kCMIOControlPropertyScope, .propertyScope),
        .element: PropertyDescriptor(kCMIOControlPropertyElement, .propertyElement),
        .variant: PropertyDescriptor(kCMIOControlPropertyVariant, .uint32)
    ]
}

public enum BooleanControlProperty: PropertySetInternal {
    /// A `UInt32` where 0 means false and 1 means true.
    /// Value type: `.boolean`
    case value
    
    static let descriptors: [BooleanControlProperty: PropertyDescriptor] = [
        .value: PropertyDescriptor(kCMIOBooleanControlPropertyValue, .boolean32)
    ]
}

public enum SelectorControlProperty: PropertySetInternal {
    /// A `UInt32` that is the ID of the item currently selected.
    /// Value type: `.uint32`
    case currentItem
    
    /// An array of `UInt32`s that represent the IDs of all the items available.
    /// Value type: `.arrayOfUInt32s`
    case availableItems

    /// This property translates the given item ID into a human readable name. The qualifier contains
    /// the ID of the item to be translated and name is returned as a CFString as
    /// the property data. The caller is responsible for releasing the returned CFObject.
    /// Qualifier type: `.uint32`
    /// Value type: `.string`
    case itemName
    
    static let descriptors: [SelectorControlProperty: PropertyDescriptor] = [
        .currentItem: PropertyDescriptor(kCMIOSelectorControlPropertyCurrentItem, .uint32),
        .availableItems: PropertyDescriptor(kCMIOSelectorControlPropertyAvailableItems, .array(.uint32)),
        .itemName: PropertyDescriptor(kCMIOSelectorControlPropertyItemName, .string, .qualifiedRead(.uint32)),
    ]
}

public enum FeatureControlProperty: PropertySetInternal {
    /// A `UInt32` where 1 corresponds to a the feature being on, and 0 corresponds to the feature being off.
    /// Value type: `.boolean`
    case onOff
    
    /// A `UInt32` where 1 corresponds to a the feature being under automatic control,
    /// and 0 corresponds to the feature being under manual control.
    /// Value type: `.boolean`
    case automaticManual
    
    /// A `UInt32` where 1 corresponds to a the feature being programmed with 'absolute' values,
    /// and 0 corresponds to the feature being programmed with 'native' values.
    /// Value type: `.boolean`
    case absoluteNative
    
    /// A `UInt32` where 1 corresponds to a the feature being tuned, and 0 corresponds to
    /// the feature not being tuned. Upon completion of the tuning, the value will automatically
    /// revert back to 0.
    /// Value type: `.boolean`
    case tune
    
    /// A `Float32` that represents the value of the feature. Native values are unitless and
    /// their the meaning can vary from device to device.
    /// Value type: `.float32`
    case nativeValue
    
    /// A `Float32` that represents the value of the value of the feature. Absolute values
    /// have units associated with them, i.e. Gain has dB, Hue has degrees, etc.
    /// Value type: `.float32`
    case absoluteValue
    
    /// An `AudioValueRange` that contains the minimum and maximum native values
    /// the feature control can have.
    /// Value type: `.audioValueRange`
    case nativeRange
    
    /// An `AudioValueRange` that contains the minimum and maximum absolute values
    /// the feature control can have.
    /// Value type: `.audioValueRange`
    case absoluteRange
    
    /// A `Float32` that on input contains a native value for the feature control and on exit
    /// contains the equivalent absolute value.
    /// Translation type: `.float32` to `.float32``
    case convertNativeToAbsolute
    
    /// A `Float32` that on input contains a an abolute value for the feature control and on exit
    /// contains the equivalent native value.
    /// Translation type: `.float32` to `.float32``
    case convertAbsoluteToNative
    
    /// A CFString that contains a human readable name for the units associated with the absolute values.
    /// The caller is responsible for releasing the returned CFObject.
    /// Value type: `.string`
    case absoluteUnitName
    
    static let descriptors: [FeatureControlProperty: PropertyDescriptor] = [
        .onOff: PropertyDescriptor(kCMIOFeatureControlPropertyOnOff, .boolean32),
        .automaticManual: PropertyDescriptor(kCMIOFeatureControlPropertyAutomaticManual, .boolean32),
        .absoluteNative: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteNative, .boolean32),
        .tune: PropertyDescriptor(kCMIOFeatureControlPropertyTune, .boolean32),
        .nativeValue: PropertyDescriptor(kCMIOFeatureControlPropertyNativeValue, .float32),
        .absoluteValue: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteValue, .float32),
        .nativeRange: PropertyDescriptor(kCMIOFeatureControlPropertyNativeRange, .audioValueRange),
        .absoluteRange: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteRange, .audioValueRange),
        .convertNativeToAbsolute: PropertyDescriptor(kCMIOFeatureControlPropertyConvertNativeToAbsolute, .float32, .mutatingRead),
        .convertAbsoluteToNative: PropertyDescriptor(kCMIOFeatureControlPropertyConvertAbsoluteToNative, .float32, .mutatingRead),
        .absoluteUnitName: PropertyDescriptor(kCMIOFeatureControlPropertyAbsoluteUnitName, .string)
    ]
}

public enum ExposureControlProperty: PropertySetInternal {
    /// A `CGRect` with origin and size coordinates in the 0. to 1. space indicating
    /// what portion of the image should be used when auto-exposing.
    /// Value type: `.rect`
    case regionOfInterest
    
    /// A `Float32` indicating a threshold that is treated as the minimum change (in either direction)
    /// that the average Y value of the image needs to stay within for the AutoExposure state machine
    /// to enter the locked state. A higher number creates more hysteresis.
    /// Value type: `.float32`
    case lockThreshold
    
    /// A `Float32` indicating a threshold that is treated as the minimum change (in either direction)
    /// that the average Y value of the image needs to exceed for the AutoExposure state machine
    /// to leave the locked state. A higher number creates more hysteresis.
    /// Value type: `.float32`
    case unlockThreshold
    
    /// A `Float32` indicating the exposure target, which is typically represented
    /// as the average Y value of the image that the firmware auto exposure control tries to achieve.
    /// Higher numbers indicate a more exposed image.
    /// Value type: `.float32`
    case target
    
    /// A `Float32` indicating how fast an auto exposure converges to the AE target.
    /// Higher numbers are faster.
    /// Value type: `.float32`
    case convergenceSpeed
    
    /// A `Float32` to tune the stability of the autoexposure algorithm, indicating how much flicker
    /// will be tolerated prior to adjusting the sensor gain.
    /// Value type: `.float32`
    case stability
    
    /// A Boolean indicating whether the camera has the autoexposure function locked due to
    /// sufficient stability. This result is only valid when the autoexposure function has not been disabled.
    /// Value type: `.boolean`
    case stable
    
    /// A `Float32` to limit the maximum integration-time for the sensor, in milliseconds.
    /// The maximum integration time is also limited by the framerate. Setting the value to
    /// 0.0 indicates no limiting is applied.
    /// Value type: `.float32`
    case integrationTime
    
    /// A `Float32` to limit the maximum allowable gain that the autoexposure algorithm will attempt to use.
    /// Setting the value to 0.0 indicates no limiting is applied.
    /// Value type: `.float32`
    case maximumGain
    
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
