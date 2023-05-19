//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
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

// deprecaed ios 10  #import <libkern/OSAtomic.h>
var tableView: UITableView?
var tlist: trackerList?
var privacyObj: privacyV?
var int32_t: _Atomic?
var initialPrefsLoad = false
var readingFile = false
var stashedTIDs: [AnyHashable]?
var scheduledReminderCounts: [AnyHashable : Any]?
var privateBtn: UIBarButtonItem?
var helpBtn: UIBarButtonItem?
var addBtn: UIBarButtonItem?
var editBtn: UIBarButtonItem?
var flexibleSpaceButtonItem: UIBarButtonItem?
var aAdSupport: adSupport?
//loadInputFiles
//refreshView
//animated
//refreshEditBtn
//tname
//tid
//rejectable
//nsnTid
//pendingNotificationCount

#if ADVERSION
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

class RootViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate, ADBannerViewDelegate {

    //openUrlLock, inputURL,

    // MARK: -
    // MARK: core object methods and support

    deinit {
        DBGLog("rvc dealloc")
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

        DBGLog("start csv parser %@", to?.trackerName)
        let parser = CSVParser(string: csvString, separator: ",", hasHeader: true, fieldNames: nil)
        to?.csvProblem = nil
        to?.csvReadFlags = 0
        parser.parseRows(forReceiver: to, selector: #selector(trackerObj.receiveRecord(_:))) // receiveRecord in trackerObj.m
        DBGLog("csv parser done %@", to?.trackerName)

        to?.loadConfig()

        if (to?.csvReadFlags ?? 0) & (CSVCREATEDVO | CSVCONFIGVO | CSVLOADRECORD) != 0 {

            to?.goRecalculate = true
            to?.recalculateFns() // updates fn vals in database
            to?.goRecalculate = false
            DBGLog("functions recalculated %@", to?.trackerName)

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
        let dirEnum = localFileManager.enumerator(atPath: docsDir ?? "")
        var newRtcsvTracker = false
        var rtcsv = false

        var file: String?

        privacyV.jumpMaxPriv()
        while (file = dirEnum?.nextObject() as? String) {
            var to: trackerObj? = nil
            let fname = file?.lastPathComponent
            var tname: String? = nil
            var inmatch: NSRange
            var validMatch = false
            #if DEBUGLOG
            var loadObj: String?
            #endif

            if URL(fileURLWithPath: file ?? "").pathExtension == "csv" {
                #if DEBUGLOG
                loadObj = "csv"
                #endif
                if let range = (fname as NSString?)?.range(of: "_in.csv", options: [.backwards, .anchored]) {
                    inmatch = range
                }
                //DBGLog(@"consider input: %@",fname);

                if (inmatch.location != NSNotFound) && (inmatch.length == 7) {
                    // matched all 7 chars of _in.csv at end of file name  (must test not _out.csv)
                    validMatch = true
                }
            } else if URL(fileURLWithPath: file ?? "").pathExtension == "rtcsv" {
                rtcsv = true
                #if DEBUGLOG
                loadObj = "rtcsv"
                #endif
                if let range = (fname as NSString?)?.range(of: ".rtcsv", options: [.backwards, .anchored]) {
                    inmatch = range
                }
                //DBGLog(@"consider input: %@",fname);

                if (inmatch.location != NSNotFound) && (inmatch.length == 6) {
                    // matched all 6 chars of .rtcsv at end of file name  (unlikely to fail but need inmatch to get tname)
                    validMatch = true
                }
            }

            if validMatch {
                tname = (fname as NSString?)?.substring(to: inmatch.location)
                DBGLog("%@ load input: %@ as %@", loadObj, fname, tname)
                //[rTracker_resource startActivityIndicator:self.view navItem:nil disable:NO str:@"loading data..."];
                //safeDispatchSync(^{
                //    [rTracker_resource startActivityIndicator:self.view navItem:nil disable:NO str:[NSString stringWithFormat:@"loading %@...", tname]];
                //});

                let tid = tlist()?.getTIDfromName(tname) ?? 0
                if tid != 0 {
                    to = trackerObj(tid)
                    DBGLog(" found existing tracker tid %ld with matching name", tid)
                } else if rtcsv {
                    to = trackerObj()
                    to?.trackerName = tname
                    to?.toid = tlist()?.getUnique() ?? 0
                    to?.saveConfig()
                    tlist()?.add(toTopLayoutTable: to)
                    newRtcsvTracker = true
                    DBGLog("created new tracker for rtcsv, id= %ld", Int(to?.toid ?? 0))
                }

                if nil != to {
                    safeDispatchSync({ [self] in
                        rTracker_resource.startActivityIndicator(view, navItem: nil, disable: false, str: "loading \(tname ?? "")...")
                    })

                    let target = URL(fileURLWithPath: docsDir ?? "").appendingPathComponent(file ?? "").path
                    var csvString: String? = nil
                    do {
                        csvString = try String(contentsOfFile: target, encoding: .utf8)

                        safeDispatchSync({ [self] in
                            UIApplication.shared.isIdleTimerDisabled = true
                            doCSVLoad(csvString, to: to, fname: fname)
                            UIApplication.shared.isIdleTimerDisabled = false
                        })
                        rTracker_resource.deleteFile(atPath: target)
                    } catch {
                    }

                    //[rTracker_resource stashProgressBarMax:(int)[rTracker_resource countLines:csvString]];


                    safeDispatchSync({ [self] in
                        rTracker_resource.finishActivityIndicator(view, navItem: nil, disable: false)
                    })
                }
            }
        }

        privacyV.restorePriv()

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
        let newTID = tdict?["tid"] as? NSNumber
        DBGLog("load input: %@ tid %@", tname, newTID)

        let newTIDi = newTID?.intValue ?? 0
        var matchTID = -1
        let tida = tlist()?.getTIDFromNameDb(tname)

        // find tracker with same name and tid, or just same name
        for tid in tida ?? [] {
            guard let tid = tid as? NSNumber else {
                continue
            }
            if (-1 == matchTID) || (tid == newTID) {
                matchTID = tid.intValue
            }
        }

        DBGLog("matchTID= %d", matchTID)

        var inputTO: trackerObj?
        if -1 != matchTID {
            // found tracker with same name and maybe same tid
            if !loadingDemos {
                rTracker_resource.stashTracker(matchTID) // make copy of current tracker so can reject newTID later
            }
            tlist()?.updateTID(matchTID, new: newTIDi) // change existing tracker tid to match new (restore if we discard later)

            inputTO = trackerObj(newTIDi) // load up existing tracker config

            inputTO?.confirmTOdict(tdict) // merge valObjs
            inputTO?.prevTID = matchTID
            inputTO?.saveConfig() // write to db -- probably redundant as confirmTOdict writes to db as well

            DBGLog("updated %@", tname)

            //DBGLog(@"skip load plist file as already have %@",tname);
        } else {
            // new tracker coming in
            tlist()?.fixDictTID(tdict) // move any existing TIDs out of way
            inputTO = trackerObj(dict: tdict) // create new tracker with input data
            inputTO?.prevTID = matchTID
            inputTO?.saveConfig() // write to db
            tlist()?.add(toTopLayoutTable: inputTO) // insert in top list
            DBGLog("loaded new %@", tname)
        }


        return newTIDi
    }

    // MARK: -
    // MARK: load .plists and .rtrks for input trackers

    func handleOpenFileURL(_ url: URL?, tname: String?) -> Int {
        var tname = tname
        var tdict: [AnyHashable : Any]? = nil
        var dataDict: [AnyHashable : Any]? = nil
        var tid: Int

        DBGLog("open url %@", url)

        privacyV.jumpMaxPriv()
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
            dataDict = rtdict?["dataDict"] as? [AnyHashable : Any]
            if loadingDemos {
                tlist()?.deleteTrackerAllTID(tdict?["tid"] as? NSNumber, name: tname) // wipe old demo tracker otherwise starts to look ugly
            }
        }

        //DBGLog(@"ltd enter dict= %lu",(unsigned long)[tdict count]);
        tid = loadTrackerDict(tdict, tname: tname)

        if nil != dataDict {
            let to = trackerObj(tid)

            to.loadDataDict(dataDict) // vids ok because confirmTOdict updated as needed
            to?.goRecalculate = true
            to.recalculateFns() // updates fn vals in database
            to?.goRecalculate = false
            to.saveChoiceConfigs() // in case input data had unrecognised choices

            DBGLog("datadict loaded for open file url:")
            #if DEBUGLOG
            to.describe()
            #endif
        }

        DBGLog("ltd/ldd finish")

        privacyV.restorePriv()
        DBGLog("removing file %@", url?.path)
        rTracker_resource.deleteFile(atPath: url?.path)

        return tid
    }

    func loadTrackerPlistFiles() -> Bool {
        // called on refresh, loads any _in.plist files as trackers
        // also called if any .rtrk files exist
        DBGLog("loadTrackerPlistFiles")
        var rtrkTid = 0

        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir ?? "")

        var file: String?

        var filesToProcess: [AnyHashable] = []
        while (file = dirEnum?.nextObject() as? String) {
            let fname = file?.lastPathComponent
            if URL(fileURLWithPath: file ?? "").pathExtension == "plist" {
                let inmatch = (fname as NSString?)?.range(of: "_in.plist", options: [.backwards, .anchored])
                //DBGLog(@"consider input: %@",fname);
                if (inmatch?.location != NSNotFound) && ((inmatch?.length ?? 0) == 9) {
                    // matched all 9 chars of _in.plist at end of file name
                    filesToProcess.append(file ?? "")
                }
            } else if URL(fileURLWithPath: file ?? "").pathExtension == "rtrk" {
                filesToProcess.append(file ?? "")
            }
        }

        for file in filesToProcess {
            guard let file = file as? file else {
                continue
            }
            var target: String?
            var newTarget: String?
            var plistFile = false

            let fname = file?.lastPathComponent
            DBGLog("process input: %@", fname)

            target = URL(fileURLWithPath: docsDir ?? "").appendingPathComponent(file ?? "").path

            newTarget = (target ?? "") + "_reading".replacingOccurrences(of: "Documents/Inbox/", with: "Documents/")

            var err: Error?
            do {
                if try localFileManager.moveItem(atPath: target ?? "", toPath: newTarget ?? "") != true {
                    DBGErr("Error on move %@ to %@: %@", target, newTarget, err)
                }
            } catch let e {
                err = e
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
                stashedTIDs()?.append(NSNumber(value: rtrkTid))
            }

            readingFile = false

            rTracker_resource.setProgressVal((Float(plistReadCount)) / (Float(plistLoadCount)))
            plistReadCount += 1
        }

        return Bool(rtrkTid)
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
            refreshLock = 0
            loadingCsvFiles = false
            DispatchQueue.main.async(execute: { [self] in
                refreshToolBar(true)
            })
            DBGLog("csv data loaded, UI enabled, CSV lock off stashedTIDs= %@", stashedTIDs())

            if 0 < (stashedTIDs()?.count ?? 0) {
                doRejectableTracker()
            }
        }

        // thread finished
    }

    func refreshViewPart2() {
        //DBGLog(@"entry");
        tlist()?.confirmToplevelTIDs()
        tlist()?.loadTopLayoutTable()
        DispatchQueue.main.async(execute: { [self] in
            tableView.reloadData()
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
                loadDemos(true)
                InstallDemos = false
            }

            if InstallSamples {
                loadSamples(true)
                InstallSamples = false
            }

            if loadTrackerPlistFiles() {
                // this thread now completes updating rvc display of trackerList as next step is load csv data and trackerlist won't change (unless rtrk files)
                tlist()?.loadTopLayoutTable() // called again in refreshviewpart2, but need for re-order to set ranks
                tlist()?.reorderFromTLT()
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
        let retval = 0

        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir ?? "")

        var file: String?

        while file = dirEnum?.nextObject() as? String {
            let fname = file?.lastPathComponent
            //DBGLog(@"consider input file %@",fname);
            let inmatch = (fname as NSString?)?.range(of: targ_ext ?? "", options: [.backwards, .anchored])
            if inmatch?.location != NSNotFound {
                DBGLog("existsInputFiles: match on %@", fname)
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
            tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true) // ScrollToTop so can see bars
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
        refreshLock = 0
        DBGLog("finished, no files to load - lock off")

        return
    }

    let SUPPLY_DEMOS = 0
    let SUPPLY_SAMPLES = 1

    func loadSuppliedTrackers(_ doLoad: Bool, set: Int) -> Int {
        let bundle = Bundle.main
        var paths: [AnyHashable]?
        if SUPPLY_DEMOS == set {
            paths = bundle.paths(forResourcesOfType: "plist", inDirectory: "demoTrackers")
        } else {
            paths = bundle.paths(forResourcesOfType: "plist", inDirectory: "sampleTrackers")
        }
        let count = 0

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
                tlist()?.fixDictTID(tdict)
                let newTracker = trackerObj(dict: tdict)

                tlist()?.deConflict(newTracker) // add _n to trackerName so we don't overwrite user's existing if any .. could just merge now?

                newTracker.saveConfig()
                tlist()?.add(toTopLayoutTable: newTracker)

                rTracker_resource.setProgressVal((Float(plistReadCount)) / (Float(plistLoadCount)))
                plistReadCount += 1

                DBGLog("finished loadSample on %@", p)
            }
            count += 1
        }

        if doLoad {
            var sql: String?
            if SUPPLY_DEMOS == set {
                sql = String(format: "insert or replace into info (val, name) values (%i,'demos_version')", DEMOS_VERSION)
            } else {
                sql = String(format: "insert or replace into info (val, name) values (%i,'samples_version')", SAMPLES_VERSION)
            }
            tlist()?.toExecSql(sql)
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
        var newp: String?
        let bundle = Bundle.main
        let paths = bundle.paths(forResourcesOfType: "rtrk", inDirectory: "demoTrackers")
        let count = 0

        loadingDemos = true
        for p in paths {
            if doLoad {
                let file = p.lastPathComponent
                //newp = [rTracker_resource ioFilePath:[NSString stringWithFormat:@"Inbox/%@",file] access:YES];
                newp = rTracker_resource.ioFilePath("\(file)", access: true)
                do {
                    try FileManager.default.copyItem(atPath: p, toPath: newp ?? "")

                    handleOpenFileURL(URL(fileURLWithPath: newp ?? ""), tname: nil)
                    //DBGLog(@"stashedTIDs= %@",self.stashedTIDs);
                } catch let err {
                    DBGErr("Error copying file: %@ to %@ error: %@", p, newp, err)
                    count -= 1
                }
            }
            count += 1
        }
        if doLoad && count != 0 {
            var sql: String?
            sql = String(format: "insert or replace into info (val, name) values (%i,'demos_version')", DEMOS_VERSION)
            tlist()?.toExecSql(sql)
        }
        loadingDemos = false
        return count
    }

    // MARK: -
    // MARK: view support

    func scrollState() {
        if _privacyObj && privacyObj()?.showing != PVNOSHOW {
            // test backing ivar first -- don't instantiate if not there
            tableView.isScrollEnabled = false
            //DBGLog(@"no");
        } else {
            tableView.isScrollEnabled = true
            //DBGLog(@"yes");
        }
    }

    func refreshToolBar(_ animated: Bool) {
        //DBGLog(@"refresh tool bar, noshow= %d",(PVNOSHOW == self.privacyObj.showing));
        setToolbarItems(
            [flexibleSpaceButtonItem(), helpBtn(),         //self.payBtn, 
        privateBtn()].compactMap { $0 },
            animated: animated)
    }

    func initTitle() {

        // set up the title 

        let devname = UIDevice.current.name
        //DBGLog(@"name = %@",devname);
        let words = devname.components(separatedBy: " ")

        var i = 0
        let c = words.count
        var name: String? = nil

        for i in 0..<c {
            var w: String? = nil
            w = words[i]
            if "" != w {
                name = w
            }
        }

        var prodNdx = 0
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

        if (nil == name) || (name == "iPhone") || (name == "iPad") || (0 == (name?.count ?? 0)) || true {
            title = Bundle.main.infoDictionary?["CFBundleName"] as? String // @"rTracker";
        } else {
            var bw1: CGFloat = 0.0
            var bw2: CGFloat = 0.0
            let view = editBtn()?.value(forKey: "view") as? UIView
            bw1 = view != nil ? ((view?.frame.size.width ?? 0.0) + (view?.frame.origin.x ?? 0.0)) : CGFloat(53.0) // hardcode after change from leftBarButton to backBarButton
            let view2 = addBtn()?.value(forKey: "view") as? UIView
            bw2 = (view2 != nil ? view2?.frame.origin.x : CGFloat(282.0)) ?? 0.0

            if (0.0 == bw1) || (0.0 == bw2) {
                title = "rTracker"
            } else {
                var tname: String? = nil
                var tn2: String?

                let r0 = (name as NSString?)?.rangeOfCharacter(from: CharacterSet(charactersIn: "'`’´‘"), options: .backwards)
                if NSNotFound != r0?.location {
                    let len = name?.count ?? 0
                    let pos = (r0?.location ?? 0) + (r0?.length ?? 0)
                    if pos == (len - 1) {
                        let c = unichar(name?[name?.index(name?.startIndex, offsetBy: UInt(pos))] ?? 0)
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

                DBGLog("tname= %@", tname)
                DBGLog("longName= %@", longName)

                let ltname = longName + " tracks"
                let ltn2 = longName + "  tracks"

                let maxWidth = (bw2 - bw1) - 8 //self.view.bounds.size.width - btnWidths;
                //DBGLog(@"view wid= %f bw1= %f bw2= %f",self.view.bounds.size.width ,bw1,bw2);

                let namesize = tn2?.size(withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20.0)
                ])
                let nameWidth = ceilf(namesize?.width)

                let lnamesize = ltn2.size(withAttributes: [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20.0)
                ])

                let lnameWidth = ceilf(lnamesize.width)

                //DBGLog(@"name wid= %f  maxwid= %f  name= %@",nameWidth,maxWidth,tname);
                if (nil != longName) && (lnameWidth < maxWidth) {
                    title = ltname
                } else if nameWidth < maxWidth {
                    title = tname
                } else {
                    title = "rTracker"
                }
            }
        }
    }

    #if ADVERSION

    override func viewDidLayoutSubviews() {
        if !rTracker_resource.getPurchased() {
            adSupport()?.layoutAnimated(self, tableview: tableView, animated: UIView.areAnimationsEnabled)
        }
    }

    func bannerViewDidLoadAd(_ banner: ADBannerView?) {
        adSupport()?.layoutAnimated(self, tableview: tableView, animated: true)
    }

    func bannerView(_ banner: ADBannerView?, didFailToReceiveAdWithError error: Error?) {
        adSupport()?.layoutAnimated(self, tableview: tableView, animated: true)
    }

    func bannerViewActionShouldBegin(_ banner: ADBannerView?, willLeaveApplication willLeave: Bool) -> Bool {
        //[self.adSupport stopTimer];
        return true
    }

    func adSupport() -> adSupport? {
        if !rTracker_resource.getPurchased() {
            if _adSupport == nil {
                _adSupport = adSupport?.init()
            }
        }
        return _adSupport
    }

    #endif


    // handle notification while in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Update the app interface directly.
        countScheduledReminders() // race me
        // nice to make this work again
        //[self doQuickAlert:notification.request.content.title msg:notification.request.content.body delay:2];
        // Play a sound.
        completionHandler(UNNotificationPresentationOptionSound)
        tableView.reloadData() // redundant but waiting for countScheduledReminders to complete
        view.setNeedsDisplay()
    }

    // handle notification while in background
    func userNotificationCenter(
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
                tableView.backgroundColor = UIColor.systemBackground
                return
            }
        }

        tableView.backgroundColor = UIColor.clear
    }

    override func viewDidLoad() {

        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self

        #if ADVERSION
        #if !RELEASE
        rTracker_resource.setPurchased(false)
        #endif
        if !rTracker_resource.getPurchased() {
            #if !DISABLE_ADS
            adSupport()?.initBannerView(self)
            #endif
        }
        //[self.view addSubview:self.adSupport.bannerView];
        #endif

        //DBGLog(@"rvc: viewDidLoad privacy= %d",[privacyV getPrivacyValue]);

        refreshLock = 0
        readingFile = false

        let vsize = rTracker_resource.get_visible_size(self)

        navigationItem.rightBarButtonItem = addBtn()
        navigationItem.leftBarButtonItem = editBtn()

        // toolbar setup
        refreshToolBar(false)

        // title setup
        initTitle()

        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            #if !DISABLE_ADS
            tableFrame.size.height -= adSupport()?.bannerView?.frame.size.height ?? 0.0
            DBGLog("ad h= %f  tfh= %f ", adSupport()?.bannerView?.frame.size.height, tableFrame.size.height)
            #endif
        }
        #endif

        let tableFrame: CGRect
        tableFrame.origin.x = 0.0
        tableFrame.origin.y = 0.0
        tableFrame.size.height = vsize.height
        tableFrame.size.width = vsize.width

        DBGLog("tvf origin x %f y %f size w %f h %f", tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height)
        tableView = UITableView(frame: tableFrame, style: .plain)

        //self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        tableView.dataSource = self
        tableView.delegate = self

        tableView.separatorStyle = .none

        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)

        setViewMode()
        view.addSubview(tableView)

        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("9.0") {
            let existingShortcutItems = UIApplication.shared.shortcutItems
            if 0 == (existingShortcutItems?.count ?? 0) /*|| ([rTracker_resource getSCICount] != [existingShortcutItems count]) */ {
                // can#'t set more than 4 or prefs messed up
                tlist()?.updateShortcutItems()
            }
        }

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    func tlist() -> trackerList? {
        if nil == _tlist {
            let tmptlist = trackerList()
            self.tlist() = tmptlist

            if self.tlist()?.recoverOrphans() ?? false {
                // added 07.viii.13
                rTracker_resource.alert("Recovered files", msg: "One or more tracker files were recovered, please delete if not needed.", vc: self)
            }
            self.tlist()?.loadTopLayoutTable()
        }
        return _tlist
    }

    func refreshEditBtn() {

        if (tlist()?.topLayoutNames?.count ?? 0) == 0 {
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem = nil
            }
        } else {
            if navigationItem.leftBarButtonItem == nil {
                navigationItem.leftBarButtonItem = editBtn()
                //[editBtn release];
            }
        }

    }

    func samplesNeeded() -> Bool {
        let sql = "select val from info where name = 'samples_version'"
        let rslt = tlist()?.toQry2Int(sql) ?? 0
        DBGLog("samplesNeeded if %d != %d", SAMPLES_VERSION, rslt)
        return SAMPLES_VERSION != rslt
    }

    func demosNeeded() -> Bool {
        let sql = "select val from info where name = 'demos_version'"
        let rslt = tlist()?.toQry2Int(sql) ?? 0
        DBGLog("demosNeeded if %d != %d", DEMOS_VERSION, rslt)
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
            privacyObj()?.resetPw()
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

        DBGLog("InstallSamples %d  InstallDemos %d", InstallSamples, InstallDemos)

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
        if 0 != atomic_fetch_or_explicit(0x0, 0, memory_order_relaxed) {
            // wasn't 0 before, so we didn't get lock, so leave because refresh already in process
            return
        }

        //DBGLog(@"refreshView");
        scrollState()

        handlePrefs()

        loadInputFiles() // do this here as restarts are infrequent and prv change may enable to read more files -- calls refreshViewPart2

        countScheduledReminders()

    }

    #if ADVERSION
    // handle rtPurchasedNotification
    @objc func updatePurchased(_ n: Notification?) {
        if n != nil {
            rTracker_resource.doQuickAlert("Purchase Successful", msg: "Thank you!", delay: 2, vc: self)
        }

        if nil != _adSupport {
            if adSupport()?.bannerView?.isDescendantOf(view) {
                adSupport()?.bannerView?.removeFromSuperview()
            }
            adSupport() = nil
        }
        let bg = UIImageView(image: UIImage(named: rTracker_resource.getLaunchImageName() ?? ""))
        let tableFrame = bg.frame
        tableFrame.size.height = rTracker_resource.get_visible_size(self).height // - ( 2 * statusBarHeight ) ;
        tableView.frame = tableFrame
        tableView.backgroundView = bg
        tableView.setNeedsDisplay()
        //[self.tableView reloadData];
    }

    #endif

    override func viewWillAppear(_ animated: Bool) {

        DBGLog("rvc: viewWillAppear privacy= %d", privacyV.getPrivacyValue())
        countScheduledReminders()

        privacyV.restorePriv()

        navigationController?.setToolbarHidden(false, animated: false)

        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            #if !DISABLE_ADS
            adSupport()?.initBannerView(self)
            if let aBannerView = adSupport()?.bannerView {
                view.addSubview(aBannerView)
            }
            #endif
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updatePurchased(_:)),
                name: NSNotification.Name(rtPurchasedNotification),
                object: nil)
        } else if _adSupport {
            updatePurchased(nil)
        }
        #endif

        super.viewWillAppear(animated)
    }

    func fixFileProblem(_ choice: Int) {
        let docsDir = rTracker_resource.ioFilePath(nil, access: true)

        let localFileManager = FileManager.default
        let dirEnum = localFileManager.enumerator(atPath: docsDir ?? "")

        var file: String?

        while (file = dirEnum?.nextObject() as? String) {
            if URL(fileURLWithPath: file ?? "").pathExtension == "rtrk_reading" {
                var err: Error?
                var target: String?
                target = URL(fileURLWithPath: docsDir ?? "").appendingPathComponent(file ?? "").path

                if 0 == choice {
                    // delete it
                    rTracker_resource.deleteFile(atPath: target)
                } else {
                    // try again -- rename from .rtrk_reading to .rtrk
                    var newTarget: String?
                    newTarget = target?.replacingOccurrences(of: "rtrk_reading", with: "rtrk")
                    do {
                        if try localFileManager.moveItem(atPath: target ?? "", toPath: newTarget ?? "") != true {
                            DBGLog("Error on move %@ to %@: %@", target, newTarget, err)
                            //DBGLog(@"Unable to move file: %@", [err localizedDescription]);
                        }
                    } catch let e {
                        err = e
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

        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            #if !DISABLE_ADS
            adSupport()?.layoutAnimated(self, tableview: tableView, animated: false)
            #endif
        }
        #endif

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
        let nsntid = stashedTIDs()?.last as? NSNumber
        performSelector(onMainThread: #selector(doOpenTrackerRejectable(_:)), with: nsntid, waitUntilDone: true)
        stashedTIDs()?.removeLast()
    }

    override func viewDidAppear(_ animated: Bool) {

        //DBGLog(@"rvc: viewDidAppear privacy= %d", [privacyV getPrivacyValue]);

        if !readingFile {
            if 0 < (stashedTIDs()?.count ?? 0) {
                doRejectableTracker()
            } else {
                let docsDir = rTracker_resource.ioFilePath(nil, access: true)
                let localFileManager = FileManager.default
                let dirEnum = localFileManager.enumerator(atPath: docsDir ?? "")

                var file: String?

                while (file = dirEnum?.nextObject() as? String) {
                    if URL(fileURLWithPath: file ?? "").pathExtension == "rtrk_reading" {
                        let fname = file?.lastPathComponent
                        let rtrkName = URL(fileURLWithPath: fname ?? "").deletingPathExtension().path
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

    override func viewWillDisappear(_ animated: Bool) {
        DBGLog("rvc viewWillDisappear")

        #if ADVERSION
        //unregister for purchase notices
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rtPurchasedNotification),
            object: nil)
        #endif

        UIApplication.shared.applicationIconBadgeNumber = pendingNotificationCount()
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.

        DBGWarn("rvc didReceiveMemoryWarning")
        // Release any cached data, images, etc that aren't in use.

        super.didReceiveMemoryWarning()




    }

    // MARK: -
    // MARK: button accessor getters

    func privBtnSetImg(_ pbtn: UIButton?, noshow: Bool) {
        //BOOL shwng = (self.privacyObj.showing == PVNOSHOW); 
        let minprv = privacyV.getPrivacyValue() > MINPRIV
        let btnImg = noshow
            ? (minprv ? "shadeview-button-7.png" : "closedview-button-7.png")
            : (minprv ? "shadeview-button-blue-7.png" : "closedview-button-blue-7.png")

        DispatchQueue.main.async(execute: {
            pbtn?.setImage(UIImage(named: btnImg), for: .normal)
        })
    }

    func privateBtn() -> UIBarButtonItem? {
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
            privBtnSetImg(_privateBtn.customView as? UIButton, noshow: true)
        } else {
            var noshow = true
            if _privacyObj {
                noshow = PVNOSHOW == privacyObj()?.showing
            }
            if !(noshow) && (PWKNOWPASS == privacyObj()?.pwState) {
                //DBGLog(@"unlock btn");
                (_privateBtn.customView as? UIButton)?.setImage(
                    UIImage(named: "fullview-button-blue-7.png"),
                    for: .normal)
            } else {
                //DBGLog(@"lock btn");
                privBtnSetImg(_privateBtn.customView as? UIButton, noshow: noshow)
            }
        }


        return _privateBtn
    }

    func helpBtn() -> UIBarButtonItem? {
        if _helpBtn == nil {
            _helpBtn = UIBarButtonItem(
                title: "Help",
                style: .plain,
                target: self,
                action: #selector(btnHelp))
        }
        return _helpBtn
    }

    func addBtn() -> UIBarButtonItem? {
        if _addBtn == nil {
            _addBtn = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(btnAddTracker))

            _addBtn.style = UIBarButtonItem.Style.done
        }
        return _addBtn
    }

    func editBtn() -> UIBarButtonItem? {
        if _editBtn == nil {
            _editBtn = UIBarButtonItem(
                barButtonSystemItem: .edit,
                target: self,
                action: #selector(btnEdit))

            _editBtn.style = UIBarButtonItem.Style.plain
        }
        return _editBtn
    }

    func flexibleSpaceButtonItem() -> UIBarButtonItem? {
        if _flexibleSpaceButtonItem == nil {
            _flexibleSpaceButtonItem = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)
        }
        return _flexibleSpaceButtonItem
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

    func privacyObj() -> privacyV? {
        if _privacyObj == nil {
            _privacyObj = privacyV(parentView: view)
            _privacyObj.parent = self
        }
        _privacyObj.tob = tlist() // not set at init
        return _privacyObj
    }

    func stashedTIDs() -> [AnyHashable]? {
        if _stashedTIDs == nil {
            _stashedTIDs = [AnyHashable]()
        }
        return _stashedTIDs
    }

    func countScheduledReminders() {

        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { [self] notifications in
            scheduledReminderCounts()?.removeAll()

            for i in 0..<(notifications?.count ?? 0) {
                let oneEvent = notifications?[i] as? UNNotificationRequest
                let userInfoCurrent = oneEvent?.content.userInfo
                DBGLog("%d uic: %@", i, userInfoCurrent)
                let tid = userInfoCurrent?["tid"] as? NSNumber
                var c: Int? = nil
                if let tid {
                    c = ((scheduledReminderCounts())?[tid] as? NSNumber)?.intValue ?? 0
                }
                c = (c ?? 0) + 1
                if let tid {
                    (scheduledReminderCounts())?[tid] = NSNumber(value: c ?? 0)
                }
            }
        })

    }

    func scheduledReminderCounts() -> [AnyHashable : Any]? {
        if nil == _scheduledReminderCounts {
            _scheduledReminderCounts = [AnyHashable : Any]()
        }
        return _scheduledReminderCounts
    }

    // MARK: -
    // MARK: button action methods

    @objc func btnAddTracker() {
        if PVNOSHOW != privacyObj()?.showing {
            return
        }
        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            if ADVER_TRACKER_LIM <= (tlist()?.topLayoutIDs?.count ?? 0) {
                //[rTracker_resource buy_rTrackerAlert];
                rTracker_resource.replaceRtrackerA(self)
                return
            }
        }
        #endif
        let atc = addTrackerController(nibName: "addTrackerController", bundle: nil)
        atc?.tlist = tlist()
        navigationController?.pushViewController(atc, animated: true)
        //[rTracker_resource myNavPushTransition:self.navigationController vc:atc animOpt:UIViewAnimationOptionTransitionCurlUp];


    }

    @IBAction func btnEdit() {

        if PVNOSHOW != privacyObj()?.showing {
            return
        }
        var ctlc: configTlistController?
        ctlc = configTlistController(nibName: "configTlistController", bundle: nil)
        ctlc?.tlist = tlist()
        if let ctlc {
            navigationController?.pushViewController(ctlc, animated: true)
        }
    }

    func btnMultiGraph() {
        DBGLog("btnMultiGraph was pressed!")
    }

    @objc func btnPrivate() {
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true) // ScrollToTop
        privacyObj()?.togglePrivacySetter()
        if PVNOSHOW == privacyObj()?.showing {
            refreshView()
        }
    }

    @objc func btnHelp() {
        #if ADVERSION
        if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/replace_rTrackerA.html") {
            UIApplication.shared.openURL(url)
        }
        #else
        //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://rob-miller.github.io/rTracker/rTracker/iPhone/userGuide/"]];  // deprecated ios 9
        if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/userGuide/") {
            UIApplication.shared.open(url, options: [:])
        }
        #endif
    }

    func btnPay() {
        DBGLog("btnPay was pressed!")

    }

    // MARK: -
    // MARK: Table view methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Customize the number of rows in the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tlist()?.topLayoutNames?.count ?? 0
    }

    func pendingNotificationCount() -> Int {
        var erc = 0
        var src = 0
        for nsn in tlist()?.topLayoutReminderCount ?? [] {
            guard let nsn = nsn as? NSNumber else {
                continue
            }
            erc += nsn.intValue
        }
        for tid in scheduledReminderCounts() ?? [:] {
            guard let tid = tid as? NSNumber else {
                continue
            }
            src += ((scheduledReminderCounts())?[tid] as? NSNumber)?.intValue ?? 0
        }

        return erc > src ? erc - src : 0
    }

    // Customize the appearance of table view cells.
    //DBGLog(@"rvc table cell at index %d label %@",[indexPath row],[tlist.topLayoutNames objectAtIndex:[indexPath row]]);

    static let tableViewCellIdentifier = "Cell"

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: RootViewController.tableViewCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: RootViewController.tableViewCellIdentifier)

            cell?.backgroundColor = .clear // clear here so table background shows through
        }

        // Configure the cell.
        let row = indexPath.row
        let tid = (tlist()?.topLayoutIDs)?[row] as? NSNumber
        let cellLabel = NSMutableAttributedString()

        let erc = ((tlist()?.topLayoutReminderCount)?[row] as? NSNumber)?.intValue ?? 0
        var src: Int? = nil
        if let tid {
            src = ((scheduledReminderCounts())?[tid] as? NSNumber)?.intValue ?? 0
        }
        DBGLog("src: %d  erc:  %d  %@ (%@)", src, erc, (tlist()?.topLayoutNames)?[row], tid)
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
        cellLabel.append(NSAttributedString(string: (tlist()?.topLayoutNames)?[row] as? String ?? ""))

        cell?.textLabel?.attributedText = cellLabel

        return cell!
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var tn: String?
        let row = indexPath.row
        if NSNotFound != row {
            tn = (tlist()?.topLayoutNames)?[row] as? String
        } else {
            tn = "Sample"
        }
        let tns = tn?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        return (tns?.height ?? 0.0) + (2 * MARGIN)
    }

    func exceedsPrivacy(_ tid: Int) -> Bool {
        return privacyV.getPrivacyValue() < (tlist()?.getPrivFromLoadedTID(tid) ?? 0)
    }

    func openTracker(_ tid: Int, rejectable: Bool) {

        if exceedsPrivacy(tid) {
            return
        }

        let topController = navigationController?.viewControllers.last
        let rtSelector = NSSelectorFromString("rejectTracker")

        if topController?.responds(to: rtSelector) ?? false {
            // top controller is already useTrackerController, is it this tracker?
            if tid == (topController as? useTrackerController)?.tracker.toid {
                return
            }
        }

        let to = trackerObj(tid)
        to.describe()

        let utc = useTrackerController()
        utc?.tracker = to
        utc?.rejectable = rejectable
        utc?.tlist = tlist() // required so reject can fix topLevel list
        utc?.saveFrame = view.frame // self.tableView.frame; //  view.frame;
        utc?.rvcTitle = title
        #if ADVERSION
        #if !DISABLE_ADS
        if !rTracker_resource.getPurchased() {
            utc?.adSupport() = adSupport()
        } else {
            utc?.adSupport() = nil
        }
        #endif
        #endif

        navigationController?.pushViewController(utc, animated: true)

    }

    // Override to support row selection in the table view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if PVNOSHOW != privacyObj()?.showing {
            return
        }

        //NSUInteger row = [indexPath row];
        //DBGLog(@"selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);
        tableView.cellForRow(at: indexPath)?.isSelected = false
        openTracker(tlist()?.getTIDfromIndex(indexPath.row) ?? 0, rejectable: false)

    }
}

#endif
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