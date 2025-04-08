//
//  RootViewControllerFileLoad.swift
//  rTracker
//
//  Created by Robert Miller on 08/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import Foundation
extension RootViewController {
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
    
    func loadTrackerDict(_ tdict: [String: Any], tname: String, completion: @escaping (Int) -> Void) {
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
                message: "A tracker named '\(tname)' already exists. Would you like to merge with it or create a new tracker?",
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
    private func processNewTracker(tdict: [String: Any], tname: String) {
        // Create a mutable copy of the dictionary
        var newDict = tdict
        let nameClash = tlist.getTIDfromNameDb(tname) != [] // redundant but need to know if have name clash
        
        // Append "-new" to the tracker name

        if !loadingDemos && nameClash {
            let newName = "\(tname)-new"
            
            // Update the name in the dictionary if there's an optDict with a name key
            if var optDict = newDict["optDict"] as? [String: Any] {
                optDict["name"] = newName
                newDict["optDict"] = optDict
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
        loadTrackerDict(tdict, tname: tname!) { tid in
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
}

