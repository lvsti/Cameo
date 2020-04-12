//
//  Qualifier.swift
//  CMIOKit
//
//  Created by Tamas Lustyik on 2020. 04. 12..
//  Copyright © 2020. Tamas Lustyik. All rights reserved.
//

import Foundation
import CoreMediaIO

public protocol QualifierProtocol {
    var data: UnsafeMutableRawPointer { get }
    var size: Int { get }
}

public class Qualifier<T>: QualifierProtocol {
    public let data: UnsafeMutableRawPointer
    public let size: Int
    
    public init(from scalar: T) {
        size = MemoryLayout<T>.size
        data = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<T>.alignment)
        let typedData = data.bindMemory(to: T.self, capacity: 1)
        typedData.pointee = scalar
    }
    
    public init(fromArray array: [T]) {
        size = MemoryLayout<T>.size * array.count
        data = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<T>.alignment)
        let typedData = data.bindMemory(to: T.self, capacity: array.count)
        let buf = UnsafeMutableBufferPointer<T>(start: typedData, count: array.count)
        _ = buf.initialize(from: array)
    }
    
    deinit {
        data.deallocate()
    }
}
