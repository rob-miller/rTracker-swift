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
    var soundFiles: [AnyHashable]?
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var soundPicker: UIPickerView!
    @IBOutlet var btnTestOutlet: UIButton!
    @IBOutlet var btnHelpOutlet: UIBarButtonItem!
    @IBOutlet var btnDoneOutlet: UIBarButtonItem!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        var sfa: [AnyHashable] = []
        datePicker.date = Date(timeIntervalSince1970: TimeInterval(parentNRVC?.nr?.saveDate ?? 0.0))

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

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.date = Date(timeIntervalSince1970: TimeInterval(parentNRVC?.nr?.saveDate ?? 0.0))
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

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)


        // Do any additional setup after loading the view.
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.setNeedsDisplay()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnDone(nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        datePicker.date = Date(timeIntervalSince1970: TimeInterval(parentNRVC?.nr?.saveDate ?? 0.0))
        let ndx = UInt((soundFiles?.firstIndex(of: parentNRVC?.nr?.soundFileName ?? "") ?? NSNotFound))
        if (nil == parentNRVC?.nr?.soundFileName) || (NSNotFound == Int(ndx)) {
            soundPicker.selectRow(soundFiles?.count ?? 0, inComponent: 0, animated: false)
            btnTestOutlet.isEnabled = false
        } else {
            soundPicker.selectRow(Int(ndx), inComponent: 0, animated: false)
            btnTestOutlet.isEnabled = true
        }

        navigationController?.setToolbarHidden(false, animated: false)

        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnHelp(_ sender: Any) {
        DBGLog("btnHelp")
        rTracker_resource.alert("Reminder details", msg: "Set the start date and time for the reminder delay here if not based on the last tracker save.\nSet the sound to be played when the reminder is triggered.  The default sound cannot be played while rTracker is the active application.", vc: self)
    }

    @IBAction func btnTest(_ sender: Any) {
        DBGLog("btnTest")
        //[self.parentNRVC.nr present];
        //[self.parentNRVC.nr schedule:[NSDate dateWithTimeIntervalSinceNow:1]];
        parentNRVC?.nr?.playSound()

    }

    @IBAction func btnDone(_ sender: Any) {
        //ios6 [self dismissModalViewControllerAnimated:YES];
        DBGLog("leaving - datepicker says %@", datePicker.date)
        parentNRVC?.nr?.saveDate = Int(datePicker.date.timeIntervalSince1970)

        dismiss(animated: true)
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

    func numberOfComponents(in pickerView: UIPickerView?) -> Int {
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
            return (soundFiles)?[row]?.replacingOccurrences(of: "_", with: " ").replacingOccurrences(
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
        super.init(coder: aDecoder)
    }
}

//@interface notifyReminderVC2 ()
//@end