//
//  CMIOObject.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 06..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

public extension CMIOObjectID {
    static let system = CMIOObjectID(kCMIOObjectSystemObject)
}

public extension CMIOClassID {
    static let object = CMIOClassID(kCMIOObjectClassID)
    static let systemObject = CMIOClassID(kCMIOSystemObjectClassID)
    static let plugIn = CMIOClassID(kCMIOPlugInClassID)
    static let device = CMIOClassID(kCMIODeviceClassID)
    static let stream = CMIOClassID(kCMIOStreamClassID)
    static let control = CMIOClassID(kCMIOControlClassID)
    static let booleanControl = CMIOClassID(kCMIOBooleanControlClassID)
    static let selectorControl = CMIOClassID(kCMIOSelectorControlClassID)
    static let featureControl = CMIOClassID(kCMIOFeatureControlClassID)

    static let jackControl = CMIOClassID(kCMIOJackControlClassID)
    static let directionControl = CMIOClassID(kCMIODirectionControlClassID)
    
    private static let booleanControlClassIDs: Set<CMIOClassID> = [
        jackControl,
        directionControl
    ]

    static let dataSourceControl = CMIOClassID(kCMIODataSourceControlClassID)
    static let dataDestinationControl = CMIOClassID(kCMIODataDestinationControlClassID)

    private static let selectorControlClassIDs: Set<CMIOClassID> = [
        dataSourceControl,
        dataDestinationControl
    ]

    static let blackLevelControl = CMIOClassID(kCMIOBlackLevelControlClassID)
    static let whiteLevelControl = CMIOClassID(kCMIOWhiteLevelControlClassID)
    static let hueControl = CMIOClassID(kCMIOHueControlClassID)
    static let saturationControl = CMIOClassID(kCMIOSaturationControlClassID)
    static let contrastControl = CMIOClassID(kCMIOContrastControlClassID)
    static let sharpnessControl = CMIOClassID(kCMIOSharpnessControlClassID)
    static let brightnessControl = CMIOClassID(kCMIOBrightnessControlClassID)
    static let gainControl = CMIOClassID(kCMIOGainControlClassID)
    static let irisControl = CMIOClassID(kCMIOIrisControlClassID)
    static let shutterControl = CMIOClassID(kCMIOShutterControlClassID)
    static let exposureControl = CMIOClassID(kCMIOExposureControlClassID)
    static let whiteBalanceUControl = CMIOClassID(kCMIOWhiteBalanceUControlClassID)
    static let whiteBalanceVControl = CMIOClassID(kCMIOWhiteBalanceVControlClassID)
    static let whiteBalanceControl = CMIOClassID(kCMIOWhiteBalanceControlClassID)
    static let gammaControl = CMIOClassID(kCMIOGammaControlClassID)
    static let temperatureControl = CMIOClassID(kCMIOTemperatureControlClassID)
    static let zoomControl = CMIOClassID(kCMIOZoomControlClassID)
    static let focusControl = CMIOClassID(kCMIOFocusControlClassID)
    static let panControl = CMIOClassID(kCMIOPanControlClassID)
    static let tiltControl = CMIOClassID(kCMIOTiltControlClassID)
    static let opticalFilter = CMIOClassID(kCMIOOpticalFilterClassID)
    static let backlightCompensationControl = CMIOClassID(kCMIOBacklightCompensationControlClassID)
    static let powerLineFrequencyControl = CMIOClassID(kCMIOPowerLineFrequencyControlClassID)
    static let noiseReductionControl = CMIOClassID(kCMIONoiseReductionControlClassID)
    static let panTiltAbsoluteControl = CMIOClassID(kCMIOPanTiltAbsoluteControlClassID)
    static let panTiltRelativeControl = CMIOClassID(kCMIOPanTiltRelativeControlClassID)
    static let zoomRelativeControl = CMIOClassID(kCMIOZoomRelativeControlClassID)

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
        zoomRelativeControl
    ]

    public func isSubclass(of baseClassID: CMIOClassID) -> Bool {
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
