//
//  atomicTestSet.swift
//  rTracker
//
//  Created by Rob Miller on 05/04/2023.
//  Copyright © 2023 Robert T. Miller. All rights reserved.
//

import Foundation

class AtomicTestAndSet {
    private var value: UnsafeMutablePointer<UInt32>

    init(initialValue: Bool) {
        let initialValue = initialValue ? 1 : 0
        value = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        value.initialize(to: UInt32(initialValue))
    }

    deinit {
        value.deallocate()
    }

    func testAndSet(newValue: Bool) -> Bool {
        let newValue = newValue ? 1 : 0
        let previousValue = OSAtomicTestAndSetBarrier(UInt32(newValue), value)
        return previousValue != false
    }
    
    func get() -> Bool {
        return value.pointee != 0
    }
}
