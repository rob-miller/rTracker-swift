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

    //init(initialValue: Bool) {
    init() {
        let initialValue = 0 // initialValue ? 1 : 0
        value = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        value.initialize(to: UInt32(initialValue))
    }

    deinit {
        value.deallocate()
    }

    func testAndSet(newValue: Bool) -> Bool {
        var previousValue: Bool
        if newValue {
            previousValue = OSAtomicTestAndSetBarrier(0, value)
        } else {
            previousValue = OSAtomicTestAndClearBarrier(0, value)
        }
        // let newValue = newValue ? 1 : 0
        DBGLog(String("atomic test and set: \(newValue) was \(previousValue)"))
        //let previousValue = OSAtomicTestAndSetBarrier(UInt32(newValue), value)
        //OSAtomicTestAndClearBarrier(<#T##__n: UInt32##UInt32#>, <#T##__theAddress: UnsafeMutableRawPointer!##UnsafeMutableRawPointer!#>)
        //DBGLog(String("atomic returning \(previousValue)"))
        return previousValue // != false
    }
    
    func get() -> Bool {
        return value.pointee != 0
    }
}
