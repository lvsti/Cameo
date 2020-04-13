//
//  AdjustControlPanelController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 05..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Cocoa
import CMIOKit

protocol AdjustControlPanelControllerDelegate: class {
    func adjustControlPanelDidDismiss()
}

final class AdjustControlPanelController: NSWindowController {
    @IBOutlet private weak var nameLabel: NSTextField!
    
    @IBOutlet private weak var booleanBox: NSView!
    @IBOutlet private weak var booleanBoxHiddenConstraint: NSLayoutConstraint!
    @IBOutlet private weak var booleanValueCheckbox: NSButton!
    
    @IBOutlet private weak var selectorBox: NSView!
    @IBOutlet private weak var selectorBoxHiddenConstraint: NSLayoutConstraint!
    @IBOutlet private weak var selectorDropdown: NSPopUpButton!
    
    @IBOutlet private weak var featureBox: NSView!
    @IBOutlet private weak var featureBoxHiddenConstraint: NSLayoutConstraint!
    @IBOutlet private weak var featureEnabledCheckbox: NSButton!
    @IBOutlet private weak var featureAutomaticRadio: NSButton!
    @IBOutlet private weak var featureManualRadio: NSButton!
    @IBOutlet private weak var featureValueSlider: NSSlider!
    @IBOutlet private weak var featureMinValueLabel: NSTextField!
    @IBOutlet private weak var featureMaxValueLabel: NSTextField!
    @IBOutlet private weak var featureValueTextField: NSTextField!
    @IBOutlet private weak var featureUnitNameLabel: NSTextField!
    @IBOutlet private weak var featureTuneButton: NSButton!
    
    private var controlModel: ControlModel {
        didSet {
            guard isWindowLoaded else { return }
            updateUI()
        }
    }
    
    private let controlID: UInt32
    
    weak var delegate: AdjustControlPanelControllerDelegate?
    
    init?(controlID: UInt32) {
        self.controlID = controlID
        guard let model = Control.model(for: controlID) else {
            return nil
        }
        self.controlModel = model
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateUI() {
        switch controlModel {
        case .boolean(let model):
            booleanBoxHiddenConstraint.priority = .defaultLow
            selectorBoxHiddenConstraint.priority = .defaultHigh
            featureBoxHiddenConstraint.priority = .defaultHigh
            
            nameLabel.stringValue = model.name
            booleanValueCheckbox.state = model.value ? .on : .off

        case .selector(let model):
            booleanBoxHiddenConstraint.priority = .defaultHigh
            selectorBoxHiddenConstraint.priority = .defaultLow
            featureBoxHiddenConstraint.priority = .defaultHigh
            
            nameLabel.stringValue = model.name

            let dropdownMenu = NSMenu(title: "Values")
            
            model.items.enumerated().forEach { arg in
                let (idx, (_, itemName)) = arg
                let menuItem = NSMenuItem(title: itemName, action: #selector(menuItemClicked(_:)), keyEquivalent: "")
                menuItem.tag = idx
                dropdownMenu.addItem(menuItem)
            }
            
            selectorDropdown.menu = dropdownMenu
            selectorDropdown.selectItem(at: model.currentItemIndex!)

        case .feature(let model):
            booleanBoxHiddenConstraint.priority = .defaultHigh
            selectorBoxHiddenConstraint.priority = .defaultHigh
            featureBoxHiddenConstraint.priority = .defaultLow

            nameLabel.stringValue = model.name

            featureEnabledCheckbox.state = model.isEnabled ? .on : .off
            featureAutomaticRadio.state = model.isAutomatic ? .on : .off
            featureAutomaticRadio.isEnabled = model.isEnabled
            featureManualRadio.state = !model.isAutomatic ? . on : .off
            featureManualRadio.isEnabled = model.isEnabled
            
            featureValueSlider.isEnabled = model.isEnabled && !model.isAutomatic && !model.isTuning
            featureValueSlider.minValue = Double(model.minValue)
            featureValueSlider.maxValue = Double(model.maxValue)
            featureValueSlider.doubleValue = Double(model.currentValue)
            featureValueTextField.stringValue = "\(model.currentValue)"
            featureValueTextField.isEnabled = model.isEnabled && !model.isAutomatic && !model.isTuning
            featureUnitNameLabel.stringValue = model.unitName ?? "units"
            featureMinValueLabel.stringValue = "\(model.minValue)"
            featureMaxValueLabel.stringValue = "\(model.maxValue)"
            featureTuneButton.title = model.isTuning ? "Tuning..." : "Tune"
            featureTuneButton.isEnabled = model.isEnabled && !model.isAutomatic && !model.isTuning
        }
    }
    
    override var windowNibName: NSNib.Name? {
        return "AdjustControlPanel"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        updateUI()
    }
    
    @IBAction private func dismissButtonClicked(_ sender: Any?) {
        delegate?.adjustControlPanelDidDismiss()
    }
    
    @IBAction private func booleanValueCheckboxClicked(_ sender: Any?) {
        guard case .boolean(var model) = controlModel else {
            return
        }
        
        model.value = booleanValueCheckbox.state == .on
        
        guard
            BooleanControlProperty.value.setValue(.boolean(model.value), in: model.controlID)
        else {
            updateUI()
            return
        }
        
        controlModel = .boolean(model)
    }
    
    @IBAction private func menuItemClicked(_ sender: NSMenuItem) {
        guard case .selector(var model) = controlModel else {
            return
        }

        model.currentItemID = model.items[sender.tag].0
        
        guard
            SelectorControlProperty.currentItem.setValue(.uint32(model.currentItemID), in: model.controlID)
        else {
            updateUI()
            return
        }
        
        controlModel = .selector(model)
    }
    
    @IBAction private func featureEnabledCheckboxClicked(_ sender: Any?) {
        guard case .feature(var model) = controlModel else {
            return
        }
        
        model.isEnabled = featureEnabledCheckbox.state == .on
        
        guard
            FeatureControlProperty.onOff.setValue(.boolean(model.isEnabled), in: model.controlID)
        else {
            updateUI()
            return
        }
        
        controlModel = .feature(model)
    }

    @IBAction private func featureAutomaticManualRadioClicked(_ sender: NSButton) {
        guard case .feature(var model) = controlModel else {
            return
        }

        model.isAutomatic = sender == featureAutomaticRadio
        
        guard
            FeatureControlProperty.automaticManual.setValue(.boolean(model.isAutomatic), in: model.controlID)
        else {
            updateUI()
            return
        }

        controlModel = .feature(model)
    }

    @IBAction private func featureValueSliderChanged(_ sender: Any?) {
        guard case .feature(var model) = controlModel else {
            return
        }

        model.currentValue = featureValueSlider.floatValue
        
        let property: FeatureControlProperty = model.isInAbsoluteUnits ? .absoluteValue : .nativeValue
        guard
            property.setValue(.float32(model.currentValue), in: model.controlID)
        else {
            updateUI()
            return
        }

        controlModel = .feature(model)
    }

    @IBAction private func featureValueTextFieldChanged(_ sender: Any?) {
        guard case .feature(var model) = controlModel else {
            return
        }

        model.currentValue = featureValueTextField.floatValue
        
        let property: FeatureControlProperty = model.isInAbsoluteUnits ? .absoluteValue : .nativeValue
        guard
            property.setValue(.float32(model.currentValue), in: model.controlID)
        else {
            updateUI()
            return
        }

        controlModel = .feature(model)
    }

    @IBAction private func featureTuneButtonClicked(_ sender: Any?) {
        guard case .feature(var model) = controlModel else {
            return
        }

        model.isTuning = true
        
        guard
            FeatureControlProperty.tune.setValue(.float32(model.currentValue), in: model.controlID)
        else {
            updateUI()
            return
        }

        controlModel = .feature(model)
    }

}
