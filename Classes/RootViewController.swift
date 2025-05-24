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
//  Copyright Robert T. Miller 2010-2025. All rights reserved.
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
//  Copyright Robert T. Miller 2010-2025. All rights reserved.
//

import UserNotifications

import Foundation
import AVFoundation

extension Notification.Name {
    static let notifyOpenTracker = Notification.Name("notifyOpenTracker")
    static let notifyOpenTrackerInApp = Notification.Name("notifyOpenTrackerInApp")
    static let notifyPrivacyLockdown = Notification.Name("notifyPrivacyLockdown")
}

public class RootViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {
    static let shared = RootViewController()
    var tableView: UITableView?

    var initialPrefsLoad = false
    var readingFile = false

    let loadFilesLock = AtomicTestAndSet()  // (initialValue: false)


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

    let SUPPLY_DEMOS = 0
    let SUPPLY_SAMPLES = 1
    
    // MARK: -
    // MARK: core object methods and support

    deinit {
        DBGLog("rvc dealloc")
        NotificationCenter.default.removeObserver(self)
    }
    
    var _tlist: trackerList?
    var tlist: trackerList {
        if _tlist == nil {
            _tlist = trackerList.shared  // Create the trackerList instance
            
            // Use the newly created _tlist to recover orphans and load the layout
            if _tlist!.recoverOrphans() {
                rTracker_resource.alert("Recovered files", msg: "One or more tracker files were recovered, please delete if not needed.", vc: self)
            }
            _tlist!.loadTopLayoutTable()
        }
        return _tlist!
    }


    
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
        //DBGLog("name = \(devname)");
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
        DBGLog("\(rtitle!) running on \(devname)")
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
        //DBGLog("release atomic loadFilesLock")
        _ = loadFilesLock.testAndSet(newValue: false)
        readingFile = false

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

        if tlist.topLayoutNamesH.count == 0 {
            if navigationItem.leftBarButtonItem != nil {
                navigationItem.leftBarButtonItem = nil
            }
        } else {
            if navigationItem.leftBarButtonItem == nil {
                navigationItem.leftBarButtonItem = editBtn
            }
        }

    }

    func samplesNeeded() -> Bool {
        let rslt = tlist.toQry2Int(sql:"select val from info where name = 'samples_version'")
        if SAMPLES_VERSION != rslt {
            DBGLog(String("samples Needed"))
        }
        return SAMPLES_VERSION != rslt
    }

    func demosNeeded() -> Bool {
        let rslt = tlist.toQry2Int(sql:"select val from info where name = 'demos_version'")
        if DEMOS_VERSION != rslt {
            DBGLog(String("demos Needed"))
        }
 
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
        if InstallSamples || InstallDemos {
            DBGLog(String("InstallSamples \(InstallSamples)  InstallDemos \(InstallDemos)"))
        }
        
        if resetPassPref {
            sud.set(false, forKey: "reset_password_pref")
        }
        if reloadSamplesPref {
            sud.set(false, forKey: "reload_sample_trackers_pref")
        }

        initialPrefsLoad = false

        sud.synchronize()
    }

    func refreshView() {
        //DBGLog("try atomic set loadFilesLock")
        if loadFilesLock.testAndSet(newValue: true) {
            // wasn't false before, so we didn't get lock, so leave because refresh already in process
            return
        }
        //DBGLog("got atomic set")

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
    
    func doOpenTracker(_ tid: Int) {
        DispatchQueue.main.async { let tid = tid
            self.openTracker(tid, rejectable: false)
        }
    }
    
    func doRejectableTracker() {
        //DBGLog(@"stashedTIDs= %@",self.stashedTIDs);
        let nsntid = stashedTIDs.last as? NSNumber
        doOpenTrackerRejectable(nsntid) {
            self.stashedTIDs.removeLast()
        }
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

            // Update badge count using ios 17 new API
            let count = pendingNotificationCount()
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if let error = error {
                    DBGLog("Failed to set badge count: \(error.localizedDescription)")
                }
            }
            
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
                action: nil )//#selector(btnOut2in))  // rtm change back!!!!
            
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
                //DBGLog(String("\(i) uic: \(userInfoCurrent)"))
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
        return tlist.topLayoutNamesH.count
    }

    func pendingNotificationCount() -> Int {
        var erc = 0
        var src = 0
        for nsn in tlist.topLayoutReminderCountH {
            erc += nsn
        }
        for (tid, _) in scheduledReminderCounts {
            if let count = scheduledReminderCounts[tid] {
                src += count
            }
        }

        return erc > src ? erc - src : 0
    }

    static let tableViewCellIdentifier = "Cell"

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: RootViewController.tableViewCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: RootViewController.tableViewCellIdentifier)

            cell?.backgroundColor = .clear // clear here so table background shows through
        }

        
        // Remove any existing streak badge (when cells are reused)
        if let existingBadge = cell?.contentView.viewWithTag(1001) {
            existingBadge.removeFromSuperview()
        }
        
        // Configure the cell.
        let row = indexPath.row
        if row >= tlist.topLayoutIDsH.count {
            DBGErr("getting toplevel cell for row \(row) but only \(tlist.topLayoutIDsH.count) in tlist")
            return cell!
        }
        let tid = tlist.topLayoutIDsH[row]
        let cellLabel = NSMutableAttributedString()

        let erc = tlist.topLayoutReminderCountH[row]
        let src = scheduledReminderCounts[tid] ?? 0

        //DBGLog(String("src: \(src)  erc:  \(erc) \(tlist.topLayoutNamesH[row]) (\(tid))"))

        if erc != src {
            cellLabel.append(
                NSAttributedString(
                    string: "➜ ",
                    attributes: [
                        .foregroundColor: UIColor.red,
                        .font: UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
                    ]))
        }
        cellLabel.append(NSAttributedString(string: tlist.topLayoutNamesH[row]))

        cell?.textLabel?.attributedText = cellLabel
        cell?.accessibilityIdentifier = "trkr_\(cellLabel.string)"
        
        // Only add streak badge if streak tracking is enabled for this tracker
        if tlist.isTrackerStreaked(tid) {
            // Get current streak count
            let to = trackerObj(tid)
            let streakCount = to.streakCount()
            DBGLog("streak count for \(to.trackerName ?? "nil") is \(streakCount)")
            // Only show streak badge if there's an active streak
            if streakCount > 0 {
                addStreakBadge(to: cell!, count: streakCount, shouldAnimate: false)
            }
        }
        
        return cell!
    }

    private func addStreakBadge(to cell: UITableViewCell, count: Int, shouldAnimate: Bool) {
        // Create container view for badge
        let badgeContainer = UIView()
        badgeContainer.tag = 1001 // Tag to find it later
        badgeContainer.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        badgeContainer.layer.cornerRadius = 12
        cell.contentView.addSubview(badgeContainer)
        
        // Create flame icon
        let flameLabel = UILabel()
        flameLabel.text = "🔥"
        flameLabel.font = UIFont.systemFont(ofSize: 14)
        flameLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(flameLabel)
        
        // Create count label
        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = UIFont.boldSystemFont(ofSize: 12)
        countLabel.textColor = .systemOrange
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeContainer.addSubview(countLabel)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            badgeContainer.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            badgeContainer.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            
            flameLabel.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 6),
            flameLabel.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
            
            countLabel.leadingAnchor.constraint(equalTo: flameLabel.trailingAnchor, constant: 2),
            countLabel.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -6),
            countLabel.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor)
        ])
        
        // Animate if needed
        if shouldAnimate {
            badgeContainer.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
                badgeContainer.transform = CGAffineTransform.identity
            })
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var tn: String?
        let row = indexPath.row
        if NSNotFound != row {
            tn = tlist.topLayoutNamesH[row]
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
        // debug only
        // to.describe()

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
        
        tableView.cellForRow(at: indexPath)?.isSelected = false
        openTracker(tlist.getTIDfromIndexH(indexPath.row), rejectable: false)

    }
}
