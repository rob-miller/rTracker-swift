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
// #define PRIVDFLT		0  //note: already in valObj.h

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

    func initTDb() {
        var c: Int
        var sql = "create table if not exists trkrInfo (field text, val text, unique ( field ) on conflict replace);"
        toExecSql(sql:sql)
        sql = "select count(*) from trkrInfo;"
        c = super.toQry2Int(sql:sql)!
        if c == 0 {
            // init clean db
            sql = "create table if not exists voConfig (id int, rank int, type int, name text, color int, graphtype int, priv int, unique (id) on conflict replace);"
            toExecSql(sql:sql)
            sql = "create table if not exists voInfo (id int, field text, val text, unique(id, field) on conflict replace);"
            toExecSql(sql:sql)
            sql = "create table if not exists voData (id int, date int, val text, unique(id, date) on conflict replace);"
            toExecSql(sql:sql)
            sql = "create index if not exists vodndx on voData (date);"
            toExecSql(sql:sql)
            sql = "create table if not exists trkrData (date int unique on conflict replace, minpriv int);"
            toExecSql(sql:sql)
        }
        
        // healthkit support added later
        sql = "create table if not exists voHKstatus (id int not null, date int not null, stat int not null, unique(id, date) on conflict replace);"
        toExecSql(sql:sql)
        sql = "create index if not exists vohkndx on voHKstatus (id, date);"
        toExecSql(sql:sql)
        
        // otherTracker support added later
        sql = "create table if not exists voOTstatus (id int not null, date int not null, stat int not null, unique(id, date) on conflict replace);"
        toExecSql(sql:sql)
        sql = "create index if not exists vootndx on voHKstatus (id, date);"
        toExecSql(sql:sql)
        
        //self.sql = nil;
    }

    func confirmDb() {
        dbgNSAssert(super.toid != 0, "tObj confirmDb toid=0")
        if dbName == nil {
            dbName = String(format: "trkr%ld.sqlite3", super.toid)
            //self.dbName = [[NSString alloc] initWithFormat:@"trkr%d.sqlite3",super.toid];
            getTDb()
            initTDb()
        }
        initReminderTable() // outside because added later
    }

    override init() {
        togd = nil
        super.init()
        trackerDate = nil
        dbName = nil

        //self.valObjTable = [[NSMutableArray alloc] init];
        valObjTable = []
        _nextColor = 0

        /*  move to utc
        		[[NSNotificationCenter defaultCenter] addObserver:self 
        												 selector:@selector(trackerUpdated:) 
        													 name:rtValueUpdatedNotification 
        												   object:nil];
        		*/
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
    
    func loadHKdata(dispatchGroup: DispatchGroup?) -> Bool {
        var rslt = false
        for vo in valObjTable {
            if vo.optDict["ahksrc"] ?? "0" != "0" {
                vo.vos?.loadHKdata(dispatchGroup: dispatchGroup)
                rslt = true
            }
        }
        return rslt
    }

    func loadOTdata(dispatchGroup: DispatchGroup?) -> Bool {
        var rslt = false
        for vo in valObjTable {
            if vo.optDict["otsrc"] ?? "0" != "0" {
                vo.vos?.loadOTdata(dispatchGroup: dispatchGroup)
                rslt = true
            }
        }
        return rslt
    }

    func sortVoTable(byArray arr: [AnyHashable]?) {
        var dict: [AnyHashable : Any] = [:]
        var ndx1 = 0
        var ndx2 = 0
        var c = 0
        var c2 = 0
        //let vo: valueObj? = nil
        for vo in valObjTable {
            dict[NSNumber(value: vo.vid)] = NSNumber(value: ndx1)
            ndx1 += 1
        }

        c = valObjTable.count
        c2 = arr?.count ?? 0
        ndx1 = 0; ndx2 = 0
        while ndx1 < c && ndx2 < c2 {
            let currVid = valObjTable[ndx1].vid
            let targVid = (arr?[ndx2] as? valueObj)?.vid ?? 0
            //DBGLog(@"ndx2: %d  targVid:%d",ndx2,targVid);
            if currVid != targVid {
                let targNdx = Int((dict[NSNumber(value: targVid)] as? NSNumber)?.uintValue ?? 0)
                valObjTable.swapAt(ndx1, targNdx)
                dict[NSNumber(value: currVid)] = NSNumber(value: targNdx)
                dict[NSNumber(value: targVid)] = NSNumber(value: ndx1)
            }
            ndx1 += 1; ndx2 += 1
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
        lastDbDate = toQry2Int(sql:sql)!
        
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
    func createVOinDb(_ name: String?, inVid: Int) -> Int {
        var vid: Int
        var sql: String
        if 0 != inVid {
            sql = "select count(*) from voConfig where id=\(inVid)"
            if 0 < toQry2Int(sql:sql)! {
                sql = "update voConfig set name=\"\(name ?? "")\" where id=\(inVid)"
                toExecSql(sql:sql)
                return inVid
            }
            vid = inVid
            minUniquev(inVid)
        } else {
            vid = getUnique()
        }
        sql = "select max(rank) from voConfig"

        let rank = toQry2Int(sql:sql)! + 1

        sql = String(format: "insert into voConfig (id, rank, type, name, color, graphtype,priv) values (%ld, %ld, %d, '%@', %d, %d, %d);", vid, rank, 0, rTracker_resource.toSqlStr(name) ?? "", 0, 0, MINPRIV)
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
                let sql = String(format: "insert or replace into voConfig (id, rank, type, name, color, graphtype, priv) values (%ld, %d, %ld, '%@', %ld, %ld, %d);", vo.vid, i, vo.vtype, rTracker_resource.toSqlStr(vo.valueName)!, vo.vcolor, vo.vGraphType, priv)
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

        //NSEnumerator *e = [self.valObjTable objectEnumerator];
        //valueObj *vo;
        //while (vo = (valueObj *) [e nextObject]) {
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
            trackerDate = qDate // from convenience method above, so do the retain
            //var i1: [AnyHashable] = []
            //var s1: [AnyHashable] = []
            sql = String(format: "select id, val from voData where date = %ld;", iDate)
            let isa = toQry2AryIS(sql: sql)

            //let e1 = (i1 as NSArray).objectEnumerator()
            //let e3 = (s1 as NSArray).objectEnumerator()
            //var vid: Int
            //while let tid = e1.nextObject() {
            for (vid, e3) in isa {
                //vid = (tid as? NSNumber)?.intValue ?? 0
                let newVal = e3 // read csv may gen bad id, keep enumerators even
                let vo = getValObj(vid)
                //dbgNSAssert1(vo,@"tObj loadData no valObj with vid %d",vid);
                if let vo {
                    // no vo if privacy restricted
                    //DBGLog(@"vo id %ld newValue: %@",(long)vid,newVal);

                    if (VOT_CHOICE == vo.vtype) || (VOT_SLIDER == vo.vtype) {
                        vo.useVO = ("" == newVal) ? false : true // enableVO disableVO
                    } else {
                        vo.useVO = true
                    }
                    vo.value = newVal // results not saved for func so not in db table to be read
                    //vo.retrievedData = YES;
                }
            }

            //self.sql = nil;

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

        DBGLog(String("tObj saveData \(trackerName) date \(trackerDate)"))

        var haveData = false
        let tdi = Int(trackerDate?.timeIntervalSince1970 ?? 0) // scary! added (int) cast 6.ii.2013 !!!
        var minPriv = BIGPRIV

        for vo in valObjTable {
            dbgNSAssert((vo.vid >= 0), "tObj saveData vo.vid <= 0")
            if VOT_INFO != vo.vtype || ("1" == vo.optDict["infosave"]) {
                //if (vo.vtype != VOT_FUNC) { // no fn results data kept
                DBGLog(String("  vo \(vo.valueName)  id \(vo.vid) val \(vo.value)"))
                if vo.value == "" {
                    sql = String(format: "delete from voData where id = %ld and date = %d;", vo.vid, tdi)
                } else {
                    haveData = true
                    minPriv = Int(min(vo.vpriv, minPriv))
                    sql = String(format: "insert or replace into voData (id, date, val) values (%ld, %d,'%@');", vo.vid, tdi, rTracker_resource.toSqlStr(vo.value) ?? "")
                }
                toExecSql(sql:sql)

                //}
            }
        }

        if haveData {
            sql = String(format: "insert or replace into trkrData (date,minpriv) values (%d,%ld);", tdi, minPriv)
            toExecSql(sql:sql)
        } else {
            sql = "select count(*) from voData where date=\(tdi);"
            let r = toQry2Int(sql:sql)
            if r == 0 {
                sql = "delete from trkrData where date=\(tdi);"
                toExecSql(sql:sql)
            }
        }

        // cleanup empty values added 28 jan 2014
        sql = "select count(*) from voData where val=''"
        let ndc = toQry2Int(sql:sql)!
        if 0 < ndc {
            DBGWarn(String("deleting \(ndc) empty values from tracker \(super.toid)"))
            sql = "delete from voData where val=''"
            toExecSql(sql:sql)
        }

        setReminders()

        //self.sql = nil;
    }

    // MARK: -
    //#pragma write tracker as rtrk or plist+csv for iTunes

    func getTmpPath(_ ext: String) -> String {
        // return URL for trackerName file with passed extension
        guard let trackerName = trackerName else { return "" }
        let fpatho = rTracker_resource.ioFilePath(nil, access: false, tmp: true)
        try? FileManager.default.createDirectory(atPath: fpatho, withIntermediateDirectories: false, attributes: nil)
        let fname = (rTracker_resource.sanitizeFileNameString(trackerName)) + ext
        //NSString *fname = [ self.trackerName stringByAppendingString:extension];
        let fpath = URL(fileURLWithPath: fpatho).appendingPathComponent(fname).path
        return fpath
    }

    /*
    func csvTmpPath() -> String? {
        return getTmpPath(rTracker_resource.getRtcsvOutput() ? RTCSVext : CSVext)
    }

    func rtrkTmpPath() -> String? {
        return getTmpPath(".rtrk")
    }
     */
    
    func writeTmpCSV() -> URL? {
        let fpath = getTmpPath(rTracker_resource.getRtcsvOutput() ? RTCSVext : CSVext)
        FileManager.default.createFile(atPath: fpath, contents: nil, attributes: nil)
        let nsfh = FileHandle(forWritingAtPath: fpath)
        writeTrackerCSV(nsfh)
        nsfh?.closeFile()

        return URL(fileURLWithPath:fpath)
    }

    func writeTmpRtrk(_ withData: Bool) -> URL? {
        var tData: [AnyHashable : Any] = [:]

        if withData {
            // save current trackerDate (NSDate->int)
            let currDate = Int(trackerDate?.timeIntervalSince1970 ?? 0)
            var nextDate = firstDate()

            var ndx: Float = 1.0
            let all = Float(getDateCount())

            repeat {
                _ = loadData(nextDate)
                var vData: [AnyHashable : Any] = [:]
                for vo in valObjTable {
                    vData[String(format: "%ld", vo.vid)] = vo.value
                    //DBGLog(@"genRtrk data: %@ for %@",vo.value,[NSString stringWithFormat:@"%d",vo.vid]);
                }
                tData["\(Int(trackerDate?.timeIntervalSinceReferenceDate ?? 0))"] = vData // copyItems: true

                //DBGLog(@"genRtrk vData: %@ for %@",vData,self.trackerDate);
                //DBGLog(@"genRtrk: tData= %@",tData);
                rTracker_resource.setProgressVal(ndx / all)
                ndx += 1.0
                nextDate = postDate()
            } while (nextDate != 0) // iterate through dates

            // restore current date
            _ = loadData(currDate)
        }
        // configDict not optional -- always need tid for load of data
        let rtrkDict: [String: Any] = [
            "tid": "\(self.toid)",
            "trackerName": self.trackerName!,
            "configDict": self.dictFromTO(),
            "dataDict": tData
        ]

        let fp = getTmpPath(RTRKext)
        if !(((rtrkDict as NSDictionary?)?.write(toFile: fp, atomically: true)) ?? false) {
            DBGErr(String("problem writing file \(fp)"))
            return nil
        } else {
            //[rTracker_resource protectFile:fp];
        }

        return URL(fileURLWithPath:fp)
    }

    func saveToItunes() -> Bool {
        var result = true
        var fname = "\(trackerName ?? "")_out.csv"

        var fpath = rTracker_resource.ioFilePath(fname, access: true)
        FileManager.default.createFile(atPath: fpath, contents: nil, attributes: nil)
        let nsfh = FileHandle(forWritingAtPath: fpath)

        //[nsfh writeData:[@"hello, world." dataUsingEncoding:NSUTF8StringEncoding]];

        writeTrackerCSV(nsfh)
        nsfh?.closeFile()


        fname = "\(trackerName ?? "")_out.plist"
        fpath = rTracker_resource.ioFilePath(fname, access: true)

        if !(((dictFromTO() as NSDictionary?)?.write(toFile: fpath, atomically: true)) ?? false) {

            DBGErr(String("problem writing file \(fname)"))
            result = false
            
            /*
            let foo = dictFromTO() as NSDictionary?
            do {
                let plistData = try PropertyListSerialization.data(fromPropertyList: (dictFromTO() as NSDictionary?), format: .xml, options: 0)
                try plistData.write(to: URL(fileURLWithPath: fpath))
            } catch {
                print("Error writing plist to file: \(error)")
            }
             */

        } else {
            //[rTracker_resource protectFile:fpath];
        }

        //[nsfh release];
        return result
    }

    func dictFromTO() -> [String : Any] {
        var vodma: [[String:Any]] = []
        for vo in valObjTable {
            if let dict = vo.dictFromVO() {
                vodma.append(dict)
            }
        }
        let voda = vodma

        var rdma: [[String:Any]] = []
        for nr in reminders {
            if let dict = nr.dictFromNR() {
                rdma.append(dict)
            }
        }
        let rda = rdma

        return [
            "tid": NSNumber(value: super.toid),
            "optDict": optDict,
            "reminders": rda,
            "valObjTable": voda
        ]

    }

    //- (NSDictionary *) genRtrk:(BOOL)withData;

    // import data for a tracker -- direct in db so privacy not observed
    func loadDataDict(_ dataDict: [String : [String : String]]) {
        rTracker_resource.stashProgressBarMax(dataDict.count)

        for dateIntStr in dataDict.keys {
            let tdate = Date(timeIntervalSinceReferenceDate: TimeInterval(Double(dateIntStr)!))
            let tdi = Int(tdate.timeIntervalSince1970)
            let vdata = dataDict[dateIntStr]
            var mp = BIGPRIV
            for vids in vdata!.keys {
                let vid = Int(vids)
                let vo = getValObj(vid!)
                //NSString *val = [vo.vos mapCsv2Value:[vdata objectForKey:vids]];
                let val = vdata![vids]
                let sql = String(format: "insert or replace into voData (id, date, val) values (%ld,%d,'%@');", vid!, tdi, rTracker_resource.toSqlStr(val)!)
                toExecSql(sql:sql)

                if (vo?.vpriv ?? 0) < mp {
                    mp = vo?.vpriv ?? 0
                }
            }
            let sql = String(format: "insert or replace into trkrData (date, minpriv) values (%d,%ld);", tdi, mp)
            toExecSql(sql:sql)
            rTracker_resource.bumpProgressBar()
        }
    }

    // MARK: -
    // MARK: read & write tracker data as csv

    func csvSafe(_ instr: String?) -> String? {
        var instr = instr
        //instr = [instr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        instr = instr?.replacingOccurrences(of: "\n", with: "\r")
        instr = instr?.replacingOccurrences(of: "\"", with: "\"\"")
        instr = "\"\(instr ?? "")\""
        if "\"(null)\"" == instr {
            instr = "\"\""
        }
        return instr
    }

    func str(toDate str: String?) -> Date? {

        return dateFormatter?.date(from: str ?? "")

    }

    func str(toDateOnly str: String?) -> Date? {

        return dateOnlyFormatter?.date(from: str ?? "")

    }

    func date(toStr dat: Date?) -> String? {

        //return [[self.dateFormatter stringFromDate:dat] stringByReplacingOccurrencesOfString:@" at " withString:@" "];
        if let dat {
            return dateFormatter?.string(from: dat)
        }
        return nil

    }

    func getDateCount() -> Int {
        let sql = "select count(*) from trkrData where minpriv <= \(privacyValue);"
        let rv = toQry2Int(sql:sql)!
        //self.sql = nil;
        return rv
    }

    func writeTrackerCSV(_ nsfh: FileHandle?) {

        //[nsfh writeData:[self.trackerName dataUsingEncoding:NSUTF8StringEncoding]];

        // write column titles

        var outString = "\"\(TIMESTAMP_LABEL)\""
        for vo in valObjTable {
            dbgNSAssert((vo.vid >= 0), "tObj writeTrackerCSV vo.vid <= 0")
            //DBGLog(@"wtxls:  vo %@  id %d val %@", vo.valueName, vo.vid, vo.value);
            //[nsfh writeData:[vo.valueName dataUsingEncoding:NSUnicodeStringEncoding]];
            if VOT_INFO != vo.vtype || ("1" == vo.optDict["infosave"]) {
                outString = outString + ",\(csvSafe(vo.valueName) ?? "")"
            }
        }
        outString = outString + "\n"
        if let data = outString.data(using: .utf8) {
            nsfh?.write(data)
        }

        if rTracker_resource.getRtcsvOutput() {
            var haveChoice = false
            outString = ""
            for vo in valObjTable {
                //DBGLog(@"vname= %@",vo.valueName);
                if VOT_INFO != vo.vtype || ("1" == vo.optDict["infosave"]) {
                    haveChoice = haveChoice || (vo.vtype == VOT_CHOICE)
                    var voStr: String? = nil
                    let vtypeNames = rTracker_resource.vtypeNames()[vo.vtype]
                    voStr = String(format: "%@:%@:%ld", vtypeNames, (vo.vcolor > -1 ? rTracker_resource.colorNames()[vo.vcolor] : ""), vo.vid)
                    
                    outString = outString + ",\(csvSafe(voStr) ?? "")"
                }
            }
            outString = outString + "\n"
            if let data = outString.data(using: .utf8) {
                nsfh?.write(data)
            }
            if haveChoice {
                for i in 0..<CHOICES {
                    outString = "\"\""
                    for vo in valObjTable {
                        //DBGLog(@"vname= %@",vo.valueName);
                        if VOT_INFO != vo.vtype || ("1" == vo.optDict["infosave"]) {
                            var voStr = ""
                            if vo.vtype == VOT_CHOICE {
                                voStr = ((vo.optDict)["c\(i)"]) ?? ""
                                // got "" if no choice at this position, "" is valid place holder so write
                            }
                            outString = outString + ",\(csvSafe(voStr) ?? "")"
                        }
                    }
                    outString = outString + "\n"
                    if let data = outString.data(using: .utf8) {
                        nsfh?.write(data)
                    }
                }
            }
        }


        // save current trackerDate (NSDate->int)
        let currDate = Int(trackerDate?.timeIntervalSince1970 ?? 0)
        var nextDate = firstDate()

        DBGLog(String("starting CSV output \(nextDate) to \(currDate)"))
        var ndx: Float = 1.0
        let all = Float(getDateCount())

        repeat {
            autoreleasepool {
                //DBGLog(@"date= %d",nextDate);
                _ = loadData(nextDate)
                // write data - each vo gets routine to write itself -- function results too
                outString = "\"\(date(toStr: trackerDate) ?? "")\""
                for vo in valObjTable {
                    if VOT_INFO != vo.vtype || ("1" == vo.optDict["infosave"]) {
                        outString = outString + ","
                        //if (VOT_CHOICE == vo.vtype) {
                        if let val = vo.csvValue() {
                            outString = outString + (csvSafe(val) ?? "")
                        }
                        //} else {
                        //outString = [outString stringByAppendingString:[self csvSafe:vo.value]];
                        //}
                    }
                }
                outString = outString + "\n"
                DBGLog(String("\(nextDate): \(outString)"))

                if let data = outString.data(using: .utf8) {
                    nsfh?.write(data)
                }
                rTracker_resource.setProgressVal(ndx / all)
                ndx += 1.0
                
                nextDate = postDate()
            }
        } while (nextDate != 0) // iterate through dates

        // restore current date
        _ = loadData(currDate)
    }

    //- (void)applicationWillTerminate:(NSNotification *)notification;

    // MARK: -
    // MARK: read in from export

    @objc func receiveRecord(_ aRecord: [String : String]) {
        DBGLog(String("input csv: \(aRecord)"))
        guard let tsStr = aRecord[TIMESTAMP_KEY] else {
            csvReadFlags |= CSVNOTIMESTAMP
            return
        }
        var sql: String

        var ts: Date? = nil
        var its = 0

        if "" != tsStr {
            ts = str(toDate: tsStr)
            if nil == ts {
                // try without time spec
                ts = str(toDateOnly: aRecord[TIMESTAMP_KEY])
            }
            if nil == ts {
                csvReadFlags |= CSVNOREADDATE
                if nil == csvProblem {
                    csvProblem = tsStr
                }
                DBGLog(String("failed reading timestamp \(tsStr)"))
                return
            }
            trackerDate = ts
            DBGLog(String("ts str: \(aRecord[TIMESTAMP_KEY]!)   ts read: \(ts!)"))
            its = Int(ts?.timeIntervalSince1970 ?? 0)
        }

        var gotData = false
        var mp = BIGPRIV
        for (key, val) in aRecord {
            DBGLog(String("processing csv record: key= \(key) value= \(val)"))
            if key != TIMESTAMP_KEY {
                // not timestamp

                // get voName and rank from aRecord item's dictionary key

                var voName: String
                var voRank: Int
                var valobjID: Int = 0
                var valobjPriv: Int = -1
                var valobjType: Int = -1
                let csvha: [String]? = csvHeaderDict[key]
                if nil == csvha {
                    //let keyComponents = key.components(separatedBy: ":")
                    //(voName, voRank) = (keyComponents[0], Int(keyComponents[1]) ?? 0)
                    if let lastColonRange = key.range(of: ":", options: .backwards) {
                        voName = String(key[..<lastColonRange.lowerBound])
                        voRank = Int(key[lastColonRange.upperBound...]) ?? 0
                    } else {
                        voName = key
                        voRank = 0 // Default value if no colon is found
                    }

                        
                    sql = "select id, priv, type from voConfig where name='\(rTracker_resource.toSqlStr(voName) ?? "")';"
                    (valobjID, valobjPriv, valobjType) = toQry2IntIntInt(sql: sql)!
                    if its != 0 {  // if no timestamp this is config data, so do not put in csvHeaderDict yet
                        csvHeaderDict[key] = [voName, String(voRank), String(valobjID), String(valobjPriv), String(valobjType)]
                    }
                } else {
                    voName = csvha![0]
                    voRank = Int(csvha![1])!
                    valobjID = Int(csvha![2])!
                    valobjPriv = Int(csvha![3])!
                    valobjType = Int(csvha![4])!
                }

                DBGLog(String("name=\(voName) rank=\(voRank) val/config=\(val) id=\(valobjID) priv=\(valobjPriv) type=\(valobjType)"))

                var configuredValObj = false
                if 0 == its {
                    // no timestamp for tracker config data, but still use variable settings from nil == csvha case above
                    // voType : color : vid
                    let valComponents = val.components(separatedBy: ":")
                    let c = valComponents.count
                    let inVot = valComponents[0]
                    var inVcolor: String?
                    var inVid = 0
                    if c>1 {
                        inVcolor = valComponents[1]
                        if c > 2 {
                            inVid = Int(valComponents[2])!
                        }
                    }

                    if (0 == valobjID) {
                        // no vo exists with this name so create and configure (reading rtcsv)

                        valobjID = createVOinDb(voName, inVid: inVid)
                        csvReadFlags |= CSVCREATEDVO
                        //}
                        configuredValObj = configVOinDb(valobjID, vots: inVot, vocs: inVcolor, rank: voRank)
                        if configuredValObj {
                            csvReadFlags |= CSVCONFIGVO
                        }
                        DBGLog(String("created new / updated valObj with id=\(valobjID) name= \(voName) type= \(inVot) color= \(inVcolor ?? "not set") rank = \(voRank)"))
                        
                        let vo = valueObj(fromDB: self, in_vid: valobjID)
                        valObjTable.append(vo)

                    } else if (inVid == valobjID) {
                        // input vid matches database valobjid for this name, mark as already configured (processing rtcsv line with :'s)
                        configuredValObj = true
                    }
                }
                //[idDict setObject:[NSNumber numberWithInt:valobjID] forKey:key];

                if !configuredValObj {
                    var val2Store = rTracker_resource.toSqlStr(val)

                    if "" != val2Store {
                        // could still be config data for choice or bool, timestamp not needed
                        if (VOT_CHOICE == valobjType) || (VOT_BOOLEAN == valobjType) {
                            if let vo = getValObj(valobjID) {
                                val2Store = vo.vos!.mapCsv2Value(val2Store!) // updates dict val for bool; for choice maps to choice number, adds choice to dict if needed
                                saveVoOptdict(vo)
                            }
                        }
                        // rtm TODO: should add function def string to rtcsv data
                    }
                    if its != 0 {
                        // if have date - then not config data
                        if "" == val2Store {
                            sql = String(format: "delete from voData where id=%ld and date=%d", valobjID, its) // added jan 2014
                        } else {
                            if valobjPriv < mp {
                                mp = valobjPriv // only fields with data
                            }
                            gotData = true
                            sql = String(format: "insert or replace into voData (id, date, val) values (%ld,%d,'%@');", valobjID, its, val2Store!)
                        }
                        toExecSql(sql:sql)

                        csvReadFlags |= CSVLOADRECORD
                    }
                }
            }
        }

        if its != 0 {
            if gotData {
                sql = String(format: "insert or replace into trkrData (date, minpriv) values (%d,%ld);", its, mp)
                toExecSql(sql:sql)
            }
        }

        //[rTracker_resource bumpProgressBar];
    }

    // MARK: -
    //#pragma save / load / remove temp tracker data file
    // save temp version of data only

    func saveTempTrackerData() {
        var saveData: [AnyHashable] = []
        for vo in valObjTable {
            if VOT_FUNC != vo.vtype {
                saveData.append(vo.value)
            }
        }
        var fp = getTmpPath(TmpTrkrData)
        if !((saveData as NSArray).write(toFile: fp, atomically: true)) {
            DBGErr(String("problem writing file \(fp)"))
        } else {
            //[rTracker_resource protectFile:fp];
        }

        var saveNames: [AnyHashable] = []
        for vo in valObjTable {
            if VOT_FUNC != vo.vtype {
                saveNames.append(vo.valueName ?? "")
            }
        }
        fp = getTmpPath(TmpTrkrNames)
        if !((saveNames as NSArray).write(toFile: fp, atomically: true)) {
            DBGErr(String("problem writing file \(fp)"))
        } else {
            //[rTracker_resource protectFile:fp];
        }
    }

    // read temp version of data only
    func loadTempTrackerData() -> Bool {

        let checkNames = NSArray(contentsOfFile: getTmpPath(TmpTrkrNames)) as? [AnyHashable]
        if 0 == (checkNames?.count ?? 0) {
            return false
        }
        var enumerator = (checkNames as NSArray?)?.objectEnumerator()
        for vo in valObjTable {
            if VOT_FUNC != vo.vtype {
                if vo.valueName != enumerator?.nextObject() as? String {
                    removeTempTrackerData()
                    return false
                }
            }
        }

        let loadData = NSArray(contentsOfFile: getTmpPath(TmpTrkrData)) as? [AnyHashable]
        if 0 == (loadData?.count ?? 0) {
            return false
        }
        enumerator = (loadData as NSArray?)?.objectEnumerator()
        for vo in valObjTable {
            if VOT_FUNC != vo.vtype {
                vo.value = enumerator?.nextObject() as? String ?? ""
            }
        }
        return true
    }

    func removeTempTrackerData() {
        _ = rTracker_resource.deleteFile(atPath: getTmpPath(TmpTrkrData))
        _ = rTracker_resource.deleteFile(atPath: getTmpPath(TmpTrkrNames))
    }

    // MARK: -
    // MARK: modify tracker object <-> db

    func resetData() {
        trackerDate = nil
        trackerDate = Date()

        for vo in valObjTable {
            vo.resetData()
            //[vo.value setString:@""];
        }
    }

    func updateValObj(_ valObj: valueObj) -> Bool {

        //NSEnumerator *enumer = [self.valObjTable objectEnumerator];
        //valueObj *vo;
        //while ( vo = (valueObj *) [enumer nextObject]) {
        for vo in valObjTable {
            if vo.vid == valObj.vid {
                //*vo = *valObj; // indirection cannot be to an interface in non-fragile ABI
                vo.vtype = valObj.vtype
                vo.valueName = valObj.valueName // property retain should keep these all ok w/o leaks
                //[vo.valueName setString:valObj.valueName];  // valueName not mutableString
                vo.value = valObj.value
                vo.display = valObj.display
                return true
            }
        }
        return false
    }

    func rescanMaxLabel() {

        var lsize = CGSize(width: 0.0, height: 0.0)

        for vo in valObjTable {
            let tsize = vo.getLabelSize()
            //DBGLog(@"rescanMaxLabel: name= %@ w=%f  h= %f",vo.valueName,tsize.width,tsize.height);
            if (VOT_INFO != vo.vtype) && (VOT_CHOICE != vo.vtype) && (VOT_SLIDER != vo.vtype) {

                if tsize.width > lsize.width {
                    lsize = tsize
                }
            }
            if tsize.height > lsize.height {
                // still need height for trackers with only choices and/or sliders
                lsize.height = tsize.height
            }
        }
        let placeholderWidth = "<enter number>".size(withAttributes: [
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)
        ]).width

        // Ensure minimum width for labels, but not more than 50% of screen width
        let kww5 = ceil(rTracker_resource.getKeyWindowWidth() / 3.0)
        if lsize.width < kww5 {
            lsize.width = kww5
        } else if lsize.width > rTracker_resource.getKeyWindowWidth() * 0.5 {
            // Limit label to 50% of screen width to ensure control has space
            lsize.width = rTracker_resource.getKeyWindowWidth() * 0.5
        }

        // Ensure there's always room for the placeholder text plus padding
        let screenWidth = rTracker_resource.getKeyWindowWidth()
        let maxWidth = screenWidth - (2 * MARGIN) - placeholderWidth - 16 // Added extra padding
        if lsize.width > maxWidth {
            lsize.width = maxWidth
        }

        //DBGLog(@"lsize.width %f maxWidth %f ss.width %f",lsize.width,maxWidth,screenSize.width);
        //DBGLog(@"maxLabel set: width %f  height %f",lsize.width, lsize.height);

        //[self.optDict setObject:[NSNumber numberWithFloat:lsize.width] forKey:@"width"];
        //[self.optDict setObject:[NSNumber numberWithFloat:lsize.height] forKey:@"height"];

        maxLabel = lsize
    }

    func addValObj(_ valObj: valueObj) {
        DBGLog(String("addValObj to \(trackerName) id= \(super.toid) : adding _\(valObj.valueName)_ id= \(Int(valObj.vid)), total items now \(UInt(valObjTable.count))"))

        // check if toid already exists, then update
        if !updateValObj(valObj) {
            valObjTable.append(valObj)
        }

        rescanMaxLabel()
    }

    func deleteTrackerDB() {
        deleteTDb()
    }
    
    func cleanDb() {
        var sql = "delete from trkrData where date not in (select date from voData)"
        toExecSql(sql: sql)
        sql = "delete from voData where date not in (select date from trkrData)"
        toExecSql(sql: sql)
    }

    func deleteTrackerRecordsOnly() {
        var sql = "delete from trkrData;"
        toExecSql(sql:sql)
        sql = "delete from voData;"
        toExecSql(sql:sql)
        sql = "delete from voHKstatus"
        toExecSql(sql:sql)
        sql = "delete from voOTstatus"
        toExecSql(sql:sql)
        //self.sql = nil;
    }

    func deleteCurrEntry() {
        let eDate = Int(trackerDate?.timeIntervalSince1970 ?? 0)
        var sql = "delete from trkrData where date = \(eDate);"
        toExecSql(sql:sql)
        sql = "delete from voData where date = \(eDate);"
        toExecSql(sql:sql)
        sql = "delete from voHKstatus where date = \(eDate);"
        toExecSql(sql:sql)
        sql = "delete from voOTstatus where date = \(eDate);"
        toExecSql(sql:sql)
        //self.sql = nil;
    }

    //load reminder data into trackerObj array from db
    func loadReminders() -> notifyReminder? {
        reminders.removeAll()
        //var rids: [AnyHashable] = []
        let sql = "select rid from reminders order by rid"
        let rids = toQry2AryI(sql: sql)
        DBGLog(String("toid \(super.toid) has \(rids.count) reminders in db"))
        if 0 < rids.count {
            for rid in rids {
                let tnr = notifyReminder(NSNumber(value:rid), to: self)
                reminders.append(tnr)
            }
            reminderNdx = 0
            return reminders[0]
        } else {
            reminderNdx = -1
            return nil
        }
    }

    func reminders2db() {
        var sql = "delete from reminders where rid not in ("
        var started = false
        for nr in reminders {
            let fmt = started ? ",%d" : "%d"
            sql = sql + String(format: fmt, nr.rid)
            started = true
        }
        sql = sql + ")"
        toExecSql(sql:sql)
        for nr in reminders {
            nr.save(self)
        }
    }

    func haveNextReminder() -> Bool {
        return reminderNdx < (reminders.count - 1)
    }

    func nextReminder() -> notifyReminder? {
        if haveNextReminder() {
            reminderNdx += 1
            return reminders[reminderNdx]
        }
        return nil
    }

    func havePrevReminder() -> Bool {
        return 0 < reminderNdx
    }

    func prevReminder() -> notifyReminder? {
        if havePrevReminder() {
            reminderNdx -= 1
            return reminders[reminderNdx]
        }
        return nil
    }

    func haveCurrReminder() -> Bool {
        return -1 != reminderNdx
    }

    func currReminder() -> notifyReminder? {
        if haveCurrReminder() {
            return reminders[reminderNdx]
        }
        return nil
    }

    func deleteReminder() {
        if haveCurrReminder() {
            //[(notifyReminder*) [self.reminders objectAtIndex:self.reminderNdx] delete:self];
            reminders.remove(at: reminderNdx)
            let last = reminders.count - 1
            if reminderNdx > last {
                reminderNdx = last
            }
        }
    }

    func add(_ newNR: notifyReminder?) {
        if let newNR {
            reminders.append(newNR)
        }
        if -1 == reminderNdx {
            reminderNdx = 0
        }
    }

    func save(_ saveNR: notifyReminder?) {
        if 0 == saveNR?.rid {
            saveNR?.rid = getUnique() // problem: this is only unique for this tracker, iOS UNUserNotificationCenter needs unique id for rTracker - use tid-rid
            reminderNdx += 1
        }
        if 0 == saveNR?.saveDate {
            saveNR?.saveDate = Int(Date().timeIntervalSince1970)
        } else {
            DBGLog(String("saveDate says \(Date(timeIntervalSince1970: TimeInterval(saveNR?.saveDate ?? 0)))"))
        }
        //[saveNR save:self];
        if reminderNdx == reminders.count {
            reminders.append(saveNR!)
        } else {
            reminders[reminderNdx] = saveNR!  // .setObject(saveNR, atIndexedSubscript: reminderNdx)
        }


        #if REMINDERDBG
        /*
        let today = Date()
        let gregorian = Calendar(identifier: .gregorian)
        // setReminder(saveNR, today: today, gregorian: gregorian)
         */
        #endif
    }

    func initReminderTable() {
        let sql = "create table if not exists reminders (rid int, monthDays int, weekDays int, everyMode int, everyVal int, start int, until int, flags int, times int, msg text, tid int, vid int, saveDate int, soundFileName text, unique(rid) on conflict replace)"
        toExecSql(sql:sql)
        // assume all old databsese updated by now.
        //sql = @"alter table reminders add column saveDate int";  // because versions released before reminders enabled but this was still called
        //[self toExecSqlIgnErr:sql];
        //sql = @"alter table reminders add column soundFileName text";  // because versions released before reminders enabled but this was still called
        //[self toExecSqlIgnErr:sql];
        //sql = nil;
    }

    // from ios docs date and time programming guide - Determining Temporal Differences
    func unitsWithinEra(from startDate: Date, to endDate: Date, calUnit: Calendar.Component, calendar: Calendar) -> Int {
        let startDay = calendar.ordinality(of: calUnit, in: .era, for: startDate) ?? 0
        let endDay = calendar.ordinality(of: calUnit, in: .era, for: endDate) ?? 0
        return endDay - startDay
    }

    func weekMonthDaysIsToday(_ nr: notifyReminder?, todayComponents: DateComponents?) -> Bool {
        if (0 != nr?.weekDays) && (0 == (Int(nr?.weekDays ?? 0) & (0x01 << ((todayComponents?.weekday ?? 0) - 1)))) {
            // weekday mode but not today
            return false
        } else if (0 != nr?.monthDays) && (0 == (Int(nr?.monthDays ?? 0) & (0x01 << ((todayComponents?.day ?? 0) - 1)))) {
            // monthday mode but not today
            return false
        }
        return true
    }
    
    func weekDaysAdjustedDate(baseDate: Date, weekDayBits: UInt8, timeSet: [Int]) -> Date? {
        let calendar = Calendar.current

        var dayAdd = 0
        while dayAdd < 8 {
            var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
            components.day! += dayAdd

            if let adjustedDate = calendar.date(from: components) {
                let updatedComponents = calendar.dateComponents([.weekday], from: adjustedDate)
                
                //print(updatedComponents)
                if (weekDayBits & (0x01 << (updatedComponents.weekday! - 1))) != 0 {
                    for startInt in timeSet {
                        let startHour = startInt / 60
                        let startMinute = startInt % 60

                        components = calendar.dateComponents([.year, .month, .day], from: adjustedDate)
                        components.hour = startHour
                        components.minute = startMinute
                        components.second = 0
                        
                        if let newDate = calendar.date(from: components), newDate > baseDate {
                            return newDate
                        }
                    }
                }
            }
            
            dayAdd += 1
        }

        return nil
    }


    func monthDaysAdjustedDate(baseDate: Date, monthDayBits: UInt32, timeSet: [Int]) -> Date? {
        let calendar = Calendar.current

        //var nextDate: Date?
        var monthAdd = 0
        while monthAdd < 2 {
            for day in 1...31 {
                if (monthDayBits & (0x01 << (day - 1))) != 0 {
                    for startInt in timeSet {
                        let startHour = startInt / 60
                        let startMinute = startInt % 60

                        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)
                        components.month! += monthAdd
                        components.hour = startHour
                        components.minute = startMinute
                        components.second = 0
                        components.day = day
                        
                        guard let newDate = calendar.date(from: components) else { continue }
                        let checkMonth = components.month! > 12 ? components.month! - 12 : components.month!
                        if calendar.component(.month, from: newDate) != checkMonth {
                            // month rolled over without monthAdd, that's wrong
                            continue
                        }
                        
                        if newDate > baseDate {
                            // nextDate = newDate
                            // break
                            return newDate
                        }
                    }
                }
            }
            monthAdd += 1
        }

        //return nextDate
        return nil
    }

    //
    // convert options set in notifyReminder to single target datetime for next reminder to fire
    //
    // 3rd 5th 7th 10th day of each month
    // every n hrs / days / weeks / months  <-- not directly supported but 'delay' below uses same values, so variable refer to 'every'
    // n mins / hrs / days / weeks / months delay from last save
    //  if days / weeks / months can set at time

    func getNextreminderDate(_ nr: notifyReminder?) -> Date? {
        guard nr != nil else {
            return nil
        }
        var sql: String
        // ensure we can set notifications or all pointless
        rTracker_resource.setNotificationsEnabled()
        
        // get single start time or list of times between start/until and equal interfals or random
        var timeSet:[Int] = []
        if !nr!.untilEnabled {
            timeSet.append(nr!.start)
        } else {
            if nr!.timesRandom {  // random
                var step = (nr!.until - nr!.start) / nr!.times
                step = step == 0 ? 1 : step
                var fin = nr!.start
                while fin < nr!.until {
                    let rnd = Double.random(in: 0...1)
                    let adjust = Int( d(step) * rnd)
                    timeSet.append(fin + adjust)
                    fin += step
                }
            } else {  // equal intervals
                var step = (nr!.until - nr!.start) / (nr!.times - 1)
                step = step == 0 ? 1 : step
                var fin = nr!.start
                while fin <= nr!.until {
                    timeSet.append(fin)
                    fin += step
                }
            }
            if timeSet.count != nr!.times {
                DBGWarn("reminders count [\(nr!.timesRandom ? "random" : "equal intervals")] wrong \(timeSet.count) should be \(nr!.times)")
            }
        }

        // start from now
        let todayNow = Date()
        var baseDate = todayNow
        
        // adjust forward if there is a saved 'start from' date
        let saveDate = Date(timeIntervalSince1970: TimeInterval(nr!.saveDate)) // default to when reminder created, but will be startFrom if set
        baseDate = saveDate > baseDate ? saveDate : baseDate

        // delay from last tracker/valobj entry
        if nr?.fromLast ?? false {
            var lastEntryDate:Date = Date.distantPast
            
            if nr?.vid != 0 {
                sql = String(format: "select date from voData where id=%ld order by date desc limit 1", Int(nr?.vid ?? 0))
            } else {
                sql = "select date from voData order by date desc limit 1"
            }
            let lastInt = toQry2Int(sql:sql)!
            if lastInt != 0 {
                lastEntryDate = Date(timeIntervalSince1970: TimeInterval(lastInt))
                var addUnits = nr?.everyVal ?? 0
                let evm = nr?.everyMode  // default is minutes
                switch(evm) {
                case UInt8(EV_WEEKS):
                    addUnits *= 7
                    fallthrough
                case UInt8(EV_DAYS):
                    addUnits *= 24
                    fallthrough
                case UInt8(EV_HOURS):
                    addUnits *= 60
                    lastEntryDate = Calendar.current.date(byAdding: .minute, value: addUnits, to: lastEntryDate) ?? lastEntryDate
                case UInt8(EV_MONTHS):
                    lastEntryDate = Calendar.current.date(byAdding: .month, value: addUnits, to: lastEntryDate) ?? lastEntryDate
                default:
                    break
                }
            }
            baseDate = lastEntryDate > baseDate ? lastEntryDate : baseDate
            
            if let wdb = nr?.weekDays {
                //  alternate to delay above is set of calendar days
                if let nextWeekDays = weekDaysAdjustedDate(baseDate: baseDate, weekDayBits: wdb, timeSet: timeSet) {
                    baseDate = nextWeekDays > baseDate ? nextWeekDays : baseDate
                }
            }
                
        } else if let mdb = nr?.monthDays {
            //  alternate to delay above is set of calendar days
            if let nextMonthDays = monthDaysAdjustedDate(baseDate: baseDate, monthDayBits: mdb, timeSet: timeSet) {
                baseDate = nextMonthDays > baseDate ? nextMonthDays : baseDate
            }
        }
        
        return baseDate > todayNow ? baseDate : nil
    }
    
    func setReminder(_ nr: notifyReminder?) {
        if let nextDate = getNextreminderDate(nr) {
            nr?.schedule(nextDate)
            DBGLog(String("finish setReminder targDate= \(DateFormatter.localizedString(from: nextDate, dateStyle: .full, timeStyle: .short))  now= \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))"))
        }
        DBGLog(String("done "))

    }

    //
    // remove all reminders set for this tracker.
    //
    // with change from UILocalNotification to UNNotification, could be more efficient
    // - just delete each matching notification with matching rid
    // or
    // - rely on setting notification with same ID updating previous notification
    //
    // but keeping old algorithm seems more robust against database being out of sync with previously set reminders
    // and would mean more code changes elsewhere.
    //

    func clearScheduledReminders() {
        let center = UNUserNotificationCenter.current()
        //NSMutableArray *toRemove = [notifyReminder getRidArray:center tid:self.toid];
        notifyReminder.useRidArray(center, tid: super.toid, callback: { toRemove in
            let rmIdStrs = toRemove.map { "\(super.toid)-\($0)" }
            center.removePendingNotificationRequests(withIdentifiers: rmIdStrs)
            DBGLog("removed identifiers \(rmIdStrs)")
        })
    }

    func setReminders() {

        // delete all reminders for this tracker
        clearScheduledReminders()
        // create unUserNotif here with access to nr data and tracker data

        _ = loadReminders()
        for nr in reminders {
            if nr.reminderEnabled {
                setReminder(nr)
            }
        }
        //[gregorian release];
    }

    func confirmReminders() {

        let center = UNUserNotificationCenter.current()
        //NSMutableArray *ridSet = [notifyReminder getRidArray:center tid:self.toid];
        notifyReminder.useRidArray(center, tid: super.toid, callback: { [self] ridSet in
            _ = loadReminders()
            for nr in reminders {
                if nr.reminderEnabled && !(ridSet.contains( String(nr.rid))) {
                    //[self setReminder:nr today:today gregorian:gregorian];
                    setReminder(nr)
                }
            }
        })
        //[gregorian release];
    }

    func enabledReminderCount() -> Int {
        var c = 0

        _ = loadReminders()
        for nr in reminders {
            if nr.reminderEnabled {
                c += 1
            }
        }

        return c
    }

    // MARK: -
    // MARK: query tracker methods

    func dateNearest(_ targ: Int) -> Int {
        var sql = String(format: "select date from trkrData where date <= %ld and minpriv <= %d order by date desc limit 1;", targ, privacyValue)
        var rslt = toQry2Int(sql:sql)!
        if 0 == rslt {
            sql = String(format: "select date from trkrData where date > %ld and minpriv <= %d order by date desc limit 1;", targ, privacyValue)
            rslt = toQry2Int(sql:sql)!
        }
        //self.sql = nil;
        return rslt
    }

    func prevDate() -> Int {
        let sql = "select date from trkrData where date < \(Int(trackerDate?.timeIntervalSince1970 ?? 0)) and minpriv <= \(privacyValue) order by date desc limit 1;"
        let rslt = toQry2Int(sql:sql)!
        DBGLog(String("curr: \(trackerDate) prev: \(Date(timeIntervalSince1970: TimeInterval(rslt)))"))
        //self.sql = nil;
        return rslt
    }

    func postDate() -> Int {
        let sql = "select date from trkrData where date > \(Int(trackerDate?.timeIntervalSince1970 ?? 0)) and minpriv <= \(privacyValue) order by date asc limit 1;"
        let rslt = toQry2Int(sql:sql)!
        //self.sql = nil;
        return rslt
    }

    func lastDate() -> Int {
        let sql = "select date from trkrData where minpriv <= \(privacyValue) order by date desc limit 1;"
        let rslt = toQry2Int(sql:sql)!
        //self.sql = nil;
        return rslt
    }

    func firstDate() -> Int {
        let sql = "select date from trkrData where minpriv <= \(privacyValue) order by date asc limit 1;"
        let rslt = toQry2Int(sql:sql)!
        //self.sql = nil;
        return rslt
    }

    func voGetName(forVID vid: Int) -> String? {
        for vo in valObjTable {
            if vo.vid == vid {
                return vo.valueName
            }
        }
        DBGLog(String("voGetNameForVID \(vid) failed"))
        //return [NSString stringWithFormat:@"vid %d not found",vid];
        return "not configured yet"
    }

    func voGetType(forVID vid: Int) -> Int {
        for vo in valObjTable {
            if vo.vid == vid {
                return vo.vtype
            }
        }
        DBGLog(String("voGetNameForVID \(vid) failed"))
        //return [NSString stringWithFormat:@"vid %d not found",vid];
        return -1
    }

    /*  precludes musltiple vo with same name
    - (NSInteger) voGetVIDforName:(NSString *)vname {
    	for (valueObj *vo in self.valObjTable) {
    		if ([vo.valueName isEqualToString:vname])
    			return vo.vid;
    	}
    	DBGLog(@"voGetVIDNameForName failed for name %@",vname);
    	//return [NSString stringWithFormat:@"vid %d not found",vid];
        return 0;
    }<#(NSUInteger)#>
    */

    func updateVIDinFns(_ old: Int, new: Int) {
        let oldstr = String(format: "%ld", old)
        let newstr = String(format: "%ld", new)
        for vo in valObjTable {
            if VOT_FUNC == vo.vtype {
                var fnstr = vo.optDict["func"]

                var fMarray: [String]? = nil
                if let componentsSeparated = fnstr?.components(separatedBy: " ") {
                    fMarray = componentsSeparated
                }
                var c: Int
                c = fMarray?.count ?? 0
                for i in 0..<c {
                    if oldstr == fMarray?[i] {
                        fMarray?[i] = newstr
                    }
                }
                fnstr = fMarray?.joined(separator: " ")
                vo.optDict["func"] = fnstr


                let sql = String(format: "update voInfo set val='%@' where id=%ld and field='func'", fnstr ?? "", vo.vid) // keep consistent
                toExecSql(sql:sql)
            }
        }

    }

    func voVIDisUsed(_ vid: Int) -> Bool {
        for vo in valObjTable {
            if vo.vid == vid {
                return true
            }
        }
        return false
    }

    func voUpdateVID(_ vo: valueObj?, newVID: Int) {

        if vo?.vid == newVID {
            return
        }

        for tvo in valObjTable {
            if tvo.vid == newVID {
                voUpdateVID(tvo, newVID: getUnique())
            }
        }

        // need to update at least voData, will write voInfo, voConfing out later but lets stay consistent
        var sql = String(format: "update voData set id=%ld where id=%ld", newVID, Int(vo?.vid ?? 0))
        toExecSql(sql:sql)
        sql = String(format: "update voInfo set id=%ld where id=%ld", newVID, Int(vo?.vid ?? 0))
        toExecSql(sql:sql)
        sql = String(format: "update voConfig set id=%ld where id=%ld", newVID, Int(vo?.vid ?? 0))
        toExecSql(sql:sql)
        sql = String(format: "update reminders set vid=%ld where vid=%ld", newVID, Int(vo?.vid ?? 0))
        toExecSql(sql:sql)

        //self.sql = nil;


        updateVIDinFns(vo?.vid ?? 0, new: newVID)
        DBGLog(String("changed \(Int(vo?.vid ?? 0)) to \(newVID)"))
        vo?.vid = newVID
    }

    func voHasData(_ vid: Int) -> Bool {
        let sql = "select count(*) from voData where id=\(vid);"
        let rslt = toQry2Int(sql:sql)
        //self.sql = nil;

        if rslt == 0 {
            return false
        }
        return true
    }

    func checkData() -> Bool {
        // does a contained valObj have stored data?
        for vo in valObjTable {
            if voHasData(vo.vid) {
                return true
            }
        }
        return false
    }

    func hasData() -> Bool {
        // is there a date entry in trkrData matching current trackerDate ?
        let sql = "select count(*) from trkrData where date=\(Int(trackerDate?.timeIntervalSince1970 ?? 0))"
        let r = toQry2Int(sql:sql)
        //self.sql = nil;
        return r != 0
    }

    func countEntries() -> Int {
        let sql = "select count(*) from trkrData;"
        let r = toQry2Int(sql:sql)!
        //self.sql = nil;
        return r
    }

    func noCollideDate(_ ptestDate: Int) -> Int {
        var going = true
        var sql: String
        var testDate = ptestDate
        while going {
            sql = "select count(*) from trkrData where date=\(testDate)"
            if toQry2Int(sql:sql) == 0 {
                going = false
            } else {
                testDate += 1
            }
        }
        //self.sql = nil;
        return testDate
    }

    func change(_ newDate: Date?) {
        if 0 == changedDateFrom {
            changedDateFrom = Int(trackerDate?.timeIntervalSince1970 ?? 0)
        }
        let ndi = noCollideDate(Int(newDate?.timeIntervalSince1970 ?? 0))
        //int odi = (int) [self.trackerDate timeIntervalSince1970];
        //self.sql = [NSString stringWithFormat:@"update trkrData set date=%d where date=%d;",ndi,odi];
        //[self toExecSql:sql];
        //self.sql = [NSString stringWithFormat:@"update voData set date=%d where date=%d;",ndi,odi];
        //[self toExecSql:sql];
        //self.sql=nil;
        trackerDate = Date(timeIntervalSince1970: TimeInterval(ndi)) // might have changed to avoid collision
    }

    // MARK: value data updated event handling

    // handle rtValueUpdatedNotification
    // sends rtTrackerUpdatedNotification

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
        DBGLog(String("tracker id \(super.toid) name \(trackerName ?? "") dbName \(dbName ?? "")"))
        DBGLog(
            String("db ver \(optDict["rtdb_version"] ?? "") fn ver \(optDict["rtfn_version"] ?? "") created by rt ver \(optDict["rt_version"] ?? "") build \(optDict["rt_build"] ?? "")"))
        //NSEnumerator *enumer = [self.valObjTable objectEnumerator];
        //valueObj *vo;
        //while ( vo = (valueObj *) [enumer nextObject]) {
        for vo in valObjTable {
            vo.describe(false)
        }




    }

    func setFnVals() {
        // leave early if no functions here
        var haveFn = false
        for vo: valueObj in valObjTable {
            if VOT_FUNC == vo.vtype {
                haveFn = true
                break
            }
        }
        if (!haveFn) { return }
                
        let currDate = Int(trackerDate?.timeIntervalSince1970 ?? 0)
        var nextDate = firstDate()

        if 0 == nextDate {
            // no data yet for this tracker so do not generate a 0 value in database
            return
        }

        var ndx: Float = 1.0
        let all = Float(getDateCount())

        repeat {
            _ = loadData(nextDate)
            for vo: valueObj in valObjTable {
                    vo.vos?.setFnVals(nextDate)
            }

            //safeDispatchSync(^{
            //dispatch_async(dispatch_get_main_queue(), ^{
            rTracker_resource.setProgressVal(ndx / all)
            //});
            ndx += 1.0
            nextDate = postDate()
        } while (nextDate != 0) // iterate through dates

        for vo in valObjTable {
            if VOT_FUNC == vo.vtype {
                vo.vos?.doTrimFnVals()
            }
        }

        // restore current date
        _ = loadData(currDate)
    }

    func recalculateFns() {
        DBGLog("try atomic set recalcFnLock")
        if recalcFnLock.testAndSet(newValue: true) {
            // wasn't 0 before, so we didn't get lock, so leave because shake handling already in process
            return
        }

        DBGLog(String("tracker id \(super.toid) name \(trackerName) dbname \(dbName) recalculateFns"))

        rTracker_resource.setProgressVal(0.0)
        setFnVals()

        if goRecalculate {
            optDict.removeValue(forKey: "dirtyFns")
            let sql = "delete from trkrInfo where field='dirtyFns';"
            toExecSql(sql:sql)

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

//#import <stdlib.h>
//#import <NSNotification.h>

//#import <libkern/OSAtomic.h>  // deprecated ios 10
