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

protocol RefreshProgressDelegate: AnyObject {
    func updateFullRefreshProgress(step: Int, phase: String?)
}

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
    
    weak var refreshDelegate: RefreshProgressDelegate?
    
    var trackerDate: Date?
    var lastDbDate: Int = 0
    
    var optDict: [String : Any] = [:]  // trackerObj level optDict in dtabase as text : any

    var valObjTable: [valueObj] = []
    var valObjTableH: [valueObj] = []

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
        if _nextColor >= rTracker_resource.colorSet.count {
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
    
    // Add this method to trackerObj for explicit progress reporting
    func reportProgressPhase(_ phase: String) {
        DBGLog("[\(Date())] Explicitly reporting progress phase: \(phase)")
        
        // Check if we're already on the main thread
        if Thread.isMainThread {
            // Execute directly
            refreshDelegate?.updateFullRefreshProgress(step: 0, phase: phase)
            
            // Force UI updates
            if let controller = refreshDelegate as? UIViewController {
                controller.view.setNeedsLayout()
                controller.view.layoutIfNeeded()
            }
        } else {
            // Force execution on main thread and wait for it to complete
            DispatchQueue.main.async {
                self.refreshDelegate?.updateFullRefreshProgress(step: 0, phase: phase)
                
                // Force UI updates
                if let controller = self.refreshDelegate as? UIViewController {
                    controller.view.setNeedsLayout()
                    controller.view.layoutIfNeeded()
                }
            }
        }
        
        // Small delay to allow UI to refresh - only use a small sleep on background threads
        if !Thread.isMainThread {
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        DBGLog("Phase report complete for: \(phase)")
    }
    
    func loadHKdata(forDate date: Int? = nil, dispatchGroup: DispatchGroup?, completion: (() -> Void)? = nil) -> Bool {
        // Report explicit phase update at the start
        if dispatchGroup == nil && refreshDelegate != nil {
            reportProgressPhase("Loading HealthKit data")
        }
        dispatchGroup?.enter()
        let localGroup = DispatchGroup()
        var rslt = false
        var hkValueObjIDs: [Int] = []
        for vo in valObjTable {
            if vo.optDict["ahksrc"] ?? "0" != "0" {
                hkValueObjIDs.append(vo.vid)
                vo.vos?.loadHKdata(forDate: date, dispatchGroup: localGroup)
                rslt = true
            }
        }
        // Wait for our local operations to complete before calling completion
        localGroup.notify(queue: .main) {
            
            // processing multiple
            if hkValueObjIDs.count > 1 {
                // Convert Int array to comma-separated string for SQL
                let hkVidsList = hkValueObjIDs.map { String($0) }.joined(separator: ",")
                
                #if DEBUGLOG
                //---------------------------------------------------------
                let countMissingSQL = """
                SELECT COUNT(*) FROM (
                    SELECT d.date, v.id as vid
                    FROM 
                        (SELECT DISTINCT date FROM voHKstatus WHERE id IN (\(hkVidsList))) d,
                        (SELECT DISTINCT id FROM voHKstatus WHERE id IN (\(hkVidsList))) v
                    WHERE NOT EXISTS (
                        SELECT 1 FROM voHKstatus 
                        WHERE voHKstatus.id = v.id
                        AND voHKstatus.date = d.date
                    )
                )
                """
                let missingCount = self.toQry2Int(sql: countMissingSQL)
                DBGLog("need to add \(missingCount) noData records")
                //---------------------------------------------------------
                #endif
                
                // This query finds all combinations of (HK valueObj ID, date with HK data)
                // where a voHKstatus entry doesn't exist, and creates entries for them
                let ensureStatusSQL = """
                            INSERT INTO voHKstatus (id, date, stat)
                            SELECT vid, date, \(hkStatus.noData.rawValue)
                            FROM (
                                SELECT d.date, v.id as vid
                                FROM 
                                    (SELECT DISTINCT date FROM voHKstatus WHERE id IN (\(hkVidsList))) d,
                                    (SELECT DISTINCT id FROM voHKstatus WHERE id IN (\(hkVidsList))) v
                                WHERE NOT EXISTS (
                                    SELECT 1 FROM voHKstatus 
                                    WHERE voHKstatus.id = v.id
                                    AND voHKstatus.date = d.date
                                )
                            )
                            """
                //DBGLog(ensureStatusSQL)
                self.toExecSql(sql: ensureStatusSQL)
                //DBGLog("Added voHKstatus entries for all dates in trkrData for all HK valueObjs")
            }
            
            // Update progress after all HealthKit processing is done
            self.refreshDelegate?.updateFullRefreshProgress(step: hkValueObjIDs.count, phase: nil)
            
            completion?()
            dispatchGroup?.leave()
        }
        return rslt
    }

    func mergeDates(inDates:[TimeInterval], set12: Bool = true) -> [TimeInterval] {
        let existingDatesQuery = "SELECT date FROM trkrData order by date DESC"
        
        let existingDatesArr = toQry2AryI(sql: existingDatesQuery)  // for debug to look at
        let existingDates = Set(existingDatesArr)
        
        let calendar = Calendar.current
        var newDates: [TimeInterval]
        
        /*
         // Filter dates that don't match within ±4 hours of existing dates
         let fourHours: TimeInterval = 4 * 60 * 60
         let newDates = hkDates.filter { hkDate in
         !existingDates.contains { abs(hkDate - Double($0)) <= fourHours }
         }
         */
        
        
        // find dates that are not on the same calendar day as any existing dates
        // because prefer to use existing times if possible, not 12:00
        // also remove today if present because today's data shown on current tracker not saved yet
        newDates = inDates.filter { inDate in
            // First check if it's not today
            !calendar.isDateInToday(Date(timeIntervalSince1970: inDate)) &&
            // Then check if it's not already in existing dates
            !existingDates.contains { existingDate in
                calendar.isDate(Date(timeIntervalSince1970: inDate), inSameDayAs: Date(timeIntervalSince1970: Double(existingDate)))
            }
        }
        
        if (set12) {
            // set all times to 12:00 noon
            let adjustedDates = newDates.map { inDate in
                var components = calendar.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: inDate))
                components.hour = 12
                components.minute = 0
                components.second = 0
                return calendar.date(from: components)?.timeIntervalSince1970 ?? inDate
            }
            
            
            // restrict any times in future to now
            let now = Date()
            newDates = adjustedDates.map { timeInterval -> TimeInterval in
                let ndate = Date(timeIntervalSince1970: timeInterval)
                if ndate > now {
                    return now.timeIntervalSince1970 // Change to the current time
                }
                // If not in the future, keep the original time
                return timeInterval
            }
        }
        return newDates
    }
    
    func loadOTdates(forDate date: Int? = nil) {
        // instantiate trkrData dates for external trackers
        for vo in self.valObjTable {
            guard vo.optDict["otsrc"] ?? "0" != "0",
                  let otTracker = vo.optDict["otTracker"],
                  let otValue = vo.optDict["otValue"] else { continue }
            
            let xto = trackerObj(trackerList.shared.getTIDfromNameDb(otTracker)[0])
            
            let xvid: Int
            if otValue != OTANYNAME {
                let tempxvid = xto.toQry2Int(sql: "select id from voConfig where name = '\(otValue)'")
                if tempxvid == 0 {
                    DBGErr("no xvid for other tracker \(otTracker) valueObj \(otValue)")
                    continue
                }
                xvid = tempxvid
            } else {
                xvid = -1
            }
            let sql = "select max(date) from voOTstatus where id = \(Int(vo.vid)) and stat = \(otStatus.otData.rawValue)"
            let lastDate = toQry2Int(sql: sql)
            
            if (otTracker != self.trackerName) {
                let selStr: String
                if otValue == OTANYNAME {
                    selStr = "trkrData where"
                } else {
                    selStr = "voData where id = \(xvid) and"
                }
                
                var myDates: [Int]
                
                // get all local tracker dates to populate
                if let specificDate = date {
                    // If a specific date is provided, only query that date and if it exists
                    myDates = xto.toQry2AryI(sql: "select date from \(selStr) date = \(specificDate)")
                } else {
                    // Original implementation - get all dates after lastDate
                    myDates = xto.toQry2AryI(sql: "select date from \(selStr) date > \(lastDate) order by date asc")
                }
                
                let newDates = self.mergeDates(inDates: myDates.map { TimeInterval($0) }, set12:false)
                
                // Insert the new dates into trkrData
                // trkrData is 'on conflict replace'
                // but should only be adding new dates
                let priv = max(MINPRIV, vo.vpriv)  // priv needs to be at least minpriv if vpriv = 0
                for newDate in newDates {
                    let sql = "insert into trkrData (date, minpriv) values (\(Int(newDate)), \(priv))"
                    toExecSql(sql: sql)
                }
                
                DBGLog("Inserted \(newDates.count) new dates into trkrData.")
            }
        }
    }
    
    func loadOTdata(forDate date: Int? = nil, otSelf: Bool = false, dispatchGroup: DispatchGroup?, completion: (() -> Void)? = nil) -> Bool {
        // Report phase update at the start
        if dispatchGroup == nil && refreshDelegate != nil {
            if otSelf {
                reportProgressPhase("Finishing up...")
            } else {
                reportProgressPhase("Loading data from other trackers")
            }
        }
        
        dispatchGroup?.enter()
        
        // Key change: Create a dedicated queue for OT processing
        let otProcessingQueue = DispatchQueue(label: "com.rtracker.otProcessing", qos: .userInitiated)
        
        var rslt = false
        var otValueObjCount = 0
        let localGroup = DispatchGroup()
        
        // Count OT value objects first for progress tracking
        for vo in valObjTable {
            guard vo.optDict["otsrc"] ?? "0" != "0",
                  let otTracker = vo.optDict["otTracker"] else { continue }
            if (otSelf && otTracker == trackerName) ||
               (!otSelf && otTracker != trackerName) {
                otValueObjCount += 1
                rslt = true
            }
        }
        DBGLog("OT value objects to process: \(otValueObjCount)")
        
        // Start background processing
        otProcessingQueue.async { [weak self] in
            guard let self = self else {
                dispatchGroup?.leave()
                completion?()
                return
            }
            
            loadOTdates(forDate: date)
                    
            // Track processed values for progress updates
            var processedCount = 0
            
            // Process each value object in the background
            for vo in self.valObjTable {
                guard vo.optDict["otsrc"] ?? "0" != "0",
                      let otTracker = vo.optDict["otTracker"] else { continue }
                
                if (otSelf && otTracker == self.trackerName) ||
                   (!otSelf && otTracker != self.trackerName) {
                    
                    vo.vos?.loadOTdata(forDate: date, dispatchGroup: localGroup)
                    
                    // Update progress periodically
                    processedCount += 1
                    
                    // Batch updates to avoid overwhelming the main thread
                    if processedCount % 5 == 0 || processedCount == otValueObjCount {
                        DispatchQueue.main.async {
                            self.refreshDelegate?.updateFullRefreshProgress(step: processedCount % 5 == 0 ? 5 : processedCount % 5, phase: nil)
                        }
                        
                        // Small yield to give main thread breathing room
                        if processedCount % 5 == 0 {
                            Thread.sleep(forTimeInterval: 0.01)
                        }
                    }
                }
            }
            
            // Final updates on main thread
            DispatchQueue.main.async {
                // Update progress after all OtherTracker processing is done
                self.refreshDelegate?.updateFullRefreshProgress(step: 1, phase: nil)
                
                // Call completion and leave dispatch group
                completion?()
                dispatchGroup?.leave()
            }
        }
        
        return rslt
    }
    // Helper class to track processing state
    private class ProcessingState {
        var currentDate: Int
        var datesProcessed = 0
        let totalDates: Int
        
        init(startDate: Int, totalDates: Int) {
            self.currentDate = startDate
            self.totalDates = totalDates
        }
    }

    private func processFnData(forDate date: Int? = nil, dispatchGroup: DispatchGroup? = nil, forceAll: Bool = false, completion: (() -> Void)? = nil) -> Bool {
        // Diagnostic step 1: Verify delegate is set
        DBGLog("[\(Date())] processFnData called - refreshDelegate is \(refreshDelegate != nil ? "SET" : "NOT SET!")")
        // Report phase update before background processing begins
        if dispatchGroup == nil && refreshDelegate != nil {
            reportProgressPhase("Computing functions")
        }
        
        //let localGroup = DispatchGroup()
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
        } else if let specifiedDate = date {
            nextDate = specifiedDate
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
        
        // Key change: Create a dedicated queue for function processing
        let functionProcessingQueue = DispatchQueue(label: "com.rtracker.functionProcessing", qos: .userInitiated)
        
        // Create a state object to track progress
        let progressState = ProcessingState(startDate: nextDate, totalDates: getDateCount())
        
        // Start background processing
        functionProcessingQueue.async { [weak self] in
            guard let self = self else {
                dispatchGroup?.leave()
                completion?()
                return
            }
            
            // Process each date in the background
            repeat {
                autoreleasepool {
                    // Load data for this date and process functions
                    _ = self.loadData(progressState.currentDate)  // does nothing if date not in db, so leaves curent gui settings
                    
                    for vo in self.valObjTable {
                        vo.vos?.setFNrecalc()  // do not use cached values
                        vo.vos?.setFnVal(progressState.currentDate)  // Use synchronous version since we're already on a background thread
                    }
                    
                    // Update progress (every 5 dates or so to avoid too many UI updates)
                    progressState.datesProcessed += 1
                    if progressState.datesProcessed % 5 == 0 {
                        DispatchQueue.main.async {
                            self.refreshDelegate?.updateFullRefreshProgress(step: 5, phase: nil)
                        }
                        
                        // Small yield to give main thread breathing room
                        Thread.sleep(forTimeInterval: 0.01)
                    }
                    
                    // Move to next date
                    progressState.currentDate = self.postDate()
                }
            } while (progressState.currentDate != 0) // iterate through dates
            
            // Final cleanup on main thread
            DispatchQueue.main.async {
                // Clean up and trim function values
                for vo in self.valObjTable {
                    vo.vos?.doTrimFnVals()
                }
                
                // Restore current date
                _ = self.loadData(currDate)  // does nothing if no db data for currDate
                
                // Clear dirty flag
                self.optDict.removeValue(forKey: "dirtyFns")
                let sql = "delete from trkrInfo where field='dirtyFns';"
                self.toExecSql(sql: sql)
                
                // Update progress after function calculations
                self.refreshDelegate?.updateFullRefreshProgress(step: progressState.datesProcessed, phase: nil)
                
                // Set result and call completion
                rslt = true
                completion?()
                dispatchGroup?.leave()
            }
        }
        
        return rslt
    }

    func loadFNdata(forDate date: Int? = nil, dispatchGroup: DispatchGroup?, completion: (() -> Void)? = nil) -> Bool {
        return processFnData(forDate: date, dispatchGroup: dispatchGroup, forceAll: false, completion: completion)
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

        //DBGLog(String("tObj loadConfig toid:\(super.toid)"))

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

        //DBGLog(String("to optdict: \(optDict)"))

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
        if nextColor >= rTracker_resource.colorSet.count {
            _nextColor = 0
        }

        valObjTableH = []
        for vo in valObjTable {
            if vo.optDict["hidden"] != "1" {
                valObjTableH.append(vo)
            }
        }


        //sql = nil;

        trackerDate = nil
        trackerDate = Date()
        rescanMaxLabel()
        
        DBGLog("loaded \(trackerName ?? "nil") \(dbName ?? "nil") \(valObjTable.count) valObjs \(reminders.count) reminders")
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

        DBGLog(String("tObj loadConfigFromDict toid:\(super.toid) name:\(trackerName ?? "nil")"))

        let voda = dict["valObjTable"] as? [AnyHashable]
        for vod in voda ?? [] {
            guard let vod = vod as? [String : Any] else {
                continue
            }
            let vo = valueObj(dict: self, dict: vod)
            DBGLog(String("add vo \(vo.valueName ?? "nil")"))
            valObjTable.append(vo)
        }

        for vo in valObjTable {

            if vo.vcolor > _nextColor {
                _nextColor = vo.vcolor
            }

            vo.vos?.setOptDictDflts()
            vo.vos?.loadConfig() // loads from vo optDict
        }

        valObjTableH = []
        for vo in valObjTable {
            if vo.optDict["hidden"] != "1" {
                valObjTableH.append(vo)
            }
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
        if _nextColor >= rTracker_resource.colorSet.count {
            _nextColor = 0
        }

        //sql = nil;

        trackerDate = nil
        trackerDate = Date()
        //DBGLog(String("loadConfigFromDict finished loading \(trackerName)"))
    }
    
    func streakCount() -> Int {
        
        // Check if most recent entry is too old (streak should be broken)

        let now = Date()
        let mostRecentQuery = "SELECT MAX(date) FROM trkrData"
        let mostRecentTimestamp = toQry2Int(sql: mostRecentQuery)
        
        if mostRecentTimestamp > 0 {
            let mostRecentDate = Date(timeIntervalSince1970: TimeInterval(mostRecentTimestamp))
            let timeSinceLastEntry = now.timeIntervalSince(mostRecentDate)
            let daysSinceLastEntry = timeSinceLastEntry / (24.0 * 60.0 * 60.0)
            
            if daysSinceLastEntry > 1.5 {
                return 0
            }
        } else {
            return 0
        }

        /*
        
        // Step 1: Debug raw data from trkrData
        DBGLog("=== STREAK DEBUG: Raw trkrData entries ===")
        let rawDataQuery = "SELECT date, datetime(date, 'unixepoch') as readable_date FROM trkrData ORDER BY date DESC LIMIT 10"
        let rawData = toQry2AryIS(sql: rawDataQuery)
        for (date, readableDate) in rawData {
            DBGLog("Raw entry - Unix timestamp: \(date), Human readable: \(readableDate)")
        }
        
        // Step 1.5: Check if most recent entry is too old (streak should be broken)
        DBGLog("=== STREAK DEBUG: Current time vs most recent entry ===")
        let now = Date()
        let nowTimestamp = Int(now.timeIntervalSince1970)
        DBGLog("Current time: \(now) (timestamp: \(nowTimestamp))")
        
        let mostRecentQuery = "SELECT MAX(date) FROM trkrData"
        let mostRecentTimestamp = toQry2Int(sql: mostRecentQuery)
        
        if mostRecentTimestamp > 0 {
            let mostRecentDate = Date(timeIntervalSince1970: TimeInterval(mostRecentTimestamp))
            let timeSinceLastEntry = now.timeIntervalSince(mostRecentDate)
            let daysSinceLastEntry = timeSinceLastEntry / (24.0 * 60.0 * 60.0)
            
            DBGLog("Most recent entry: \(mostRecentDate) (timestamp: \(mostRecentTimestamp))")
            DBGLog("Time since last entry: \(timeSinceLastEntry) seconds = \(daysSinceLastEntry) days")
            
            if daysSinceLastEntry > 1.5 {
                DBGLog("*** STREAK BROKEN: Last entry is \(daysSinceLastEntry) days old (> 1.5 days) ***")
                DBGLog("=== STREAK DEBUG: Final result = 0 (streak expired) ===")
                return 0
            } else {
                DBGLog("Streak still active: Last entry is only \(daysSinceLastEntry) days old (<= 1.5 days)")
            }
        } else {
            DBGLog("No entries found in trkrData")
            return 0
        }
        
        // Step 2: Debug daily_entries CTE
        DBGLog("=== STREAK DEBUG: Daily entries (after grouping) ===")
        let dailyEntriesQuery = """
            SELECT 
                date(datetime(date, 'unixepoch')) as entry_date,
                count(*) as entries_count
            FROM trkrData
            GROUP BY entry_date
            ORDER BY entry_date DESC
            LIMIT 15
        """
        let dailyEntries = toQry2ArySI(sql: dailyEntriesQuery)
        for (entryDate, count) in dailyEntries {
            DBGLog("Daily entry: \(entryDate), Count: \(count)")
        }
        
        // Step 3: Debug date_gaps CTE  
        DBGLog("=== STREAK DEBUG: Date gaps calculation ===")
        let dateGapsQuery = """
            WITH daily_entries AS (
                SELECT 
                    date(datetime(date, 'unixepoch')) as entry_date
                FROM trkrData
                GROUP BY entry_date
            )
            SELECT 
                entry_date,
                COALESCE(CAST(julianday(entry_date) - 
                julianday(lag(entry_date, 1) OVER (ORDER BY entry_date)) AS TEXT), 'NULL') as gap_text
            FROM daily_entries
            ORDER BY entry_date DESC
            LIMIT 15
        """
        let dateGaps = toQry2ArySS(sql: dateGapsQuery) // Using SS since gap might be null for first entry
        for (entryDate, gapStr) in dateGaps {
            let gap = gapStr == "NULL" ? "NULL (first entry)" : gapStr
            DBGLog("Date: \(entryDate), Gap from previous: \(gap)")
        }
        
        // Step 4: Debug streak_groups CTE
        DBGLog("=== STREAK DEBUG: Streak groups ===")
        let streakGroupsQuery = """
            WITH daily_entries AS (
                SELECT 
                    date(datetime(date, 'unixepoch')) as entry_date
                FROM trkrData
                GROUP BY entry_date
            ),
            date_gaps AS (
                SELECT 
                    entry_date,
                    julianday(entry_date) - 
                    julianday(lag(entry_date, 1) OVER (ORDER BY entry_date)) as gap
                FROM daily_entries
                ORDER BY entry_date DESC
            )
            SELECT 
                entry_date,
                COALESCE(CAST(gap AS TEXT), 'NULL') as gap_text,
                CASE WHEN gap > 1.5 THEN 1 ELSE 0 END as is_break,
                sum(CASE WHEN gap > 1.5 THEN 1 ELSE 0 END) 
                    OVER (ORDER BY entry_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as streak_group
            FROM date_gaps
            ORDER BY entry_date DESC
            LIMIT 20
        """
        let streakGroups = toQry2ArySSSI(sql: streakGroupsQuery)
        for (entryDate, gapStr, isBreakStr, streakGroup) in streakGroups {
            DBGLog("Date: \(entryDate), Gap: \(gapStr), IsBreak: \(isBreakStr), StreakGroup: \(streakGroup)")
        }
        
        // Step 5: Debug final count for group 0
        DBGLog("=== STREAK DEBUG: Group 0 count (current streak) ===")
        let group0CountQuery = """
            WITH daily_entries AS (
                SELECT 
                    date(datetime(date, 'unixepoch')) as entry_date
                FROM trkrData
                GROUP BY entry_date
            ),
            date_gaps AS (
                SELECT 
                    entry_date,
                    julianday(entry_date) - 
                    julianday(lag(entry_date, 1) OVER (ORDER BY entry_date)) as gap
                FROM daily_entries
                ORDER BY entry_date DESC
            ),
            streak_groups AS (
                SELECT 
                    entry_date,
                    sum(CASE WHEN gap > 1.5 THEN 1 ELSE 0 END) 
                        OVER (ORDER BY entry_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as streak_group
                FROM date_gaps
            )
            SELECT entry_date, streak_group
            FROM streak_groups
            WHERE streak_group = 0
            ORDER BY entry_date DESC
        """
        let group0Entries = toQry2ArySI(sql: group0CountQuery)
        DBGLog("Entries in current streak (group 0):")
        for (entryDate, streakGroup) in group0Entries {
            DBGLog("  \(entryDate) (group \(streakGroup))")
        }
        
        // Original query unchanged
         */
        let queryStreak = """
            WITH daily_entries AS (
                SELECT 
                    date(datetime(date, 'unixepoch')) as entry_date,
                    date(datetime(date, 'unixepoch')) as calendar_date
                FROM trkrData
                GROUP BY entry_date
            ),
            date_gaps AS (
                SELECT 
                    entry_date,
                    julianday(entry_date) - 
                    julianday(lag(entry_date, 1) OVER (ORDER BY entry_date)) as gap
                FROM daily_entries
                ORDER BY entry_date DESC
            ),
            streak_groups AS (
                SELECT 
                    entry_date,
                    sum(CASE WHEN gap > 1.5 THEN 1 ELSE 0 END) 
                        OVER (ORDER BY entry_date DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as streak_group
                FROM date_gaps
            )
            SELECT count(*) as streak_count
            FROM streak_groups
            WHERE streak_group = 0
        """
        
        let result = toQry2Int(sql: queryStreak)
        DBGLog("=== STREAK DEBUG: Final result = \(result) ===")
        
        return result
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

        let vot = rTracker_resource.vtypeNames.firstIndex(of: vots ?? "") ?? NSNotFound // [self.votArray indexOfObject:vots];
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
            voc = rTracker_resource.colorNames.firstIndex(of: vocs ?? "") ?? NSNotFound
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

        var sql = String(format: "select count(*) from trkrData where date = %ld and minpriv <= %d;", iDate, privacyValue)
        let c = toQry2Int(sql:sql)
        if c != 0 {
            resetData()
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
        let count = toQry2Int(sql: "select count(*) from trkrData")
        DBGLog(String("tracker \(trackerName ?? "") has \(count) data entries"))
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

