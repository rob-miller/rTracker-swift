//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/

import UIKit
///************
/// RootViewController.swift
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
//  RootViewController.swift
//  rTracker
//
//  This is the first interactive screen, showing a list of the available trackers plus
// top:
//  - button to add a new tracker
//  - button to edit the list of available trackers
//
// bottom:
//  - pay button
//  - button to set privacy level
//  - button to graph multiple trackers together
//  - ??? export button ???
//
//  Created by Robert Miller on 16/03/2010.
//  Copyright Robert T. Miller 2010. All rights reserved.
//

///************
/// RootViewController.swift
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
//  RootViewController.swift
//  rTracker
//
//  Created by Robert Miller on 16/03/2010.
//  Copyright Robert T. Miller 2010. All rights reserved.
//

import UserNotifications

import Foundation

public class RootViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {
    var tableView: UITableView?
    
    //var _privacyObj: privacyV?
    //var int32_t: _Atomic?
    var initialPrefsLoad = false
    var readingFile = false

    //var refreshLock: Bool = false
    let atomicLock = AtomicTestAndSet(initialValue: false)
    
    //var aAdSupport: adSupport?
    //loadInputFiles
    //refreshView
    //animated
    //refreshEditBtn
    //tname
    //tid
    //rejectable
    //nsnTid
    //pendingNotificationCount

    // MARK: -
    // MARK: load CSV files waiting for input
    var csvLoadCount = 0
    var plistLoadCount = 0
    var csvReadCount = 0
    var plistReadCount = 0
    var InstallSamples = false
    var InstallDemos = false
    var loadingCsvFiles = false
    var loadingInputFiles = false
    var stashAnimated = false

    //openUrlLock, inputURL,

    // MARK: -
    // MARK: core object methods and support

    deinit {
        DBGLog("rvc dealloc")
    }
    
    var _tlist: trackerList?
    var tlist: trackerList {
        if _tlist == nil {
            let tmptlist = trackerList()
            _tlist = tmptlist
            
            if self.tlist.recoverOrphans() {
                rTracker_resource.alert("Recovered files", msg: "One or more tracker files were recovered, please delete if not needed.", vc: self)
            }
            self.tlist.loadTopLayoutTable()
        }
        return _tlist!
    }

    //
    // original code:
    //-------------------
    //  Created by Matt Gallagher on 2009/11/30.
    //  Copyright 2009 Matt Gallagher. All rights reserved.
    //
    //  Permission is given to use this source code file, free of charge, in any
    //  project, commercial or otherwise, entirely at your risk, with the condition
    //  that any redistribution (in part or whole) of source code must retain
    //  this copyright and permission notice. Attribution in compiled projects is
    //  appreciated but not required.
    //-------------------

    func doCSVLoad(_ csvString: String?, to: trackerObj?, fname: String?) {

        DBGLog(String("start csv parser \(to?.trackerName)"))
        let parser = CSVParser(string: csvString, separator: ",", hasHeader: true, fieldNames: nil)
        to?.csvProblem = nil
        to?.csvReadFlags = 0
        parser.parseRows(forReceiver: to, selector: #selector(trackerObj.receiveRecord(_:))) // receiveRecord in trackerObj.m
        DBGLog(String("csv parser done \(to?.trackerName)"))

        to?.loadConfig()

        if (to?.csvReadFlags ?? 0) & (CSVCREATEDVO | CSVCONFIGVO | CSVLOADRECORD) != 0 {

            to?.goRecalculate = true
            to?.recalculateFns() // updates fn vals in database
            to?.goRecalculate = false
            DBGLog(String("functions recalculated \(to?.trackerName)") )

            to?.saveChoiceConfigs() // in case csv data had unrecognised choices

            DBGLog("csv loaded:")
            #if DEBUGLOG
            to?.describe()
            #endif
        }
        if (to?.csvReadFlags ?? 0) & CSVNOTIMESTAMP != 0 {
            rTracker_resource.alert("No timestamp column", msg: "The file \(fname ?? "") has been rejected by the CSV loader as it does not have '\(TIMESTAMP_LABEL)' as the first column.", vc: self)
            //[rTracker_resource finishActivityIndicator:self.view navItem:nil disable:NO];
            return
        } else if (to?.csvReadFlags ?? 0) & CSVNOREADDATE != 0 {
            rTracker_resource.alert("Date format problem", msg: "Some records in the file \(fname ?? "") were ignored because timestamp dates like '\(to?.csvProblem ?? "")' are not compatible with your device's calendar settings (\(to?.dateFormatter?.string(from: Date()) ?? "")).  Please modify the file or change your international locale preferences in System Settings and try again.", vc: self)
            //[rTracker_resource finishActivityIndicator:self.view navItem:nil disable:NO];
            return
        }

        rTracker_resource.setProgressVal((Float(csvReadCount)) / (Float(csvLoadCount)))

        csvReadCount += 1




    }

    func startLoadActivityIndicator(_ str: String?) {
        rTracker_resource.startActivityIndicator(view, navItem: nil, disable: false, str: str)
    }

    func loadTrackerCsvFiles() {
        //DBGLog(@"loadTrackerCsvFiles");
        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir)
        var newRtcsvTracker = false
        var rtcsv = false

        // var file: String?

        jumpMaxPriv()
        while let file = dirEnum?.nextObject() as? URL {
            var to: trackerObj? = nil
            let fname = file.lastPathComponent
            var tname: String? = nil
            var inmatch: NSRange?
            var validMatch = false
            var loadObj: String?

            if file.pathExtension == "csv" {
                #if DEBUGLOG
                loadObj = "csv"
                #endif
                let range = (fname as NSString?)!.range(of: "_in.csv", options: [.backwards, .anchored])
                inmatch = range
                
                //DBGLog(@"consider input: %@",fname);

                if (inmatch!.location != NSNotFound) && (inmatch!.length == 7) {
                    // matched all 7 chars of _in.csv at end of file name  (must test not _out.csv)
                    validMatch = true
                }
            } else if file.pathExtension == "rtcsv" {
                rtcsv = true
                loadObj = "rtcsv"
                let range = (fname as NSString?)?.range(of: ".rtcsv", options: [.backwards, .anchored])
                inmatch = range!
                
                //DBGLog(@"consider input: %@",fname);

                if (inmatch!.location != NSNotFound) && (inmatch!.length == 6) {
                    // matched all 6 chars of .rtcsv at end of file name  (unlikely to fail but need inmatch to get tname)
                    validMatch = true
                }
            }

            if validMatch {
                tname = (fname as NSString?)?.substring(to: inmatch!.location)
                DBGLog(String("\(loadObj) load input: \(fname) as \(tname)"))
                //[rTracker_resource startActivityIndicator:self.view navItem:nil disable:NO str:@"loading data..."];
                //safeDispatchSync(^{
                //    [rTracker_resource startActivityIndicator:self.view navItem:nil disable:NO str:[NSString stringWithFormat:@"loading %@...", tname]];
                //});

                let tid = tlist.getTIDfromName(tname)
                if tid != 0 {
                    to = trackerObj(tid)
                    DBGLog(String(" found existing tracker tid \(tid) with matching name"))
                } else if rtcsv {
                    to = trackerObj()
                    to?.trackerName = tname
                    to?.toid = tlist.getUnique()
                    to?.saveConfig()
                    tlist.add(toTopLayoutTable: to!)
                    newRtcsvTracker = true
                    DBGLog(String("created new tracker for rtcsv, id= \(to?.toid)"))
                }

                if nil != to {
                    safeDispatchSync({ [self] in
                        rTracker_resource.startActivityIndicator(view, navItem: nil, disable: false, str: "loading \(tname ?? "")...")
                    })

                    let target = file // URL(fileURLWithPath: docsDir ?? "").appendingPathComponent(file ?? "").path
                    var csvString: String? = nil
                    do {
                        csvString = try String(contentsOfFile: target.absoluteString, encoding: .utf8)

                        safeDispatchSync({ [self] in
                            UIApplication.shared.isIdleTimerDisabled = true
                            doCSVLoad(csvString, to: to, fname: fname)
                            UIApplication.shared.isIdleTimerDisabled = false
                        })
                        _ = rTracker_resource.deleteFile(atPath: target.absoluteString)
                    } catch {
                    }

                    //[rTracker_resource stashProgressBarMax:(int)[rTracker_resource countLines:csvString]];


                    safeDispatchSync({ [self] in
                        rTracker_resource.finishActivityIndicator(view, navItem: nil, disable: false)
                    })
                }
            }
        }

        restorePriv()

        if newRtcsvTracker {
            refreshViewPart2()
        }
    }

    // load a tracker from NSDictionary generated by trackerObj:dictFromTO()
    //    [consists of tid, optDict and valObjTable]
    //    if trackerName match
    //      if different tid
    //         change tid of existing to input new
    //      merge new trackerObj:
    //         update vids as needed
    //         add valObjs as needed
    //    else
    //      if existing tid match
    //         move existing to new tid
    //      add new tracker
    //
    //  added nov 2012
    //
    func loadTrackerDict(_ tdict: [AnyHashable : Any]?, tname: String?) -> Int {

        // get input tid
        let newTID = (tdict?["tid"])! as! Int
        DBGLog(String("load input: \(tname) tid \(newTID)"))

        let newTIDi = newTID
        var matchTID = -1
        let tida = tlist.getTIDFromNameDb(tname)

        // find tracker with same name and tid, or just same name
        for tid in tida {
            if (-1 == matchTID) || (tid == newTID) {
                matchTID = tid
            }
        }

        DBGLog(String("matchTID= \(matchTID)"))

        var inputTO: trackerObj?
        if -1 != matchTID {
            // found tracker with same name and maybe same tid
            if !loadingDemos {
                rTracker_resource.stashTracker(matchTID) // make copy of current tracker so can reject newTID later
            }
            tlist.updateTID(matchTID, new: newTIDi) // change existing tracker tid to match new (restore if we discard later)

            inputTO = trackerObj(newTIDi) // load up existing tracker config

            inputTO?.confirmTOdict(tdict) // merge valObjs
            inputTO?.prevTID = matchTID
            inputTO?.saveConfig() // write to db -- probably redundant as confirmTOdict writes to db as well

            DBGLog(String("updated \(tname)"))

            //DBGLog(@"skip load plist file as already have %@",tname);
        } else {
            // new tracker coming in
            tlist.fixDictTID(tdict) // move any existing TIDs out of way
            inputTO = trackerObj(dict: tdict) // create new tracker with input data
            inputTO?.prevTID = matchTID
            inputTO?.saveConfig() // write to db
            tlist.add(toTopLayoutTable: inputTO!) // insert in top list
            DBGLog(String("loaded new \(tname)"))
        }


        return newTIDi
    }

    // MARK: -
    // MARK: load .plists and .rtrks for input trackers

    func handleOpenFileURL(_ url: URL?, tname: String?) -> Int {
        var tname = tname
        var tdict: [AnyHashable : Any]? = nil
        var dataDict: [String : [String : String]]? = nil
        var tid: Int

        DBGLog(String("open url \(url)"))

        jumpMaxPriv()
        if nil != tname {
            // if tname set it is just a plist
            if let url {
                tdict = NSDictionary(contentsOf: url) as Dictionary?
            }
        } else {
            // else is an rtrk
            var rtdict: [AnyHashable : Any]? = nil
            if let url {
                rtdict = NSDictionary(contentsOf: url) as Dictionary?
            }
            tname = rtdict?["trackerName"] as? String
            tdict = rtdict?["configDict"] as? [AnyHashable : Any]
            dataDict = rtdict?["dataDict"] as? [String : [String : String]]
            if loadingDemos {
                tlist.deleteTrackerAllTID(tdict?["tid"] as? NSNumber, name: tname) // wipe old demo tracker otherwise starts to look ugly
            }
        }

        //DBGLog(@"ltd enter dict= %lu",(unsigned long)[tdict count]);
        tid = loadTrackerDict(tdict, tname: tname)

        if nil != dataDict {
            let to = trackerObj(tid)

            to.loadDataDict(dataDict!) // vids ok because confirmTOdict updated as needed
            to.goRecalculate = true
            to.recalculateFns() // updates fn vals in database
            to.goRecalculate = false
            to.saveChoiceConfigs() // in case input data had unrecognised choices

            DBGLog("datadict loaded for open file url:")
            #if DEBUGLOG
            to.describe()
            #endif
        }

        DBGLog("ltd/ldd finish")

        restorePriv()
        DBGLog(String("removing file \(url?.path)"))
        _ = rTracker_resource.deleteFile(atPath: url?.path)

        return tid
    }

    func loadTrackerPlistFiles() -> Bool {
        // called on refresh, loads any _in.plist files as trackers
        // also called if any .rtrk files exist
        DBGLog("loadTrackerPlistFiles")
        var rtrkTid = 0

        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir)

        var filesToProcess: [AnyHashable] = []
        while let file = dirEnum?.nextObject() as? URL {
            let fname = file.lastPathComponent
            if file.pathExtension == "plist" {
                let inmatch = (fname as NSString?)?.range(of: "_in.plist", options: [.backwards, .anchored])
                //DBGLog(@"consider input: %@",fname);
                if (inmatch?.location != NSNotFound) && ((inmatch?.length ?? 0) == 9) {
                    // matched all 9 chars of _in.plist at end of file name
                    filesToProcess.append(file)
                }
            } else if file.pathExtension == "rtrk" {
                filesToProcess.append(file)
            }
        }

        for file in filesToProcess {
            guard let file = file as? URL else {
                continue
            }
            //var target: String?
            var newTarget: String?
            var plistFile = false

            let fname = file.lastPathComponent
            DBGLog(String("process input: \(fname)"))

            //target = file // URL(fileURLWithPath: docsDir ?? "").appendingPathComponent(file ?? "").path

            newTarget = file.absoluteString + "_reading".replacingOccurrences(of: "Documents/Inbox/", with: "Documents/")

            var err: Error?
            do {
                try localFileManager.moveItem(atPath: file.absoluteString, toPath: newTarget ?? "")
            } catch let e {
                err = e
                DBGErr(String("Error on move \(file) to \(newTarget): \(err)"))
            }

            readingFile = true

            let inmatch = (fname as NSString?)?.range(of: "_in.plist", options: [.backwards, .anchored])

            safeDispatchSync({ [self] in
                UIApplication.shared.isIdleTimerDisabled = true

                if (inmatch?.location != NSNotFound) && ((inmatch?.length ?? 0) == 9) {
                    // matched all 9 chars of _in.plist at end of file name
                    rtrkTid = handleOpenFileURL(URL(fileURLWithPath: newTarget ?? ""), tname: (fname as NSString?)?.substring(to: inmatch?.location ?? 0))
                    plistFile = true
                } else {
                    // .rtrk file
                    rtrkTid = handleOpenFileURL(URL(fileURLWithPath: newTarget ?? ""), tname: nil)
                }

                UIApplication.shared.isIdleTimerDisabled = false
            })

            if plistFile {
                rTracker_resource.rmStashedTracker(0) // 0 means rm last stashed tracker, in this case the one stashed by handleOpenFileURL
            } else {
                stashedTIDs.append(NSNumber(value: rtrkTid))
            }

            readingFile = false

            rTracker_resource.setProgressVal((Float(plistReadCount)) / (Float(plistLoadCount)))
            plistReadCount += 1
        }

        return (rtrkTid != 0)
    }

    @objc func doLoadCsvFiles() {
        if loadingCsvFiles {
            return
        }
        loadingCsvFiles = true
        autoreleasepool {

            loadTrackerCsvFiles()
            safeDispatchSync({ [self] in
                // csv file load done, close activity indicators
                rTracker_resource.finishProgressBar(view, navItem: navigationItem, disable: true)
                rTracker_resource.finishActivityIndicator(view, navItem: navigationItem, disable: false)
            })

            // give up lock
            //refreshLock = false
            _ = atomicLock.testAndSet(newValue: false)
            loadingCsvFiles = false
            DispatchQueue.main.async(execute: { [self] in
                refreshToolBar(true)
            })
            DBGLog(String("csv data loaded, UI enabled, CSV lock off stashedTIDs= \(stashedTIDs)"))

            if 0 < stashedTIDs.count {
                doRejectableTracker()
            }
        }

        // thread finished
    }

    func refreshViewPart2() {
        //DBGLog(@"entry");
        tlist.confirmToplevelTIDs()
        tlist.loadTopLayoutTable()
        DispatchQueue.main.async(execute: { [self] in
            tableView!.reloadData()
            refreshEditBtn()
            refreshToolBar(true)
            view.setNeedsDisplay()
        })
        // no effect [self.tableView setNeedsDisplay];
    }

    @objc func doLoadInputfiles() {
        if loadingInputFiles {
            return
        }
        if loadingCsvFiles {
            return
        }
        loadingInputFiles = true
        autoreleasepool {

            if InstallDemos {
                _ = loadDemos(true)
                InstallDemos = false
            }

            if InstallSamples {
                _ = loadSamples(true)
                InstallSamples = false
            }

            if loadTrackerPlistFiles() {
                // this thread now completes updating rvc display of trackerList as next step is load csv data and trackerlist won't change (unless rtrk files)
                tlist.loadTopLayoutTable() // called again in refreshviewpart2, but need for re-order to set ranks
                tlist.reorderFromTLT()
            }

            safeDispatchSync({ [self] in
                //[rTracker_resource finishProgressBar:self.view navItem:self.navigationItem disable:YES];
                if csvLoadCount != 0 {
                    rTracker_resource.finishActivityIndicator(view, navItem: nil, disable: false) // finish 'loading trackers' spinner
                    //[rTracker_resource startActivityIndicator:self.view navItem:nil disable:NO str:@"loading data..."];
                }
            })
            refreshViewPart2()

            Thread.detachNewThreadSelector(#selector(doLoadCsvFiles), toTarget: self, with: nil)

            loadingInputFiles = false
            DBGLog("load plist thread finished, lock off, UI enabled, dispatched CSV load")
        }
        // end of this thread, refreshLock still on, userInteraction disabled, activityIndicator still spinning and doLoadCsvFiles is in charge
    }

    func countInputFiles(_ targ_ext: String?) -> Int {
        var retval = 0

        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir)

        while let file = dirEnum?.nextObject() as? URL {
            let fname = file.lastPathComponent
            //DBGLog(@"consider input file %@",fname);
            let inmatch = (fname as NSString?)?.range(of: targ_ext ?? "", options: [.backwards, .anchored])
            if inmatch?.location != NSNotFound {
                DBGLog(String("existsInputFiles: match on \(fname)"))
                retval += 1
                
            }
        }

        return retval
    }

    func loadInputFiles() {
        if loadingInputFiles {
            return
        }
        if loadingCsvFiles {
            return
        }
        //if (!self.openUrlLock) {
        csvLoadCount = countInputFiles("_in.csv")
        plistLoadCount = countInputFiles("_in.plist")
        let rtrkLoadCount = countInputFiles(".rtrk")
        csvLoadCount += countInputFiles(".rtcsv")

        // handle rtrks as plist + csv, just faster if only has data or only has tracker def
        csvLoadCount += rtrkLoadCount
        plistLoadCount += rtrkLoadCount

        if InstallSamples {
            plistLoadCount += loadSamples(false)
        }
        if InstallDemos {
            plistLoadCount += loadDemos(false)
        }

        // set rvc:static numerators for progress bars
        csvReadCount = 1
        plistReadCount = 1

        if 0 < (plistLoadCount + csvLoadCount) {
            tableView!.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true) // ScrollToTop so can see bars
            rTracker_resource.startActivityIndicator(view, navItem: nil, disable: false, str: "loading trackers...")
            rTracker_resource.startProgressBar(view, navItem: navigationItem, disable: true, yloc: 0.0)

            Thread.detachNewThreadSelector(#selector(doLoadInputfiles), toTarget: self, with: nil)
            // lock stays on, userInteraction disabled, activityIndicator spinning,   give up and doLoadInputFiles() is in charge

            DBGLog("returning main thread, lock on, UI disabled, activity spinning,  files to load")
            return
        }
        //}

        // if here (did not return above), no files to load, this thread set the lock and refresh is done now

        refreshViewPart2()
        //refreshLock = false
        _ = atomicLock.testAndSet(newValue: false)
        DBGLog("finished, no files to load - lock off")

        return
    }

    let SUPPLY_DEMOS = 0
    let SUPPLY_SAMPLES = 1

    func loadSuppliedTrackers(_ doLoad: Bool, set: Int) -> Int {
        // loads sample tracker plist files which are slurped in as dicts.  demo tracker is .rtrk (rtcsv) file and loaded differently
        let bundle = Bundle.main
        var paths: [AnyHashable]?
        if SUPPLY_DEMOS == set {
            paths = bundle.paths(forResourcesOfType: "plist", inDirectory: "demoTrackers")
        } else {
            paths = bundle.paths(forResourcesOfType: "plist", inDirectory: "sampleTrackers")
        }
        var count = 0

        /* copy plists over version
             NSString *docsDir = [rTracker_resource ioFilePath:nil access:YES];
             NSFileManager *dfltManager = [NSFileManager defaultManager];
             */

        //DBGLog(@"paths %@",paths  );


        for p in paths ?? [] {
            guard let p = p as? String else {
                continue
            }

            if doLoad {
                // load now into trackerObj - needs progressBar
                let tdict = NSDictionary(contentsOfFile: p) as Dictionary?
                tlist.fixDictTID(tdict)
                let newTracker = trackerObj(dict: tdict)

                tlist.deConflict(newTracker) // add _n to trackerName so we don't overwrite user's existing if any .. could just merge now?

                newTracker.saveConfig()
                tlist.add(toTopLayoutTable: newTracker)

                rTracker_resource.setProgressVal((Float(plistReadCount)) / (Float(plistLoadCount)))
                plistReadCount += 1

                DBGLog(String("finished loadSample on \(p)"))
            }
            count += 1
        }

        if doLoad {
            var sql: String
            if SUPPLY_DEMOS == set {
                sql = String(format: "insert or replace into info (val, name) values (%i,'demos_version')", DEMOS_VERSION)
            } else {
                sql = String(format: "insert or replace into info (val, name) values (%i,'samples_version')", SAMPLES_VERSION)
            }
            tlist.toExecSql(sql:sql)
        }

        return count

    }

    func loadSamples(_ doLoad: Bool) -> Int {
        // called when handlePrefs decides is needed, copies plist files to documents dir
        // also called with doLoad=NO to just count
        // returns count

        let count = loadSuppliedTrackers(doLoad, set: SUPPLY_SAMPLES)

        return count
    }

    func loadDemos(_ doLoad: Bool) -> Int {

        //return [self loadSuppliedTrackers:doLoad set:SUPPLY_DEMOS];
        //var newp: String?
        let bundle = Bundle.main
        let paths = bundle.paths(forResourcesOfType: "rtrk", inDirectory: "demoTrackers")
        let urls = paths.map { URL(fileURLWithPath: $0) }
        
        let fm = FileManager.default
        let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var count = 0

        loadingDemos = true
        for p in urls {
            if doLoad {
                let file = p.lastPathComponent
                //newp = [rTracker_resource ioFilePath:[NSString stringWithFormat:@"Inbox/%@",file] access:YES];
                //newp = rTracker_resource.ioFilePath("\(file)", access: true)

                let destinationURL = documentsURL.appendingPathComponent(file)

                do {
                    try fm.copyItem(atPath: p.path, toPath: destinationURL.path)  // FileManager.default.copyItem(atPath: p.absoluteString, toPath: newp ?? "")

                    _ = handleOpenFileURL(URL(fileURLWithPath: destinationURL.path), tname: nil)
                    //DBGLog(@"stashedTIDs= %@",self.stashedTIDs);
                } catch let err {
                    DBGErr(String("Error copying file: \(p.path) to \(destinationURL.path) error: \(err)"))
                    count -= 1
                }
            }
            count += 1
        }
        if doLoad && count != 0 {
            let sql = String(format: "insert or replace into info (val, name) values (%i,'demos_version')", DEMOS_VERSION)
            tlist.toExecSql(sql:sql)
        }
        loadingDemos = false
        return count
    }

    // MARK: -
    // MARK: view support

    func scrollState() {
        if let privacyObj = _privacyObj, privacyObj.showing != PVNOSHOW {
            // test backing ivar first -- don't instantiate if not there
            tableView!.isScrollEnabled = false
            //DBGLog(@"no");
        } else {
            tableView!.isScrollEnabled = true
            //DBGLog(@"yes");
        }
    }

    func refreshToolBar(_ animated: Bool) {
        //DBGLog(@"refresh tool bar, noshow= %d",(PVNOSHOW == self.privacyObj.showing));
        setToolbarItems(
            [flexibleSpaceButtonItem, helpBtn, privateBtn].compactMap { $0 },
            animated: animated)
    }

    func initTitle() {

        // set up the window title, try to get owner's name

        let devname = UIDevice.current.name
        //DBGLog(@"name = %@",devname);
        let words = devname.components(separatedBy: " ")
        let bname = Bundle.main.infoDictionary?["CFBundleName"] as? String // @"rTracker";  default title
        var rtitle = bname
        
        // if devname looks like "foo bar's iPhone" then title is "foo bar's tracks"
        var owner: String? = nil
        var foundOwner = false
        for w in words {
            if owner != nil {
                owner! += " \(w)"
            } else {
                owner = w
            }
            if w.hasSuffix("'s") {
                foundOwner = true
                break
            }
        }
        if foundOwner {
            rtitle = "\(owner!) tracks"
        }
        
        // if rtitle is too long go back to rTracker
        var bw1: CGFloat = 0.0
        var bw2: CGFloat = 0.0
        let view = editBtn.value(forKey: "view") as? UIView
        bw1 = view != nil ? ((view?.frame.size.width ?? 0.0) + (view?.frame.origin.x ?? 0.0)) : CGFloat(53.0) // hardcode after change from leftBarButton to backBarButton
        let view2 = addBtn.value(forKey: "view") as? UIView
        bw2 = (view2 != nil ? view2?.frame.origin.x : CGFloat(282.0)) ?? 0.0

        if (0.0 == bw1) || (0.0 == bw2) {
            rtitle = bname // "rTracker"
        } else {
            let maxWidth = (bw2 - bw1) - 8 //self.view.bounds.size.width - btnWidths;
            //DBGLog(@"view wid= %f bw1= %f bw2= %f",self.view.bounds.size.width ,bw1,bw2);

            let namesize = rtitle!.size(withAttributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20.0)
            ])
            let nameWidth = ceil(namesize.width)
            if nameWidth >= maxWidth {
                rtitle = bname // "rTracker"
            }
        }
        
        title = rtitle
        DBGLog("title= \(rtitle!)")
        
        /*
        let c = words.count
        var name: String? = nil

        for i in 0..<c {
            var w: String? = nil
            w = words[i]
            if "" != w {
                name = w
            }
        }


        let prodNdx = 0
        var longName = words[0]

        for prodNdx in 0..<c {
            if (.orderedSame == "iphone".caseInsensitiveCompare(words[prodNdx])) || (.orderedSame == "ipad".caseInsensitiveCompare(words[prodNdx])) || (.orderedSame == "ipod".caseInsensitiveCompare(words[prodNdx])) || (.orderedSame == "itouch".caseInsensitiveCompare(words[prodNdx])) {
                break
            }
        }
        if (1 <= prodNdx) && (prodNdx < c) {
            for i in 1..<prodNdx {
                longName = longName + " \(words[i])"
            }
        } else if (0 == prodNdx) || (prodNdx >= c) {
            longName = ""
        }
        #if RELEASE
        let ReleaseFlag = true
        #else
        let ReleaseFlag = false
        #endif
        #if NONAME
        let NoNameFlag = true
        #else
        let NoNameFlag = false
        #endif
        
        if (nil == name)
            || (ReleaseFlag && ((name == "iPhone") || (name == "iPad")))
            || (0 == (name?.count ?? 0))
            || NoNameFlag  {
            title = Bundle.main.infoDictionary?["CFBundleName"] as? String // @"rTracker";
        } else {
         
            var bw1: CGFloat = 0.0
            var bw2: CGFloat = 0.0
            let view = editBtn.value(forKey: "view") as? UIView
            bw1 = view != nil ? ((view?.frame.size.width ?? 0.0) + (view?.frame.origin.x ?? 0.0)) : CGFloat(53.0) // hardcode after change from leftBarButton to backBarButton
            let view2 = addBtn.value(forKey: "view") as? UIView
            bw2 = (view2 != nil ? view2?.frame.origin.x : CGFloat(282.0)) ?? 0.0

            if (0.0 == bw1) || (0.0 == bw2) {
                rtitle = "rTracker"
            } else {
                var tname: String? = nil
                var tn2: String?

                let r0 = (name as NSString?)?.rangeOfCharacter(from: CharacterSet(charactersIn: "'`’´‘"), options: .backwards)
                if NSNotFound != r0?.location {
                    let len = name?.count ?? 0
                    let pos = (r0?.location ?? 0) + (r0?.length ?? 0)
                    if pos == (len - 1) {
                        let c = name?[name!.index(name!.startIndex, offsetBy: pos)]  // unichar(from: name?[(name?.index(name!.startIndex, offsetBy: UInt(pos)))!] ?? 0)
                        if ("s" == c) || ("S" == c) {
                            tname = (name ?? "") + " tracks"
                            tn2 = (name ?? "") + "  tracks"
                        }
                    } else if pos == len {
                        tname = (name ?? "") + " tracks"
                        tn2 = (name ?? "") + "  tracks"
                    }
                }

                if nil == tname {
                    tname = (name ?? "") + "’s tracks"
                    tn2 = (name ?? "") + " ’s tracks"
                }

                DBGLog(String("tname= \(tname) longname = \(longName)"))

                let ltname = longName + " tracks"
                let ltn2 = longName + "  tracks"

                let maxWidth = (bw2 - bw1) - 8 //self.view.bounds.size.width - btnWidths;
                //DBGLog(@"view wid= %f bw1= %f bw2= %f",self.view.bounds.size.width ,bw1,bw2);

                let namesize = tn2?.size(withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20.0)
                ])
                let nameWidth = ceil(namesize!.width)

                let lnamesize = ltn2.size(withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20.0)
                ])

                let lnameWidth = ceil(lnamesize.width)

                //DBGLog(@"name wid= %f  maxwid= %f  name= %@",nameWidth,maxWidth,tname);
                if ("" != longName) && (lnameWidth < maxWidth) {
                    title = ltname
                } else if nameWidth < maxWidth {
                    title = tname
                } else {
                    title = "rTracker"
                }
            }
        }
         */
    }


    // handle notification while in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Update the app interface directly.
        countScheduledReminders() // race me
        // nice to make this work again
        //[self doQuickAlert:notification.request.content.title msg:notification.request.content.body delay:2];
        // Play a sound.

        completionHandler(UNNotificationPresentationOptions.sound)
        tableView!.reloadData() // redundant but waiting for countScheduledReminders to complete
        view.setNeedsDisplay()
    }

    // handle notification while in background
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        DBGLog("did receive notification response while in backrgound")
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            // The user dismissed the notification without taking action.
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // The user launched the app.

            let userInfo = response.notification.request.content.userInfo
            let rootController = (navigationController?.viewControllers)?[0] as? RootViewController
            rootController?.performSelector(onMainThread: #selector(doOpenTracker(_:)), with: (userInfo)["tid"], waitUntilDone: false)
        }

        // Else handle any custom actions. . .


    }

    func setViewMode() {
        rTracker_resource.setViewMode(self)
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                // if darkMode
                tableView!.backgroundColor = UIColor.systemBackground
                return
            }
        }

        tableView!.backgroundColor = UIColor.clear
    }

    public override func viewDidLoad() {

        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self

        //DBGLog(@"rvc: viewDidLoad privacy= %d",[privacyObj getPrivacyValue]);

        //refreshLock = false
        _ = atomicLock.testAndSet(newValue: false)
        readingFile = false

        let vsize = rTracker_resource.get_visible_size(self)

        navigationItem.rightBarButtonItem = addBtn
        navigationItem.leftBarButtonItem = editBtn

        // toolbar setup
        refreshToolBar(false)

        // title setup
        initTitle()

        var tableFrame: CGRect = CGRect.zero
        tableFrame.origin.x = 0.0
        tableFrame.origin.y = 0.0
        tableFrame.size.height = vsize.height
        tableFrame.size.width = vsize.width

        DBGLog(String("tvf \(tableFrame)"))  // origin x %f y %f size w %f h %f"), tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height)
        tableView = UITableView(frame: tableFrame, style: .plain)

        //self.tableView!.translatesAutoresizingMaskIntoConstraints = NO;
        tableView!.dataSource = self
        tableView!.delegate = self

        tableView!.separatorStyle = .none

        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)

        setViewMode()
        view.addSubview(tableView!)

        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("9.0") {
            let existingShortcutItems = UIApplication.shared.shortcutItems
            if 0 == (existingShortcutItems?.count ?? 0) /*|| ([rTracker_resource getSCICount] != [existingShortcutItems count]) */ {
                // can't set more than 4 or prefs messed up
                tlist.updateShortcutItems()
            }
        }

    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView!.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    func refreshEditBtn() {

        if (tlist.topLayoutNames?.count ?? 0) == 0 {
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem = nil
            }
        } else {
            if navigationItem.leftBarButtonItem == nil {
                navigationItem.leftBarButtonItem = editBtn
                //[editBtn release];
            }
        }

    }

    func samplesNeeded() -> Bool {
        let rslt = tlist.toQry2Int(sql:"select val from info where name = 'samples_version'")
        DBGLog(String("samplesNeeded if \(SAMPLES_VERSION) != \(rslt)"))
        return SAMPLES_VERSION != rslt
    }

    func demosNeeded() -> Bool {
        let rslt = tlist.toQry2Int(sql:"select val from info where name = 'demos_version'")
        DBGLog(String("demosNeeded if \(DEMOS_VERSION) != \(rslt)"))
        #if !RELEASE
        //rslt=0;
        if 0 == rslt {
            DBGLog("forcing demosNeeded")
        }
        #endif
        return DEMOS_VERSION != rslt
    }

    func handlePrefs() {

        let sud = UserDefaults.standard
        sud.synchronize()

        let resetPassPref = sud.bool(forKey: "reset_password_pref")
        let reloadSamplesPref = sud.bool(forKey: "reload_sample_trackers_pref")

        rTracker_resource.setSeparateDateTimePicker(sud.bool(forKey: "separate_date_time_pref"))
        rTracker_resource.setRtcsvOutput(sud.bool(forKey: "rtcsv_out_pref"))
        rTracker_resource.setSavePrivate(sud.bool(forKey: "save_priv_pref"))

        //[rTracker_resource setHideRTimes:[sud boolForKey:@"hide_rtimes_pref"]];
        //[rTracker_resource setSCICount:(NSUInteger)[sud integerForKey:@"shortcut_count_pref"]];

        rTracker_resource.setToldAboutSwipe(sud.bool(forKey: "toldAboutSwipe"))
        rTracker_resource.setToldAboutNotifications(sud.bool(forKey: "toldAboutNotifications"))
        rTracker_resource.setAcceptLicense(sud.bool(forKey: "acceptLicense"))

        //DBGLog(@"entry prefs-- resetPass: %d  reloadsamples: %d",resetPassPref,reloadSamplesPref);

        if resetPassPref {
            privacyObj.resetPw()
        }

        InstallSamples = false
        InstallDemos = false
        if reloadSamplesPref {
            InstallSamples = true
            InstallDemos = true
        } else {
            if samplesNeeded() {
                InstallSamples = true
            }
            if demosNeeded() {
                //[self deleteDemos];
                InstallDemos = true
            }
        }

        DBGLog(String("InstallSamples \(InstallSamples)  InstallDemos \(InstallDemos)"))

        if resetPassPref {
            sud.set(false, forKey: "reset_password_pref")
        }
        if reloadSamplesPref {
            sud.set(false, forKey: "reload_sample_trackers_pref")
        }

        initialPrefsLoad = false

        sud.synchronize()
        /*
        #if DEBUGLOG
            resetPassPref = [sud boolForKey:@"reset_password_pref"];
            reloadSamplesPref = [sud boolForKey:@"reload_sample_trackers_pref"];

            DBGLog(@"exit prefs-- resetPass: %d  reloadsamples: %d",resetPassPref,reloadSamplesPref);
        #endif
        */
    }

    /*
     refreshView:
       loadInputFiles:
         if files to load
            thread:
              load demos, samples, plist files
              refreshViewPart2
              thread:
                load csv files
                if rtcsv (might add trackers)
                   refreshViewPart2
         else
            refreshViesPart2
      */
    func refreshView() {

        // deprecated ios 10 - if (0 != OSAtomicTestAndSet(0, &(_refreshLock))) {
        if atomicLock.testAndSet(newValue: true) {  // was 0 in objective-c ? this should be where take the lock?
            // wasn't 0 before, so we didn't get lock, so leave because refresh already in process
            return
        }

        //DBGLog(@"refreshView");
        scrollState()

        handlePrefs()

        loadInputFiles() // do this here as restarts are infrequent and prv change may enable to read more files -- calls refreshViewPart2

        countScheduledReminders()

    }

    public override func viewWillAppear(_ animated: Bool) {

        DBGLog(String("rvc: viewWillAppear privacy= \(privacyValue)"))
        countScheduledReminders()

        restorePriv()

        navigationController?.setToolbarHidden(false, animated: false)

        super.viewWillAppear(animated)
    }

    func fixFileProblem(_ choice: Int) {
        let docsDir = rTracker_resource.ioFilePath(nil, access: true)

        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir)


        while let file = dirEnum?.nextObject() as? String {
            if URL(fileURLWithPath: file).pathExtension == "rtrk_reading" {
                var err: Error?
                var target: String?
                target = URL(fileURLWithPath: docsDir).appendingPathComponent(file).path

                if 0 == choice {
                    // delete it
                    _ = rTracker_resource.deleteFile(atPath: target)
                } else {
                    // try again -- rename from .rtrk_reading to .rtrk
                    var newTarget: String?
                    newTarget = target?.replacingOccurrences(of: "rtrk_reading", with: "rtrk")
                    do {
                        try localFileManager.moveItem(atPath: target ?? "", toPath: newTarget ?? "")
                    } catch let e {
                        err = e
                        DBGLog(String("Error on move \(target) to \(newTarget): \(err)"))
                    }
                }
            }
        }

        viewDidAppearRestart()

    }

    /*
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        [self fixFileProblem:buttonIndex];
    }
    */
    func viewDidAppearRestart() {
        refreshView()

        super.viewDidAppear(stashAnimated)
    }

    @objc func doOpenTrackerRejectable(_ nsnTid: NSNumber?) {
        openTracker(nsnTid?.intValue ?? 0, rejectable: true)
    }

    @objc func doOpenTracker(_ nsnTid: NSNumber?) {
        openTracker(nsnTid?.intValue ?? 0, rejectable: false)
    }

    func doRejectableTracker() {
        //DBGLog(@"stashedTIDs= %@",self.stashedTIDs);
        let nsntid = stashedTIDs.last as? NSNumber
        performSelector(onMainThread: #selector(doOpenTrackerRejectable(_:)), with: nsntid, waitUntilDone: true)
        stashedTIDs.removeLast()
    }

    public override func viewDidAppear(_ animated: Bool) {

        //DBGLog(@"rvc: viewDidAppear privacy= %d", [privacyObj getPrivacyValue]);

        if !readingFile {
            if 0 < stashedTIDs.count {
                doRejectableTracker()
            } else {
                let docsDir = rTracker_resource.ioFilePath(nil, access: true)
                let localFileManager = FileManager.default
                let dirEnum = localFileManager.enumerator(atPath: docsDir)

                while let file = dirEnum?.nextObject() as? String {
                    let fu = URL(fileURLWithPath: file)
                    if fu.pathExtension == "rtrk_reading" {
                        //let fname = fu.lastPathComponent
                        let rtrkName = fu.deletingPathExtension().path
                        let title = "Problem reading .rtrk file?"
                        let msg = "There was a problem while loading the \(rtrkName) rtrk file"
                        let btn0 = "Delete it"
                        let btn1 = "Try again"
                        let alert = UIAlertController(
                            title: title,
                            message: msg,
                            preferredStyle: .alert)

                        let deleteAction = UIAlertAction(
                            title: btn0,
                            style: .default,
                            handler: { [self] action in
                                fixFileProblem(0)
                            })
                        let retryAction = UIAlertAction(
                            title: btn1,
                            style: .default,
                            handler: { [self] action in
                                fixFileProblem(1)
                            })

                        alert.addAction(deleteAction)
                        alert.addAction(retryAction)

                        present(alert, animated: true)
                    }
                }
            }
        } else {
            //if (self.readingFile) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        stashAnimated = animated
        viewDidAppearRestart()

        // [super viewDidApeear] called in [self viewDidAppearRestart]
    }

    public override func viewWillDisappear(_ animated: Bool) {
        DBGLog("rvc viewWillDisappear")

        UIApplication.shared.applicationIconBadgeNumber = pendingNotificationCount()
        super.viewWillDisappear(animated)
    }

    public override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.

        DBGWarn("rvc didReceiveMemoryWarning")
        // Release any cached data, images, etc that aren't in use.

        super.didReceiveMemoryWarning()




    }

    // MARK: -
    // MARK: button accessor getters

    func privBtnSetImg(_ pbtn: UIButton?, noshow: Bool) {
        //BOOL shwng = (self.privacyObj.showing == PVNOSHOW); 
        let minprv = privacyValue > MINPRIV
        let btnImg = noshow
            ? (minprv ? "shadeview-button-7.png" : "closedview-button-7.png")
            : (minprv ? "shadeview-button-blue-7.png" : "closedview-button-blue-7.png")

        DispatchQueue.main.async(execute: {
            pbtn?.setImage(UIImage(named: btnImg), for: .normal)
        })
    }

    var _privateBtn: UIBarButtonItem?
    var privateBtn: UIBarButtonItem {
        //
        if _privateBtn == nil {
            let pbtn = UIButton()
            pbtn.setImage(
                UIImage(named: "closedview-button-7.png"),
                for: .normal)
            pbtn.frame = CGRect(x: 0, y: 0, width: (pbtn.currentImage?.size.width ?? 0.0) * 1.5, height: pbtn.currentImage?.size.height ?? 0.0)
            pbtn.addTarget(self, action: #selector(btnPrivate), for: .touchUpInside)
            _privateBtn = UIBarButtonItem(
                customView: pbtn)
            privBtnSetImg(_privateBtn!.customView as? UIButton, noshow: true)
        } else {
            var noshow = true
            if _privacyObj != nil {
                noshow = PVNOSHOW == privacyObj.showing
            }
            if !(noshow) && (PWKNOWPASS == privacyObj.pwState) {
                //DBGLog(@"unlock btn");
                (_privateBtn!.customView as? UIButton)?.setImage(
                    UIImage(named: "fullview-button-blue-7.png"),
                    for: .normal)
            } else {
                //DBGLog(@"lock btn");
                privBtnSetImg(_privateBtn!.customView as? UIButton, noshow: noshow)
            }
        }


        return _privateBtn!
    }

    var _helpBtn: UIBarButtonItem?
    var helpBtn: UIBarButtonItem {
        if _helpBtn == nil {
            _helpBtn = UIBarButtonItem(
                title: "Help",
                style: .plain,
                target: self,
                action: #selector(btnHelp))
        }
        return _helpBtn!
    }

    var _addBtn: UIBarButtonItem?
    var addBtn: UIBarButtonItem {
        if _addBtn == nil {
            _addBtn = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(btnAddTracker))

            _addBtn!.style = UIBarButtonItem.Style.done
        }
        return _addBtn!
    }

    var _editBtn: UIBarButtonItem?
    var editBtn: UIBarButtonItem {
        if _editBtn == nil {
            _editBtn = UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(btnEdit))

            _editBtn!.style = UIBarButtonItem.Style.plain
        }
        return _editBtn!
    }

    var _flexibleSpaceButtonItem: UIBarButtonItem?
    var flexibleSpaceButtonItem: UIBarButtonItem {
        if _flexibleSpaceButtonItem == nil {
            _flexibleSpaceButtonItem = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)
        }
        return _flexibleSpaceButtonItem!
    }

    /*
     - (UIBarButtonItem *) multiGraphBtn {
    	if (multiGraphBtn == nil) {
    		multiGraphBtn = [[UIBarButtonItem alloc]
    					  initWithTitle:@"Multi-Graph"
    					  style:UIBarButtonItemStylePlain
    					  target:self
    					  action:@selector(btnMultiGraph)];
    	}
    	return multiGraphBtn;
    }
    */

    // MARK: -

    var _privacyObj: privacyV?
    var privacyObj: privacyV {
        if _privacyObj == nil {
            _privacyObj = privacyV(parentView: self)
        }
        _privacyObj!.tob = tlist // not set at init
        return _privacyObj!
    }

    var stashedTIDs: [AnyHashable] = []

    func countScheduledReminders() {
        
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { notifications in
            self.scheduledReminderCounts.removeAll()
            
            for i in 0..<notifications.count {
                let oneEvent = notifications[i]
                let userInfoCurrent = oneEvent.content.userInfo
                DBGLog(String("\(i) uic: \(userInfoCurrent)"))
                if let tid = userInfoCurrent["tid"] as? NSNumber {
                    var c = (self.scheduledReminderCounts[tid] as? Int) ?? 0
                    c += 1
                    self.scheduledReminderCounts[tid] = c
                }
            }
        }
    }

    // MARK: -
    // MARK: button action methods

    @objc func btnAddTracker() {
        if PVNOSHOW != privacyObj.showing {
            return
        }

        let atc = addTrackerController(nibName: "addTrackerController", bundle: nil)
        atc.tlist = tlist
        navigationController?.pushViewController(atc, animated: true)
        //[rTracker_resource myNavPushTransition:self.navigationController vc:atc animOpt:UIViewAnimationOptionTransitionCurlUp];


    }

    @IBAction func btnEdit() {

        if PVNOSHOW != privacyObj.showing {
            return
        }
        var ctlc: configTlistController?
        ctlc = configTlistController(nibName: "configTlistController", bundle: nil)
        ctlc?.tlist = tlist
        if let ctlc {
            navigationController?.pushViewController(ctlc, animated: true)
        }
    }

    func btnMultiGraph() {
        DBGLog("btnMultiGraph was pressed!")
    }

    @objc func btnPrivate() {
        tableView!.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true) // ScrollToTop
        privacyObj.togglePrivacySetter()
        if PVNOSHOW == privacyObj.showing {
            refreshView()
        }
    }

    @objc func btnHelp() {

        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://rob-miller.github.io/rTracker/rTracker/iPhone/userGuide/"]];  // deprecated ios 9
        if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/userGuide/") {
            UIApplication.shared.open(url, options: [:])
        }
    }

    func btnPay() {
        DBGLog("btnPay was pressed!")

    }

    // MARK: -
    // MARK: Table view methods
    

    var scheduledReminderCounts: [AnyHashable : Any] = [:]


    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Customize the number of rows in the table view.
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tlist.topLayoutNames?.count ?? 0
    }

    func pendingNotificationCount() -> Int {
        var erc = 0
        var src = 0
        for nsn in tlist.topLayoutReminderCount ?? [] {
            guard let nsn = nsn as? NSNumber else {
                continue
            }
            erc += nsn.intValue
        }
        for (tid, _) in scheduledReminderCounts {
            if let count = scheduledReminderCounts[tid] as? NSNumber {
                src += count.intValue
            }
        }

        return erc > src ? erc - src : 0
    }

    // Customize the appearance of table view cells.
    //DBGLog(@"rvc table cell at index %d label %@",[indexPath row],[tlist.topLayoutNames objectAtIndex:[indexPath row]]);

    static let tableViewCellIdentifier = "Cell"

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: RootViewController.tableViewCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: RootViewController.tableViewCellIdentifier)

            cell?.backgroundColor = .clear // clear here so table background shows through
        }

        // Configure the cell.
        let row = indexPath.row
        let tid = (tlist.topLayoutIDs)?[row] as? NSNumber
        let cellLabel = NSMutableAttributedString()

        let erc = ((tlist.topLayoutReminderCount)?[row] as? NSNumber)?.intValue ?? 0
        var src: Int? = nil
        if let tid {
            src = (scheduledReminderCounts[tid] as? NSNumber)?.intValue ?? 0
        }
        DBGLog(String("src: \(src)  erc:  \(erc) \(tlist.topLayoutNames![row]) (\(tid))"))
        //NSString *formatString = @"%@";
        //UIColor *bg = [UIColor clearColor];
        if erc != src {
            //formatString = @"> %@";
            //bg = [UIColor redColor];
            cellLabel.append(
                NSAttributedString(
                    string: "➜ ",
                    attributes: [
                        .foregroundColor: UIColor.red,
                        .font: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
                    ]))
        }
        //DBGLog(@"erc= %d  src= %d",erc,src);
        //[cellLabel appendAttributedString:
        // [[NSAttributedString alloc]initWithString:(self.tlist.topLayoutNames)[row] attributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}]] ;
        cellLabel.append(NSAttributedString(string: (tlist.topLayoutNames)?[row] as? String ?? ""))

        cell?.textLabel?.attributedText = cellLabel

        return cell!
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var tn: String?
        let row = indexPath.row
        if NSNotFound != row {
            tn = (tlist.topLayoutNames)?[row] as? String
        } else {
            tn = "Sample"
        }
        let tns = tn?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        return (tns?.height ?? 0.0) + (2 * MARGIN)
    }

    func exceedsPrivacy(_ tid: Int) -> Bool {
        return privacyValue < (tlist.getPrivFromLoadedTID(tid))
    }

    func openTracker(_ tid: Int, rejectable: Bool) {

        if exceedsPrivacy(tid) {
            return
        }

        let topController = navigationController?.viewControllers.last
        let rtSelector = NSSelectorFromString("rejectTracker")

        if topController?.responds(to: rtSelector) ?? false {
            // top controller is already useTrackerController, is it this tracker?
            if tid == (topController as? useTrackerController)?.tracker!.toid {
                return
            }
        }

        let to = trackerObj(tid)
        to.describe()

        let utc = useTrackerController()
        utc.tracker = to
        utc.rejectable = rejectable
        utc.tlist = tlist // required so reject can fix topLevel list
        utc.saveFrame = view.frame // self.tableView.frame; //  view.frame;
        utc.rvcTitle = title

        navigationController?.pushViewController(utc, animated: true)

    }

    // Override to support row selection in the table view.
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if PVNOSHOW != privacyObj.showing {
            return
        }

        //NSUInteger row = [indexPath row];
        //DBGLog(@"selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);
        tableView.cellForRow(at: indexPath)?.isSelected = false
        openTracker(tlist.getTIDfromIndex(indexPath.row), rejectable: false)

    }
}

/*
 {

	trackerList *tlist;
	privacyV *privacyObj;
    int32_t refreshLock;
    BOOL initialPrefsLoad;
    NSNumber *stashedPriv;
    //BOOL openUrlLock;
    //NSURL *inputURL;
    BOOL readingFile;
    NSMutableArray *stashedTIDs;
    NSMutableDictionary *scheduledReminderCounts;
}
*/
