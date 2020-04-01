//
//  TranslationPanelController.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 02. 01..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Cocoa
import CMIOKit

protocol TranslationPanelControllerDelegate: class {
    func translationPanelDidDismiss()
}

final class TranslationPanelController: NSWindowController {
    @IBOutlet private weak var sourceField: NSTextField!
    @IBOutlet private weak var valueLabel: NSTextField!

    weak var delegate: TranslationPanelControllerDelegate?
    
    private let translation: (String) -> String

    init?(property: Property, objectID: UInt32) {
        self.translation = {
            property.descriptionForTranslating($0, in: objectID) ?? "#ERROR"
        }
        super.init(window: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var windowNibName: NSNib.Name? {
        return "TranslationPanel"
    }

    @IBAction private func translateButtonClicked(_ sender: Any?) {
        valueLabel.stringValue = translation(sourceField.stringValue)
    }
    
    @IBAction private func dismissButtonClicked(_ sender: Any?) {
        delegate?.translationPanelDidDismiss()
    }
}
