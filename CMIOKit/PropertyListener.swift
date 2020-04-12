//
//  PropertyListener.swift
//  CMIOKit
//
//  Created by Tamas Lustyik on 2020. 04. 12..
//  Copyright © 2020. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

public extension Property {
    func addListener(scope: CMIOObjectPropertyScope = .anyScope,
                     element: CMIOObjectPropertyElement = .anyElement,
                     in objectID: CMIOObjectID,
                     queue: DispatchQueue? = nil,
                     block: @escaping ([CMIOObjectPropertyAddress]) -> Void) -> PropertyListener? {
        let address = CMIOObjectPropertyAddress(selector, scope, element)
        
        return PropertyListenerImpl(objectID: objectID, address: address, queue: queue) { addressCount, addressPtr in
            guard addressCount > 0, let array = addressPtr else { return }
            block(UnsafeBufferPointer(start: array, count: Int(addressCount)).map { $0 })
        }
    }
}

public protocol PropertyListener {
    func remove()
}

class PropertyListenerImpl: PropertyListener {
    private let objectID: CMIOObjectID
    private let address: CMIOObjectPropertyAddress
    private let queue: DispatchQueue?
    private let block: CMIOObjectPropertyListenerBlock
    private var isActive: Bool
    
    init?(objectID: CMIOObjectID,
          address: CMIOObjectPropertyAddress,
          queue: DispatchQueue?,
          block: @escaping CMIOObjectPropertyListenerBlock) {
        self.objectID = objectID
        self.address = address
        self.queue = queue
        self.block = block
        
        var address = address
        let status = CMIOObjectAddPropertyListenerBlock(objectID, &address, queue, block)
        guard status == kCMIOHardwareNoError else {
            return nil
        }
        
        isActive = true
    }
    
    func remove() {
        deactivate()
    }
    
    @discardableResult
    func deactivate() -> Bool {
        guard isActive else { return true }
        
        var address = self.address
        let status = CMIOObjectRemovePropertyListenerBlock(objectID, &address, queue, block)
        guard status == kCMIOHardwareNoError else {
            return false
        }
        
        isActive = false
        return true
    }
    
    deinit {
        if isActive {
            deactivate()
        }
    }
}
