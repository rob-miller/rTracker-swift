//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/

import UIKit
///************
/// dbg-defs.swift
/// Copyright 2011-2021 Robert T. Miller
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

//
//  dbg-defs.swift
//  rTracker
//
//  Created by Rob Miller on 30/03/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//


let RELEASE = 0

let DEBUGLOG = 1
let DEBUGWARN = 1
let DEBUGERR = 1

// enable additional debugging code in these sections
// *** Doesn't work in Swift need compile defs ***

// ***
// *** xcode menu Product - scheme - manage schemes - select, edit...
// *** or top bar, click project (rTracker) -> edit scheme in dropdown
// ***

let SQLDEBUG = 0
let FUNCTIONDBG = 0
let REMINDERDBG = 0
let GRAPHDBG = 0

// ***

// enable Lukas Petr's GSTouchesShowingWindow (https://github.com/LukasCZ/GSTouchesShowingWindow - not included here)
let SHOWTOUCHES = 0

// enable Fabric Crashlytics crash reporting (https://try.crashlytics.com/ - not included here)
let FABRIC = 0

// disable attempts to extract device owner's name and use for main screen title line ("rob's tracks")
let NONAME = 0


// iOS Version Checking
func SYSTEM_VERSION_EQUAL_TO(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) == .orderedSame
}
func SYSTEM_VERSION_GREATER_THAN(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) == .orderedDescending
}
func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) != .orderedAscending
}
func SYSTEM_VERSION_LESS_THAN(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) == .orderedAscending
}
func SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(_ v: String) -> Bool {
    UIDevice.current.systemVersion.compare(v, options: .numeric, range: nil, locale: .current) != .orderedDescending
}



// implementation for debug messages:
     
func SQLDbg(_ message: String) {
#if SQLDEBUG
    print(message)
    //#define SQLDbg(args...) NSLog(@"%@",[NSString stringWithFormat: args])
//#else
    //#define SQLDbg(args...)
#endif
}

func DBGLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUGLOG
    //#define DBGLog(args...) NSLog(@"%s%d: %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])
    let fileName = file.components(separatedBy: "/").last ?? ""
    print("[\(fileName):\(line)] \(function): \(message)")
#endif
}

func DBGWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUGWARN
    //print("dbgwarn enabled")
    let fileName = file.components(separatedBy: "/").last ?? ""
    print("**warning** [\(fileName):\(line)] \(function): \(message)")
    //#define DBGWarn(args...) NSLog(@"%@",[NSString stringWithFormat: args])
    //#define DBGWarn(args...) NSLog(@"%s%d: **WARNING** %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])
#endif
}

func DBGErr(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUGERR
    let fileName = file.components(separatedBy: "/").last ?? ""
    print("**error** [\(fileName):\(line)] \(function): \(message)")
    //#define DBGErr(args...) NSLog(@"%s%d: **ERROR** %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])
#endif
}

func dbgNSAssert(_ x: Bool, _ y: String) {
    if !x {
        DBGErr(y)
    }
#if !RELEASE
    assert(x,y)
#endif
}
