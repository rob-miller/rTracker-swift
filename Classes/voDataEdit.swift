//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voDataEdit.swift
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
//  voDataEdit.swift
//  rTracker
//
//  Created by Robert Miller on 10/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

///************
/// voDataEdit.swift
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
//  voDataEdit.swift
//  rTracker
//
//  Created by Robert Miller on 10/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

// implements textbox editor

import UIKit

class voDataEdit: UIViewController, UITextViewDelegate {
    /*{

    	valueObj *vo;

    }*/
    var vo: valueObj?
    var textView: UITextView?
    //@property (nonatomic) CGRect saveFrame;
    var saveClass: voState?  // Any?
    var saveSelector: Selector?
    var text: String?

    /*
     // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
        if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
            // Custom initialization
        }
        return self;
    }
    */


    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {

        super.viewDidLoad()

        var f = view.frame
        f.size.width = rTracker_resource.getKeyWindowWidth()
        view.frame = f

        if let vo {
            // valueObj data edit - voTextBox, voImage
            DBGLog("vde view did load")
            title = vo.valueName
            vo.vos?.dataEditVDidLoad(self)
            textView = (vo.vos as? voTextBox)?.textView
        } else {
            // generic text editor
            textView = UITextView(frame: view.frame)
            textView?.textColor = .label
            textView?.font = PrefBodyFont // [UIFont fontWithName:@"Arial" size:18];
            textView?.delegate = self
            textView?.backgroundColor = .systemBackground

            //self.textView.text = self.vo.value;
            textView?.returnKeyType = .default
            textView?.keyboardType = .default // use the default type input method (entire keyboard)
            textView?.isScrollEnabled = true
            textView?.isUserInteractionEnabled = true

            // this will cause automatic vertical resize when the table is resized
            textView?.autoresizingMask = .flexibleHeight

            textView?.text = text

            // note: for UITextView, if you don't like autocompletion while typing use:
            // myTextView.autocorrectionType = UITextAutocorrectionTypeNo;

            if let textView {
                view.addSubview(textView)
            }

            keyboardIsShown = false

            textView?.becomeFirstResponder()
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        if let vo {
            vo.vos?.dataEditVWAppear(self)
        }

        keyboardIsShown = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configTVObjVC.keyboardWillShow(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification /*UIKeyboardWillShowNotification */,
            object: view.window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configTVObjVC.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: view.window)


        //[self.navigationController setToolbarHidden:NO animated:NO];

        super.viewWillAppear(animated)

    }

    override func viewWillDisappear(_ animated: Bool) {
        if let vo {
            vo.vos?.dataEditVWDisappear(self)
        }
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification /* UIKeyboardWillShowNotification */,
            object: nil)
        //--object:self.textView];    // nil]; //self.devc.view.window];
        //object:self.devc.view.window];
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        //object:self.textView];    // nil];   // self.devc.view.window];
        //object:self.devc.view.window];


        super.viewWillDisappear(animated)
    }

    class func getInitTVF(_ vc: UIViewController) -> CGRect {
        var frame = vc.view.frame
        let frame2 = vc.navigationController!.navigationBar.frame
        DBGLog(String("nvb rect: \(frame2)"))
        let frame3 = vc.navigationController!.toolbar.frame
        DBGLog(String("tb rect: \(frame3))"))

        frame.origin.y += frame2.size.height  + frame2.origin.y 
        frame.size.height -= frame.origin.y + frame3.size.height

        DBGLog(String("initTVF rect: \(frame.origin.x) \(frame.origin.y) \(frame.size.width) \(frame.size.height)"))
        return frame
    }

    @objc func keyboardWillShow(_ aNotification: Notification?) {
        DBGLog("votb keyboardwillshow")

        if keyboardIsShown {
            return
        }

        // the keyboard is showing so resize the table's height
        //self.saveFrame = self.textView.frame;
        let userInfo = aNotification?.userInfo
        let keyboardRect = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect // ?.cgRectValue
        DBGLog(String("keyboard rect: \(keyboardRect.origin.x) \(keyboardRect.origin.y) \(keyboardRect.size.width) \(keyboardRect.size.height)"))
        /*
            if (self.vo) {
                keyboardRect = [self.vo.vos.vc.view convertRect:keyboardRect fromView:nil];
            } else {
                keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
            }
            */
        //DBGLog(@"keyboard rect conv: %f %f %f %f",keyboardRect.origin.x,keyboardRect.origin.y,keyboardRect.size.width,keyboardRect.size.height);

        //NSTimeInterval animationDuration = [[aNotification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        var frame = voDataEdit.getInitTVF(self)
        frame.size.height -= keyboardRect.size.height
        //UIView *iav = ((voTextBox*)self.vo.vos).textView.inputAccessoryView;
        //CGRect avframe = iav.frame;
        let avframe = textView?.inputAccessoryView?.frame
        DBGLog(String("acc view frame rect: \(avframe!.origin.x) \(avframe!.origin.y) \(avframe!.size.width) \(avframe!.size.height)"))

        frame.size.height += avframe?.size.height ?? 0.0

        DBGLog(String("keyboard TVF: \(frame.origin.x) \(frame.origin.y) \(frame.size.width) \(frame.size.height)"))

        //[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        //[UIView setAnimationDuration:animationDuration];

        UIView.animate(withDuration: 0.2, animations: { [self] in
            textView?.frame = frame
            if let selectedRange = textView?.selectedRange {
                textView?.scrollRangeToVisible(selectedRange)
            }
        })
        //[UIView commitAnimations];

        keyboardIsShown = true

    }

    @objc func keyboardWillHide(_ aNotification: Notification?) {
        DBGLog("votb keyboardwillhide")

        // the keyboard is hiding reset the table's height
        //CGRect keyboardRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        //NSTimeInterval animationDuration = [[aNotification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        //CGRect frame = self.devc.view.frame;
        //frame.size.height += keyboardRect.size.height;
        //[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        //[UIView setAnimationDuration:animationDuration];
        UIView.animate(withDuration: 0.2, animations: { [self] in
            textView?.frame = voDataEdit.getInitTVF(self)
        })
        //[UIView commitAnimations];


        keyboardIsShown = false
    }
    /*
    func saveAction(sender: Any) {
        print("save me")
        // Use performSelector, if needed
        // saveClass.perform(self.saveSelector, with: "FOOOO", afterDelay: 0)
        saveClass!.perform(self.saveSelector!, with: self.textView!.text, afterDelay: 0)
        self.dismiss(animated: true, completion: nil)
    }
     */

    @objc func saveAction(_ sender: Any?) {
        DBGLog("save me")
        //[self.saveClass performSelector:self.saveSelector withObject:@"FOOOO" afterDelay:(NSTimeInterval)0];
        saveClass!.perform(saveSelector!, with: textView?.text, afterDelay: TimeInterval(0))
        dismiss(animated: true)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // provide my own Save button to dismiss the keyboard
        let saveItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveAction(_:)))
        navigationItem.rightBarButtonItem = saveItem
    }

    func textViewShouldBeginEditing(_ aTextView: UITextView) -> Bool {

        /*
             You can create the accessory view programmatically (in code), in the same nib file as the view controller's main view, or from a separate nib file. This example illustrates the latter; it means the accessory view is loaded lazily -- only if it is required.
             */
        /*
            if (self.textView.inputAccessoryView == nil) {
                [[NSBundle mainBundle] loadNibNamed:@"voTBacc" owner:self options:nil];
                // Loading the AccessoryView nib file sets the accessoryView outlet.
                self.textView.inputAccessoryView = self.accessoryView;
                // After setting the accessory view for the text view, we no longer need a reference to the accessory view.
                self.accessoryView = nil;
                self.addButton.hidden = YES;
                CGFloat fsize = 20.0;
                [self.segControl setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fsize]} forState:UIControlStateNormal];
                [self.setSearchSeg setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fsize]} forState:UIControlStateNormal];
            }
            */
        return true
    }

    func textViewShouldEndEditing(_ aTextView: UITextView) -> Bool {
        aTextView.resignFirstResponder()
        return true
    }

    /*
     // needs more work to adjust text box size / display point as rotated view is very short

    // Override to allow orientations other than the default portrait orientation.
    - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
        // Return YES for supported orientations
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    */

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }

    /*
    - (void)viewDidUnload {
    	DBGLog(@"vde view did unload");

        [super viewDidUnload];
        // Release any retained subviews of the main view.
        // e.g. self.myOutlet = nil;
    	[self.vo.vos dataEditVDidUnload];
    	self.vo = nil;
    }
    */

    deinit {

        //DBGLog(@"vde dealloc");
        if vo != nil {
            vo = nil
        }
        //[vo release];


    }
}
