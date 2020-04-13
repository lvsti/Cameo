//
//  Class.swift
//  CMIOKit
//
//  Created by Tamás Lustyik on 2019. 01. 06..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

public extension CMIOClassID {
    /// The CMIOClassID that identifies the CMIOObject class.
    static let object = CMIOClassID(kCMIOObjectClassID)
    
    /// The CMIOClassID that identifies the CMIOSystemObject class.
    static let system = CMIOClassID(kCMIOSystemObjectClassID)
    
    /// The CMIOClassID that identifies the CMIOPlugIn class.
    static let plugIn = CMIOClassID(kCMIOPlugInClassID)
    
    /// The CMIOClassID that identifies the CMIODevice class.
    static let device = CMIOClassID(kCMIODeviceClassID)
    
    /// The CMIOClassID that identifies the CMIOStream class.
    static let stream = CMIOClassID(kCMIOStreamClassID)
    
    /// The CMIOClassID that identifies the CMIOControl class.
    static let control = CMIOClassID(kCMIOControlClassID)
    
    /// The CMIOClassID that identifies the CMIOBooleanControl class which is a subclass of CMIOControl.
    /// CMIOBooleanControls manipulate on/off switches in the hardware.
    static let booleanControl = CMIOClassID(kCMIOBooleanControlClassID)
    
    /// The CMIOClassID that identifies the CMIOSelectorControl class which is a subclass of CMIOControl.
    /// CMIOSelectorControls manipulate controls that have multiple, but discreet values.
    static let selectorControl = CMIOClassID(kCMIOSelectorControlClassID)
    
    /// The CMIOClassID that identifies the CMIOFeatureControl class which is a subclass of CMIOControl.
    /// CMIOFeatureControls manipulate various features that might be present on a device,
    /// such as hue, saturation, zoom, etc.
    static let featureControl = CMIOClassID(kCMIOFeatureControlClassID)

    /// A CMIOBooleanControl where a true value means something is plugged into that element.
    static let jackControl = CMIOClassID(kCMIOJackControlClassID)
    
    /// A CMIOBooleanControl where a true value means the element is operating in input mode,
    /// and false means the element is operating in output mode. This control is only needed
    /// for devices which can do input and output, but not at the same time.
    static let directionControl = CMIOClassID(kCMIODirectionControlClassID)
    
    private static let booleanControlClassIDs: Set<CMIOClassID> = [
        jackControl,
        directionControl
    ]

    /// A CMIOSelectorControl that identifies where the data for the element is coming from.
    static let dataSourceControl = CMIOClassID(kCMIODataSourceControlClassID)
    
    /// A CMIOSelectorControl that identifies where the data for the element is going.
    static let dataDestinationControl = CMIOClassID(kCMIODataDestinationControlClassID)

    private static let selectorControlClassIDs: Set<CMIOClassID> = [
        dataSourceControl,
        dataDestinationControl
    ]

    /// A CMIOFeatureControl that controls the black level offset. The units for the control's
    /// absolute value are percetage (%).
    static let blackLevelControl = CMIOClassID(kCMIOBlackLevelControlClassID)
    
    /// A CMIOFeatureControl that controls the white level offset. The units for the control's
    /// absolute value are percentage (%).
    static let whiteLevelControl = CMIOClassID(kCMIOWhiteLevelControlClassID)
    
    /// A CMIOFeatureControl that controls the hue offset. Positive values mean counterclockwise,
    /// negative values means clockwise on a vector scope. The units for the control's
    /// absolute value are degrees (°).
    static let hueControl = CMIOClassID(kCMIOHueControlClassID)
    
    /// A CMIOFeatureControl that controls color intensity. For example, at high saturation levels,
    /// red appears to be red; at low saturation, red appears as pink. The unit for the control's
    /// absolute value is a percentage (%).
    static let saturationControl = CMIOClassID(kCMIOSaturationControlClassID)
    
    /// A CMIOFeatureControl that controls a the distance bewtween the whitest whites and
    /// blackest blacks. The units for the control's absolute value are percentage (%).
    static let contrastControl = CMIOClassID(kCMIOContrastControlClassID)
    
    /// A CMIOFeatureControl that controls the sharpness of the picture. The units for the control's
    /// absolute value are undefined.
    static let sharpnessControl = CMIOClassID(kCMIOSharpnessControlClassID)
    
    /// A CMIOFeatureControl that controls the intensity of the video level. The units for
    /// the control's absolute value are percetage (%).
    static let brightnessControl = CMIOClassID(kCMIOBrightnessControlClassID)
    
    /// A CMIOFeatureControl that controls the amplification of the signal. The units for
    /// the control's absolute value are decibels (dB).
    static let gainControl = CMIOClassID(kCMIOGainControlClassID)
    
    /// A CMIOFeatureControl that controls a mechanical lens iris. The units for the control's
    /// absolute value are an F number (F).
    static let irisControl = CMIOClassID(kCMIOIrisControlClassID)
    
    /// A CMIOFeatureControl that controls the integration time of the incoming light. The units
    /// for the control's absolute value are seconds (s).
    static let shutterControl = CMIOClassID(kCMIOShutterControlClassID)
    
    /// A CMIOFeatureControl that controls a the total amount of light accumulated. The units
    /// for the control's absolute value are exposure value (EV).
    static let exposureControl = CMIOClassID(kCMIOExposureControlClassID)
    
    /// A CMIOFeatureControl that controls the adjustment of the white color of the picture.
    /// The units for the control's absolute value are kelvin (K).
    static let whiteBalanceUControl = CMIOClassID(kCMIOWhiteBalanceUControlClassID)
    
    /// A CMIOFeatureControl that controls a adjustment of the white color of the picture.
    /// The units for the control's absolute value are kelvin (K).
    static let whiteBalanceVControl = CMIOClassID(kCMIOWhiteBalanceVControlClassID)
    
    /// A CMIOFeatureControl that controls a adjustment of the white color of the picture.
    /// The units for the control's absolute value are kelvin (K).
    static let whiteBalanceControl = CMIOClassID(kCMIOWhiteBalanceControlClassID)
    
    /// A CMIOFeatureControl that defines the function between incoming light level and
    /// output picture level. The units for the control's absolute value are undefined.
    static let gammaControl = CMIOClassID(kCMIOGammaControlClassID)
    
    /// A CMIOFeatureControl that controls the temperature inside of the device and/or
    /// controlling temperature. The units for the control's absolute value are undefined.
    static let temperatureControl = CMIOClassID(kCMIOTemperatureControlClassID)
    
    /// A CMIOFeatureControl that controls the zoom. The units for the control's absolute value
    /// are power where 1 is the wide end.
    static let zoomControl = CMIOClassID(kCMIOZoomControlClassID)
    
    /// A CMIOFeatureControl that controls a focus mechanism. The units for the control's
    /// absolute value are meters (m).
    static let focusControl = CMIOClassID(kCMIOFocusControlClassID)
    
    /// A CMIOFeatureControl that controls a panning mechanism. Positive values mean clockwise,
    /// negative values means counterclockwise. The units for the control's absolute value are degrees (°).
    static let panControl = CMIOClassID(kCMIOPanControlClassID)
    
    /// A CMIOFeatureControl that controls a tilt mechanism. Positive values mean updwards,
    /// negative values means downwards. The units for the control's absolute value are degrees (°).
    static let tiltControl = CMIOClassID(kCMIOTiltControlClassID)
    
    /// A CMIOFeatureControl that controls changing the optical filter of camera lens function.
    /// The units for the control's absolute value are undefined.
    static let opticalFilter = CMIOClassID(kCMIOOpticalFilterClassID)
    
    /// A CMIOFeatureControl that controls the amount of backlight compensation to apply.
    /// A low number indicates the least amount of backlight compensation. The units for the
    /// control's absolute value are undefined.
    static let backlightCompensationControl = CMIOClassID(kCMIOBacklightCompensationControlClassID)
    
    /// A CMIOFeatureControl to specify the power line frequency to properly implement
    /// anti-flicker processing. The units for the contorl's absolute value are hertz (Hz).
    static let powerLineFrequencyControl = CMIOClassID(kCMIOPowerLineFrequencyControlClassID)
    
    /// A CMIOFeatureControl that controls the noise reduction strength. The units for the control's
    /// absolute value are undefined.
    static let noiseReductionControl = CMIOClassID(kCMIONoiseReductionControlClassID)
    
    /// A CMIOFeatureControl that controls a pan/tilt mechanism. It is 8 byte control with first 4 bytes
    /// representing pan value and last 4 byte representing tilt value .Positive values for pan mean
    /// clockwise, negative values for pan means counterclockwise.
    /// Positive values for tilt mean updwards, negative values for tilt  means downwards.
    static let panTiltAbsoluteControl = CMIOClassID(kCMIOPanTiltAbsoluteControlClassID)
    
    /// A CMIOFeatureControl that controls a pan/tilt mechanism. It is 4 byte control with first 2 bytes
    /// representing pan value and last 2 bytes representing tilt value. Pan value is composed of two
    /// parts , Pan Relative(direction) and Pan Speed each having size of 1 byte. For Pan Relative value
    /// of 0 indicates stop, 1 indicates movement in clockwise direction and 0xff indicates movement in
    /// counterclockwise direction. For Pan Speed low number indicates a slow speed and high number
    /// indicates a higher speed. Tilt value of conposed of two parts , Tilt Relative(direction) and Tilt
    /// Speed each having size of 1 byte. For Tilt Relative value of 0 indicates stop, 1 indicates
    /// movement in upward direction and 0xff indicates movement in downward direction.
    /// For Tilt Speed low number indicates slow speed and high number indicates higher speed.
    static let panTiltRelativeControl = CMIOClassID(kCMIOPanTiltRelativeControlClassID)
    
    /// A CMIOFeatureControl that controls the zoom focal length relatively as powered zoom.
    /// It is 4 byte control. First byte specifies whether zoom lens group is stopped or direction
    /// of zoom lens. Value of 0 indicates that zoom lens is stopped, 1 indicates that zoom lens
    /// is moved towards the telephoto direction and 0xff indicates that zoom lens is moved towards
    /// the wide-angle direction. Second 1 byte specifies whether digital zoom is enabled or disabled.
    /// Third 1 byte represent speed of control change where low number specifies low speed and
    /// higher number specifies higher speed. Last 1 byte is padding byte.
    static let zoomRelativeControl = CMIOClassID(kCMIOZoomRelativeControlClassID)
    
    // macOS 10.15+
    /// A CMIOFeratureControl that control rotate degree of camera image. Value ranges from
    /// +180 to -180 degree with default value set to zero determining no rotation. Positive
    /// value causes a clockwise rotation of the camera image along with the image
    /// viewing axis and negative value causes a counter clockwise rotation of camera image.
    /// Rotation degree can be any value in range +180 to -180 or set of discrete values
    /// +90, -90, +180/-180. Values supported for rotation degree is implementation specific.
    static let rollAbsoluteControl = CMIOClassID(0x726f6c61) // kCMIORollAbsoluteControlClassID
    
    private static let featureControlClassIDs: Set<CMIOClassID> = [
        blackLevelControl,
        whiteLevelControl,
        hueControl,
        saturationControl,
        contrastControl,
        sharpnessControl,
        brightnessControl,
        gainControl,
        irisControl,
        shutterControl,
        exposureControl,
        whiteBalanceUControl,
        whiteBalanceVControl,
        whiteBalanceControl,
        gammaControl,
        temperatureControl,
        zoomControl,
        focusControl,
        panControl,
        tiltControl,
        opticalFilter,
        backlightCompensationControl,
        powerLineFrequencyControl,
        noiseReductionControl,
        panTiltAbsoluteControl,
        panTiltRelativeControl,
        zoomRelativeControl,
        rollAbsoluteControl
    ]

    func isSubclass(of baseClassID: CMIOClassID) -> Bool {
        switch baseClassID {
        case .object: return true
        case .control:
            switch self {
            case .control, .booleanControl, .selectorControl, .featureControl:
                return true
            case _ where CMIOClassID.booleanControlClassIDs.contains(self):
                return true
            case _ where CMIOClassID.selectorControlClassIDs.contains(self):
                return true
            case _ where CMIOClassID.featureControlClassIDs.contains(self):
                return true
            default:
                return false
            }
            
        case .booleanControl:
            return self == .booleanControl || CMIOClassID.booleanControlClassIDs.contains(self)
            
        case .selectorControl:
            return self == .selectorControl || CMIOClassID.selectorControlClassIDs.contains(self)
            
        case .featureControl:
            return self == .featureControl || CMIOClassID.featureControlClassIDs.contains(self)
            
        default:
            return self == baseClassID
        }
    }
    
}
