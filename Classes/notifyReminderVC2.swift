//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// notifyReminderVC2.swift
/// Copyright 2014-2021 Robert T. Miller
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
//  notifyReminderVC2.swift
//  rTracker
//
//  Created by Rob Miller on 19/04/2014.
//  Copyright (c) 2014 Robert T. Miller. All rights reserved.
//

import UIKit

class notifyReminderVC2: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    /*
    {
        notifyReminderViewController *parentNRVC;
        NSArray *soundFiles;
    }
    */
    var parentNRVC: notifyReminderViewController?
    var soundFiles: [String]?
    private var datePicker: UIDatePicker!
    private var soundPicker: UIPickerView!
    private var btnTestOutlet: UIButton!
    private var btnHelpOutlet: UIBarButtonItem!
    private var btnDoneOutlet: UIBarButtonItem!
    private var clearStartDate: UIButton!
    private var toolbar: UIToolbar!
    private var startDateLabel: UILabel!
    private var soundLabel: UILabel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        var sfa: [String] = []
        //datePicker.date = Date(timeIntervalSince1970: TimeInterval(parentNRVC!.nr!.saveDate))

        var files: [String]? = nil
        do {
            files = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
        } catch {
        }
        for fileName in files ?? [] {
            if fileName.hasSuffix(".caf") {
                sfa.append(fileName)
            }
        }
        soundFiles = sfa
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        // Create "Start Date:" label
        startDateLabel = UILabel()
        startDateLabel.text = "Start Date:"
        startDateLabel.font = UIFont.systemFont(ofSize: 17)
        startDateLabel.accessibilityLabel = "start Date"
        startDateLabel.accessibilityHint = "start for delay if not last tracker"
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startDateLabel)

        // Create date picker
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minuteInterval = 1
        datePicker.accessibilityIdentifier = "nrvc2_datepicker"
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)

        // Create reset button
        clearStartDate = UIButton(type: .system)
        clearStartDate.setTitle("Reset", for: .normal)
        clearStartDate.accessibilityHint = "reset the start date"
        clearStartDate.accessibilityIdentifier = "clearStartDate"
        clearStartDate.addTarget(self, action: #selector(btnResetStartDate(_:)), for: .touchUpInside)
        clearStartDate.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearStartDate)

        // Create "Sound:" label
        soundLabel = UILabel()
        soundLabel.text = "Sound:"
        soundLabel.font = UIFont.systemFont(ofSize: 17)
        soundLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(soundLabel)

        // Create sound picker
        soundPicker = UIPickerView()
        soundPicker.dataSource = self
        soundPicker.delegate = self
        soundPicker.accessibilityHint = "sound to play with notification"
        soundPicker.accessibilityIdentifier = "nr-sound-chooser"
        soundPicker.accessibilityLabel = "sound choice"
        soundPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(soundPicker)

        // Create sample button
        btnTestOutlet = UIButton(type: .system)
        btnTestOutlet.setTitle("Sample", for: .normal)
        btnTestOutlet.setTitleShadowColor(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), for: .normal)
        btnTestOutlet.accessibilityHint = "tap to play selected sound"
        btnTestOutlet.accessibilityIdentifier = "nr-sound-play"
        btnTestOutlet.accessibilityLabel = "play sample"
        btnTestOutlet.addTarget(self, action: #selector(btnTest(_:)), for: .touchUpInside)
        btnTestOutlet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btnTestOutlet)

        // Create toolbar
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Create toolbar items
        btnDoneOutlet = UIBarButtonItem(title: "✓", style: .plain, target: self, action: #selector(btnDone(_:)))
        btnDoneOutlet.accessibilityLabel = "done"
        btnDoneOutlet.accessibilityIdentifier = "nrvc2_done"
        btnDoneOutlet.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 28.0)], for: .normal)

        btnHelpOutlet = UIBarButtonItem(title: "?", style: .plain, target: self, action: #selector(btnHelp(_:)))
        btnHelpOutlet.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 28.0)], for: .normal)

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.setItems([btnDoneOutlet, flexibleSpace, btnHelpOutlet], animated: false)
    }

    private func setupConstraints() {

        NSLayoutConstraint.activate([
            // Start Date label
            startDateLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            startDateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 19),

            // Reset button
            clearStartDate.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -33),
            clearStartDate.firstBaselineAnchor.constraint(equalTo: startDateLabel.firstBaselineAnchor),

            // Date picker
            datePicker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            datePicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            datePicker.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 5),

            // Sound label
            soundLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            soundLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 5),

            // Sample button
            btnTestOutlet.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            btnTestOutlet.centerYAnchor.constraint(equalTo: soundLabel.centerYAnchor),

            // Sound picker
            soundPicker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            soundPicker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            soundPicker.topAnchor.constraint(equalTo: soundLabel.bottomAnchor, constant: 5),

            // Toolbar
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.date = Date(timeIntervalSince1970: TimeInterval(parentNRVC!.nr!.saveDate))

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.setNeedsDisplay()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnDone(nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        datePicker.date = Date(timeIntervalSince1970: TimeInterval(parentNRVC!.nr!.saveDate))
        let ndx = UInt((soundFiles?.firstIndex(of: parentNRVC?.nr?.soundFileName ?? "") ?? NSNotFound))
        if (nil == parentNRVC?.nr?.soundFileName) || (NSNotFound == Int(ndx)) {
            soundPicker.selectRow(soundFiles?.count ?? 0, inComponent: 0, animated: false)
            btnTestOutlet.isEnabled = false
        } else {
            soundPicker.selectRow(Int(ndx), inComponent: 0, animated: false)
            btnTestOutlet.isEnabled = true
        }

        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func btnHelp(_ sender: Any) {
        DBGLog("btnHelp")
        rTracker_resource.alert("Reminder details", msg: "Set the start date and time for the reminder delay here if not based on the last tracker save.\nSet the sound to be played when the reminder is triggered.  The default sound cannot be played while rTracker is the active application.", vc: self)
    }

    @objc func btnTest(_ sender: Any) {
        DBGLog("btnTest")
        //[self.parentNRVC.nr present];
        //[self.parentNRVC.nr schedule:[NSDate dateWithTimeIntervalSinceNow:1]];
        parentNRVC?.nr?.playSound()

    }

    @objc func btnDone(_ sender: Any?) {
        DBGLog("btnDone called")
        DBGLog(String("leaving - datepicker says \(datePicker.date)"))

        guard let parentNRVC = parentNRVC,
              let nr = parentNRVC.nr else {
            DBGErr("parentNRVC or nr is nil")
            return
        }

        nr.saveDate = Int(datePicker.date.timeIntervalSince1970)
        DBGLog("saveDate set to \(nr.saveDate)")

        dismiss(animated: true) {
            DBGLog("dismiss completed, calling updateEnabledButton")
            parentNRVC.updateEnabledButton()
        }
    }
    
    @objc func btnResetStartDate(_ sender: Any) {
        datePicker.date = Date()
    }
    /*
    #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
    {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    /*
    - (void)viewDidUnload {
        [self setDatePicker:nil];
        [self setSoundPicker:nil];
        [self setBtnTestOutlet:nil];
        [super viewDidUnload];
    }
    */

    // MARK: -
    // MARK: Picker Data Source Methods

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (soundFiles?.count ?? 0) + 2
    }

    // MARK: Picker Delegate Methods

    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        let c = soundFiles?.count ?? 0
        if row < c {
            return soundFiles![row].replacingOccurrences(of: "_", with: " ").replacingOccurrences(
                of: ".caf",
                with: "")
        } else if row == c {
            return "Default"
        } else {
            return "Silent"
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let c = soundFiles?.count ?? 0
        if row < c {
            parentNRVC?.nr?.soundFileName = (soundFiles)?[row] as? String
            btnTestOutlet.isEnabled = true
        } else {
            btnTestOutlet.isEnabled = false
            if row == c {
                parentNRVC?.nr?.soundFileName = nil
            } else {
                parentNRVC?.nr?.soundFileName = "Silent"
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("XIB-based initialization not supported")
    }
}

//@interface notifyReminderVC2 ()
//@end
