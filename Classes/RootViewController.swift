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
/// Copyright 2010-2025 Robert T. Miller
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
import AVFoundation

extension Notification.Name {
    static let notifyOpenTracker = Notification.Name("notifyOpenTracker")
}

extension Notification.Name {
    static let notifyOpenTrackerInApp = Notification.Name("notifyOpenTrackerInApp")
}

extension Notification.Name {
    static let notifyPrivacyLockdown = Notification.Name("notifyPrivacyLockdown")
}

public class RootViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {
    static let shared = RootViewController()
    var tableView: UITableView?
    
    //var _privacyObj: privacyV?
    //var int32_t: _Atomic?
    var initialPrefsLoad = false
    var readingFile = false

    //var refreshLock: Bool = false
    let loadFilesLock = AtomicTestAndSet()  // (initialValue: false)
    
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
    var audioPlayer: AVAudioPlayer?
    var tldStashedTID = -1
    
    //openUrlLock, inputURL,

    // MARK: -
    // MARK: core object methods and support

    deinit {
        DBGLog("rvc dealloc")
        NotificationCenter.default.removeObserver(self)
    }
    
    var _tlist: trackerList?
    var tlist: trackerList {
        if _tlist == nil {
            _tlist = trackerList()  // Create the trackerList instance
            
            // Use the newly created _tlist to recover orphans and load the layout
            if _tlist!.recoverOrphans() {
                rTracker_resource.alert("Recovered files", msg: "One or more tracker files were recovered, please delete if not needed.", vc: self)
            }
            _tlist!.loadTopLayoutTable()
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

        DBGLog(String("start csv parser \(to!.trackerName) to-toid: \(to!.toid)"))
        let parser = CSVParser(string: csvString, separator: ",", hasHeader: true, fieldNames: nil)
        to?.csvProblem = nil
        to?.csvReadFlags = 0
        parser.parseRows(forReceiver: to, selector: #selector(trackerObj.receiveRecord(_:))) // receiveRecord in trackerObj.m
        DBGLog(String("csv parser done \(to!.trackerName) to-toid: \(to!.toid)"))

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

    func is_rtcsv(_ url: URL) -> Bool {
        do {
            // Read the content of the file
            let content = try String(contentsOf: url, encoding: .utf8)
            // Split the content into lines
            let lines = content.split(separator: "\n")
            
            // Ensure there's at least a second line
            guard lines.count >= 2 else { return false }
            
            // Extract the second line
            let secondLine = String(lines[1])
            
            // Check if the second line starts with a comma
            guard secondLine.starts(with: ",") else { return false }
            
            // Define the regular expression pattern for matching the fields
            let pattern = "^,(\"[a-zA-Z]+:[a-zA-Z]*:[0-9]+\"(?:,\"[a-zA-Z]+:[a-zA-Z]*:[0-9]+\")*)$"
            
            // Create a regular expression with the pattern
            let regex = try NSRegularExpression(pattern: pattern)
            
            // Perform the regex match on the second line
            let matches = regex.matches(in: secondLine, range: NSRange(secondLine.startIndex..., in: secondLine))
            
            // If there is at least one match, the line is valid
            return !matches.isEmpty
        } catch {
            // If there's an error reading the file or processing the regex, return false
            print(error.localizedDescription)
            return false
        }
    }
    
    func loadTrackerCsvFiles(completion: @escaping () -> Void) {
        if loadingCsvFiles {
            completion()
            return
        }
        
        loadingCsvFiles = true
        let localFileManager = FileManager.default
        //var newRtcsvTracker = false
        
        // Collect all files to process
        var filesToProcess: [URL] = []
        
        // Check main Documents directory
        var docsDir = rTracker_resource.ioFilePath(nil, access: true)
        var directoryURL = URL(fileURLWithPath: docsDir)
        if let enumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
            while let url = enumerator.nextObject() as? URL {
                filesToProcess.append(url)
            }
        }
        
        // Check Inbox directory
        docsDir = rTracker_resource.ioFilePath("Inbox", access: true)
        directoryURL = URL(fileURLWithPath: docsDir)
        if let enumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
            while let url = enumerator.nextObject() as? URL {
                filesToProcess.append(url)
            }
        }
        
        safeDispatchSync { [self] in
            jumpMaxPriv()
            tlist.loadTopLayoutTable()  // runs on main queue
            
            // Process files sequentially with completion handlers
            processNextCsvFile(files: filesToProcess, index: 0, createdNewTracker: false) { createdNewTracker in
                // All files processed
                restorePriv()
                self.tlist.loadTopLayoutTable()
                
                DispatchQueue.main.async {
                    self.refreshToolBar(true)
                    
                    if createdNewTracker {
                        self.refreshViewPart2()
                    }
                    
                    // Signal completion
                    completion()
                }
            }
        }
    }

    // Process CSV files one by one with completion handlers
    func processNextCsvFile(files: [URL], index: Int, createdNewTracker: Bool, completion: @escaping (Bool) -> Void) {
        // Base case: no more files to process
        if index >= files.count {
            completion(createdNewTracker)
            return
        }
        
        let fileUrl = files[index]
        let fname = fileUrl.lastPathComponent
        var to: trackerObj? = nil
        var tname: String? = nil
        var validMatch = false
        var loadObj: String?
        var newRtcsvTracker = createdNewTracker
        
        // Check if file is a CSV we should process
        switch fileUrl.pathExtension {
        case "csv":
            if fname.hasSuffix("_in.csv") {
                loadObj = "_in.csv"
                validMatch = true
            } else if fileUrl.pathComponents.contains("Inbox") {
                loadObj = ".csv"
                validMatch = true
            }
        case "rtcsv":
            if fname.hasSuffix("_in.rtcsv") {
                loadObj = "_in.rtcsv"
                validMatch = true
            } else {
                loadObj = ".rtcsv"
                validMatch = true
            }
        default:
            // Not a CSV we care about, skip to next file
            processNextCsvFile(files: files, index: index + 1, createdNewTracker: newRtcsvTracker, completion: completion)
            return
        }
        
        if validMatch {
            tname = String(fname.dropLast(loadObj!.count))
            let tid = tlist.getTIDfromName(tname)
            let isRtcsv = is_rtcsv(fileUrl)
            
            if tid != 0 {
                to = trackerObj(tid)
                DBGLog("found existing tracker tid \(tid) with matching name for _in.[rt]csv file")
            } else if isRtcsv {
                to = trackerObj()
                to?.trackerName = tname
                to?.toid = tlist.getUnique()
                to?.saveConfig()
                tlist.add(toTopLayoutTable: to!)
                newRtcsvTracker = true
                DBGLog("created new tracker for rtcsv, id= \(to!.toid)")
            } else {
                rTracker_resource.alert("No matching tracker", msg: "No '\(tname ?? "")' tracker found for \(fname), and the file does not conform to rtCSV format.", vc: self)
                _ = rTracker_resource.deleteFile(atPath: fileUrl.path)
                
                // Continue with next file
                processNextCsvFile(files: files, index: index + 1, createdNewTracker: newRtcsvTracker, completion: completion)
                return
            }
            
            if let to = to {
                // Show activity indicator on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    rTracker_resource.startActivityIndicator(self.view, navItem: nil, disable: false, str: "loading \(tname ?? "")...")
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                
                // Process the CSV file
                do {
                    let csvString = try String(contentsOfFile: fileUrl.path, encoding: .utf8)
                    doCSVLoad(csvString, to: to, fname: fname)
                    
                    do {
                        let fm = FileManager.default
                        try fm.removeItem(at: fileUrl)
                    } catch {
                        DBGWarn("Error deleting file \(fname): \(error)")
                    }
                    
                    // Stop activity indicator on main thread
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        UIApplication.shared.isIdleTimerDisabled = false
                        rTracker_resource.finishActivityIndicator(self.view, navItem: nil, disable: false)
                        
                        // Process next file
                        self.processNextCsvFile(files: files, index: index + 1, createdNewTracker: newRtcsvTracker, completion: completion)
                    }
                } catch {
                    // Handle error and continue processing
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        UIApplication.shared.isIdleTimerDisabled = false
                        DBGWarn("Error processing file \(fname): \(error)")
                        rTracker_resource.finishActivityIndicator(self.view, navItem: nil, disable: false)
                        
                        // Continue with next file despite error
                        self.processNextCsvFile(files: files, index: index + 1, createdNewTracker: newRtcsvTracker, completion: completion)
                    }
                }
            } else {
                // Continue with next file if no tracker could be created/found
                processNextCsvFile(files: files, index: index + 1, createdNewTracker: newRtcsvTracker, completion: completion)
            }
        } else {
            // Continue with next file if not a valid match
            processNextCsvFile(files: files, index: index + 1, createdNewTracker: newRtcsvTracker, completion: completion)
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
    /*
    func loadTrackerDict(_ tdict: [String : Any], tname: String?) -> Int {
            // get input tid
            let newTID = tdict["tid"] as! Int  // rejectable if not there, better than crash but still wrong
            DBGLog(String("load input: \(tname) tid \(newTID)"))
            let newTIDi = newTID
            var matchTID = -1
            let tida = tlist.getTIDfromNameDb(tname)
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
                    tldStashedTID = matchTID
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
                tldStashedTID = -1
            }
            return newTIDi
        }
     */
    
    func loadTrackerDict(_ tdict: [String: Any], tname: String?, completion: @escaping (Int) -> Void) {
        // get input tid
        let newTID = tdict["tid"] as! Int
        DBGLog(String("load input: \(tname) tid \(newTID)"))
        var matchTID = -1
        let tida = tlist.getTIDfromNameDb(tname)
        // find tracker with same name and tid, or just same name
        for tid in tida {
            if (-1 == matchTID) || (tid == newTID) {
                matchTID = tid
            }
        }
        DBGLog(String("matchTID= \(matchTID)"))
        
        // Check if we found a matching tracker name
        if matchTID != -1 {
            // If loading demos, just merge without asking
            if loadingDemos {
                processMergeTracker(matchTID: matchTID, newTID: newTID, tdict: tdict, tname: tname)
                completion(newTID)
                return
            }
            
            // Present a choice to the user
            let alertController = UIAlertController(
                title: "Tracker Already Exists",
                message: "A tracker named '\(tname ?? "")' already exists. Would you like to merge with it or create a new tracker?",
                preferredStyle: .alert
            )
            
            // Option to merge (original behavior)
            alertController.addAction(UIAlertAction(title: "Merge", style: .default) { [weak self] _ in
                self?.processMergeTracker(matchTID: matchTID, newTID: newTID, tdict: tdict, tname: tname)
                completion(newTID)
            })
            
            // Option to create new
            alertController.addAction(UIAlertAction(title: "Create New", style: .cancel) { [weak self] _ in
                self?.processNewTracker(tdict: tdict, tname: tname)
                completion(newTID)
            })
            
            // Show the alert on the main thread using the modern scene-aware approach
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let topVC = windowScene.windows.first?.rootViewController?.presentedViewController ?? windowScene.windows.first?.rootViewController {
                    topVC.present(alertController, animated: true)
                }
            }
        } else {
            // No match found, proceed with creating a new tracker
            processNewTracker(tdict: tdict, tname: tname)
            completion(newTID)
        }
    }

    // Helper method to handle the merge case
    private func processMergeTracker(matchTID: Int, newTID: Int, tdict: [String: Any], tname: String?) {
        if !loadingDemos {
            rTracker_resource.stashTracker(matchTID) // make copy of current tracker so can reject newTID later
            tldStashedTID = matchTID
        }
        tlist.updateTID(matchTID, new: newTID) // change existing tracker tid to match new (restore if we discard later)
        let inputTO = trackerObj(newTID) // load up existing tracker config
        inputTO.confirmTOdict(tdict) // merge valObjs
        inputTO.prevTID = matchTID
        inputTO.saveConfig() // write to db -- probably redundant as confirmTOdict writes to db as well
        DBGLog(String("updated \(tname)"))
    }

    // Helper method to handle the create new case
    private func processNewTracker(tdict: [String: Any], tname: String?) {
        // Create a mutable copy of the dictionary
        var newDict = tdict
        let nameClash = tlist.getTIDfromNameDb(tname) != [] // redundant but need to know if have name clash
        
        // Append "-new" to the tracker name
        if let trackerName = tname {
            if !loadingDemos && nameClash {
                let newName = "\(trackerName)-new"
                
                // Update the name in the dictionary if there's an optDict with a name key
                if var optDict = newDict["optDict"] as? [String: Any] {
                    optDict["name"] = newName
                    newDict["optDict"] = optDict
                }
            }
        }
        
        tlist.fixDictTID(newDict) // move any existing TIDs out of way
        let inputTO = trackerObj(dict: newDict) // create new tracker with input data
        inputTO.prevTID = -1
        inputTO.saveConfig() // write to db
        tlist.add(toTopLayoutTable: inputTO) // insert in top list
        DBGLog(String("loaded new \(tname)-new"))
        tldStashedTID = -1
    }
    

    // MARK: -
    // MARK: load .plists and .rtrks for input trackers

    func handleOpenFileURL(_ url: URL, tname: String?, completion: @escaping (Int) -> Void) {
        var tname = tname
        var tdict: [String: Any] = [:]
        var dataDict: [String: [String: String]]? = nil
        
        DBGLog(String("open url \(url)"))
        jumpMaxPriv()
        
        if nil != tname {
            // if tname set it is just a plist
            tdict = (NSDictionary(contentsOf: url) as Dictionary? as! [String: Any])
        } else {
            // else is an rtrk
            var rtdict: [String: Any] = [:]
            rtdict = NSDictionary(contentsOf: url) as Dictionary? as! [String: Any]

            tname = rtdict["trackerName"] as? String
            tdict = (rtdict["configDict"] ?? [:]) as! [String: Any]
            dataDict = rtdict["dataDict"] as? [String: [String: String]]
            
            let ttid = tdict["tid"] as! Int
            if loadingDemos {
                tlist.deleteTrackerAllTID(ttid, name: tname) // wipe old demo tracker otherwise starts to look ugly
            }
        }
        
        // Call the asynchronous loadTrackerDict with a completion handler
        loadTrackerDict(tdict, tname: tname) { tid in
            if let dataDict = dataDict {
                let to = trackerObj(tid)
                to.loadDataDict(dataDict) // vids ok because confirmTOdict updated as needed
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
            DBGLog(String("removing file \(url.path)"))
            _ = rTracker_resource.deleteFile(atPath: url.path)
            
            // Pass the tid to the completion handler
            completion(tid)
        }
    }

    
    // MARK: - File Loading System

    // Count input files matching a specific extension
    func countInputFiles(_ targ_ext: String?, inbox: Bool = false) -> Int {
        var retval = 0
        let docsDir = inbox ? rTracker_resource.ioFilePath("Inbox", access: true) : rTracker_resource.ioFilePath(nil, access: true)
        let directoryURL = URL(fileURLWithPath: docsDir)
        
        guard let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: []) else {
            return 0
        }
        
        while let url = enumerator.nextObject() as? URL {
            if url.lastPathComponent.hasSuffix(targ_ext ?? "") {
                DBGLog("countInputFiles: match on \(url.lastPathComponent) url is \(url)")
                retval += 1
            //} else {
               // DBGLog("cif: url \(url.lastPathComponent) no match for \(targ_ext ?? "")")
            }
        }
        
        return retval
    }

    // Main entry point for loading all input files
    func loadInputFiles() {
        DBGLog("loadInputFiles")
        
        // Check if already processing files
        if loadingInputFiles || loadingCsvFiles || !loadFilesLock.testAndSet(newValue: true) {
            return
        }
        
        // Count files to load
        csvLoadCount = countInputFiles("_in.csv") + countInputFiles(".rtcsv")
        plistLoadCount = countInputFiles("_in.plist")
        
        let rtrkLoadCount = countInputFiles(".rtrk") + countInputFiles(".rtrk", inbox: true)
        csvLoadCount += countInputFiles(".csv", inbox: true) + countInputFiles(".rtcsv", inbox: true)
        
        // Handle rtrks as plist + csv
        csvLoadCount += rtrkLoadCount
        plistLoadCount += rtrkLoadCount
        
        // Count demos and samples asynchronously, then proceed with loading
        countDemosAndSamples { [weak self] in
            guard let self = self else { return }
            
            // Reset counters for progress bars
            self.csvReadCount = 1
            self.plistReadCount = 1
            
            // Check if there are any files to load
            if self.plistLoadCount + self.csvLoadCount > 0 {
                // Show UI indicators
                DispatchQueue.main.async {
                    self.tableView?.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
                    rTracker_resource.startActivityIndicator(self.view, navItem: nil, disable: false, str: "loading trackers...")
                    rTracker_resource.startProgressBar(self.view, navItem: self.navigationItem, disable: true, yloc: 0.0)
                }
                
                // Start the loading process asynchronously
                self.loadTrackerFiles()
                
                DBGLog("Started async loading process, UI showing activity")
                return
            }
            
            // No files to load, just refresh the view
            self.refreshViewPart2()
            _ = self.loadFilesLock.testAndSet(newValue: false)
            DBGLog("No files to load - lock released")
        }
    }

    // Helper to count demos and samples
    func countDemosAndSamples(completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        if InstallSamples {
            group.enter()
            _ = loadSamples(false) { [weak self] count in
                self?.plistLoadCount += count
                group.leave()
            }
        }
        
        if InstallDemos {
            group.enter()
            loadDemos(false) { [weak self] count in
                self?.plistLoadCount += count
                group.leave()
            }
        }
        
        // When both counts are done
        group.notify(queue: .main) {
            completion()
        }
    }

    // Primary loading function - processes tracker definition files first, then data files
    func loadTrackerFiles() {
        loadingInputFiles = true
        
        // Step 1: Load demos and samples if requested
        loadInitialFiles { [weak self] loadedSomething in
            guard let self = self else { return }
            
            // Step 2: Load tracker definitions (plist files and rtrk files)
            self.loadTrackerPlistFiles { loadedTrackers in
                let totalLoadedSomething = loadedSomething || loadedTrackers
                
                // Update the tracker list if we loaded any trackers
                if totalLoadedSomething {
                    self.tlist.loadTopLayoutTable()
                    self.tlist.reorderDbFromTLT()
                }
                
                // Update UI to show we're done loading trackers
                DispatchQueue.main.async {
                    if self.csvLoadCount != 0 {
                        rTracker_resource.finishActivityIndicator(self.view, navItem: nil, disable: false)
                    }
                    
                    // Refresh the view
                    self.refreshViewPart2()
                }
                
                // Step 3: Load CSV data files
                self.loadingInputFiles = false
                self.loadTrackerCsvFiles { [weak self] in
                    guard let self = self else { return }
                    
                    // All loading completed
                    DispatchQueue.main.async {
                        // Clean up UI
                        rTracker_resource.finishProgressBar(self.view, navItem: self.navigationItem, disable: true)
                        rTracker_resource.finishActivityIndicator(self.view, navItem: self.navigationItem, disable: false)
                        
                        // Release lock
                        _ = self.loadFilesLock.testAndSet(newValue: false)
                        self.loadingCsvFiles = false
                        
                        // Final UI refresh
                        self.refreshToolBar(true)
                        
                        // Handle any rejectable trackers
                        if self.stashedTIDs.count > 0 {
                            self.doRejectableTracker()
                        }
                        
                        DBGLog("All files loaded - loading complete, lock released")
                    }
                }
            }
        }
    }

    // Helper to load demos and samples
    func loadInitialFiles(completion: @escaping (Bool) -> Void) {
        var loadedSomething = false
        let group = DispatchGroup()
        
        if InstallDemos {
            group.enter()
            loadDemos(true) { count in
                loadedSomething = (count > 0) || loadedSomething
                self.InstallDemos = false
                group.leave()
            }
        }
        
        if InstallSamples {
            group.enter()
            _ = loadSamples(true) { count in
                loadedSomething = (count > 0) || loadedSomething
                self.InstallSamples = false
                group.leave()
            }
        }
        
        // When both loading operations are complete
        group.notify(queue: .main) {
            completion(loadedSomething)
        }
    }

    // Load tracker definition files (plist and rtrk)
    func loadTrackerPlistFiles(completion: @escaping (Bool) -> Void) {
        DBGLog("loadTrackerPlistFiles")
        
        var loadedTrackers = false
        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let directoryURL = URL(fileURLWithPath: docsDir)
        
        // Find all files to process
        var filesToProcess: [URL] = []
        if let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
            while let url = enumerator.nextObject() as? URL {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
                    if resourceValues.isDirectory == false {
                        if url.lastPathComponent.hasSuffix("_in.plist") || url.pathExtension == "rtrk" {
                            filesToProcess.append(url)
                        }
                    }
                } catch {
                    DBGLog("Error retrieving resource values for file: \(url.path), error: \(error)")
                }
            }
        }
        
        // Process files sequentially with completion handlers
        processNextFile(files: filesToProcess, index: 0) { success in
            loadedTrackers = loadedTrackers || success
            completion(loadedTrackers)
        }
    }

    // Process files one by one with completion handlers
    func processNextFile(files: [URL], index: Int, completion: @escaping (Bool) -> Void) {
        // Base case: no more files to process
        if index >= files.count {
            completion(false)
            return
        }
        
        let file = files[index]
        let fname = file.lastPathComponent
        DBGLog("process input: \(fname)")
        
        // Prepare file for reading
        let newTarget = (file.path + "_reading").replacingOccurrences(of: "Documents/Inbox/", with: "Documents/")
        DBGLog("newTarget= \(newTarget)")
        
        do {
            try FileManager.default.moveItem(atPath: file.path, toPath: newTarget)
        } catch {
            DBGErr("Error on move \(file) to \(newTarget): \(error)")
            // Continue with next file
            processNextFile(files: files, index: index + 1, completion: completion)
            return
        }
        
        readingFile = true
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Process the file - plist or rtrk
        let processFile = {
            var rtrkTid = 0
            
            if fname.hasSuffix("_in.plist") {
                self.handleOpenFileURL(URL(fileURLWithPath: newTarget), tname: String(fname.prefix(fname.count - 9))) { tid in
                    rtrkTid = tid
                    rTracker_resource.rmStashedTracker(self.tldStashedTID)
                    self.tldStashedTID = -1
                    
                    self.readingFile = false
                    UIApplication.shared.isIdleTimerDisabled = false
                    
                    // Update progress and continue with next file
                    rTracker_resource.setProgressVal(Float(self.plistReadCount) / Float(self.plistLoadCount))
                    self.plistReadCount += 1
                    
                    self.processNextFile(files: files, index: index + 1, completion: completion)
                }
            } else {
                self.handleOpenFileURL(URL(fileURLWithPath: newTarget), tname: nil) { tid in
                    rtrkTid = tid
                    self.stashedTIDs.append(NSNumber(value: rtrkTid))
                    
                    self.readingFile = false
                    UIApplication.shared.isIdleTimerDisabled = false
                    
                    // Update progress and continue with next file
                    rTracker_resource.setProgressVal(Float(self.plistReadCount) / Float(self.plistLoadCount))
                    self.plistReadCount += 1
                    
                    self.processNextFile(files: files, index: index + 1, completion: { success in
                        completion(true) // We processed at least one rtrk file
                    })
                }
            }
        }
        
        // Ensure UI operations are on main thread
        DispatchQueue.main.async {
            processFile()
        }
    }


    // Refresh the view - called after loading files
    func refreshViewPart2() {
        tlist.confirmToplevelTIDs()
        tlist.loadTopLayoutTable()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.tableView?.reloadData()
            self.refreshEditBtn()
            self.refreshToolBar(true)
            self.view.setNeedsDisplay()
        }
    }
    let SUPPLY_DEMOS = 0
    let SUPPLY_SAMPLES = 1

    // Load supplied trackers with completion handler
    func loadSuppliedTrackers(_ doLoad: Bool, set: Int, completion: ((Int) -> Void)? = nil) -> Int {
        let bundle = Bundle.main
        var paths: [String]?
        
        if SUPPLY_DEMOS == set {
            paths = bundle.paths(forResourcesOfType: "plist", inDirectory: "demoTrackers")
        } else {
            paths = bundle.paths(forResourcesOfType: "plist", inDirectory: "sampleTrackers")
        }
        
        let count = paths?.count ?? 0
        
        if !doLoad {
            // If just counting, return the count immediately
            completion?(count)
            return count
        }
        
        // Process each tracker plist file sequentially
        processNextSuppliedTracker(paths: paths ?? [], index: 0, set: set) { finalCount in
            completion?(finalCount)
        }
        
        return count // Return the count for synchronous calls
    }

    // Helper function to process supplied trackers one by one
    func processNextSuppliedTracker(paths: [String], index: Int, set: Int, completion: @escaping (Int) -> Void) {
        // Base case: all trackers processed
        if index >= paths.count {
            // All trackers loaded, update version
            let sql: String
            if SUPPLY_DEMOS == set {
                sql = String(format: "insert or replace into info (val, name) values (%i,'demos_version')", DEMOS_VERSION)
            } else {
                sql = String(format: "insert or replace into info (val, name) values (%i,'samples_version')", SAMPLES_VERSION)
            }
            tlist.toExecSql(sql: sql)
            
            // Return the count
            completion(paths.count)
            return
        }
        
        let p = paths[index]
        
        // Load the tracker plist
        let tdict = NSDictionary(contentsOfFile: p) as Dictionary? as! [String: Any]
        tlist.fixDictTID(tdict)
        let newTracker = trackerObj(dict: tdict)
        tlist.deConflict(newTracker) // add _n to trackerName to avoid conflicts
        newTracker.saveConfig()
        tlist.add(toTopLayoutTable: newTracker)
        
        // Update progress
        rTracker_resource.setProgressVal((Float(plistReadCount)) / (Float(plistLoadCount)))
        plistReadCount += 1
        
        DBGLog(String("finished loading supplied tracker from \(p)"))
        
        // Process the next tracker
        processNextSuppliedTracker(paths: paths, index: index + 1, set: set, completion: completion)
    }

    // Load sample trackers with completion handler
    func loadSamples(_ doLoad: Bool, completion: ((Int) -> Void)? = nil) -> Int {
        if !doLoad {
            // If just counting, call loadSuppliedTrackers synchronously
            let count = loadSuppliedTrackers(doLoad, set: SUPPLY_SAMPLES)
            completion?(count)
            return count
        }
        
        // Otherwise, use the asynchronous version
        let count = loadSuppliedTrackers(doLoad, set: SUPPLY_SAMPLES) { count in
            completion?(count)
        }
        return count
    }

    // Load demo trackers with completion handler
    func loadDemos(_ doLoad: Bool, completion: ((Int) -> Void)? = nil) {
        let bundle = Bundle.main
        let paths = bundle.paths(forResourcesOfType: "rtrk", inDirectory: "demoTrackers")
        let urls = paths.map { URL(fileURLWithPath: $0) }
        
        let fm = FileManager.default
        let documentsURL = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        if !doLoad {
            // If just counting, return the count immediately
            completion?(urls.count)
            return
        }
        
        loadingDemos = true
        
        // Process each demo file sequentially
        processNextDemoTracker(urls: urls, index: 0, documentsURL: documentsURL) { count in
            if count > 0 {
                let sql = String(format: "insert or replace into info (val, name) values (%i,'demos_version')", DEMOS_VERSION)
                self.tlist.toExecSql(sql: sql)
            }
            
            loadingDemos = false
            completion?(count)
        }
    }

    // Helper function to process demo trackers one by one
    func processNextDemoTracker(urls: [URL], index: Int, documentsURL: URL, completion: @escaping (Int) -> Void) {
        // Base case: all demos processed
        if index >= urls.count {
            completion(urls.count)
            return
        }
        
        let p = urls[index]
        let file = p.lastPathComponent
        let destinationURL = documentsURL.appendingPathComponent(file)
        
        do {
            try FileManager.default.copyItem(atPath: p.path, toPath: destinationURL.path)
            
            // Handle the file with a completion handler
            handleOpenFileURL(URL(fileURLWithPath: destinationURL.path), tname: nil) { _ in
                // Process the next demo
                self.processNextDemoTracker(urls: urls, index: index + 1, documentsURL: documentsURL, completion: completion)
            }
        } catch let err {
            DBGErr(String("Error copying file: \(p.path) to \(destinationURL.path) error: \(err)"))
            
            // Continue with the next demo despite error
            processNextDemoTracker(urls: urls, index: index + 1, documentsURL: documentsURL) { count in
                // Subtract 1 from count for the failed file
                completion(count - 1)
            }
        }
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
#if TESTING
        setToolbarItems(
            [out2inBtn, xprivBtn, tstBtn, flexibleSpaceButtonItem, helpBtn, privateBtn].compactMap { $0 },
            animated: animated)
#else
        setToolbarItems(
            [flexibleSpaceButtonItem, helpBtn, privateBtn].compactMap { $0 },
            animated: animated)
#endif
    }
    
    func initTitle() {

        // set up the window title, try to get owner's name

        let devname = UIDevice.current.name  // this no longer works from iOS 16, need an 'entitlement'
        DBGLog("name = \(devname)");
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
    }


    // handle notification while in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        //countScheduledReminders()
        //let userInfo = notification.request.content.userInfo

        NotificationCenter.default.post(name: .notifyOpenTrackerInApp, object: nil, userInfo: nil)
        
        completionHandler([.sound, .list])  // need .list to make the .sound work on its own
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
            NotificationCenter.default.post(name: .notifyOpenTracker, object: nil, userInfo: userInfo)
        }
        completionHandler()
    }
    
    @objc func handleNotifyOpenTracker(_ notification: Notification) {
        // Extract userInfo and handle it
        if let userInfo = notification.userInfo as? [String: Any] {
            if let tidNumber = userInfo["tid"] as? NSNumber {
                let tid = tidNumber.intValue
                doOpenTracker(tid)
            }
        }
    }

    @objc func handleNotifyOpenTrackerInApp(_ notification: Notification) {
        countScheduledReminders()
        //tableView!.reloadData() // redundant but waiting for countScheduledReminders to complete
        //view.setNeedsDisplay()
    }
/*
    @objc func handlePrivacyLockdown(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            _ = self.privacyObj.lockDown() // hiding is handled after startup - viewDidAppear() below
            self.tableView?.reloadData()
        })
    }
 */
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifyOpenTracker(_:)), name: .notifyOpenTracker, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifyOpenTrackerInApp(_:)), name: .notifyOpenTrackerInApp, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackgroundRVC), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForegroundRVC), name: UIApplication.willEnterForegroundNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(handlePrivacyLockdown(_:)), name: .notifyPrivacyLockdown, object: nil)

        //DBGLog(@"rvc: viewDidLoad privacy= %d",[privacyObj getPrivacyValue]);

        //refreshLock = false
        DBGLog("release atomic loadFilesLock")
        _ = loadFilesLock.testAndSet(newValue: false)
        readingFile = false

        //let vsize = rTracker_resource.get_visible_size(self)
        //let vsize = rTracker_resource.getVisibleSize(of: self)
        
        navigationItem.rightBarButtonItem = addBtn
        navigationItem.leftBarButtonItem = editBtn
        
        // toolbar setup
        refreshToolBar(false)

        // title setup
        initTitle()
        
        // Create a new UITableView instance
        tableView = UITableView(frame: .zero, style: .plain)
        
        // Set tableView's translatesAutoresizingMaskIntoConstraints property to false
        // This allows us to add our own constraints to the tableView
        tableView!.translatesAutoresizingMaskIntoConstraints = false

        tableView?.accessibilityIdentifier = "trackerList"
        
        // Add the tableView as a subview of the current view
        view.addSubview(tableView!)

        // Set up constraints to pin the tableView to the edges of the safe area
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView!.topAnchor.constraint(equalTo: guide.topAnchor),
            tableView!.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableView!.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        
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

        let existingShortcutItems = UIApplication.shared.shortcutItems
        if 0 == (existingShortcutItems?.count ?? 0) /*|| ([rTracker_resource getSCICount] != [existingShortcutItems count]) */ {
            // can't set more than 4 or prefs messed up
            tlist.updateShortcutItems()
        }
        
        refreshView()
    }

    @objc func appWillEnterBackgroundRVC() {
        // set privacy mode off
        _ = self.privacyObj.lockDown()
    }
    @objc func appWillEnterForegroundRVC() {
        // privacy locked down when rvc entered background, while appdelegate puts up and pulls down blank image
        // this refreshview seems to happen before the blank view controller disappears
        refreshView()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView!.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    func refreshEditBtn() {

        if tlist.topLayoutNames.count == 0 {
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
        rTracker_resource.setToldAboutSwipe2(sud.bool(forKey: "toldAboutSwipe2"))
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
        DBGLog("try atomic set loadFilesLock")
        if loadFilesLock.testAndSet(newValue: true) {
            // wasn't false before, so we didn't get lock, so leave because refresh already in process
            return
        }
        DBGLog("got atomic set")
        //DBGLog(@"refreshView");
        scrollState()

        handlePrefs()

        loadInputFiles() // do this here as restarts are infrequent and prv change may enable to read more files -- calls refreshViewPart2

        countScheduledReminders()

    }

    public override func viewWillAppear(_ animated: Bool) {

        DBGLog(String("rvc: viewWillAppear privacy= \(privacyValue)"))
        countScheduledReminders()

        restorePriv()  // for returning from jump to maxpriv
        
        navigationController?.setToolbarHidden(false, animated: false)
        // tableView?.reloadData() // now in countScheduledReminders
        super.viewWillAppear(animated)
    }

    func fixFileProblem(_ choice: Int) {
        let docsDir = rTracker_resource.ioFilePath(nil, access: true)
        let localFileManager = FileManager.default
        

        //let files = try localFileManager.contentsOfDirectory(atPath: docsDir)
        let directoryURL = URL(fileURLWithPath: docsDir)
        let enumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        
        var files: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            files.append(url)
        }
        for fileURL in files {
            if fileURL.lastPathComponent.hasSuffix("_reading") {
                if choice == 0 {
                    // delete it
                    try? localFileManager.removeItem(at: fileURL)
                } else {
                    // try again -- rename from .rtrk_reading to .rtrk
                    if let newTarget = URL(string:fileURL.absoluteString.replacingOccurrences(of: "_reading", with: "")) {
                        do {
                            try localFileManager.moveItem(at: fileURL, to: newTarget)
                        } catch {
                            DBGLog("Error on move \(fileURL) to \(newTarget): \(error)")
                        }
                    }
                }
            }
        }

        viewDidAppearRestart()
    }

    func viewDidAppearRestart() {
        refreshView()

        super.viewDidAppear(stashAnimated)
    }

    func doOpenTrackerRejectable(_ nsnTid: NSNumber?, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.openTracker(nsnTid?.intValue ?? 0, rejectable: true)
            completion()  // Call the completion handler when done
        }
        
        // Usage
        //  doOpenTrackerRejectable(nsnTid) {
        //    // Code here will run after `openTracker` in the async block
        //  }
        // or
        //   doOpenTrackerRejectable(nsnTid)
        // for don't wait / no completion handler
    }
    
    /*
    @objc func doOpenTrackerOCRejectable(_ nsnTid: NSNumber?) {
        openTracker(nsnTid?.intValue ?? 0, rejectable: true)
    }
     */
    
    func doOpenTracker(_ tid: Int) {
        DispatchQueue.main.async { let tid = tid
            self.openTracker(tid, rejectable: false)
        }
    }
    /*
    @objc func doOpenTrackerOC(_ nsnTid: Int) {
        openTracker(nsnTid, rejectable: false)
    }
*/
    
    func doRejectableTracker() {
        //DBGLog(@"stashedTIDs= %@",self.stashedTIDs);
        let nsntid = stashedTIDs.last as? NSNumber
        doOpenTrackerRejectable(nsntid) {
            self.stashedTIDs.removeLast()
        }
        
        // performSelector(onMainThread: #selector(doOpenTrackerOCRejectable(_:)), with: nsntid, waitUntilDone: true)
        // stashedTIDs.removeLast()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !readingFile {
            if !stashedTIDs.isEmpty {
                doRejectableTracker()
            } else {
                let docsDir = rTracker_resource.ioFilePath(nil, access: true)
                
                //let files = try FileManager.default.contentsOfDirectory(atPath: docsDir)
                let directoryURL = URL(fileURLWithPath: docsDir)
                let localFileManager = FileManager.default
                let enumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: [])
                
                var files: [String] = []
                while let url = enumerator?.nextObject() as? URL {
                    files.append(url.lastPathComponent)
                }
                for fileName in files where fileName.hasSuffix("_reading") {
                    let fullPath = URL(fileURLWithPath: docsDir).appendingPathComponent(fileName)
                    let rtrkName = fullPath.lastPathComponent.replacingOccurrences(of: "_reading", with: "")  //.deletingPathExtension().lastPathComponent
                    presentProblemAlert(for: rtrkName)
                    return
                }

            }
        } else {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        stashAnimated = animated
        viewDidAppearRestart()
    }

    private func presentProblemAlert(for rtrkName: String) {
        let title = "Problem reading file?"
        let msg = "There was a problem while loading the \(rtrkName) file"
        let btn0 = "Delete it"
        let btn1 = "Try again"
        
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: btn0, style: .default) { [weak self] _ in
            self?.fixFileProblem(0)
        }
        let retryAction = UIAlertAction(title: btn1, style: .default) { [weak self] _ in
            self?.fixFileProblem(1)
        }
        
        alert.addAction(deleteAction)
        alert.addAction(retryAction)
        
        present(alert, animated: true)
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
            
            _privateBtn!.accessibilityLabel = "Privacy"
            _privateBtn!.accessibilityHint = "tap to show privacy filter"
            _privateBtn!.accessibilityIdentifier = "privacy"
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
            
            _helpBtn!.accessibilityLabel = "Help"
            _helpBtn!.accessibilityHint = "tap visit rTracker help web pages"
            _helpBtn!.accessibilityIdentifier = "help"
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
            
            _addBtn!.accessibilityLabel = "Add"
            _addBtn!.accessibilityHint = "tap create a new tracker"
            _addBtn!.accessibilityIdentifier = "add"
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
            
            _editBtn!.accessibilityLabel = "Edit"
            _editBtn!.accessibilityHint = "tap modify existing trackers"
            _editBtn!.accessibilityIdentifier = "edit"
            
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

    #if TESTING
    var _out2inBtn: UIBarButtonItem?
    var out2inBtn: UIBarButtonItem {
        if _out2inBtn == nil {
            _out2inBtn = UIBarButtonItem(
                title: "out2in",
                style: .plain,
                target: self,
                action: #selector(btnOut2in))
            
            _out2inBtn!.accessibilityLabel = "out2in"
            //_out2inBtn!.accessibilityIdentifier = "out2in"
        }
        return _out2inBtn!
    }

    
    var _xprivBtn: UIBarButtonItem?
    var xprivBtn: UIBarButtonItem {
        if _xprivBtn == nil {
            _xprivBtn = UIBarButtonItem(
                title: "xpriv",
                style: .plain,
                target: self,
                action: #selector(btnXpriv))
            
            _xprivBtn!.accessibilityLabel = "xpriv"
            //_xprivBtn!.accessibilityIdentifier = "xpriv"
        }
        return _xprivBtn!
    }
    
    var _tstBtn: UIBarButtonItem?
    var tstBtn: UIBarButtonItem {
        if _tstBtn == nil {
            _tstBtn = UIBarButtonItem(
                title: "tst",
                style: .plain,
                target: self,
                action: #selector(btnTst))
            
            _tstBtn!.accessibilityLabel = "tst"
            //_tstBtn!.accessibilityIdentifier = "tst"
        }
        return _tstBtn!
    }
    #endif
    
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
                if let tidNumber = userInfoCurrent["tid"] as? NSNumber {
                    let tid = tidNumber.intValue

                    var c = self.scheduledReminderCounts[tid] ?? 0
                    c += 1
                    self.scheduledReminderCounts[tid] = c
                }
            }

            DispatchQueue.main.async(execute: { [self] in
                tableView?.reloadData()
            })
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
        if privacyObj.jmpriv {
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

    #if TESTING
    @objc func btnOut2in() {
        DBGLog("out2in pressed")
        
        let fileManager = FileManager.default
        do {
            let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let directoryContents = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])

            for url in directoryContents {
                let fileName = url.deletingPathExtension().lastPathComponent
                let fileExtension = url.pathExtension
                
                if fileName.hasSuffix("_out"), let range = fileName.range(of: "_out") {
                    let newName = fileName[..<range.lowerBound] + "_in"
                    let newURL = url.deletingLastPathComponent().appendingPathComponent(String(newName)).appendingPathExtension(fileExtension)
                    
                    try fileManager.moveItem(at: url, to: newURL)
                    DBGLog("Renamed \(url.lastPathComponent) to \(newURL.lastPathComponent)")
                }
            }
        } catch {
            DBGWarn("out2in - An error occurred: \(error)")
        }
    }
    @objc func btnXpriv() {
        DBGLog("xpriv pressed")
        privacyObj.resetPw()
        privacyObj.dbClrKeys()
        privBtnSetImg(_privateBtn!.customView as? UIButton, noshow: true)
    }
    
    @objc func btnTst() {
        DBGLog("tst pressed")
        _ = self.privacyObj.lockDown()
        refreshView()
        //tableView?.reloadData()
    }
    #endif
    /*
    func btnPay() {
        DBGLog("btnPay was pressed!")

    }
     */
    // MARK: -
    // MARK: Table view methods
    

    var scheduledReminderCounts: [Int : Int] = [:]


    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Customize the number of rows in the table view.
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tlist.topLayoutNames.count
    }

    func pendingNotificationCount() -> Int {
        var erc = 0
        var src = 0
        for nsn in tlist.topLayoutReminderCount {
            erc += nsn
        }
        for (tid, _) in scheduledReminderCounts {
            if let count = scheduledReminderCounts[tid] {
                src += count
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
        if row >= tlist.topLayoutIDs.count {
            DBGErr("getting toplevel cell for row \(row) but only \(tlist.topLayoutIDs.count) in tlist")
            return cell!
        }
        let tid = tlist.topLayoutIDs[row]
        let cellLabel = NSMutableAttributedString()

        let erc = tlist.topLayoutReminderCount[row]
        let src = scheduledReminderCounts[tid] ?? 0

        DBGLog(String("src: \(src)  erc:  \(erc) \(tlist.topLayoutNames[row]) (\(tid))"))
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
        cellLabel.append(NSAttributedString(string: tlist.topLayoutNames[row]))

        cell?.textLabel?.attributedText = cellLabel
        cell?.accessibilityIdentifier = "trkr_\(cellLabel.string)"
        return cell!
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var tn: String?
        let row = indexPath.row
        if NSNotFound != row {
            tn = tlist.topLayoutNames[row]
        } else {
            tn = "Sample"
        }
        let tns = tn?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        return (tns?.height ?? 0.0) + (2 * MARGIN)
    }

    func exceedsPrivacy(_ tid: Int) -> Bool {
        DBGLog("curr priv \(privacyValue)  tid \(tid)  tid priv \(tlist.getPrivFromLoadedTID(tid))")
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
        
        self.navigationController!.pushViewController(utc, animated: true)
    }

    // Override to support row selection in the table view.
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        
        if _privacyObj != nil {
            if PVNOSHOW != privacyObj.showing {
                return
            }
            if privacyObj.jmpriv {
                return
            }
        }
        
        //NSUInteger row = [indexPath row];
        //DBGLog(@"selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);
        
        //print("Navigation controller: \(String(describing: self.navigationController))")
        //print("Top controller: \(String(describing: self.navigationController?.topViewController))")
        
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
