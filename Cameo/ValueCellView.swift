//
//  ValueCellView.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2019. 01. 01..
//  Copyright © 2019. Tamas Lustyik. All rights reserved.
//

import Cocoa

protocol ValueCellDelegate: class {
    func valueCellDidClickLinkButton(_ sender: ValueCellView)
}

final class ValueCellView: NSTableCellView {

    @IBOutlet private weak var linkButton: NSButton!
    
    var showsLinkButton: Bool = false {
        didSet {
            linkButton.isHidden = !showsLinkButton
        }
    }
    
    weak var delegate: ValueCellDelegate?
    
    @IBAction private func linkButtonClicked(_ sender: Any?) {
        delegate?.valueCellDidClickLinkButton(self)
    }
}
