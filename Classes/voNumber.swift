//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voNumber.swift
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
//  voNumber.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation

class voNumber: voState, UITextFieldDelegate {
    /*{
        UITextField *dtf;
    }*/


    private var _dtf: UITextField?
    var dtf: UITextField? {
        safeDispatchSync({ [self] in
            if self.dtf != nil && self.dtf?.frame.size.width != vosFrame.size.width {
                self.dtf = nil // first time around thinks size is 320, handle larger devices
            }
        })

        if nil == _dtf {
            DBGLog("init %@ : x=%f y=%f w=%f h=%f", vo?.valueName, vosFrame.origin.x, vosFrame.origin.y, vosFrame.size.width, vosFrame.size.height)
            _dtf = UITextField(frame: vosFrame)

            if #available(iOS 13.0, *) {
                _dtf?.textColor = .label
                _dtf?.backgroundColor = .secondarySystemBackground
            } else {
                _dtf?.textColor = .black
                _dtf?.backgroundColor = .white
            }

            _dtf?.borderStyle = .roundedRect //Bezel;
            _dtf?.font = PrefBodyFont // [UIFont systemFontOfSize:17.0];
            _dtf?.autocorrectionType = .no // no auto correction support

            _dtf?.placeholder = "<enter number>"
            _dtf?.textAlignment = .right // ios6 UITextAlignmentRight;
            //[dtf addTarget:self action:@selector(numTextFieldClose:) forControlEvents:UIControlEventTouchUpOutside];


            //_dtf.keyboardType = UIKeyboardTypeNumbersAndPunctuation;	// use the number input only -- need decimal point

            _dtf?.keyboardType = .decimalPad //number pad with decimal point but no done button 	// use the number input only
            // no done button for number pad // _dtf.returnKeyType = UIReturnKeyDone;
            // need this from http://stackoverflow.com/questions/584538/how-to-show-done-button-on-iphone-number-pad Michael Laszlo
            // .applicationFrame deprecated ios9
            let appWidth = Float(UIScreen.main.bounds.width)
            let accessoryView = UIToolbar(
                frame: CGRect(x: 0, y: 0, width: CGFloat(appWidth), height: CGFloat(0.1 * appWidth)))
            let space = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)
            let done = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(selectDoneButton))
            let minus = UIBarButtonItem(
                title: "-",
                style: .plain,
                target: self,
                action: #selector(selectMinusButton))

            accessoryView.items = [space, done, space, minus, space]
            _dtf?.inputAccessoryView = accessoryView



            _dtf?.clearButtonMode = .whileEditing // has a clear 'x' button to the right

            //dtf.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
            _dtf?.delegate = self // let us be the delegate so we know when the keyboard's "Done" button is pressed

            // Add an accessibility label that describes what the text field is for.
            _dtf?.accessibilityLabel = NSLocalizedString("enter a number", comment: "")
            _dtf?.text = ""
            _dtf?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        //DBGLog(@"num dtf rc= %d",[dtf retainCount]);

        return _dtf
    }
    weak var startStr: String?

    func textFieldDidBeginEditing(_ textField: UITextField) {
        //DBGLog(@"number tf begin editing vid=%ld",(long)self.vo.vid);
        startStr = textField.text
        (vo?.parentTracker as? trackerObj)?.activeControl = textField as? UIControl
    }

    @objc func textFieldDidChange(_ textField: UITextField?) {
        // not sure yet - lot of actions for every char when just want to enable 'save'
        //[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        DBGLog("vo.value= %@", vo?.value)
        DBGLog("tf.text= %@", textField.text)
        DBGLog("tf end editing vid=%ld vo.value=%@ tf.text=%@", Int(vo?.vid ?? 0), vo?.value, textField.text)

        if startStr != textField.text {
            vo?.value = textField.text
            //textField.textColor = [UIColor blackColor];
            //textField.backgroundColor = [UIColor whiteColor];
            NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
            startStr = nil
        }

        (vo?.parentTracker as? trackerObj)?.activeControl = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // the user pressed the "Done" button, so dismiss the keyboard
        //DBGLog(@"textField done: %@  vid=%d", textField.text,self.vo.vid);
        // [self tfvoFinEdit:textField];  // textFieldDidEndEditing will be called, just dismiss kybd here
        DBGLog("tf should return vid=%ld vo.value=%@ tf.text=%@", Int(vo?.vid ?? 0), vo?.value, textField.text)

        textField.resignFirstResponder()
        return true
    }

    @objc func selectDoneButton() {
        dtf?.resignFirstResponder()
    }

    @objc func selectMinusButton() {
        dtf?.text = rTracker_resource.negateNumField(dtf?.text)
    }

    override func resetData() {
        if nil != dtf {
            // not self as don't want to instantiate prematurely
            if Thread.isMainThread {
                dtf?.text = ""
            } else {
                DispatchQueue.main.async(execute: { [self] in
                    dtf?.text = ""
                })
            }
        }
        vo?.useVO = true
    }

    override func voDisplay(_ bounds: CGRect) -> UIView? {
        vosFrame = bounds

        //if (![self.vo.value isEqualToString:dtf.text]) {

        if vo?.value == "" {
            if ((vo?.optDict)?["nswl"] == "1") /* && ![to hasData] */ {
                // only if new entry
                let to = vo?.parentTracker as? trackerObj
                var sql = String(format: "select count(*) from voData where id=%ld and date<%d", Int(vo?.vid ?? 0), Int(to?.trackerDate?.timeIntervalSince1970 ?? 0))
                let v = to?.toQry2Int(sql) ?? 0
                if v > 0 {
                    sql = String(format: "select val from voData where id=%ld and date<%d order by date desc limit 1;", Int(vo?.vid ?? 0), Int(to?.trackerDate?.timeIntervalSince1970 ?? 0))
                    let r = to?.toQry2Str(sql)
                    dtf?.textColor = .lightGray
                    dtf?.backgroundColor = .darkGray
                    dtf?.text = r
                }
                //sql = nil;
            } else {
                dtf?.text = ""
                //DBGLog(@"reset dtf.txt to empty");
            }
        } else {

            if #available(iOS 13.0, *) {
                dtf?.backgroundColor = .secondarySystemBackground
                dtf?.textColor = .label
            } else {
                dtf?.backgroundColor = .white
                dtf?.textColor = .black
            }
            dtf?.text = vo?.value
        }

        //DBGLog(@"dtf: vo val= %@  dtf.text= %@", self.vo.value, self.dtf.text);
        //}

        DBGLog("number voDisplay: %@", dtf?.text)
        return dtf
    }

    override func update(_ instr: String?) -> String? {
        // confirm textfield not forgotten
        if ((nil == dtf) /* NOT self.dtf as we want to test if is instantiated */) || !(instr == "") {
            return instr
        }
        var cpy: String?
        safeDispatchSync({ [self] in
            cpy = dtf?.text ?? ""
        })
        return cpy
    }

    override func voGraphSet() -> [AnyHashable]? {
        return voState.voGraphSetNum()
    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {

        if nil == (vo?.optDict)?["nswl"] {
            (vo?.optDict)?["nswl"] = NSWLDFLT ? "1" : "0"
        }

        if nil == (vo?.optDict)?["autoscale"] {
            (vo?.optDict)?["autoscale"] = AUTOSCALEDFLT ? "1" : "0"
        }

        if nil == (vo?.optDict)?["numddp"] {
            (vo?.optDict)?["numddp"] = "\(NUMDDPDFLT)"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String?) -> Bool {

        let val = (vo?.optDict)?[key ?? ""] as? String
        if nil == val {
            return true
        }

        if ((key == "nswl") && (val == NSWLDFLT ? "1" : "0")) || ((key == "autoscale") && (val == AUTOSCALEDFLT ? "1" : "0")) || ((key == "numddp") && (Int(val ?? "") ?? 0 == NUMDDPDFLT)) {
            vo?.optDict?.removeValue(forKey: key)
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC?) {

        var frame = CGRect(x: MARGIN, y: ctvovc?.lasty ?? 0.0, width: 0.0, height: 0.0)

        var labframe = ctvovc?.configLabel("Start with last saved value:", frame: frame, key: "swlLab", addsv: true)
        frame = CGRect(x: (labframe?.size.width ?? 0.0) + MARGIN + SPACE, y: frame.origin.y, width: labframe?.size.height ?? 0.0, height: labframe?.size.height ?? 0.0)
        frame = ctvovc?.configCheckButton(
            frame,
            key: "swlBtn",
            state: (vo?.optDict)?["nswl"] == "1",
            addsv: true) ?? CGRect.zero
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        frame = ctvovc?.yAutoscale(frame) ?? CGRect.zero

        frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN

        labframe = ctvovc?.configLabel("graph decimal places (-1 auto):", frame: frame, key: "numddpLab", addsv: true)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        let tfWidth = "99999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovc?.lfHeight ?? 0.0 // self.labelField.frame.size.height; // lab.frame.size.height;

        frame = ctvovc?.configTextField(
            frame,
            key: "numddpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(NUMDDPDFLT)",
            text: (vo?.optDict)?["numddp"] as? String,
            addsv: true) ?? CGRect.zero


        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        //-- title label

        labframe = ctvovc?.configLabel("Other options:", frame: frame, key: "noLab", addsv: true)

        ctvovc?.lasty = frame.origin.y + (labframe?.size.height ?? 0.0) + MARGIN

        super.voDrawOptions(ctvovc)
    }

    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        [self transformVO_num:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> Any? {
        return vogd?.initAsNum(vo)
    }
}