//
//  trackerObjDbCsv.swift
//  rTracker
//
//  Created by Robert Miller on 08/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import Foundation

extension trackerObj {
    
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
        // wipe empty voData entries
        var sql = "delete from voData where val=''"
        toExecSql(sql:sql)
        // wipe trkrData where no voData entries
        sql = "delete from trkrData where date not in (select date from voData)"
        toExecSql(sql: sql)
        // wipe voData and support tables where no trkrData entries
        let tables = ["voData", "voHKstatus", "voOTstatus", "voFNstatus"]
        for table in tables {
            sql = "delete from \(table) where date not in (select date from trkrData)"
            toExecSql(sql: sql)
        }
    }

    func deleteTrackerRecordsOnly() {
        deleteTrackerVoData()
    }

    func deleteCurrEntry() {
        if let eDate = trackerDate?.timeIntervalSince1970 {
            deleteTrackerVoData(date: Int(eDate))
        }
    }

    func delVOdb(_ vid: Int) {
        deleteTrackerVoData(vid: vid)
    }
    
    func deleteTrackerVoData(vid: Int? = nil, date: Int? = nil) {
        
        // Danger Will Robinson
        
        // Example usage:
        // deleteTrackerVoData()                    // Delete all data from all tables
        // deleteTrackerVoData(vid: 5)              // Delete all data for valueObj 5
        // deleteTrackerVoData(date: 1234567890)    // Delete all data for specific date
        // deleteTrackerVoData(vid: 5, date: 1234567890) // Delete data for valueObj 5 at specific date
        
        // Tables that store value/status data
        let tables = ["voData", "voHKstatus", "voOTstatus", "voFNstatus"]
        
        var whereClause = ""
        if let vid = vid {
            whereClause += "id=\(vid)"
        }
        if let date = date {
            if !whereClause.isEmpty {
                whereClause += " AND "
            }
            whereClause += "date=\(date)"
        }
        
        // Delete from all relevant tables
        for table in tables {
            let sql = whereClause.isEmpty ?
                "delete from \(table);" :
                "delete from \(table) where \(whereClause);"
            toExecSql(sql: sql)
        }
        
        if vid == nil {
            let sql = whereClause.isEmpty ?
            "delete from trkrData;" :
            "delete from trkrData where \(whereClause);"
            toExecSql(sql: sql)
        }
    }

    func insertTrackerVodata(vid: Int, date: Int, val: String, vo: valueObj? = nil) {
        var sql = "insert or replace into voData (id, date, val) values (\(vid),\(date),'\(val)');"
        toExecSql(sql:sql)
        if let vo = vo {
            if vo.vtype == VOT_FUNC {
                sql = "insert or replace into voFNstatus (id, date, stat) values (\(vid),\(date),\(fnStatus.fnData.rawValue));"
            } else if vo.optDict["otsrc"] ?? "0" != "0" {
                sql = "insert or replace into voOTstatus (id, date, stat) values (\(vid),\(date),\(otStatus.otData.rawValue));"
            } else if vo.optDict["ahksrc"] ?? "0" != "0" {
                sql = "insert or replace into voHKstatus (id, date, stat) values (\(vid),\(date),\(hkStatus.hkData.rawValue));"
            }
            toExecSql(sql:sql)
        }
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

    
}
