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
    /*{

    	NSString *myTitle;
        dpRslt *dpr;
    	//NSDate *date;
    	//NSInteger action;
    }
    */
    var myTitle: String?
    //@property (nonatomic,retain) NSDate *date;
    //@property (nonatomic) NSInteger action;
    var dpr: dpRslt?
    // UI element properties 
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var entryNewBtn: UIButton!
    //@property (nonatomic,strong) IBOutlet UIButton *entryCopyBtn;
    @IBOutlet var dateSetBtn: UIButton!
    @IBOutlet var dateGotoBtn: UIButton!
    //@property (nonatomic,strong) IBOutlet UISegmentedControl *dtSegmentedControl;
    @IBOutlet var cancelBtn: UIBarButtonItem!

    @IBAction func btnCancel(_ btn: UIButton?) {
        dpr?.date = datePicker.date
        dpr?.action = DPA_CANCEL
        //[self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)
    }

    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        navBar.items?.last?.title = myTitle
        //CGRect f = self.view.frame;
        //f.size.width = [rTracker_resource getKeyWindowWidth];
        //self.view.frame = f;
        /*
            if (@available(iOS 13.0, *)) {
                bool darkMode = false;

                darkMode = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
                if (darkMode) {
                    self.view.backgroundColor = [UIColor systemBackgroundColor];
                }
            }
             */

        /*
             // does not resize well -- need more work on xib
            self.dateSetBtn.titleLabel.font = PrefBodyFont;
            self.entryNewBtn.titleLabel.font = PrefBodyFont;
            self.dateGotoBtn.titleLabel.font = PrefBodyFont;
            */
        super.viewDidLoad()
        /*f.origin.y= 416;
            f.size.height = 44;
            UIToolbar *tb = [ [UIToolbar alloc]initWithFrame:f ];
            self.toolBar = tb;
             */
        /*
        	UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc]
        								initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
        								target:self
        								action:@selector(btnCancel:)];
            //[self setToolbarItems:@[cancelBtn]];
        	self.toolBar.items = @[cancelBtn];
            */

        //self.datePicker.locale = [NSLocale currentLocale];
        datePicker.maximumDate = Date()
        if let aDate = dpr?.date {
            datePicker.date = aDate
        }

        //self.datePicker.minuteInterval = 2;


    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }

    /*
    - (void)viewDidUnload {
    	self.title = nil;
    	self.entryNewBtn = nil;
    	self.dateSetBtn = nil;
    	self.dateGotoBtn = nil;
    	self.datePicker = nil;
    	self.navBar = nil;
    	self.toolBar = nil;

    	// note keep date for parent

        [super viewDidUnload];
        // Release any retained subviews of the main view.
        // e.g. self.myOutlet = nil;
    }
    */



    // MARK: -
    // MARK: button actions

    @IBAction func cancelEvent(_ sender: Any) {
    }

    @IBAction func entryNewBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_NEW
        //[self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)

        /*
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("13.0") {
            (presentationController?.delegate as? UIViewController)?.viewWillAppear(false)
        }
         */
        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }

    //- (IBAction) entryCopyBtnAction;
    @IBAction func dateSetBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_SET
        //[self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)
        /*
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("13.0") {
            (presentationController?.delegate as? UIViewController)?.viewWillAppear(false)
        }
         */
        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }


    //- (IBAction) dateModeChoice:(id)sender;
    @IBAction func dateGotoBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_GOTO
        //[self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)
        /*
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("13.0") {
            (presentationController?.delegate as? UIViewController)?.viewWillAppear(false)
        }
         */
        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }
    /*
    - (IBAction) dateModeChoice:(id)sender
    {
    	self.datePicker.maximumDate = [NSDate date];
    	self.datePicker.date = self.dpr.date;

    	switch ([sender selectedSegmentIndex]) {
    		case SEG_DATE :
    			self.datePicker.datePickerMode = UIDatePickerModeDate;
    			break;
    		case SEG_TIME:
    			self.datePicker.datePickerMode = UIDatePickerModeTime;
    			break;
    		default:
    			dbgNSAssert(0,@"dateModeChoice: cannot identify seg index");
    			break;
    	}
    }
    */
}
