//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voFunction.swift
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

//
//  voFunction.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit

//function support
// values are negative so positive values will be vid's
let FNSETVERSION = 1

let FNSTART = -1

// old 1arg begin
let FN1ARGFIRST = FNSTART
let FN1ARGDELTA = FN1ARGFIRST
let FN1ARGSUM = FN1ARGDELTA - 1
let FN1ARGPOSTSUM = FN1ARGSUM - 1
let FN1ARGPRESUM = FN1ARGPOSTSUM - 1
let FN1ARGAVG = FN1ARGPRESUM - 1
let FN1ARGLAST = FN1ARGAVG
// old 1arg end -- do not edit, add below

// old 2arg begin
let FN2ARGFIRST = FN1ARGLAST - 1
let FN2ARGPLUS = FN2ARGFIRST
let FN2ARGMINUS = FN2ARGPLUS - 1
let FN2ARGTIMES = FN2ARGMINUS - 1
let FN2ARGDIVIDE = FN2ARGTIMES - 1
let FN2ARGLAST = FN2ARGDIVIDE
// old 2arg end -- do not edit, add below

let FNPARENOPEN = FN2ARGLAST - 1
let FNPARENCLOSE = FNPARENOPEN - 1
let FNPARENLAST = FNPARENCLOSE

// old time fns begin
let FNTIMEFIRST = FNPARENCLOSE - 1
let FNTIMEWEEKS = FNTIMEFIRST
let FNTIMEDAYS = FNTIMEWEEKS - 1
let FNTIMEHRS = FNTIMEDAYS - 1
let FNTIMELAST = FNTIMEHRS
// old time fns end -- do not edit, add below

let FNCONSTANT = FNTIMELAST - 1

let FNOLDLAST = FNCONSTANT

// define extra space for new functions below

let FNNEW1ARGFIRST = FNOLDLAST - 10

let FN1ARGMIN = FNNEW1ARGFIRST - 1
let FN1ARGMAX = FN1ARGMIN - 1
let FN1ARGCOUNT = FN1ARGMAX - 1
let FN1ARGONRATIO = FN1ARGCOUNT - 1
let FN1ARGNORATIO = FN1ARGONRATIO - 1
let FN1ARGELAPSEDWEEKS = FN1ARGNORATIO - 1
let FN1ARGELAPSEDDAYS = FN1ARGELAPSEDWEEKS - 1
let FN1ARGELAPSEDHOURS = FN1ARGELAPSEDDAYS - 1
let FN1ARGELAPSEDMINS = FN1ARGELAPSEDHOURS - 1
let FN1ARGELAPSEDSECS = FN1ARGELAPSEDMINS - 1
let FN1ARGDELAY = FN1ARGELAPSEDSECS - 1
let FN1ARGROUND = FN1ARGDELAY - 1

let FNNEW1ARGLAST = FNNEW1ARGFIRST - 100

func isFn1Arg(_ i: Int) -> Bool {
    ((i <= FN1ARGFIRST) && (i >= FN1ARGLAST)) || ((i <= FNNEW1ARGFIRST) && (i >= FNNEW1ARGLAST))
}
func isFn1ArgElapsed(_ i: Int) -> Bool {
    (i <= FN1ARGELAPSEDWEEKS) && (i >= FN1ARGELAPSEDSECS)
}

let FNNEW2ARGFIRST = FNNEW1ARGLAST - 10
let FNNEW2ARGLAST = FNNEW2ARGFIRST - 100

func isFn2ArgOp(_ i: Int) -> Bool {
    ((i <= FN2ARGFIRST) && (i >= FN2ARGLAST)) || ((i <= FNNEW2ARGFIRST) && (i >= FNNEW2ARGLAST))
}

let FNNEWTIMEFIRST = FNNEW2ARGLAST - 10
let FNTIMEMINS = FNNEWTIMEFIRST - 1
let FNTIMESECS = FNTIMEMINS - 1
let FNNEWTIMELAST = FNNEWTIMEFIRST - 100

func isFnTimeOp(_ i: Int) -> Bool {
    ((i <= FNTIMEFIRST) && (i >= FNTIMELAST)) || ((i <= FNNEWTIMEFIRST) && (i >= FNNEWTIMELAST))
}


let FNFIN = FNNEWTIMELAST

func isFn(_ i: Int) -> Bool {
    (i <= FNSTART) && (i >= FNFIN)
}

let FNCONSTANT_TITLE = "constant"


let ARG1FNS = [FN1ARGDELTA,FN1ARGSUM,FN1ARGPOSTSUM,FN1ARGPRESUM,FN1ARGAVG,FN1ARGMIN,FN1ARGMAX,FN1ARGCOUNT,FN1ARGONRATIO,FN1ARGNORATIO,FN1ARGELAPSEDWEEKS,FN1ARGELAPSEDDAYS,FN1ARGELAPSEDHOURS,FN1ARGELAPSEDMINS,FN1ARGELAPSEDSECS,FN1ARGDELAY, FN1ARGROUND]
let ARG1STRS = ["change_in","sum","post-sum","pre-sum","avg","min","max","count","old/new","new/old","elapsed_weeks","elapsed_days","elapsed_hrs","elapsed_mins","elapsed_secs", "delay", "round"]
let ARG1CNT = ARG1FNS.count

let ARG2FNS = [FN2ARGPLUS,FN2ARGMINUS,FN2ARGTIMES,FN2ARGDIVIDE]
let ARG2STRS = ["+","-","*","/"]
let ARG2CNT = ARG2FNS.count

let PARENFNS = [FNPARENOPEN, FNPARENCLOSE]
let PARENSTRS = ["(", ")"]
let PARENCNT = PARENFNS.count

let TIMEFNS = [FNTIMEWEEKS,FNTIMEDAYS,FNTIMEHRS,FNTIMEMINS,FNTIMESECS]
let TIMESTRS = ["weeks","days","hours","minutes","seconds"]
let TIMECNT = TIMEFNS.count

let OTHERFNS = [FNCONSTANT]
let OTHERSTRS = [FNCONSTANT_TITLE]
let OTHERCNT = OTHERFNS.count

let TOTFNCNT = ARG1CNT + ARG2CNT + PARENCNT + TIMECNT + OTHERCNT

let FREPENTRY = -1
let FREPHOURS = -2
let FREPDAYS = -3
let FREPWEEKS = -4
let FREPMONTHS = -5
let FREPYEARS = -6
let FREPCDAYS = -7
let FREPCWEEKS = -8
let FREPCMONTHS = -9
let FREPCYEARS = -10
let FREPNONE = -11

func ISCALFREP(_ x: Int) -> Bool {
    (FREPCDAYS >= x) && (FREPCYEARS <= x)
}

let MAXFREP = 11

let FNSEGNDX_OVERVIEW = 0
let FNSEGNDX_RANGEBLD = 1
let FNSEGNDX_FUNCTBLD = 2

// end functions 

// MARK: -
    // MARK: core object methods and support
    var FnErr = false

class voFunction: voState, UIPickerViewDelegate, UIPickerViewDataSource {

    private var _fnStrDict: [NSNumber : String]?
    var fnStrDict: [NSNumber : String] {
        if nil == _fnStrDict {
            let fnTokArr = PARENFNS + OTHERFNS
            let fnStrArr = ARG1STRS + ARG2STRS + TIMESTRS + PARENSTRS + OTHERSTRS
            var fnTokNSNarr: [NSNumber] = []

            for a1 in fn1args {
                fnTokNSNarr.append(NSNumber(value:a1))
            }
            for a2 in fn2args {
                fnTokNSNarr.append(NSNumber(value:a2))
            }
            for tmop in fnTimeOps {
                fnTokNSNarr.append(NSNumber(value:tmop))
            }
            for tok in fnTokArr {
                fnTokNSNarr.append(NSNumber(value:tok))
            }
            _fnStrDict = Dictionary(uniqueKeysWithValues: zip(fnTokNSNarr, fnStrArr))
        }
        return _fnStrDict!
    }

    private var _fn1args: [Int]?
    var fn1args: [Int] {
        if nil == _fn1args {
            _fn1args = Array(ARG1FNS[..<ARG1CNT]) // copyItems: true
        }
        return _fn1args!
    }

    private var _fn2args: [Int]?
    var fn2args: [Int] {
        if nil == _fn2args {
            _fn2args = Array(ARG2FNS[..<ARG2CNT]) // copyItems: true
        }

        return _fn2args!
    }

    private var _fnTimeOps: [Int]?
    var fnTimeOps: [Int] {
        if nil == _fnTimeOps {
            _fnTimeOps = Array(TIMEFNS[..<TIMECNT]) // copyItems: true
        }
        return _fnTimeOps!
    }
    var ctvovcp: configTVObjVC?
    var fnSegNdx = 0

    private var _epTitles: [String]?
    var epTitles: [String] {
        if _epTitles == nil {
            // n.b.: tied to FREP symbol defns in voFunctions.h
            _epTitles = [
                "entry",
                "hours",
                "days",
                "weeks",
                "months",
                "years",
                "cal days",
                "cal weeks",
                "cal months",
                "cal years",
                "<none>"
            ]
        }
        return _epTitles!
    }

    private var _fnTitles: [NSNumber]?
    var fnTitles: [NSNumber] {
        get {
            if _fnTitles == nil {
                _fnTitles = []
            }
            return _fnTitles!
        }
        set {
            _fnTitles = newValue
        }
    }

    var _fnArray: [NSNumber]?
    var fnArray: [NSNumber] {
        if _fnArray == nil {
            _fnArray = []
        }
        return _fnArray!
    }
    var currFnNdx = 0

    private var _rlab: UILabel?
    var rlab: UILabel? {
        if _rlab != nil && _rlab?.frame.size.width != vosFrame.size.width {
            _rlab = nil
        }

        if nil == _rlab {
            _rlab = UILabel(frame: vosFrame)
            _rlab?.textAlignment = .right // ios6 UITextAlignmentRight;
            _rlab?.font = PrefBodyFont
            _rlab?.accessibilityIdentifier = "fnVal_\(vo.valueName!)"
        }
        return _rlab
    }

    private var _votWoSelf: [valueObj]?
    var votWoSelf: [valueObj] {
        if nil == _votWoSelf {
            var tvot: [valueObj] = [] // (repeating: 0, count: MyTracker?.valObjTable?.count ?? 0)
            for tvo in MyTracker.valObjTable {
                // Only add if:
                // 1. It's not the current valueObj (vo)
                // 2. It's not referencing current tracker as its otTracker
                if tvo.vid != vo.vid && tvo.optDict["otTracker"] != MyTracker.trackerName {
                    tvot.append(tvo as valueObj)
                }
            }

            _votWoSelf = tvot
            /*
                    DBGLog(@"instantiate votWoSelf:");
                    DBGLog(@"self.vo vid=%d  name= %@",self.vo.vid,self.vo.valueName);
                    for (valueObj *mvo in votWoSelf) {
                        DBGLog(@"  %d: %@",mvo.vid,mvo.valueName);
                    }
                    DBGLog(@".");
            */
        }
        return _votWoSelf!
    }

    private var lastEpd0: Int = -1
    private var lastCalcValue: String = ""
    private var fnDirty = false

    //@property (nonatomic, retain) NSNumber *foo;
    func saveFnArray() {
        // note this converts NSNumbers to NSStrings
        // works because NSNumber returns an NSString for [description]

        // don't save an empty string
        let fnas = fnArray.map { String(describing: $0) }
        let ts = fnas.joined(separator: " ")
        //DBGLog(@"saving fnArray ts= .%@.",ts);
        if 0 < ts.count {
            vo.optDict["func"] = ts
        }
    }

    func loadFnArray() {

        _fnArray?.removeAll()
        _fnArray = nil
        // all works fine if we load as strings with 
        // [self.fnArray addObjectsFromArray: [[self.vo.optDict objectForKey:@"func"] componentsSeparatedByString:@" "];
        // but prefer to keep as NSNumbers 

        let tmp = vo.optDict["func"]?.components(separatedBy: " ")
        var tfna: [NSNumber] = []
        for s in tmp ?? [] {
            if "" != s {
                //[self.fnArray addObject:[NSNumber numberWithInteger:[s integerValue]]];
                tfna.append(NSNumber(value: Double(s)!)) // because of constant
            }
        }
        _fnArray = tfna
    }

    // MARK: protocol: getValCap

    override func getValCap() -> Int {
        // NSMutableString size for value
        return 32
    }

    // MARK: protocol: loadConfig

    override func loadConfig() {
        loadFnArray()
        if nil == vo.optDict["frep0"] {
            vo.optDict["frep0"] = String("\(FREPDFLT)")
        }
        if nil == vo.optDict["frep1"] {
            vo.optDict["frep1"] = String("\(FREPDFLT)")
        }

    }

    // MARK: protocol: updateVORefs

    // called to instantiate tempTrackerObj with -vid to real trackerObj on save tracker config

    override func updateVORefs(_ newVID: Int, old oldVID: Int) {
        loadFnArray()
        //var i = 0
        let max = fnArray.count
        #if FUNCTIONDBG
        DBGLog(String("start fnArray= \(fnArray)"))
        #endif
        for i in 0..<max {
            if fnArray[i].intValue == oldVID {
                _fnArray![i] = NSNumber(value: newVID)
            }
        }
        #if FUNCTIONDBG
        DBGLog(String("fin fnArray= \(fnArray)"))
        #endif
        saveFnArray()

        for i in 0..<2 {
            let key = String(format: "frep%lu", UInt(i))
            let ep = Int(vo.optDict[key] ?? "")
            if ep == oldVID {
                vo.optDict[key] = String("\(newVID)")
            }
        }
    }

    // MARK: -
    // MARK: protocol: voDisplay value

    func qdate(_ d: Int) -> String? {
        return DateFormatter.localizedString(
            from: Date(timeIntervalSince1970: TimeInterval(d)),
            dateStyle: .short,
            timeStyle: .short)
    }
    
    func getEpDate(_ ndx: Int, maxdate: Int) -> Int {
        let key = "frep\(ndx)"
        var ep: Int?
        let nep = vo.optDict[key]
        ep = (nep != nil ? Int(nep!) : nil)

        var epDate: Int
        let to = MyTracker
        var sql: String

        if nep == nil || ep == FREPENTRY {
            // also FREPDFLT  -- no value specified
            // use last entry
            sql = "select max(date) from trkrData where date < \(maxdate);"
            epDate = to.toQry2Int(sql:sql)
            //DBGLog(@"ep %d ->entry: %@", ndx, [self qdate:epDate] );
        } else if ep! >= 0 {
            // ep is vid
            sql = "select max(date) from voData where id=\(ep!) and date < \(maxdate) and val <> 0 and val <> '';"
            #if FUNCTIONDBG
            DBGLog(String("get ep qry: \(sql)"))
            #endif
            epDate = to.toQry2Int(sql:sql)
            #if FUNCTIONDBG
            DBGLog(String("ep \(ndx) ->vo \(vo.valueName): \(qdate(epDate))"))
            DBGLog(String("ep \(ndx) ->vo \(vo.valueName): \(qdate(epDate))"))
            #endif
        } else {
            // ep is (offset * -1)+1 into epTitles, with optDict:frv0 multiplier

            let vkey = "frv\(ndx)"
            var ival = (Int(vo.optDict[vkey] ?? "") ?? 0) * (ndx != 0 ? 1 : -1) // negative offset if ep0
            var gregorian = Calendar(identifier: .gregorian)
            gregorian.locale = NSLocale.current
            var offsetComponents = DateComponents()

            //NSString *vt=nil;

            switch ep {
            case FREPNONE:
                // no previous endpoint - find nothing prior to now
                break
            case FREPHOURS:
                offsetComponents.hour = ival
                //vt = @"hours";
                break
            case FREPCDAYS:
                ival += ndx != 0 ? 0 : 1 // for -1 calendar day, we want offset -0 day and normalize to previous midnight below
                fallthrough
            case FREPDAYS:
                offsetComponents.day = ival
                //vt = @"days";
                break
            case FREPCWEEKS:
                ival += ndx != 0 ? 0 : 1
                fallthrough
            case FREPWEEKS:
                offsetComponents.weekOfYear = ival
                //vt = @"weeks";
                break
            case FREPCMONTHS:
                ival += ndx != 0 ? 0 : 1
                fallthrough
            case FREPMONTHS:
                offsetComponents.month = ival
                //vt = @"months";
                break
            case FREPCYEARS:
                ival += ndx != 0 ? 0 : 1
                fallthrough
            case FREPYEARS:
                //vt = @"years";
                offsetComponents.year = ival
                break
            default:
                dbgNSAssert(false, "getEpDate: failed to identify ep \(ep!)")
            }

            var targ = gregorian.date(
                byAdding: offsetComponents,
                to: Date(timeIntervalSince1970: TimeInterval(maxdate)))

            var unitFlags: Set<Calendar.Component> = []

            switch ep {
            // if calendar week, we need to get to beginning of week as per calendar
            case FREPCWEEKS:
                DBGLog(String("first day of week= \(gregorian.firstWeekday) targ= \(targ)"))
                targ = gregorian.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: targ!).date
                
                DBGLog(String("targ= \(targ)"))

            // if any of week, day, month, year we need to wipe hour, minute, second components
                fallthrough
            case FREPCDAYS:
                unitFlags.insert(.day)
                fallthrough
            case FREPCMONTHS:
                unitFlags.insert(.month)
                fallthrough
            case FREPCYEARS:
                unitFlags.insert(.year)
                var components: DateComponents? = nil
                if let targ {
                    //components = gregorian.components(NSCalendar.Unit(rawValue: unitFlags), from: targ)
                    components = gregorian.dateComponents(unitFlags, from: targ)
                }
                if let components {
                    targ = gregorian.date(from: components)
                }
                break
            default:
                break
            }


            epDate = Int(targ?.timeIntervalSince1970 ?? 0)
            #if FUNCTIONDBG
            DBGLog(String("ep \(ndx) ->offset \(ival): \(qdate(epDate))"))
            #endif
        }
        //sql = nil;

        return epDate
    }
    
    // supplied with previous endpoint (endpoint 0), calculate function to current tracker
    func calcFunctionValue(withCurrent epd0: Int, fn2op: Bool = false) -> NSNumber? {

        let maxc = fnArray.count
        var vid = 0
        let to = vo.parentTracker // MyTracker;
        var sql: String

        FnErr = false

        var epd1: Int
        if to.trackerDate == nil {
            // current tracker entry no date set so epd1=now
            epd1 = Int(Date().timeIntervalSince1970)
        } else {
            // set epd1 to date of current (this) tracker entry
            epd1 = Int(to.trackerDate?.timeIntervalSince1970 ?? 0)
        }
        
#if FUNCTIONDBG
        // print our complete function
        //var i: Int
        var outstr = ""
        for i in 0..<maxc {
            let object = fnArray[i]
            outstr = outstr + " \(object)"
            
        }
        DBGLog(String("fndbg \(vo.valueName ?? "") calcFnValueWithCurrent fnArray= \(outstr)"))
        DBGLog("epd0 \(Date(timeIntervalSince1970: TimeInterval(epd0)))  epd1 \(Date(timeIntervalSince1970: TimeInterval(epd1)))  trackerDate \(self.MyTracker.trackerDate)")
#endif

        var result = 0.0

        while currFnNdx < maxc {
            // recursive function, self.currFnNdx holds our current processing position
            let currTok = fnArray[currFnNdx].intValue
            #if FUNCTIONDBG
            DBGLog(String("fndbg currFnNdx= \(currFnNdx) currTok= \(currTok) result = \(result) fn2op = \(fn2op)"))
            DBGLog(String("fndbg : \(voFnDefnStr(false, cfndx: currFnNdx)!)"))
            #endif
            if fn2op && (currTok == FN2ARGPLUS || currTok == FN2ARGMINUS || currTok == FNPARENCLOSE) {
                #if FUNCTIONDBG
                DBGLog("fndbg +-) return result= \(result)")
                #endif
                return NSNumber(value: result)  // return from recursion leaving currFnNdx=>currTok
            }
            currFnNdx += 1
            if isFn1Arg(currTok) {
                // currTok is function taking 1 argument, so get it
                if currFnNdx >= maxc {
                    FnErr = true
                    return NSNumber(value: result) // crashlytics report past array bounds at next line, so at least return without crashing
                }
                vid = fnArray[currFnNdx].intValue
                currFnNdx += 1 // get fn arg, can only be valobj vid
                //valueObj *valo = [to getValObj:vid];
                let sv1 = to.getValObj(vid)?.value
                let nullV1 = (nil == sv1 || ("" == sv1))
                let v1 = Double(sv1 ?? "") ?? 0.0
                sql = String(format: "select count(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                var ci = to.toQry2Int(sql:sql)
                #if FUNCTIONDBG
                DBGLog(String("v1= \(v1) nullV1=\(nullV1) vid=\(vid) \(vo.parentTracker.trackerName):\(vo.valueName)"))
                #endif
                // v1 is value for current tracker entry (epd1) for our arg
                switch currTok {
                // changed to date > epd1 for consistency with other functions
                case FN1ARGROUND, FN1ARGDELTA, FN1ARGONRATIO, FN1ARGNORATIO, FN1ARGELAPSEDWEEKS, FN1ARGELAPSEDDAYS, FN1ARGELAPSEDHOURS, FN1ARGELAPSEDMINS, FN1ARGELAPSEDSECS:
                    if nullV1 {
                        return nil // delta requires v1 to subtract from, sums and avg just get one less result
                    }
                    // epd1 value is ok, get from db value for epd0
                    //to.sql = [NSString stringWithFormat:@"select val from voData where id=%d and date=%d;",vid,epd0];
                    // with per calendar date calcs, epd0 may not match a datapoint
                    // - so get val coming into this time segment or skip for beginning - rtm 17.iii.13
                    sql = String(format: "select count(val) from voData where id=%ld and date>=%ld;", vid, epd0)
                    ci = to.toQry2Int(sql:sql) // slightly different for delta
                    if 0 == ci {
                        return nil // skip for beginning
                    }
                    if isFn1ArgElapsed(currTok) {
                        sql = String(format: "select date from voData where id=%ld and date>=%ld order by date asc limit 1;", vid, epd0)
                        let d0 = to.toQry2Int(sql:sql)
                        result = Double(epd1) - Double(d0)
                        DBGLog(String("elapsed unit: epd0= \(epd0) d0= \(d0) epd1=\(epd1) rslt= \(result)"))
                        switch currTok {
                        case FN1ARGELAPSEDWEEKS:
                            result /= d(7)
                            fallthrough
                        case FN1ARGELAPSEDDAYS:
                            result /= d(24)
                            fallthrough
                        case FN1ARGELAPSEDHOURS:
                            result /= d(60)
                            fallthrough
                        case FN1ARGELAPSEDMINS:
                            result /= d(60)
                            fallthrough
                        case FN1ARGELAPSEDSECS:
                            fallthrough
                        default:
                            break
                        }
                        DBGLog(String("elapsed unit: final result = \(result)"))
                    }
                    sql = String(format: "select val from voData where id=%ld and date>=%ld order by date asc limit 1;", vid, epd0) // desc->asc 22.ii.2016 to match <= -> >= change 25.01.16
                    let v0 = to.toQry2Double(sql:sql)
                    #if FUNCTIONDBG
                    DBGLog(String("delta/on_ratio/no_ratio: v0= \(v0)"))
                    #endif
                    // do caclulation
                    switch currTok {
                    case FN1ARGROUND:
                        result = round(v1)
                    case FN1ARGDELTA:
                        result = v1 - v0
                    case FN1ARGONRATIO:
                        if 0 == v1 {
                            return nil
                        }
                        result = v0 / v1
                    case FN1ARGNORATIO:
                        if 0 == v0 {
                            return nil
                        }
                        result = v1 / v0
                    default:
                        break
                    }
                case FN1ARGAVG:
                    // 14.iv.25  behavior change: average is over count of events, if they want per days have to do that explicitly

                    sql = String(format: "select count(val) from voData where id=%ld and val <> '' and date >=%ld and date <%d;", vid, epd0, epd1)
                    let count = Double(to.toQry2Float(sql:sql) + (nullV1 ? 0.0 : 1.0)) // +1 for current on screen
                    
                    if count == 0.0 {
                        // nothing in db to average and nullV1 so no current
                        return nil
                    }

                    sql = String(format: "select sum(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                    let v = Double(to.toQry2Float(sql:sql))
                    result = (v + v1) / count
                    #if FUNCTIONDBG
                    DBGLog(String("avg: v= \(v) v1= \(v1) (v+v1)= \(v + v1) c= \(count) rslt= \(result) "))
                    DBGLog("hello")
                    #endif
                case FN1ARGMIN:
                    if 0 == ci && nullV1 {
                        return nil
                    } else if 0 == ci {
                        result = v1
                    } else {
                        sql = String(format: "select min(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                        result = Double(to.toQry2Float(sql:sql))
                        if !nullV1 && v1 < result {
                            result = v1
                        }
                    }
                    #if FUNCTIONDBG
                    DBGLog(String("min: result= \(result)"))
                    #endif
                case FN1ARGMAX:
                    if 0 == ci && nullV1 {
                        return nil
                    } else if 0 == ci {
                        result = v1
                    } else {
                        sql = String(format: "select max(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                        result = Double(to.toQry2Float(sql:sql))
                        if !nullV1 && v1 > result {
                            result = v1
                        }
                    }
                    #if FUNCTIONDBG
                    DBGLog(String("max: result= \(result)"))
                    #endif
                case FN1ARGCOUNT:
                    sql = String(format: "select count(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                    result = Double(to.toQry2Float(sql:sql))
                    if !nullV1 {
                        result += 1.0
                    }
                    #if FUNCTIONDBG
                    DBGLog(String("count: result= \(result)"))
                    #endif
                case FN1ARGDELAY:
                    let ep0def = Int(self.vo.optDict["frep0"]!)
                    let ep0delta = (ep0def == FREPENTRY ? 0 : ep0def == FREPHOURS ? (60*60) : (60*60*24)) / 2
                    sql = String(format: "select val from voData where id=%ld and date >=%ld and date <%d limit 1;", vid, epd0-ep0delta, epd0+ep0delta)
                    result = Double(to.toQry2Float(sql:sql))
                    #if FUNCTIONDBG
                    DBGLog(String("delay: result= \(result)"))
                    #endif
                default:
                    // remaining options for fn w/ 1 arg are pre/post/all sum
                    switch currTok {
                    // by selecting for not null ep0 using total() these sum over intermediate non-endpoint values
                    // -- ignoring passed epd0
                    case FN1ARGPRESUM:
                        // we conditionally add in v1=(date<=%d) below so presum sql query same as sum

                        //to.sql = [NSString stringWithFormat:@"select total(val) from voData where id=%d and date >=%d and date <%d;",
                        //		  vid,epd0,epd1];
                        //break;
                        #if FUNCTIONDBG
                        DBGLog("presum: fall through")
                        #endif
                        fallthrough
                    case FN1ARGSUM:
                        // (date<%d) because add in v1 below
                        sql = String(format: "select total(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                        #if FUNCTIONDBG
                        DBGLog("sum: set sql")
                        #endif
                    case FN1ARGPOSTSUM:
                        // (date<%d) because add in v1 below
                        // 24.ii.2016 below does not really work, was created when start date was exact match to one to skip -- but with e.g. 'current-3 weeks' need to skip earliest value
                        sql = String(format: "select total(val) from voData where id=%ld and date >%ld and date <%d;", vid, epd0, epd1)

                        #if FUNCTIONDBG
                        DBGLog("postsum: set sql")
                        #endif
                    default:
                        break
                    }
                    result = Double(to.toQry2Float(sql:sql))
                    if currTok != FN1ARGPRESUM {
                        result += v1
                    }
                    #if FUNCTIONDBG
                    DBGLog(String("pre/post/sum: result= \(result)"))
                    #endif
                }
            } else if isFn2ArgOp(currTok) {
                // we are processing some combo of previous result and next value, currFnNdx was ++ already so get that result:
                let nrnum = calcFunctionValue(withCurrent: epd0, fn2op: true) // currFnNdx now at next place already
                if nil == nrnum {
                    return nil
                }
                let nextResult = nrnum?.doubleValue ?? 0.0
                switch currTok {
                // now just combine with what we have so far
                case FN2ARGPLUS:
                    result += nextResult
                    #if FUNCTIONDBG
                    DBGLog(String("fndbg plus [\(nextResult)]: result= \(result)"))
                    #endif
                case FN2ARGMINUS:
                    result -= nextResult
                    #if FUNCTIONDBG
                    DBGLog(String("fndbg minus [\(nextResult)]: result= \(result)"))
                    #endif
                case FN2ARGTIMES:
                    result *= nextResult
                    #if FUNCTIONDBG
                    DBGLog(String("fndbg times [\(nextResult)]: result= \(result)"))
                    #endif
                case FN2ARGDIVIDE:
                    if nrnum != nil && nextResult != 0.0 {
                        result /= nextResult
                        #if FUNCTIONDBG
                        DBGLog(String("fndbg divide [\(nextResult)]: result= \(result)"))
                        #endif
                    } else {
                        //result = nil;
                        #if FUNCTIONDBG
                        DBGLog("divide: rdivide by zero!")
                        #endif
                        return nil
                    }
                default:
                    break
                }
            } else if currTok == FNPARENOPEN {
                // open paren means just recurse and return the result up
                let nrnum = calcFunctionValue(withCurrent: epd0) // currFnNdx now at next place already
                if nil == nrnum {
                    return nil
                }
                result = nrnum?.doubleValue ?? 0.0
                #if FUNCTIONDBG
                DBGLog(String("fndbg paren open: result= \(result)"))
                #endif
            } else if currTok == FNPARENCLOSE {
                // close paren means we are there, return what we have
                #if FUNCTIONDBG
                DBGLog(String("fndbg paren close return with result= \(result)"))
                #endif
                return NSNumber(value: result)
            } else if FNCONSTANT == currTok {
                if currFnNdx >= maxc {
                    //DBGErr(@"constant fn missing arg: %@",self.fnArray);
                    FnErr = true
                    return NSNumber(value: result) // crashlytics report past array bounds above (1-arg) processing function, so safety check here to return without crashing
                }
                result = fnArray[currFnNdx].doubleValue
                currFnNdx += 1
                currFnNdx += 1 // skip the bounding constant tok
                #if FUNCTIONDBG
                DBGLog(String("paren open: result= \(result)"))
                #endif
            } else if isFnTimeOp(currTok) {
                if 0 == epd0 {
                    #if FUNCTIONDBG
                    DBGLog(" timefn: at beginning")
                    #endif
                    return nil
                }

                result = Double(epd1) - Double(epd0)
                #if FUNCTIONDBG
                DBGLog(String("timefn: \(result) secs"))
                #endif
                switch currTok {
                case FNTIMEWEEKS:
                    result /= 7 // 7 days /week
                    #if FUNCTIONDBG
                    DBGLog(String("timefn: weeks : \(result)"))
                    #endif
                    fallthrough
                case FNTIMEDAYS:
                    result /= 24 // 24 hrs / day
                    #if FUNCTIONDBG
                    DBGLog(String("timefn: days \(result)"))
                    #endif
                    fallthrough
                case FNTIMEHRS:
                    result /= 60 // 60 mins / hr
                    #if FUNCTIONDBG
                    DBGLog(String("timefn: hrs \(result)"))
                    #endif
                    fallthrough
                case FNTIMEMINS:
                    result /= 60 // 60 secs / min
                    #if FUNCTIONDBG
                    DBGLog(String("timefn: mins \(result)"))
                    #endif
                    fallthrough
                case FNTIMESECS:
                    #if FUNCTIONDBG
                    DBGLog(String("timefn: secs \(result)"))
                    #endif
                    fallthrough
                default:
                    //result /= d( 60 * 60 );  // 60 secs min * 60 secs hr
                    break
                }
                #if FUNCTIONDBG
                DBGLog(String("timefn: \(result) final units"))
                #endif
            } else {
                // remaining option is we have some vid as currTok, return its value up the chain
                let lvo = to.getValObj(currTok)!
                result = lvo.vos!.getNumVal()  // Double(lvo.value) ?? 0
                #if FUNCTIONDBG
                DBGLog(String("vid \(lvo.vid): result= \(result)"))
                #endif
                //result = [[to getValObj:currTok].value doubleValue];
                //self.currFnNdx++;  // on to next  // already there - postinc on read
            }
        }
        // swiftify oops?  currFnNdx += 1

        #if FUNCTIONDBG
        DBGLog(String("fndbg \(vo.valueName ?? "") calcFnValueWithCurrent rtn: \(NSNumber(value: result))"))
        #endif
        return NSNumber(value: result)

    }

    func checkEP(_ ep: Int) -> Bool {
        let epstr = "frep\(ep)"
        let epval = Int(vo.optDict[epstr] ?? "") ?? 0
        if epval >= 0 {
            // if epval is a valueObj
            let valo = MyTracker.getValObj(epval)
            if valo == nil || valo?.value == nil || (valo?.value == "") || (valo?.vtype == VOT_BOOLEAN && (valo?.value != "1")) {
                return false
            }
        }
        return true
    }

    //- (NSString*) currFunctionValue {
    override func update(_ instr: String?) -> String {
        let pto = vo.parentTracker

        if nil == pto.tDb {
            return ""
        }

        if !checkEP(1) {
            return ""
        }

        // search back for start endpoint that is ok
        let ep0start = Int(MyTracker.trackerDate!.timeIntervalSince1970)
        let ep0date = getEpDate(0, maxdate: ep0start) // start with immed prev to curr record set

#if FUNCTIONDBG
        DBGLog("ep0start \(Date(timeIntervalSince1970: TimeInterval(ep0start)))   ep0date \(Date(timeIntervalSince1970: TimeInterval(ep0date)))")
#endif
        
        if ep0date == 0 {
            // start endpoint not ok - no prior date
            if let nep = vo.optDict["frep0"], let ep = Int(nep), ep != FREPENTRY {
                // allow to go through if just looking for previous entry and this is first
                return instr ?? ""
            }
        }

        if instr?.isEmpty == false && !fnDirty {
            return instr ?? ""
        }
        
        if ep0date == lastEpd0 && !lastCalcValue.isEmpty {
            DBGLog("fn \(vo.valueName!) update using cached value \(lastCalcValue)")
            return lastCalcValue
        }
        
        currFnNdx = 0

        let val = calcFunctionValue(withCurrent: ep0date)
        
        #if FUNCTIONDBG
        DBGLog(String("fndbg fn update val= \(val)"))
        #endif
        if let val {
            let nddp = vo.optDict["fnddp"]
            let ddp = (nddp == nil ? FDDPDFLT : Int(nddp!))
            lastCalcValue = String(format: String(format: "%%0.%df", ddp!), val.floatValue)
            lastEpd0 = ep0date
            return lastCalcValue
        } else {
            lastEpd0 = -1
            lastCalcValue = ""  // empty
        }
        
        #if FUNCTIONDBG
        DBGLog(String("fndbg fn update returning: \(instr)"))
        #endif
        return instr ?? ""
    }

    override func voDisplay(_ bounds: CGRect) -> UIView {

        //trackerObj *to = (trackerObj*) parentTracker;
        vosFrame = bounds
        _rlab = nil  // force recreate
        
        //UILabel *rlab = [[UILabel alloc] initWithFrame:bounds];
        //rlab.textAlignment = UITextAlignmentRight;

        #if FABRIC
        CrashlyticsKit.setObjectValue(voFnDefnStr(true), forKey: "fnDefn")
        CrashlyticsKit.setObjectValue(voRangeStr(true), forKey: "fnRange")
        #endif

        var valstr = vo.value // evaluated on read so make copy
        if FnErr {
            valstr = "❌ " + (valstr)
        }
        if valstr != "" {
            rlab?.backgroundColor = .clear // was whiteColor
            rlab?.text = valstr
        } else {
            rlab?.backgroundColor = .secondarySystemBackground  //.lightGray
            rlab?.text = "-"
        }

        //return [rlab autorelease];
        DBGLog(String("fn voDisplay: \(rlab?.text ?? "")"))
        //self.rlab.tag = kViewTag;

        return rlab!
    }

    override func voGraphSet() -> [String] {
        return voState.voGraphSetNum()
    }

    // MARK: -
    
    // MARK: -
    // MARK: fn value results for graphing

    func trimFnVals(_ frep0: Int) {
        // deletes duplicate date entries depending on ep0
        
        DBGLog(String("ep= \(frep0)"))
        var sql: String

        var ival = Int(vo.optDict["frv0"]!)! * -1 // negative offset if ep0
        let gregorian = Calendar(identifier: .gregorian)
        var offsetComponents = DateComponents()

        switch frep0 {
        case FREPCDAYS:
            ival += 1 // for -1 calendar day, we want offset -0 day and normalize to previous midnight below
            offsetComponents.day = ival
            //vt = @"days";
        case FREPCWEEKS:
            ival += 1
            offsetComponents.weekOfYear = ival
            //vt = @"weeks";
        case FREPCMONTHS:
            ival += 1
            offsetComponents.month = ival
            //vt = @"months";
        case FREPCYEARS:
            ival += 1
            //vt = @"years";
            offsetComponents.year = ival
        default:
            dbgNSAssert(false, "trimFnVals: failed to identify ep \(frep0)")
        }

        var epDate = -1

        sql = String(format: "select date from voData where id = %ld order by date desc", Int(vo.vid))
        let dates = MyTracker.toQry2AryI(sql: sql)
        for d in dates {
            var targ = gregorian.date(
                byAdding: offsetComponents,
                to: Date(timeIntervalSince1970: TimeInterval(d)))

            var unitFlags: Set<Calendar.Component> = []

            switch frep0 {
            // if calendar week, we need to get to beginning of week as per calendar
            case FREPCWEEKS:
                targ = gregorian.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: targ!).date
                fallthrough
            // if any of week, day, month, year we need to wipe hour, minute, second components
            case FREPCDAYS:
                unitFlags.insert(.day)  // |= NSCalendar.Unit.day.rawValue
                fallthrough
            case FREPCMONTHS:
                unitFlags.insert(.month)  //  |= NSCalendar.Unit.month.rawValue
                fallthrough
            case FREPCYEARS:
                unitFlags.insert(.year)  //  |= NSCalendar.Unit.year.rawValue
                var components: DateComponents? = nil
                if let targ {
                    components = gregorian.dateComponents(unitFlags, from: targ)
                }
                if let components {
                    targ = gregorian.date(from: components)
                }
                fallthrough
            default:
                break
            }

            let currD = Int(targ?.timeIntervalSince1970 ?? 0)
            if epDate == currD {
                sql = String(format: "delete from voData where id = %ld and date = %d", Int(vo.vid), d) // safe because this is just cached fn rslt
                MyTracker.toExecSql(sql:sql)
                sql = "delete from voFNstatus where id = \(vo.vid) and date = \(d);"
                MyTracker.toExecSql(sql:sql)
            } else {
                epDate = currD
            }
        }
    }

    override func setFnVal(_ tDate: Int, dispatchGroup: DispatchGroup?) {
        dispatchGroup?.enter()
        // track vo's in fnstatus so can delete independently
        var sql: String
        // vo.value is computed for this tracker date from loaded tracker data when we read it here because reading calls update()
        // but db must be cleared for vot_function s or will just get db value
        if vo.value == "" {
            // if value is empty we should not have data in db
            sql = "delete from voData where id = \(vo.vid) and date = \(tDate);"
            MyTracker.toExecSql(sql:sql)
            sql = "delete from voFNstatus where id = \(vo.vid) and date = \(tDate);"
            MyTracker.toExecSql(sql:sql)
        } else {
            let val = rTracker_resource.toSqlStr(vo.value)
            sql = "insert or replace into voData (id, date, val) values (\(vo.vid), \(tDate),'\(val)');"
            MyTracker.toExecSql(sql:sql)
            sql = "insert into voFNstatus (id, date, stat) values (\(vo.vid), \(tDate), \(fnStatus.fnData.rawValue))"
            MyTracker.toExecSql(sql:sql)
        }
        dispatchGroup?.leave()
    }

    override func clearFNdata() {
        let to = vo.parentTracker
        var sql = "delete from voData where (id, date) in (select id, date from voFNstatus where id = \(vo.vid))"
        to.toExecSql(sql: sql)
        sql = "delete from voFNstatus where id = \(vo.vid)"
        to.toExecSql(sql: sql)
    }
    
    override func setFNrecalc() {
        // force recaclulation, no cached value
        lastCalcValue = ""
        fnDirty = true
    }
    
    override func doTrimFnVals() {
        let frep0 = Int(vo.optDict["frep0"]!)!
        if ISCALFREP(frep0) && (vo.optDict["graphlast"] != "0") && MyTracker.goRecalculate {
            trimFnVals(frep0)
        }
    }

    override func newVOGD() -> vogd {
        return vogd(vo).initAsNum(vo)
    }
    
    
    // MARK: protocol: voDrawOptions page

    override func setOptDictDflts() {
        if nil == vo.optDict["frep0"] {
            vo.optDict["frep0"] = "\(FREPDFLT)"
        }
        if nil == vo.optDict["frep1"] {
            vo.optDict["frep1"] = "\(FREPDFLT)"
        }
        if nil == vo.optDict["fnddp"] {
            vo.optDict["fnddp"] = "\(FDDPDFLT)"
        }
        if nil == vo.optDict["func"] {
            vo.optDict["func"] = ""
        }
        if nil == vo.optDict["autoscale"] {
            vo.optDict["autoscale"] = AUTOSCALEDFLT ? "1" : "0"
        }
        if nil == vo.optDict["graphlast"] {
            vo.optDict["graphlast"] = GRAPHLASTDFLT ? "1" : "0"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "frep0") && (Int(val!) == FREPDFLT))
            || ((key == "frep1") && (Int(val!) == FREPDFLT))
            || ((key == "fnddp") && (Int(val!) == FDDPDFLT))
            || ((key == "func") && (val! == ""))
            || ((key == "autoscale") && (val! == (AUTOSCALEDFLT ? "1" : "0")))
            || ((key == "graphlast") && (val! == (GRAPHLASTDFLT ? "1" : "0"))) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC?) {
        ctvovcp = ctvovc
        reloadEmptyFnArray()
        drawSelectedPage()
    }
}
