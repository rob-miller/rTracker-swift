//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// tObjBase.swift
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
//  tObjBase.swift
//  rTracker
//
//  Created by Robert Miller on 29/04/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import SQLite3
import UIKit

// MARK: -
// MARK: total db methods

// gpt-4 version
func col_str_flt(udp: UnsafeMutableRawPointer?, lenA: Int32, strA: UnsafeRawPointer?, lenB: Int32, strB: UnsafeRawPointer?) -> Int32 {
    
    let astr = strA!.assumingMemoryBound(to: CChar.self)
    let bstr = strB!.assumingMemoryBound(to: CChar.self)
    
    let va = strtod(astr, nil)
    let vb = strtod(bstr, nil)
    
    var r: Int32 = 0
    if (va > vb) {
        r = 1
    }
    if (va < vb) {
        r = -1
    }
    //print("a= \(va)  b= \(vb)  r= \(r)")
    
    return r
}

class tObjBase: NSObject {

    private static var dbConnections: [Int: OpaquePointer?] = [:]
    private static var dbQueues: [Int: DispatchQueue] = [:]

    var toid = 0
    //@property (nonatomic, strong) NSString *sql;
    var dbName: String?
    var tDb: OpaquePointer? = nil
    var tuniq = 0


    //sqlite3 *tDb;

    ///***************************
    ///
    /// base tObj db tables
    ///
    ///  uniquev: id(int) ; value(int)
    ///       persistent store to maintain unique trackerObj and valueObj IDs
    ///
    ///****************************

    // MARK: -
    // MARK: core object methods and support

    override init() {

        super.init()
        tuniq = TMPUNIQSTART
    }

    deinit {
        closeTDb()
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willTerminateNotification,
            object: nil)

        NotificationCenter.default.removeObserver(self)

    }

    
    static func getDatabaseQueue(toid: Int) -> DispatchQueue {
        if let queue = dbQueues[toid] {
            return queue
        } else {
            let newQueue = DispatchQueue(label: "com.realidata.rTracker.databaseQueue.\(toid)")
            dbQueues[toid] = newQueue
            return newQueue
        }
    }

    static func performDatabaseOperation<T>(toid: Int, operation: () -> T) -> T {
        return getDatabaseQueue(toid: toid).sync {
            return operation()
        }
    }


    
    @objc func applicationWillTerminate(_ notification: Notification) {
        DBGLog(String("tObjBase: app will terminate: toid= \(toid)"))
        closeTDb()
    }

    func getTDb() {
        //DBGLog(@"getTDb dbName= %@ id=%d",self.dbName,self.toid);
        dbgNSAssert(dbName != nil, "getTDb called with no dbName set")

        if tDb != nil {
            return // don't instantiate if already open  .. don't think this can happen
        }
        
        // Check if a connection for this tid already exists
        if let existingConnection = tObjBase.dbConnections[toid] {
            tDb = existingConnection
            return
        }
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            if sqlite3_open_v2(
                rTracker_resource.ioFilePath(dbName!, access: DBACCESS),
                &tDb,
                SQLITE_OPEN_FILEPROTECTION_COMPLETE | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
                if let errorPointer = sqlite3_errmsg(tDb) {
                    let errorMessage = String(cString: errorPointer)
                    DBGErr("SQLite error: \(errorMessage) \(dbName ?? "dbname is nil!")")
                } else {
                    DBGErr("SQLite error with unknown error message")
                }
                sqlite3_close(tDb)
                dbgNSAssert(false, "error opening rTracker database \(dbName!)")
                return
            } else {
                tObjBase.dbConnections[toid] = tDb  // log successful open connection
                
                sqlite3_create_collation(tDb, "CMPSTRDBL", SQLITE_UTF8, nil, col_str_flt) // set how comparisons will be done on this database
                
                let app = UIApplication.shared // add callback to close database on app terminate
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)),
                    name: UIApplication.willTerminateNotification,
                    object: app)
                
                DBGLog(String("opened tDb \(dbName) tDb= \(tDb)"))
            }
        }
        
        var c: Int
        toExecSql(sql:"create table if not exists uniquev (id integer primary key, value integer);")
        c = toQry2Int(sql:"select count(*) from uniquev where id=0;")
        
        if c == 0 {
            DBGLog("init uniquev")
            toExecSql(sql:"insert into uniquev (id, value) values (0, 1);")
        }
    }

    func deleteTDb() {
        DBGLog(String("deleteTDb dbName= \(dbName ?? "") id=\(toid)"))
        guard let _ = dbName else {
            DBGWarn("deleteTDb called for tid \(toid) with no dbName set")
            return
        }
        //dbgNSAssert(dbName != nil && dbName != "", "deleteTDb called with no dbName set")
        
        closeTDb()
        
        if rTracker_resource.deleteFile(atPath: rTracker_resource.ioFilePath(self.dbName, access: DBACCESS)) {
            DBGLog("deleteTDb  deleted \(dbName!)")
            self.dbName = nil
        } else {
            DBGErr(String("error removing tDb named \(self.dbName)"))
        }
    }

    func closeTDb() {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            if let db = tDb {
                if sqlite3_close(tDb) == SQLITE_OK {
                    tObjBase.dbConnections[toid] = nil
                    tDb = nil
                    DBGLog("closeTDb closed \(dbName!) tdb= \(db)")
                    DBGLog(String("closed tDb: \(dbName!) tdb= \(db)"))
                } else {
                    DBGErr("failed to close databae \(dbName!) tDb \(tDb!)")
                }
            }
        }
    }

    // MARK: -
    // MARK: tObject support utilities

    func getUnique() -> Int {
        var i: Int
        if tDb == nil {
            tuniq += 1
            i = -tuniq
            //DBGLog(@"temp tObj id=%d getUnique returning %d",self.toid,i);
        } else {
            i = toQry2Int(sql:"select value from uniquev where id=0;")
            DBGLog(String("id \(toid) getUnique got \(i)"))
            toExecSql(sql:"update uniquev set value = \(i+1) where id=0;")
        }
        return i
    }

    func minUniquev(_ minU: Int) {
        let i = toQry2Int(sql:"select value from uniquev where id=0;")
        if i <= minU {
            toExecSql(sql:"update uniquev set value = \(minU + 1) where id=0;")
        }
    }

    // MARK: -
    // MARK: escape chars for sql store (apostrophe)

    // move to rTracker_resource

    // MARK: -
    // MARK: sql db errors

    func tobPrepError(_ sql: String?) {
        var err = "no error message"
        if let errorPointer = sqlite3_errmsg(tDb) {
            let errorMessage = String(cString: errorPointer)
            err = errorMessage
        }
        DBGErr(String("tob error preparing -> \(sql) <- : \(err) toid \(toid) dbName \(dbName!)"))
    }

    func tobDoneCheck(_ rslt: Int, sql: String?) {
        if rslt != SQLITE_DONE {
            DBGErr(String("tob error not SQL_DONE (\(rslt)) -> \(sql) <- : \(sqlite3_errmsg(tDb)!) toid \(toid) dbName \(dbName!)"))
        }
    }

    func tobExecError(_ sql: String?) {
        var err = "no error message"
        if let errorPointer = sqlite3_errmsg(tDb) {
            let errorMessage = String(cString: errorPointer)
            err = errorMessage
        }

        DBGErr(String("tob error executing -> \(sql) <- : \(err) toid \(toid) dbName \(dbName!)"))
    }

    // MARK: -
    // MARK: sql query execute methods

    func toQry2AryS(sql: String) -> [String] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in

            SQLDbg(String("toQry2AryS: \(dbName!) => _\(sql)_"))
            dbgNSAssert(tDb != nil, "toQry2AryS called with no tDb")
            
            var stmt: OpaquePointer?  // sqlite3_stmt?
            var strings = [String]()
            
            //objc_sync_enter(self)
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let val = sqlite3_column_text(stmt, 0) {
                        strings.append(String(cString: val))
                    }
                }
                //tobDoneCheck(rslt, sql: sql)
            } else {
                tobPrepError(sql)
            }
            sqlite3_finalize(stmt)
            //objc_sync_exit(self)
            SQLDbg(String("returns \(strings.joined(separator: " "))"))
            return strings
        }
    }

    func toQry2AryIS(sql: String) -> [(Int, String)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryIS: \(dbName!) => _\(sql)_"))
            dbgNSAssert(tDb != nil, "toQry2AryIS called with no tDb")
            
            var stmt: OpaquePointer?  // sqlite3_stmt?
            //objc_sync_enter(self)
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, String)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let s1 = String(cString: sqlite3_column_text(stmt, 1)!)
                    results.append((i1, s1))
                    SQLDbg(String("  rslt: \(i1) \(s1)"))
                }
                //tobDoneCheck(rslt, sql: sql)
                sqlite3_finalize(stmt)
                //objc_sync_exit(self)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }

    func toQry2AryISI(sql: String) -> [(Int, String, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryISI: \(dbName!) => _\(sql)_"))
            guard let tDb = tDb else {
                dbgNSAssert(false, "toQry2AryISI called with no tDb")
                return []
            }
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, String, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let s1 = String(cString: sqlite3_column_text(stmt, 1)!)
                    let i2 = Int(sqlite3_column_int(stmt, 2))
                    results.append((i1, s1, i2))
                    SQLDbg(String("  rslt: \(i1) \(s1) \(i2)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }


    func toQry2AryISII(sql: String) -> [(Int, String, Int, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryISII: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, String, Int, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let s1 = String(cString: sqlite3_column_text(stmt, 1)!)
                    let i2 = Int(sqlite3_column_int(stmt, 2))
                    let i3 = Int(sqlite3_column_int(stmt, 3))
                    results.append((i1, s1, i2, i3))
                    SQLDbg(String("  rslt: \(i1) \(s1) \(i2) \(i3)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return [(0, "", 0, 0)]
            }
        }
    }

    func toQry2AryISIII(sql: String) -> [(Int, String, Int, Int, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryISII: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, String, Int, Int, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let s1 = String(cString: sqlite3_column_text(stmt, 1)!)
                    let i2 = Int(sqlite3_column_int(stmt, 2))
                    let i3 = Int(sqlite3_column_int(stmt, 3))
                    let i4 = Int(sqlite3_column_int(stmt, 4))
                    results.append((i1, s1, i2, i3, i4))
                    SQLDbg(String("  rslt: \(i1) \(s1) \(i2) \(i3) \(i4)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return [(0, "", 0, 0, 0)]
            }
        }
    }
    
    func toQry2ArySS(sql: String) -> [(String, String)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2ArySS: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(String, String)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let s1 = String(cString: sqlite3_column_text(stmt, 0)!)
                    let s2 = String(cString: sqlite3_column_text(stmt, 1)!)
                    results.append((s1, s2))
                    SQLDbg(String("  rslt: \(s1) \(s2)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }

    func toQry2ArySSI(sql: String) -> [(String, String, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2ArySSI: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(String, String, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let s1 = String(cString: sqlite3_column_text(stmt, 0)!)
                    let s2 = String(cString: sqlite3_column_text(stmt, 1)!)
                    let i1 = Int(sqlite3_column_int(stmt, 2))
                    results.append((s1, s2, i1))
                    SQLDbg(String("  rslt: \(s1) \(s2) \(i1)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }

    func toQry2ArySSSI(sql: String) -> [(String, String, String, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2ArySSSI: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(String, String, String, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let s1 = String(cString: sqlite3_column_text(stmt, 0)!)
                    let s2 = String(cString: sqlite3_column_text(stmt, 1)!)
                    let s3 = String(cString: sqlite3_column_text(stmt, 2)!)
                    let i1 = Int(sqlite3_column_int(stmt, 3))
                    results.append((s1, s2, s3, i1))
                    SQLDbg(String("  rslt: \(s1) \(s2) \(s3) \(i1)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }
    
    func toQry2AryIIS(sql: String) -> [(Int, Int, String)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryIIS: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, Int, String)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let i2 = Int(sqlite3_column_int(stmt, 1))
                    let s1 = String(cString: sqlite3_column_text(stmt, 2)!)
                    results.append((i1, i2, s1))
                    SQLDbg(String("  rslt: \(i1) \(i2) \(s1)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }
    
    func toQry2AryIISIII(sql: String) -> [(Int, Int, String, Int, Int, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryIISIII: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, Int, String, Int, Int, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let i2 = Int(sqlite3_column_int(stmt, 1))
                    let s1 = String(cString: sqlite3_column_text(stmt, 2)!)
                    let i3 = Int(sqlite3_column_int(stmt, 3))
                    let i4 = Int(sqlite3_column_int(stmt, 4))
                    let i5 = Int(sqlite3_column_int(stmt, 5))
                    results.append((i1, i2, s1, i3, i4, i5))
                    //SQLDbg(String("  rslt: \(i1) \(i2) \(s1) \(i3) \(i4) \(i5)"))
                }
                sqlite3_finalize(stmt)
                SQLDbg(String("    rslt: \(results)"))
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }

    /*  not needed
    func toQry2AryIISIIII(sql: String) -> [(Int, Int, String, Int, Int, Int, Int)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryIISIII: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, Int, String, Int, Int, Int, Int)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let i2 = Int(sqlite3_column_int(stmt, 1))
                    let s1 = String(cString: sqlite3_column_text(stmt, 2)!)
                    let i3 = Int(sqlite3_column_int(stmt, 3))
                    let i4 = Int(sqlite3_column_int(stmt, 4))
                    let i5 = Int(sqlite3_column_int(stmt, 5))
                    let i6 = Int(sqlite3_column_int(stmt, 6))
                    results.append((i1, i2, s1, i3, i4, i5, i6))
                    //SQLDbg(String("  rslt: \(i1) \(i2) \(s1) \(i3) \(i4) \(i5) \(i5)"))
                }
                sqlite3_finalize(stmt)
                SQLDbg(String("    rslt: \(results)"))
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }
    */
    
    func toQry2AryID(sql: String) -> [(Int, Double)] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryID: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Int, Double)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let i1 = Int(sqlite3_column_int(stmt, 0))
                    let d1 = sqlite3_column_double(stmt, 1)
                    results.append((i1, d1))
                    SQLDbg(String("  rslt: \(i1) \(d1)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }

    func toQry2Ary(sql: String) -> [(Any, Any)] {
        return tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2Ary: \(dbName!) => *\(sql)*"))

            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Any, Any)] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    // Get column types
                    let col0Type = sqlite3_column_type(stmt, 0)
                    let col1Type = sqlite3_column_type(stmt, 1)
                    
                    // Extract values based on column types
                    var val0: Any
                    var val1: Any
                    
                    // Column 0
                    switch col0Type {
                    case SQLITE_INTEGER:
                        val0 = Int(sqlite3_column_int64(stmt, 0))
                    case SQLITE_FLOAT:
                        val0 = sqlite3_column_double(stmt, 0)
                    case SQLITE_TEXT:
                        if let cString = sqlite3_column_text(stmt, 0) {
                            val0 = String(cString: cString)
                        } else {
                            val0 = ""
                        }
                    case SQLITE_NULL:
                        val0 = NSNull()
                    default:
                        val0 = NSNull()
                    }
                    
                    // Column 1
                    switch col1Type {
                    case SQLITE_INTEGER:
                        val1 = Int(sqlite3_column_int64(stmt, 1))
                    case SQLITE_FLOAT:
                        val1 = sqlite3_column_double(stmt, 1)
                    case SQLITE_TEXT:
                        if let cString = sqlite3_column_text(stmt, 1) {
                            val1 = String(cString: cString)
                        } else {
                            val1 = ""
                        }
                    case SQLITE_NULL:
                        val1 = NSNull()
                    default:
                        val1 = NSNull()
                    }
                    
                    results.append((val0, val1))
                    SQLDbg(String("  rslt: \(val0) \(val1)"))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }
    
    func toQry2AryDate(sql: String) -> [(Date, Double)] {
        return tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(self.tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [(Date, Double)] = []
                
                while sqlite3_step(stmt) == SQLITE_ROW {
                    // Get the timestamp as seconds since 1970
                    let timestamp = sqlite3_column_int64(stmt, 0)
                    // Convert to Date
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                    let val = sqlite3_column_double(stmt, 1)
                    results.append((date, val))
                }
                sqlite3_finalize(stmt)
                return results
            } else {
                // Handle error
                return []
            }
        } ?? []
    }
    
    func toQry2AryI(sql: String) -> [Int] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            
            SQLDbg(String("toQry2AryI: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                var results: [Int] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let intValue = Int(sqlite3_column_int(stmt, 0))
                    results.append(intValue)
                    SQLDbg(String("  rslt: \(intValue)"))
                }
                sqlite3_finalize(stmt)
                SQLDbg(String("  returns \(results)"))
                return results
            } else {
                tobPrepError(sql)
                return []
            }
        }
    }

    func toQry2DictII(sql: String?) -> [Int : Int] {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2DictII: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var dict: [Int: Int] = [:]
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                //var rslt: Int
                while sqlite3_step(stmt) == SQLITE_ROW {
                    dict[Int(sqlite3_column_int(stmt, 0))] = Int(sqlite3_column_int(stmt, 1))
                    SQLDbg(String("  rslt: \(sqlite3_column_int(stmt, 0)) -> \(dict[Int(sqlite3_column_int(stmt, 0))])"))
                }
                //tobDoneCheck(rslt, sql: sql)
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg(String("  returns \(dict)"))
            return dict
        }
    }

    func toQry2SetI(sql: String) -> Set<Int> {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2SetI: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var set = Set<Int>()
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                //var rslt: Int
                while sqlite3_step(stmt) == SQLITE_ROW {
                    set.insert(Int(sqlite3_column_int(stmt, 0)))
                    SQLDbg(String("  rslt: \(sqlite3_column_int(stmt, 0)) "))
                }
                //tobDoneCheck(rslt, sql: sql)
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            objc_sync_exit(self)
            SQLDbg(String("  returns \(set)"))
            return set
        }
    }

    func toQry2IntInt(sql: String) -> (Int, Int)? {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2AryII: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var i1:Int = 0, i2:Int = 0
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    i1 = Int(sqlite3_column_int(stmt, 0))
                    i2 = Int(sqlite3_column_int(stmt, 1))
                    SQLDbg(String("  rslt: \(i1) \(i2)"))
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg(String("  returns \(i1) \(i2)"))
            
            return (i1, i2)
        }
    }

    func toQry2IntIntInt(sql: String) -> (Int, Int, Int)? {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2IntIntInt: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var i1:Int = 0, i2:Int = 0, i3:Int = 0
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    i1 = Int(sqlite3_column_int(stmt, 0))
                    i2 = Int(sqlite3_column_int(stmt, 1))
                    i3 = Int(sqlite3_column_int(stmt, 2))
                    SQLDbg(String("  rslt: \(i1) \(i2) \(i3)"))
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg(String("  returns \(i1) \(i2) \(i3)"))
            
            return (i1, i2, i3)
        }
    }

    func toQry2Int(sql: String) -> Int {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2Int: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var irslt = 0
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    irslt = Int(sqlite3_column_int(stmt, 0))
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg("  returns \(irslt)")
            
            return irslt
        }
    }
    
    func toAddColumnINE(table: String, col: String, typ: String, dflt: String? = nil) {
        // Check if the column already exists
        let checkColumnSQL = "SELECT COUNT(*) FROM pragma_table_info('\(table)') WHERE name = '\(col)'"
        let columnExistsResult = toQry2Str(sql: checkColumnSQL)
        let columnExists = (Int(columnExistsResult) ?? 0) > 0
        
        if !columnExists {
            //DBGLog("Adding 'hidden' column to toplevel table")
            let alterTableSQL = "ALTER TABLE \(table) ADD COLUMN \(col) \(typ)\(dflt != nil ? " DEFAULT \(dflt!)" : "")"
            toExecSql(sql: alterTableSQL)
        } else {
            //DBGLog("'hidden' column already exists in toplevel table")
        }
    }
    
    func toQry2Str(sql: String) -> String {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2StrCopy: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var srslt : String = ""
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let textPointer = sqlite3_column_text(stmt, 0)
                    if let textPointer = textPointer {
                        srslt = rTracker_resource.fromSqlStr(String(cString: textPointer))
                    }
                }
                //[self tobDoneCheck:rslt];
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            //objc_sync_exit(self)
            SQLDbg(String("  returns _\(srslt)_"))
            
            return srslt
        }
    }
    
    func toQry2I12aS1(sql: String) -> ([Int], String) {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2AryI11S1: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var srslt : String = ""
            var arr = Array(repeating: 0, count: 12)
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    for i in 0..<12 {
                        arr[i] = Int(sqlite3_column_int(stmt, Int32(i)))
                    }
                    let textPointer = sqlite3_column_text(stmt, 12)
                    if let textPointer = textPointer {
                        srslt = rTracker_resource.fromSqlStr(String(cString: textPointer))
                    }
                    SQLDbg(String("  rslt: \(arr[0]) \(arr[1]) \(arr[2]) \(arr[3]) \(arr[4]) \(arr[5]) \(arr[6]) \(arr[7]) \(arr[8]) \(arr[9]) \(arr[10]) \(arr[11]) \(srslt)"))
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg(String("  returns \(arr[0]) \(arr[1]) \(arr[2]) \(arr[3]) \(arr[4]) \(arr[5]) \(arr[6]) \(arr[7]) \(arr[8]) \(arr[9]) \(arr[10]) \(arr[11]) \(srslt)"))
            return (arr, srslt)
        }
    }
    
    func toQry2Float(sql: String) -> Float {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2Float: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var frslt: Float = 0.0
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    frslt = Float(sqlite3_column_double(stmt, 0))
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg(String("  returns \(frslt)"))
            
            return frslt
        }
    }

    func toQry2Double(sql: String) -> Double {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2Double: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var drslt = 0.0
            objc_sync_enter(self)
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    drslt = sqlite3_column_double(stmt, 0)
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
            SQLDbg("  returns \(drslt)")
            
            return drslt
        }
    }

    func toExecSql(sql: String) {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toExecSql: \(dbName!) => _\(sql)_"))
            guard let tDb = tDb else {
                dbgNSAssert(false, "toExecSql called with no tDb")
                return
            }
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) != SQLITE_DONE {
                    tobExecError(sql)
                }
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
        }
    }

    // so we can ignore error when adding column
    func toExecSqlIgnErr(sql: String) {
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toExecSqlIgnErr: \(dbName!) => _\(sql)_"))
            guard let tDb = tDb else {
                dbgNSAssert(false, "toExecSqlIgnErr called with no tDb")
                return
            }
            
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_step(stmt)
                sqlite3_finalize(stmt)
            }
        }
    }

    func toQry2Log(sql: String) {
        #if DEBUGLOG
        tObjBase.performDatabaseOperation(toid: toid) { [self] in
            SQLDbg(String("toQry2Log: \(dbName!) => _\(sql)_"))
            
            var stmt: OpaquePointer?
            var srslt: String
            
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                let c = sqlite3_column_count(stmt)
                var cols = ""
                for i in 0..<c {
                    cols = cols + String(utf8String: sqlite3_column_name(stmt, i))!
                    cols = cols + " "
                }
                print("\(cols)  (db)")
                //var rslt: Int32
                while sqlite3_step(stmt) == SQLITE_ROW {
                    cols = ""
                    for i in 0..<c {
                        srslt = String(cString: sqlite3_column_text(stmt, i))
                        cols = cols + srslt
                        cols = cols + " "
                    }
                    print("\(cols)")
                }
                //tobDoneCheck(rslt, sql: sql)
                sqlite3_finalize(stmt)
            } else {
                tobPrepError(sql)
            }
        }
        #endif
    }
}

