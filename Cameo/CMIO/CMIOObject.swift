//
//  CMIOObject.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 06..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

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
