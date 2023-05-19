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
    var tDb: sqlite3?
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
            name: UIApplicationDelegate.willTerminateNotification,
            object: nil)
        //object:app];
        closeTDb()




    }

    @objc func applicationWillTerminate(_ notification: Notification) {
        DBGLog("tObjBase: app will terminate: toid= %ld", toid)
        closeTDb()
    }

    func getTDb() {
        //DBGLog(@"getTDb dbName= %@ id=%d",self.dbName,self.toid);
        dbgNSAssert(dbName, "getTDb called with no dbName set")

        if tDb != nil {
            return // don't instantiate if already open
        }

        //if (sqlite3_open([[rTracker_resource ioFilePath:self.dbName access:DBACCESS] UTF8String], &_tDb) != SQLITE_OK) {
        if sqlite3_open_v2(
            rTracker_resource.ioFilePath(dbName, access: DBACCESS)?.utf8CString,
            &tDb,
            SQLITE_OPEN_FILEPROTECTION_COMPLETE | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE,
            nil) != SQLITE_OK {
            sqlite3_close(tDb)
            dbgNSAssert(0, "error opening rTracker database")
        } else {
            //DBGLog(@"opened tDb %@",self.dbName);
            var c: Int

            var sql = "create table if not exists uniquev (id integer primary key, value integer);"
            toExecSql(sql)
            sql = "select count(*) from uniquev where id=0;"
            c = toQry2Int(sql)

            if c == 0 {
                DBGLog("init uniquev")
                sql = "insert into uniquev (id, value) values (0, 1);"
                toExecSql(sql)
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
                name: UIApplicationDelegate.willTerminateNotification,
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
        DBGLog("deleteTDb dbName= %@ id=%ld", dbName, toid)
        dbgNSAssert(dbName, "deleteTDb called with no dbName set")
        sqlite3_close(tDb)
        tDb = nil
        if rTracker_resource.deleteFile(atPath: rTracker_resource.ioFilePath(dbName, access: DBACCESS)) {
            dbName = nil
        } else {
            DBGErr("error removing tDb named %@", dbName)
        }
    }

    func closeTDb() {
        if tDb != nil {
            sqlite3_close(tDb)
            tDb = nil
            DBGLog("closed tDb: %@", dbName)
        } else {
            DBGLog("hey! tdb close when tDb already closed %@", dbName)
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
            var sql = "select value from uniquev where id=0;"
            i = toQry2Int(sql)
            DBGLog("id %ld getUnique got %ld", toid, i)
            sql = String(format: "update uniquev set value = %ld where id=0;", i + 1)
            toExecSql(sql)
            //self.sql = nil;
        }
        return i
    }

    func minUniquev(_ minU: Int) {
        var i: Int
        var sql = "select value from uniquev where id=0;"
        i = toQry2Int(sql)
        if i <= minU {
            sql = String(format: "update uniquev set value = %ld where id=0;", minU + 1)
            toExecSql(sql)
            //self.sql = nil;
        }
    }

    // MARK: -
    // MARK: escape chars for sql store (apostrophe)

    // move to rTracker_resource

    // MARK: -
    // MARK: sql db errors

    func tobPrepError(_ sql: String?) {
        DBGErr("tob error preparing -> %@ <- : %s toid %ld dbName %@", sql, sqlite3_errmsg(tDb), toid, dbName)
    }

    func tobDoneCheck(_ rslt: Int, sql: String?) {
        if rslt != SQLITE_DONE {
            DBGErr("tob error not SQL_DONE (%d) -> %@ <- : %s toid %ld dbName %@", rslt, sql, sqlite3_errmsg(tDb), toid, dbName)
        }
    }

    func tobExecError(_ sql: String?) {
        DBGErr("tob error executing -> %@ <- : %s toid %ld dbName %@", sql, sqlite3_errmsg(tDb), toid, dbName)
    }

    // MARK: -
    // MARK: sql query execute methods

    func toQry2AryS(_ inAry: inout [AnyHashable], sql: String?) {

        SQLDbg("toQry2AryS: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryS called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)
        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                let rslts = UnsafePointer<Int8>(Int8(sqlite3_column_text(stmt, 0)))
                let tlentry = rTracker_resource.fromSqlStr(NSNumber(value: rslts))
                inAry.append(tlentry)
                SQLDbg("  rslt: %@", tlentry)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %@", inAry)
    }

    func toQry2AryIS(_ i1: inout [AnyHashable], s1: inout [AnyHashable], sql: String?) {


        SQLDbg("toQry2AryIS: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryIS called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)
        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                var li1: Int
                var ls1: UnsafeMutablePointer<Int8>?
                li1 = sqlite3_column_int(stmt, 0)
                ls1 = UnsafeMutablePointer<Int8>(mutating: Int8(sqlite3_column_text(stmt, 1)))

                //if (strlen(ls1)) {  // don't report if empty ? - fix problem with csv load...
                i1.append(NSNumber(value: li1))
                s1.append(rTracker_resource.fromSqlStr(NSNumber(value: ls1!)) ?? "")
                SQLDbg("  rslt: %@ %@", i1.last, s1.last)
                //}
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2AryISI(_ i1: inout [AnyHashable], s1: inout [AnyHashable], i2: inout [AnyHashable], sql: String?) {


        SQLDbg("toQry2AryISI: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryISI called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1.append(NSNumber(value: sqlite3_column_int(stmt, 0)))
                s1.append(rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 1)))) ?? "")
                i2.append(NSNumber(value: sqlite3_column_int(stmt, 2)))

                SQLDbg("  rslt: %@ %@ %@", i1.last, s1.last, i2.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2AryISII(_ i1: inout [AnyHashable], s1: inout [AnyHashable], i2: inout [AnyHashable], i3: inout [AnyHashable], sql: String?) {


        SQLDbg("toQry2AryISII: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryISI called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1.append(NSNumber(value: sqlite3_column_int(stmt, 0)))
                s1.append(rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 1)))) ?? "")
                i2.append(NSNumber(value: sqlite3_column_int(stmt, 2)))
                i3.append(NSNumber(value: sqlite3_column_int(stmt, 3)))

                SQLDbg("  rslt: %@ %@ %@ %@", i1.last, s1.last, i2.last, i3.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2ArySS(_ s1: inout [AnyHashable], s2: inout [AnyHashable], sql: String?) {


        SQLDbg("toQry2ArySS: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2ArySS called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                s1.append(rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 0)))) ?? "")

                s2.append(rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 1)))) ?? "")

                SQLDbg("  rslt: %@ %@", s1.last, s2.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2AryIIS(_ i1: inout [AnyHashable], i2: inout [AnyHashable], s1: inout [AnyHashable], sql: String?) {
        // not used

        SQLDbg("toQry2AryIIS: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryIIS called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1.append(NSNumber(value: sqlite3_column_int(stmt, 0)))

                i2.append(NSNumber(value: sqlite3_column_int(stmt, 1)))

                s1.append(rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 2)))) ?? "")

                SQLDbg("  rslt: %@ %@ %@", i1.last, i2.last, s1.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    //- (void) toQry2AryIIS : (NSMutableArray *) i1 i2: (NSMutableArray *) i2 s1: (NSMutableArray *) s1;
    func toQry2AryIISIII(_ i1: inout [AnyHashable], i2: inout [AnyHashable], s1: inout [AnyHashable], i3: inout [AnyHashable], i4: inout [AnyHashable], i5: inout [AnyHashable], sql: String?) {


        SQLDbg("toQry2AryIISII: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryIISII called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1.append(NSNumber(value: sqlite3_column_int(stmt, 0)))

                i2.append(NSNumber(value: sqlite3_column_int(stmt, 1)))

                s1.append(rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 2)))) ?? "")

                i3.append(NSNumber(value: sqlite3_column_int(stmt, 3)))

                i4.append(NSNumber(value: sqlite3_column_int(stmt, 4)))
                i5.append(NSNumber(value: sqlite3_column_int(stmt, 5)))

                SQLDbg("  rslt: %@ %@ %@ %@ %@ %@", i1.last, i2.last, s1.last, i4.last, i4.last, i5.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2AryID(_ i1: inout [AnyHashable], d1: inout [AnyHashable], sql: String?) {
        SQLDbg("toQry2AryID: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryIF called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1.append(NSNumber(value: sqlite3_column_int(stmt, 0)))
                d1.append(NSNumber(value: sqlite3_column_double(stmt, 1)))

                SQLDbg("  rslt: %@ %@", i1.last, d1.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2AryI(_ inAry: inout [AnyHashable], sql: String?) {

        SQLDbg("toQry2AryI: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryI called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                inAry.append(NSNumber(value: sqlite3_column_int(stmt, 0)))
                SQLDbg("  rslt: %@", inAry.last)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %@", inAry)
    }

    func toQry2DictII(_ dict: inout [AnyHashable : Any], sql: String?) {
        SQLDbg("toQry2DictII: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2DictII called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                dict[NSNumber(value: sqlite3_column_int(stmt, 0))] = NSNumber(value: sqlite3_column_int(stmt, 1))
                SQLDbg("  rslt: %@ -> %@", NSNumber(value: sqlite3_column_int(stmt, 0)), dict[NSNumber(value: sqlite3_column_int(stmt, 0))])
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %@", dict)

    }

    func toQry2SetI(_ set: inout Set<AnyHashable>, sql: String?) {
        SQLDbg("toQry2SetI: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2SetI called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                set.insert(NSNumber(value: sqlite3_column_int(stmt, 0)))
                SQLDbg("  rslt: %@ ", NSNumber(value: sqlite3_column_int(stmt, 0)))
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %@", set)

    }

    func toQry2IntInt(_ i1: UnsafeMutablePointer<Int>?, i2: UnsafeMutablePointer<Int>?, sql: String?) {
        var i1 = i1
        var i2 = i2

        SQLDbg("toQry2AryII: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryII called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            i1 = nil
            i2 = nil
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1 = sqlite3_column_int(stmt, 0)
                i2 = sqlite3_column_int(stmt, 1)
                SQLDbg("  rslt: %d %d", i1, i2)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %d %d", i1, i2)
    }

    func toQry2IntIntInt(_ i1: UnsafeMutablePointer<Int>?, i2: UnsafeMutablePointer<Int>?, i3: UnsafeMutablePointer<Int>?, sql: String?) {
        var i1 = i1
        var i2 = i2
        var i3 = i3

        SQLDbg("toQry2IntIntInt: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2IntIntInt called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            i1 = nil
            i2 = nil
            i3 = nil
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                i1 = sqlite3_column_int(stmt, 0)
                i2 = sqlite3_column_int(stmt, 1)
                i3 = sqlite3_column_int(stmt, 2)
                SQLDbg("  rslt: %ld %ld %ld", Int(i1 ?? 0), Int(i2 ?? 0), Int(i3 ?? 0))
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %ld %ld %ld", Int(i1 ?? 0), Int(i2 ?? 0), Int(i3 ?? 0))
    }

    func toQry2Int(_ sql: String?) -> Int {
        SQLDbg("toQry2Int: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2Int called with no tDb")

        var stmt: sqlite3_stmt?
        var irslt = 0
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                irslt = sqlite3_column_int(stmt, 0)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %d", irslt)

        return irslt
    }

    func toQry2Str(_ sql: String?) -> String? {
        SQLDbg("toQry2StrCopy: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2StrCopy called with no tDb")

        var stmt: sqlite3_stmt?
        var srslt = ""
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            //int rslt;
            if (sqlite3_step(stmt)) == SQLITE_ROW {
                if sqlite3_column_text(stmt, 0) {
                    srslt = rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 0)))) ?? ""
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
        SQLDbg("  returns _%@_", srslt)

        return srslt
    }

    func toQry2I12aS1(_ arr: UnsafeMutablePointer<Int>?, sql: String?) -> String? {

        SQLDbg("toQry2AryI11S1: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2AryI11S1 called with no tDb")

        var stmt: sqlite3_stmt?
        var srslt = ""
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            var i: Int
            for i in 0..<12 {
                arr?[i] = nil
            }

            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                for i in 0..<12 {
                    arr?[i] = sqlite3_column_int(stmt, i)
                }
                srslt = rTracker_resource.fromSqlStr(NSNumber(value: Int8(sqlite3_column_text(stmt, 12)))) ?? ""
                SQLDbg("  rslt: %d %d %d %d %d %d %d %d %d %d %d %d %@", arr?[0], arr?[1], arr?[2], arr?[3], arr?[4], arr?[5], arr?[6], arr?[7], arr?[8], arr?[9], arr?[10], arr?[11], srslt)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %d %d %d %d %d %d %d %d %d %d %d %d %@", arr?[0], arr?[1], arr?[2], arr?[3], arr?[4], arr?[5], arr?[6], arr?[7], arr?[8], arr?[9], arr?[10], arr?[11], srslt)
        return srslt
    }

    func toQry2Float(_ sql: String?) -> Float {
        SQLDbg("toQry2Float: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2Float called with no tDb")

        var stmt: sqlite3_stmt?
        var frslt: Float = 0.0
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                frslt = Float(sqlite3_column_double(stmt, 0))
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %f", frslt)

        return frslt
    }

    func toQry2Double(_ sql: String?) -> Double {
        SQLDbg("toQry2Double: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2Double called with no tDb")

        var stmt: sqlite3_stmt?
        var drslt = 0.0
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                drslt = sqlite3_column_double(stmt, 0)
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        SQLDbg("  returns %f", drslt)

        return drslt
    }

    func toExecSql(_ sql: String?) {
        SQLDbg("toExecSql: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toExecSql called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) != SQLITE_DONE {
                tobExecError(sql)
            }
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    // so we can ignore error when adding column
    func toExecSqlIgnErr(_ sql: String?) {
        SQLDbg("toExecSqlIgnErr: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toExecSqlIgnErr called with no tDb")

        var stmt: sqlite3_stmt?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
    }

    func toQry2Log(_ sql: String?) {
        #if DEBUGLOG
        SQLDbg("toQry2Log: %@ => _%@_", dbName, sql)
        dbgNSAssert(tDb, "toQry2Log called with no tDb")

        var stmt: sqlite3_stmt?
        var srslt: String?
        objc_sync_enter(self)

        if sqlite3_prepare_v2(tDb, sql?.utf8CString, -1, &stmt, nil) == SQLITE_OK {
            var rslt: Int
            let c = sqlite3_column_count(stmt)
            var i: Int
            var cols = ""
            for i in 0..<c {
                cols = cols + (String(utf8String: sqlite3_column_name(stmt, i)) ?? "")
                cols = cols + " "
            }
            print("\(cols)  (db)")
            while (rslt = sqlite3_step(stmt)) == SQLITE_ROW {
                cols = ""
                for i in 0..<c {
                    srslt = String(utf8String: Int8(sqlite3_column_text(stmt, i)))
                    cols = cols + (srslt ?? "")
                    cols = cols + " "
                }
                print("\(cols)")
            }
            tobDoneCheck(rslt, sql: sql)
        } else {
            tobPrepError(sql)
        }
        sqlite3_finalize(stmt)
        objc_sync_exit(self)
        #endif
    }
}