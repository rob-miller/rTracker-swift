//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
///************
/// datePickerVC.swift
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
//  datePicker.m
//  rTracker
//
//  Created by Robert Miller on 14/10/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import UIKit

///************
/// datePickerVC.h
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

//  datePicker.h
//  rTracker
//
//  this support screen enables the user to specify a date/time to navigate, create or edit  entries for a tracker
//
//  Created by Robert Miller on 14/10/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//


let SEG_DATE = 0
let SEG_TIME = 1


class datePickerVC: UIViewController {

    var myTitle: String?
    var dpr: dpRslt?
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var entryNewBtn: UIButton!
    @IBOutlet var dateSetBtn: UIButton!
    @IBOutlet var dateGotoBtn: UIButton!
    @IBOutlet var cancelBtn: UIBarButtonItem!

    @IBAction func btnCancel(_ btn: UIButton?) {
        dpr?.date = datePicker.date
        dpr?.action = DPA_CANCEL
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        navBar.items?.last?.title = myTitle

        super.viewDidLoad()

        datePicker.maximumDate = Date()
        if let aDate = dpr?.date {
            datePicker.date = aDate
        }
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }




    // MARK: -
    // MARK: button actions

    @IBAction func cancelEvent(_ sender: Any) {
    }

    @IBAction func entryNewBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_NEW
        dismiss(animated: true)

        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }

    //- (IBAction) entryCopyBtnAction;
    @IBAction func dateSetBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_SET
        dismiss(animated: true)

        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }


    //- (IBAction) dateModeChoice:(id)sender;
    @IBAction func dateGotoBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_GOTO

        dismiss(animated: true)

        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }

}
