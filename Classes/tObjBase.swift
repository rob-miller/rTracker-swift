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

//- (sqlite3*) tDb {
//    return _tDb;  // don't auto-allocate; allow to be nil
//}

/*
- (NSString *) trackerDbFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  // file itunes accessible
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);  // files not accessible
	NSString *docsDir = [paths objectAtIndex:0];
	return [docsDir stringByAppendingPathComponent:self.dbName];
}
*/
/*
private func col_str_flt(_ udp: UnsafeMutableRawPointer?, _ lenA: Int, _ strA: UnsafeRawPointer?, _ lenB: Int, _ strB: UnsafeRawPointer?) -> Int {
    // strAm strB not guaranteed to be null-terminated

    //double va = atof(strA);
    //double vb = atof(strB);
    let astr = UnsafePointer<Int8>(Int8(strA ?? 0))
    let bstr = UnsafePointer<Int8>(Int8(strB ?? 0))
    var ta = Int8((astr[lenA - 1]) ?? 0)
    var tb = Int8((bstr[lenB - 1]) ?? 0)
    let va = strtod(strA, &ta)
    let vb = strtod(strB, &tb)
    var r = 0
    if va > vb {
        r = 1
    }
    if va < vb {
        r = -1
    }
    //DBGLog(@"a= %f  b= %f  r= %d",va,vb,r);

    return r
}
*/
/*
func col_str_flt(_ udp: UnsafeMutableRawPointer?, _ lenA: Int32, _ strA: UnsafeRawPointer?, _ lenB: Int32, _ strB: UnsafeRawPointer?) -> Int32 {
    guard let strA = strA?.assumingMemoryBound(to: CChar.self), let strB = strB?.assumingMemoryBound(to: CChar.self) else {
        return 0
    }
    
    // strAm strB not guaranteed to be null-terminated
    
    let astr = strA.advanced(by: Int(lenA) - 1)
    let bstr = strB.advanced(by: Int(lenB) - 1)
    let va = Double(String(cString: astr))
    let vb = Double(String(cString: bstr))
    var r = 0
    if va! > vb! {
        r = 1
    }
    if va! < vb! {
        r = -1
    }
    //DBGLog(@"a= %f  b= %f  r= %d",va,vb,r);
    
    return Int32(r)
}
*/
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
    /*{

    	NSInteger toid;
    	NSString *dbName;
    	NSString *sql;
    	sqlite3 *tDb;
    	int tuniq;
    }*/
    var toid = 0
    //@property (nonatomic, strong) NSString *sql;
    var dbName: String?
    var tDb: OpaquePointer? = nil // sqlite3?
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
        //DBGLog(@"tObjBase init: db %@",self.dbName);
        //self.tDb=nil;
        //[self getTDb];
        tuniq = TMPUNIQSTART
    }

    deinit {
        //DBGLog(@"dealloc tObjBase: %@  id=%d",self.dbName,self.toid);

        //UIApplication *app = [UIApplication sharedApplication];
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willTerminateNotification,
            object: nil)
        //object:app];
        closeTDb()




    }

    @objc func applicationWillTerminate(_ notification: Notification) {
        DBGLog(String("tObjBase: app will terminate: toid= \(toid)"))
        closeTDb()
    }

    func getTDb() {
        //DBGLog(@"getTDb dbName= %@ id=%d",self.dbName,self.toid);
        dbgNSAssert(dbName != nil, "getTDb called with no dbName set")

        if tDb != nil {
            return // don't instantiate if already open
        }

        if sqlite3_open_v2(
            rTracker_resource.ioFilePath(dbName!, access: DBACCESS),
            &tDb,
            SQLITE_OPEN_FILEPROTECTION_COMPLETE | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
            sqlite3_close(tDb)
            dbgNSAssert(false, "error opening rTracker database")
        } else {
            //DBGLog(@"opened tDb %@",self.dbName);
            var c: Int
            toExecSql(sql:"create table if not exists uniquev (id integer primary key, value integer);")
            c = toQry2Int(sql:"select count(*) from uniquev where id=0;")!

            if c == 0 {
                DBGLog("init uniquev")
                toExecSql(sql:"insert into uniquev (id, value) values (0, 1);")
            }
            /*
            #if DEBUGLOG
                    else {
            		sql = @"select value from uniquev where id=0;";
            			c = [self toQry2Int:sql];
            			DBGLog(@"uniquev= %d",c);
            		}
            #endif
            */
            //self.sql = nil;


            sqlite3_create_collation(tDb, "CMPSTRDBL", SQLITE_UTF8, nil, col_str_flt) // set how comparisons will be done on this database

            let app = UIApplication.shared // add callback to close database on app terminate
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(UIApplicationDelegate.applicationWillTerminate(_:)),
                name: UIApplication.willTerminateNotification,
                object: app)
        }
    }

    /* valid to have as nil
    - (sqlite3*) tDb {
        if (nil == tDb) {
            [self getTDb];
        }
        return tDb;
    }
    */

    func deleteTDb() {
        DBGLog(String("deleteTDb dbName= \(dbName!) id=\(toid)"))
        dbgNSAssert(dbName != nil && dbName != "", "deleteTDb called with no dbName set")
        sqlite3_close(tDb)
        tDb = nil
        if rTracker_resource.deleteFile(atPath: rTracker_resource.ioFilePath(dbName!, access: DBACCESS)) {
            dbName = nil
        } else {
            DBGErr(String("error removing tDb named \(dbName!)"))
        }
    }

    func closeTDb() {
        if tDb != nil {
            sqlite3_close(tDb)
            tDb = nil
            DBGLog(String("closed tDb: \(dbName!)"))
        //} else {
            // DBGLog(String("hey! tdb close when tDb already closed \(dbName!)"))
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
            i = toQry2Int(sql:"select value from uniquev where id=0;")!
            DBGLog(String("id \(toid) getUnique got \(i)"))
            toExecSql(sql:"update uniquev set value = \(i+1) where id=0;")
        }
        return i
    }

    func minUniquev(_ minU: Int) {
        let i = toQry2Int(sql:"select value from uniquev where id=0;")!
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
        DBGErr(String("tob error preparing -> \(sql) <- : \(sqlite3_errmsg(tDb)!) toid \(toid) dbName \(dbName!)"))
    }

    func tobDoneCheck(_ rslt: Int, sql: String?) {
        if rslt != SQLITE_DONE {
            DBGErr(String("tob error not SQL_DONE (\(rslt)) -> \(sql) <- : \(sqlite3_errmsg(tDb)!) toid \(toid) dbName \(dbName!)"))
        }
    }

    func tobExecError(_ sql: String?) {
        DBGErr(String("tob error executing -> \(sql) <- : \(sqlite3_errmsg(tDb)!) toid \(toid) dbName \(dbName!)"))
    }

    // MARK: -
    // MARK: sql query execute methods

    func toQry2AryS(sql: String) -> [String] {

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

    func toQry2AryIS(sql: String) -> [(Int, String)] {

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

    func toQry2AryISI(sql: String) -> [(Int, String, Int)] {
        
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


    func toQry2AryISII(sql: String) -> [(Int, String, Int, Int)] {
        
        SQLDbg(String("toQry2AryISII: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryISII called with no tDb")
            return []
        }
        
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
            return []
        }
    }

    func toQry2ArySS(sql: String) -> [(String, String)] {
        
        SQLDbg(String("toQry2ArySS: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2ArySS called with no tDb")
            return []
        }
        
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


    func toQry2AryIIS(sql: String) -> [(Int, Int, String)] {
        
        SQLDbg(String("toQry2AryIIS: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryIIS called with no tDb")
            return []
        }
        
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


    func toQry2AryIISIII(sql: String) -> [(Int, Int, String, Int, Int, Int)] {
        
        SQLDbg(String("toQry2AryIISIII: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryIISIII called with no tDb")
            return []
        }
        
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
                SQLDbg(String("  rslt: \(i1) \(i2) \(s1) \(i3) \(i4) \(i5)"))
            }
            sqlite3_finalize(stmt)
            return results
        } else {
            tobPrepError(sql)
            return []
        }
    }

    func toQry2AryID(sql: String) -> [(Int, Double)] {
        
        SQLDbg(String("toQry2AryID: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryID called with no tDb")
            return []
        }
        
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

    func toQry2AryI(sql: String) -> [Int] {
        
        SQLDbg(String("toQry2AryI: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryI called with no tDb")
            return []
        }
        
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

    func toQry2DictII(sql: String?) -> [Int : Int] {
        SQLDbg(String("toQry2DictII: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2DictII called with no tDb")
            return [:]
        }

        var stmt: OpaquePointer?
        var dict: [Int: Int] = [:]

        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            //var rslt: Int
            while sqlite3_step(stmt) == SQLITE_ROW {
                dict[Int(sqlite3_column_int(stmt, 0))] = Int(sqlite3_column_int(stmt, 1))
                SQLDbg(String("  rslt: \(sqlite3_column_int(stmt, 0)) -> \(dict[Int(sqlite3_column_int(stmt, 0))])"))
            }
            //tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        SQLDbg(String("  returns \(dict)"))
        return dict
    }

    func toQry2SetI(sql: String) -> Set<Int> {
        SQLDbg(String("toQry2SetI: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2SetI called with no tDb")
            return []
        }

        var stmt: OpaquePointer?
        var set = Set<Int>()

        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            //var rslt: Int
            while sqlite3_step(stmt) == SQLITE_ROW {
                set.insert(Int(sqlite3_column_int(stmt, 0)))
                SQLDbg(String("  rslt: \(sqlite3_column_int(stmt, 0)) "))
            }
            //tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg(String("  returns \(set)"))
        return set
    }

    func toQry2IntInt(sql: String) -> (Int, Int)? {
        SQLDbg(String("toQry2AryII: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryII called with no tDb")
            return nil
        }

        var stmt: OpaquePointer?
        var i1:Int = 0, i2:Int = 0
        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                i1 = Int(sqlite3_column_int(stmt, 0))
                i2 = Int(sqlite3_column_int(stmt, 1))
                SQLDbg(String("  rslt: \(i1) \(i2)"))
            }
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        SQLDbg(String("  returns \(i1) \(i2)"))
                       
        return (i1, i2)
    }

    func toQry2IntIntInt(sql: String) -> (Int, Int, Int)? {
            SQLDbg(String("toQry2IntIntInt: \(dbName!) => _\(sql)_"))
            guard let tDb = tDb else {
                dbgNSAssert(false, "toQry2IntIntInt called with no tDb")
                return nil
            }

            var stmt: OpaquePointer?
            var i1:Int = 0, i2:Int = 0, i3:Int = 0
            if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    i1 = Int(sqlite3_column_int(stmt, 0))
                    i2 = Int(sqlite3_column_int(stmt, 1))
                    i3 = Int(sqlite3_column_int(stmt, 2))
                    SQLDbg(String("  rslt: \(i1) \(i2) \(i3)"))
                }
            } else {
                tobPrepError(sql)
            }
            sqlite3_finalize(stmt)
            SQLDbg(String("  returns \(i1) \(i2) \(i3)"))
                           
            return (i1, i2, i3)
        }

    func toQry2Int(sql: String) -> Int? {
        SQLDbg(String("toQry2Int: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2Int called with no tDb")
            return nil
        }

        var stmt: OpaquePointer?
        var irslt = 0
        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                irslt = Int(sqlite3_column_int(stmt, 0))
            }
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        SQLDbg("  returns \(irslt)")

        return irslt
    }

    func toQry2Str(sql: String) -> String? {
        SQLDbg(String("toQry2StrCopy: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2StrCopy called with no tDb")
            return nil
        }

        var stmt: OpaquePointer?
        var srslt : String?
        
        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            if (sqlite3_step(stmt)) == SQLITE_ROW {
                let textPointer = sqlite3_column_text(stmt, 0)
                if let textPointer = textPointer {
                    srslt = rTracker_resource.fromSqlStr(String(cString: textPointer))
                }
            } else {
                tobExecError(sql)
            }
            //[self tobDoneCheck:rslt];
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg(String("  returns _\(srslt)_"))

        return srslt
    }

    func toQry2I12aS1(sql: String) -> ([Int], String)? {

        SQLDbg(String("toQry2AryI11S1: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2AryI11S1 called with no tDb")
            return nil
        }

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
                    srslt = rTracker_resource.fromSqlStr(String(cString: textPointer))!
                }
                SQLDbg(String("  rslt: \(arr[0]) \(arr[1]) \(arr[2]) \(arr[3]) \(arr[4]) \(arr[5]) \(arr[6]) \(arr[7]) \(arr[8]) \(arr[9]) \(arr[10]) \(arr[11]) \(srslt)"))
            }
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        SQLDbg(String("  returns \(arr[0]) \(arr[1]) \(arr[2]) \(arr[3]) \(arr[4]) \(arr[5]) \(arr[6]) \(arr[7]) \(arr[8]) \(arr[9]) \(arr[10]) \(arr[11]) \(srslt)"))
        return (arr, srslt)
    }

    func toQry2Float(sql: String) -> Float? {
        SQLDbg(String("toQry2Float: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2Float called with no tDb")
            return nil
        }

        var stmt: OpaquePointer?
        var frslt: Float = 0.0

        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                frslt = Float(sqlite3_column_double(stmt, 0))
            }
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        SQLDbg(String("  returns \(frslt)"))

        return frslt
    }

    func toQry2Double(sql: String) -> Double? {
        SQLDbg(String("toQry2Double: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2Double called with no tDb")
            return nil
        }

        var stmt: OpaquePointer?
        var drslt = 0.0
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                drslt = sqlite3_column_double(stmt, 0)
            }
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        SQLDbg("  returns \(drslt)")

        return drslt
    }

    func toExecSql(sql: String) {
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
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
    }

    // so we can ignore error when adding column
    func toExecSqlIgnErr(sql: String) {
        SQLDbg(String("toExecSqlIgnErr: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toExecSqlIgnErr called with no tDb")
            return
        }

        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(tDb, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    func toQry2Log(sql: String) {
        #if DEBUGLOG
        SQLDbg(String("toQry2Log: \(dbName!) => _\(sql)_"))
        guard let tDb = tDb else {
            dbgNSAssert(false, "toQry2Log called with no tDb")
            return
        }

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
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        #endif
    }
}
