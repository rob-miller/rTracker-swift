//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// trackerList.swift
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
//  trackerList.swift
//  rTracker
//
//  Created by Robert Miller on 16/03/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation

//#import "/usr/include/sqlite3.h"


class trackerList: tObjBase {
    /*{

    	NSMutableArray *topLayoutNames;
    	NSMutableArray *topLayoutIDs;
    	NSMutableArray *topLayoutPriv;
        NSMutableArray *topLayoutReminderCount;
    	//trackerObj *tObj;

    }*/

    var topLayoutNames: [AnyHashable]?
    var topLayoutIDs: [AnyHashable]?
    var topLayoutPriv: [AnyHashable]?
    var topLayoutReminderCount: [AnyHashable]?

    //@synthesize tObj;

    ///***************************
    ///
    /// trackerList db tables
    ///
    ///   toplevel: rank(int) ; id(int) ; name(text) ; priv(int)
    ///      primarily for entry listbox of tracker names
    ///
    ///****************************

    // MARK: -
    // MARK: core object methods and support

    func initTDb() {
        //int c;

        //DBGLog(@"Initializing top level dtabase!");
        dbName = "topLevel.sqlite3"
        getTDb()

        var sql = "create table if not exists toplevel (rank integer, id integer unique, name text, priv integer, remindercount integer);"
        toExecSql(sql)
        // assume all old users have updated columns by now
        //sql = @"alter table toplevel add column remindercount int";  // new column added for reminders
        //[self toExecSqlIgnErr:sql];

        //self.sql = @"select count(*) from toplevel;";
        //DBGLog(@"toplevel at open contains %d entries",[self toQry2Int:sql]);

        sql = "create table if not exists info (name text unique, val integer);"
        toExecSql(sql)

        sql = "select max(val) from info where name='rtdb_version'"
        let dbVer = toQry2Int(sql)
        if 0 == dbVer {
            // 0 means no entry so need to initialise
            DBGLog("rtdb_version not set")
            sql = String(format: "insert into info (name, val) values ('rtdb_version',%i);", RTDB_VERSION)
            toExecSql(sql)
        } else {

            if 1 == dbVer {
                // fix info table to be unique on name
                sql = "select max(val) from info where name='samples_version'"
                let samplesVer = toQry2Int(sql)
                sql = "select max(val) from info where name='demos_version'"
                let demosVer = toQry2Int(sql)
                sql = "drop table info"
                toExecSql(sql)
                sql = "create table if not exists info (name text unique, val integer);"
                toExecSql(sql)
                sql = String(format: "insert into info (name, val) values ('rtdb_version',%i);", RTDB_VERSION) // upgraded now
                toExecSql(sql)
                sql = String(format: "insert into info (name, val) values ('demos_version',%i);", demosVer)
                toExecSql(sql)
                sql = String(format: "insert into info (name, val) values ('samples_version',%i);", samplesVer)
                toExecSql(sql)
            }
        }


        //self.sql = nil;
    }

    //@property (nonatomic,retain) trackerObj *tObj;
    override init() {
        //DBGLog(@"init trackerList");

        super.init()
        topLayoutNames = []
        topLayoutIDs = []
        topLayoutPriv = []
        topLayoutReminderCount = []

        initTDb()
    }

    // MARK: -
    // MARK: TopLayoutTable <-> db support

    func loadTopLayoutTable() {
        //DBGTLIST(self);
        topLayoutNames?.removeAll()
        topLayoutIDs?.removeAll()
        topLayoutPriv?.removeAll()
        topLayoutReminderCount?.removeAll()

        //self.sql = @"select * from toplevel";
        //[self toQry2Log];

        let sql = String(format: "select id, name, priv, remindercount from toplevel where priv <= %i order by rank;", privacyV.getPrivacyValue())
        toQry2AryISII(&topLayoutIDs, s1: &topLayoutNames, i2: &topLayoutPriv, i3: &topLayoutReminderCount, sql: sql)
        //self.sql = nil;
        DBGLog("loadTopLayoutTable finished, priv=%i tlt= %@", privacyV.getPrivacyValue(), topLayoutNames)
        //DBGTLIST(self);
    }

    func add(toTopLayoutTable tObj: trackerObj?) {
        DBGLog("%@ toid %ld", tObj?.trackerName, Int(tObj?.toid ?? 0))

        topLayoutIDs?.append(NSNumber(value: tObj?.toid ?? 0))
        topLayoutNames?.append(tObj?.trackerName ?? "")
        topLayoutPriv?.append(NSNumber(value: (tObj?.optDict?["privacy"] as? NSNumber)?.intValue ?? 0))
        topLayoutReminderCount?.append(NSNumber(value: tObj?.enabledReminderCount() ?? 0))

        confirmToplevelEntry(tObj)
    }

    /*
     ensure there is accurate entry in db table toplevel for passed trackerObj
     */
    func confirmToplevelEntry(_ tObj: trackerObj?) {
        //self.sql = @"select * from toplevel";
        //[self toQry2Log];
        //DBGLog(@"%@ toid %d",tObj.trackerName, tObj.toid);
        //DBGTLIST(self);
        var sql = String(format: "select rank from toplevel where id=%ld;", Int(tObj?.toid ?? 0))
        var rank = toQry2Int(sql) // returns 0 if not found
        if rank == 0 {
            DBGLog("rank not found")
        } else {
            sql = String(format: "select count(*) from toplevel where rank=%li;", rank)
            if 1 < toQry2Int(sql) {
                DBGLog("too many at rank %li", rank)
                rank = 0
            }
        }
        if rank == 0 {
            sql = "select max(rank) from toplevel;" // so put at end
            rank = toQry2Int(sql) + 1
            DBGLog("rank adjust, set to %ld", rank)
        }

        dbgNSAssert(tObj?.toid, "confirmTLE: toid=0")
        var privVal = (tObj?.optDict?["privacy"] as? NSNumber)?.intValue ?? 0
        privVal = (privVal != 0 ? privVal : PRIVDFLT) // default is 1 not 0;
        sql = String(format: "insert or replace into toplevel (rank, id, name, priv, remindercount) values (%li, %li, \"%@\", %i, %i);", rank, Int(tObj?.toid ?? 0), rTracker_resource.toSqlStr(tObj?.trackerName) ?? "", privVal, tObj?.enabledReminderCount() ?? 0)
        toExecSql(sql)
    }

    func reorderFromTLT() {
        //DBGTLIST(self);
        let nrank = 0
        for tracker in topLayoutNames ?? [] {
            guard let tracker = tracker as? String else {
                continue
            }
            //DBGLog(@" %@ to rank %d",tracker,nrank);
            let sql = "update toplevel set rank = \(nrank + 1) where name = \"\(rTracker_resource.toSqlStr(tracker) ?? "")\";"
            toExecSql(sql) // better if used bind vars, but this keeps access in tObjBase
            nrank += 1
        }
        //DBGTLIST(self);
    }

    func reloadFromTLT() {
        //DBGTLIST(self);
        let nrank = 0
        var sql = "delete from toplevel where priv <= \(privacyV.getPrivacyValue());"
        toExecSql(sql)
        for tracker in topLayoutNames ?? [] {
            guard let tracker = tracker as? String else {
                continue
            }
            let tid = ((topLayoutIDs)?[nrank] as? NSNumber)?.intValue ?? 0
            let priv = ((topLayoutPriv)?[nrank] as? NSNumber)?.intValue ?? 0
            let rc = ((topLayoutReminderCount)?[nrank] as? NSNumber)?.intValue ?? 0

            //DBGLog(@" %@ id %d to rank %d",tracker,tid,nrank);
            sql = String(format: "insert into toplevel (rank, id, name, priv,remindercount) values (%i, %ld, \"%@\", %ld, %ld);", nrank + 1, tid, rTracker_resource.toSqlStr(tracker) ?? "", priv, rc) // rank in db always non-0
            toExecSql(sql) // better if used bind vars, but this keeps access in tObjBase
            nrank += 1
        }
    }

    func getTIDfromIndex(_ ndx: Int) -> Int {
        return ((topLayoutIDs)?[ndx] as? NSNumber)?.intValue ?? 0
    }

    func getPrivFromLoadedTID(_ tid: Int) -> Int {

        let ndx = topLayoutIDs?.firstIndex(of: NSNumber(value: tid)) ?? NSNotFound
        if NSNotFound == ndx {
            return MAXPRIV
        }
        return ((topLayoutPriv)?[ndx] as? NSNumber)?.intValue ?? 0
    }

    func checkTIDexists(_ tid: NSNumber?) -> Bool {
        let sql = "select id from toplevel where id=\(tid?.intValue ?? 0)"
        let rslt = toQry2Int(sql)
        return 0 != rslt
    }

    // return tid for first matching name
    func getTIDfromName(_ str: String?) -> Int {
        let ndx = 0
        for tname in topLayoutNames ?? [] {
            guard let tname = tname as? String else {
                continue
            }
            if tname == str {
                return getTIDfromIndex(ndx)
            }
            ndx += 1
        }
        return 0
    }

    // return aaray of TIDs which match name, order by rank
    func getTIDFromNameDb(_ str: String?) -> [AnyHashable]? {
        var i1: [AnyHashable] = []
        let sql = "select id from toplevel where name=\"\(rTracker_resource.toSqlStr(str) ?? "")\" order by rank"
        toQry2AryI(&i1, sql: sql)
        let ra = i1
        return ra
    }

    ////
    //
    // 26.xi.12 previously this would modify dictionary to set its TID to non-conflicting value, now calls updateTID to move existing trackers with conflicting TID to new TID
    //
    ////
    func fixDictTID(_ tdict: [AnyHashable : Any]?) {
        let tid = tdict?["tid"] as? NSNumber
        minUniquev(tid?.intValue ?? 0)

        if checkTIDexists(tid) {
            //[tdict setValue:[NSNumber numberWithInt:[self getUnique]] forKey:@"tid"];
            //DBGLog(@"  changed to: %@",[tdict objectForKey:@"tid"]);
            updateTID(tid?.intValue ?? 0, new: getUnique())
        }
    }

    func updateTLtid(_ old: Int, new: Int) {
        var sql: String?
        if -1 == new {
            sql = String(format: "delete from toplevel where id=%ld", old)
        } else if old == new {
            return
        } else {
            sql = String(format: "update toplevel set id=%ld where id=%ld", new, old)
        }
        toExecSql(sql)
        //self.sql = nil;

        loadTopLayoutTable()

        DBGLog("changed toplevel TID %lD to %ld", old, new)
    }

    func updateTID(_ old: Int, new: Int) {

        if old == new {
            return
        }
        if checkTIDexists(NSNumber(value: new)) {
            updateTID(new, new: getUnique())
        }
        var to = trackerObj(old)
        to.clearScheduledReminders() // remove any reminders with old tid
        to.closeTDb()
        to = nil

        // rename file
        let oldFname = String(format: "trkr%ld.sqlite3", old)
        let newFname = String(format: "trkr%ld.sqlite3", new)
        var error: Error?

        let fm = FileManager.default
        do {
            if try fm.moveItem(
                atPath: rTracker_resource.ioFilePath(oldFname, access: DBACCESS) ?? "",
                toPath: rTracker_resource.ioFilePath(newFname, access: DBACCESS) ?? "") != true {
                DBGErr("Unable to move file %@ to %@: %@", oldFname, newFname, error?.localizedDescription)
            }
        } catch let e {
            error = e
        }

        let upReminders = String(format: "update reminders set tid=%ld", new)

        to = trackerObj(new)
        to.toExecSql(upReminders)
        to.setReminders()
        to.closeTDb()
    }

    // MARK: -
    // MARK: tracker manipulation methods

    func reorderTLT(_ fromRow: Int, toRow: Int) {
        DBGTLIST(self)

        let tName = (topLayoutNames)?[fromRow]
        let tID = (topLayoutIDs)?[fromRow]
        let tPriv = (topLayoutPriv)?[fromRow]
        let tRC = (topLayoutReminderCount)?[fromRow]

        topLayoutNames?.remove(at: fromRow)
        topLayoutIDs?.remove(at: fromRow)
        topLayoutPriv?.remove(at: fromRow)
        topLayoutReminderCount?.remove(at: fromRow)

        if let tName {
            topLayoutNames?.insert(tName, at: toRow)
        }
        if let tID {
            topLayoutIDs?.insert(tID, at: toRow)
        }
        if let tPriv {
            topLayoutPriv?.insert(tPriv, at: toRow)
        }
        if let tRC {
            topLayoutReminderCount?.insert(tRC, at: toRow)
        }


        //DBGTLIST(self);
    }

    func copy(toConfig srcTO: trackerObj?) -> trackerObj? {
        //DBGLog(@"copyToConfig: src id= %d %@",srcTO.toid,srcTO.trackerName);
        var newTO = trackerObj
        newTO?.toid = getUnique()
        newTO = newTO.init()

        let oTN = srcTO?.trackerName
        //NSString *nTN = [[NSString alloc] initWithString:oTN];
        //newTO.trackerName = nTN;
        // release as well
        newTO?.trackerName = oTN ?? ""

        //NSEnumerator *enumer = [srcTO.valObjTable objectEnumerator];
        //valueObj *vo;
        //while (vo = (valueObj *) [enumer nextObject]) {
        for vo in srcTO?.valObjTable ?? [] {
            guard let vo = vo as? valueObj else {
                continue
            }
            let newVO = newTO.copyVoConfig(vo)
            newTO.addValObj(newVO)
        }

        newTO.saveConfig()
        //DBGLog(@"copyToConfig: copy id= %d %@",newTO.toid,newTO.trackerName);

        return newTO
    }

    func deleteTrackerAllRow(_ row: Int) {
        if row >= (topLayoutIDs?.count ?? 0) {
            return
        }

        let tid = ((topLayoutIDs)?[row] as? NSNumber)?.intValue ?? 0
        let to = trackerObj(tid)
        DBGLog("delete tracker all name:%@ id:%ldd rowtext= %@", to.trackerName, to.toid, topLayoutNames?[row])
        to.clearScheduledReminders()
        to.deleteTrackerDB()

        toExecSql("delete from toplevel where id=\(tid) and name='\(to.trackerName ?? "")'")

        topLayoutNames?.remove(at: row)
        topLayoutIDs?.remove(at: row)
        topLayoutPriv?.remove(at: row)
        topLayoutReminderCount?.remove(at: row)
    }

    func deleteTrackerAllTID(_ nsnTID: NSNumber?, name: String?) {
        var row: Int? = nil
        if let nsnTID {
            row = topLayoutIDs?.firstIndex(of: nsnTID) ?? NSNotFound
        }
        let tid = nsnTID?.intValue ?? 0
        let to = trackerObj(tid)

        if (NSNotFound != row) && (name == to.trackerName) {
            deleteTrackerAllRow(row ?? 0)
        }
    }

    func deleteTrackerRecordsRow(_ row: Int) {
        let tid = ((topLayoutIDs)?[row] as? NSNumber)?.intValue ?? 0
        let to = trackerObj(tid)
        to.deleteTrackerRecordsOnly()
    }

    //- (void) writeTListXLS:(NSFileHandle*)nsfh;
    func exportAll() {
        var ndx: Float = 1.0
        privacyV.jumpMaxPriv() // reasonable to do this now with default encryption enabled

        let sql = "select id from toplevel" // ignore current (self) list because subject to privacy
        var idSet: [AnyHashable] = []
        toQry2AryI(&idSet, sql: sql)
        let all = Float(idSet.count)

        for tid in idSet {
            guard let tid = tid as? NSNumber else {
                continue
            }
            let to = trackerObj(tid.intValue)
            to.saveToItunes()

            rTracker_resource.setProgressVal(ndx / all)
            ndx += 1.0
        }

        privacyV.restorePriv()
    }

    func confirmToplevelTIDs() {
        privacyV.jumpMaxPriv() // reasonable to do this now with default encryption enabled

        let sql = "select id from toplevel" // ignore current (self) list because subject to privacy
        var idSet: [AnyHashable] = []
        toQry2AryI(&idSet, sql: sql)

        for tid in idSet {
            guard let tid = tid as? NSNumber else {
                continue
            }
            let to = trackerObj(tid.intValue)
            confirmToplevelEntry(to)
        }

        privacyV.restorePriv()
    }

    func testConflict(_ tname: String?) -> Bool {
        for n in topLayoutNames ?? [] {
            guard let n = n as? String else {
                continue
            }
            if tname == n {
                return true
            }
        }
        return false
    }

    // add _n to trackername - used only when adding samples
    func deConflict(_ newTracker: trackerObj?) {
        if !testConflict(newTracker?.trackerName) {
            return
        }

        let i = 2
        var tstr: String?

        tstr = "\(newTracker?.trackerName ?? "") \(i)"
        while testConflict(tstr) {
            i += 1
        }
        i += 1
        newTracker?.trackerName = tstr
    }

    func wipeOrphans() {
        let sql = "select id, name from toplevel order by id"
        var i1: [AnyHashable] = []
        var s1: [AnyHashable] = []
        toQry2AryIS(&i1, s1: &s1, sql: sql)
        var dictTid2Ndx: [AnyHashable : Any] = [:]
        let c = i1.count
        var i: Int
        for i in 0..<c {
            dictTid2Ndx[i1[i]] = NSNumber(value: i)
        }

        var err: Error?
        var fileList: [String]? = nil
        do {
            fileList = try FileManager.default.contentsOfDirectory(atPath: rTracker_resource.ioFilePath("", access: DBACCESS) ?? "")
        } catch let e {
            err = e
        }
        var dictTid2Filename: [AnyHashable : Any] = [:]

        if nil == fileList {
            DBGLog("error getting file list: %@", err)
        } else {
            let fn: String? = nil
            for fn in fileList ?? [] {
                guard let fn = fn as? fn else {
                    continue
                }
                let ftid = Int((fn as NSString?)?.substring(from: 4) ?? "") ?? 0
                if ftid != 0 {
                    dictTid2Filename[NSNumber(value: ftid)] = fn ?? ""
                    let ftidNdx = dictTid2Ndx[NSNumber(value: ftid)] as? NSNumber
                    if let ftidNdx {
                        DBGLog("%@ iv: %d toplevel: %@", fn, ftid, s1[Int(ftidNdx.uintValue)])
                    } else {
                        let doDel = true
                        if doDel {
                            DBGLog("deleting orphan %d file %@", ftid, fn)
                            rTracker_resource.deleteFile(atPath: rTracker_resource.ioFilePath(fn, access: DBACCESS))
                        } else {
                            //trackerObj *to = [[trackerObj alloc]init:ftid];
                            DBGLog("%@ iv: %d orphan file: %@", fn, ftid, trackerObj(ftid).trackerName)
                        }
                    }
                } else if fn?.hasPrefix("stash_trkr") ?? false {
                    DBGLog("deleting stashed tracker %@", fn)
                    rTracker_resource.deleteFile(atPath: rTracker_resource.ioFilePath(fn, access: DBACCESS))
                }
            }
            let tlTid: NSNumber? = nil
            i = 0
            for tlTid in i1 {
                guard let tlTid = tlTid as? tlTid else {
                    continue
                }
                var tltidFilename: String? = nil
                if let tlTid {
                    tltidFilename = dictTid2Filename[tlTid] as? String
                }
                if let tltidFilename {
                    DBGLog("tid %@ name %@ file %@", tlTid, s1[i], tltidFilename)
                } else {
                    let tname = s1[i] as? String
                    DBGLog("tid %@ name %@ no file found - delete from tlist", tlTid, tname)
                    let sql = "delete from toplevel where id=\(tlTid ?? 0) and name='\(tname ?? "")'"
                    toExecSql(sql)
                }
                i += 1
            }
        }

        //self.sql = nil;


    }

    func restoreTracker(_ fn: String?, ndx: Int) {
        var ftid = Int((fn as NSString?)?.substring(from: ndx) ?? "") ?? 0
        var to: trackerObj?
        var newTid = ftid

        if checkTIDexists(NSNumber(value: ftid)) {
            newTid = getUnique()
        }
        var newFn = String(format: "trkr%ld.sqlite3", newTid)
        let fm = FileManager.default
        var error: Error?

        while fm.fileExists(atPath: rTracker_resource.ioFilePath(newFn, access: DBACCESS) ?? "") {
            newTid = getUnique()
            newFn = String(format: "trkr%ld.sqlite3", newTid)
        }

        // RTM TODO ADDRESS: what if fn = newFN here?

        do {
            if try fm.moveItem(
                atPath: rTracker_resource.ioFilePath(fn, access: DBACCESS) ?? "",
                toPath: rTracker_resource.ioFilePath(newFn, access: DBACCESS) ?? "") != true {
                DBGWarn("Unable to move file %@ to %@: %@", fn, newFn, error?.localizedDescription) // only if gtUnique fails ?
            }
        } catch let e {
            error = e
        }

        ftid = newTid

        to = trackerObj(ftid)
        if nil == to?.trackerName {
            DBGWarn("deleting empty tracker file %@", newFn)
            do {
                if try fm.removeItem(atPath: rTracker_resource.ioFilePath(newFn, access: DBACCESS) ?? "") != true {
                    DBGLog("Unable to delete file %@: %@", newFn, error?.localizedDescription)
                }
            } catch let e {
                error = e
            }
        } else {
            let newName = "recovered: " + (to?.trackerName ?? "")
            to?.trackerName = newName
            add(toTopLayoutTable: to)
        }
    }

    func recoverOrphans() -> Bool {
        var didRecover = false
        let sql = "select id, name from toplevel order by id"
        var i1: [AnyHashable] = []
        var s1: [AnyHashable] = []
        toQry2AryIS(&i1, s1: &s1, sql: sql)
        var dictTid2Ndx: [AnyHashable : Any] = [:]
        let c = i1.count
        var i: Int
        for i in 0..<c {
            dictTid2Ndx[i1[i]] = NSNumber(value: i)
        }

        var err: Error?
        var fileList: [String]? = nil
        do {
            fileList = try FileManager.default.contentsOfDirectory(atPath: rTracker_resource.ioFilePath("", access: DBACCESS) ?? "")
        } catch let e {
            err = e
        }
        var dictTid2Filename: [AnyHashable : Any] = [:]

        if nil == fileList {
            DBGLog("error getting file list: %@", err)
        } else {
            let fn: String? = nil
            for fn in fileList ?? [] {
                guard let fn = fn as? fn else {
                    continue
                }

                let ftid = Int((fn as NSString?)?.substring(from: 4) ?? "") ?? 0
                if ftid != 0 && fn?.hasPrefix("trkr") ?? false && fn?.hasSuffix("sqlite3") ?? false {
                    dictTid2Filename[NSNumber(value: ftid)] = fn ?? ""
                    let ftidNdx = dictTid2Ndx[NSNumber(value: ftid)] as? NSNumber
                    if ftidNdx != nil {
                        //DBGLog(@"%@ iv: %d toplevel: %@",fn, ftid, [s1 objectAtIndex:[ftidNdx unsignedIntegerValue]]);
                    } else {
                        restoreTracker(fn, ndx: 4)
                        didRecover = true
                    }
                } else if fn?.hasPrefix("stash_trkr") ?? false {
                    restoreTracker(fn, ndx: 10)
                    didRecover = true
                }
            }
            let tlTid: NSNumber? = nil
            i = 0
            for tlTid in i1 {
                guard let tlTid = tlTid as? tlTid else {
                    continue
                }
                var tltidFilename: String? = nil
                if let tlTid {
                    tltidFilename = dictTid2Filename[tlTid] as? String
                }
                if tltidFilename != nil {
                    //DBGLog(@"tid %@ name %@ file %@",tlTid,[s1 objectAtIndex:i],tltidFilename);
                } else {
                    let tname = s1[i] as? String
                    DBGLog("tid %@ name %@ no file found - delete from tlist", tlTid, tname)
                    let sql = "delete from toplevel where id=\(tlTid ?? 0) and name='\(tname ?? "")'"
                    toExecSql(sql)
                }
                i += 1
            }
        }

        //self.sql = nil;

        return didRecover
    }

    func updateShortcutItems() {

        let sciCount = SCICOUNTDFLT //[rTracker_resource getSCICount];
        var newShortcutItems = [AnyHashable](repeating: 0, count: sciCount)
        var idArray = [AnyHashable](repeating: 0, count: sciCount)
        var nameArray = [AnyHashable](repeating: 0, count: sciCount)

        let sql = String(format: "select id, name from toplevel where priv <= %i order by rank limit %d;", MINPRIV, UInt(sciCount))
        toQry2AryIS(&idArray, s1: &nameArray, sql: sql)

        if nameArray == nil {
            return // no trackers, no names on first start
        }
        let c = nameArray.count
        if c == 0 {
            return // no trackers, no names on first start
        }

        var i: Int
        for i in 0..<sciCount {
            let si = UIApplicationShortcutItem(
                type: "open",
                localizedTitle: nameArray[i] as? String ?? "",
                localizedSubtitle: nil,
                icon: nil,
                userInfo: [
                    "tid": idArray[i]
                ])

            newShortcutItems.append(si)
        }

        UIApplication.shared.shortcutItems = newShortcutItems as? [UIApplicationShortcutItem]

    }
}