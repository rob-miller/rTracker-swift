//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// notifyReminderViewController.swift
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
//  notifyReminderViewController.swift
//  rTracker
//
//  Created by Rob Miller on 07/08/2013.
//  Copyright (c) 2013 Robert T. Miller. All rights reserved.
//

import UIKit

/*
 weekdays : 7 bits
 monthdays : 31 bits
 everyVal : int
 everyMode : int (5) (3-4 bits?)

 start : int (1440)
 until : int (1440)
 times : int

 bools:
 fromLast
 until
 interval/random

 message : nsstring

 sound : alert/banner : badge  -- can only be alert/banner; badge is for all pending rTracker notifications, sound to be done but just one

 enable / disable toggle ?

 */

class notifyReminderViewController: UIViewController, UITextFieldDelegate {
    var weekdays = [Int](repeating: 0, count: 7)
    /*
        trackerObj *tracker;
        notifyReminder *nr;
        //BOOL tmpReminder;         // nr.rid=0 // displayed reminder is only in view controller, no entry in tracker.reminders

        NSArray *weekdayBtns;
        NSArray *everyTrackerNames;
        UIImage *chkImg;
        UIImage *unchkImg;
        NSUInteger firstWeekDay;
        NSUInteger everyTrackerNdx;
        uint8_t everyMode;
        NSString *lastDefaultMsg;
        BOOL delayDaysState;
    */
    var tracker: trackerObj?
    var nr: notifyReminder?
    //@property (nonatomic) BOOL tmpReminder;

    private var _weekdayBtns: [AnyHashable]?
    var weekdayBtns: [AnyHashable]? {
        if nil == _weekdayBtns {
            _weekdayBtns = [
                wdButton1,
                wdButton2,
                wdButton3,
                wdButton4,
                wdButton5,
                wdButton6,
                wdButton7
            ]
        }
        return _weekdayBtns
    }

    private var _everyTrackerNames: [String]?
    var everyTrackerNames: [String] {
        if nil == _everyTrackerNames {
            _everyTrackerNames = []
            _everyTrackerNames?.append(tracker!.trackerName!)
            for vo in tracker!.valObjTable{
                _everyTrackerNames!.append(vo.valueName!)
            }
        }
        return _everyTrackerNames!
    }
    var chkImg: UIImage?
    var unchkImg: UIImage?
    var lastDefaultMsg: String?
    var firstWeekDay = 0
    var everyTrackerNdx = 0
    var everyMode: UInt8 = 0
    var delayDaysState = false
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var prevBarButton: UIBarButtonItem!
    @IBOutlet var nextAddBarButton: UIBarButtonItem!
    @IBOutlet var msgTF: UITextField!
    @IBOutlet var enableButton: UIButton!
    @IBOutlet var delayDaysButton: UIButton!
    @IBOutlet var thenOnLabel: UILabel!
    @IBOutlet var wdButton1: UIButton!
    @IBOutlet var wdButton2: UIButton!
    @IBOutlet var wdButton3: UIButton!
    @IBOutlet var wdButton4: UIButton!
    @IBOutlet var wdButton5: UIButton!
    @IBOutlet var wdButton6: UIButton!
    @IBOutlet var wdButton7: UIButton!
    //@IBOutlet var monthDaysLabel: UILabel!
    @IBOutlet var monthDays: UITextField!
    @IBOutlet var everyTF: UITextField!
    @IBOutlet var everyButton: UIButton!
    @IBOutlet var fromLastButton: UIButton!
    @IBOutlet var fromLastLabel: UILabel!
    @IBOutlet var everyTrackerButton: UIButton!
    var activeField: UITextField? //just a pointer, no retain
    //@property (nonatomic,retain) IBOutlet UISegmentedControl *weekMonthEvery;
    //- (IBAction)weekMonthEveryChange:(id)sender;

    @IBOutlet var startHr: UITextField!
    @IBOutlet var startMin: UITextField!
    @IBOutlet var startSlider: UISlider!
    @IBOutlet var startTimeAmPm: UILabel!
    @IBOutlet var startLabel: UILabel!
    @IBOutlet var finishHr: UITextField!
    @IBOutlet var finishMin: UITextField!
    @IBOutlet var finishSlider: UISlider!
    @IBOutlet var finishTimeAmPm: UILabel!
    @IBOutlet var finishLabel: UILabel!
    @IBOutlet var finishColon: UILabel!
    @IBOutlet var repeatTimes: UITextField!
    @IBOutlet var repeatTimesLabel: UILabel!
    @IBOutlet var intervalButton: UIButton!
    @IBOutlet var enableFinishButton: UIButton!
    /*
    - (IBAction)finishSliderAction:(id)sender;
    - (IBAction)timesChange:(id)sender;
    - (IBAction) intervalBtn:(id)sender;
    */

    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var gearButton: UIBarButtonItem!
    @IBOutlet var btnDoneOutlet: UIBarButtonItem!
    @IBOutlet var btnHelpOutlet: UIBarButtonItem!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        //self.tmpReminder=TRUE;

        //self.title=@"hello";
        // Custom initialization
        // [self viewDidLoad];
    }

    // MARK: -

    override func viewDidLoad() {

        /*
            UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc]
        								initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        								target:self
        								action:@selector(btnDone:)];
            self.toolbarItems = [NSArray arrayWithObjects: doneBtn, nil];

        	[doneBtn release];
        */
        chkImg = UIImage(named: "checked.png")
        unchkImg = UIImage(named: "unchecked.png")

        rTracker_resource.initHasAmPm()
        if hasAmPm {
            startTimeAmPm.isHidden = false
            finishTimeAmPm.isHidden = false
            finishTimeAmPm.isEnabled = false
            finishHr.text = "11"
        }
        // set weekday buttons to reflect users calendar settings

        firstWeekDay = Calendar.current.firstWeekday
        //DBGLog(@"firstweekday= %d",self.firstWeekDay);

        let dateFormatter = DateFormatter()

        for i in 0..<7 {
            var wd = firstWeekDay + i
            if wd > 7 {
                wd -= 7
            }
            weekdays[i] = wd - 1 // firstWeekDay is 1-indexed, switch to 0-indexed

            ((weekdayBtns)?[i] as? UIButton)?.setTitle(dateFormatter.shortWeekdaySymbols[weekdays[i]], for: .normal)
            //DBGLog(@"i=%d wd=%d sdayName= %@",i,wd,[[dateFormatter shortWeekdaySymbols] objectAtIndex:(self->weekdays[i])]);
        }

        everyMode = UInt8(EV_HOURS)
        setEveryTrackerBtnName()

        msgTF.text = tracker?.trackerName
        lastDefaultMsg = msgTF.text

        if 0 < (tracker?.reminders.count ?? 0) {
            nr = tracker?.currReminder()
        } else {
            nr = tracker?.loadReminders()
        }

        setDelayDaysButtonTitle(false)
        doDelayDaysButtonState()

        guiFromNr()

        gearButton.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)
        btnHelpOutlet.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)

        btnDoneOutlet.title = "\u{2611}"
        btnDoneOutlet.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)


        nextAddBarButton.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)
        prevBarButton.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)


        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.setNeedsDisplay()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnDone(nil)
    }

    func leaveNR() -> Bool {
        if nullNRguiState() {
            if nr?.rid != nil {
                tracker?.deleteReminder()
                return true
            }
        } else {
            nrFromGui()
            tracker?.save(nr)
        }
        return false
    }

    @IBAction func btnDone(_ sender: Any?) {
        _ = leaveNR()
        dismiss(animated: true)
    }

    @IBAction func prevBtn(_ sender: Any) {
        DBGLog("prevBtn")
        let rslt = leaveNR()
        nr = (0 == nr?.rid) || rslt ? tracker?.currReminder() : tracker?.prevReminder()
        //self.nr = ( 0 == self.nr.rid && [self.tracker havePrevReminder] ? [self.tracker prevReminder] : [self.tracker currReminder]);
        guiFromNr()
    }

    @IBAction func nextAddBtn(_ sender: Any) {
        DBGLog("nextAddBtn")
        if leaveNR() {
            nr = tracker?.currReminder()
        } else {
            nr = tracker?.nextReminder()
        }
        guiFromNr()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {

        /*
             if (0 < [self.tracker.reminders count]) {
             //self.nextAddBarButton.title = @">";
             self.nr = [self.tracker.reminders objectAtIndex:0];
             } else {
             self.nr = [[notifyReminder alloc] init:self.tracker];
             }
             */
        //DBGLog(@" saveDate= %@",[NSDate dateWithTimeIntervalSince1970:self.nr.saveDate]);

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configTVObjVC.keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: view.window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configTVObjVC.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: view.window)

        navigationController?.setToolbarHidden(false, animated: false)

        super.viewWillAppear(animated)

    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        // unregister for keyboard notifications while not visible.
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        super.viewWillDisappear(animated)
    }

    // MARK: -

    func setDelayDaysButtonTitle(_ state: Bool) {
        delayDaysState = state
        if state {
            delayDaysButton.setTitle("Days of month:", for: .normal)
        } else {
            delayDaysButton.setTitle("Delay:", for: .normal)
        }
        DBGLog(String("state= \(state) titleIsDelay= \(ddbTitleIsDelay()) title= \(delayDaysButton.titleLabel?.text)"))
    }

    func ddbTitleIsDelay() -> Bool {
        return !delayDaysState
        // return ([@"Delay:" isEqualToString:[[self.delayDaysButton titleLabel] text]]);  // race condition immediately after set
    }

    func guiFromNr() {

        if nil == nr {
            nr = notifyReminder()
            nr!.msg = tracker!.trackerName
            nr!.tid = tracker!.toid
            nr!.fromLast = true // default to this as probably more common
            nr!.reminderEnabled = true // if nothing in database, enable by default -- nrFromGui will clear and read from gui setting
            //self.tmpReminder=TRUE;
        } else {
            //self.tmpReminder=FALSE;
        }
        DBGLog(String("\(nr)"))
        enableButton.isSelected = nr!.reminderEnabled
        updateCheckBtn(enableButton)
        msgTF.text = nr?.msg

        if nr!.start > -1 {
            enableStartControls(true)
            startSlider.value = Float(nr!.start)
            sliderUpdate(Int(startSlider.value), hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
        } else {
            enableStartControls(false)
        }

        if nr!.untilEnabled {
            enableFinishButton.isSelected = true
            finishSlider.value = Float(nr!.until)
            repeatTimes.text = String(format: "%ld", Int(nr?.times ?? 0))
            intervalButton.setTitle(nr?.timesRandom ?? false ? "random" : "interval", for: .normal)
            sliderUpdate(Int(finishSlider.value), hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
        } else {
            enableFinishButton.isSelected = false
        }
        updateCheckBtn(enableFinishButton)

        doEFbtnState()

        if nr!.monthDays != 0 {
            //self.weekMonthEvery.selectedSegmentIndex=SEGMONTH;
            setDelayDaysButtonTitle(true)
            var nma: [String] = [] // (repeating: nil, count: 32)
            for i in 0..<32 {
                if Int(nr?.monthDays ?? 0) & (0x01 << i) != 0 {
                    nma.append("\(i + 1)")
                }
            }
            monthDays.text = nma.joined(separator: ",")
            clearWeekDays()
            clearEvery()
        } else {
            // if (self.nr.everyVal) {
            //self.weekMonthEvery.selectedSegmentIndex=SEGEVERY;
            setDelayDaysButtonTitle(false)
            doDelayDaysButtonState()
            everyTF.text = String(format: "%ld", Int(nr!.everyVal))
            everyMode = nr!.everyMode
            everyBtnStateUpdate()
            if nr!.fromLast {
                fromLastButton.isSelected = true
                if nr!.vid != 0 {
                    let c = tracker?.valObjTable.count ?? 0
                    for i in 0..<c {
                        if nr!.vid == ((tracker!.valObjTable)[i]).vid {
                            everyTrackerNdx = i + 1
                        }
                    }
                } else {
                    everyTrackerNdx = 0
                }
            } else {
                fromLastButton.isSelected = false
            }
            updateCheckBtn(fromLastButton)

            setEveryTrackerBtnName()
            clearWeekDays()
            clearMonthDays()

            for i in 0..<7 {
                // added weekdays to every
                ((weekdayBtns)?[i] as? UIButton)?.isSelected = 0 != (Int(nr?.weekDays ?? 0) & (0x01 << weekdays[i]))
            }
        }
        /*
            } else {   // if (self.nr.weekDays)  = default if nothing set
                //self.weekMonthEvery.selectedSegmentIndex=SEGWEEK;
                for (i=0;i<7;i++) {
                    ((UIButton*)[self.weekdayBtns objectAtIndex:i]).selected = (BOOL) (0 != (self.nr.weekDays & (0x01 << self->weekdays[i])));
        / *
        #if DEBUGLOG
                    if (((UIButton*)[self.weekdayBtns objectAtIndex:i]).selected) {
                        DBGLog(@"weekday btn %d is selected",i);
                    } else {
                        DBGLog(@"i=%d s->w[i] = %d  nrwd= %d  shift = %0x &= %d",i,self->weekdays[i], self.nr.weekDays, (0x01 << self->weekdays[i]), (self.nr.weekDays & (0x01 << self->weekdays[i])) );
                    }
        #endif
        * /

                }
                [self clearMonthDays];
                [self clearEvery];
            }
        */
        doDelayDaysButtonState()
        // [self weekMonthEveryChange:self.weekMonthEvery];
        updateEnabledButton()
    }

    func clearMonthDays() {
        monthDays.text = ""
    }

    func clearWeekDays() {
        for i in 0..<7 {
            ((weekdayBtns)?[i] as? UIButton)?.isSelected = false
        }

    }

    func clearEvery() {
        everyTF.text = ""
        everyMode = 0
        everyBtnStateUpdate()
        everyTrackerNdx = 0
        fromLastButton.isSelected = false
        updateCheckBtn(fromLastButton)
    }

    func nrFromGui() {
        nr?.clearNR() // does not wipe rid,saveDate or soundFileName
        if enableButton.isHidden {
            return
        }

        nr?.reminderEnabled = enableButton.isSelected

        nr?.msg = msgTF.text
        nr?.tid = tracker?.toid ?? 0

        nr?.start = Int((startSlider.isEnabled ? startSlider.value : -1))

        if enableFinishButton.isSelected && !enableFinishButton.isHidden {
            nr?.until = Int(finishSlider.value)
            nr?.times = Int(repeatTimes.text ?? "") ?? 0
            if 1 < (nr?.times ?? 0) {
                nr?.timesRandom = intervalButton.title(for: .normal) == "random"
            }
            nr?.untilEnabled = true
        } else {
            nr?.until = -1
            nr?.times = 1
            nr?.untilEnabled = false
        }

        /*
            self.nr.until = (self.finishSlider.enabled ? self.finishSlider.value : -1);

            if (self.repeatTimes.hidden) {
                self.nr.times = 1;
            } else {
                self.nr.times = [self.repeatTimes.text intValue];
            }
            */

        if ddbTitleIsDelay() {
            nr?.everyVal = Int(everyTF.text ?? "") ?? 0
            nr?.everyMode = everyMode
            nr?.fromLast = fromLastButton.isSelected
            if !everyTrackerButton.isHidden {
                nr?.vid = (everyTrackerNdx != 0 ? ((tracker?.valObjTable)?[everyTrackerNdx - 1] as? valueObj)?.vid : 0) ?? 0
            }
            for i in 0..<7 {
                if ((weekdayBtns)?[i] as? UIButton)?.isSelected ?? false {
                    nr?.weekDays |= UInt8((0x01 << (weekdays[i])))
                }
            }
        } else {
            let monthDayComponents = monthDays.text?.components(separatedBy: ",")
            for mdComp in monthDayComponents ?? [] {
                nr?.monthDays |= UInt32((0x01 << (Int(mdComp) ?? 0 - 1)))
            }
        }
        /*
            int wme = self.weekMonthEvery.selectedSegmentIndex;
            switch (wme) {
                case SEGWEEK: {
                    int i;
                    for (i=0; i<7; i++) {
                        if ([(UIButton*)[self.weekdayBtns objectAtIndex:i] isSelected]) {
                            self.nr.weekDays |= (0x01 << (self->weekdays[i]));
                        }
                    }
                    break;
                }
                case SEGMONTH: {
                    NSArray *monthDayComponents = [[self.monthDays text] componentsSeparatedByString:@","];
                    for (NSString *mdComp in monthDayComponents) {
                        self.nr.monthDays |= (0x01 << ([mdComp intValue] -1));
                    }
                    break;
                }
                case SEGEVERY: {
                    self.nr.everyVal = [[self.everyTF text] intValue];
                    self.nr.everyMode = self.everyMode;
                    self.nr.fromLast = self.fromLastButton.selected;
                    if (![self.everyTrackerButton isHidden]) {
                        self.nr.vid = ( self.everyTrackerNdx ? ((valueObj*)[self.tracker.valObjTable objectAtIndex:(self.everyTrackerNdx-1)]).vid : 0 );
                    }
                    int i;
                    for (i=0; i<7; i++) {
                        if ([(UIButton*)[self.weekdayBtns objectAtIndex:i] isSelected]) {
                            self.nr.weekDays |= (0x01 << (self->weekdays[i]));
                        }
                    }
                    break;
                }
                default:
                    break;
            }
        */


    }

    func nullNRguiState() -> Bool {
        if startSlider.isEnabled && finishSlider.isEnabled && (startSlider.value > finishSlider.value) {
            return true // if start > fin yes it is null state
        }

        if ddbTitleIsDelay() {
            for i in 0..<7 {
                if ((weekdayBtns)?[i] as? UIButton)?.isSelected ?? false {
                    // if any one is set, no it is not null
                    return false
                }
            }
        } else {
            let monthDayComponents = monthDays.text?.components(separatedBy: ",") // if any positive value here no it is not null
            for mdComp in monthDayComponents ?? [] {
                if 0 < Int(mdComp) ?? 0 {
                    return false
                }
            }
        }

        /*
            int wme = self.weekMonthEvery.selectedSegmentIndex;
            switch (wme) {
                case SEGEVERY:
                    if (0 >= [[self.everyTF text] intValue]) return YES;    // if no positive value here yes it is null

                    //break;    // segevery must have weekdays set too so fall through to weekday check

                case SEGWEEK:
                    for (i=0; i<7; i++) {
                        if ([(UIButton*)[self.weekdayBtns objectAtIndex:i] isSelected]) {   // if any one is set, no it is not null
                            return NO;
                        }
                    }
                    break;

                case SEGMONTH: {
                    NSArray *monthDayComponents = [[self.monthDays text] componentsSeparatedByString:@","];    // if any positive value here no it is not null
                    for (NSString *mdComp in monthDayComponents) {
                        if (0 < [mdComp intValue]) return NO;
                    }
                    break;
                }
                default:
                    break;
            }
            */

        return true
    }

    /*
    - (void) saveNR {
        [compute nr data from gui]
        if computed_nr is null_event
         if 0 != rid : delete rid from db and array
        else (non-null setting)
         if (0 == rid)
            set computed_nr as new nr in db
         else
            update <rid> nr in db
    }
    */

    // MARK: -

    func updateEnabledButton() {
        rTracker_resource.setNotificationsEnabled()
        let guiStateIsNull = nullNRguiState()
        enableButton.isHidden = guiStateIsNull

        enableButton.isSelected = !guiStateIsNull && nr?.reminderEnabled ?? false // enable by default if reminder is valid
        updateCheckBtn(enableButton)

        nextAddBarButton.isEnabled = !guiStateIsNull || tracker?.haveNextReminder() ?? false
        prevBarButton.isEnabled = tracker?.havePrevReminder() ?? false || ((0 == nr?.rid) && tracker?.haveCurrReminder() ?? false)

        if enableButton.isSelected {
            if !rTracker_resource.getNotificationsEnabled() {
                let bdn = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                rTracker_resource.alert("Notifications disabled", msg: "Notifications are disabled for \(bdn ?? "") in system settings, so reminders cannot work.\n\nPlease go to System Settings -> Notifications -> \(bdn ?? "") and allow notifications.\n\n\(bdn ?? "") reminders use badges, sounds and lock screen alerts.", vc: self)
            }
        }
    }

    func updateCheckBtn(_ btn: UIButton?) {
        if btn?.isSelected ?? false {
            btn?.setImage(chkImg, for: .normal)
        } else {
            btn?.setImage(unchkImg, for: .normal)
        }
    }

    func toggleCheckBtn(_ btn: UIButton?) {
        btn?.isSelected = !(btn?.isSelected ?? false)
        updateCheckBtn(btn)
    }

    // 3rd 5th 7th 10th day of each month
    // every n hrs / days / weeks / months
    // n mins / hrs / days / weeks / months from last save
    //  if days / weeks / months can set at time

    func fromLastBtnStateUpdate() {
        if fromLastButton.isSelected {
            //if ((self.everyMode == EV_HOURS) || (self.everyMode == EV_MINUTES) ) {
            //    [self enableStartControls:NO];
            //} else {
            enableStartControls(true)
            //}
            everyTrackerButton.isHidden = false
        } else {
            enableStartControls(true)
            everyTrackerButton.isHidden = true
        }
        updateMessage()
    }

    @IBAction func fromLastBtn(_ sender: Any) {
        DBGLog("fromLastBtn")
        toggleCheckBtn(fromLastButton)
        fromLastBtnStateUpdate()
    }

    @IBAction func everyBtn(_ sender: Any) {
        DBGLog(String("everyBtn \(everyButton.title(for: .normal))"))
        everyMode = UInt8((everyMode != 0 ? Int((everyMode << 1)) & EV_MASK : EV_HOURS))
        everyBtnStateUpdate()
    }

    func everyBtnStateUpdate() {
        switch everyMode {
        case UInt8(EV_HOURS):
            everyButton.setTitle("Hours", for: .normal)
            ///*
            hideFinishControls(false)
            if fromLastButton.isSelected {
                enableStartControls(true)
            }
            //[self startLabelFrom:YES];
            //*/
        case UInt8(EV_DAYS):
            everyButton.setTitle("Days", for: .normal)
            ///*
            hideFinishControls(true)
            if fromLastButton.isSelected {
                enableStartControls(true)
            }
            //[self startLabelFrom:NO];
            //*/
        case UInt8(EV_WEEKS):
            everyButton.setTitle("Weeks", for: .normal)
            ///*
            hideFinishControls(true)
            if fromLastButton.isSelected {
                enableStartControls(true)
            }
            //[self startLabelFrom:NO];
            //*/
        case UInt8(EV_MONTHS):
            everyButton.setTitle("Months", for: .normal)
            ///*
            hideFinishControls(true)
            if fromLastButton.isSelected {
                enableStartControls(true)
            }
            //[self startLabelFrom:NO];
            //*/
        default:
            everyMode = 0 // safety net
            everyButton.setTitle("Minutes", for: .normal)
            ///*
            hideFinishControls(false)
            if fromLastButton.isSelected {
                enableStartControls(true)
            }
            //[self startLabelFrom:YES];
            //*/
        }

        doEFbtnState()

        /*
            [self hideFinishControls:NO];
            if ([self.fromLastButton isSelected]) {
                [self enableStartControls:YES];
            }
            [self startLabelFrom:NO];
             */

        //[self updateEnabledButton];
    }

    @IBAction func btnGear(_ sender: Any) {
        DBGLog("gear button here")
        nrFromGui()

        let nrvc2 = notifyReminderVC2(nibName: "notifyReminderVC2", bundle: nil)
        //nrvc.view.hidden = NO;
        nrvc2.parentNRVC = self
        nrvc2.modalTransitionStyle = .flipHorizontal
        //if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") ) {
        present(nrvc2, animated: true)
        //} else {
        //    [self presentModalViewController:nrvc animated:YES];
        //}
        //[self.navigationController pushViewController:nrvc animated:YES];




    }

    @IBAction func btnHelp(_ sender: Any) {
        DBGLog("btnHelp")
        rTracker_resource.alert("Reminders", msg: "Blue labels are buttons, tap to see the options.\nSet a delay from the last time this tracker (or value) was saved and the weekdays the reminder should trigger, or choose calendar days.\nSet a single time for the reminder to fire, or a time range with equal or random  intervals.\nWhen settings are OK, an 'enable' checkbox appears in the lower right.\nTo delete a reminder, leave the form when the enable checkbox is not shown.\nMultiple reminders may be set using the < and +> buttons in the titlebar.", vc: self)
    }

    @IBAction func monthDaysChange(_ sender: Any) {
        DBGLog("monthDaysChange ")
        updateEnabledButton()
    }

    func updateMessage() {
        if lastDefaultMsg == msgTF.text {
            if !(fromLastButton.isHidden) && (fromLastButton.isSelected) {
                if everyTrackerNdx != 0 {
                    msgTF.text = "\(tracker?.trackerName ?? "") : \(((tracker?.valObjTable)?[everyTrackerNdx - 1] as? valueObj)?.valueName ?? "")"
                    lastDefaultMsg = msgTF.text
                    return
                }
            }
            msgTF.text = tracker?.trackerName
            lastDefaultMsg = msgTF.text
        }
    }

    func setEveryTrackerBtnName() {
        everyTrackerButton.setTitle(everyTrackerNames[everyTrackerNdx], for: .normal)
        DBGLog(String("everyTracker name \(everyTrackerNames[everyTrackerNdx])"))
        everyTrackerButton.setTitleColor(everyTrackerNdx != 0 ? UIColor.blue : UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0), for: .normal)
        updateMessage()
    }

    @IBAction func everyTrackerBtn(_ sender: Any) {
        everyTrackerNdx = everyTrackerNdx < everyTrackerNames.count - 1 ? everyTrackerNdx + 1 : 0
        setEveryTrackerBtnName()
    }

    @IBAction func everyTFChange(_ sender: UITextField) {
        DBGLog("everyTFChange")
        if let intval = Int(sender.text!) {
            if 0 >= intval {
                sender.text = ""
            }
        } else {
            sender.text = ""
        }
        updateEnabledButton()
    }

    @IBAction func messageTFChange(_ sender: Any) {
        DBGLog("messageTFChange")
    }

    func hideWeekdays(_ state: Bool) {
        for i in 0..<7 {
            ((weekdayBtns)?[i] as? UIButton)?.isHidden = state
        }

        thenOnLabel.isHidden = state
    }

    func hideMonthdays(_ state: Bool) {
        //monthDaysLabel.isHidden = state
        monthDays.isHidden = state
    }

    func hideEvery(_ state: Bool) {
        everyTF.isHidden = state
        everyButton.isHidden = state
        fromLastButton.isHidden = state
        fromLastLabel.isHidden = state
        everyTrackerButton.isHidden = state
    }

    func doDelayDaysButtonState() {
        if ddbTitleIsDelay() {
            hideWeekdays(false)
            hideMonthdays(true)
            hideEvery(false)
            enableStartControls(true)
            hideFinishControls(false)
            everyBtnStateUpdate()
            fromLastBtnStateUpdate()
        } else {
            hideWeekdays(true)
            hideMonthdays(false)
            hideEvery(true)
            enableStartControls(true)
            hideFinishControls(false)
        }
        updateMessage()
        updateEnabledButton()
    }

    @IBAction func delayDaysBtn(_ sender: UIButton) {
        //- (IBAction)weekMonthEveryChange:(id)sender {
        //    DBGLog(@"weekMonthEveryChange -- %d --",[sender selectedSegmentIndex]);
        DBGLog(String("curr title: \(sender.titleLabel?.text)"))
        if ddbTitleIsDelay() {
            setDelayDaysButtonTitle(true)
        } else {
            setDelayDaysButtonTitle(false)
        }

        DBGLog(String("change to -- \(sender.titleLabel?.text) --"))

        activeField?.resignFirstResponder()
        doDelayDaysButtonState()

        /*
            switch([sender selectedSegmentIndex]) {
                case SEGWEEK:
                    [self hideWeekdays:NO];
                    [self hideMonthdays:YES];
                    [self hideEvery:YES];
                    [self enableStartControls:YES];
                    [self hideFinishControls:NO];
                    break;
                case SEGMONTH:
                    [self hideWeekdays:YES];
                    [self hideMonthdays:NO];
                    [self hideEvery:YES];
                    [self enableStartControls:YES];
                    [self hideFinishControls:NO];
                break;
                case SEGEVERY:
                    [self hideWeekdays:NO];
                    [self hideMonthdays:YES];
                    [self hideEvery:NO];
                    [self enableStartControls:(! [self.fromLastButton isSelected])];
                    [self everyBtnStateUpdate];
                    [self fromLastBtnStateUpdate];
                break;

            }
            [self updateMessage];
            [self updateEnabledButton];
             */
    }

    @IBAction func wdBtn(_ sender: UIButton) {
        DBGLog(String("wdBtn \(sender.currentTitle)"))
        sender.isSelected = !sender.isSelected
        updateEnabledButton()
    }

    func doEFbtnState() {

        if enableFinishButton.isSelected && !enableFinishButton.isHidden {
            finishSlider.isEnabled = true
            finishHr.isEnabled = true
            finishMin.isEnabled = true
            if hasAmPm {
                finishTimeAmPm.isEnabled = true
            }
            finishLabel.isEnabled = true
            /*
                    if (SEGEVERY == self.weekMonthEvery.selectedSegmentIndex) {
                        self.intervalButton.hidden = YES;
                        self.repeatTimes.hidden = YES;
                        self.repeatTimesLabel.hidden = YES;
                    } else {
                     */
            intervalButton.isHidden = false
            repeatTimes.isHidden = false
            repeatTimesLabel.isHidden = false
            //}
            startLabel(from: true)
        } else {
            intervalButton.isHidden = true
            finishSlider.isEnabled = false
            finishHr.isEnabled = false
            finishMin.isEnabled = false
            if hasAmPm {
                finishTimeAmPm.isEnabled = false
            }
            finishLabel.isEnabled = false
            repeatTimes.isHidden = true
            repeatTimesLabel.isHidden = true
            /*
                    if ((SEGEVERY == self.weekMonthEvery.selectedSegmentIndex) && ((EV_HOURS == self.everyMode) || (EV_MINUTES == self.everyMode))) {
                        [self startLabelFrom:YES];
                    } else {
                     */
            startLabel(from: false)
            //}
        }
        updateEnabledButton()
    }

    func startLabel(from: Bool) {
        if from {
            startLabel.text = "From"
        } else {
            startLabel.text = "At"
        }
    }

    func hideFinishControls(_ hide: Bool) {
        enableFinishButton.isHidden = hide
        finishSlider.isHidden = hide
        finishHr.isHidden = hide
        finishMin.isHidden = hide
        finishLabel.isHidden = hide
        finishColon.isHidden = hide

        if hasAmPm {
            finishTimeAmPm.isHidden = hide
        }

        //if (!hide)
        doEFbtnState()
    }

    func enableStartControls(_ enable: Bool) {
        startHr.isEnabled = enable
        startMin.isEnabled = enable
        startSlider.isEnabled = enable
        startLabel.isEnabled = enable

        if hasAmPm {
            startTimeAmPm.isEnabled = enable
        }

    }

    @IBAction func enableBtn(_ sender: UIButton) {
        toggleCheckBtn(sender)
        if !sender.isSelected {
            rTracker_resource.alert("Reminder disabled", msg: "This reminder is now disabled.  To delete it, clear the settings and navigate away.", vc: self)
        }
    }

    @IBAction func enableFinishBtn(_ sender: Any) {
        DBGLog("enableFinishBtn")
        toggleCheckBtn(sender as? UIButton)
        doEFbtnState()

        //img = (dfltState ? @"unchecked.png" : @"checked.png"); // going to not default state
        //[btn setImage:[UIImage imageNamed:img] forState: UIControlStateNormal];

        //efBtn.
    }

    @IBAction func intervalBtn(_ sender: UIButton) {
        DBGLog(String("intervalBtn \(sender.currentTitle)"))
        DBGLog(String("everyBtn \(intervalButton.title(for: .normal))"))
        if intervalButton.title(for: .normal) == "random" {
            intervalButton.setTitle("interval", for: .normal)
        } else {
            intervalButton.setTitle("random", for: .normal)
        }
        //((UIButton*)sender).selected = ! ((UIButton*)sender).selected;
    }

    func sliderUpdate(_ val: Int, hrtf: UITextField?, mntf: UITextField?, ampml: UILabel?) {
        var hrVal = nr?.hrVal(val) ?? 0
        let mnVal = nr?.mnVal(val) ?? 0

        if hasAmPm {
            if hrVal >= 12 {
                if hrVal > 12 {
                    hrVal -= 12
                }
                ampml?.text = "pm"
            } else {
                if 0 == hrVal {
                    hrVal = 12
                }
                ampml?.text = "am"
            }
        }
        //DBGLog(@"val %d hrVal %d mnVal %d",val,hrVal,mnVal);
        hrtf?.text = String(format: "%02ld", hrVal)
        mntf?.text = String(format: "%02ld", mnVal)

        updateEnabledButton()
    }

    @IBAction func startSliderAction(_ sender: UISlider) {
        //DBGLog(@"startSlider");
        sliderUpdate(Int(sender.value), hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
    }

    @IBAction func finishSliderAction(_ sender: UISlider) {
        //DBGLog(@"finishSlider %f",sender.value);
        sliderUpdate(Int(sender.value), hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
    }

    func timeTfUpdate(_ slider: UISlider?, hrtf: UITextField?, mntf: UITextField?, ampml: UILabel?) {
        var hrVal = Int(hrtf?.text ?? "") ?? 0
        let mnVal = Int(mntf?.text ?? "") ?? 0

        if hasAmPm {
            if hrVal >= 12 {
                ampml?.text = "pm"
            } else if ampml?.text == "pm" {
                hrVal += 12
            }
        }

        slider?.setValue(Float((hrVal * 60) + mnVal), animated: true)
        updateEnabledButton()
    }

    func limitTimeTF(_ tf: UITextField?, max: Int) {
        if 0 > Int(tf?.text ?? "") ?? 0 {
            tf?.text = "0"
        }
        if max < Int(tf?.text ?? "") ?? 0 {
            tf?.text = "\(max)"
        }
    }

    //start
    @IBAction func startHrChange(_ sender: UITextField) {
        DBGLog(String("hrChange \(sender.text)"))
        limitTimeTF(sender, max: 23)
        timeTfUpdate(startSlider, hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
    }

    @IBAction func startMinChange(_ sender: UITextField) {
        DBGLog(String("minChange \(sender.text)"))
        limitTimeTF(sender, max: 59)
        timeTfUpdate(startSlider, hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
    }

    //fin
    @IBAction func finishHrChange(_ sender: UITextField) {
        DBGLog(String("hrChange \(sender.text)"))
        limitTimeTF(sender, max: 23)
        timeTfUpdate(finishSlider, hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
    }

    @IBAction func finishMinChange(_ sender: UITextField) {
        DBGLog(String("minChange \(sender.text)"))
        limitTimeTF(sender, max: 59)
        timeTfUpdate(finishSlider, hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
    }

    @IBAction func timesChange(_ sender: UITextField) {
        DBGLog(String("timesChange \(sender.text)"))

        if 2 > Int(sender.text ?? "") ?? 0 {
            if nr?.timesRandom ?? false {
                sender.text = "1"
            } else {
                sender.text = "2"
            }
        }
    }

    // MARK: -

    @IBAction func TFdidBeginEditing(_ textField: Any) {
        DBGLog("tf begin editing")
        activeField = textField as? UITextField
    }

    @objc func keyboardWillShow(_ n: Notification?) {
        //DBGLog(@"configTVObjVC keyboardwillshow");
        let boty = (activeField?.frame.origin.y ?? 0.0) + (activeField?.frame.size.height ?? 0.0) + MARGIN
        rTracker_resource.willShowKeyboard(n, view: view, boty: boty)
    }

    @objc func keyboardWillHide(_ n: Notification?) {
        //DBGLog(@"handling keyboard will hide");
        rTracker_resource.willHideKeyboard()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUGLOG
        let touch = touches.first
        let touchPoint = touch?.location(in: view)
        DBGLog(String("I am touched at \(touchPoint!.x), \(touchPoint!.y)."))
        #endif

        activeField?.resignFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    /*
    - (void)viewDidUnload {
        [self setMsgTF:nil];
        [self setEnableButton:nil];
        [super viewDidUnload];
    }
    */
}

let SEGWEEK = 0
let SEGMONTH = 1
let SEGEVERY = 2

//@interface notifyReminderViewController ()

//@end
