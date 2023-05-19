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

import Crashlytics
import Fabric
import Foundation

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

let FNNEW1ARGLAST = FNNEW1ARGFIRST - 100

func isFn1Arg(_ i: Any) -> Bool {
    ((i <= FN1ARGFIRST) && (i >= FN1ARGLAST)) || ((i <= FNNEW1ARGFIRST) && (i >= FNNEW1ARGLAST))
}
func isFn1ArgElapsed(_ i: Any) -> Bool {
    (i <= FN1ARGELAPSEDWEEKS) && (i >= FN1ARGELAPSEDSECS)
}

let FNNEW2ARGFIRST = FNNEW1ARGLAST - 10
let FNNEW2ARGLAST = FNNEW2ARGFIRST - 100

func isFn2ArgOp(_ i: Any) -> Bool {
    ((i <= FN2ARGFIRST) && (i >= FN2ARGLAST)) || ((i <= FNNEW2ARGFIRST) && (i >= FNNEW2ARGLAST))
}

let FNNEWTIMEFIRST = FNNEW2ARGLAST - 10
let FNTIMEMINS = FNNEWTIMEFIRST - 1
let FNTIMESECS = FNTIMEMINS - 1
let FNNEWTIMELAST = FNNEWTIMEFIRST - 100

func isFnTimeOp(_ i: Any) -> Bool {
    ((i <= FNTIMEFIRST) && (i >= FNTIMELAST)) || ((i <= FNNEWTIMEFIRST) && (i >= FNNEWTIMELAST))
}


let FNFIN = FNNEWTIMELAST

func isFn(_ i: Any) -> Bool {
    (i <= FNSTART) && (i >= FNFIN)
}

let FNCONSTANT_TITLE = "constant"


func ARG1FNS() {
    FN1ARGDELTA
    FN1ARGSUM
    FN1ARGPOSTSUM
    FN1ARGPRESUM
    FN1ARGAVG
    FN1ARGMIN
    FN1ARGMAX
    FN1ARGCOUNT
    FN1ARGONRATIO
    FN1ARGNORATIO
    FN1ARGELAPSEDWEEKS
    FN1ARGELAPSEDDAYS
    FN1ARGELAPSEDHOURS
    FN1ARGELAPSEDMINS
    FN1ARGELAPSEDSECS
}
func ARG1STRS() {
    "change_in"
    "sum"
    "post-sum"
    "pre-sum"
    "avg"
    "min"
    "max"
    "count"
    "old/new"
    "new/old"
    "elapsed_weeks"
    "elapsed_days"
    "elapsed_hrs"
    "elapsed_mins"
    "elapsed_secs"
}
let ARG1CNT = 15

func ARG2FNS() {
    FN2ARGPLUS
    FN2ARGMINUS
    FN2ARGTIMES
    FN2ARGDIVIDE
}
func ARG2STRS() {
    "+"
    "-"
    "*"
    "/"
}
let ARG2CNT = 4

func PARENFNS() {
    FNPARENOPEN
    FNPARENCLOSE
}
func PARENSTRS() {
    "("
    ")"
}
let PARENCNT = 2

func TIMEFNS() {
    FNTIMEWEEKS
    FNTIMEDAYS
    FNTIMEHRS
    FNTIMEMINS
    FNTIMESECS
}
func TIMESTRS() {
    "weeks"
    "days"
    "hours"
    "minutes"
    "seconds"
}
let TIMECNT = 5

let OTHERFNS = FNCONSTANT
let OTHERSTRS = FNCONSTANT_TITLE
let OTHERCNT = 1

let TOTFNCNT = ARG1CNT + ARG2CNT + PARENCNT + TIMECNT + OTHERCNT

//xx c arr = double balance[] = {1000.0, 2.0, 3.4, 17.0, 50.0};

//#define FnArrMap   FN1ARGDELTA,FN1ARGSUM,FN1ARGPOSTSUM,FN1ARGPRESUM,FN1ARGAVG,FN1ARGMIN,FN1ARGMAX,FN1ARGCOUNT,FN2ARGPLUS,FN2ARGMINUS,FN2ARGTIMES,FN2ARGDIVIDE,FNPARENOPEN,FNPARENCLOSE,FNPARENCLOSE,FNTIMEWEEKS,FNTIMEDAYS,FNTIMEHRS,FNCONSTANT
// FnArrStrs must be same order as #defines above
//#define FnArrStrs	@"change_in", @"sum", @"post-sum", @"pre-sum", @"avg", @"min", @"max", @"count", @"+", @"-", @"*", @"/", @"(", @")",@"weeks",@"days",@"hours", FNCONSTANT_TITLE


// range endpoint symbols tied to epTitles ivar creation
//   @"entry", @"hours", @"days", @"weeks", @"months", @"years"

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

func ISCALFREP(_ x: Any) -> Bool {
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
    /*{
    	configTVObjVC *ctvovcp;

    	NSInteger fnSegNdx;				// overview, range, or fn definition page in configTVObjVC
    	NSArray *epTitles;				// available range endpoints: valueObjs or offsets (hour, month, ...)
    	NSMutableArray *fnTitles;		// 
    	NSMutableArray *fnArray;		// ordered array of symbols (valObj [vid] or operation [<0]) to compute, <=> optDict:@"func"
    	//NSMutableArray *fnStrs;			// valueObj names or predefined operation names (map to symbols, vids in nfArray)
        NSArray *fn2args;
    	NSInteger currFnNdx;			// index as we compute the function

        UILabel *rlab;

        NSArray *votWoSelf;             // myTracker's valobjtable without reference to self for picking endpoints
    }*/

    //@property (nonatomic,retain) NSMutableArray *fnStrs;

    private var _fnStrDict: [AnyHashable : Any]?
    var fnStrDict: [AnyHashable : Any]? {
        if nil == _fnStrDict {
            let fnTokArr = [PARENFNS, OTHERFNS]
            let fnStrArr = [ARG1STRS, ARG2STRS, TIMESTRS, PARENSTRS, OTHERSTRS]
            let fnTokNSNarr: [NSNumber]? = nil

            var i: Int
            let j = 0
            for i in 0..<ARG1CNT {
                fnTokNSNarr?[j] = (fn1args)?[i] as? NSNumber
                j += 1
            }
            for i in 0..<ARG2CNT {
                fnTokNSNarr?[j] = (fn2args)?[i] as? NSNumber
                j += 1
            }
            for i in 0..<TIMECNT {
                fnTokNSNarr?[j] = (fnTimeOps)?[i] as? NSNumber
                j += 1
            }
            for i in 0..<(PARENCNT + OTHERCNT) {
                fnTokNSNarr?[j] = NSNumber(value: fnTokArr[i])
                j += 1
            }
            //fnStrDict = [NSDictionary dictionaryWithObjects:fnStrArr forKeys:fnTokNSNarr count:TOTFNCNT];
            _fnStrDict = NSDictionary(objects:fnStrArr as [AnyObject]?, forKeys:fnTokNSNarr as [NSCopying]?, count: TOTFNCNT) as Dictionary
        }
        return _fnStrDict
    }

    private var _fn1args: [AnyHashable]?
    var fn1args: [AnyHashable]? {
        if nil == _fn1args {
            let fn1argToks = [ARG1FNS]
            let fn1argsArr: [NSNumber]? = nil
            var i: Int
            for i in 0..<ARG1CNT {
                fn1argsArr?[i] = NSNumber(value: fn1argToks[i])
            }
            if let fn1argsArr {
                _fn1args = Array(fn1argsArr[..<ARG1CNT]) // copyItems: true
            }
        }
        return _fn1args
    }

    private var _fn2args: [AnyHashable]?
    var fn2args: [AnyHashable]? {
        if nil == _fn2args {
            let fn2argToks = [ARG2FNS]
            let fn2argsArr: [NSNumber]? = nil
            var i: Int
            for i in 0..<ARG2CNT {
                fn2argsArr?[i] = NSNumber(value: fn2argToks[i])
            }
            if let fn2argsArr {
                _fn2args = Array(fn2argsArr[..<ARG2CNT]) // copyItems: true
            }
        }

        return _fn2args
    }

    private var _fnTimeOps: [AnyHashable]?
    var fnTimeOps: [AnyHashable]? {
        if nil == _fnTimeOps {
            let fnTimeOpToks = [TIMEFNS]
            let fnTimeOpsArr: [NSNumber]? = nil
            var i: Int
            for i in 0..<TIMECNT {
                fnTimeOpsArr?[i] = NSNumber(value: fnTimeOpToks[i])
            }
            if let fnTimeOpsArr {
                _fnTimeOps = Array(fnTimeOpsArr[..<TIMECNT]) // copyItems: true
            }
        }
        return _fnTimeOps
    }
    var ctvovcp: configTVObjVC?
    var fnSegNdx = 0

    private var _epTitles: [AnyHashable]?
    var epTitles: [AnyHashable]? {
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
        return _epTitles
    }

    private var _fnTitles: [AnyHashable]?
    var fnTitles: [AnyHashable]? {
        if _fnTitles == nil {
            _fnTitles = []
        }
        return _fnTitles
    }

    private var _fnArray: [AnyHashable]?
    var fnArray: [AnyHashable]? {
        if _fnArray == nil {
            _fnArray = []
        }
        return _fnArray
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
        }
        return _rlab
    }

    private var _votWoSelf: [AnyHashable]?
    var votWoSelf: [AnyHashable]? {
        if nil == _votWoSelf {
            //if (0 > self.vo.vid) {  // temporary vo waiting for save so not included in tracker's vo table
            //  -> no, could be editinging an already existing entry
            //    votWoSelf = [NSArray arrayWithArray:MyTracker.valObjTable];
            //} else {

            var tvot = [AnyHashable](repeating: 0, count: MyTracker?.valObjTable?.count ?? 0)
            for tvo in MyTracker?.valObjTable ?? [] {
                guard let tvo = tvo as? valueObj else {
                    continue
                }
                if tvo.vid != vo?.vid {
                    tvot.append(tvo)
                }
            }
            //votWoSelf = [NSArray arrayWithArray:tvot];
            _votWoSelf = tvot
            // not needed? [tvot release];
            //}
            /*
                    DBGLog(@"instantiate votWoSelf:");
                    DBGLog(@"self.vo vid=%d  name= %@",self.vo.vid,self.vo.valueName);
                    for (valueObj *mvo in votWoSelf) {
                        DBGLog(@"  %d: %@",mvo.vid,mvo.valueName);
                    }
                    DBGLog(@".");
            */
        }
        return _votWoSelf
    }

    //@property (nonatomic, retain) NSNumber *foo;
    func saveFnArray() {
        // note this converts NSNumbers to NSStrings
        // works because NSNumber returns an NSString for [description]

        //[self.vo.optDict setObject:[self.fnArray componentsJoinedByString:@" "] forKey:@"func"];
        // don't save an empty string
        let ts = fnArray?.joined(separator: " ")
        //DBGLog(@"saving fnArray ts= .%@.",ts);
        if 0 < (ts?.count ?? 0) {
            (vo?.optDict)?["func"] = ts
        }
    }

    func loadFnArray() {

        fnArray?.removeAll()
        // all works fine if we load as strings with 
        // [self.fnArray addObjectsFromArray: [[self.vo.optDict objectForKey:@"func"] componentsSeparatedByString:@" "];
        // but prefer to keep as NSNumbers 

        let tmp = (vo?.optDict)?["func"]?.components(separatedBy: " ")
        for s in tmp ?? [] {
            if "" != s {
                //[self.fnArray addObject:[NSNumber numberWithInteger:[s integerValue]]];
                fnArray?.append(NSNumber(value: Double(s) ?? 0.0)) // because of constant
            }
        }
    }

    // MARK: protocol: getValCap

    override func getValCap() -> Int {
        // NSMutableString size for value
        return 32
    }

    // MARK: protocol: loadConfig

    override func loadConfig() {
        loadFnArray()
        if nil == vo?.optDict?["frep0"] {
            (vo?.optDict)?["frep0"] = NSNumber(value: FREPDFLT)
        }
        if nil == vo?.optDict?["frep1"] {
            (vo?.optDict)?["frep1"] = NSNumber(value: FREPDFLT)
        }

    }

    // MARK: protocol: updateVORefs

    // called to instantiate tempTrackerObj with -vid to real trackerObj on save tracker config

    override func updateVORefs(_ newVID: Int, old oldVID: Int) {
        loadFnArray()
        var i = 0
        let max = fnArray?.count ?? 0
        #if FUNCTIONDBG
        DBGLog("start fnArray= %@", fnArray)
        #endif
        for i in 0..<max {
            if ((fnArray)?[i] as? NSNumber)?.intValue ?? 0 == oldVID {
                (fnArray)?[i] = NSNumber(value: newVID)
            }
        }
        #if FUNCTIONDBG
        DBGLog("fin fnArray= %@", fnArray)
        #endif
        saveFnArray()

        for i in 0..<2 {
            let key = String(format: "frep%lu", UInt(i))
            let nep = (vo?.optDict)?[key] as? NSNumber
            let ep = nep?.intValue ?? 0
            if ep == oldVID {
                (vo?.optDict)?[key] = NSNumber(value: newVID)
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
        let nep = (vo?.optDict)?[key] as? NSNumber
        let ep = nep?.intValue ?? 0
        var epDate: Int
        let to = MyTracker
        var sql: String?

        if nep == nil || ep == FREPENTRY {
            // also FREPDFLT  -- no value specified
            // use last entry
            sql = String(format: "select date from trkrData where date < %ld order by date desc limit 1;", maxdate)
            epDate = to?.toQry2Int(sql) ?? 0
            //DBGLog(@"ep %d ->entry: %@", ndx, [self qdate:epDate] );
        } else if ep >= 0 {
            // ep is vid
            sql = String(format: "select date from voData where id=%ld and date < %ld and val <> 0 and val <> '' order by date desc limit 1;", ep, maxdate) // add val<>0,<>"" 5.vii.12
            #if FUNCTIONDBG
            DBGLog("get ep qry: %@", sql)
            #endif
            epDate = to?.toQry2Int(sql) ?? 0
            #if FUNCTIONDBG
            DBGLog("ep %d ->vo %@: %@", ndx, vo?.valueName, qdate(epDate))
            #endif
        } else {
            // ep is (offset * -1)+1 into epTitles, with optDict:frv0 multiplier

            let vkey = "frv\(ndx)"
            var ival = ((vo?.optDict)?[vkey] as? NSNumber)?.intValue ?? 0 * (ndx != 0 ? 1 : -1) // negative offset if ep0
            let gregorian = Calendar(identifier: .gregorian)
            gregorian?.locale = NSLocale.current
            let offsetComponents = DateComponents()

            //NSString *vt=nil;

            switch ep {
            case FREPNONE:
                // no previous endpoint - find nothing prior to now
                break
            case FREPHOURS:
                offsetComponents.hour = ival
                //vt = @"hours";
            case FREPCDAYS:
                ival += ndx != 0 ? 0 : 1 // for -1 calendar day, we want offset -0 day and normalize to previous midnight below
            case FREPDAYS:
                offsetComponents.day = ival
                //vt = @"days";
            case FREPCWEEKS:
                ival += ndx != 0 ? 0 : 1
            case FREPWEEKS:
                offsetComponents.weekOfYear = ival
                //vt = @"weeks";
            case FREPCMONTHS:
                ival += ndx != 0 ? 0 : 1
            case FREPMONTHS:
                offsetComponents.month = ival
                //vt = @"months";
            case FREPCYEARS:
                ival += ndx != 0 ? 0 : 1
            case FREPYEARS:
                //vt = @"years";
                offsetComponents.year = ival
            default:
                dbgNSAssert1(0, "getEpDate: failed to identify ep %ld", ep)
            }

            var targ = gregorian?.date(
                byAdding: offsetComponents,
                to: Date(timeIntervalSince1970: TimeInterval(maxdate)),
                options: [])

            var unitFlags: UInt = 0

            switch ep {
            // if calendar week, we need to get to beginning of week as per calendar
            case FREPCWEEKS:
                DBGLog("first day of week= %lu targ= %@", UInt(gregorian?.firstWeekday ?? 0), targ)
                var beginOfWeek: Date? = nil
                /*
                                 // ios8 deprecation of NSWeekCalendarUnit -- WeekOfMonth and WeekOfYear below give same result; NSCalendarUnitWeekday does not respect locale preferences
                                 // note dbg messages time given in GMT but we fall through cases below and wipe the time component
                                 // so we need to get the begin of week date utc time 00:00:00 to be the date in the local time zone
                                 BOOL rslt = [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginOfWeek interval:NULL forDate: targ];
                                 DBGLog(@"NSWeekCalendarUnit (iOS7) %d %@ ",rslt,beginOfWeek);
                                 rslt = [gregorian rangeOfUnit:NSCalendarUnitWeekOfMonth startDate:&beginOfWeek interval:NULL forDate: targ];
                                 DBGLog(@"NSCalendarUnitWeekOfMonth (iOS8) %d %@ ",rslt,beginOfWeek);
                                 rslt = [gregorian rangeOfUnit:NSCalendarUnitWeekday startDate:&beginOfWeek interval:NULL forDate: targ];
                                 DBGLog(@"NSCalendarUnitWeekday (iOS8) %d %@ %",rslt,beginOfWeek);
                                 */

                var rslt = false
                if let targ {
                    rslt = gregorian?.range(of: .weekOfYear, start: &beginOfWeek, interval: nil, for: targ) ?? false
                }

                DBGLog("NSCalendarUnitWeekOfYear (iOS8) %d %@", rslt, beginOfWeek)

                if rslt {
                    // need to shift date with 00:00:00 UTC ( = 21:00 day before in tz ) to local timezone so day component is correct 
                    let tz = NSTimeZone.default as NSTimeZone
                    if let beginOfWeek {
                        targ = beginOfWeek?.addingTimeInterval(TimeInterval(tz.secondsFromGMT(for: beginOfWeek)))
                    }
                    // DBGLog(@"targ= %@",targ);
                }
            // if any of week, day, month, year we need to wipe hour, minute, second components
            case FREPCDAYS:
                unitFlags |= NSCalendar.Unit.day.rawValue
            case FREPCMONTHS:
                unitFlags |= NSCalendar.Unit.month.rawValue
            case FREPCYEARS:
                unitFlags |= NSCalendar.Unit.year.rawValue
                var components: DateComponents? = nil
                if let targ {
                    components = gregorian?.components(NSCalendar.Unit(rawValue: unitFlags), from: targ)
                }
                if let components {
                    targ = gregorian?.date(from: components)
                }
            default:
                break
            }


            epDate = Int(targ?.timeIntervalSince1970 ?? 0)
            #if FUNCTIONDBG
            DBGLog("ep %d ->offset %ld: %@", ndx, ival, qdate(epDate))
            #endif
        }
        //sql = nil;

        return epDate
    }

    func calcFunctionValue(_ datePair: [AnyHashable]?) -> NSNumber? {
        // TODO: finish this -- not used
        if datePair == nil {
            return nil
        }
        var sql: String?

        let epd0 = (datePair?[0] as? NSNumber)?.intValue ?? 0
        let epd1 = (datePair?[1] as? NSNumber)?.intValue ?? 0

        let maxc = fnArray?.count ?? 0
        var vid: Int
        let to = MyTracker

        var result = 0.0
        var v0 = 0.0
        var v1 = 0.0

        while currFnNdx < maxc {
            let currTok = ((fnArray)?[currFnNdx] as? NSNumber)?.intValue ?? 0
            if isFn1Arg(currTok) {
                currFnNdx += 1
                vid = ((fnArray)?[currFnNdx] as? NSNumber)?.intValue ?? 0
                switch currTok {
                case FN1ARGDELTA:
                    if epd1 == 0 {
                        v1 = Double(to?.getValObj(vid)?.value ?? "") ?? 0.0
                    } else {
                        sql = String(format: "select val from voData where vid=%ld and date=%d;", vid, epd1)
                        v1 = to?.toQry2Double(sql) ?? 0.0
                    }
                    sql = String(format: "select val from voData where vid=%ld and date=%d;", vid, epd0)
                    v0 = to?.toQry2Double(sql) ?? 0.0
                    result = v1 - v0
                case FN1ARGAVG:
                    if epd1 == 0 {
                        v1 = Double(to?.getValObj(vid)?.value ?? "") ?? 0.0
                        sql = String(format: "select avg(val) from voData where vid=%ld and date >=%d;", vid, epd0)
                        result = Double(to?.toQry2Float(sql) ?? 0.0) + v1
                    } else {
                        sql = String(format: "select avg(val) from voData where vid=%ld and date >=%d and date <=%d;", vid, epd0, epd1)
                        result = Double(to?.toQry2Float(sql) ?? 0.0)
                    }
                default:
                    switch currTok {
                    case FN1ARGSUM, FN1ARGPOSTSUM, FN1ARGPRESUM:
                        break
                    default:
                        break
                    }
                }
            }
        }


        return NSNumber(value: result)

    }

    // supplied with previous endpoint (endpoint 0), calculate function to current tracker
    func calcFunctionValue(withCurrent epd0: Int) -> NSNumber? {

        let maxc = fnArray?.count ?? 0
        var vid = 0
        let to = vo?.parentTracker as? trackerObj // MyTracker;
        var sql: String?

        FnErr = false

        #if FUNCTIONDBG
        // print our complete function
        var i: Int
        var outstr = ""
        for i in 0..<maxc {
            if let object = fnArray?[i] {
                outstr = outstr + " \(object)"
            }
        }
        DBGLog("%@ calcFnValueWithCurrent fnArray= %@ ", vo?.valueName, outstr)
        #endif

        var epd1: Int
        if to?.trackerDate == nil {
            // current tracker entry no date set so epd1=now
            epd1 = Int(Date().timeIntervalSince1970)
        } else {
            // set epd1 to date of current (this) tracker entry
            epd1 = Int(to?.trackerDate?.timeIntervalSince1970 ?? 0)
        }

        var result = 0.0

        while currFnNdx < maxc {
            // recursive function, self.currFnNdx holds our current processing position
            let currTok = ((fnArray)?[currFnNdx] as? NSNumber)?.intValue ?? 0
            if isFn1Arg(currTok) {
                // currTok is function taking 1 argument, so get it
                if currFnNdx >= maxc {
                    // <--- added from line 462
                    //DBGErr(@"1-arg fn missing arg: %@",self.fnArray);
                    FnErr = true
                    return NSNumber(value: result) // crashlytics report past array bounds at next line, so at least return without crashing
                }
                vid = ((fnArray)?[currFnNdx] as? NSNumber)?.intValue ?? 0
                currFnNdx += 1 // get fn arg, can only be valobj vid
                //valueObj *valo = [to getValObj:vid];
                let sv1 = to?.getValObj(vid)?.value
                let nullV1 = nil == sv1 || ("" == sv1)
                let v1 = Double(sv1 ?? "") ?? 0.0
                sql = String(format: "select count(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                var ci = to?.toQry2Int(sql) ?? 0
                #if FUNCTIONDBG
                DBGLog(
                    "v1= %f nullV1=%d vid=%ld %@:%@",
                    v1,
                    nullV1,
                    vid,
                    (vo?.parentTracker as? trackerObj)?.trackerName,
                    vo?.valueName)
                #endif
                // v1 is value for current tracker entry (epd1) for our arg
                switch currTok {
                // changed to date > epd1 for consistency with other functions
                case FN1ARGDELTA, FN1ARGONRATIO, FN1ARGNORATIO, FN1ARGELAPSEDWEEKS, FN1ARGELAPSEDDAYS, FN1ARGELAPSEDHOURS, FN1ARGELAPSEDMINS, FN1ARGELAPSEDSECS:
                    if nullV1 {
                        return nil // delta requires v1 to subtract from, sums and avg just get one less result
                    }
                    // epd1 value is ok, get from db value for epd0
                    //to.sql = [NSString stringWithFormat:@"select val from voData where id=%d and date=%d;",vid,epd0];
                    // with per calendar date calcs, epd0 may not match a datapoint
                    // - so get val coming into this time segment or skip for beginning - rtm 17.iii.13
                    sql = String(format: "select count(val) from voData where id=%ld and date>=%ld;", vid, epd0)
                    ci = to?.toQry2Int(sql) ?? 0 // slightly different for delta
                    if 0 == ci {
                        return nil // skip for beginning
                    }
                    if isFn1ArgElapsed(currTok) {
                        sql = String(format: "select date from voData where id=%ld and date>=%ld order by date asc limit 1;", vid, epd0)
                        let d0 = to?.toQry2Int(sql) ?? 0
                        result = Double(epd1) - Double(d0)
                        DBGLog("elapsed unit: epd0= %ld d0= %d epd1=%d rslt= %lf", epd0, d0, epd1, result)
                        switch currTok {
                        case FN1ARGELAPSEDWEEKS:
                            result /= d(7)
                        case FN1ARGELAPSEDDAYS:
                            result /= d(24)
                        case FN1ARGELAPSEDHOURS:
                            result /= d(60)
                        case FN1ARGELAPSEDMINS:
                            result /= d(60)
                        case FN1ARGELAPSEDSECS:
                            fallthrough
                        default:
                            break
                        }
                        DBGLog("elapsed unit: final result = %lf", result)
                    }
                    sql = String(format: "select val from voData where id=%ld and date>=%ld order by date asc limit 1;", vid, epd0) // desc->asc 22.ii.2016 to match <= -> >= change 25.01.16
                    let v0 = to?.toQry2Double(sql) ?? 0.0
                    #if FUNCTIONDBG
                    DBGLog("delta/on_ratio/no_ratio: v0= %f", v0)
                    #endif
                    // do caclulation
                    switch currTok {
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
                    // below (calculate via sqlite) works but need to include any current but unsaved value
                    //to.sql = [NSString stringWithFormat:@"select avg(val) from voData where id=%d and date >=%d and date <%d;",
                    //		  vid,epd0,epd1];
                    //result = [to toQry2Float:sql];  // --> + v1;

                    var c = ((vo?.optDict)?["frv0"] as? NSNumber)?.doubleValue ?? 0.0 // if ep has assoc value, then avg is over that num with date/time range already determined
                    // in other words, is it avg over 'frv' number of hours/days/weeks then that is our denominator
                    if c == 0.0 {
                        // else denom is number of entries between epd0 to epd1 
                        sql = String(format: "select count(val) from voData where id=%ld and val <> '' and date >=%ld and date <%d;", vid, epd0, epd1)
                        c = Double((to?.toQry2Float(sql) ?? 0.0) + (nullV1 ? 0.0 : 1.0)) // +1 for current on screen
                    }

                    if c == 0.0 {
                        return nil
                    }
                    sql = String(format: "select sum(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                    let v = Double(to?.toQry2Float(sql) ?? 0.0)
                    result = (v + v1) / c
                    #if FUNCTIONDBG
                    DBGLog("avg: v= %f v1= %f (v+v1)= %f c= %f rslt= %f ", v, v1, (v + v1), c, result)
                    #endif
                case FN1ARGMIN:
                    if 0 == ci && nullV1 {
                        return nil
                    } else if 0 == ci {
                        result = v1
                    } else {
                        sql = String(format: "select min(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                        result = Double(to?.toQry2Float(sql) ?? 0.0)
                        if !nullV1 && v1 < result {
                            result = v1
                        }
                    }
                    #if FUNCTIONDBG
                    DBGLog("min: result= %f", result)
                    #endif
                case FN1ARGMAX:
                    if 0 == ci && nullV1 {
                        return nil
                    } else if 0 == ci {
                        result = v1
                    } else {
                        sql = String(format: "select max(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                        result = Double(to?.toQry2Float(sql) ?? 0.0)
                        if !nullV1 && v1 > result {
                            result = v1
                        }
                    }
                    #if FUNCTIONDBG
                    DBGLog("max: result= %f", result)
                    #endif
                case FN1ARGCOUNT:
                    sql = String(format: "select count(val) from voData where id=%ld and date >=%ld and date <%d;", vid, epd0, epd1)
                    result = Double(to?.toQry2Float(sql) ?? 0.0)
                    if !nullV1 {
                        result += 1.0
                    }
                    #if FUNCTIONDBG
                    DBGLog("count: result= %f", result)
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
                        /*
                                                     // except
                                                    sql = [NSString stringWithFormat:@"select date from voData where id=%ld and date >=%ld and date <%d limit 1;",(long)vid,(long)epd0,epd1];
                                                    int firstDate = [to toQry2Int:sql];
                                                    if (firstDate) {
                                                        sql = [NSString stringWithFormat:@"select total(val) from voData where id=%ld and date >%d and date <%d;",(long)vid,firstDate,epd1];
                                                    } else {
                                                        sql = @"select 0";
                                                    }
                                                     */
                        #if FUNCTIONDBG
                        DBGLog("postsum: set sql")
                        #endif
                    default:
                        break
                    }
                    result = Double(to?.toQry2Float(sql) ?? 0.0)
                    if currTok != FN1ARGPRESUM {
                        result += v1
                    }
                    #if FUNCTIONDBG
                    DBGLog("pre/post/sum: result= %f", result)
                    #endif
                }
            } else if isFn2ArgOp(currTok) {
                // we are processing some combo of previous result and next value, currFnNdx was ++ already so get that result:
                let nrnum = calcFunctionValue(withCurrent: epd0) // currFnNdx now at next place already
                if nil == nrnum {
                    return nil
                }
                let nextResult = nrnum?.doubleValue ?? 0.0
                switch currTok {
                // now just combine with what we have so far
                case FN2ARGPLUS:
                    result += nextResult
                    #if FUNCTIONDBG
                    DBGLog("plus: result= %f", result)
                    #endif
                case FN2ARGMINUS:
                    result -= nextResult
                    #if FUNCTIONDBG
                    DBGLog("minus: result= %f", result)
                    #endif
                case FN2ARGTIMES:
                    result *= nextResult
                    #if FUNCTIONDBG
                    DBGLog("times: result= %f", result)
                    #endif
                case FN2ARGDIVIDE:
                    if nrnum != nil && nextResult != 0.0 {
                        result /= nextResult
                        #if FUNCTIONDBG
                        DBGLog("divide: result= %f", result)
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
                DBGLog("paren open: result= %f", result)
                #endif
            } else if currTok == FNPARENCLOSE {
                // close paren means we are there, return what we have
                #if FUNCTIONDBG
                DBGLog("paren close: result= %f", result)
                #endif
                return NSNumber(value: result)
            } else if FNCONSTANT == currTok {
                if currFnNdx >= maxc {
                    //DBGErr(@"constant fn missing arg: %@",self.fnArray);
                    FnErr = true
                    return NSNumber(value: result) // crashlytics report past array bounds above (1-arg) processing function, so safety check here to return without crashing
                }
                result = ((fnArray)?[currFnNdx] as? NSNumber)?.doubleValue ?? 0.0
                currFnNdx += 1
                currFnNdx += 1 // skip the bounding constant tok
                #if FUNCTIONDBG
                DBGLog("constant: result= %f", result)
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
                DBGLog(" timefn: %f secs", result)
                #endif
                switch currTok {
                case FNTIMEWEEKS:
                    result /= 7 // 7 days /week
                    #if FUNCTIONDBG
                    DBGLog(" timefn: weeks : %f ", result)
                #endif
                case FNTIMEDAYS:
                    result /= 24 // 24 hrs / day
                    #if FUNCTIONDBG
                    DBGLog(" timefn: days %f ", result)
                #endif
                case FNTIMEHRS:
                    result /= 60 // 60 mins / hr
                    #if FUNCTIONDBG
                    DBGLog(" timefn: hrs %f ", result)
                #endif
                case FNTIMEMINS:
                    result /= 60 // 60 secs / min
                    #if FUNCTIONDBG
                    DBGLog(" timefn: mins %f ", result)
                #endif
                case FNTIMESECS:
                    #if FUNCTIONDBG
                    DBGLog(" timefn: secs %f ", result)
                #endif
                default:
                    //result /= d( 60 * 60 );  // 60 secs min * 60 secs hr
                    break
                }
                #if FUNCTIONDBG
                DBGLog(" timefn: %f final units", result)
                #endif
            } else {
                // remaining option is we have some vid as currTok, return its value up the chain
                let lvo = to?.getValObj(currTok)
                result = Double(lvo?.value ?? "") ?? 0.0
                #if FUNCTIONDBG
                DBGLog("vid %ld: result= %f", Int(lvo?.vid ?? 0), result)
                #endif
                //result = [[to getValObj:currTok].value doubleValue];
                //self.currFnNdx++;  // on to next  // already there - postinc on read
            }
        }
        currFnNdx += 1

        #if FUNCTIONDBG
        DBGLog("%@ calcFnValueWithCurrent rtn: %@", vo?.valueName, NSNumber(value: result))
        #endif
        return NSNumber(value: result)

    }

    func checkEP(_ ep: Int) -> Bool {
        let epstr = "frep\(ep)"
        let epval = (vo?.optDict?[epstr] as? NSNumber)?.intValue ?? 0
        if epval >= 0 {
            // if epval is a valueObj
            let valo = MyTracker?.getValObj(epval)
            if valo == nil || valo?.value == nil || (valo?.value == "") || (valo?.vtype == VOT_BOOLEAN && (valo?.value != "1")) {
                return false
            }
        }
        return true
    }

    //- (NSString*) currFunctionValue {
    override func update(_ instr: String?) -> String? {
        var instr = instr
        instr = ""
        let pto = vo?.parentTracker as? trackerObj

        if nil == pto?.tDb {
            return ""
        }

        if !checkEP(1) {
            return instr
        }


        // search back for start endpoint that is ok
        let ep0start = Int(MyTracker?.trackerDate?.timeIntervalSince1970 ?? 0)
        let ep0date = getEpDate(0, maxdate: ep0start) // start with immed prev to curr record set
        /*
            if (ep0date != 0) {
                [MyTracker loadData:ep0date];   // set values for initial checkEP test
                while((ep0date != 0) && (![self checkEP:0])) {
                    ep0date = [self getEpDate:0 maxdate:ep0date];  // not ok, back one more
                    [MyTracker loadData:ep0date];
                }
                [MyTracker loadData:ep0start];   // reset from search
            }
          */

        if ep0date == 0 {
            // start endpoint not ok
            let nep = (vo?.optDict)?["frep0"] as? NSNumber
            let ep = nep?.intValue ?? 0
            if !(nep == nil || ep == FREPENTRY) {
                // allow to go through if just looking for previous entry and this is first
                return instr
            }
        }

        currFnNdx = 0

        let val = calcFunctionValue(withCurrent: ep0date)
        #if FUNCTIONDBG
        DBGLog("fn update val= %@", val)
        #endif
        if let val {
            let nddp = (vo?.optDict)?["fnddp"] as? NSNumber
            let ddp = nddp == nil ? FDDPDFLT : nddp?.intValue ?? 0
            return String(format: String(format: "%%0.%df", ddp), val.floatValue)
        }
        #if FUNCTIONDBG
        DBGLog("fn update returning: %@", instr)
        #endif
        return instr
    }

    override func voDisplay(_ bounds: CGRect) -> UIView? {

        //trackerObj *to = (trackerObj*) parentTracker;
        vosFrame = bounds

        //UILabel *rlab = [[UILabel alloc] initWithFrame:bounds];
        //rlab.textAlignment = UITextAlignmentRight;

        #if FABRIC
        CrashlyticsKit.setObjectValue(voFnDefnStr(true), forKey: "fnDefn")
        CrashlyticsKit.setObjectValue(voRangeStr(true), forKey: "fnRange")
        #endif

        var valstr = vo?.value // evaluated on read so make copy
        if FnErr {
            valstr = "❌ " + (valstr ?? "")
        }
        if valstr != "" {
            rlab?.backgroundColor = .clear // was whiteColor
            rlab?.text = valstr
        } else {
            rlab?.backgroundColor = .lightGray
            rlab?.text = "-"
        }

        //return [rlab autorelease];
        DBGLog("fn voDisplay: %@", rlab?.text)
        //self.rlab.tag = kViewTag;
        return rlab
    }

    override func voGraphSet() -> [AnyHashable]? {
        return voState.voGraphSetNum()
    }

    // MARK: -
    // MARK: function configTVObjVC
    // MARK: -

    // MARK: range definition page

    //
    // convert endpoint from left or right picker to rownum for offset symbol (hours, months, ...) or valobj
    //

    // ep options are : 
    //     row 0:      entry 
    //     rows 1..m:  [valObjs] (ep = vid)
    //     rows n...:  other epTitles entries

    func ep(toRow component: Int) -> Int {
        let key = String(format: "frep%ld", component)
        let n = (vo?.optDict)?[key] as? NSNumber
        let ep = n?.intValue ?? 0
        DBGLog("comp= %ld ep= %ld n= %@ ", component, ep, n)
        if n == nil || ep == FREPDFLT {
            // no endpoint defined, so default row 0
            DBGLog(" returning 0")
            return 0
        }
        if ep >= 0 || ep <= -TMPUNIQSTART {
            // ep defined and saved, or ep not saved and has tmp vid, so return ndx in vo table
            //return [MyTracker.valObjTable indexOfObjectIdenticalTo:[MyTracker getValObj:ep]] +1;
            if let getValObj = MyTracker?.getValObj(ep) {
                DBGLog(" returning %lu", UInt(((votWoSelf as NSArray?)?.indexOfObjectIdentical(to: getValObj) ?? 0) + 1))
                return ((votWoSelf as NSArray?)?.indexOfObjectIdentical(to: getValObj) ?? 0) + 1
            }
            return 0
            //return ep+1;
        }
        DBGLog(" returning %lu", UInt((ep * -1) + (votWoSelf?.count ?? 0) - 1))
        return (ep * -1) + (votWoSelf?.count ?? 0) - 1 // ep is offset into hours, months list
        //return (ep * -1) + [MyTracker.valObjTable count] -1;  // ep is offset into hours, months list
    }

    func fnrRowTitle(_ row: Int) -> String? {
        var row = row
        if row != 0 {
            let votc = votWoSelf?.count ?? 0 //[MyTracker.valObjTable count];
            if row <= votc {
                DBGLog(" returning %@", (votWoSelf?[row - 1] as? valueObj)?.valueName)
                return ((votWoSelf)?[row - 1] as? valueObj)?.valueName //((valueObj*) [MyTracker.valObjTable objectAtIndex:row-1]).valueName;
            } else {
                row -= votc
            }
        }
        DBGLog(" returning %@", epTitles?[row])
        return (epTitles)?[row] as? String
    }

    // 
    // if picker row is offset (not valobj), display a textfield and label to get number of (hours, months,...) offset
    // check 
    //

    func updateValTF(_ row: Int, component: Int) {
        let votc = votWoSelf?.count ?? 0 //[MyTracker.valObjTable count];

        if row > votc {
            let vkey = String(format: "frv%ld", component)
            let key = String(format: "frep%ld", component)
            if FREPNONE == ((vo?.optDict)?[key] as? NSNumber)?.intValue ?? 0 {
                return
            }
            let vtfkey = String(format: "fr%ldTF", component)
            let pre_vkey = String(format: "frpre%ldvLab", component)
            let post_vkey = String(format: "frpost%ldvLab", component)

            let vtf = (ctvovcp?.wDict)?[vtfkey] as? UITextField
            vtf?.text = (vo?.optDict)?[vkey] as? String
            if let vtf {
                ctvovcp?.scroll.addSubview(vtf)
            }
            if let aWDict = (ctvovcp?.wDict)?[pre_vkey] as? UIView {
                ctvovcp?.scroll.addSubview(aWDict)
            }
            let postLab = (ctvovcp?.wDict)?[post_vkey] as? UILabel
            //postLab.text = [[self fnrRowTitle:row] stringByReplacingOccurrencesOfString:@"cal " withString:@"c "];
            postLab?.text = fnrRowTitle(row)
            DBGLog(" postlab= %@", postLab?.text)
            if let postLab {
                ctvovcp?.scroll.addSubview(postLab)
            }

            if (0 == component) && (ISCALFREP(((vo?.optDict)?[key] as? NSNumber)?.intValue ?? 0)) {
                let ckBtn = (ctvovcp?.wDict)?["graphLastBtn"] as? UIButton
                let state = !((vo?.optDict)?["graphlast"] == "0") // default:1
                ckBtn?.setImage(
                    UIImage(named: state ? "checked.png" : "unchecked.png"),
                    for: .normal)
                if let ckBtn {
                    ctvovcp?.scroll.addSubview(ckBtn)
                }
                let glLab = (ctvovcp?.wDict)?["graphLastLabel"] as? UILabel
                if let glLab {
                    ctvovcp?.scroll.addSubview(glLab)
                }
            }
        }
    }

    func drawFuncOptsRange() {
        var frame = CGRect(x: MARGIN, y: ctvovcp?.lasty ?? 0.0, width: 0.0, height: 0.0)

        var labframe = ctvovcp?.configLabel(
            "Function range endpoints:",
            frame: frame,
            key: "freLab",
            addsv: true)
        frame.origin.x = MARGIN
        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN

        //labframe =
        ctvovcp?.configLabel(
            "Previous:",
            frame: frame,
            key: "frpLab",
            addsv: true)
        frame.origin.x = ((ctvovcp?.view.frame.size.width ?? 0.0) / 2.0) + MARGIN

        labframe = ctvovcp?.configLabel(
            "Current:",
            frame: frame,
            key: "frcLab",
            addsv: true)

        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN
        frame.origin.x = 0.0

        frame = ctvovcp?.configPicker(frame, key: "frPkr", caller: self) ?? CGRect.zero
        let pkr = (ctvovcp?.wDict)?["frPkr"] as? UIPickerView

        DBGLog("pkr component 0 selectRow %ld", ep(toRow: 0))
        pkr?.selectRow(ep(toRow: 0), inComponent: 0, animated: false)
        DBGLog("pkr component 1 selectRow %ld", ep(toRow: 1))
        pkr?.selectRow(ep(toRow: 1), inComponent: 1, animated: false)

        frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN

        labframe = ctvovcp?.configLabel(
            "-",
            frame: frame,
            key: "frpre0vLab",
            addsv: false)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        let tfWidth = "9999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovcp?.lfHeight ?? 0.0

        ctvovcp?.configTextField(
            frame,
            key: "fr0TF",
            target: nil,
            action: nil,
            num: true,
            place: nil,
            text: (vo?.optDict)?["frv0"] as? String,
            addsv: false)

        frame.origin.x += tfWidth + 2 * SPACE
        //labframe =
        ctvovcp?.configLabel(
            "cal months",
            frame: frame,
            key: "frpost0vLab",
            addsv: false)

        //[self updateValTF:[self epToRow:0] component:0];

        frame.origin.x = ((ctvovcp?.view.frame.size.width ?? 0.0) / 2.0) + MARGIN

        labframe = ctvovcp?.configLabel(
            "only last:",
            frame: frame,
            key: "graphLastLabel",
            addsv: false)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        ctvovcp?.configCheckButton(
            frame,
            key: "graphLastBtn",
            state: !((vo?.optDict)?["graphlast"] == "0"),
            addsv: false)

        updateValTF(ep(toRow: 0), component: 0)

        /*
        	labframe = [self.ctvovcp configLabel:@"+" 
        						   frame:frame
        							 key:@"frpre1vLab" 
        						   addsv:NO ];

        	frame.origin.x += labframe.size.width + SPACE;
        	[self.ctvovcp configTextField:frame 
        					  key:@"fr1TF" 
        				   target:nil
        				   action:nil
        					  num:YES 
        					place:nil
        					 text:[self.vo.optDict objectForKey:@"frv1"] 
        					addsv:NO ];

        	frame.origin.x += tfWidth + 2*SPACE;
        	/ *labframe =* / [self.ctvovcp configLabel:@"cal months"
        							   frame:frame
        								 key:@"frpost1vLab" 
        							   addsv:NO ];
        	[self updateValTF:[self epToRow:1] component:1];
        	*/


    }

    // MARK: -
    // MARK: function definition page

    //
    // generate text to describe function as specified by symbols,vids in fnArray from 
    //  strings in fnStrs or valueObj names
    //

    func reloadEmptyFnArray() {
        if 0 == (fnArray?.count ?? 0) {
            // one last try if nothing there
            loadConfig()
        }
    }

    func voFnDefnStr(_ dbg: Bool) -> String? {
        var fstr = ""
        var closePending = false //square brackets around target of Fn1Arg
        var constantPending = false // next item is a number not tok or vid
        var constantClosePending = false // constant bounded on both sides by constant token
        var arg2Pending = false // looking for second argument
        let openParenCount = 0

        for n in fnArray ?? [] {
            guard let n = n as? NSNumber else {
                continue
            }
            let i = n.intValue
            //DBGLog(@"loop start: closePend=%d constantPend=%d constantClosePend=%d arg2Pend=%d openParen=%d fstr=%@",closePending,constantPending,constantClosePending,arg2Pending, openParenCount, fstr);
            if constantPending {
                fstr += n.stringValue
                constantPending = false
                constantClosePending = true
            } else if isFn(i) {
                if isFn2ArgOp(i) {
                    arg2Pending = true
                } else {
                    arg2Pending = false
                }
                if FNCONSTANT == i {
                    if constantClosePending {
                        constantClosePending = false
                    } else {
                        constantPending = true
                    }
                } else {
                    //NSInteger ndx = (i * -1) -1;
                    //[fstr appendString:[self.fnStrs objectAtIndex:ndx]];  xxx   // get str for token
                    fstr += (fnStrDict)?[NSNumber(value: i)] as? String ?? ""
                    if isFn1Arg(i) {
                        fstr += "["
                        closePending = true
                    }
                    if FNPARENOPEN == i {
                        openParenCount += 1
                    } else if FNPARENCLOSE == i {
                        openParenCount -= 1
                    }
                }
            } else {
                if dbg {
                    let vt = MyTracker?.voGetType(forVID: i) ?? 0
                    if 0 > vt {
                        fstr += "noType"
                    } else {
                        fstr += rTracker_resource.vtypeNames()?[vt] as? String ?? ""
                    }
                } else {
                    fstr += MyTracker?.voGetName(forVID: i) ?? "" // could get from self.fnStrs
                }
                if closePending {
                    fstr += "]"
                    closePending = false
                }
                arg2Pending = false
            }
            if !closePending {
                fstr += " "
            }
            DBGLog("loop end: closeP=%d constantP=%d constantCloseP=%d arg2P=%d openPC=%d fstr=%@", closePending, constantPending, constantClosePending, arg2Pending, openParenCount, fstr)
        }
        if arg2Pending || closePending || constantPending || constantClosePending || openParenCount != 0 {
            fstr += " ❌"
            FnErr = true
        } else {
            FnErr = false
        }
        DBGLog("final fstr: %@", fstr)
        return fstr
    }

    func updateFnTV() {
        let ftv = (ctvovcp?.wDict)?["fdefnTV2"] as? UITextView
        ftv?.text = voFnDefnStr(false)
    }

    @objc func btnAdd(_ sender: Any?) {
        if 0 >= (fnTitles?.count ?? 0) {
            noVarsAlert()
            return
        }

        let pkr = (ctvovcp?.wDict)?["fdPkr"] as? UIPickerView
        let row = pkr?.selectedRow(inComponent: 0) ?? 0
        let ntok = (fnTitles)?[row] as? NSNumber // get tok from fnTitle and add to fnArray
        if let ntok {
            fnArray?.append(ntok)
        }
        if FNCONSTANT == ntok?.intValue ?? 0 {
            // constant has const_tok on both sides to help removal
            let vtf = (ctvovcp?.wDict)?[CTFKEY] as? UITextField
            fnArray?.append(NSNumber(value: Double(vtf?.text ?? "") ?? 0.0))
            if let ntok {
                fnArray?.append(ntok)
            }
            ctvovcp?.tfDone(vtf)
        }
        updateFnTitles()
        pkr?.reloadComponent(0)
        updateFnTV()
    }

    @objc func btnDelete(_ sender: Any?) {
        // i= constTok remove token and value  -- done
        //  also [self.tempValObj.optDict removeObjectForKey:@"fdc"]; -- can't be sure with mult consts
        let pkr = (ctvovcp?.wDict)?["fdPkr"] as? UIPickerView
        if 0 < (fnArray?.count ?? 0) {
            if FNCONSTANT == (fnArray?.last as? NSNumber)?.intValue ?? 0 {
                fnArray?.removeLast() // remove bounding token after
                fnArray?.removeLast() // remove constant value
            }
            fnArray?.removeLast()
        }
        updateFnTitles()
        pkr?.reloadComponent(0)
        updateFnTV()
    }

    func drawFuncOptsDefinition() {
        updateFnTitles()

        var frame = CGRect(x: MARGIN, y: ctvovcp?.lasty ?? 0.0, width: 0.0, height: 0.0)

        var labframe = ctvovcp?.configLabel(
            "Function definition:",
            frame: frame,
            key: "fdLab",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + (labframe?.size.height ?? 0.0)
        frame.size.width = (ctvovcp?.view.frame.size.width ?? 0.0) - 2 * MARGIN // 300.0f;
        frame.size.height = 2 * (ctvovcp?.lfHeight ?? 0.0)

        let maxDim = rTracker_resource.getScreenMaxDim()
        if maxDim > 480 {
            if maxDim <= 568 {
                // iphone 5
                frame.size.height = 4 * (ctvovcp?.lfHeight ?? 0.0)
            } else if maxDim <= 736 {
                // iphone 6, 6+
                frame.size.height = 6 * (ctvovcp?.lfHeight ?? 0.0)
            } else {
                frame.size.height = 8 * (ctvovcp?.lfHeight ?? 0.0)
            }
        }
        ctvovcp?.configTextView(frame, key: "fdefnTV2", text: voFnDefnStr(false))

        frame.origin.x = 0.0
        frame.origin.y += frame.size.height + MARGIN

        frame = ctvovcp?.configPicker(frame, key: "fdPkr", caller: self) ?? CGRect.zero
        //UIPickerView *pkr = [self.ctvovcp.wDict objectForKey:@"fdPkr"];

        //[pkr selectRow:[self epToRow:0] inComponent:0 animated:NO];
        //[pkr selectRow:[self epToRow:1] inComponent:1 animated:NO];

        frame.origin.y += frame.size.height //+ MARGIN;
        //frame.origin.x = MARGIN;
        frame.size.height = labframe?.size.height ?? 0.0
        //
        frame.origin.x = "Add".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width + 3 * MARGIN
        //frame.origin.y += frame.size.height + MARGIN;
        labframe = ctvovcp?.configLabel(
            "Constant value:",
            frame: frame,
            key: CLKEY,
            addsv: false)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        let tfWidth = "9999.99".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovcp?.lfHeight ?? 0.0

        ctvovcp?.configTextField(
            frame,
            key: "fdcTF",
            target: nil,
            action: nil,
            num: true,
            place: nil,
            text: nil,
            addsv: false)

        frame.origin.x = MARGIN
        frame.origin.y -= 3 * MARGIN // I DO NOT UNDERSTAND THIS!!!!!

        ctvovcp?.configActionBtn(frame, key: "fdaBtn", label: "Add", target: self, action: #selector(btnAdd(_:)))
        frame.origin.x = -1.0
        ctvovcp?.configActionBtn(frame, key: "fddBtn", label: "Delete", target: self, action: #selector(btnDelete(_:)))

    }

    // MARK: -
    // MARK: function overview page

    //
    // nice text string to describe a specified range endpoint
    //

    func voEpStr(_ component: Int, dbg: Bool) -> String? {
        let key = String(format: "frep%ld", component)
        let vkey = String(format: "frv%ld", component)
        let pre = component != 0 ? "current" : "previous"

        let n = (vo?.optDict)?[key] as? NSNumber
        let ep = n?.intValue ?? 0
        let ep2 = n != nil ? (ep + 1) * -1 : 0 // invalid if ep is tmpUniq (negative)

        if nil == n || FREPDFLT == ep || FREPNONE == ep {
            if let anEpTitles = (epTitles)?[ep2] {
                return "\(pre) \(anEpTitles)" // FREPDFLT
            }
            return nil
        }

        if ep >= 0 || ep <= -TMPUNIQSTART {
            // endpoint is vid and valobj saved, or tmp vid as valobj not saved
            if dbg {
                if let vtypeNames = rTracker_resource.vtypeNames()?[(MyTracker?.getValObj(ep))?.vtype ?? 0] {
                    return "\(pre) \(vtypeNames)"
                }
                return nil
            } else {
                return "\(pre) \((MyTracker?.getValObj(ep))?.valueName ?? "")"
            }
        }

        // ep is hours / days / months entry
        if let anEpTitles = (epTitles)?[ep2] {
            return "\(component != 0 ? "+" : "-")\(((vo?.optDict)?[vkey] as? NSNumber)?.intValue ?? 0) \(anEpTitles)"
        }
        return nil

    }

    func voRangeStr(_ dbg: Bool) -> String? {
        return "\(voEpStr(0, dbg: dbg) ?? "") to \(voEpStr(1, dbg: dbg) ?? "")"
    }

    func drawFuncOptsOverview() {

        var frame = CGRect(x: MARGIN, y: ctvovcp?.lasty ?? 0.0, width: 0.0, height: 0.0)
        var labframe = ctvovcp?.configLabel(
            "Range:",
            frame: frame,
            key: "frLab",
            addsv: true)

        //frame = (CGRect) {-1.0f, frame.origin.y, 0.0f,labframe.size.height};
        //[self configActionBtn:frame key:@"frbBtn" label:@"Build" action:@selector(btnBuild:)]; 
        let screenSize = UIScreen.main.bounds.size

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + (labframe?.size.height ?? 0.0)
        frame.size.width = screenSize.width - 2 * MARGIN // seems always wrong on initial load // self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
        frame.size.height = ctvovcp?.lfHeight ?? 0.0

        ctvovcp?.configTextView(frame, key: "frangeTV", text: voRangeStr(false))

        frame.origin.y += frame.size.height + MARGIN
        labframe = ctvovcp?.configLabel(
            "Definition:",
            frame: frame,
            key: "fdLab",
            addsv: true)

        frame = CGRect(x: -1.0, y: frame.origin.y, width: 0.0, height: labframe?.size.height ?? 0.0)
        //[self configActionBtn:frame key:@"fdbBtn" label:@"Build" action:@selector(btnBuild:)]; 

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        frame.size.width = screenSize.width - 2 * MARGIN // self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
        frame.size.height = 2 * (ctvovcp?.lfHeight ?? 0.0)

        let maxDim = rTracker_resource.getScreenMaxDim()
        if maxDim > 480 {
            if maxDim <= 568 {
                // iphone 5
                frame.size.height = 3 * (ctvovcp?.lfHeight ?? 0.0)
            } else if maxDim <= 736 {
                // iphone 6, 6+
                frame.size.height = 4 * (ctvovcp?.lfHeight ?? 0.0)
            } else {
                frame.size.height = 6 * (ctvovcp?.lfHeight ?? 0.0)
            }
        }

        ctvovcp?.configTextView(frame, key: "fdefnTV", text: voFnDefnStr(false))

        frame.origin.y += frame.size.height + MARGIN

        labframe = ctvovcp?.configLabel("Display result decimal places:", frame: frame, key: "fnddpLab", addsv: true)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        let tfWidth = "999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovcp?.lfHeight ?? 0.0 // self.labelField.frame.size.height; // lab.frame.size.height;

        ctvovcp?.configTextField(
            frame,
            key: "fnddpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(FDDPDFLT)",
            text: (vo?.optDict)?["fnddp"] as? String,
            addsv: true)


        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + (labframe?.size.height ?? 0.0)

        frame = ctvovcp?.yAutoscale(frame) ?? CGRect.zero

        //frame.origin.y += frame.size.height + MARGIN;
        //frame.origin.x = MARGIN;

        ctvovcp?.lasty = frame.origin.y + frame.size.height + MARGIN
    }

    // MARK: -
    // MARK: configTVObjVC general support

    //
    // called for btnDone in configTVObjVC
    //

    func funcDone() -> Bool {
        if FnErr {
            return false
        }
        if fnArray != nil && (fnArray?.count ?? 0) != 0 {
            //DBGLog(@"funcDone 0: %@",[self.vo.optDict objectForKey:@"func"]);
            saveFnArray()
            DBGLog("funcDone 1: %@", vo?.optDict?["func"])

            // frep0 and 1 not set if user did not click on range picker
            if (vo?.optDict)?["frep0"] == nil {
                (vo?.optDict)?["frep0"] = NSNumber(value: FREPDFLT)
            }
            if (vo?.optDict)?["frep1"] == nil {
                (vo?.optDict)?["frep1"] = NSNumber(value: FREPDFLT)
            }

            DBGLog("ep0= %@  ep1=%@", vo?.optDict?["frep0"], vo?.optDict?["frep1"])
        }
        return true
    }

    @objc func btnHelp() {
        switch fnSegNdx {
        case FNSEGNDX_OVERVIEW:
            if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/addFunction.html#overview") {
                UIApplication.shared.open(url, options: [:])
            }
        case FNSEGNDX_RANGEBLD:
            if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/addFunction.html#range") {
                UIApplication.shared.open(url, options: [:])
            }
        case FNSEGNDX_FUNCTBLD:
            if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/addFunction.html#operators") {
                UIApplication.shared.open(url, options: [:])
            }
        default:
            dbgNSAssert(0, "fnSegmentAction bad index!")
        }




    }

    //
    // called for configTVObjVC  viewDidLoad
    //
    func funcVDL(_ ctvovc: configTVObjVC?, donebutton db: UIBarButtonItem?) {

        if ((vo?.parentTracker as? trackerObj)?.valObjTable?.count ?? 0) > 0 {

            let flexibleSpaceButtonItem = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)

            let segmentTextContent = ["Overview", "Range", "Definition"]

            let segmentedControl = UISegmentedControl(items: segmentTextContent)
            //[segmentTextContent release];

            segmentedControl.addTarget(self, action: #selector(fnSegmentAction(_:)), for: .valueChanged)
            //segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
            segmentedControl.selectedSegmentIndex = fnSegNdx //= 0;
            let scButtonItem = UIBarButtonItem(
                customView: segmentedControl)
            let fnHelpButtonItem = UIBarButtonItem(title: "Help", style: .plain, target: self, action: #selector(RootViewController.btnHelp))

            ctvovc?.toolBar.items = [
                db,
                flexibleSpaceButtonItem,
                scButtonItem,
                flexibleSpaceButtonItem,
                fnHelpButtonItem,
                flexibleSpaceButtonItem
            ].compactMap { $0 }
        } else {
            ctvovc?.toolBar.items = [db].compactMap { $0 }
        }

    }

    func drawSelectedPage() {
        ctvovcp?.lasty = 2 //frame.origin.y + frame.size.height + MARGIN;
        switch fnSegNdx {
        case FNSEGNDX_OVERVIEW:
            drawFuncOptsOverview()
            super.voDrawOptions(ctvovcp)
        case FNSEGNDX_RANGEBLD:
            drawFuncOptsRange()
        case FNSEGNDX_FUNCTBLD:
            drawFuncOptsDefinition()
        default:
            dbgNSAssert(0, "fnSegmentAction bad index!")
        }
    }

    @objc func fnSegmentAction(_ sender: Any?) {
        fnSegNdx = sender?.selectedSegmentIndex ?? 0
        //DBGLog(@"fnSegmentAction: selected segment = %d", self.fnSegNdx);

        //[UIView beginAnimations:nil context:NULL];
        //[UIView setAnimationBeginsFromCurrentState:YES];
        //[UIView setAnimationDuration:kAnimationDuration];
        UIView.animate(withDuration: 0.2, animations: { [self] in
            ctvovcp?.removeSVFields()
            drawSelectedPage()
        })
        //[UIView commitAnimations];
    }

    // MARK: protocol: voDrawOptions page

    override func setOptDictDflts() {
        if nil == (vo?.optDict)?["frep0"] {
            (vo?.optDict)?["frep0"] = "\(FREPDFLT)"
        }
        if nil == (vo?.optDict)?["frep1"] {
            (vo?.optDict)?["frep1"] = "\(FREPDFLT)"
        }
        if nil == (vo?.optDict)?["fnddp"] {
            (vo?.optDict)?["fnddp"] = "\(FDDPDFLT)"
        }
        if nil == (vo?.optDict)?["func"] {
            (vo?.optDict)?["func"] = ""
        }
        if nil == (vo?.optDict)?["autoscale"] {
            (vo?.optDict)?["autoscale"] = AUTOSCALEDFLT ? "1" : "0"
        }
        if nil == (vo?.optDict)?["graphlast"] {
            (vo?.optDict)?["graphlast"] = GRAPHLASTDFLT ? "1" : "0"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String?) -> Bool {

        let val = (vo?.optDict)?[key ?? ""] as? String
        if nil == val {
            return true
        }

        if ((key == "frep0") && (Int(val ?? "") ?? 0 == FREPDFLT)) || ((key == "frep1") && (Int(val ?? "") ?? 0 == FREPDFLT)) || ((key == "fnddp") && (Int(val ?? "") ?? 0 == FDDPDFLT)) || ((key == "func") && (val == "")) || ((key == "autoscale") && (val == AUTOSCALEDFLT ? "1" : "0")) || ((key == "graphlast") && (val == GRAPHLASTDFLT ? "1" : "0")) {
            vo?.optDict?.removeValue(forKey: key)
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    func checkVOs() -> Bool {
        for valo in MyTracker?.valObjTable ?? [] {
            guard let valo = valo as? valueObj else {
                continue
            }
            if valo.vtype != VOT_FUNC {
                return true
            }
        }
        return false
    }

    func noVarsAlert() {
        rTracker_resource.alert("No variables for function", msg: "A function needs variables to work on.\n\nPlease add a value (like a number, or anything other than a function) to your tracker before trying to create a function.", vc: nil)
    }

    // MARK: -


    override func voDrawOptions(_ ctvovc: configTVObjVC?) {
        ctvovcp = ctvovc
        reloadEmptyFnArray()
        drawSelectedPage()

        if !checkVOs() {
            noVarsAlert()
        }

    }

    // MARK: -


    // MARK: picker support

    //
    // build list of titles for symbols,operations available for current point in fn definition string
    //

    func ftAddFnSet() {
        var i: Int
        //for (i=FN1ARGFIRST;i>=FN1ARGLAST;i--) {
        //	[self.fnTitles addObject:[NSNumber numberWithInt:i]];   xxx // add nsnumber token, enumerated by fn class
        //}
        for i in 0..<ARG1CNT {
            if let aFn1args = (fn1args)?[i] {
                fnTitles?.append(aFn1args)
            }
        }
        fnTitles?.append(String(utf8String: FNCONSTANT) ?? "")
    }

    func ftAddTimeSet() {
        var i: Int
        for i in 0..<TIMECNT {
            if let aFnTimeOps = (fnTimeOps)?[i] {
                fnTitles?.append(aFnTimeOps)
            }
        }
        //for (i=FNTIMEFIRST;i>=FNTIMELAST;i--) {
        //	[self.fnTitles addObject:[NSNumber numberWithInt:i]];   xxx
        //}
    }

    func ftAdd2OpSet() {
        var i: Int
        for i in 0..<ARG2CNT {
            if let aFn2args = (fn2args)?[i] {
                fnTitles?.append(aFn2args)
            }
        }
        //for (i=FN2ARGFIRST;i>=FN2ARGLAST;i--) {
        //	[self.fnTitles addObject:[NSNumber numberWithInt:i]];  xxx
        //}
    }

    func ftAddVOs() {
        for valo in MyTracker?.valObjTable ?? [] {
            guard let valo = valo as? valueObj else {
                continue
            }
            if valo != vo {
                fnTitles?.append(NSNumber(value: valo.vid))
            }
        }
    }

    func ftAddCloseParen() {
        let pcount = 0
        for ni in fnArray ?? [] {
            guard let ni = ni as? NSNumber else {
                continue
            }
            let i = ni.intValue
            if i == FNPARENOPEN {
                pcount += 1
            } else if i == FNPARENCLOSE {
                pcount -= 1
            }
        }
        if pcount > 0 {
            fnTitles?.append(String(utf8String: FNPARENCLOSE) ?? "")
        }
    }

    func ftStartSet() {
        ftAddFnSet()
        ftAddTimeSet()
        fnTitles?.append(String(utf8String: FNPARENOPEN) ?? "")
        ftAddVOs()
    }

    func updateFnTitles() {
        // create array fnTitles of nsnumber tokens which should be presented in picker for current last of fn being built
        fnTitles?.removeAll()
        hideConstTF()
        DBGLog("fnArray= %@", fnArray)
        if (fnArray?.count ?? 0) == 0 {
            // state = start
            ftStartSet()
        } else {
            let last = (fnArray?.last as? NSNumber)?.intValue ?? 0
            if last >= 0 || last <= -TMPUNIQSTART || isFnTimeOp(last) || FNCONSTANT == last {
                // state = after valObj
                ftAdd2OpSet()
                ftAddCloseParen()
            } else if isFn1Arg(last) {
                // state = after Fn1 = delta, avg, sum
                ftAddVOs()
            } else if isFn2ArgOp(last) {
                // state = after fn2op = +,-,*,/
                ftStartSet()
            } else if last == FNPARENCLOSE {
                // state = after close paren
                ftAdd2OpSet()
                ftAddCloseParen()
            } else if last == FNPARENOPEN {
                // state = after open paren
                ftStartSet()
            } else {
                dbgNSAssert(0, "lost it at updateFnTitles")
            }
        }
    }

    func fnToken(toStr tok: Int) -> String? {
        // convert token to str
        if isFn(tok) {
            return (fnStrDict)?[NSNumber(value: tok)] as? String
            //tok = (tok * -1) -1;
            //return [self.fnStrs objectAtIndex:tok];
        } else {
            for valo in MyTracker?.valObjTable ?? [] {
                guard let valo = valo as? valueObj else {
                    continue
                }
                if valo.vid == tok {
                    return valo.valueName
                }
            }
            dbgNSAssert(0, "fnTokenToStr failed to find valObj")
            return "unknown vid"
        }
    }

    func fndRowTitle(_ row: Int) -> String? {
        return fnToken(toStr: ((fnTitles)?[row] as? NSNumber)?.intValue ?? 0) // get nsnumber(tok) from fnTitles, convert to int, convert to str to be placed in specified picker rox
    }

    func fnrRowCount(_ component: Int) -> Int {
        /*
        	NSInteger other = (component ? 0 : 1);
        	NSString *otherKey = [NSString stringWithFormat:@"frep%d",other];
        	id otherObj = [self.vo.optDict objectForKey:otherKey];
        	NSInteger otherVal = [otherObj integerValue];
        	if (otherVal < -1) {
         */        // only allow time offset for previous side of range
        if component == 1 {
            DBGLog(" returning %lu", UInt((votWoSelf?.count ?? 0) + 1))
            return (votWoSelf?.count ?? 0) + 1 // [MyTracker.valObjTable count]+1;  // count all +1 for 'current entry'
        } else {
            DBGLog(" returning %lu", UInt((votWoSelf?.count ?? 0) + MAXFREP))
            return (votWoSelf?.count ?? 0) + MAXFREP //[MyTracker.valObjTable count] + MAXFREP;
        }
    }

    func numberOfComponents(in pickerView: UIPickerView?) -> Int {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return 2
        } else {
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return fnrRowCount(component)
        } else {
            return fnTitles?.count ?? 0
        }
    }

    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return fnrRowTitle(row)
        } else {
            // FNSEGNDX_FUNCTBLD
            return fndRowTitle(row)
        }
        //return [NSString stringWithFormat:@"row %d", row];
    }

    func update(forPickerRowSelect row: Int, inComponent component: Int) {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            ((ctvovcp?.wDict)?["frPkr"] as? UIPickerView)?.reloadComponent(component != 0 ? 0 : 1)
            //else {
        }
        //[((UIPickerView*) [self.wDict objectForKey:@"fnPkr"]) reloadComponent:0];
        //}
    }

    func showConstTF() {
        // display constant box
        let vtf = (ctvovcp?.wDict)?[CTFKEY] as? UITextField
        vtf?.text = (vo?.optDict)?[LCKEY] as? String
        if let aWDict = (ctvovcp?.wDict)?[CLKEY] as? UIView {
            ctvovcp?.scroll.addSubview(aWDict)
        }
        if let vtf {
            ctvovcp?.scroll.addSubview(vtf)
        }
    }

    func hideConstTF() {
        // hide constant box
        ((ctvovcp?.wDict)?[CTFKEY] as? UIView)?.removeFromSuperview()
        ((ctvovcp?.wDict)?[CLKEY] as? UIView)?.removeFromSuperview()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            let votc = votWoSelf?.count ?? 0 //[MyTracker.valObjTable count];

            let key = String(format: "frep%ld", component)
            let vtfkey = String(format: "fr%ldTF", component)
            let pre_vkey = String(format: "frpre%ldvLab", component)
            let post_vkey = String(format: "frpost%ldvLab", component)

            ((ctvovcp?.wDict)?[pre_vkey] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?[vtfkey] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?[post_vkey] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?["graphLastBtn"] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?["graphLastLabel"] as? UIView)?.removeFromSuperview()

            if row == 0 {
                (vo?.optDict)?[key] = NSNumber(value: -1)
            } else if row <= votc {
                (vo?.optDict)?[key] = NSNumber(value: ((votWoSelf)?[row - 1] as? valueObj)?.vid ?? 0)
            } else {
                (vo?.optDict)?[key] = NSNumber(value: ((row - votc) + 1) * -1)
                updateValTF(row, component: component)
            }
            DBGLog("picker sel row %ld %@ now= %ld", row, key, (vo?.optDict?[key] as? NSNumber)?.intValue ?? 0)
        } else if fnSegNdx == FNSEGNDX_FUNCTBLD {
            //DBGLog(@"fn build row %d= %@",row,[self fndRowTitle:row]);
            if FNCONSTANT_TITLE == fndRowTitle(row) {
                showConstTF()
            } else {
                hideConstTF()
            }
        }

        update(forPickerRowSelect: row, inComponent: component)

    }

    // MARK: -
    // MARK: fn value results for graphing

    func trimFnVals(_ frep0: Int) {
        DBGLog("ep= %ld", frep0)
        var sql: String?

        var ival = ((vo?.optDict)?["frv0"] as? NSNumber)?.intValue ?? 0 * -1 // negative offset if ep0
        let gregorian = Calendar(identifier: .gregorian)
        let offsetComponents = DateComponents()

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
            dbgNSAssert1(0, "trimFnVals: failed to identify ep %ld", frep0)
        }

        var epDate = -1

        sql = String(format: "select date from voData where id = %ld order by date desc", Int(vo?.vid ?? 0))
        var dates: [AnyHashable] = []
        MyTracker?.toQry2AryI(&dates, sql: sql)
        for d in dates {
            guard let d = d as? NSNumber else {
                continue
            }
            var targ = gregorian?.date(
                byAdding: offsetComponents,
                to: Date(timeIntervalSince1970: TimeInterval(d.intValue)),
                options: [])

            var unitFlags: UInt = 0

            switch frep0 {
            // if calendar week, we need to get to beginning of week as per calendar
            case FREPCWEEKS:
                var beginOfWeek: Date? = nil
                //BOOL rslt = [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginOfWeek interval:NULL forDate: targ];
                var rslt = false
                if let targ {
                    rslt = gregorian?.range(of: .weekOfYear, start: &beginOfWeek, interval: nil, for: targ) ?? false
                }
                if rslt {
                    targ = beginOfWeek
                }
            // if any of week, day, month, year we need to wipe hour, minute, second components
            case FREPCDAYS:
                unitFlags |= NSCalendar.Unit.day.rawValue
            case FREPCMONTHS:
                unitFlags |= NSCalendar.Unit.month.rawValue
            case FREPCYEARS:
                unitFlags |= NSCalendar.Unit.year.rawValue
                var components: DateComponents? = nil
                if let targ {
                    components = gregorian?.components(NSCalendar.Unit(rawValue: unitFlags), from: targ)
                }
                if let components {
                    targ = gregorian?.date(from: components)
                }
            default:
                break
            }

            let currD = Int(targ?.timeIntervalSince1970 ?? 0)
            if epDate == currD {
                sql = String(format: "delete from voData where id = %ld and date = %d", Int(vo?.vid ?? 0), d.intValue) // safe because this is just cached fn rslt
                MyTracker?.toExecSql(sql)
            } else {
                epDate = currD
            }
        }




    }

    override func setFnVals(_ tDate: Int) {
        // called from trackerObj.m
        var sql: String?
        if vo?.value == "" {
            //TODO: null/init value is 0.00 so what does this delete line do?
            sql = String(format: "delete from voData where id = %ld and date = %d;", Int(vo?.vid ?? 0), tDate)
            //DBGLog(@"sql delete= %@",sql);
        } else {
            sql = String(format: "insert or replace into voData (id, date, val) values (%ld, %d,'%@');", Int(vo?.vid ?? 0), tDate, rTracker_resource.toSqlStr(vo?.value) ?? "")
        }
        MyTracker?.toExecSql(sql)
    }

    override func doTrimFnVals() {
        let frep0 = ((vo?.optDict)?["frep0"] as? NSNumber)?.intValue ?? 0
        if ISCALFREP(frep0) && ((vo?.optDict)?["graphlast"] != "0") && MyTracker?.goRecalculate ?? false {
            trimFnVals(frep0)
        }
    }

    /*
    // change to move loop on date to tracker level so just do once, not for every fn vo

     // TODO: rtm here -- optionally eliminate fn results for calendar unit endpoints
    // based on vo opt @"graphlast"
    - (void) setFnVals {
        int currDate = (int) [MyTracker.trackerDate timeIntervalSince1970];
        int nextDate = [MyTracker firstDate];

        if (0 == nextDate) {  // no data yet for this tracker so do not generate a 0 value in database
            return;
        }

        float ndx=1.0;
        float all = [self.vo.parentTracker getDateCount];

        do {
            [MyTracker loadData:nextDate];
            //DBGLog(@"sfv: %@ => %@",MyTracker.trackerDate, self.vo.value);
            if ([self.vo.value isEqualToString:@""]) {   //TODO: null/init value is 0.00 so what does this delete line do? 
               sql = [NSString stringWithFormat:@"delete from voData where id = %d and date = %d;",self.vo.vid, nextDate];
            } else {
               sql = [NSString stringWithFormat:@"insert or replace into voData (id, date, val) values (%d, %d,'%@');",
                            self.vo.vid, nextDate, [rTracker_resource toSqlStr:self.vo.value]];
            }
            [MyTracker toExecSql:sql];

            [rTracker_resource setProgressVal:(ndx/all)];
            ndx += 1.0;

        } while (MyTracker.goRecalculate && (nextDate = [MyTracker postDate]));    // iterate through dates

        NSInteger frep0 = [[self.vo.optDict objectForKey:@"frep0"] integerValue];
        if (ISCALFREP(frep0)
            &&
            (![[self.vo.optDict objectForKey:@"graphlast"] isEqualToString:@"0"])
            &&
            MyTracker.goRecalculate
            ) {
            [self trimFnVals:frep0];
        }

        // restore current date
    	[MyTracker loadData:currDate];

    }

    - (void) recalculate {
        [self setFnVals];
    }
    */

    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        // set val for all dates if dirty
        //[self setFnVals];

        [self transformVO_num:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> Any? {
        return vogd?.initAsNum(vo)
    }
}