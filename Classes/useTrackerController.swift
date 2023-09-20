//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
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
//  this screen presents the list of value objects for a specified tracker
//
//  Created by Robert Miller on 03/09/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
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

class useTrackerController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UIAdaptivePresentationControllerDelegate {

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
    /*
    var prevDateBtn: UIBarButtonItem?
    var postDateBtn: UIBarButtonItem?
    var currDateBtn: UIBarButtonItem?
    var calBtn: UIBarButtonItem?
    var searchBtn: UIBarButtonItem?
    var delBtn: UIBarButtonItem?
    var skip2EndBtn: UIBarButtonItem?
    //var flexibleSpaceButtonItem: UIBarButtonItem?
    var fixed1SpaceButtonItem: UIBarButtonItem?
    var saveBtn: UIBarButtonItem?
    var menuBtn: UIBarButtonItem?
    */
    var gt: UIViewController?
    //n
    //updateToolBar
    //targD
    //doGT
    //returnFromGraph
    //rejectTracker
    //- (BOOL) automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers;


    var alreadyReturning = false // graphTrackerVC viewWillTransitionToSize() called when we dismissVieControllerAnimated() below, so don't call a second time
    var emCancel = "Cancel"
    var emEmailCsv = "email CSV"
    var emEmailTracker = "email Tracker"
    var emEmailTrackerData = "email Tracker+Data"
    var emItunesExport = "save for PC (iTunes)"
    var emDuplicate = "duplicate entry to now"
    //BOOL keyboardIsShown=NO;

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

        for vo in tracker!.valObjTable {
            if VOT_FUNC == vo.vtype {
                vo.display = nil // always redisplay
                iparr.append(IndexPath(index: 0).appending(n))
            } else if (inVO?.vid == vo.vid) && (nil == vo.display) {
                iparr.append(IndexPath(index: 0).appending(n))
            }
            n += 1
        }
        // n.b. we hardcode number of sections in a tracker tableview here
        if isViewLoaded && view.window != nil {
            if let iparr = iparr as? [IndexPath] {
                tableView!.reloadRows(at: iparr, with: .none)
            }
        }

    }

    // handle rtTrackerUpdatedNotification
    @objc func updateUTC(_ notification: Notification?) {
        DBGLog(String("UTC update notification from tracker \((notification?.object as? trackerObj)?.trackerName)"))
        var vo: valueObj?
        if let obj = notification?.object, type(of: obj) == valueObj.self {
            vo = obj as? valueObj
            DBGLog(String("updated vo \(vo?.valueName)"))
        }
        updateTableCells(vo)
        needSave = true
        showSaveBtn()
        tracker?.saveTempTrackerData()
        // delete on save or cancel button
        // load if present in viewdidload [?]
        // delete all on program start [?]
    }
/*
    override func loadView() {
        // Ensure that we don't load an .xib file for this viewcontroller
        view = UIView()
    }
*/
    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {

        super.viewDidLoad()

        //DBGLog(@"utc: viewDidLoad dpvc=%d", (self.dpvc == nil ? 0 : 1));
        fwdRotations = true
        needSave = false

        //for (valueObj *vo in self.tracker.valObjTable) {
        //	[vo display];
        //}

        keyboardIsShown = false

        // navigationbar setup
        let backButton = UIBarButtonItem(
            title: String("< \(rvcTitle!)") /*@"< rTracker"  // rTracker ... tracks ? */,
            style: .plain,
            target: self,
            action: #selector(addTrackerController.btnCancel))
        navigationItem.leftBarButtonItem = backButton

        // toolbar setup
        updateToolBar()

        // title setup
        title = tracker!.trackerName

        // tableview setup
        //UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[rTracker_resource getLaunchImageName]]];
        let bg = UIImageView(image: rTracker_resource.get_background_image(self))

        //CGRect statusBarFrame = [self.navigationController.view.window convertRect:UIApplication.sharedApplication.statusBarFrame toView:self.navigationController.view];
        //CGFloat statusBarHeight = statusBarFrame.size.height;

        /*
        var tableFrame = bg.frame
        tableFrame.size.height = rTracker_resource.getVisibleSize(of:self).height //- ( 2 * statusBarHeight ) ;


        DBGLog(String("tvf \(tableFrame)"))  // origin x %f y %f size w %f h %f", tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height)
        tableView = UITableView(frame: tableFrame, style: .plain) // because getLaunchImageName worked out size! //self.saveFrame
         */
        // Create a new UITableView instance
        tableView = UITableView(frame: .zero, style: .plain)
        
        // Set tableView's translatesAutoresizingMaskIntoConstraints property to false
        // This allows us to add our own constraints to the tableView
        tableView!.translatesAutoresizingMaskIntoConstraints = false

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

        swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)

        /*
             * cannot seem to work alongside tableview swipe
             *
            swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewSwipeUp:)];
            [swipe setDirection:UISwipeGestureRecognizerDirectionUp];
            [self.view addGestureRecognizer:swipe];
            */

        tracker!.vc = self
        alertResponse = 0
        saveTargD = 0

        //load temp tracker data here if available
        if tracker!.loadTempTrackerData() {
            needSave = true
            showSaveBtn()
        }

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView!.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }

    /*
    - (void)viewDidUnload {
    	// Release any retained subviews of the main view.
    	// e.g. self.myOutlet = nil;

        DBGLog(@"utc unload %@",self.tracker.trackerName);

    	UIView *haveView = [self.view viewWithTag:kViewTag2];
    	if (haveView) 
    		[haveView removeFromSuperview];
    	self.dpvc = nil;
        self.dpr = nil;
    	self.table = nil;

    	self.title = nil;
    	self.prevDateBtn = nil;
    	self.currDateBtn = nil;
    	self.postDateBtn = nil;
    	self.delBtn = nil;
    	self.calBtn = nil;

    	self.fixed1SpaceButtonItem = nil;
    	self.flexibleSpaceButtonItem = nil;

    	self.toolbarItems = nil;
    	self.navigationItem.rightBarButtonItem = nil;	
    	self.navigationItem.leftBarButtonItem = nil;

    	self.dpr.action = DPA_CANCEL;

    	self.tracker.vc = nil;

    	[super viewDidUnload];
    }
    */

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

        //DBGLog(@"utc: view will appear");

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
                    //[self updateTrackerTableView];  // moved below
                    tracker!.trackerDate = Date(timeIntervalSince1970: TimeInterval(tracker!.noCollideDate(Int(dpr.date!.timeIntervalSince1970))))
                    //[self updateToolBar];
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
                    setTrackerDate(targD)
                case DPA_GOTO_POST /* for TimesSquare calendar which gives date with time=midnight (= beginning of day) */:
                    var targD = 0
                    if nil != dpr.date {
                        // set to nil to cause reset tracker, ready for new
                        targD = Int(dpr.date?.timeIntervalSince1970 ?? 0)
                        if !tracker!.loadData(targD) {
                            tracker!.trackerDate = dpr.date
                            targD = tracker!.postDate()
                            if targD == 0 {
                                targD = 0 // if no post date, must mean today so new tracker
                            }
                            //targD = [self.tracker prevDate];
                        }
                    }
                    setTrackerDate(targD)
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
            updateTrackerTableView() // need to force redisplay and set sliders, so reload in viewdidappear not so noticeable

            navigationController?.toolbar.backgroundColor = .tertiarySystemBackground
            navigationController?.navigationBar.backgroundColor = .tertiarySystemBackground
            navigationController?.setToolbarHidden(false, animated: false)

            updateToolBar()

        }

        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {

        //DBGLog(@"utc view did appear!");
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
        //[self updateTrackerTableView];  // need for ios5 after set date in graph and return
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

    override func viewWillDisappear(_ animated: Bool) {
        viewDisappearing = true
        /*
         if (self.needSave) {
                self.alertResponse=CSCANCEL;
                [self alertChkSave];
            }
         */

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

        /* 
             // failed effort to use default back button
            if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
                // back button was pressed.  We know this is true because self is no longer
                // in the navigation stack.
            }
             */

        super.viewWillDisappear(animated)
    }

    /*
     // failed effort to use default back button
     - (void)willMoveToParentViewController:(UIViewController *)parent {
         if (parent == nil) {
             DBGLog(@"will move to parent view controller");
             if (self.needSave) {
                 self.alertResponse=CSLEAVE;
                 [self alertLeaving];
                 return; // don't disappear yet...
             } else {
                 [self leaveTracker];
             }

         }
    }
    */

    func rejectTracker() {
        DBGLog(String("rejecting input tracker \(tracker!.toid) \(tracker!.trackerName)  prevTID= \(tracker!.prevTID)"))
        // RootViewController:loadTrackerDict() sets prevTID to -1 if this is new = no name or existing tid match (rejectable tracker)
        // also loadTrackerDict sets tid to -1 in error condition but never checked
        tlist!.updateTLtid(Int(tracker!.toid), new: tracker!.prevTID) // revert topLevel to before
        tracker!.deleteTrackerDB()
        rTracker_resource.unStashTracker(tracker!.prevTID) // this view and tracker going away now so dont need to clear rejectable or prevTID
    }

    override func didMove(toParent parent: UIViewController?) {
        if rejectable && viewDisappearing {
            rejectTracker()
        }
    }

    // MARK: view rotation methods
    /*
     // Override to allow orientations other than the default portrait orientation.
    - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

        // only for pre ios 6.0

        // Return YES for supported orientations
    	switch (interfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"utc should rotate to interface orientation portrait?");
    			break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"utc should rotate to interface orientation portrait upside down?");
    			break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"utc should rotate to interface orientation landscape left?");

                if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") ) {//if 5
                    [self doGT];
                }

    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"utc should rotate to interface orientation landscape right?");

                if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0") ) { //if 5
                    [self doGT];
                }

    			break;
    		default:
    			DBGWarn(@"utc rotation query but can't tell to where?");
    			break;			
    	}

        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown );
    }
    */
    /*
    - (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    	switch (fromInterfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"utc did rotate from interface orientation portrait");

                //if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") ) {
                    [self doGT];
                //}

    			break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"utc did rotate from interface orientation portrait upside down");
                [self doGT];
    			break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"utc did rotate from interface orientation landscape left");
    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"utc did rotate from interface orientation landscape right");
    			break;
    		default:
    			DBGWarn(@"utc did rotate but can't tell from where");
    			break;			
    	}
    }
    */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if isViewLoaded && view.window != nil {

            coordinator.animate(alongsideTransition: { context in
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let orientation = windowScene!.interfaceOrientation
                /*
                //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                let firstWindow = UIApplication.shared.windows.first
                let windowScene = firstWindow?.windowScene
                let orientation = windowScene?.interfaceOrientation
                */
                
                // do whatever  -- willRotateTo

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
                /*
                //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                let firstWindow = UIApplication.shared.windows.first
                let windowScene = firstWindow?.windowScene
                let orientation = windowScene?.interfaceOrientation
                 */
                // do whatever -- didRotateTo
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
        }

        super.viewWillTransition(to: size, with: coordinator)

    }

    func doGT() {
        DBGLog("start present graph")

        var gt: graphTrackerVC?
        gt = graphTrackerVC()
        gt?.modalPresentationStyle = .fullScreen // need for iPad, this is default for 'horizontally compact environment'

        gt?.tracker = tracker
        if tracker!.hasData() {
            dpr.date = tracker!.trackerDate
            dpr.action = DPA_GOTO
        }
        gt?.dpr = dpr
        gt?.parentUTC = self

        self.gt = gt

        //gt.modalPresentationStyle = UIModalPresentationFullScreen;
        //self.modalPresentationStyle = UIModalPresentationFullScreen;

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

    /*

    - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    	switch (interfaceOrientation) {
    		case UIInterfaceOrientationPortrait:
    			DBGLog(@"utc will animate rotation to interface orientation portrait duration: %f sec",duration);
    			break;
    		case UIInterfaceOrientationPortraitUpsideDown:
    			DBGLog(@"utc will animate rotation to interface orientation portrait upside down duration: %f sec", duration);
    			break;
    		case UIInterfaceOrientationLandscapeLeft:
    			DBGLog(@"utc will animate rotation to interface orientation landscape left duration: %f sec", duration);

                if ( SYSTEM_VERSION_LESS_THAN(@"5.0") ) {// if not 5
                    [self doGT];
                }

    			break;
    		case UIInterfaceOrientationLandscapeRight:
    			DBGLog(@"utc will animate rotation to interface orientation landscape right duration: %f sec", duration);

                if ( SYSTEM_VERSION_LESS_THAN(@"5.0") ) { // if not 5
                    [self doGT];
                }

    			break;
    		default:
    			DBGWarn(@"utc will animate rotation but can't tell to where. duration: %f sec", duration);
    			break;			
    	}
    }
    */


    // MARK: -
    // MARK: keyboard notifications

    /*
    - (void)textFieldDidBeginEditing:(UITextField *)textField
    {
    	DBGLog(@"utc: tf begin editing");
    }

    - (void)textFieldDidEndEditing:(UITextField *)textField
    {
    	DBGLog(@"utc: tf end editing");
    }

    //UITextField *activeField;
    */

    @objc func keyboardWillShow(_ n: Notification?) {
        if let sv = tracker?.activeControl?.superview {
            // can get here after closing voTextBox with nil activeControl
            rTracker_resource.willShowKeyboard(n, vwTarg:sv, vwScroll: view)  // superview is table cell holding active control
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
    //- (void)testAction:(id)sender {
    //	DBGLog(@"test button pressed");
    /*
     *  fn= period[full tank]:(delta[odometer]/postSum[fuel])
     *
     *  keywords
     *      period(x)	x= non-null vo | time interval string : define begin,end timestamps; default if not spec'd is each pair of dates
     *			-> gen array T0[] and array T1[]
     *		delta(x)	x= non-null vo : return vo(time1) - vo(time0)
     *			-> ('select val where id=%id and date=%t1' | vo.value) - 'select val where id=%id and date=%t0'
     *		postsum(x)	x= vo : return sum of vo(>time0)...vo(=time1)
     *			-> 'select val where id=%id and date > %t0 and date <= %t1' ... sum
     *		presum(x)	x= vo : return sum of vo(=time0)...vo(<time1)
     *			-> 'select val where id=%id and date >= %t0 and date < %t1' ... sum
     *		sum(x)		x= vo : return sum of vo(=time0)...vo(=time1)
     *			-> 'select val where id=%id and date >= %t0 and date <= %t1' ... sum
     *		avg(x)      x= vo : return avg of vo(=time0)...vo(=time1)
     *			-> 'select val where id=%id and date > %t0 and date <= %t1' ... avg
     *		
     * -> vo => convert to vid
     * -> separately define period: none | event pair | event + (plus,minus,centered) time interval 
     *                            : event = vo not null or hour / week day / month day
     *
     * ... can't do plus/minus/centered, value will be plotted on T1
     */
    //NSString *myfn = @"period[full tank]:(delta[odometer]/postSum[fuel])";
    //	
    //}

    /*
     - (UIBarButtonItem*)testBtn {
     if (testBtn == nil) {
     testBtn = [[UIBarButtonItem alloc]
     initWithTitle:@"test"
     style:UIBarButtonItemStylePlain
     target:self
     action:@selector(testAction:)];
     }

     return testBtn;

     }
     */

    var _saveBtn: UIBarButtonItem?
    var saveBtn: UIBarButtonItem {
        if _saveBtn == nil {
            _saveBtn = UIBarButtonItem(
                barButtonSystemItem: .save,
                target: self,
                action: #selector(addTrackerController.btnSave))
        }
        return _saveBtn!
    }

    var _menuBtn: UIBarButtonItem?
    var menuBtn: UIBarButtonItem {
        if _menuBtn == nil {
            if rejectable {
                _menuBtn = UIBarButtonItem(
                    title: "Accept",
                    style: .plain,
                    target: self,
                    action: #selector(btnAccept))
                _menuBtn!.tintColor = .green
            } else {
                _menuBtn = UIBarButtonItem(
                    barButtonSystemItem: .action,
                    target: self,
                    action: #selector(btnMenu))
            }
        }

        return _menuBtn!
    }

    // MARK: -
    // MARK: datepicker support

    func clearVoDisplay() {
        for vo in tracker!.valObjTable {
            //if (vo.vtype == VOT_FUNC)
            vo.display = nil // always redisplay
        }

    }

    func updateTrackerTableView() {
        // see related updateTableCells above
        //DBGLog(@"utc: updateTrackerTableView");
        DispatchQueue.main.async(execute: { [self] in

            for vo in tracker!.valObjTable {
                //if (vo.vtype == VOT_FUNC)
                vo.display = nil // always redisplay
            }

            tableView!.reloadData()
        })

        //[(UITableView *) self.view reloadData];
        //	[self.tableView reloadData];  // if we were a uitableviewcontroller not uiviewcontroller
    }

    func updateToolBar() {
        //[self setToolbarItems:nil animated:YES];

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
        } else {
            tbi.append(fixed1SpaceButtonItem)
        }

        //[tbi addObject:[self testBtn]];

        setToolbarItems(tbi as? [UIBarButtonItem], animated: true)
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
                setTrackerDate(tsdate)
            } else if CSCANCEL == alertResponse {
                alertResponse = 0
                btnCancel()
                //[self dealloc];
            } else if CSSHOWCAL == alertResponse {
                alertResponse = 0
                btnCal()
                /*
                             // failed effort to use default back button
                             } else if (CSLEAVE==self.alertResponse) {
                             [self leaveTracker];
                             //[super viewWillDisappear:YES];
                             */
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
            setTrackerDate(targD)
        }
    }

    func duplicateEntry() {
        tracker!.trackerDate = Date()
        needSave = true

        showSaveBtn()

        // write temp tracker here
        tracker!.saveTempTrackerData()
        updateToolBar()
        updateTrackerTableView()

        //[[NSNotificationCenter defaultCenter] postNotificationName:rtTrackerUpdatedNotification object:self]; // not sure why this doesn't work here....


    }

    @IBAction func iTunesExport() {

        DBGLog("exporting tracker:")
        #if DEBUGLOG
        tracker!.describe()
        #endif
        //[rTracker_resource startProgressBar:self.view navItem:self.navigationItem disable:YES];
        let navframe = navigationController?.navigationBar.frame
        rTracker_resource.startProgressBar(view, navItem: navigationItem, disable: true, yloc: (navframe?.size.height ?? 0.0) + (navframe?.origin.y ?? 0.0))
        //[rTracker_resource startProgressBar:self.navigationController.view navItem:self.navigationItem disable:YES];
        Thread.detachNewThreadSelector(#selector(doPlistExport), toTarget: self, with: nil)
    }

    func handleExportTracker(_ buttonTitle: String?) {

        if emCancel == buttonTitle {
            DBGLog("cancelled")
        } else if emItunesExport == buttonTitle {
            iTunesExport()
        } else if emDuplicate == buttonTitle {
            duplicateEntry()
        } else {
            openMail(buttonTitle)
        }

    }

    /*
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        if ([alertView.title hasSuffix:@"modified"]) {          // tracker modified and trying to leave without save
            [self dispatchHandleModifiedTracker:buttonIndex];
        } else if ([alertView.title hasPrefix:@"Really"]) {     // pessed delete button for entry
            [self handleDeleteEntry:buttonIndex];
        }else {                                                 // export menu
            [self handleExportTracker:[alertView buttonTitleAtIndex:buttonIndex]];
        }
    }
     */
    /*
    xxx stuck here - how to get back to setTrackerDate or btnCancel ?

    save targD somewhere
    if targd exists then do settrackerdate
    else do btnCancel/btnSave
    */

    func alertChkSave() {
        let title = tracker!.trackerName! + " modified" // 'modified' needed by handler
        let msg = "Save this record before leaving?"
        let btn0 = "Cancel"
        let btn1 = "Save"
        let btn2 = "Discard"

        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: btn0, style: .default, handler: { [self] action in
            dispatchHandleModifiedTracker(0)
        })
        let saveAction = UIAlertAction(title: btn1, style: .default, handler: { [self] action in
            dispatchHandleModifiedTracker(1)
        })
        let discardAction = UIAlertAction(title: btn2, style: .default, handler: { [self] action in
            dispatchHandleModifiedTracker(2)
        })

        alert.addAction(saveAction)
        alert.addAction(discardAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    /*
     // failed effort to use default back button
    - (void) alertLeaving {

        UIAlertView *alert;
        alert = [[UIAlertView alloc]
                 initWithTitle:[self.tracker.trackerName stringByAppendingString:@" modified"]
                 message:@"Save this record before leaving?"
                 delegate:self
                 cancelButtonTitle:@"Discard"
                 otherButtonTitles: @"Save",nil];

        [alert show];

    }
    */

    func setTrackerDate(_ targD: Int) {

        if needSave {
            alertResponse = CSSETDATE
            saveTargD = targD
            alertChkSave()
            return
        }

        if targD == 0 {
            DBGLog(String(" setTrackerDate: \(targD) = reset to now"))
            tracker!.resetData()
        } else if targD < 0 {
            DBGLog(String("setTrackerDate: \(targD) = no earlier date"))
        } else {
            DBGLog(String(" setTrackerDate: \(targD) = \(Date(timeIntervalSince1970: TimeInterval(targD)))"))
            _ = tracker!.loadData(targD)
        }
        needSave = false // dumping anything not saved by going to another date.
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
            tracker!.setReminders() // saved data may change reminder action so wipe and set again
            didSave = false
        } else {
            tracker!.confirmReminders() // else just confirm any enabled reminders have one scheduled
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
            showSaveBtn() // also don't clear form as below
            return
        }

        if tracker!.optDict["savertn"] as? String ?? "1" == "0" {
            // default:1
            // do not return to tracker list after save, so generate clear form
            //if !(toolbarItems?.contains(postDateBtn) ?? false) {
            tracker!.resetData()
            //}
            updateToolBar()
            updateTrackerTableView()
            needSave = false
            showSaveBtn()
        } else {
            leaveTracker()
            // added here after removing from leaveTracker
            // but FAILED
            // [self.navigationController popViewControllerAnimated:YES];
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
            //DBGLog(@"start export");

            _ = tracker!.saveToItunes()
            safeDispatchSync({ [self] in
                rTracker_resource.finishProgressBar(view, navItem: navigationItem, disable: true)
            })
            rTracker_resource.alert("Tracker saved", msg: "\(tracker!.trackerName ?? "")_out.csv and _out.plist files have been saved to the rTracker Documents directory on this device.  Access them through iTunes on your PC/Mac, or with a program like iExplorer from Macroplant.com.  Import by changing the names to _in.csv and _in.plist, and read about .rtcsv file import capabilities in the help pages.", vc: self)
        }
    }

    @IBAction func btnMenu() {

        //int prevD = (int)[self.tracker prevDate];
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

        let title = "\(tracker!.trackerName ?? "") tracker"
        let msg: String? = nil
        // NSString *btn5 = (postD != 0 || (lastD == currD)) ? emDuplicate : nil;

        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)

        let ecsvAction = UIAlertAction(title: emEmailCsv, style: .default, handler: { [self] action in
            handleExportTracker(emEmailCsv)
        })
        let etAction = UIAlertAction(title: emEmailTracker, style: .default, handler: { [self] action in
            handleExportTracker(emEmailTracker)
        })
        let etdAction = UIAlertAction(title: emEmailTrackerData, style: .default, handler: { [self] action in
            handleExportTracker(emEmailTrackerData)
        })
        let iteAction = UIAlertAction(title: emItunesExport, style: .default, handler: { [self] action in
            handleExportTracker(emItunesExport)
        })
        let cancelAction = UIAlertAction(title: emCancel, style: .default, handler: { [self] action in
            handleExportTracker(emCancel)
        })
        if MFMailComposeViewController.canSendMail() {
            alert.addAction(ecsvAction)
            alert.addAction(etAction)
            alert.addAction(etdAction)
        }
        alert.addAction(iteAction)
        if postD != 0 || (lastD == currD) {
            let dupAction = UIAlertAction(title: emDuplicate, style: .default, handler: { [self] action in
                handleExportTracker(emDuplicate)
            })
            alert.addAction(dupAction)
        }
        alert.addAction(cancelAction)

        present(alert, animated: true)




    }

    func privAlert(_ tpriv: Int, vpm: Int) {
        var msg: String?
        if vpm > tpriv {
            if tpriv > PRIVDFLT {
                msg = String(format: "Set a privacy level greater than %ld to see the %@ tracker, and greater than %ld to see all items in it", tpriv, tracker!.trackerName ?? "", vpm)
            } else {
                msg = String(format: "Set a privacy level greater than %ld to see all items in the %@ tracker", vpm, tracker!.trackerName ?? "")
            }
        } else {
            msg = String(format: "Set a privacy level greater than %ld to see the %@ tracker", tpriv, tracker!.trackerName ?? "")
        }
        rTracker_resource.alert("Privacy alert", msg: msg, vc: self)
    }

    func checkPrivWarn() {
        let tpriv = Int(tracker!.optDict["privacy"] as? String ?? "1") ?? 1
        var vprivmax = PRIVDFLT

        for vo in tracker!.valObjTable {
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
        setTrackerDate(targD)

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
        setTrackerDate(targD)
        if targD > 0 {
            tableView!.reloadData()
        }

    }

    @objc func btnSkip2End() {
        setTrackerDate(0)
    }

    @objc func btnCurrDate() {
        //DBGLog(@"pressed date becuz its a button, should pop up a date picker....");

        dpvc.myTitle = "Date for \(tracker!.trackerName ?? "")"
        dpr.date = tracker!.trackerDate
        dpvc.dpr = dpr

        //CGRect f = self.view.frame;

        dpvc.modalTransitionStyle = .coverVertical
        dpvc.presentationController?.delegate = self // need for ios 13 to access viewWillAppear as presentationControllerDidDismiss not firing
        present(dpvc, animated: true)
    }

    @objc func btnDel() {
        let title = "Delete entry"
        let msg = "Really delete \(tracker!.trackerName ?? "") entry \(tracker!.trackerDate?.description(with: NSLocale.current) ?? "")?"
        let btn0 = "Cancel"
        let btn1 = "Yes, delete"

        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: btn0, style: .default, handler: { [self] action in
            handleDeleteEntry(0)
        })
        let deleteAction = UIAlertAction(title: btn1, style: .default, handler: { [self] action in
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
        tsCalVC.presentationController?.delegate = self // need for ios 13 to access viewWillAppear as presentationControllerDidDismiss not firing

        tsCalVC.modalTransitionStyle = .coverVertical

        present(tsCalVC, animated: true)
    }

    // MARK: -
    // MARK: UIBar button getters
    /*

    - (UIBarButtonItem *) prevDateBtn {
    	if (_prevDateBtn == nil) {
    		_prevDateBtn = [[UIBarButtonItem alloc]
    					   initWithTitle:@"<-" // @"Prev"    // @"<"
    					   style:UIBarButtonItemStylePlain
    					   target:self
    					   action:@selector(btnPrevDate)];
            _prevDateBtn.tintColor = [UIColor darkGrayColor];
    	}
    	return _prevDateBtn;
    }

    - (UIBarButtonItem *) postDateBtn {
    	if (_postDateBtn == nil) {
    		_postDateBtn = [[UIBarButtonItem alloc]
    					   initWithTitle:@"->" // @"Next"    //@">"
    					   style:UIBarButtonItemStylePlain
    					   target:self
    					   action:@selector(btnPostDate)];
            _postDateBtn.tintColor = [UIColor darkGrayColor];
    	}

    	return _postDateBtn;
    }

    */

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
            _currDateBtn = UIBarButtonItem(
                title: datestr,
                style: .plain,
                target: self,
                action: #selector(btnCurrDate))
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
            _calBtn = UIBarButtonItem(
                title: "📆" /* @"\u2630" //@"Cal" */,
                style: .plain,
                target: self,
                action: #selector(btnCal))
            _calBtn!.tintColor = UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
            //_calBtn.tintColor = [UIColor greenColor];
            _calBtn!.setTitleTextAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 28.0)
                //,NSForegroundColorAttributeName: [UIColor greenColor]
                ],
                for: .normal)
        }

        return _calBtn!
    }

    var _searchBtn: UIBarButtonItem?
    var searchBtn: UIBarButtonItem {
        if _searchBtn == nil {
            _searchBtn = UIBarButtonItem(
                title: "🔍" /*@"Cal" */,
                style: .plain,
                target: self,
                action: #selector(btnSearch))
            _searchBtn!.tintColor = UIColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0)
            //_searchBtn.tintColor = [UIColor greenColor];
            _searchBtn!.setTitleTextAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 28.0)
                //,NSForegroundColorAttributeName: [UIColor greenColor]
                ],
                for: .normal)
        }

        return _searchBtn!
    }

    @objc func btnSearch() {
        rTracker_resource.alert("Search results", msg: String(format: "%ld entries highlighted in calendar and graph views, or swipe right/left", Int(searchSet!.count)), vc: self)
    }

    var _delBtn: UIBarButtonItem?
    var delBtn: UIBarButtonItem {
        if _delBtn == nil {
            _delBtn = UIBarButtonItem(
                barButtonSystemItem: .trash,
                target: self,
                action: #selector(btnDel))
            _delBtn!.tintColor = .red
            //[_delBtn setTitleTextAttributes:@{
            //                                 NSFontAttributeName: [UIFont systemFontOfSize:28.0]
            //                                 ,NSForegroundColorAttributeName: [UIColor redColor]
            //                                 } forState:UIControlStateNormal];
        }

        return _delBtn!
    }

    var _skip2EndBtn: UIBarButtonItem?
    var skip2EndBtn: UIBarButtonItem {
        if _skip2EndBtn == nil {
            _skip2EndBtn = UIBarButtonItem(
                barButtonSystemItem: .fastForward,
                target: self,
                action: #selector(btnSkip2End))
            //_calBtn.tintColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0];
            //_calBtn.tintColor = [UIColor greenColor];
            //[_calBtn setTitleTextAttributes:@{
            //                                  NSFontAttributeName: [UIFont systemFontOfSize:28.0]
            //                                  ,NSForegroundColorAttributeName: [UIColor blueColor]
            //                                  } forState:UIControlStateNormal];
        }

        return _skip2EndBtn!
    }

    // MARK: -
    // MARK: mail support

    func attachTrackerData(_ mailer: MFMailComposeViewController?, key: String?) -> Bool {
        var result: Bool
        var fp = tracker!.getPath(RTRKext)
        var mimetype = "application/rTracker"
        var fname = (tracker!.trackerName ?? "") + RTRKext

        if key == emEmailCsv {
            result = tracker!.writeCSV()
            if result {
                fp = tracker!.getPath(CSVext)
                mimetype = "text/csv"
                fname = (tracker!.trackerName ?? "") + CSVext
            }
        } else if key == emEmailTrackerData {
            result = tracker!.writeRtrk(true)
        } else if key == emEmailTracker {
            result = tracker!.writeRtrk(false)
        } else {
            DBGLog(String("no match for key \(key)"))
            result = false
        }

        if result {
            var fileData: Data? = nil
            do {
                fileData = try NSData(contentsOfFile: fp ?? "", options: .uncached) as Data?
            } catch {
            }
            if nil != fileData {
                if let fileData {
                    mailer?.addAttachmentData(fileData, mimeType: mimetype, fileName: fname)
                }
            } else {
                result = false
            }
        }

        return result
    }

    func openMail(_ btnTitle: String?) {

        let mailer = MFMailComposeViewController()
        mailer.mailComposeDelegate = self
        if tracker!.optDict["dfltEmail"] != nil {
            let toRecipients = [(tracker!.optDict)["dfltEmail"]]
            mailer.setToRecipients(toRecipients.compactMap { $0 } as? [String])
        }
        var emailBody: String?
        var ext: String?

        if emEmailCsv == btnTitle {
            if rTracker_resource.getRtcsvOutput() {
                emailBody = (tracker!.trackerName ?? "") + " tracker data file in rtCSV format attached.  Generated by <a href=\"http://rob-miller.github.io/rTracker/rTracker/iPhone/pages/rTracker-main.html\">rTracker</a>."
            } else {
                emailBody = (tracker!.trackerName ?? "") + " tracker data file in CSV format attached.  Generated by <a href=\"http://rob-miller.github.io/rTracker/rTracker/iPhone/pages/rTracker-main.html\">rTracker</a>."
            }
            mailer.setSubject((tracker!.trackerName ?? "") + " tracker CSV data")
            ext = CSVext
        } else {
            if emEmailTrackerData == btnTitle {
                emailBody = (tracker!.trackerName ?? "") + " tracker with data attached.  Open with <a href=\"http://rob-miller.github.io/rTracker/rTracker/iPhone/pages/rTracker-main.html\">rTracker</a>."
                mailer.setSubject((tracker!.trackerName ?? "") + " tracker with data")
            } else {
                emailBody = (tracker!.trackerName ?? "") + " tracker attached.  Open with <a href=\"http://rob-miller.github.io/rTracker/rTracker/iPhone/pages/rTracker-main.html\">rTracker</a>."
                mailer.setSubject((tracker!.trackerName ?? "") + " tracker")
            }
            ext = RTRKext
        }

        mailer.setMessageBody(emailBody ?? "", isHTML: true)
        if attachTrackerData(mailer, key: btnTitle) {
            present(mailer, animated: true)
            //[self presentModalViewController:mailer animated:YES];
        }
        #if RELEASE
        _ = rTracker_resource.deleteFile(atPath: tracker!.getPath(ext))
        #else
        DBGErr(String("leaving rtrk at path: (tracker.getPath(ext))"))
        #endif

    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            DBGLog("Mail cancelled: you cancelled the operation and no email message was queued.")
        case .saved:
            DBGLog("Mail saved: you saved the email message in the drafts folder.")
        case .sent:
            DBGLog("Mail send: the email message is queued in the outbox. It is ready to send.")
        case .failed:
            DBGLog("Mail failed: the email message was not saved or queued, possibly due to an error.")
        default:
            DBGLog("Mail not sent.")
        }
        // Remove the mail view
        dismiss(animated: true)
        // some say this way but don't think so: [controller dismissViewControllerAnimated:YES completion:NULL ];
        //[self dismissModalViewControllerAnimated:YES];
    }

    // MARK: -
    // MARK: Table view methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Customize the number of rows in the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return 0;  //[rTrackerAppDelegate.topLayoutTable count];
        return tracker!.valObjTable.count
    }

    //#define MARGIN 7.0f

    let CHECKBOX_WIDTH = 40.0


    // Customize the appearance of table view cells.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let vo = (tracker!.valObjTable)[row]
        //DBGLog(@"uvc table cell at index %d label %@",row,vo.valueName);

        return (vo.vos?.voTVCell(tableView))!
        /*
            UITableViewCell *tvc = [vo.vos voTVCell:tableView];
            UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bkgnd-cell1-320-56.png"]];
            [tvc setBackgroundView:bg];
            [bg release];

            return tvc;
             */
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let vo = (tracker!.valObjTable)[row]
        return vo.vos?.voTVCellHeight() ?? 0.0
        /*
        	NSInteger vt = ((valueObj*) (self.tracker.valObjTable)[[indexPath row]]).vtype;
        	if ( vt == VOT_CHOICE || vt == VOT_SLIDER )
        		return CELL_HEIGHT_TALL;
        	return CELL_HEIGHT_NORMAL;
             */
    }

    // Override to support row selection in the table view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Navigation logic may go here -- for example, create and push another view controller.
        // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
        // [self.navigationController pushViewController:anotherViewController animated:YES];
        // [anotherViewController release];

        let vo = (tracker!.valObjTable)[indexPath.row]

        #if DEBUGLOG
        let row = indexPath.row
        //valueObj *vo = (valueObj *) [self.tracker.valObjTable  objectAtIndex:row];
        DBGLog(String("selected row \(UInt(row)): \(vo.valueName)"))
        #endif

        if VOT_INFO == vo.vtype {
            if var url = (vo.optDict["infourl"])?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !url.isEmpty {
                if !url.contains("://") {
                    url = "http://" + url
                }
                DBGLog("vot_info: selected -> fire url: \(url)")
                UIApplication.shared.open(URL(string: url)!, options: [:]) { success in
                    if !success {
                        if url.localizedCaseInsensitiveContains("http://") || url.localizedCaseInsensitiveContains("https://") {
                            rTracker_resource.alert("Failed to open URL", msg: "Failed to open the URL \(url) - network problem?", vc: self)
                        } else {
                            rTracker_resource.alert("Failed to open URL", msg: "Failed to open the URL \(url) - perhaps the supporting app is not installed??", vc: self)
                        }
                    }
                }
            }

        }






    }
}

// UIAdaptivePresentationControllerDelegate added so dpvc.presentationController.delegate can be set to trigger viewWillAppear for ios13 - hacky.

/*
 {
	trackerObj *tracker;
	datePickerVC *dpvc;
    dpRslt *dpr;
	CGRect saveFrame;
    BOOL needSave;
    BOOL didSave;
    BOOL fwdRotations;
    BOOL rejectable;
    BOOL viewDisappearing;
    trackerList *tlist;
    int alertResponse;
    int saveTargD;

    trackerCalViewController *tsCalVC;
}
*/

let CSCANCEL = 1
let CSSETDATE = 2
let CSSHOWCAL = 3
//#define CSLEAVE     4

//#import "trackerCalViewController.h"
