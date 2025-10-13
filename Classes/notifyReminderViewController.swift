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
            for vo in tracker!.valObjTableH{
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
    var navBar: UINavigationBar!
    var prevBarButton: UIBarButtonItem!
    var nextAddBarButton: UIBarButtonItem!
    var msgTF: UITextField!
    var enableButton: UIButton!
    var delayDaysButton: UIButton!
    var thenOnLabel: UILabel!
    var wdButton1: UIButton!
    var wdButton2: UIButton!
    var wdButton3: UIButton!
    var wdButton4: UIButton!
    var wdButton5: UIButton!
    var wdButton6: UIButton!
    var wdButton7: UIButton!
    //@IBOutlet var monthDaysLabel: UILabel!
    var monthDays: UITextField!
    var everyTF: UITextField!
    var everyButton: UIButton!
    var fromLastButton: UIButton!
    var fromLastLabel: UILabel!
    var everyTrackerButton: UIButton!
    var activeField: UITextField? //just a pointer, no retain
    //@property (nonatomic,retain) IBOutlet UISegmentedControl *weekMonthEvery;
    //- (IBAction)weekMonthEveryChange:(id)sender;

    var startHr: UITextField!
    var startMin: UITextField!
    var startSlider: UISlider!
    var startTimeAmPm: UILabel!
    var startLabel: UILabel!
    var finishHr: UITextField!
    var finishMin: UITextField!
    var finishSlider: UISlider!
    var finishTimeAmPm: UILabel!
    var finishLabel: UILabel!
    var finishColon: UILabel!
    var repeatTimes: UITextField!
    var repeatTimesLabel: UILabel!
    var intervalButton: UIButton!
    var enableFinishButton: UIButton!


    var r_nextevent: UILabel!
    var r_day: UILabel!
    var r_month: UILabel!
    var r_monthday: UILabel!
    var r_year: UILabel!
    var r_hour: UILabel!
    var r_colon: UILabel!
    var r_minute: UILabel!
    var r_ampm: UILabel!
    
    var r_set: [UILabel] {
        [r_nextevent, r_day, r_month, r_monthday, r_year, r_hour, r_colon, r_minute, r_ampm]
    }
    
    /*
    - (IBAction)finishSliderAction:(id)sender;
    - (IBAction)timesChange:(id)sender;
    - (IBAction) intervalBtn:(id)sender;
    */

    var toolBar: UIToolbar!
    var gearButton: UIBarButtonItem!
    var btnDoneOutlet: UIBarButtonItem!
    var btnHelpOutlet: UIBarButtonItem!

    var dismissalHandler: (() -> Void)?  // so presenting controller configTVObjVC can know when we finish

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        //self.tmpReminder=TRUE;

        //self.title=@"hello";
        // Custom initialization
        // [self viewDidLoad];

    }

    // MARK: - View Loading

    override func loadView() {
        // Create main view
        view = UIView()
        view.backgroundColor = UIColor.systemBackground

        // Create all UI elements
        createUIElements()
        setupConstraints()
        wireUpActions()
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
        gearButton.accessibilityLabel = "Configure"
        gearButton.accessibilityIdentifier = "nrvc_config"
        
        btnHelpOutlet.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)
        btnHelpOutlet.accessibilityLabel = "Help"
        btnHelpOutlet.accessibilityIdentifier = "nrvc_help"

        // btnDoneOutlet styling handled by createDoneButton - modern iOS 26 burnt yellow checkmark
        btnDoneOutlet.accessibilityLabel = "Done"


        nextAddBarButton.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)
        
        nextAddBarButton.accessibilityLabel = "Next"
        nextAddBarButton.accessibilityIdentifier = "nrvc_next"
        
        prevBarButton.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            //,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)

        prevBarButton.accessibilityLabel = "Previous"
        prevBarButton.accessibilityIdentifier = "nrvc_prev"
        
        enableButton.accessibilityLabel = "Enable"
        enableButton.accessibilityIdentifier = "nrvc_enable"
        
        fromLastButton.accessibilityHint = "enable to trigger based on last entry"
        fromLastButton.accessibilityIdentifier = "nrvc_fromLastEnable"
        
        fromLastButton.accessibilityHint = "tap to cycle values or tracker"
        fromLastButton.accessibilityIdentifier = "nrvc_fromLastLabel"
        
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)

        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }

    // MARK: - UI Creation

    private func createUIElements() {
        createNavigationBar()
        createDelaySection()
        createEverySection()
        createWeekdaysSection()
        createTimeSection()
        createFinishSection()
        createRepeatSection()
        createMessageSection()
        createNextEventSection()
        createToolbar()
    }

    private func createNavigationBar() {
        navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        let navigationItem = UINavigationItem(title: "Reminders")

        prevBarButton = UIBarButtonItem(title: "<", style: .plain, target: self, action: #selector(prevBtn(_:)))
        prevBarButton.isEnabled = false

        nextAddBarButton = UIBarButtonItem(title: "+>", style: .plain, target: self, action: #selector(nextAddBtn(_:)))
        nextAddBarButton.isEnabled = false

        navigationItem.leftBarButtonItem = prevBarButton
        navigationItem.rightBarButtonItem = nextAddBarButton

        navBar.setItems([navigationItem], animated: false)
    }

    private func createDelaySection() {
        delayDaysButton = UIButton(type: .system)
        delayDaysButton.translatesAutoresizingMaskIntoConstraints = false
        delayDaysButton.setTitle("Delay:", for: .normal)
        delayDaysButton.contentHorizontalAlignment = .left
        delayDaysButton.accessibilityIdentifier = "dly_dom"
        delayDaysButton.addTarget(self, action: #selector(delayDaysBtn(_:)), for: .touchUpInside)
        view.addSubview(delayDaysButton)

        fromLastButton = UIButton(type: .custom)
        fromLastButton.translatesAutoresizingMaskIntoConstraints = false
        fromLastButton.setImage(UIImage(named: "unchecked.png"), for: .normal)
        fromLastButton.addTarget(self, action: #selector(fromLastBtn(_:)), for: .touchUpInside)
        view.addSubview(fromLastButton)

        fromLastLabel = UILabel()
        fromLastLabel.translatesAutoresizingMaskIntoConstraints = false
        fromLastLabel.text = "from last"
        fromLastLabel.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(fromLastLabel)
    }

    private func createEverySection() {
        everyTF = UITextField()
        everyTF.translatesAutoresizingMaskIntoConstraints = false
        everyTF.borderStyle = .roundedRect
        everyTF.font = UIFont.systemFont(ofSize: 14)
        everyTF.keyboardType = .numbersAndPunctuation
        everyTF.returnKeyType = .done
        everyTF.delegate = self
        everyTF.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        everyTF.addTarget(self, action: #selector(everyTFChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(everyTF)

        everyButton = UIButton(type: .system)
        everyButton.translatesAutoresizingMaskIntoConstraints = false
        everyButton.setTitle("Hours", for: .normal)
        everyButton.addTarget(self, action: #selector(everyBtn(_:)), for: .touchUpInside)
        view.addSubview(everyButton)

        everyTrackerButton = UIButton(type: .system)
        everyTrackerButton.translatesAutoresizingMaskIntoConstraints = false
        everyTrackerButton.setTitle("-tracker-", for: .normal)
        everyTrackerButton.contentHorizontalAlignment = .left
        everyTrackerButton.isHidden = true
        everyTrackerButton.addTarget(self, action: #selector(everyTrackerBtn(_:)), for: .touchUpInside)
        view.addSubview(everyTrackerButton)

        monthDays = UITextField()
        monthDays.translatesAutoresizingMaskIntoConstraints = false
        monthDays.borderStyle = .roundedRect
        monthDays.placeholder = "1,8,15,22,29"
        monthDays.font = UIFont.systemFont(ofSize: 14)
        monthDays.keyboardType = .numbersAndPunctuation
        monthDays.returnKeyType = .done
        monthDays.delegate = self
        monthDays.isHidden = true
        monthDays.accessibilityIdentifier = "r_domtf"
        monthDays.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        monthDays.addTarget(self, action: #selector(monthDaysChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(monthDays)
    }

    private func createWeekdaysSection() {
        thenOnLabel = UILabel()
        thenOnLabel.translatesAutoresizingMaskIntoConstraints = false
        thenOnLabel.text = "then on"
        thenOnLabel.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(thenOnLabel)

        // Create weekday buttons
        wdButton1 = createWeekdayButton(identifier: "nrvc_wd0")
        wdButton2 = createWeekdayButton(identifier: "nrvc_wd1")
        wdButton3 = createWeekdayButton(identifier: "nrvc_wd2")
        wdButton4 = createWeekdayButton(identifier: "nrvc_wd3")
        wdButton5 = createWeekdayButton(identifier: "nrvc_wd4")
        wdButton6 = createWeekdayButton(identifier: "nrvc_wd5")
        wdButton7 = createWeekdayButton(identifier: "nrvc_wd6")

        // Create stack view for weekday buttons
        let weekdaysStackView = UIStackView(arrangedSubviews: [wdButton1, wdButton2, wdButton3, wdButton4, wdButton5, wdButton6, wdButton7])
        weekdaysStackView.translatesAutoresizingMaskIntoConstraints = false
        weekdaysStackView.axis = .horizontal
        weekdaysStackView.distribution = .equalSpacing
        weekdaysStackView.spacing = UIStackView.spacingUseSystem
        view.addSubview(weekdaysStackView)
    }

    private func createWeekdayButton(identifier: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = identifier
        button.addTarget(self, action: #selector(wdBtn(_:)), for: .touchUpInside)
        return button
    }

    private func createTimeSection() {
        startLabel = UILabel()
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        startLabel.text = "At"
        startLabel.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(startLabel)

        startHr = UITextField()
        startHr.translatesAutoresizingMaskIntoConstraints = false
        startHr.borderStyle = .roundedRect
        startHr.text = "07"
        startHr.font = UIFont.systemFont(ofSize: 14)
        startHr.keyboardType = .numbersAndPunctuation
        startHr.returnKeyType = .done
        startHr.delegate = self
        startHr.accessibilityIdentifier = "nrvc_at_hrs"
        startHr.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        startHr.addTarget(self, action: #selector(startHrChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(startHr)

        let colonLabel = UILabel()
        colonLabel.translatesAutoresizingMaskIntoConstraints = false
        colonLabel.text = ":"
        colonLabel.font = UIFont.systemFont(ofSize: 17)
        colonLabel.textColor = UIColor.darkText
        view.addSubview(colonLabel)

        startMin = UITextField()
        startMin.translatesAutoresizingMaskIntoConstraints = false
        startMin.borderStyle = .roundedRect
        startMin.text = "00"
        startMin.font = UIFont.systemFont(ofSize: 14)
        startMin.keyboardType = .numbersAndPunctuation
        startMin.returnKeyType = .done
        startMin.delegate = self
        startMin.accessibilityIdentifier = "nrvc_at_minutes"
        startMin.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        startMin.addTarget(self, action: #selector(startMinChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(startMin)

        // Add the colon constraint
        NSLayoutConstraint.activate([
            colonLabel.centerYAnchor.constraint(equalTo: startLabel.centerYAnchor),
            colonLabel.leadingAnchor.constraint(equalTo: startHr.trailingAnchor, constant: 1)
        ])

        startTimeAmPm = UILabel()
        startTimeAmPm.translatesAutoresizingMaskIntoConstraints = false
        startTimeAmPm.text = "am"
        startTimeAmPm.font = UIFont.systemFont(ofSize: 17)
        startTimeAmPm.textColor = UIColor.darkText
        startTimeAmPm.isHidden = true
        view.addSubview(startTimeAmPm)

        startSlider = UISlider()
        startSlider.translatesAutoresizingMaskIntoConstraints = false
        startSlider.minimumValue = 0.0
        startSlider.maximumValue = 1439.0
        startSlider.value = 420.0
        startSlider.isEnabled = false
        startSlider.accessibilityIdentifier = "nrvc_at_slider"
        startSlider.addTarget(self, action: #selector(startSliderAction(_:)), for: .valueChanged)
        view.addSubview(startSlider)
    }

    private func createFinishSection() {
        enableFinishButton = UIButton(type: .custom)
        enableFinishButton.translatesAutoresizingMaskIntoConstraints = false
        enableFinishButton.setImage(UIImage(named: "unchecked.png"), for: .normal)
        enableFinishButton.accessibilityLabel = "enable"
        enableFinishButton.accessibilityHint = "set end time for reminders"
        enableFinishButton.accessibilityIdentifier = "nrvc_enable_until"
        enableFinishButton.addTarget(self, action: #selector(enableFinishBtn(_:)), for: .touchUpInside)
        view.addSubview(enableFinishButton)

        finishLabel = UILabel()
        finishLabel.translatesAutoresizingMaskIntoConstraints = false
        finishLabel.text = "Until"
        finishLabel.font = UIFont.systemFont(ofSize: 17)
        finishLabel.isEnabled = false
        view.addSubview(finishLabel)

        finishHr = UITextField()
        finishHr.translatesAutoresizingMaskIntoConstraints = false
        finishHr.borderStyle = .roundedRect
        finishHr.text = "23"
        finishHr.font = UIFont.systemFont(ofSize: 14)
        finishHr.keyboardType = .numbersAndPunctuation
        finishHr.returnKeyType = .done
        finishHr.delegate = self
        finishHr.isEnabled = false
        finishHr.accessibilityIdentifier = "nrvc_until_hrs"
        finishHr.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        finishHr.addTarget(self, action: #selector(finishHrChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(finishHr)

        finishColon = UILabel()
        finishColon.translatesAutoresizingMaskIntoConstraints = false
        finishColon.text = ":"
        finishColon.font = UIFont.systemFont(ofSize: 17)
        finishColon.textColor = UIColor.darkText
        view.addSubview(finishColon)

        finishMin = UITextField()
        finishMin.translatesAutoresizingMaskIntoConstraints = false
        finishMin.borderStyle = .roundedRect
        finishMin.text = "00"
        finishMin.font = UIFont.systemFont(ofSize: 14)
        finishMin.keyboardType = .numbersAndPunctuation
        finishMin.returnKeyType = .done
        finishMin.delegate = self
        finishMin.isEnabled = false
        finishMin.accessibilityIdentifier = "nrvc_until_minutes"
        finishMin.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        finishMin.addTarget(self, action: #selector(finishMinChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(finishMin)

        finishTimeAmPm = UILabel()
        finishTimeAmPm.translatesAutoresizingMaskIntoConstraints = false
        finishTimeAmPm.text = "pm"
        finishTimeAmPm.font = UIFont.systemFont(ofSize: 17)
        finishTimeAmPm.textColor = UIColor.darkText
        finishTimeAmPm.isHidden = true
        view.addSubview(finishTimeAmPm)

        finishSlider = UISlider()
        finishSlider.translatesAutoresizingMaskIntoConstraints = false
        finishSlider.minimumValue = 0.0
        finishSlider.maximumValue = 1439.0
        finishSlider.value = 1380.0
        finishSlider.isEnabled = false
        finishSlider.accessibilityIdentifier = "nrvc_until_slider"
        finishSlider.addTarget(self, action: #selector(finishSliderAction(_:)), for: .valueChanged)
        view.addSubview(finishSlider)
    }

    private func createRepeatSection() {
        repeatTimes = UITextField()
        repeatTimes.translatesAutoresizingMaskIntoConstraints = false
        repeatTimes.borderStyle = .roundedRect
        repeatTimes.text = "2"
        repeatTimes.font = UIFont.systemFont(ofSize: 14)
        repeatTimes.keyboardType = .numbersAndPunctuation
        repeatTimes.returnKeyType = .done
        repeatTimes.delegate = self
        repeatTimes.isHidden = true
        repeatTimes.accessibilityIdentifier = "nrvc_times_count"
        repeatTimes.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        repeatTimes.addTarget(self, action: #selector(timesChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(repeatTimes)

        repeatTimesLabel = UILabel()
        repeatTimesLabel.translatesAutoresizingMaskIntoConstraints = false
        repeatTimesLabel.text = "times"
        repeatTimesLabel.font = UIFont.systemFont(ofSize: 17)
        repeatTimesLabel.isHidden = true
        view.addSubview(repeatTimesLabel)

        intervalButton = UIButton(type: .system)
        intervalButton.translatesAutoresizingMaskIntoConstraints = false
        intervalButton.setTitle("Equal Intervals", for: .normal)
        intervalButton.contentHorizontalAlignment = .left
        intervalButton.isHidden = true
        intervalButton.accessibilityIdentifier = "nrvc_interval_random"
        intervalButton.addTarget(self, action: #selector(intervalBtn(_:)), for: .touchUpInside)
        view.addSubview(intervalButton)
    }

    private func createMessageSection() {
        let textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = "Text:"
        textLabel.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(textLabel)

        msgTF = UITextField()
        msgTF.translatesAutoresizingMaskIntoConstraints = false
        msgTF.borderStyle = .roundedRect
        msgTF.font = UIFont.systemFont(ofSize: 14)
        msgTF.returnKeyType = .done
        msgTF.delegate = self
        msgTF.addTarget(self, action: #selector(TFdidBeginEditing(_:)), for: .editingDidBegin)
        msgTF.addTarget(self, action: #selector(messageTFChange(_:)), for: .editingDidEndOnExit)
        view.addSubview(msgTF)

        enableButton = UIButton(type: .custom)
        enableButton.translatesAutoresizingMaskIntoConstraints = false
        enableButton.setImage(UIImage(named: "checked.png"), for: .normal)
        enableButton.setImage(UIImage(named: "checked.png"), for: .selected)
        enableButton.isSelected = true
        enableButton.isHidden = true
        enableButton.addTarget(self, action: #selector(enableBtn(_:)), for: .touchUpInside)
        view.addSubview(enableButton)
    }

    private func createNextEventSection() {
        r_nextevent = UILabel()
        r_nextevent.translatesAutoresizingMaskIntoConstraints = false
        r_nextevent.text = "Next event:"
        r_nextevent.font = UIFont.systemFont(ofSize: 17)
        r_nextevent.isHidden = true
        r_nextevent.accessibilityIdentifier = "r_nextEvent"
        view.addSubview(r_nextevent)

        r_day = UILabel()
        r_day.translatesAutoresizingMaskIntoConstraints = false
        r_day.text = "Wednesday"
        r_day.font = UIFont.systemFont(ofSize: 17)
        r_day.isHidden = true
        r_day.accessibilityIdentifier = "r_day"
        view.addSubview(r_day)

        r_month = UILabel()
        r_month.translatesAutoresizingMaskIntoConstraints = false
        r_month.text = "November"
        r_month.font = UIFont.systemFont(ofSize: 17)
        r_month.isHidden = true
        r_month.accessibilityIdentifier = "r_month"
        view.addSubview(r_month)

        r_monthday = UILabel()
        r_monthday.translatesAutoresizingMaskIntoConstraints = false
        r_monthday.text = "23"
        r_monthday.font = UIFont.systemFont(ofSize: 17)
        r_monthday.isHidden = true
        r_monthday.accessibilityIdentifier = "r_monthday"
        view.addSubview(r_monthday)

        r_year = UILabel()
        r_year.translatesAutoresizingMaskIntoConstraints = false
        r_year.text = "2023"
        r_year.font = UIFont.systemFont(ofSize: 17)
        r_year.isHidden = true
        r_year.accessibilityIdentifier = "r_year"
        view.addSubview(r_year)

        r_hour = UILabel()
        r_hour.translatesAutoresizingMaskIntoConstraints = false
        r_hour.text = "00"
        r_hour.font = UIFont.systemFont(ofSize: 17)
        r_hour.isHidden = true
        r_hour.accessibilityIdentifier = "r_hour"
        view.addSubview(r_hour)

        r_colon = UILabel()
        r_colon.translatesAutoresizingMaskIntoConstraints = false
        r_colon.text = ":"
        r_colon.font = UIFont.systemFont(ofSize: 17)
        r_colon.isHidden = true
        r_colon.accessibilityIdentifier = "r_colon"
        view.addSubview(r_colon)

        r_minute = UILabel()
        r_minute.translatesAutoresizingMaskIntoConstraints = false
        r_minute.text = "00"
        r_minute.font = UIFont.systemFont(ofSize: 17)
        r_minute.isHidden = true
        r_minute.accessibilityIdentifier = "r_minute"
        view.addSubview(r_minute)

        r_ampm = UILabel()
        r_ampm.translatesAutoresizingMaskIntoConstraints = false
        r_ampm.text = "AM"
        r_ampm.font = UIFont.systemFont(ofSize: 17)
        r_ampm.isHidden = true
        r_ampm.accessibilityIdentifier = "r_ampm"
        view.addSubview(r_ampm)
    }

    private func createToolbar() {
        toolBar = UIToolbar()
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBar)

        btnDoneOutlet = rTracker_resource.createDoneButton(target: self, action: #selector(btnDone(_:)), accId: "nrvc_done")

        let flexibleSpace1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        gearButton = UIBarButtonItem(title: "⚙", style: .plain, target: self, action: #selector(btnGear(_:)))

        let flexibleSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        btnHelpOutlet = UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(btnHelp(_:)))

        toolBar.setItems([btnDoneOutlet, flexibleSpace1, gearButton, flexibleSpace2, btnHelpOutlet], animated: false)
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Navigation Bar
            navBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 22),
            navBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44),

            // Delay section
            delayDaysButton.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 10),
            delayDaysButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),

            fromLastButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fromLastButton.centerYAnchor.constraint(equalTo: delayDaysButton.centerYAnchor),
            fromLastButton.widthAnchor.constraint(equalToConstant: 24),
            fromLastButton.heightAnchor.constraint(equalToConstant: 20),

            fromLastLabel.leadingAnchor.constraint(equalTo: fromLastButton.trailingAnchor, constant: 8),
            fromLastLabel.centerYAnchor.constraint(equalTo: delayDaysButton.centerYAnchor),

            // Every section
            everyTF.topAnchor.constraint(equalTo: fromLastButton.bottomAnchor, constant: 10),
            everyTF.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
            everyTF.widthAnchor.constraint(equalToConstant: 32),

            everyButton.topAnchor.constraint(equalTo: fromLastButton.bottomAnchor, constant: 10),
            everyButton.leadingAnchor.constraint(equalTo: everyTF.trailingAnchor, constant: 3),

            everyTrackerButton.topAnchor.constraint(equalTo: fromLastButton.bottomAnchor, constant: 10),
            everyTrackerButton.leadingAnchor.constraint(equalTo: fromLastButton.trailingAnchor),

            monthDays.topAnchor.constraint(equalTo: fromLastButton.bottomAnchor, constant: 10),
            monthDays.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
            monthDays.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10),

            // Then on section
            thenOnLabel.topAnchor.constraint(equalTo: monthDays.bottomAnchor, constant: 10),
            thenOnLabel.leadingAnchor.constraint(equalTo: delayDaysButton.leadingAnchor),
        ])

        // Find the weekdays stack view and set up its constraints
        if let weekdaysStackView = view.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
            NSLayoutConstraint.activate([
                weekdaysStackView.topAnchor.constraint(equalTo: thenOnLabel.bottomAnchor, constant: 10),
                weekdaysStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
                weekdaysStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),
                weekdaysStackView.heightAnchor.constraint(equalToConstant: 30),
            ])

            setupTimeConstraints(belowView: weekdaysStackView, safeArea: safeArea)
        }
    }

    private func setupTimeConstraints(belowView: UIView, safeArea: UILayoutGuide) {
        NSLayoutConstraint.activate([
            // Start time section
            startLabel.topAnchor.constraint(equalTo: belowView.bottomAnchor, constant: 34),
            startLabel.leadingAnchor.constraint(equalTo: delayDaysButton.leadingAnchor),

            startHr.centerYAnchor.constraint(equalTo: startLabel.centerYAnchor),
            startHr.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -120),
            startHr.widthAnchor.constraint(equalToConstant: 45),

            startMin.centerYAnchor.constraint(equalTo: startLabel.centerYAnchor),
            startMin.leadingAnchor.constraint(equalTo: startHr.trailingAnchor, constant: 7),
            startMin.widthAnchor.constraint(equalToConstant: 46),

            startTimeAmPm.centerYAnchor.constraint(equalTo: startLabel.centerYAnchor),
            startTimeAmPm.leadingAnchor.constraint(equalTo: startMin.trailingAnchor, constant: 8),
            startTimeAmPm.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -36),

            startSlider.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 10),
            startSlider.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            startSlider.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20),

            // Finish section
            enableFinishButton.topAnchor.constraint(equalTo: startSlider.bottomAnchor, constant: 32),
            enableFinishButton.leadingAnchor.constraint(equalTo: delayDaysButton.leadingAnchor),
            enableFinishButton.widthAnchor.constraint(equalToConstant: 24),
            enableFinishButton.heightAnchor.constraint(equalToConstant: 20),

            finishLabel.leadingAnchor.constraint(equalTo: enableFinishButton.trailingAnchor, constant: 8),
            finishLabel.centerYAnchor.constraint(equalTo: enableFinishButton.centerYAnchor),

            finishHr.centerYAnchor.constraint(equalTo: enableFinishButton.centerYAnchor),
            finishHr.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -121),
            finishHr.widthAnchor.constraint(equalToConstant: 45),

            finishColon.centerYAnchor.constraint(equalTo: enableFinishButton.centerYAnchor),
            finishColon.leadingAnchor.constraint(equalTo: finishHr.trailingAnchor, constant: 1),

            finishMin.centerYAnchor.constraint(equalTo: enableFinishButton.centerYAnchor),
            finishMin.leadingAnchor.constraint(equalTo: finishColon.trailingAnchor, constant: 1),
            finishMin.widthAnchor.constraint(equalToConstant: 46),

            finishTimeAmPm.centerYAnchor.constraint(equalTo: enableFinishButton.centerYAnchor),
            finishTimeAmPm.leadingAnchor.constraint(equalTo: finishMin.trailingAnchor, constant: 8),
            finishTimeAmPm.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -36),

            finishSlider.topAnchor.constraint(equalTo: finishLabel.bottomAnchor, constant: 10),
            finishSlider.leadingAnchor.constraint(equalTo: startSlider.leadingAnchor),
            finishSlider.trailingAnchor.constraint(equalTo: startSlider.trailingAnchor),

            // Repeat section
            repeatTimes.topAnchor.constraint(equalTo: finishSlider.bottomAnchor, constant: 26.5),
            repeatTimes.leadingAnchor.constraint(equalTo: delayDaysButton.leadingAnchor),
            repeatTimes.widthAnchor.constraint(equalToConstant: 37),

            repeatTimesLabel.leadingAnchor.constraint(equalTo: repeatTimes.trailingAnchor, constant: 8),
            repeatTimesLabel.centerYAnchor.constraint(equalTo: repeatTimes.centerYAnchor),

            intervalButton.centerYAnchor.constraint(equalTo: repeatTimesLabel.centerYAnchor),
            intervalButton.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            intervalButton.widthAnchor.constraint(equalToConstant: 100),

            // Toolbar
            toolBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: 49)
        ])

        // Set up message and next event sections separately
        setupMessageConstraints(belowView: repeatTimes, safeArea: safeArea)
        setupNextEventConstraints(safeArea: safeArea)
    }

    private func setupMessageConstraints(belowView: UIView, safeArea: UILayoutGuide) {
        // Find the Text: label and message text field
        let textLabel = view.subviews.first { ($0 as? UILabel)?.text == "Text:" } as? UILabel

        if let textLabel = textLabel {
            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: belowView.bottomAnchor, constant: 26.5),
                textLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),

                msgTF.centerYAnchor.constraint(equalTo: textLabel.centerYAnchor),
                msgTF.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 8),
                msgTF.trailingAnchor.constraint(equalTo: enableButton.leadingAnchor, constant: -10),

                enableButton.centerYAnchor.constraint(equalTo: msgTF.centerYAnchor),
                enableButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10),
                enableButton.widthAnchor.constraint(equalToConstant: 30),
                enableButton.heightAnchor.constraint(equalToConstant: 30)
            ])
        }
    }

    private func setupNextEventConstraints(safeArea: UILayoutGuide) {
        // Find message text field for positioning
        let messageBottomAnchor = msgTF.bottomAnchor

        NSLayoutConstraint.activate([
            r_nextevent.topAnchor.constraint(equalTo: messageBottomAnchor, constant: 47.5),
            r_nextevent.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 20),
            r_nextevent.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -237),

            r_day.topAnchor.constraint(equalTo: r_nextevent.bottomAnchor, constant: 7.5),
            r_day.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 29),
            r_day.widthAnchor.constraint(equalToConstant: 97),

            r_month.firstBaselineAnchor.constraint(equalTo: r_day.firstBaselineAnchor),
            r_month.leadingAnchor.constraint(equalTo: r_day.trailingAnchor, constant: 14),
            r_month.widthAnchor.constraint(equalToConstant: 85),

            r_monthday.firstBaselineAnchor.constraint(equalTo: r_day.firstBaselineAnchor),
            r_monthday.leadingAnchor.constraint(equalTo: fromLastLabel.leadingAnchor),
            r_monthday.widthAnchor.constraint(equalToConstant: 26),

            r_year.firstBaselineAnchor.constraint(equalTo: r_monthday.firstBaselineAnchor),
            r_year.leadingAnchor.constraint(equalTo: r_monthday.trailingAnchor, constant: 19),

            r_hour.topAnchor.constraint(equalTo: r_day.bottomAnchor, constant: 8),
            r_hour.leadingAnchor.constraint(equalTo: repeatTimesLabel.leadingAnchor),

            r_colon.firstBaselineAnchor.constraint(equalTo: r_hour.firstBaselineAnchor),
            r_colon.leadingAnchor.constraint(equalTo: r_hour.trailingAnchor, constant: 3),
            r_colon.widthAnchor.constraint(equalToConstant: 4),

            r_minute.firstBaselineAnchor.constraint(equalTo: r_colon.firstBaselineAnchor),
            r_minute.leadingAnchor.constraint(equalTo: r_colon.trailingAnchor, constant: 8),

            r_ampm.firstBaselineAnchor.constraint(equalTo: r_minute.firstBaselineAnchor),
            r_ampm.leadingAnchor.constraint(equalTo: r_minute.trailingAnchor, constant: 8)
        ])
    }

    private func wireUpActions() {
        // All button actions and text field delegates are already set up in createUIElements methods
        // This method exists for any additional wiring that might be needed
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.setNeedsDisplay()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnDone(nil)
    }

    // shifting to another nr, do we delete current because it is cleared, or save?
    func leaveNR() -> Bool {
        if nullNRguiState() {
            if nr?.rid != 0 {  // nil rtmx
                tracker?.deleteReminder()
                return true
            }
        } else {
            nrFromGui()
            tracker?.save(nr)
        }
        return false
    }

    @objc func btnDone(_ sender: Any?) {
        _ = leaveNR()
        dismiss(animated: true)
    }

 @objc func prevBtn(_ sender: Any) {
        DBGLog("prevBtn")
        let rslt = leaveNR()
        nr = (0 == nr?.rid) || rslt ? tracker?.currReminder() : tracker?.prevReminder()
        //self.nr = ( 0 == self.nr.rid && [self.tracker havePrevReminder] ? [self.tracker prevReminder] : [self.tracker currReminder]);
        guiFromNr()
    }

 @objc func nextAddBtn(_ sender: Any) {
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

    deinit {
        NotificationCenter.default.removeObserver(self)
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
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: view.window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
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
        
        dismissalHandler?()  // so presenting controller configTVObjVC can know when we finish
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateEnabledButton()
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

    func clearGui() {
        clearWeekDays()
        clearEvery()
        clearMonthDays()
    }
    
    func guiFromNr() {
        clearGui()
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
        DBGLog(String("\(nr!)"))
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
            if nr!.timesRandom {
                intervalButton.setTitle("Random", for: .normal)
            } else {
                intervalButton.setTitle("Equal Intervals", for: .normal)
            }
            sliderUpdate(Int(finishSlider.value), hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
        } else {
            enableFinishButton.isSelected = false
            sliderUpdate(nr!.until, hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
        }
        updateCheckBtn(enableFinishButton)

        doEFbtnState()

        if nr!.monthDays != 0 {
            //self.weekMonthEvery.selectedSegmentIndex=SEGMONTH;
            setDelayDaysButtonTitle(true)
            var nma: [String] = [] // (repeating: nil, count: 32)
            for i in 0..<31 {
                if nr!.monthDays & (0x01 << i) != 0 {
                    nma.append("\(i + 1)")
                }
            }
            monthDays.text = nma.joined(separator: ",")
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
                    let c = tracker?.valObjTableH.count ?? 0
                    for i in 0..<c {
                        if nr!.vid == ((tracker!.valObjTableH)[i]).vid {
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

            for i in 0..<7 {
                // added weekdays to every
                ((weekdayBtns)?[i] as? UIButton)?.isSelected = 0 != (Int(nr!.weekDays) & (0x01 << weekdays[i]))
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
            nr!.until = Int(finishSlider.value)
            nr!.times = Int(repeatTimes.text ?? "") ?? 2
            nr!.timesRandom = intervalButton.title(for: .normal) == "Random"
            if nr!.times < 2 && !nr!.timesRandom {
                nr!.times = 2
            }
            nr?.untilEnabled = true
        } /* else {
            nr?.until = -1
            nr?.times = 1
            nr?.untilEnabled = false
        } */

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
                nr?.vid = (everyTrackerNdx != 0 ? ((tracker?.valObjTableH)?[everyTrackerNdx - 1] as? valueObj)?.vid : 0) ?? 0
            }
            for i in 0..<7 {
                if ((weekdayBtns)?[i] as? UIButton)?.isSelected ?? false {
                    nr?.weekDays |= UInt8((0x01 << (weekdays[i])))
                }
            }
        } else {
            let monthDayComponents = monthDays.text?.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) }.compactMap { Int($0) }.sorted()
            nr?.monthDays = 0
            for i in monthDayComponents ?? [] {
                nr?.monthDays |= UInt32((0x01 << (i-1)))
            }
            //print(nr!.monthDays)
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

    // return true if gui is not valid reminder state // return false if reminder should be enabled
    //   logic is so enableBtn.isHidden = result
    // valid is
    // start is less than finish
    // and
    //   delay from tracker with at least one day set
    // or
    //   any positive value in monthDays
    
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
            let monthDayComponents = monthDays.text?.components(separatedBy: ",").map{ $0.trimmingCharacters(in: .whitespaces) }.compactMap { Int($0) } // if any positive value here no it is not null
            for mdComp in monthDayComponents ?? [] {
                if 0 < Int(mdComp) {
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
        
        updateReminderDateDisplay(guiStateIsNull)
    }
    
    func getDateComponents(for date: Date) -> (dayName: String, day: Int, month: String, year: Int, hour: Int, minute: Int, ampm: String?) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute], from: date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current

        // Day name
        dateFormatter.dateFormat = "EEEE"
        let dayName = dateFormatter.string(from: date)

        // Month name
        dateFormatter.dateFormat = "MMMM"
        let monthName = dateFormatter.string(from: date)

        // AM/PM
        dateFormatter.dateFormat = "a"
        let ampm = dateFormatter.string(from: date) // This will be an empty string in locales that don't use AM/PM

        return (dayName, components.day!, monthName, components.year!, components.hour!, components.minute!, ampm.isEmpty ? nil : ampm)
    }
    
    func hideReminderDateDiaplay(_ noDisplay: Bool) {
        r_set.forEach{ $0.isHidden = noDisplay}
    }
    
    func updateReminderDateDisplay(_ noDisplay: Bool) {
        hideReminderDateDiaplay(noDisplay)
        if !noDisplay {
            nrFromGui()
            if let nrDate = tracker?.getNextreminderDate(nr) {
                let components = getDateComponents(for: nrDate)
                DBGLog("Day Name: \(components.dayName), Day: \(components.day), Month: \(components.month), Year: \(components.year), Hour: \(components.hour), Minute: \(components.minute), AM/PM: \(components.ampm ?? "")")

                r_day.text = components.dayName
                r_monthday.text = "\(components.day)"
                r_month.text = components.month
                r_year.text = "\(components.year)"
                r_minute.text = "\(String(format: "%02d", components.minute))"
                
                if components.ampm != nil {
                    r_ampm.text = components.ampm
                    var hr = components.hour
                    if hr > 12 {
                        hr -= 12
                    }
                    if hr == 0 {
                        hr = 12
                    }
                    r_hour.text = "\(hr)"
                } else {
                    r_ampm.isHidden = true
                    r_hour.text = "\(components.hour)"
                }
            } else {
                hideReminderDateDiaplay(true)
                DBGLog("no next reminder date")
            }
        } else {
            DBGLog("invalid GUI state")
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
    // every n hrs / days / weeks / months  <-- no longer supported but 'delay' below uses same values
    // n mins / hrs / days / weeks / months delay from last save
    //  if days / weeks / months can set at time

    func fromLastBtnStateUpdate() {
        if fromLastButton.isSelected {
            //if ((self.everyMode == EV_HOURS) || (self.everyMode == EV_MINUTES) ) {
            //    [self enableStartControls:NO];
            //} else {
            enableStartControls(true)
            //}
            everyTrackerButton.isHidden = false

            everyTF.text = String(format: "%ld", Int(nr!.everyVal))
            everyTF.isEnabled = true
            everyTF.isHidden = false
            everyButton.isHidden = false
        
        } else {
            enableStartControls(true)
            everyTrackerButton.isHidden = true
            everyTF.text = ""
            everyTF.isEnabled = false
            everyTF.isHidden = true
            everyButton.isHidden = true

        }
        updateMessage()
    }

 @objc func fromLastBtn(_ sender: Any) {
        DBGLog("fromLastBtn")
        toggleCheckBtn(fromLastButton)

        fromLastBtnStateUpdate()
    }

 @objc func everyBtn(_ sender: Any) {
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

 @objc func btnGear(_ sender: Any) {
        DBGLog("gear button here")
        nrFromGui()

        let nrvc2 = notifyReminderVC2()
        //nrvc.view.hidden = NO;
        nrvc2.parentNRVC = self
        nrvc2.modalPresentationStyle = .fullScreen
        nrvc2.modalTransitionStyle = .coverVertical
        //if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") ) {
        present(nrvc2, animated: true)
        //} else {
        //    [self presentModalViewController:nrvc animated:YES];
        //}
        //[self.navigationController pushViewController:nrvc animated:YES];




    }

 @objc func btnHelp(_ sender: Any) {
        DBGLog("btnHelp")
        rTracker_resource.alert("Reminders", msg: "Blue labels are buttons, tap to see the options.\nSet a delay from the last time this tracker (or value) was saved and the weekdays the reminder should trigger, or choose calendar days.\nSet a single time for the reminder to fire, or a time range with equal or random intervals.\nWhen settings are OK, an 'enable' checkbox appears in the lower right.\nTo delete a reminder, leave the form when the enable checkbox is not shown.\nMultiple reminders may be set using the < and +> buttons in the titlebar.", vc: self)
    }

 @objc func monthDaysChange(_ sender: Any) {
        DBGLog("monthDaysChange ")
        updateEnabledButton()
    }

    func updateMessage() {
        if lastDefaultMsg == msgTF.text {
            if !(fromLastButton.isHidden) && (fromLastButton.isSelected) {
                if everyTrackerNdx != 0 {
                    msgTF.text = "\(tracker?.trackerName ?? "") : \(((tracker?.valObjTableH)?[everyTrackerNdx - 1] as? valueObj)?.valueName ?? "")"
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

 @objc func everyTrackerBtn(_ sender: Any) {
        everyTrackerNdx = everyTrackerNdx < everyTrackerNames.count - 1 ? everyTrackerNdx + 1 : 0
        setEveryTrackerBtnName()
    }

 @objc func everyTFChange(_ sender: UITextField) {
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

 @objc func messageTFChange(_ sender: Any) {
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

 @objc func delayDaysBtn(_ sender: UIButton) {
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

 @objc func wdBtn(_ sender: UIButton) {
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

 @objc func enableBtn(_ sender: UIButton) {
        toggleCheckBtn(sender)
        if !sender.isSelected {
            rTracker_resource.alert("Reminder disabled", msg: "This reminder is now disabled.  To delete it, clear the settings and 'set reminders' or save the tracker.", vc: self)
        }
    }

 @objc func enableFinishBtn(_ sender: Any) {
        DBGLog("enableFinishBtn")
        toggleCheckBtn(sender as? UIButton)
        doEFbtnState()

        //img = (dfltState ? @"unchecked.png" : @"checked.png"); // going to not default state
        //[btn setImage:[UIImage imageNamed:img] forState: UIControlStateNormal];

        //efBtn.
    }

 @objc func intervalBtn(_ sender: UIButton) {
        DBGLog(String("intervalBtn \(sender.currentTitle)"))
        DBGLog(String("everyBtn \(intervalButton.title(for: .normal))"))
        if intervalButton.title(for: .normal) == "Random" {
            intervalButton.setTitle("Equal Intervals", for: .normal)
        } else {
            intervalButton.setTitle("Random", for: .normal)
        }

        limitTimes()
        updateEnabledButton()
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

        limitTimes()
        updateEnabledButton()
    }

 @objc func startSliderAction(_ sender: UISlider) {
        //DBGLog(@"startSlider");
        sliderUpdate(Int(sender.value), hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
    }

 @objc func finishSliderAction(_ sender: UISlider) {
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
 @objc func startHrChange(_ sender: UITextField) {
        DBGLog(String("hrChange \(sender.text)"))
        limitTimeTF(sender, max: 23)
        timeTfUpdate(startSlider, hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
    }

 @objc func startMinChange(_ sender: UITextField) {
        DBGLog(String("minChange \(sender.text)"))
        limitTimeTF(sender, max: 59)
        timeTfUpdate(startSlider, hrtf: startHr, mntf: startMin, ampml: startTimeAmPm)
    }

    //fin
 @objc func finishHrChange(_ sender: UITextField) {
        DBGLog(String("hrChange \(sender.text)"))
        limitTimeTF(sender, max: 23)
        timeTfUpdate(finishSlider, hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
    }

 @objc func finishMinChange(_ sender: UITextField) {
        DBGLog(String("minChange \(sender.text)"))
        limitTimeTF(sender, max: 59)
        timeTfUpdate(finishSlider, hrtf: finishHr, mntf: finishMin, ampml: finishTimeAmPm)
    }

    func limitTimes() {
        if 2 > Int(repeatTimes.text ?? "") ?? 0 {
            if nr?.timesRandom ?? false {
                repeatTimes.text = "1"
            } else {
                repeatTimes.text = "2"
            }
        }
        let maxMinutes = Int(finishSlider.value - startSlider.value) + 1

        if maxMinutes < Int(repeatTimes.text ?? "") ?? 0 {  // max is 1440 minutes per day, can't work with smaller intervals so indicate here
            repeatTimes.text = "\(maxMinutes)"
        }
    }
    
 @objc func timesChange(_ sender: UITextField) {
        DBGLog(String("timesChange \(sender.text)"))
        limitTimes()
        updateEnabledButton()
    }

    // MARK: -

 @objc func TFdidBeginEditing(_ textField: Any) {
        DBGLog("tf begin editing")
        activeField = textField as? UITextField
    }

    @objc func keyboardWillShow(_ n: Notification?) {
        rTracker_resource.willShowKeyboard(n, vwTarg: activeField!, vwScroll: view)
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
