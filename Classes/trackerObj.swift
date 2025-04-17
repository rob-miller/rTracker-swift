//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// trackerObj.swift
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
//  trackerObj.swift
//  rTracker
//
//  Created by Robert Miller on 16/03/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit

// to config checkbutton default states
let SAVERTNDFLT = true

// to config textfield default values
// #define PRIVDFLT        0  //note: already in valObj.h

// max days for graph, 0= no limit
let GRAPHMAXDAYSDFLT = 0

class trackerObj: tObjBase {

    private var _trackerName: String?
    var trackerName: String? {
        get {
            if nil == _trackerName {
                _trackerName = optDict["name"] as! String?
            }
            return _trackerName
        }
        set(trackerNameValue) {
            if _trackerName != trackerNameValue {
                _trackerName = trackerNameValue

                if let trackerNameValue {
                    // if not nil
                    optDict["name"] = trackerNameValue
                } else {
                    optDict.removeValue(forKey: "name")
                }
            }
        }
    }
    var trackerDate: Date?
    var lastDbDate: Int = 0
    
    var optDict: [String : Any] = [:]  // trackerObj level optDict in dtabase as text : any

    var valObjTable: [valueObj] = []

    var reminders: [notifyReminder] = []
    var reminderNdx = 0
    let recalcFnLock = AtomicTestAndSet()  //(initialValue: false)
    
    private var _maxLabel = CGSize.zero
    var maxLabel: CGSize {
        get {
            if (_maxLabel.height == 0) || (_maxLabel.width == 0) {
                let w = CGFloat(optDict["width"] as? Double ?? 0)
                let h = CGFloat(optDict["height"] as? Double ?? 0)
                _maxLabel = CGSize(width: w, height: h)
            }
            return _maxLabel
        }
        set(maxLabelValue) {
            if (_maxLabel.height != maxLabelValue.height) || (_maxLabel.width != maxLabelValue.width) {
                _maxLabel = maxLabelValue
                if _maxLabel.height != 0.0 && _maxLabel.width != 0.0 {
                    optDict["width"] = String(Float(_maxLabel.width))
                    optDict["height"] = String(Float(_maxLabel.height))
                } else {
                    optDict.removeValue(forKey: "width")
                    optDict.removeValue(forKey: "height")
                }
            }
        }
    }

    private var _nextColor = 0
    var nextColor: Int {
        let rv = _nextColor
        _nextColor += 1
        if _nextColor >= rTracker_resource.colorSet().count {
            _nextColor = 0
        }
        return rv
    }
    //@property (nonatomic,strong) NSArray *votArray;
    var activeControl: UIControl?
    var vc: UIViewController?

    private var _dateFormatter: DateFormatter?
    var dateFormatter: DateFormatter? {
        if nil == _dateFormatter {
            _dateFormatter = DateFormatter()
            _dateFormatter?.timeStyle = .long
            _dateFormatter?.dateStyle = .long

            //[_dateFormatter setTimeStyle:NSDateFormatterLongStyle];
            //[_dateFormatter setDateStyle:NSDateFormatterShortStyle];

            /*
                    NSString *dateComponents = @"yyyy MM dd HH mm ss";
                    _dateFormatter.locale = [NSLocale currentLocale];
                    _dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale currentLocale]];
                     */
        }
        return _dateFormatter
    }

    private var _dateOnlyFormatter: DateFormatter?
    var dateOnlyFormatter: DateFormatter? {
        if nil == _dateOnlyFormatter {
            _dateOnlyFormatter = DateFormatter()
            _dateOnlyFormatter?.timeStyle = .none
            _dateOnlyFormatter?.dateStyle = .long
            //[_dateOnlyFormatter setDateStyle:NSDateFormatterShortStyle];
        }
        return _dateOnlyFormatter
    }
    var csvReadFlags = 0
    var csvProblem: String?
    var togd: Togd?

    var prevTID: Int {
        get {
            return Int(optDict["prevTID"] as? String ?? "0")!
        }
        set(prevTIDvalue) {
            if prevTIDvalue != 0 {
                optDict["prevTID"] = String(prevTIDvalue)
            } else {
                optDict.removeValue(forKey: "prevTID")
            }
        }
    }
    var goRecalculate = false
    var swipeEnable = false
    var changedDateFrom = 0
   
    var csvHeaderDict: [String : [String]] = [:]
    var csvChoiceDict: [String : Int] = [:]

    var loadingDbData = false
    
    override init() {
        togd = nil
        super.init()
        trackerDate = nil
        dbName = nil

        //self.valObjTable = [[NSMutableArray alloc] init];
        valObjTable = []
        _nextColor = 0

        //DBGLog(@"init trackerObj New");
        goRecalculate = false
        swipeEnable = true
        changedDateFrom = 0
    }

    convenience init(_ tid: Int) {
        self.init()
        //DBGLog(@"init trackerObj id: %d",tid);
        super.toid = tid
        confirmDb()
        loadConfig()
    }

    convenience init(dict: [String : Any]) {
        self.init()
        //DBGLog(@"init trackerObj from dict id: %d",[dict objectForKey:@"tid"]);
        super.toid = dict["tid"] as! Int
        confirmDb()
        loadConfig(fromDict: dict)
    }

    func mvIfFn(_ vo: valueObj?, testVT tstVT: Int) -> Bool {
        if (VOT_FUNC != tstVT) || (VOT_FUNC == vo?.vtype) {
            return false
        }

        // fix it
        voUpdateVID(vo, newVID: getUnique())

        vo?.valueName = (vo?.valueName ?? "") + "_data"

        return true
    }
    
    func loadHKdata(dispatchGroup: DispatchGroup?, completion: (() -> Void)? = nil) -> Bool {
        dispatchGroup?.enter()
        let localGroup = DispatchGroup()
        var rslt = false
        for vo in valObjTable {
            if vo.optDict["ahksrc"] ?? "0" != "0" {
                vo.vos?.loadHKdata(dispatchGroup: localGroup)
                rslt = true
            }
        }
        // Wait for our local operations to complete before calling completion
        localGroup.notify(queue: .main) {
            completion?()
            dispatchGroup?.leave()
        }
        return rslt
    }

    func loadOTdata(otSelf: Bool = false, dispatchGroup: DispatchGroup?, completion: (() -> Void)? = nil) -> Bool {
        dispatchGroup?.enter()
        let localGroup = DispatchGroup()
        var rslt = false
        for vo in valObjTable {
            guard vo.optDict["otsrc"] ?? "0" != "0",
                  let otTracker = vo.optDict["otTracker"] else { continue }
            if (otSelf && otTracker == trackerName) ||
               (!otSelf && otTracker != trackerName) {
                vo.vos?.loadOTdata(dispatchGroup: localGroup)
                rslt = true
            }
        }
        // Wait for our local operations to complete before calling completion
        localGroup.notify(queue: .main) {
            completion?()
            dispatchGroup?.leave()
        }
        return rslt
    }

    private func processFnData(dispatchGroup: DispatchGroup? = nil, forceAll: Bool = false, completion: (() -> Void)? = nil) -> Bool {
        let localGroup = DispatchGroup()
        var rslt = false
        
        // Check if we have any functions
        var haveFn = false
        for vo in valObjTable {
            if VOT_FUNC == vo.vtype {
                haveFn = true
                break
            }
        }
        if !haveFn {
            completion?()
            return rslt
        }
        
        let currDate = Int(trackerDate?.timeIntervalSince1970 ?? 0)
        
        // Determine start date based on mode
        var nextDate: Int
        if forceAll {
            nextDate = firstDate() // Always start from beginning for setFnVals
        } else {
            let sql = "select max(date) from voFNstatus where stat = \(fnStatus.fnData.rawValue)"
            nextDate = toQry2Int(sql: sql)
            if nextDate == 0 || (optDict["dirtyFns"] as? String) == "1" {
                nextDate = firstDate()
            }
        }
        
        if 0 == nextDate {
            // no data yet for this tracker so do not generate a 0 value in database
            completion?()
            return rslt
        }
        
        dispatchGroup?.enter()
        
        var ndx: Float = 1.0
        let all = Float(getDateCount())
        
        repeat {
            _ = loadData(nextDate)
            
            for vo in valObjTable {
                if dispatchGroup != nil {
                    vo.vos?.setFnVal(nextDate, dispatchGroup: localGroup)  // async with dispatch group
                } else {
                    vo.vos?.setFnVal(nextDate)  // sync without dispatch group
                }
            }
            
            // Only show progress if no dispatch group (sync operation)
            if dispatchGroup == nil {
                rTracker_resource.setProgressVal(ndx / all)
                ndx += 1.0
            }
            
            nextDate = postDate()
        } while (nextDate != 0) // iterate through dates
        
        for vo in valObjTable {
            vo.vos?.doTrimFnVals()
        }
        
        // restore current date
        _ = loadData(currDate)
        
        // Clear dirty flag regardless
        optDict.removeValue(forKey: "dirtyFns")
        let sql = "delete from trkrInfo where field='dirtyFns';"
        toExecSql(sql:sql)
        
        
        rslt = true
        
        // Wait for local operations to complete before calling completion
        localGroup.notify(queue: .main) {
            completion?()
            dispatchGroup?.leave()
        }
        
        return rslt
    }

    func loadFNdata(dispatchGroup: DispatchGroup?, completion: (() -> Void)? = nil) -> Bool {
        return processFnData(dispatchGroup: dispatchGroup, forceAll: false, completion: completion)
    }

    func setFnVals(completion: (() -> Void)? = nil) {
        _ = processFnData(forceAll: true, completion: completion)
    }
    
    func sortVoTable(byArray arr: [AnyHashable]?) {
        guard let arr = arr as? [valueObj], !arr.isEmpty else { return }
        
        // Create dictionary mapping vid to target index
        let targetIndices = Dictionary(uniqueKeysWithValues: arr.enumerated().map { ($0.element.vid, $0.offset) })
        
        // Sort valObjTable based on target indices
        valObjTable.sort { vo1, vo2 in
            let idx1 = targetIndices[vo1.vid] ?? Int.max
            let idx2 = targetIndices[vo2.vid] ?? Int.max
            return idx1 < idx2
        }
    }
    
    func voSet(fromDict vo: valueObj?, dict: [AnyHashable : Any]?) {
        vo?.setOptDict((dict?["optDict"] as? [String : String])!)
        vo?.vpriv = (dict?["vpriv"] as? NSNumber)?.intValue ?? 0
        vo?.vtype = (dict?["vtype"] as? NSNumber)?.intValue ?? 0
        vo?.vcolor = (dict?["vcolor"] as? NSNumber)?.intValue ?? 0
        vo?.vGraphType = (dict?["vGraphType"] as? NSNumber)?.intValue ?? 0
    }

    func rescanVoIds(_ existingVOs: inout [AnyHashable : Any]) {
        existingVOs.removeAll()
        for vo in valObjTable {
            existingVOs[NSNumber(value: vo.vid)] = vo
        }
    }

    // make self trackerObj conform to incoming dict = trackerObj optdict, valobj array of vid, name
    // handle voConfig voInfo; voData to be handled by loadDataDict
    func confirmTOdict(_ dict: [AnyHashable : Any]?) {

        //---- optDict ----//
        if let newOptDict = dict?["optDict"] as? [String : String] {
            for (key, value) in newOptDict {
                self.optDict[key] = value
            }
        }


        //---- reminders ----//
        let rda = dict?["reminders"] as? [AnyHashable]
        for rd in rda ?? [] {
            guard let rd = rd as? [AnyHashable : Any] else {
                continue
            }
            let nr = notifyReminder(dict: rd)
            nr.tid = super.toid
            reminders.append(nr)
        }

        //---- valObjTable and db ----//
        let newValObjs = dict?["valObjTable"] as? [AnyHashable] // typo @"valObjTable@" removed 26.v.13
        rTracker_resource.stashProgressBarMax((newValObjs?.count ?? 0))

        var existingVOs: [AnyHashable : Any] = [:]
        var newVOs: [AnyHashable] = []

        rescanVoIds(&existingVOs)
        var regex: NSRegularExpression? = nil
        do {
            regex = try NSRegularExpression(pattern: "^recover\\d+$", options: [])
        } catch {
        }

        for voDict in newValObjs ?? [] {
            guard let voDict = voDict as? [AnyHashable : Any] else {
                continue
            }
            let nVidN = voDict["vid"] as? NSNumber // new VID
            let nVname = voDict["valueName"] as? String
            let nVtype = (voDict["vtype"] as? NSNumber)?.intValue ?? 0
            var addVO = true
            //BOOL createdVO=NO;

            var eVO: valueObj? = nil
            if let nVidN {
                eVO = existingVOs[nVidN] as? valueObj
            }
            if eVO != nil {
                // self has vid;
                let recoveredName = regex?.numberOfMatches(in: eVO?.valueName ?? "", options: [], range: NSRange(location: 0, length: eVO?.valueName?.count ?? 0)) ?? 0
                if (nVname == eVO?.valueName) || (1 == recoveredName) || (loadingDemos) {
                    // name matches same vid or name is recovered1234 or we are loading demo so overwrite on same vid
                    if mvIfFn(eVO, testVT: nVtype) {
                        // move out of way if fn-data clash
                        rescanVoIds(&existingVOs) // re-validate
                        eVO = valueObj(dict: self, dict: voDict) // create new vo
                        //createdVO=YES;
                    } else {
                        addVO = false // name and VID match so we overwrite existing vo
                        voSet(fromDict: eVO, dict: voDict)
                    }
                } else {
                    // name does not match
                    voUpdateVID(eVO, newVID: getUnique()) // shift eVO to another vid
                    rescanVoIds(&existingVOs) // re-validate
                    eVO = nil // scan names below
                }
            }

            if eVO == nil {
                // self does not have vid, or has vid and name does not match and self's vid moved out of way
                var foundMatch = false
                for vo in valObjTable {
                    // now look for any existing vo with same name
                    if !foundMatch {
                        //  (only take first match)
                        if nVname == vo.valueName {
                            // name matches different existing vid
                            foundMatch = true
                            if mvIfFn(vo, testVT: nVtype) {
                                // move out of way if fn-data clash
                                rescanVoIds(&existingVOs) // re-validate
                                //eVO = [[valueObj alloc] initWithDict:self dict:voDict];  // create new vo --> do below  (eVO is nil)
                            } else {
                                // did not mv due to fn-data clash - so overwrite
                                voUpdateVID(vo, newVID: nVidN?.intValue ?? 0) // change self vid to input vid
                                rescanVoIds(&existingVOs) // re-validate
                                eVO = vo
                                addVO = false
                                voSet(fromDict: eVO, dict: voDict)
                            }
                        }
                    }
                }
                if !(foundMatch) || (eVO == nil) {
                    eVO = valueObj(dict: self, dict: voDict) // also confirms uniquev >= nVid
                    //createdVO=YES;
                }
            }

            if addVO {
                addValObj(eVO!)
                rescanVoIds(&existingVOs) // re-validate
            }

            if let eVO {
                newVOs.append(eVO)
            }
            //DBGLog(@"** added eVO vid %d",eVO.vid);

            rTracker_resource.bumpProgressBar()
        }

        sortVoTable(byArray: newVOs)

    }

    deinit {
        DBGLog(String("dealloc tObj: \(trackerName)"))

        trackerName = nil

        vc = nil
        activeControl = nil
    }

    //- (void) reloadVOtable;

    // MARK: -
    // MARK: load/save db<->object

    func loadConfig() {

        dbgNSAssert(super.toid != 0, "tObj load toid=0")

        DBGLog(String("tObj loadConfig toid:\(super.toid) name:\(trackerName)"))

        //var s1: [AnyHashable] = []
        //var s2: [AnyHashable] = []
        var sql = "select field, val from trkrInfo;"
        var ssa = toQry2ArySS(sql: sql)

        //NSEnumerator *e1 = [s1 objectEnumerator];
        //var e2 = (s2 as NSArray).objectEnumerator()

        for (key, e2) in ssa {
            optDict[key] = (key == "name") ? rTracker_resource.fromSqlStr(e2) : e2
        }

        setTrackerVersion()
        setToOptDictDflts()
        _ = loadReminders() // required here as can't distinguish did not load vs. deleted all

        DBGLog(String("to optdict: \(optDict)"))

        sql = "select max(date) from trkrData"
        lastDbDate = toQry2Int(sql:sql)
        
        //self.trackerName = [self.optDict objectForKey:@"name"];

        let w = CGFloat(Double(optDict["width"] as? Double ?? 0))
        let h = CGFloat(Double(optDict["height"] as? Double ?? 0))
        maxLabel = CGSize(width: w, height: h)

        //self.sql = @"select id, type, name, color, graphtype from voConfig order by rank;";
        sql = String(format: "select id, type, name, color, graphtype, priv from voConfig where priv <= %i order by rank;", privacyValue)
        let iisiii = toQry2AryIISIII(sql: sql)
        for (vid,e2,e3,e4,e5,e6) in iisiii {
            let vo = valueObj(
                data: self,
                in_vid: vid,
                in_vtype: e2,
                in_vname: e3,
                in_vcolor: e4,
                in_vgraphtype: e5,
                in_vpriv: e6)
            valObjTable.append(vo)
        }

        for vo in valObjTable {
            sql = String(format: "select field, val from voInfo where id=%ld;", vo.vid)
            ssa = toQry2ArySS(sql: sql)
            for (key, e2) in ssa {
                vo.setOptDictKeyVal(key: key, val: e2)
            }

            if vo.vcolor > nextColor {
                _nextColor = vo.vcolor
            }

            vo.vos?.setOptDictDflts()
            vo.vos?.loadConfig()

            vo.validate()
        }

        //[self nextColor];  // inc safely past last used color
        if nextColor >= rTracker_resource.colorSet().count {
            _nextColor = 0
        }



        //sql = nil;

        trackerDate = nil
        trackerDate = Date()
        rescanMaxLabel()




    }

    //
    // load tracker config, valObjs from supplied dictionary
    // self.trackerName from dictionary:optDict:trackerName
    //
    func loadConfig(fromDict dict: [String : Any]) {

        dbgNSAssert(super.toid != 0, "tObj load from dict toid=0")

        optDict = dict["optDict"] as! [String : Any]

        setTrackerVersion()
        setToOptDictDflts() // probably redundant

        //self.trackerName = [self.optDict objectForKey:@"name"];

        DBGLog(String("tObj loadConfigFromDict toid:\(super.toid) name:\(trackerName)"))

        //CGFloat w = [[self.optDict objectForKey:@"width"] floatValue];
        //CGFloat h = [[self.optDict objectForKey:@"height"] floatValue];
        //self.maxLabel = (CGSize) {w,h};

        let voda = dict["valObjTable"] as? [AnyHashable]
        for vod in voda ?? [] {
            guard let vod = vod as? [String : Any] else {
                continue
            }
            let vo = valueObj(dict: self, dict: vod)
            DBGLog(String("add vo \(vo.valueName)"))
            valObjTable.append(vo)
        }

        for vo in valObjTable {

            if vo.vcolor > _nextColor {
                _nextColor = vo.vcolor
            }

            vo.vos?.setOptDictDflts()
            vo.vos?.loadConfig() // loads from vo optDict
        }

        let rda = dict["reminders"] as? [AnyHashable]
        for rd in rda ?? [] {
            guard let rd = rd as? [AnyHashable : Any] else {
                continue
            }
            let nr = notifyReminder(dict: rd)
            reminders.append(nr)
        }

        //[self nextColor];  // inc safely past last used color
        if _nextColor >= rTracker_resource.colorSet().count {
            _nextColor = 0
        }

        //sql = nil;

        trackerDate = nil
        trackerDate = Date()
        DBGLog(String("loadConfigFromDict finished loading \(trackerName)"))
    }

    // delete default settings from vo.optDict to save space

    func clearVoOptDictDflts(_ vo: valueObj) {
        //var s1: [String] = []
        var sql = String(format: "select field from voInfo where id=%ld;", Int(vo.vid))
        var s1 = toQry2AryS(sql: sql)
        for dk in vo.optDict.keys {
            if !s1.contains(dk) {
                s1.append(dk)
            }
        }

        for key in s1 {
            sql = String(format: "delete from voInfo where id=%ld and field='%@';", Int(vo.vid), key)

            if (vo.vos?.cleanOptDictDflts(key)) ?? false {
                toExecSql(sql:sql)
            }
        }

        //sql = nil;
    }

    // MARK: tracker obj default set and vacuum routines together

    //  version change for 1.0.7 to include version info with tracker
    func setTrackerVersion() {

        if nil == optDict["rt_build"] {
            optDict["rtdb_version"] = String(RTDB_VERSION)
            optDict["rtfn_version"] = String(RTFN_VERSION)
            optDict["rt_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            optDict["rt_build"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            saveToOptDict()

            DBGLog("tracker init version info")
        }
    }

    // setToOptDictDflts
    //  fields not stored in db if they are set to default values, so here set set those values in Tobj if not read in from db
    func setToOptDictDflts() {
        if nil == optDict["savertn"] {
            optDict["savertn"] = SAVERTNDFLT ? "1" : "0"
        }
        if nil == optDict["privacy"] {
            optDict["privacy"] = "\(PRIVDFLT)"
        }
        if nil == optDict["graphMaxDays"] {
            optDict["graphMaxDays"] = "\(GRAPHMAXDAYSDFLT)"
        }
    }

    func clearToOptDict() {
        //var s1: [AnyHashable] = []
        var sql = "select field from trkrInfo;"
        let s1 = toQry2AryS(sql: sql)
        var val: String?

        for key in s1 {
            val = optDict[key] as? String? ?? nil
            sql = "delete from trkrInfo where field='\(key)';"

            if val == nil {
                toExecSql(sql:sql)
            } else if ((key == "savertn") && (val == (SAVERTNDFLT ? "1" : "0"))) || ((key == "privacy") && (Int(val ?? "") ?? PRIVDFLT == PRIVDFLT)) || ((key == "graphMaxDays") && (Int(val ?? "") ?? GRAPHMAXDAYSDFLT == GRAPHMAXDAYSDFLT)) {
                toExecSql(sql:sql)
                optDict.removeValue(forKey: key)
            }
        }

        //sql = nil;
    }

    func saveToOptDict() {

        clearToOptDict()

        for (key, val) in optDict {
            let sql = "insert or replace into trkrInfo (field, val) values ('\(key)', '\(val)');"
            toExecSql(sql:sql)
        }

    }

    func updateVORefs(_ newVID: Int, old oldVID: Int) {
        for vo in valObjTable {
            vo.vos?.updateVORefs(newVID, old: oldVID)
        }
    }

    // create minimal valobj in db tables to handle column in CSV data that does not match existing valObj
    func createVOinDb(_ name: String, inVid: Int) -> Int {
        var vid: Int
        var sql: String
        if 0 != inVid {
            sql = "select count(*) from voConfig where id=\(inVid)"
            if 0 < toQry2Int(sql:sql) {
                sql = "update voConfig set name=\"\(name)\" where id=\(inVid)"
                toExecSql(sql:sql)
                return inVid
            }
            vid = inVid
            minUniquev(inVid)
        } else {
            vid = getUnique()
        }
        sql = "select max(rank) from voConfig"

        let rank = toQry2Int(sql:sql) + 1

        sql = String(format: "insert into voConfig (id, rank, type, name, color, graphtype,priv) values (%ld, %ld, %d, '%@', %d, %d, %d);", vid, rank, 0, rTracker_resource.toSqlStr(name), 0, 0, MINPRIV)
        toExecSql(sql:sql)

        return vid
    }

    // set type for valobj in db table if passed vot matches a type
    func configVOinDb(_ valObjID: Int, vots: String?, vocs: String?, rank: Int) -> Bool {
        var rslt = false
        if "" == vots {
            return rslt
        }

        let vot = rTracker_resource.vtypeNames().firstIndex(of: vots ?? "") ?? NSNotFound // [self.votArray indexOfObject:vots];
        if NSNotFound == vot {
            return rslt
        }

        //DBGLog(@"vot= %d",vot);

        var sql = String(format: "update voConfig set type=%lu where id=%ld", UInt(vot), valObjID)
        toExecSql(sql:sql)
        rslt = true
        DBGLog(String("vot= \(UInt(vot))"))
        if vocs == nil {
            return rslt
        }

        DBGLog(String("search for \(vocs!)"))

        var voc = -1 // default to VOT_CHOICE: choice color is -1 for no color as need to check optdict
        if VOT_CHOICE != vot {
            voc = rTracker_resource.colorNames().firstIndex(of: vocs ?? "") ?? NSNotFound
            if NSNotFound == voc {
                return rslt
            }
        }

        DBGLog(String("voc= \(Int(voc))"))

        sql = String(format: "update voConfig set color=%ld where id=%ld", Int(voc), valObjID)
        toExecSql(sql:sql)

        // rank only 0 for timestamp
        sql = String(format: "update voConfig set rank=%ld where id=%ld", rank, valObjID)
        toExecSql(sql:sql)


        //sql = nil;

        return rslt
    }

    func saveVoOptdict(_ vo: valueObj) {
        clearVoOptDictDflts(vo)  // wipe default values to save space
        var sql: String
        for (key, val) in vo.optDict {
            sql = String("insert or replace into voInfo (id, field, val) values (\(vo.vid), '\(key)', '\(val)')")
            toExecSql(sql:sql)
        }
    }

    func saveConfig() {
        DBGLog(String("tObj saveConfig: trackerName= \(trackerName!)"))

        confirmDb()

        // trackerName and maxLabel maintained in optDict by routines which set them

        saveToOptDict()

        var vids: [String] = []
        // put valobjs in state for saving
        for vo in valObjTable {
            if vo.vid <= 0 {
                let old = vo.vid
                vo.vid = getUnique()
                updateVORefs(vo.vid, old: old)
            }
            vids.append(String(format: "%ld", vo.vid))
        }

        // remove previous data - input rtrk may renumber and then some vids become obsolete -- if reading rtrk have done jumpMaxPriv
        var sql = "delete from voConfig where priv <=\(privacyValue) and id not in (\(vids.joined(separator: ",")))" // 18.i.2014 don't wipe all in case user quits before we finish

        toExecSql(sql:sql)

        sql = "delete from voInfo where id not in (select id from voConfig)" // 10.xii.2013 don't delete info for hidden items
        toExecSql(sql:sql)

        safeDispatchSync({ [self] in
            // now save
            UIApplication.shared.isIdleTimerDisabled = true
            var i = 0
            for vo in valObjTable {
                //DBGLog(@"  vo %@  id %ld", vo.valueName, (long)vo.vid);
                let priv: Int = Int(vo.optDict["privacy"] ?? "") ?? PRIVDFLT
                let sql = String(format: "insert or replace into voConfig (id, rank, type, name, color, graphtype, priv) values (%ld, %d, %ld, '%@', %ld, %ld, %d);", vo.vid, i, vo.vtype, rTracker_resource.toSqlStr(vo.valueName!), vo.vcolor, vo.vGraphType, priv)
                toExecSql(sql:sql)

                saveVoOptdict(vo)
                i += 1
            }
            

            reminders2db()
            setReminders()

            UIApplication.shared.isIdleTimerDisabled = false
        })
    }

    func saveChoiceConfigs() {
        // for csv load, need to update vo optDict if vo is VOT_CHOICE
        //DBGLog(@"tObj saveChoiceConfig: trackerName= %@",self.trackerName) ;
        var NeedSave = false
        for vo in valObjTable {
            if VOT_CHOICE == vo.vtype {
                NeedSave = true
                break
            }
        }
        if NeedSave {
            saveConfig()
        }
    }

    func getValObj(_ qVid: Int) -> valueObj? {
        var rvo: valueObj? = nil

        for vo in valObjTable {
            if vo.vid == qVid {
                rvo = vo
                break
            }
        }

        if rvo == nil {
            // won't find if privacy restricted
            DBGLog(String("tObj getValObj failed to find vid \(qVid)"))
        }
        return rvo
    }

    func getValObjByName(_ qName: String) -> valueObj? {
        var rvo: valueObj? = nil

        //NSEnumerator *e = [self.valObjTable objectEnumerator];
        //valueObj *vo;
        //while (vo = (valueObj *) [e nextObject]) {
        for vo in valObjTable {
            if vo.valueName == qName {
                rvo = vo
                break
            }
        }

        if rvo == nil {
            DBGLog(String("tObj getValObj failed to find vname \(qName)"))
        }
        return rvo
    }
    
    func loadData(_ iDate: Int) -> Bool {

        let qDate = Date(timeIntervalSince1970: TimeInterval(iDate))
        // DBGLog(@"trackerObj loadData for date %@",qDate);
        // don't leave thread, need values reset here: dispatch_async(dispatch_get_main_queue(), ^(void){
        resetData()
        var sql = String(format: "select count(*) from trkrData where date = %ld and minpriv <= %d;", iDate, privacyValue)
        let c = toQry2Int(sql:sql)
        if c != 0 {
            trackerDate = qDate 
            sql = String(format: "select id, val from voData where date = %ld;", iDate)
            let isa = toQry2AryIS(sql: sql)

            for (vid, dbVal) in isa {
                let vo = getValObj(vid)

                if let vo {
                    // no vo if privacy restricted
                    //DBGLog(@"vo id %ld newValue: %@",(long)vid,newVal);

                    if (VOT_CHOICE == vo.vtype) || (VOT_SLIDER == vo.vtype) {
                        vo.useVO = ("" == dbVal) ? false : true // enableVO disableVO
                    } else {
                        vo.useVO = true
                    }
                    vo.value = dbVal
                }
            }

            return true
        } else {
            DBGLog(String("tObj loadData: nothing for date \(iDate) \(qDate)"))
            return false
        }
    }

    func saveData() {
        var sql: String
        if trackerDate == nil {
            trackerDate = Date()
        } else if 0 != changedDateFrom {
            let ndi = Int(trackerDate?.timeIntervalSince1970 ?? 0)
            sql = "update trkrData set date=\(ndi) where date=\(changedDateFrom);"
            toExecSql(sql:sql)
            sql = "update voData set date=\(ndi) where date=\(changedDateFrom);"
            toExecSql(sql:sql)
            changedDateFrom = 0
        }

        DBGLog(String("tObj saveData \(trackerName) date \(trackerDate!)"))

        let tdi = Int(trackerDate?.timeIntervalSince1970 ?? 0) // scary! added (int) cast 6.ii.2013 !!!
        var minPriv = BIGPRIV

        for vo in valObjTable {
            dbgNSAssert((vo.vid >= 0), "tObj saveData vo.vid <= 0")
            if VOT_INFO != vo.vtype || ("1" == vo.optDict["infosave"]) {
                
                DBGLog(String("  vo \(vo.valueName)  id \(vo.vid) val \(vo.value)"))
                minPriv = Int(min(vo.vpriv, minPriv))
                insertTrackerVodata(vid: vo.vid, date: tdi, val: rTracker_resource.toSqlStr(vo.value), vo:vo)
                
            }
        }

        sql = String(format: "insert or replace into trkrData (date,minpriv) values (%d,%ld);", tdi, minPriv)
        toExecSql(sql:sql)
        
        // might have inserted blank voData or trkrData with no voData entries, so clean up
        // confirm only matching trkrData and voData (and support) entries, no voData entries of ''
        cleanDb()
        
        setReminders()
    }

    
    // MARK: value data updated event handling

    @objc func trackerUpdated(_ n: Notification?) {
        #if DEBUGLOG
        let obj = n!.object
        if obj is valueObj {  // type(of: obj) === valueObj.self {
            let vo = n!.object as! valueObj
            DBGLog(String("trackerObj \(trackerName) updated by vo \(vo.vid) : \(vo.valueName) => \(vo.value)"))
        } else {
            let vos = obj as! voState
            DBGLog(String("trackerObj \(trackerName) updated by vo (voState)  \(vos.vo.vid) : \(vos.vo.valueName) => \(vos.vo.value)"))
        }
        #endif

        NotificationCenter.default.post(name: NSNotification.Name(rtTrackerUpdatedNotification), object: self)
    }

    // MARK: -
    // MARK: manipulate tracker's valObjs

    func copyVoConfig(_ srcVO: valueObj) -> valueObj {
        DBGLog(String("copyVoConfig: to= id \(super.toid) \(trackerName) input vid=\(srcVO.vid) \(srcVO.valueName)"))

        let newVO = valueObj(parentOnly: srcVO.parentTracker)
        newVO.vid = getUnique()

        newVO.vtype = srcVO.vtype
        newVO.valueName = srcVO.valueName

        for (key, val) in srcVO.optDict {
            newVO.optDict[key] = val
        }

        return newVO
    }

    // MARK: -
    // MARK: utility methods

    func describe() {
#if DEBUGLOG
        DBGLog(String("tracker id \(super.toid) name \(trackerName ?? "") dbName \(dbName ?? "")"))
        DBGLog(
            String("db ver \(optDict["rtdb_version"] ?? "") fn ver \(optDict["rtfn_version"] ?? "") created by rt ver \(optDict["rt_version"] ?? "") build \(optDict["rt_build"] ?? "")"))

        for vo in valObjTable {
            vo.describe(false)
        }
#endif
    }


    func recalculateFns() {
        DBGLog("try atomic set recalcFnLock")
        if recalcFnLock.testAndSet(newValue: true) {
            // wasn't 0 before, so we didn't get lock, so leave because shake handling already in process
            return
        }

        DBGLog(String("tracker id \(super.toid) name \(trackerName) dbname \(dbName) recalculateFns"))

        rTracker_resource.setProgressVal(0.0)
        for vo in valObjTable {
            if vo.vtype == VOT_FUNC {
                vo.vos?.clearFNdata()  // wipe db values so vo.value read forced to update
            }
        }
        setFnVals()

        if goRecalculate {
            goRecalculate = false
        }

            DBGLog("release atomic recalcFnLock")
        _ = recalcFnLock.testAndSet(newValue: false)
    }

    func setTOGD(_ inRect: CGRect) {
        // note TOGD not Togd -- so self.togd still automatically retained/released
        let ttogd = Togd(data: self, rect: inRect)
        togd = ttogd
        togd!.fillVOGDs()
        //[self.togd release];  // rtm 05 feb 2012 +1 alloc, +1 self.togd retain
    }


    func getPrivacyValue() -> Int {
        return Int(optDict["privacy"] as? String ?? "") ?? 1
    }

}
