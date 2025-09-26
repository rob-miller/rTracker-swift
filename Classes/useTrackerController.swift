//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// useTrackerController.swift
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
//  useTrackerController.swift
//  rTracker
//
//  this screen presents the list of value objects for a specified tracker
//
//  Created by Robert Miller on 03/09/2010.
//  Copyright 2010-2025 Robert T. Miller. All rights reserved.
//

///************
/// useTrackerController.swift
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
//  useTrackerController.swift
//  rTracker
//
//  Created by Robert Miller on 03/09/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import MessageUI
import UIKit

class useTrackerController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                            UITextFieldDelegate, MFMailComposeViewControllerDelegate,
                            UIAdaptivePresentationControllerDelegate, RefreshProgressDelegate
{
    
    var tracker: trackerObj?
    var saveFrame = CGRect.zero
    var needSave = false
    var didSave = false
    var fwdRotations = false
    var rejectable = false
    var viewDisappearing = false
    var tlist: trackerList?
    var alertResponse = 0
    var saveTargD = 0
    var searchSet: [Int]?
    var rvcTitle: String?
    var tableView: UITableView?
    
    var hkDataSource = false
    var otDataSource = false
    var fnDataSource = false
    
    private var loadingData = false
    
    var gt: UIViewController?
    
    var alreadyReturning = false  // graphTrackerVC viewWillTransitionToSize() called when we dismissVieControllerAnimated() below, so don't call a second time
    var emCancel = "Cancel"
    var emEmailCsv = "email CSV"
    var emEmailTracker = "email Tracker"
    var emEmailTrackerData = "email Tracker+Data"
    var emItunesExport = "save for PC (iTunes)"
    var emDuplicate = "duplicate entry to now"
    //BOOL keyboardIsShown=NO;
    
    private var pullCounter = 0
    private var refreshTimer: Timer?
    private var isRefreshInProgress = false
    private var partialRefreshWorkItem: DispatchWorkItem? = nil
    private var refreshActivityIndicator: UIActivityIndicatorView?
    private var raiDelayedWork: DispatchWorkItem?
    
    // refresh progress bar
    private var fullRefreshProgressBar: UIProgressView?
    private var fullRefreshProgressLabel: UILabel?
    private var currentProgressStep = 0
    private var currentRefreshPhase = ""
    private var currentProgressMaxValue: Float = 1.0  // Track current phase max value
    private var currentProgressThreshold: Int = 1  // Track current phase threshold
    private var currentTotalSteps: Int = 0  // Track current total value
    private var currentTasks: Int = 0  // for tracking multiple HK addSteps
    private var progressBarShown: Bool = false
    private var lastUIProgressValue: Float = -1.0  // Track last progress value sent to UI
    private var fullRefreshProgressContainerView: UIView?
    private var frDate: Int = 0  // Date?  // trackerDate shown when full refresh started
    private var raiShown: Bool = false
    
#if DEBUGLOG
    private var lastLoggedTenPercent: Int = -1  // Track last logged 10% bracket
#endif
    
    let refreshLabelId = 1002
    let refreshLabelId2 = 1003
    
    // MARK: -
    // MARK: core object methods and support
    
    var _dpvc: datePickerVC?
    var dpvc: datePickerVC {
        if _dpvc == nil {
            _dpvc = datePickerVC()
        }
        return _dpvc!
    }
    
    var _dpr: dpRslt?
    var dpr: dpRslt {
        if _dpr == nil {
            _dpr = dpRslt()
        }
        return _dpr!
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Initialize progress tracking variables
        currentRefreshPhase = ""
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Initialize progress tracking variables
        currentRefreshPhase = ""
    }
    
    // MARK: -
    // MARK: view support
    
    func showSaveBtn() {
        if needSave && navigationItem.rightBarButtonItem != saveBtn {
            navigationItem.setRightBarButton(saveBtn, animated: true)
        } else if !needSave && navigationItem.rightBarButtonItem != menuBtn {
            navigationItem.setRightBarButton(menuBtn, animated: true)
        }
    }
    
    // MARK: -
    // MARK: tracker data updated event handling -- rtTrackerUpdatedNotification
    
    func updateTableCells(_ inVO: valueObj?) {
        var iparr: [AnyHashable] = []
        var n = 0
        
        for vo in tracker!.valObjTableH {
            if VOT_FUNC == vo.vtype || vo.optDict["otTracker"] ?? "" == tracker?.trackerName {
                vo.display = nil  // always redisplay
                vo.vos?.setFNrecalc()  // no caching, recompute function
                iparr.append(IndexPath(index: 0).appending(n))
            } else if (inVO?.vid == vo.vid) && (nil == vo.display) {
                iparr.append(IndexPath(index: 0).appending(n))
            }
            n += 1
        }
        
        if isViewLoaded && view.window != nil {
            UIView.performWithoutAnimation {
                if let iparr = iparr as? [IndexPath] {
                    tableView!.reloadRows(at: iparr, with: .none)
                }
            }
        }
        
    }
    
    // handle rtTrackerUpdatedNotification
    @objc func updateUTC(_ notification: Notification?) {
        DBGLog(
            String(
                "UTC update notification from tracker \((notification?.object as? trackerObj)?.trackerName)"
            ))
        var vo: valueObj?
        if let obj = notification?.object, type(of: obj) == valueObj.self {
            vo = obj as? valueObj
            DBGLog(String("updated vo \(vo?.valueName)"))
        }
        updateTableCells(vo)
        needSave = true
        showSaveBtn()
        tracker?.saveTempTrackerData()
        
    }
    
    func startRAI() {
        if raiShown {
            return
        }
        DispatchQueue.main.async {
            //guard let self = self else { return }
            self.refreshActivityIndicator = UIActivityIndicatorView(style: .large)
            if let rai = self.refreshActivityIndicator {
                rai.center = self.view.center
                rai.startAnimating()
                self.view.addSubview(rai)
                DBGLog("started RAI!")
                self.raiShown = true
            }
        }
        
    }
    
    func endRAI() {  // end refresh activity indicator
        // Remove existing activity indicator if shown
        refreshActivityIndicator?.stopAnimating()
        refreshActivityIndicator?.removeFromSuperview()
        refreshActivityIndicator = nil
        raiShown = false
    }
    
    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        DBGLog("STATE: useTrackerController viewDidLoad start")
        
        //DBGLog(@"utc: viewDidLoad dpvc=%d", (self.dpvc == nil ? 0 : 1));
        fwdRotations = true
        needSave = false
        
        keyboardIsShown = false
        
        // navigationbar setup
        let backButton = rejectable ?
            rTracker_resource.createActionButton(target: self, action: #selector(addTrackerController.btnCancel), symbolName: "chevron.left.circle.fill", tintColor: .systemRed, fallbackTitle: "<") :
            rTracker_resource.createNavigationButton(target: self, action: #selector(addTrackerController.btnCancel), direction: .left)
        navigationItem.leftBarButtonItem = backButton
        
        // toolbar setup - defer to viewWillAppear to avoid constraint conflicts
        // updateToolBar() - moved to viewWillAppear
        
        // title setup
        title = tracker!.trackerName
        
        // tableview setup
        
        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        
        // Create a new UITableView instance
        tableView = UITableView(frame: .zero, style: .plain)
        
        // Set tableView's translatesAutoresizingMaskIntoConstraints property to false
        // This allows us to add our own constraints to the tableView
        tableView!.translatesAutoresizingMaskIntoConstraints = false
        tableView?.accessibilityIdentifier = "useTracker_\(title!)"
        
        // Add the tableView as a subview of the current view
        view.addSubview(tableView!)
        
        // Set up constraints to pin the tableView to the edges of the safe area
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView!.topAnchor.constraint(equalTo: guide.topAnchor),
            tableView!.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableView!.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])
        
        //self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        tableView!.dataSource = self
        tableView!.delegate = self
        
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)
        
        setViewMode()
        
        tableView!.separatorStyle = .none
        //self.tableView.separatorColor = [UIColor clearColor];
        view.addSubview(tableView!)
        
        // swipe gesture recognizer
        
        var swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleViewSwipeLeft(_:)))
        swipe.direction = .left
        view.addGestureRecognizer(swipe)
        
        //swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)
        
        tracker!.vc = self
        alertResponse = 0
        saveTargD = 0
        
        //load temp tracker data here if available
        if tracker!.loadTempTrackerData() {
            needSave = true
            showSaveBtn()
        } else {
            self.frDate = 0
            
            performDataLoadingSequence {
                // Perform any UI updates after data loading
                DBGLog("HealthKit and Othertracker data loaded.")
                self.loadTrackerDate(self.frDate)
                self.updateTrackerTableView()
                
                if self.hkDataSource || self.otDataSource || self.fnDataSource {
                    let refreshControl = UIRefreshControl()
                    
                    // Add target for when pull begins
                    refreshControl.addTarget(
                        self, action: #selector(self.pullToRefreshStarted), for: .valueChanged)
                    
                    self.tableView!.refreshControl = refreshControl
                }
            }
        }
        
    }
    
    // Called when pull-to-refresh starts or continues
    @objc func pullToRefreshStarted(_ refreshControl: UIRefreshControl) {
        // Stop native spinner immediately for smoother transition to our custom spinner
        refreshControl.endRefreshing()
        // If we're already in a refresh operation, do nothing
        if (isRefreshInProgress || loadingData || tracker?.loadingDbData == true) && (pullCounter != 1)
        {
            DBGLog(
                "Pull to refresh blocked - refresh already in progress (isRefreshInProgress: \(isRefreshInProgress), loadingData: \(loadingData), loadingDbData: \(tracker?.loadingDbData ?? false))"
            )
            rTracker_resource.addTimedLabel(
                text: "Refresh already in progress", tag: self.refreshLabelId, sv: self.view, ti: 2.0, viewController: self)
            return
        }
        
        // Increment the pull counter
        pullCounter += 1
        DBGLog("Pull counter incremented to \(pullCounter)", color: .RED)
        
        if pullCounter == 1 {
            // First pull - light feedback and start timer
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            
            // Cancel any existing timer
            refreshTimer?.invalidate()
            
            // Start a timer for the single pull refresh
            refreshTimer = Timer.scheduledTimer(
                timeInterval: 2.0, target: self, selector: #selector(handleSinglePullTimeout),
                userInfo: nil, repeats: false)
            
            rTracker_resource.addTimedLabel(
                text: "Pull again to refresh all", tag: self.refreshLabelId2, sv: self.view, ti: 2.0, viewController: self)
            
            // Cancel any existing partial refresh
            partialRefreshWorkItem?.cancel()
            
            // Create cancellable work item for partial refresh
            
            partialRefreshWorkItem = DispatchWorkItem {
                // should finish inside 2 second pull timeout anyway so why wait
                self.handleRefresh(forDate: Int(self.tracker!.trackerDate!.timeIntervalSince1970))
            }
            
            DispatchQueue.main.async(execute: partialRefreshWorkItem!)
            
            // just leave partialRefreshWorkItem not cleaned up if it finishes on its own
            
        } else if pullCounter >= 2 {
            // Multiple pulls - stronger feedback and full refresh
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            feedbackGenerator.impactOccurred()
            
            // Cancel the timer for single pull
            refreshTimer?.invalidate()
            refreshTimer = nil
            
            // Cancel any pending partial refresh
            partialRefreshWorkItem?.cancel()
            partialRefreshWorkItem = nil
            
            // Reset counter
            pullCounter = 0
            
            // Remove spinner as we'll use the progress bar instead
            // endRAI()
            
            // Show visual indicator for full refresh
            DispatchQueue.main.async {
                rTracker_resource.addTimedLabel(
                    text: "Full refresh in progress...", tag: self.refreshLabelId, sv: self.view, ti: 3.0, viewController: self)
                // Start the full refresh
                
                self.handleRefresh()
            }
        }
    }
    
    // Timer handler for single pull timeout
    @objc func handleSinglePullTimeout() {
        DBGLog("Single pull timer expired, counter = \(pullCounter)")
        pullCounter = 0
        /*
         DispatchQueue.main.async {
         rTracker_resource.addTimedLabel(text:"Full refresh in progress...", tag:self.refreshLabelId, sv:self.view, ti:3.0)
         // Start the full refresh
         self.handleRefresh(forDate:Int(self.tracker!.trackerDate!.timeIntervalSince1970))
         }
         */
        // already did single refresh
    }
    
    // refresh current record
    func xrefreshCurrentRecord(_ refreshControl: UIRefreshControl) {
        DBGLog("Short refresh initiated - updating current record only")
        
        let dispatchGroup = DispatchGroup()
        let currentDate = Int(tracker!.trackerDate!.timeIntervalSince1970)
        self.isRefreshInProgress = true
        
        DispatchQueue.main.async {
            // Clear only the current record's HK ,FN and OT data
            for vo in self.tracker!.valObjTableH {
                vo.vos?.clearHKdata(forDate: currentDate)
                vo.vos?.clearOTdata(forDate: currentDate)
                vo.vos?.clearFNdata(forDate: currentDate)
            }
            
            // Load data only for the current record
            dispatchGroup.enter()
            _ = self.tracker!.loadHKdata(
                forDate: currentDate, dispatchGroup: nil,
                completion: {
                    _ = self.tracker!.loadOTdata(
                        forDate: currentDate, otSelf: false, dispatchGroup: nil,
                        completion: {
                            _ = self.tracker!.loadFNdata(
                                forDate: currentDate, dispatchGroup: nil,
                                completion: {
                                    _ = self.tracker!.loadOTdata(
                                        forDate: currentDate, otSelf: true, dispatchGroup: nil,
                                        completion: {
                                            dispatchGroup.leave()
                                        })
                                })
                        })
                })
            
            dispatchGroup.notify(queue: .main) {
                DBGLog("Current record data refreshed")
                self.endRAI()
                _ = self.tracker!.loadData(currentDate)  // does nothing if currentDate not in db so leaves current ui settings
                self.updateTrackerTableView()
                self.isRefreshInProgress = false
            }
        }
    }
    
    func handleRefresh(forDate: Int? = nil) {
        if let forDate = forDate {
            DBGLog(
                "Partial Refresh initiated for date: \(Date(timeIntervalSince1970: TimeInterval(forDate)))")
        } else {
            DBGLog("Full Refresh initiated")
        }
        
        // this either clears all HK/FN/OT records, or just for the specified date
        for vo in self.tracker!.valObjTableH {
            vo.vos?.clearHKdata(forDate: forDate)
            vo.vos?.clearOTdata(forDate: forDate)
            vo.vos?.clearFNdata(forDate: forDate)
        }
        
        // Delete trkrData entries which no longer have associated voData
        let sql =
        "delete from trkrdata where date not in (select date from voData where voData.date = trkrdata.date)"
        self.tracker?.toExecSql(sql: sql)
        
        self.frDate = forDate ?? Int(tracker!.trackerDate!.timeIntervalSince1970)
        DBGLog("frDate set to \(Date(timeIntervalSince1970: TimeInterval(self.frDate)))")

        performDataLoadingSequence(forDate: forDate) {
            if forDate == nil {
                DBGLog(
                    "Full refresh completed - All data loaded and SQL inserts completed. frDate= \(Date(timeIntervalSince1970: TimeInterval(self.frDate))) "
                )
                self.needSave = false  // full refresh means wipe what you were doing, sorry.
                self.loadTrackerDate(self.frDate)
                rTracker_resource.addTimedLabel(
                    text: "Refresh completed successfully", tag: self.refreshLabelId, sv: self.view, ti: 3.0, viewController: self)
            } else {
                DBGLog(
                    "Partial refresh for \(Date(timeIntervalSince1970: TimeInterval(forDate!))) completed. frDate= \(Date(timeIntervalSince1970: TimeInterval(self.frDate)))"
                )
                // did not move from current ui
                if self.tracker!.loadData(self.frDate, derivedOnly: true) {

                    // date is in db
                    //self.needSave = false  // did not wipe local changes
                    self.showSaveBtn()
                    self.updateToolBar()
                } else {
                    // date not in db, ui not changed just ensure date is right
                    self.tracker!.trackerDate = Date(timeIntervalSince1970: TimeInterval(self.frDate))
                }
            }
            self.updateTrackerTableView()
            DBGLog("trackerDate is \(String(describing: self.tracker!.trackerDate))")
        }
        
    }
    
    // MARK: - Data Loading Sequence
    
    private func performDataLoadingSequence(forDate: Int? = nil, completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        self.loadingData = true
        self.tracker!.loadingDbData = true
        self.isRefreshInProgress = true
        
        // Setup progress UI before starting operations
        self.setupFullRefreshProgressUI()
        // Set the tracker as the delegate for progress updates
        self.tracker!.refreshDelegate = self
        
        dispatchGroup.enter()
        self.hkDataSource = self.tracker!.loadHKdata(
            forDate: forDate, dispatchGroup: nil,
            completion: {
                // have hk data, load OT data for really other trackers
                self.otDataSource = self.tracker!.loadOTdata(
                    forDate: forDate, otSelf: false, dispatchGroup: nil,
                    completion: {
                        // now can compute fn results
                        self.fnDataSource = self.tracker!.loadFNdata(
                            forDate: forDate, dispatchGroup: nil,
                            completion: {
                                // now load ot data that look at self
                                _ = self.tracker!.loadOTdata(
                                    forDate: forDate, otSelf: true, dispatchGroup: nil,
                                    completion: {
                                        DispatchQueue.main.async {
                                            self.tracker?.cleanDb()  // no orphaned data
                                            // Clean up progress UI
                                            self.cleanupFullRefreshProgressUI()
                                            self.tracker!.refreshDelegate = nil
                                            
                                            self.loadingData = false
                                            self.tracker!.loadingDbData = false
                                            self.isRefreshInProgress = false
                                            
                                            dispatchGroup.leave()
                                        }
                                    })
                            })
                    })
            })
        
        // Notify when all operations are completed
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView!.setNeedsDisplay()
        view.setNeedsDisplay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func setViewMode() {
        rTracker_resource.setViewMode(self)
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                // if darkMode
                tableView!.backgroundView = nil
                tableView!.backgroundColor = UIColor.systemBackground
                return
            }
        }

        tableView!.backgroundColor = UIColor.clear

    }

    override func viewWillAppear(_ animated: Bool) {
        
        DBGLog("STATE: view will appear start")
        
        viewDisappearing = false
        
        var f = rTracker_resource.getKeyWindowFrame()
        
        if f.size.width > f.size.height {
            // already in landscape view
            doGT()
        } else {
            if f.size.width != tableView!.frame.size.width {
                f.origin.x = 0.0
                f.origin.y = 0.0
                tableView!.frame = f
                setViewMode()
                tracker!.rescanMaxLabel()
                tableView!.reloadData()
            }
            
            if _dpr != nil {
                switch dpr.action {
                case DPA_NEW:
                    tracker!.resetData()
                    tracker!.trackerDate = Date(
                        timeIntervalSince1970: TimeInterval(
                            tracker!.noCollideDate(Int(dpr.date!.timeIntervalSince1970))))
                case DPA_SET:
                    if tracker!.hasData() {
                        tracker!.change(dpr.date)
                        needSave = true
                    } else {
                        tracker!.trackerDate = dpr.date
                    }
                    //[self updateToolBar];
                case DPA_GOTO:
                    var targD = 0
                    if nil != dpr.date {
                        // set to nil to cause reset tracker, ready for new
                        targD = Int(dpr.date?.timeIntervalSince1970 ?? 0)
                        if !tracker!.loadData(targD) {
                            tracker!.trackerDate = dpr.date
                            targD = tracker!.prevDate()
                            if targD == 0 {
                                targD = tracker!.postDate()
                            }
                        }
                    }
                    loadTrackerDate(targD)
                case DPA_GOTO_POST /* for TimesSquare calendar which gives date with time=midnight (= beginning of day) */
                    :
                    var targD = 0
                    if nil != dpr.date {
                        // set to nil to cause reset tracker, ready for new
                        targD = Int(dpr.date?.timeIntervalSince1970 ?? 0)
                        if !tracker!.loadData(targD) {
                            tracker!.trackerDate = dpr.date
                            targD = tracker!.postDate()
                            if targD == 0 {
                                targD = 0  // if no post date, must mean today so new tracker
                            }
                            //targD = [self.tracker prevDate];
                        }
                    }
                    loadTrackerDate(targD)
                case DPA_CANCEL:
                    break
                default:
                    dbgNSAssert(false, "failed to determine dpr action")
                }
                dpr.date = nil
                _dpvc = nil
                _dpr = nil
            }
            
            NotificationCenter.default.addObserver(
                tracker!,
                selector: #selector(trackerObj.trackerUpdated(_:)),
                name: NSNotification.Name(rtValueUpdatedNotification),
                object: nil)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(updateUTC(_:)),
                name: NSNotification.Name(rtTrackerUpdatedNotification),
                object: tracker)
            
            //DBGLog(@"add kybd will show notifcation");
            keyboardIsShown = false
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow(_:)),
                name: UIResponder.keyboardWillShowNotification,
                object: view.window)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(configTVObjVC.keyboardWillHide(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: view.window)
            
            showSaveBtn()
            updateTrackerTableView()  // need to force redisplay and set sliders, so reload in viewdidappear not so noticeable

            // controlled by rTracker_resource.setViewMode()
            //navigationController?.toolbar.backgroundColor = .red
            //navigationController?.navigationBar.backgroundColor = .secondarySystemBackground
            navigationController?.setToolbarHidden(false, animated: false)
            
            navigationController?.toolbar.accessibilityIdentifier = "useT_toolbar"

            #if DEBUGLOG
            // Add layout debugging to catch constraint conflicts
            if let toolbar = navigationController?.toolbar {
                DBGLog("Updating toolbar with frame: \(toolbar.frame)")
            }
            #endif

            // Defer toolbar update to next run loop to ensure proper view hierarchy
            DispatchQueue.main.async { [weak self] in
                self?.updateToolBar()
            }
            
        }
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        DBGLog("STATE: view did appear start")
        // in case we just regained active after interruption -- sadly view still seen if done in viewWillAppear
        if (nil != tracker) && (tracker!.getPrivacyValue() > privacyValue) {
            //[self.navigationController popViewControllerAnimated:YES];
            tracker!.activeControl?.resignFirstResponder()
            
            if rTracker_resource.getSavePrivate() {
                btnCancel()
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
        
        tableView!.reloadData()
        didSave = false
        
        if !rTracker_resource.getToldAboutSwipe() {
            // if not yet told
            if 0 != tracker!.prevDate() {
                //  and have previous data
                rTracker_resource.alert("Swipe control", msg: "Swipe for earlier entries", vc: self)
                rTracker_resource.setToldAboutSwipe(true)
                UserDefaults.standard.set(true, forKey: "toldAboutSwipe")
                UserDefaults.standard.synchronize()
            }
        }
        
        super.viewDidAppear(animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewDisappearing = true
        
        DBGLog("utc view disappearing")
        //already done [self.tracker.activeControl resignFirstResponder];
        
        // unregister this tracker for value updated notifications
        NotificationCenter.default.removeObserver(
            tracker!,
            name: NSNotification.Name(rtValueUpdatedNotification),
            object: nil)
        
        //unregister for tracker updated notices
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rtTrackerUpdatedNotification),
            object: nil)
        
        //DBGLog(@"remove kybd will show notifcation");
        // unregister for keyboard notifications while not visible.
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        // unregister for keyboard notifications while not visible.
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        
        // Remove any visual indicators
        rTracker_resource.removeLabels(view: view, labelIds: [refreshLabelId, refreshLabelId2])
        endRAI()
        
        super.viewWillDisappear(animated)
    }
    
    func rejectTracker() {
        DBGLog(
            String(
                "rejecting input tracker \(tracker!.toid) \(tracker!.trackerName ?? "nil")  prevTID= \(tracker!.prevTID)"
            ))
        // RootViewController:loadTrackerDict() sets prevTID to -1 if this is new = no name or existing tid match (rejectable tracker)
        // also loadTrackerDict sets tid to -1 in error condition but never checked
        tlist!.updateTLtid(Int(tracker!.toid), new: tracker!.prevTID)  // revert topLevel to before
        tracker!.deleteTrackerDB()
        rTracker_resource.unStashTracker(tracker!.prevTID)  // this view and tracker going away now so dont need to clear rejectable or prevTID
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if rejectable && viewDisappearing {
            rejectTracker()
        }
    }
    
    // MARK: view rotation methods
    
    override func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        if isViewLoaded && view.window != nil && !isRefreshInProgress {
            
            coordinator.animate(alongsideTransition: { context in
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let orientation = windowScene!.interfaceOrientation
                
                switch orientation {
                case .portrait:
                    DBGLog("utc will rotate to interface orientation portrait")
                case .portraitUpsideDown:
                    DBGLog("utc will rotate to interface orientation portrait upside down")
                case .landscapeLeft:
                    DBGLog("utc will rotate to interface orientation landscape left")
                    //[self.tracker.activeControl resignFirstResponder];
                    //[self doGT];
                case .landscapeRight:
                    DBGLog("utc will rotate to interface orientation landscape right")
                    //[self.tracker.activeControl resignFirstResponder];
                    //[self doGT];
                default:
                    DBGWarn("utc will rotate but can't tell to where")
                }
                
            }) { [self] context in
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let orientation = windowScene!.interfaceOrientation
                switch orientation {
                case .portrait:
                    DBGLog("utc did rotate to interface orientation portrait")
                case .portraitUpsideDown:
                    DBGLog("utc did rotate to interface orientation portrait upside down")
                case .landscapeLeft:
                    DBGLog("utc did rotate to interface orientation landscape left")
                    tracker!.activeControl?.resignFirstResponder()
                    doGT()
                case .landscapeRight:
                    DBGLog("utc did rotate to interface orientation landscape right")
                    tracker!.activeControl?.resignFirstResponder()
                    doGT()
                default:
                    DBGWarn("utc did rotate but can't tell to where")
                }
            }
        } else if isRefreshInProgress {
            // Handle rotation during refresh by ensuring progress UI stays properly positioned
            coordinator.animate(alongsideTransition: { _ in
                // Ensure the progress container stays centered during rotation
                if let container = self.fullRefreshProgressContainerView {
                    // Only update if using constraints - our implementation should already handle this
                    if !container.translatesAutoresizingMaskIntoConstraints {
                        container.layoutIfNeeded()
                    }
                }
            })
        }
        
        super.viewWillTransition(to: size, with: coordinator)
        
    }
    
    func doGT() {
        DBGLog("start present graph")
        
        var gt: graphTrackerVC?
        gt = graphTrackerVC()
        gt?.modalPresentationStyle = .fullScreen  // need for iPad, this is default for 'horizontally compact environment'
        
        gt?.tracker = tracker
        if tracker!.hasData() {
            dpr.date = tracker!.trackerDate
            dpr.action = DPA_GOTO
        }
        gt?.dpr = dpr
        gt?.parentUTC = self
        
        self.gt = gt
        
        fwdRotations = false
        if let gt {
            present(gt, animated: true)
        }
        
        DBGLog("graph up")
    }
    
    func returnFromGraph() {
        if alreadyReturning {
            return
        }
        alreadyReturning = true
        DBGLog("start return from graph")
        fwdRotations = true
        dismiss(animated: true)
        alreadyReturning = false
        DBGLog("graph down")
    }
    
    // MARK: -
    // MARK: full refresh progress bar
    
    private func setupFullRefreshProgressUI() {
        // Calculate size and position for both portrait and landscape orientations
        let containerWidth = min(view.bounds.width - 40, 400)  // Cap width at 400 for large screens
        let containerHeight = 90
        
        // Center in the view
        let xPosition = (view.bounds.width - containerWidth) / 2
        let yPosition = (view.bounds.height - CGFloat(containerHeight)) / 2
        
        // Create container view with Auto Layout support
        fullRefreshProgressContainerView = UIView(
            frame: CGRect(
                x: xPosition, y: yPosition, width: containerWidth, height: CGFloat(containerHeight)))
        fullRefreshProgressContainerView?.translatesAutoresizingMaskIntoConstraints = false
        
        // Style the container
        fullRefreshProgressContainerView?.backgroundColor = UIColor.systemBackground.withAlphaComponent(
            0.95)
        fullRefreshProgressContainerView?.layer.cornerRadius = 12
        fullRefreshProgressContainerView?.layer.borderWidth = 0.5
        fullRefreshProgressContainerView?.layer.borderColor = UIColor.separator.cgColor
        fullRefreshProgressContainerView?.layer.shadowColor = UIColor.black.cgColor
        fullRefreshProgressContainerView?.layer.shadowOffset = CGSize(width: 0, height: 2)
        fullRefreshProgressContainerView?.layer.shadowOpacity = 0.2
        fullRefreshProgressContainerView?.layer.shadowRadius = 6
        
        // Create and configure the progress label with Auto Layout support
        fullRefreshProgressLabel = UILabel()
        fullRefreshProgressLabel?.translatesAutoresizingMaskIntoConstraints = false
        fullRefreshProgressLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        fullRefreshProgressLabel?.textColor = .label
        fullRefreshProgressLabel?.textAlignment = .center
        fullRefreshProgressLabel?.text = "Preparing refresh..."
        
        // Create and configure the progress bar with Auto Layout support
        fullRefreshProgressBar = UIProgressView()
        fullRefreshProgressBar?.translatesAutoresizingMaskIntoConstraints = false
        fullRefreshProgressBar?.progressViewStyle = .bar
        fullRefreshProgressBar?.progressTintColor = .systemBlue
        fullRefreshProgressBar?.trackTintColor = .systemGray5
        fullRefreshProgressBar?.progress = 0.0
        fullRefreshProgressBar?.layer.cornerRadius = 4
        fullRefreshProgressBar?.clipsToBounds = true
        
        currentTotalSteps = 0
        
        // Add the UI elements to the container
        if let container = fullRefreshProgressContainerView, let label = fullRefreshProgressLabel,
           let progressBar = fullRefreshProgressBar
        {
            view.addSubview(container)
            container.addSubview(label)
            container.addSubview(progressBar)
            
            // Center the container in the view with constraints
            NSLayoutConstraint.activate([
                container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                container.widthAnchor.constraint(equalToConstant: containerWidth),
                container.heightAnchor.constraint(equalToConstant: CGFloat(containerHeight)),
                
                // Position the label at the top with margins
                label.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
                
                // Position the progress bar below the label
                progressBar.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 15),
                progressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 15),
                progressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -15),
                progressBar.heightAnchor.constraint(equalToConstant: 8),
            ])
            
            // Bring to front to ensure visibility
            view.bringSubviewToFront(container)
            
            // Keep hidden initially - will be shown when a phase exceeds threshold
            container.isHidden = true
            progressBar.isHidden = true
            label.isHidden = true
        }
    }
    
    // Clean up progress tracking UI elements
    private func cleanupFullRefreshProgressUI() {
        DBGLog("Cleaning up progress UI for phase '\(currentRefreshPhase)'")
        
        self.endRAI()
        self.progressBarShown = false
        
        // Fade out the progress view container with animation
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.fullRefreshProgressContainerView?.alpha = 0
                self.fullRefreshProgressContainerView?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: { _ in
                // Clean up resources after animation completes
                self.fullRefreshProgressContainerView?.removeFromSuperview()
                self.fullRefreshProgressContainerView = nil
                self.fullRefreshProgressBar = nil
                self.fullRefreshProgressLabel = nil
                
                // Reset tracking variables
                self.currentProgressStep = 0
                self.currentRefreshPhase = ""
                self.currentProgressMaxValue = 1.0
                self.lastUIProgressValue = -1.0
            })
    }
    
    // Update progress bar and label - implements RefreshProgressDelegate protocol
    func updateFullRefreshProgress(
        step: Int, phase: String?, totalSteps: Int?, addSteps: Int?, threshold: Int?, completed: Bool
    ) {
        if let threshold = threshold {
            currentProgressThreshold = threshold
            //DBGLog("Progress threshold set to: \(threshold)")
        }
        if let phase = phase {
            currentRefreshPhase = phase
            //DBGLog("Progress phase set to: \(phase)")
        }
        // If totalSteps provided, initialize/reset the progress bar for this phase
        var doInit = false
        var addedSteps = false
        if let totalSteps = totalSteps {
            currentTotalSteps = totalSteps
            doInit = true
            currentTasks = 0
            //DBGLog("Progress total steps set to: \(totalSteps) threshold is \(currentProgressThreshold) progressBarShown is \(progressBarShown)")
        }
        
        if let addSteps = addSteps {
            if currentTotalSteps == 0 {
                doInit = true  // only works because only HK uses addSteps, and HK is first
                currentTasks = 1
            } else {
                currentTasks += 1
            }
            
            addedSteps = true
            currentTotalSteps += addSteps
            DBGLog(
                "Progress total steps increased by: \(addSteps) currentTotalSteps is \(currentTotalSteps)")
        }
        if completed {
            currentTasks -= 1
        }
        if doInit {
            if currentTotalSteps > currentProgressThreshold {
                DBGLog(
                    "Initializing progress bar for phase '\(phase ?? "unknown")' with \(currentTotalSteps) total steps threshold is \(currentProgressThreshold) progressBarShown is \(progressBarShown)"
                )
                currentProgressStep = 0
                lastUIProgressValue = -1.0  // Reset UI tracking for new phase
#if DEBUGLOG
                lastLoggedTenPercent = -1  // Reset logging tracker for new phase
#endif
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    // Set maximum value and reset progress to 0
                    self.currentProgressMaxValue = Float(currentTotalSteps)
                    self.fullRefreshProgressBar?.progress = 0.0
                    
                    // Check if container was hidden before showing it
                    let wasHidden = self.fullRefreshProgressContainerView?.isHidden ?? true
                    
                    if !progressBarShown {
                        // Show the progress bar and stop spinner
                        self.fullRefreshProgressBar?.isHidden = false
                        self.fullRefreshProgressLabel?.isHidden = false
                        self.fullRefreshProgressContainerView?.isHidden = false
                        self.progressBarShown = true
                        
                        self.endRAI()
                        DBGLog("endRAI called from progress init for phase \(self.currentRefreshPhase)")
                    }
                    
                    if currentTotalSteps > currentProgressThreshold {
                        // Set initial phase text
                        self.fullRefreshProgressLabel?.text = "\(self.currentRefreshPhase) - 0%"
                    }
                    
                    // Animate appearance only when first showing (if previously hidden)
                    if wasHidden, let container = self.fullRefreshProgressContainerView {
                        container.alpha = 0
                        UIView.animate(withDuration: 0.3) {
                            container.alpha = 1
                        }
                    }
                    
                    // Force layout update
                    self.fullRefreshProgressContainerView?.setNeedsLayout()
                    self.fullRefreshProgressContainerView?.layoutIfNeeded()
                }
            } else {
                DBGLog("phase \(self.currentRefreshPhase) Current total steps: \(currentTotalSteps), Progress threshold: \(currentProgressThreshold), frac: \((Double(currentTotalSteps) / Double(currentProgressThreshold))), progBarShown: \(progressBarShown)")
                if currentTotalSteps > 1
                        && (Double(currentTotalSteps) / Double(currentProgressThreshold)) > 0.1 && !progressBarShown
            {
                self.startRAI()
            }
            }
            return
        }
        
        // Check if progress bar is initialized (visible) before processing step updates
        if !progressBarShown {
            // Progress bar not initialized, ignore step updates (spinner continues)
            return
        } else if addedSteps {
            self.currentProgressMaxValue = Float(currentTotalSteps)
        }
        
        currentProgressStep += step
        
        // Calculate progress based on current maximum value
        let progressValue = min(Float(currentProgressStep) / currentProgressMaxValue, 1.0)
        
        // Early return optimization: Skip UI updates if progress change is too small to be visible
        // Progress bar has ~4 visual increments per percentage point, so 0.002 threshold
        let progressDelta = abs(progressValue - lastUIProgressValue)
        let bigStep = step >= max(5, Int(currentProgressMaxValue * 0.05))  // Always update for big steps (5+ or 5% of total)
        
        if lastUIProgressValue >= 0 && progressDelta < 0.002 && !completed && !bigStep {
            // Skip this update - too small to see, unless it's completion or a significant step
            return
        }
        
#if DEBUGLOG
        // Log only when we cross into a new 10% bracket or when we're updating UI
        let currentTenPercent = Int(progressValue * 10)
        if currentTenPercent > lastLoggedTenPercent {
            lastLoggedTenPercent = currentTenPercent
            let updateReason = completed ? " [COMPLETION]" : bigStep ? " [BIG_STEP]" : progressDelta >= 0.002 ? " [VISIBLE_DELTA]" : ""
            DBGLog(
                "🔄 UI UPDATE\(updateReason) - step \(step), phase '\(currentRefreshPhase)', progress \(currentProgressStep)/\(Int(currentProgressMaxValue)) (\(String(format: "%.3f", progressValue)), Δ\(String(format: "%.4f", progressDelta)))"
            )
        }
#endif
        
        if currentTotalSteps > currentProgressThreshold {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Update UI elements
                self.fullRefreshProgressBar?.progress = progressValue
                
                // Format the text with phase and percentage
                let cPhase = self.currentRefreshPhase.isEmpty ? "Processing data" : self.currentRefreshPhase
                let taskState = (currentTasks > 1) ? " (\(currentTasks) tasks)" : ""
                self.fullRefreshProgressLabel?.text = "\(cPhase) - \(Int(progressValue * 100))%\(taskState)"
                
                // Record this as the last UI update value
                self.lastUIProgressValue = progressValue
                
                // Force immediate layout update for toolbar progress indicator
                self.fullRefreshProgressLabel?.setNeedsDisplay()
                self.fullRefreshProgressBar?.setNeedsDisplay()
                self.fullRefreshProgressContainerView?.setNeedsLayout()
                self.fullRefreshProgressContainerView?.layoutIfNeeded()
                
                // Force window update if possible
                self.view.window?.layoutIfNeeded()
            }
        }
    }
    
    // MARK: -
    // MARK: keyboard notifications
    
    @objc func keyboardWillShow(_ n: Notification?) {
        if let sv = tracker?.activeControl?.superview {
            // can get here after closing voTextBox with nil activeControl
            rTracker_resource.willShowKeyboard(n, vwTarg: sv, vwScroll: view)  // superview is table cell holding active control
        }
    }
    
    @objc func keyboardWillHide(_ n: Notification?) {
        DBGLog("handling keyboard will hide")
        rTracker_resource.willHideKeyboard()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
#if DEBUGLOG
        let touch = touches.first
        let touchPoint = touch?.location(in: view)
        DBGLog(String("I am touched at \(touchPoint!.x), \(touchPoint!.y)."))
#endif
        
        tracker!.activeControl?.resignFirstResponder()
    }
    
    // MARK: -
    // MARK: top toolbar button factories
    
    var _saveBtn: UIBarButtonItem?
    var saveBtn: UIBarButtonItem {
        if _saveBtn == nil {
            _saveBtn = rTracker_resource.createSaveButton(target: self, action: #selector(addTrackerController.btnSave))

            _saveBtn!.accessibilityLabel = "Save"
            _saveBtn!.accessibilityHint = "tap to save this entry"
            _saveBtn!.accessibilityIdentifier = "trkrSave"
        }
        return _saveBtn!
    }
    
    var _menuBtn: UIBarButtonItem?
    var menuBtn: UIBarButtonItem {
        if _menuBtn == nil {
            if rejectable {
                _menuBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnAccept), symbolName: "arrow.down.doc.fill", tintColor: .systemGreen, fallbackTitle: "Accept")
                _menuBtn!.accessibilityLabel = "Accept"
                _menuBtn!.accessibilityHint = "tap to accept importing this tracker"
                _menuBtn!.accessibilityIdentifier = "trkrAccept"
            } else {
                let paleBlue = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
                _menuBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnMenu), symbolName: "filemenu.and.pointer.arrow", tintColor: paleBlue, fallbackSystemItem: .action)
                _menuBtn!.accessibilityLabel = "Share Menu"
                _menuBtn!.accessibilityHint = "tap to show sharing options"
                _menuBtn!.accessibilityIdentifier = "trkrMenu"
            }
        }

        return _menuBtn!
    }
    
    // MARK: -
    // MARK: datepicker support
    
    func clearVoDisplay() {
        for vo in tracker!.valObjTableH {
            //if (vo.vtype == VOT_FUNC)
            vo.display = nil  // always redisplay
        }
        
    }
    
    func updateTrackerTableView() {
        // see related updateTableCells above
        //DBGLog(@"utc: updateTrackerTableView");
        DispatchQueue.main.async(execute: { [self] in
            
            for vo in tracker!.valObjTableH {
                vo.display = nil  // always redisplay
            }
            
            // Remove any existing tint view (in case state changed)
            if let existingTintView = view.viewWithTag(1001) {
                existingTintView.removeFromSuperview()
            }
            
            // Check if record is ignored and add tint if needed
            if isRecordIgnored() {
                // Create a semi-transparent red overlay
                let tintView = UIView(frame: tableView!.frame)
                tintView.backgroundColor = UIColor.red.withAlphaComponent(0.05)  // Light red tint
                tintView.tag = 1001  // Tag to find it later
                
                // Add it above background but below table
                view.insertSubview(tintView, aboveSubview: view.viewWithTag(BGTAG)!)
                //view.sendSubviewToBack(tableView!)
                //view.bringSubviewToFront(tintView)
            }
            
            tableView!.reloadData()
        })
    }
    
    // MARK: - Constraint Helper Method (No longer needed - kept for reference)
    // The constraint conflicts were resolved by using emoji buttons on iOS 18+ and glass buttons on iOS 26+

    func updateToolBar() {

        #if DEBUGLOG
        // Defensive check to prevent layout conflicts during view transitions
        if view.window == nil {
            DBGLog("Deferring toolbar update until view is in window hierarchy")
            DispatchQueue.main.async { [weak self] in
                self?.updateToolBar()
            }
            return
        }
        #endif

        var tbi: [AnyHashable] = []
        
        let prevD = tracker!.prevDate()
        let postD = tracker!.postDate()
        let lastD = tracker!.lastDate()
        let currD = Int(tracker!.trackerDate?.timeIntervalSince1970 ?? 0)
        /*
         DBGLog(@"prevD = %d %@",prevD,[NSDate dateWithTimeIntervalSince1970:prevD]);
         DBGLog(@"currD = %d %@",currD,[NSDate dateWithTimeIntervalSince1970:currD]);
         DBGLog(@"postD = %d %@",postD,[NSDate dateWithTimeIntervalSince1970:postD]);
         DBGLog(@"lastD = %d %@",lastD,[NSDate dateWithTimeIntervalSince1970:lastD]);
         */
        _currDateBtn = nil
        
        if postD != 0 || (lastD == currD) {
            tbi.append(delBtn)
            
        } else {
            tbi.append(fixed1SpaceButtonItem)
        }
        
        tbi.append(flexibleSpaceButtonItem)
        
        tbi.append(currDateBtn)
        
        tbi.append(flexibleSpaceButtonItem)
        
        if (prevD != 0) || (postD != 0) || (lastD == currD) {
            tbi.append(calBtn)
        } else {
            tbi.append(fixed1SpaceButtonItem)
        }
        tbi.append(flexibleSpaceButtonItem)
        
        if nil != searchSet {
            tbi.append(searchBtn)
        } else {
            tbi.append(fixed1SpaceButtonItem)
        }
        _tsCalVC = nil  // reload calendar to reflect searchSet or not
        
        tbi.append(flexibleSpaceButtonItem)
        if postD != 0 || (lastD == currD) {
            tbi.append(skip2EndBtn)
        } else if 10 < tracker?.toQry2Int(sql: "select count(*) from trkrData") ?? 0 {
            tbi.append(createChartBtn)
        } else {
            tbi.append(fixed1SpaceButtonItem)
        }
        
        // Ensure all toolbar items are valid UIBarButtonItems before setting
        let validToolbarItems = tbi.compactMap { $0 as? UIBarButtonItem }

        #if DEBUGLOG
        if validToolbarItems.count != tbi.count {
            DBGWarn("Some toolbar items were not UIBarButtonItem instances: expected \(tbi.count), got \(validToolbarItems.count)")
        }
        #endif

        // Set toolbar items - simplified since constraint conflicts are resolved
        if !validToolbarItems.isEmpty {
            setToolbarItems(validToolbarItems, animated: false)
        }
    }
    
    func dispatchHandleModifiedTracker(_ choice: Int) {
        
        if 0 == choice {
            // cancel
            return
        }
        
        if alertResponse != 0 {
            if 1 == choice {
                // save
                saveActions()
            } else if 2 == choice {
                // discard
            }
            needSave = false
            if CSSETDATE == alertResponse {
                let tsdate = saveTargD
                alertResponse = 0
                saveTargD = 0
                loadTrackerDate(tsdate)
            } else if CSCANCEL == alertResponse {
                alertResponse = 0
                btnCancel()
                //[self dealloc];
            } else if CSSHOWCAL == alertResponse {
                alertResponse = 0
                btnCal()
            }
        }
    }
    
    func handleDeleteEntry(_ choice: Int) {
        
        if 0 == choice {
            DBGLog("cancelled")
        } else {
            var targD = tracker!.prevDate()
            if targD == 0 {
                targD = tracker!.postDate()
            }
            tracker!.deleteCurrEntry()
            loadTrackerDate(targD)
        }
    }
    
    func alertChkSave() {
        let title = tracker!.trackerName! + " modified"  // 'modified' needed by handler
        let msg = "Save this record before leaving?"
        let btn0 = "Cancel"
        let btn1 = "Save"
        let btn2 = "Discard"
        
        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(
            title: btn0, style: .default,
            handler: { [self] action in
                dispatchHandleModifiedTracker(0)
            })
        let saveAction = UIAlertAction(
            title: btn1, style: .default,
            handler: { [self] action in
                dispatchHandleModifiedTracker(1)
            })
        let discardAction = UIAlertAction(
            title: btn2, style: .default,
            handler: { [self] action in
                dispatchHandleModifiedTracker(2)
            })
        
        alert.addAction(saveAction)
        alert.addAction(discardAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func loadTrackerDate(_ targD: Int) {
        
        if needSave {
            alertResponse = CSSETDATE
            saveTargD = targD
            alertChkSave()
            return
        }
        
        if targD > 0 {
            DBGLog(
                String(" setTrackerDate: \(targD) = \(Date(timeIntervalSince1970: TimeInterval(targD)))"))
            if !tracker!.loadData(targD) {
                DBGLog("date not found! resetting tracker")
                tracker!.resetData()
            }
        } else {
            DBGLog(String(" setTrackerDate: \(targD) = reset to now"))
            tracker!.resetData()
        }
        
        needSave = false  // dumping anything not saved by going to another date.
        showSaveBtn()
        updateToolBar()
        updateTrackerTableView()
    }
    
    // MARK: -
    // MARK: button press action methods
    
    func applicationWillResignActive(_ application: UIApplication) {
        DBGLog("HEY!")
    }
    
    func leaveTracker() {
        tracker!.removeTempTrackerData()
        if didSave {
            tracker!.setReminders()  // saved data may change reminder action so wipe and set again
            didSave = false
        } else {
            tracker!.confirmReminders()  // else just confirm any enabled reminders have one scheduled
        }
        // took out because need default 'back button' = "<name>'s tracks" but can't set action only for that button -- need to catch in viewWillDisappear  -- FAILED
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnCancel() {
        // back button
        
        DBGLog("btnCancel was pressed!")
        if needSave {
            alertResponse = CSCANCEL
            alertChkSave()
            return
        }
        
        leaveTracker()
    }
    
    func saveActions() {
        if rejectable {
            if tracker!.prevTID != 0 {
                rTracker_resource.rmStashedTracker(tracker!.prevTID)
                tracker!.prevTID = 0
            }
            rejectable = false
            checkPrivWarn()
        }
        
        tracker!.saveData()
        needSave = false
        
    }
    
    @objc func btnSave() {
        //DBGLog(@"btnSave was pressed! tracker name= %@ toid= %d",self.tracker.trackerName, self.tracker.toid);
        saveActions()
        
        if nil != searchSet {
            // don't leave if have search set, just update save button to indicate save not needed
            showSaveBtn()  // also don't clear form as below
            return
        }
        
        if tracker!.optDict["savertn"] as? String ?? "1" == "0" {
            let postD = tracker!.postDate()
            if postD == 0 {
                // Only reset if we're on the last record (no next date)
                tracker!.resetData()
            }
            
            updateToolBar()
            updateTrackerTableView()
            needSave = false
            showSaveBtn()
        } else {
            leaveTracker()
        }
    }
    
    func handleViewSwipeUp(_ gesture: UISwipeGestureRecognizer?) {
        if needSave {
            btnSave()
        } else {
            btnCancel()
        }
    }
    
    @objc func doPlistExport() {
        autoreleasepool {
            _ = tracker!.saveToItunes()
            safeDispatchSync({ [self] in
                rTracker_resource.finishProgressBar(view, navItem: navigationItem, disable: true)
            })
            rTracker_resource.alert(
                "Tracker saved",
                msg:
                    "\(tracker!.trackerName ?? "")_out.csv and _out.plist files have been saved to the rTracker Documents directory on this device\(rTracker_resource.getRtcsvOutput() ? " in rtCSV format" : "").  Access them through iTunes on your PC/Mac, or with a program like iExplorer from Macroplant.com.  Import by changing the names to _in.csv and _in.plist, and read about .rtcsv file import capabilities in the help pages.\n\nNote: Hidden private data has not been saved.",
                vc: self)
        }
    }
    
    func privAlert(_ tpriv: Int, vpm: Int) {
        var msg: String?
        if vpm > tpriv {
            if tpriv > PRIVDFLT {
                msg = String(
                    format:
                        "Set a privacy level greater than %ld to see the %@ tracker, and greater than %ld to see all items in it",
                    tpriv, tracker!.trackerName ?? "", vpm)
            } else {
                msg = String(
                    format: "Set a privacy level greater than %ld to see all items in the %@ tracker", vpm,
                    tracker!.trackerName ?? "")
            }
        } else {
            msg = String(
                format: "Set a privacy level greater than %ld to see the %@ tracker", tpriv,
                tracker!.trackerName ?? "")
        }
        rTracker_resource.alert("Privacy alert", msg: msg, vc: self)
    }
    
    func checkPrivWarn() {
        let tpriv = Int(tracker!.optDict["privacy"] as? String ?? "1") ?? 1
        var vprivmax = PRIVDFLT
        
        for vo in tracker!.valObjTableH {
            vo.vpriv = Int(vo.optDict["privacy"]!)!
            if vo.vpriv > vprivmax {
                vprivmax = vo.vpriv
            }
        }
        
        if (tpriv > PRIVDFLT) || (vprivmax > PRIVDFLT) {
            privAlert(tpriv, vpm: vprivmax)
        }
    }
    
    @IBAction func btnAccept() {
        
        DBGLog("accepting tracker")
        if tracker!.prevTID != 0 {
            rTracker_resource.rmStashedTracker(tracker!.prevTID)
            tracker!.prevTID = 0
        }
        rejectable = false
        //[self.tlist loadTopLayoutTable];
        checkPrivWarn()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        if !tracker!.swipeEnable {
            return
        }
        var targD = tracker!.prevDate()
        if targD == 0 {
            targD = -1  // no previous date available
        } else if let searchSet {
            let filteredValues = searchSet.filter { $0 <= targD }
            targD = filteredValues.max() ?? -1  // no more values
        }
        loadTrackerDate(targD)
        
        if targD > 0 {
            tableView!.reloadSections(NSIndexSet(index: 0) as IndexSet, with: .right)
        }
    }
    
    @objc func handleViewSwipeLeft(_ gesture: UISwipeGestureRecognizer?) {
        if !tracker!.swipeEnable {
            return
        }
        var targD = tracker!.postDate()
        if targD > 0, let searchSet {
            let filteredValues = searchSet.filter { $0 >= targD }
            targD = filteredValues.min() ?? 0  // past last search targ go to blank tracker
        }
        loadTrackerDate(targD)
        if targD > 0 {
            tableView!.reloadData()
        }
        
    }
    
    @objc func btnSkip2End() {
        loadTrackerDate(0)
    }
    
    @objc func btnCreateChart() {
        if isRefreshInProgress {
            return  // just wait please....
        }
        // Create an instance of the TrackerChart view controller
        let chartVC = TrackerChart(nibName: nil, bundle: nil)
        
        // Pass the current tracker to the chart view controller
        chartVC.tracker = self.tracker
        
        // Present the chart view controller
        navigationController?.pushViewController(chartVC, animated: true)
    }
    
    @objc func btnCurrDate() {
        //DBGLog(@"pressed date becuz its a button, should pop up a date picker....");
        
        dpvc.myTitle = "Date for \(tracker!.trackerName ?? "")"
        dpr.date = tracker!.trackerDate
        dpvc.dpr = dpr
        
        //CGRect f = self.view.frame;
        
        dpvc.modalTransitionStyle = .coverVertical
        dpvc.presentationController?.delegate = self  // need for ios 13 to access viewWillAppear as presentationControllerDidDismiss not firing
        present(dpvc, animated: true)
    }
    
    @objc func btnDel() {
        let title = "Delete entry"
        let msg =
        "Really delete \(tracker!.trackerName ?? "") entry \(tracker!.trackerDate?.description(with: NSLocale.current) ?? "")?"
        let btn0 = "Cancel"
        let btn1 = "Yes, delete"
        
        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(
            title: btn0, style: .default,
            handler: { [self] action in
                handleDeleteEntry(0)
            })
        let deleteAction = UIAlertAction(
            title: btn1, style: .default,
            handler: { [self] action in
                handleDeleteEntry(1)
            })
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
        
    }
    
    // MARK: -
    // MARK: timesSquare calendar vc
    
    var _tsCalVC: trackerCalViewController?
    var tsCalVC: trackerCalViewController {
        if nil == _tsCalVC {
            _tsCalVC = trackerCalViewController()
        }
        return _tsCalVC!
    }
    
    @objc func btnCal() {
        DBGLog("cal btn")
        if needSave {
            alertResponse = CSSHOWCAL
            alertChkSave()
            return
        }
        
        //self.dpvc.myTitle = [NSString stringWithFormat:@"Date for %@", self.tracker.trackerName];
        dpr.date = tracker!.trackerDate
        tsCalVC.dpr = dpr
        tsCalVC.tracker = tracker
        tsCalVC.parentUTC = self
        tsCalVC.presentationController?.delegate = self  // need for ios 13 to access viewWillAppear as presentationControllerDidDismiss not firing
        
        tsCalVC.modalTransitionStyle = .coverVertical
        
        present(tsCalVC, animated: true)
    }
    
    // MARK: -
    // MARK: UIBar button getters
    
    var _currDateBtn: UIBarButtonItem?
    var currDateBtn: UIBarButtonItem {
        //DBGLog(@"currDateBtn called");
        if _currDateBtn == nil {

            var datestr: String? = nil
            if let aTrackerDate = tracker!.trackerDate {
                datestr = DateFormatter.localizedString(
                    from: aTrackerDate,
                    dateStyle: .short,
                    timeStyle: .short)
            }

            //DBGLog(@"creating button");
            if #available(iOS 26.0, *) {
                // iOS 26: Use glass effect button
                let button = UIButton(type: .system)
                button.setTitle(datestr, for: .normal)
                button.configuration = UIButton.Configuration.glass()
                button.addTarget(self, action: #selector(btnCurrDate), for: .touchUpInside)
                _currDateBtn = UIBarButtonItem(customView: button)
                _currDateBtn!.hidesSharedBackground = true  // Remove white container background
            } else {
                // Pre-iOS 26: Use text button as before
                _currDateBtn = UIBarButtonItem(
                    title: datestr,
                    style: .plain,
                    target: self,
                    action: #selector(btnCurrDate))
            }

            //_currDateBtn!.accessibilityLabel = "Date"
            _currDateBtn!.accessibilityHint = "tap to modify entry time and date"
            _currDateBtn!.accessibilityIdentifier = "trkrDate"
        }

        return _currDateBtn!
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
    
    var _fixed1SpaceButtonItem: UIBarButtonItem?
    var fixed1SpaceButtonItem: UIBarButtonItem {
        if _fixed1SpaceButtonItem == nil {
            _fixed1SpaceButtonItem = UIBarButtonItem(
                barButtonSystemItem: .fixedSpace,
                target: nil,
                action: nil)
            _fixed1SpaceButtonItem!.width = CGFloat(32.0)
        }
        
        return _fixed1SpaceButtonItem!
    }
    
    var _calBtn: UIBarButtonItem?
    var calBtn: UIBarButtonItem {
        if _calBtn == nil {
            let paleGreen = UIColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
            _calBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnCal), symbolName: "calendar", tintColor: paleGreen, fallbackTitle: "Cal")
            _calBtn!.accessibilityLabel = "Calendar"
            _calBtn!.accessibilityHint = "tap to select entries by date"
            _calBtn!.accessibilityIdentifier = "trkrCal"
        }

        return _calBtn!
    }
    
    var _searchBtn: UIBarButtonItem?
    var searchBtn: UIBarButtonItem {
        if _searchBtn == nil {
            let blue = UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
            _searchBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnSearch), symbolName: "magnifyingglass.circle", tintColor: blue, fallbackTitle: "Search")
            _searchBtn!.accessibilityLabel = "Search"
            _searchBtn!.accessibilityHint = "tap for search instructions"
            _searchBtn!.accessibilityIdentifier = "trkrSearch"
        }

        return _searchBtn!
    }
    
    @objc func btnSearch() {
        rTracker_resource.alert(
            "Search results",
            msg: String(
                format: "%ld entries highlighted in calendar and graph views, or swipe right/left",
                Int(searchSet!.count)), vc: self)
    }
    
    var _delBtn: UIBarButtonItem?
    var delBtn: UIBarButtonItem {
        if _delBtn == nil {
            _delBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnDel), symbolName: "xmark.bin", tintColor: .systemRed, fallbackSystemItem: .trash)
        }

        return _delBtn!
    }
    
    var _skip2EndBtn: UIBarButtonItem?
    var skip2EndBtn: UIBarButtonItem {
        if _skip2EndBtn == nil {
            _skip2EndBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnSkip2End), symbolName: "chevron.forward.to.line", fallbackSystemItem: .fastForward)
            _skip2EndBtn!.accessibilityLabel = "Skip"
            _skip2EndBtn!.accessibilityHint = "tap to skip to new entry"
            _skip2EndBtn!.accessibilityIdentifier = "trkrSkip"
        }

        return _skip2EndBtn!
    }
    
    // MARK: -
    // MARK: share sheet
    
    func duplicateEntry() {
        tracker!.trackerDate = Date()
        needSave = true
        
        showSaveBtn()
        
        // write temp tracker here
        tracker!.saveTempTrackerData()
        updateToolBar()
        updateTrackerTableView()
    }
    
    func ignoreRecord() {
        let currD = Int(tracker!.trackerDate?.timeIntervalSince1970 ?? 0)
        if currD != 0 {
            tracker!.toExecSql(sql: "insert into ignoreRecords (date) values (\(currD))")
        }
        updateTrackerTableView()
    }
    
    func restoreRecord() {
        let currD = Int(tracker!.trackerDate?.timeIntervalSince1970 ?? 0)
        if currD != 0 {
            tracker!.toExecSql(sql: "delete from ignoreRecords where date = \(currD)")
        }
        updateTrackerTableView()
    }
    
    var _createChartBtn: UIBarButtonItem?
    var createChartBtn: UIBarButtonItem {
        if _createChartBtn == nil {
            _createChartBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnCreateChart), symbolName: "chart.line.uptrend.xyaxis", fallbackTitle: "Chart")
            _createChartBtn!.accessibilityLabel = "Chart"
            _createChartBtn!.accessibilityHint = "tap to view data charts"
            _createChartBtn!.accessibilityIdentifier = "trkrChart"
        }
        return _createChartBtn!
    }
    
    @IBAction func iTunesExport() {
        
        DBGLog("exporting tracker:")
#if DEBUGLOG
        tracker!.describe()
#endif
        let navframe = navigationController?.navigationBar.frame
        rTracker_resource.startProgressBar(
            view, navItem: navigationItem, disable: true,
            yloc: (navframe?.size.height ?? 0.0) + (navframe?.origin.y ?? 0.0))
        Thread.detachNewThreadSelector(#selector(doPlistExport), toTarget: self, with: nil)
    }
    
    // Menu options
    enum MenuOption: String {
        case shareCSV = "Share CSV"
        case shareTracker = "Share Tracker"
        case shareTrackerData = "Share Tracker+Data"
        case saveToPC = "Save to app directory"
        case saveRecord = "Save unchanged record"
        case duplicateEntry = "Duplicate entry to Now"
        case ignoreRecord = "ignore record"
        case restoreRecord = "restore record for charts"
        case cancel = "Cancel"
    }
    
    func isRecordIgnored() -> Bool {
        let currD = Int(tracker!.trackerDate?.timeIntervalSince1970 ?? 0)
        if currD != 0 {
            let ignored = tracker!.toQry2Int(
                sql: "select exists (select 1 from ignoreRecords where date = \(currD))")
            return (ignored == 1)
        }
        return false
    }
    
    @IBAction func btnMenu() {
        let alert = UIAlertController(
            title: tracker?.trackerName ?? "", message: nil, preferredStyle: .actionSheet)
        
        var options: [MenuOption] = [.shareCSV, .shareTracker, .shareTrackerData, .saveToPC]
        
        let postD = tracker!.postDate()
        let lastD = tracker!.lastDate()
        let currD = Int(tracker!.trackerDate?.timeIntervalSince1970 ?? 0)
        if postD != 0 || lastD == currD {
            options.append(.duplicateEntry)
            if isRecordIgnored() {
                options.append(.restoreRecord)
            } else {
                options.append(.ignoreRecord)
            }
        } else {
            options.append(.saveRecord)
        }
        
        for option in options {
            let action = UIAlertAction(title: option.rawValue, style: .default) { [self] _ in
                handleMenuOption(option)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: MenuOption.cancel.rawValue, style: .cancel, handler: nil))

        present(alert, animated: true)
    }
    
    func handleMenuOption(_ option: MenuOption) {
        guard let tracker = tracker else { return }
        
        var fileURL: URL?
        // var fileType: String?
        
        switch option {
        case .shareCSV:
            fileURL = tracker.writeTmpCSV()
        case .shareTracker, .shareTrackerData:
            fileURL = tracker.writeTmpRtrk(option == .shareTrackerData)
        case .saveToPC:
            iTunesExport()
        case .saveRecord:
            saveActions()
        case .duplicateEntry:
            duplicateEntry()
        case .ignoreRecord:
            ignoreRecord()
        case .restoreRecord:
            restoreRecord()
        case .cancel:
            break
        }
        
        guard let fileURL = fileURL else {
            // exit path for iTunesExport, duplicateEntry and faile to writeTmpXXX
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = {
            activityType, completed, returnedItems, activityError in
            // Handle completion
            try? FileManager.default.removeItem(at: fileURL)  // Ensure temporary files are cleaned up
        }
        self.present(activityViewController, animated: true)
    }
    
    // MARK: -
    // MARK: Table view methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Customize the number of rows in the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracker!.valObjTableH.count
    }
    
    let CHECKBOX_WIDTH = 40.0
    
    // Customize the appearance of table view cells.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let vo = (tracker!.valObjTableH)[row]
        //DBGLog(@"uvc table cell at index %d label %@",row,vo.valueName);
        
        return (vo.vos?.voTVCell(tableView))!
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let vo = (tracker!.valObjTableH)[row]
        return vo.vos?.voTVCellHeight() ?? 0.0
    }
    
    // Override to support row selection in the table view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vo = (tracker!.valObjTableH)[indexPath.row]
        
#if DEBUGLOG
        let row = indexPath.row
        //valueObj *vo = (valueObj *) [self.tracker.valObjTableH  objectAtIndex:row];
        DBGLog(String("selected row \(UInt(row)): \(vo.valueName)"))
#endif
        
        if VOT_INFO == vo.vtype {
            if var url = (vo.optDict["infourl"])?.trimmingCharacters(
                in: CharacterSet.whitespacesAndNewlines), !url.isEmpty
            {
                if !url.contains("://") {
                    url = "http://" + url
                }
                DBGLog("vot_info: selected -> fire url: \(url)")
                UIApplication.shared.open(URL(string: url)!, options: [:]) { success in
                    if !success {
                        if url.localizedCaseInsensitiveContains("http://")
                            || url.localizedCaseInsensitiveContains("https://")
                        {
                            rTracker_resource.alert(
                                "Failed to open URL", msg: "Failed to open the URL \(url) - network problem?",
                                vc: self)
                        } else {
                            rTracker_resource.alert(
                                "Failed to open URL",
                                msg:
                                    "Failed to open the URL \(url) - perhaps the supporting app is not installed??",
                                vc: self)
                        }
                    }
                }
            }
            
        }
    }
}

let CSCANCEL = 1
let CSSETDATE = 2
let CSSHOWCAL = 3
