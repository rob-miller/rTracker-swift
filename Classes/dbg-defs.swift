//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
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


let RELEASE = 1

let DEBUGLOG = 0
let DEBUGWARN = 1
let DEBUGERR = 1

// enable additional debugging code in these sections
let SQLDEBUG = 0
let FUNCTIONDBG = 0
let REMINDERDBG = 0
let GRAPHDBG = 0


// enable advertising code -- controlled in Xcode build settings (Apple LLVM -> Preprocessing -> Preprocessor macros) for rTrackerA
//#define ADVERSION   0

// advertisements disabled - open source - no revenue -- code left in place as documentation/example for interested parties
let DISABLE_ADS = 1


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

#if SQLDEBUG
//#define SQLDbg(args...) NSLog(@"%@",[NSString stringWithFormat: args])
#else
//#define SQLDbg(args...)
#endif

//#define DBGSTR
#if DEBUGLOG
//#define DBGLog(args...) NSLog(@"%s%d: %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])

func DBGTLIST(_ tl: Any) {
    let c = tl.topLayoutNames?.count ?? 0
    var i: Int
    DBGLog("tlist: %lu items  privacy= %d", UInt(c), privacyV.getPrivacyValue())
    print("n  id  priv   name (tlist)")
    for i in 0..<c {
        if let object = tl.topLayoutIDs?[i], let anObject = tl.topLayoutPriv?[i], let aAnObject = tl.topLayoutNames?[i] {
            print(String(format: " %lu  %@  %@   %@", UInt(i) + 1, object, anObject, aAnObject))
        }
    }
    let sql = "select rank, id, priv, name from toplevel order by rank"
    tl.toQry2Log(sql)
}

#else
//#define DBGLog(...)
//#define DBGTLIST(tl)
#endif

#if DEBUGWARN
//#define DBGWarn(args...) NSLog(@"%@",[NSString stringWithFormat: args])
//#define DBGWarn(args...) NSLog(@"%s%d: **WARNING** %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])
#else
//#define DBGWarn(args...)
#endif


#if DEBUGERR
//#define DBGErr(args...) NSLog(@"%s%d: **ERROR** %@",__PRETTY_FUNCTION__,__LINE__,[NSString stringWithFormat: args])
#else
//#define DBGErr(args...)
#endif

#if RELEASE
func dbgNSAssert(_ x: Any, _ y: Any) {
    if 0 == x {
        DBGErr(y)
    }
}
func dbgNSAssert1(_ x: Any, _ y: Any, _ z: Any) {
    if 0 == x {
        DBGErr(y, z)
    }
}
func dbgNSAssert2(_ x: Any, _ y: Any, _ z: Any, _ t: Any) {
    if 0 == x {
        DBGErr(y, z, t)
    }
}
#else
typealias dbgNSAssert = NSAssert
typealias dbgNSAssert1 = NSAssert1
typealias dbgNSAssert2 = NSAssert2
#endif