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
            textView?.keyboardAppearance = .default // follow system appearance
            textView?.isScrollEnabled = true
            textView?.isUserInteractionEnabled = self.vo?.optDict["otsrc"] ?? "0" != "1"

            // this will cause automatic vertical resize when the table is resized
            textView?.autoresizingMask = .flexibleHeight

            textView?.text = text

            // note: for UITextView, if you don't like autocompletion while typing use:
            // myTextView.autocorrectionType = UITextAutocorrectionTypeNo;

            textView?.accessibilityIdentifier = "\(vo!.vos!.tvn())_textBox"
            if let textView {
                view.addSubview(textView)
            }

            keyboardIsShown = false

            // Keyboard presentation now handled in viewDidAppear for better timing
        }

    }
    

    override func viewWillAppear(_ animated: Bool) {
        if let vo {
            vo.vos?.dataEditVWAppear(self)
        }

        keyboardIsShown = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification /*UIKeyboardWillShowNotification */,
            object: view.window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configTVObjVC.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: view.window)

        super.viewWillAppear(animated)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Handle keyboard presentation for both voTextBox and generic paths
        // Use longer delay for subsequent visits to ensure proper appearance timing
        let shouldShowKeyboard = (vo != nil && (vo?.vos as? voTextBox)?.shouldBecomeFirstResponder == true) ||
                                (vo == nil && textView != nil && textView?.text == "")

        if shouldShowKeyboard {
            // Longer delay for subsequent visits to avoid appearance flicker
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.textView?.becomeFirstResponder()
                // Clear the flag for voTextBox case
                if let votb = self?.vo?.vos as? voTextBox {
                    votb.shouldBecomeFirstResponder = false
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let vo {
            vo.vos?.dataEditVWDisappear(self)
        }
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification /* UIKeyboardWillShowNotification */,
            object: nil)

        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

        super.viewWillDisappear(animated)
    }

    class func getInitTVF(_ vc: UIViewController) -> CGRect {
        var frame = vc.view.frame

        let frame2 = vc.navigationController!.navigationBar.frame
        DBGLog(String("nvb rect: \(frame2)"))
        let frame3 = vc.navigationController!.toolbar.frame
        DBGLog(String("tb rect: \(frame3))"))

        // Use safe area insets for more reliable layout
        let safeArea = vc.view.safeAreaInsets
        DBGLog(String("safe area: top=\(safeArea.top) bottom=\(safeArea.bottom)"))

        // Calculate frame based on safe area and navigation bar
        frame.origin.y = safeArea.top
        frame.size.height = vc.view.frame.height - safeArea.top - safeArea.bottom

        DBGLog(String("initTVF rect: \(frame.origin.x) \(frame.origin.y) \(frame.size.width) \(frame.size.height)"))
        return frame
    }

    @objc func keyboardWillShow(_ aNotification: Notification?) {
        DBGLog("votb keyboardwillshow")

        let userInfo = aNotification?.userInfo
        let keyboardRect = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect // ?.cgRectValue
        DBGLog(String("keyboard rect: \(keyboardRect.origin.x) \(keyboardRect.origin.y) \(keyboardRect.size.width) \(keyboardRect.size.height)"))

        // Calculate new frame for text view
        var frame = voDataEdit.getInitTVF(self)
        frame.size.height -= keyboardRect.size.height

        // Add back accessory view height if present
        if let avframe = textView?.inputAccessoryView?.frame {
            DBGLog(String("acc view frame rect: \(avframe.origin.x) \(avframe.origin.y) \(avframe.size.width) \(avframe.size.height)"))
            frame.size.height += avframe.size.height
        }

        DBGLog(String("keyboard TVF: \(frame.origin.x) \(frame.origin.y) \(frame.size.width) \(frame.size.height)"))

        // Only animate if frame actually changes to avoid conflicts during rapid transitions
        if !frame.equalTo(textView?.frame ?? .zero) {
            UIView.animate(withDuration: 0.2, animations: { [self] in
                textView?.frame = frame
                if let selectedRange = textView?.selectedRange {
                    textView?.scrollRangeToVisible(selectedRange)
                }
            })
        }

        keyboardIsShown = true
    }

    @objc func keyboardWillHide(_ aNotification: Notification?) {
        DBGLog("votb keyboardwillhide")

        let fullFrame = voDataEdit.getInitTVF(self)

        // Only animate if frame actually changes to avoid conflicts during rapid transitions
        if !fullFrame.equalTo(textView?.frame ?? .zero) {
            UIView.animate(withDuration: 0.2, animations: { [self] in
                textView?.frame = fullFrame
            })
        }

        keyboardIsShown = false
    }

    @objc func saveAction(_ sender: Any?) {
        DBGLog("save me")

        if self.vo?.optDict["otsrc"] ?? "0" != "1" {
            saveClass!.perform(saveSelector!, with: textView?.text, afterDelay: TimeInterval(0))
        }
        dismiss(animated: true)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        // Save button is set up in voTextBox.dataEditVDidLoad for voTextBox cases
        // No need to create one here - back button handles navigation
    }

    /*
    func textViewShouldBeginEditing(_ aTextView: UITextView) -> Bool {
        if vo?.optDict["otsrc"] ?? "0" != "0" {
            return false
        }
        return true
    }

    func textViewShouldEndEditing(_ aTextView: UITextView) -> Bool {
        aTextView.resignFirstResponder()
        return true
    }
*/
    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()
    }

    deinit {

        //DBGLog(@"vde dealloc");
        if vo != nil {
            vo = nil
        }

        NotificationCenter.default.removeObserver(self)
        
    }
}
