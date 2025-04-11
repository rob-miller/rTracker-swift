//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// notifyReminder.swift
/// Copyright 2013-2021 Robert T. Miller
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
//  notifyReminder.swift
//  rTracker
//
//  Created by Rob Miller on 07/11/2013.
//  Copyright (c) 2013 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

//#import "trackerObj.h"

/*
 weekdays : 7 bits
 monthdays : 31 bits
 everyMode : int (5) (3-4 bits?)
 */

//#define EV_MINUTES (0x01 << 0)  // default 0 is valid as minutes
let EV_MINUTES = 0
let EV_HOURS = 0x01 << 0
let EV_DAYS = 0x01 << 1
let EV_WEEKS = 0x01 << 2
let EV_MONTHS = 0x01 << 3

let EV_MASK = EV_HOURS | EV_DAYS | EV_WEEKS | EV_MONTHS


/*
 bools:
 fromSave
 until
 interval/random

 everyVal : int
 start : int (1440)
 until : int (1440)
 times : int

 message : nsstring

 sound : alert/banner : badge  -- can only be alert/banner; badge is for all pending rTracker notifications, sound to be done but just one

 enable / disable toggle ?

 */

class notifyReminder: NSObject {
    /*{
     
     int rid;
     
     uint32_t monthDays;
     uint8_t weekDays;
     uint8_t everyMode;
     
     int everyVal;
     int start;        // -1 for not used
     int until;
     int times;
     
     
     NSString *msg;
     NSString *soundFileName;
     
     BOOL timesRandom;
     BOOL reminderEnabled;
     BOOL untilEnabled;
     BOOL fromLast;
     
     NSInteger tid;
     NSInteger vid;   // 0 => tracker OR not used if start valid
     
     int saveDate;
     
     UNMutableNotificationContent *notifContent;
     
     //trackerObj *to;
     }*/
    
    var rid = 0
    var monthDays: UInt32 = 0
    var weekDays: UInt8 = 0
    var everyMode: UInt8 = 0
    var everyVal = 0
    var start = 0
    var until = 0
    var times = 0
    var tid = 0
    var vid = 0
    var msg: String?
    var soundFileName: String?
    var timesRandom = false
    var reminderEnabled = false
    var untilEnabled = false
    var fromLast = false
    var saveDate = 0
    var notifContent: UNMutableNotificationContent?
    //var uNid: String?
    
    let UNTILFLAG = 0x01 << 0
    let TIMESRFLAG = 0x01 << 1
    let ENABLEFLAG = 0x01 << 2
    let FROMLASTFLAG = 0x01 << 3
    
    override init() {
        
        super.init()
        notifContent = nil
        saveDate = Int(Date().timeIntervalSince1970)
        soundFileName = nil
        self.clearNR()
    }
    
    //@property (nonatomic,retain) trackerObj *to;
    
    //-(id) init:(trackerObj*) tObjIn;
    
    /*
     - (id)init:(trackerObj*) tObjIn {
     if ((self = [self init])) {
     //DBGLog(@"init trackerObj id: %d",tid);
     self.to = tObjIn;
     [self initReminderTable];
     [self nextRid];
     }
     return self;
     }
     */
    
    convenience init(_ inRid: NSNumber?, to: trackerObj?) {
        self.init()
        //DBGLog(@"init trackerObj id: %d",tid);
        //[self initReminderTable];
        loadRid(String(format: "rid=%d and tid=%ld", inRid?.intValue ?? 0, Int(to!.toid)), to: to!)
        DBGLog("\(self)")
        
    }
    
    init(dict: [AnyHashable : Any]?) {
        
        super.init()
        rid = (dict?["rid"] as? NSNumber)?.intValue ?? 0
        monthDays = (dict?["monthDays"] as? NSNumber)?.uint32Value ?? 0
        weekDays = UInt8((dict?["weekDays"] as? NSNumber)?.uint32Value ?? 0)
        everyMode = UInt8((dict?["everyMode"] as? NSNumber)?.uint32Value ?? 0)
        everyVal = (dict?["everyVal"] as? NSNumber)?.intValue ?? 0
        start = (dict?["start"] as? NSNumber)?.intValue ?? 0
        until = (dict?["until"] as? NSNumber)?.intValue ?? 0
        times = (dict?["times"] as? NSNumber)?.intValue ?? 0
        msg = dict?["msg"] as? String
        soundFileName = dict?["soundFile"] as? String
        
        putFlags(UInt((dict?["flags"] as? NSNumber)?.uint32Value ?? 0))
        
        tid = (dict?["tid"] as? NSNumber)?.intValue ?? 0
        vid = (dict?["vid"] as? NSNumber)?.intValue ?? 0
        
        saveDate = (dict?["saveDate"] as? NSNumber)?.intValue ?? 0
        DBGLog(String(describing: self))
    }
    
    deinit {
        DBGLog("nr dealloc");
        // do not remove here as may cancel out of changes
        //UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(rid)"])

    }
    
    func save(_ to: trackerObj) {
        let flags = getFlags()
        
        DBGLog(String(describing: self))
        let sql = String(format: "insert or replace into reminders (rid, monthDays, weekDays, everyMode, everyVal, start, until, times, flags, tid, vid, saveDate, msg, soundFileName) values (%ld, %d, %d, %d,%ld, %ld, %ld, %ld, %d, %ld, %ld, %ld, '%@', '%@')", rid, monthDays, weekDays, everyMode, everyVal, start, until, times, flags, tid, vid, saveDate, msg ?? "", soundFileName ?? "")
        DBGLog(String("save sql= \(sql)"))
        to.toExecSql(sql:sql)
        //sql = nil;
    }
    
    /*
     // not used - db updates only on tracker saveConfig
     - (void) delete:(trackerObj*)to {
     if (!self.rid) return;
     sql = [NSString stringWithFormat:@"delete from reminders where rid=%d",self.rid];
     [to toExecSql:sql];
     //sql = nil;
     }
     */
    func getFlags() -> UInt {
        var flags: UInt = 0
        if timesRandom {
            flags |= UInt(TIMESRFLAG)
        }
        if reminderEnabled {
            flags |= UInt(ENABLEFLAG)
        }
        if untilEnabled {
            flags |= UInt(UNTILFLAG)
        }
        if fromLast {
            flags |= UInt(FROMLASTFLAG)
        }
        return flags
    }
    
    func putFlags(_ flags: UInt) {
        timesRandom = Int(flags) & TIMESRFLAG != 0 ? true : false
        reminderEnabled = Int(flags) & ENABLEFLAG != 0 ? true : false
        untilEnabled = Int(flags) & UNTILFLAG != 0 ? true : false
        fromLast = Int(flags) & FROMLASTFLAG != 0 ? true : false
    }
    
    //-(void) delete:(id)to;
    func loadRid(_ sqlWhere: String?, to: trackerObj) {
        var sql = "select rid, monthDays, weekDays, everyMode, everyVal, start, until, times, flags, tid, vid, saveDate, msg from reminders where \(sqlWhere ?? "")"
        //let arr = [Int](repeating: 0, count: 12)
        var flags: UInt = 0
        let (arr, str) = to.toQry2I12aS1(sql: sql)
        
        //DBGLog(@"read msg: %@",tmp);
        if 0 != arr[0] {
            // && (arr[0] != self.rid)) {
            rid = arr[0]
            monthDays = UInt32(arr[1])
            weekDays = UInt8(arr[2])
            everyMode = UInt8(arr[3])
            everyVal = arr[4]
            start = arr[5]
            until = arr[6]
            times = arr[7]
            flags = UInt(arr[8])
            tid = arr[9]
            vid = arr[10]
            saveDate = arr[11]
            
            putFlags(flags)
            
            msg = str
            sql = "select soundFileName from reminders where \(sqlWhere ?? "")"
            soundFileName = to.toQry2Str(sql:sql)
            if "(null)" == soundFileName {
                soundFileName = nil
            }
        } else {
            clearNR()
            rid = 0
            saveDate = Int(Date().timeIntervalSince1970)
            msg = to.trackerName
            tid = to.toid
        }
        
        //sql = nil;
        
        DBGLog(String(describing: self))
    }
    
    func dictFromNR() -> [String : Any]? {
        let flags = getFlags()
        return [
            "rid": NSNumber(value: rid),
            "monthDays": NSNumber(value: monthDays),
            "weekDays": NSNumber(value: weekDays),
            "everyMode": NSNumber(value: everyMode),
            "everyVal": NSNumber(value: everyVal),
            "start": NSNumber(value: start),
            "until": NSNumber(value: until),
            "times": NSNumber(value: times),
            "msg": msg ?? "",
            "soundFile": soundFileName ?? "",
            "flags": NSNumber(value: flags),
            "tid": NSNumber(value: tid),
            "vid": NSNumber(value: vid),
            "saveDate": NSNumber(value: saveDate)
        ]
    }
    
    func clearNR() {
        //self.rid=0; // need to keep if set
        monthDays = 0
        weekDays = 0
        everyMode = 0
        everyVal = 0
        start = 7 * 60
        until = 23 * 60
        untilEnabled = false
        times = 0
        //if (nil != to) {
        //    self.msg = to.trackerName;
        //    self.tid = to.toid;
        //} else {
        msg = nil
        tid = 0
        //}
        //self.soundFileName=nil;
        timesRandom = false
        reminderEnabled = true
        untilEnabled = false
        fromLast = false
        vid = 0
        //self.saveDate=0;  // need to keep if set
    }
    
    func hrVal(_ val: Int) -> Int {
        return val / 60
    }
    
    func mnVal(_ val: Int) -> Int {
        return val % 60
    }
    
    func timeStr(_ val: Int) -> String? {
        if -1 == val {
            return "-"
        }
        return String(format: "%02ld:%02ld", hrVal(val), mnVal(val))
    }
    
    override var description: String {
        var desc = String(format: "nr:%ld ", rid)
        
        if start > -1 {
            desc = desc + "start \(timeStr(start) ?? "") "
        }
        
        if untilEnabled {
            desc = desc + "until \(timeStr(until) ?? "") "
        }
        
        if monthDays != 0 {
            //var i: Int
            var nma:[String] = []
            for i in 0..<32 {
                if Int(monthDays) & (0x01 << i) != 0 {
                    nma.append("\(i + 1)")
                }
            }
            desc = desc + "monthDays:\(nma.joined(separator: ",")) "
        } else if everyVal != 0 {
            
            switch everyMode {
            case UInt8(EV_HOURS):
                desc = desc + String(format: "every %ld Hours ", everyVal)
            case UInt8(EV_DAYS):
                desc = desc + String(format: "every %ld Days ", everyVal)
            case UInt8(EV_WEEKS):
                desc = desc + String(format: "every %ld Weeks ", everyVal)
            case UInt8(EV_MONTHS):
                desc = desc + String(format: "every %ld Months ", everyVal)
            default:
                desc = desc + String(format: "every %ld Minutes ", everyVal)
            }
            
            if fromLast {
                if vid != 0 {
                    desc = desc + String(format: "from last vid:%ld ", vid)
                } else {
                    desc = desc + String(format: "from last tracker:%ld ", tid)
                }
            }
        } else {
            // if (self.nr.weekDays)  = default if nothing set
            desc = desc + "weekdays: "
            
            let firstWeekDay = Calendar.current.firstWeekday
            let dateFormatter = DateFormatter()
            var weekdays = [Int](repeating: 0, count: 7)
            var wdNames = [String](repeating: "", count: 7)

            for i in 0..<7 {
                var wd = firstWeekDay + i
                if wd > 7 {
                    wd -= 7
                }
                weekdays[i] = wd - 1  // firstWeekday is 1-indexed, switch to 0-indexed
                wdNames[i] = dateFormatter.shortWeekdaySymbols[weekdays[i]]
            }

            for i in 0..<7 {
                if (self.weekDays & (0x01 << weekdays[i])) != 0 {
                    desc += "\(wdNames[i]) "
                }
            }
        }
        
        desc = desc + "msg:'\(msg ?? "")' "
        desc = desc + "saveDate:'\(Date(timeIntervalSince1970: TimeInterval(saveDate)))' "
        
        if nil == soundFileName {
            desc = desc + "default sound "
        } else {
            desc = desc + "soundfile \(soundFileName ?? "") "
        }
        
        if reminderEnabled {
            desc = desc + "enabled"
        } else {
            desc = desc + "disabled"
        }
        
        return desc
    }
    
    func create() {
        if nil == notifContent {
            notifContent = UNMutableNotificationContent()
        }
        
        //self.notifContent.timeZone = [NSTimeZone defaultTimeZone];
        
        notifContent?.body = msg ?? ""
        notifContent?.title = NSLocalizedString("rTracker reminder", comment: "")
        
        notifContent?.badge = NSNumber(value: 1)
        
        if nil == soundFileName || ("" == soundFileName) {
            notifContent?.sound = UNNotificationSound.default
        } else {
            notifContent?.sound = UNNotificationSound(named: UNNotificationSoundName(soundFileName!))
        }
        notifContent?.launchImageName = rTracker_resource.getLaunchImageName() ?? ""
        
        //NSDictionary *infoDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.tid] forKey:@"tid"];
        let infoDict = [
            "tid": NSNumber(value: tid),
            "rid": NSNumber(value: rid),
            "soundfile": NSString(string:soundFileName ?? "")
        ]
        notifContent?.userInfo = infoDict
        DBGLog("created. \(infoDict)")
    }
    
    func cancelOld() {
        let center = UNUserNotificationCenter.current()
        let idArr = ["\(tid)-\(rid)"]
        center.removePendingNotificationRequests(withIdentifiers: idArr)
    }
    
    func schedule(_ targDate: Date?) {
        cancelOld() // remove any notifications set with rid instead of tid-rid
        if nil == notifContent {
            create()
        }
        if nil == notifContent {
            return
        }
        
        let center = UNUserNotificationCenter.current()
        /*
         [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
         if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
         return; // Notifications not allowed
         }
         }];
         */
        if !rTracker_resource.getNotificationsEnabled() {
            return // Notifications not allowed
        }
        
        let idStr = String(format: "%ld-%ld", tid, rid)
        
        var triggerDate: DateComponents? = nil
        if let targDate {
            //triggerDate = Calendar.current.components([.year + .month + .day + .hour + .minute + .second],from: targDate!)
            let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
            triggerDate = Calendar.current.dateComponents(components, from: targDate)
        }
        
        var trigger: UNCalendarNotificationTrigger? = nil
        if let triggerDate {
            trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        }
        
        var request: UNNotificationRequest? = nil
        if let notifContent {
            request = UNNotificationRequest(identifier: idStr, content: notifContent, trigger: trigger)
        }
        
        if let request {
            center.add(request, withCompletionHandler: { error in
                if let error {
                    DBGErr(String("error scheduling reminder \(idStr): \(error)"))
                }
            })
        }
        
        DBGLog(String("scheduled \(idStr)"))
    }
    
    func playSound() {
        rTracker_resource.playSound(soundFileName)
    }
    
    // process (callback) with the list of rid's for pending notifications for this tid
    static func useRidArray(_ center: UNUserNotificationCenter, tid: Int, callback: @escaping ([String]) -> Void) {
        var ridArray = [String]()
        center.getPendingNotificationRequests { notifications in
            for notification in notifications {
                let userInfo = notification.content.userInfo
                if let notificationTid = userInfo["tid"] as? Int, notificationTid == tid {
                    let components = notification.identifier.components(separatedBy: "-")
                    if let rid = components.last {
                        ridArray.append(rid)
                    }
                }
            }
            DBGLog("rid array = \(ridArray)")
            callback(ridArray)
        }
    }
}
     
    
