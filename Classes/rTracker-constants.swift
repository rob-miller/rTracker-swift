//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/

import CoreGraphics
import UIKit


///************
/// rTracker-constants.swift
/// Copyright 2010-2021 Robert T. Miller
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///***************

/*
 *  rTracker-constants.h
 *  rTracker
 *
 *  Created by Robert Miller on 18/10/2010.
 *  Copyright 2010 Robert T. Miller. All rights reserved.
 *
 */

// 18 dec change MARGIN from 10.0f
let MARGIN = 8.0
let SPACE = 3.0
let TFXTRA = 2.0


let rtTrackerUpdatedNotification = "rtTrackerUpdatedNotification"
let rtValueUpdatedNotification = "rtValueUpdatedNotification"
let rtProgressBarUpdateNotification = "rtProgressBarUpdateNotification"

let kAnimationDuration = 0.3

let kViewTag = Int(1)
//#define kViewTag2		((NSInteger) 2)

let TMPUNIQSTART = 1000

let TIMESTAMP_LABEL = "timestamp"
let TIMESTAMP_KEY = "timestamp:0"

let MINPRIV = 1
let MAXPRIV = 100
let BIGPRIV = 1000
let PRIVDFLT = MINPRIV


func f(_ x: Any) -> Float {
    if let doubleValueF = x as? Double {
        return Float(doubleValueF)
    } else if let intValueF = x as? Int {
        return Float(intValueF)
    } else if let cgfValueF = x as? CGFloat {
        return Float(cgfValueF)
    } else {
        dbgNSAssert(false, "unable to convert \(x) to Float")
        return 0.0 // or some default value
    }
}

func d(_ x: Any) -> Double {
    if let doubleValueD = x as? Double {
        return doubleValueD
    } else if let intValueD = x as? Int {
        return Double(intValueD)
    } else if let cgfValueD = x as? CGFloat {
        return Double(cgfValueD)
    } else {
        dbgNSAssert(false, "unable to convert \(x) to Double")
        return 0.0 // or some default value
    }
}


let SAMPLES_VERSION = 1

let DEMOS_VERSION = 5
// demos_version 2 improve colours for one graph, wording improvements, link to getTrackers.pl, iOS settings to change text size
// demos version 3 fix link for 'tap to drop me a note'; add endpoint <none> example;
// demos version 4 change links to GitHub, remove rTrackerA URL scheme entry
// demos version 5 change github link to rTracker-swift

let RTDB_VERSION = 2
// rtdb_version 2 info table added unique constraint on names column

let RTFN_VERSION = 1

// strings to access text field for setting constant
// lc= lastConst, could be more than 1
let LCKEY = "fdlc"
let CTFKEY = "fdcTF"
let CLKEY = "fdcLab"


// add to x and y axes to improve visibility of endpoints
let GRAPHSCALE = d(0.02)

// default preference for separateDateTimePicker

let SDTDFLT = false
let RTCSVOUTDFLT = false
let SAVEPRIVDFLT = true
let ACCEPTLICENSEDFLT = false

//#define HIDERTIMESDFLT YES
let SCICOUNTDFLT = 6

let RTCSVext = ".csv"
let CSVext = ".csv"
let RTRKext = ".rtrk"
let TmpTrkrData = ".tdata"
let TmpTrkrNames = ".tnames"

// rtm swift let CELL_HEIGHT_NORMAL = ((vo.parentTracker as? trackerObj)?.maxLabel.height ?? 0.0) + (3.0 * MARGIN)
// rtm swift let CELL_HEIGHT_TALL = 2.0 * CELL_HEIGHT_NORMAL

let PrefBodyFont = UIFont.preferredFont(forTextStyle: .body)

let CSVNOTIMESTAMP = 0x01 << 0
let CSVNOREADDATE = 0x01 << 1
let CSVCREATEDVO = 0x01 << 2
let CSVCONFIGVO = 0x01 << 3
let CSVLOADRECORD = 0x01 << 4

