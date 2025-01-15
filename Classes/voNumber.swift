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
import UIKit
import SwiftUI

class voNumber: voState, UITextFieldDelegate {
    /*{
        UITextField *dtf;
    }*/


    private var _dtf: UITextField?
    var rthk = rtHealthKit.shared
    
    var dtf: UITextField {
        //safeDispatchSync({ [self] in
        if _dtf?.frame.size.width != vosFrame.size.width {
            _dtf = nil // first time around thinks size is 320, handle larger devices
        }
        //})
        
        if nil == _dtf {
            DBGLog(String("init \(vo.valueName) : x=\(vosFrame.origin.x) y=\(vosFrame.origin.y) w=\(vosFrame.size.width) h=\(vosFrame.size.height)"))
            _dtf = UITextField(frame: vosFrame)
            

            _dtf?.textColor = .label
            _dtf?.backgroundColor = .secondarySystemBackground

            
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
            _dtf?.accessibilityHint = NSLocalizedString("enter a number", comment: "")
            _dtf?.text = ""
            _dtf?.accessibilityIdentifier = "\(self.tvn())_numberfield"
            _dtf?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
        //DBGLog(@"num dtf rc= %d",[dtf retainCount]);
    
        return _dtf!
    }
    
    
    var startStr: String?
    var ctvovcp: configTVObjVC?
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //DBGLog(@"number tf begin editing vid=%ld",(long)self.vo.vid);
        startStr = textField.text
        vo.parentTracker.activeControl = textField
    }

    @objc func textFieldDidChange(_ textField: UITextField?) {
        // not sure yet - lot of actions for every char when just want to enable 'save'
        //[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        DBGLog(String("vo.value= \(vo.value)"))
        DBGLog(String("tf.text= \(textField.text)"))
        DBGLog(String("tf end editing vid=\(Int(vo.vid)) vo.value=\(vo.value) tf.text=\(textField.text)"))

        if startStr != textField.text {
            vo.value = textField.text ?? ""
            //textField.textColor = [UIColor blackColor];
            //textField.backgroundColor = [UIColor whiteColor];
            NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
            startStr = nil
        }

        vo.parentTracker.activeControl = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // the user pressed the "Done" button, so dismiss the keyboard
        //DBGLog(@"textField done: %@  vid=%d", textField.text,self.vo.vid);
        // [self tfvoFinEdit:textField];  // textFieldDidEndEditing will be called, just dismiss kybd here
        DBGLog(String("tf should return vid=\(Int(vo.vid)) vo.value=\(vo.value) tf.text=\(textField.text)"))

        textField.resignFirstResponder()
        return true
    }

    @objc func selectDoneButton() {
        dtf.resignFirstResponder()
    }

    @objc func selectMinusButton() {
        dtf.text = rTracker_resource.negateNumField(dtf.text)
    }

    override func resetData() {
        if nil != _dtf {
            // not self as don't want to instantiate prematurely
            if Thread.isMainThread {
                dtf.text = ""
            } else {
                DispatchQueue.main.async(execute: { [self] in
                    dtf.text = ""
                })
            }
        }
        vo.useVO = true
    }

    override func voDisplay(_ bounds: CGRect) -> UIView {
        vosFrame = bounds

        //if (![self.vo.value isEqualToString:dtf.text]) {

        if vo.value == "" {
            if (vo.optDict["nswl"] == "1") /* && ![to hasData] */ {
                // only if new entry
                let to = vo.parentTracker
                var sql = String(format: "select count(*) from voData where id=%ld and date<%d", Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
                let v = to.toQry2Int(sql:sql)!
                if v > 0 {
                    sql = String(format: "select val from voData where id=%ld and date<%d order by date desc limit 1;", Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
                    let r = to.toQry2Str(sql:sql)
                    dtf.textColor = .lightGray
                    dtf.backgroundColor = .darkGray
                    dtf.text = r
                }
                //sql = nil;
            } else {
                dtf.text = ""
                //DBGLog(@"reset dtf.txt to empty");
            }
        } else {
            DispatchQueue.main.async { [self] in
                dtf.backgroundColor = .secondarySystemBackground
                dtf.textColor = .label
                dtf.text = vo.value
            }
        }

        //DBGLog(@"dtf: vo val= %@  dtf.text= %@", self.vo.value, self.dtf.text);
        //}

        DBGLog(String("number voDisplay: \(dtf.text)"))
        return dtf
    }

    override func voTVCellHeight() -> CGFloat {
        return minLabelHeight(super.voTVCellHeight())
    }
    
    override func update(_ instr: String) -> String {
        // confirm textfield not forgotten
        if ((nil == _dtf) /* NOT self.dtf as we want to test if is instantiated */) || !(instr == "") {
            return instr
        }
        var cpy: String?
        safeDispatchSync({ [self] in
            cpy = dtf.text ?? ""
        })
        return cpy!
    }

    override func voGraphSet() -> [String] {
        return voState.voGraphSetNum()
    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {

        if nil == vo.optDict["nswl"] {
            vo.optDict["nswl"] = NSWLDFLT ? "1" : "0"
        }

        if nil == vo.optDict["ahksrc"] {
            vo.optDict["ahksrc"] = AHKSRCDFLT ? "1" : "0"
        }
        
        if nil == vo.optDict["autoscale"] {
            vo.optDict["autoscale"] = AUTOSCALEDFLT ? "1" : "0"
        }

        if nil == vo.optDict["numddp"] {
            vo.optDict["numddp"] = "\(NUMDDPDFLT)"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "nswl") && (val == (NSWLDFLT ? "1" : "0")))
            || ((key == "ahksrc") && ((val == (AHKSRCDFLT ? "1" : "0") || (vo.optDict["ahSource"] == nil))))  // unspecified ahSource disallowed
            || ((key == "autoscale") && (val == (AUTOSCALEDFLT ? "1" : "0")))
            || ((key == "numddp") && (Int(val ?? "") ?? 0 == NUMDDPDFLT)) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if key == "ahSource" && (vo.optDict["ahksrc"] ?? "0") == "0" {  // clear ahSource value if ah source disabled
            vo.optDict.removeValue(forKey: key)
            return true
        }
        
        return super.cleanOptDictDflts(key)
    }

    override func loadHKdata(dispatchGroup: DispatchGroup?) {
        let to = vo.parentTracker

        guard let srcName = vo.optDict["ahSource"] else {
            DBGErr("no ahSource specified for valueObj \(vo.valueName ?? "no name")")
            return
        }

        dispatchGroup?.enter()  // wait for getHealthkitDates processing overall
        
        // Create a separate DispatchGroup for getHealthKitDates processing
        let hkDispatchGroup = DispatchGroup()

        hkDispatchGroup.enter()
        rthk.getHealthKitDates(for: srcName) { hkDates in
            let existingDatesQuery = """
            SELECT date
            FROM trkrData
            """
            let existingDates = Set(to.toQry2AryI(sql: existingDatesQuery))
            
            let fourHours: TimeInterval = 4 * 60 * 60

            // Filter dates that don't match within ±4 hours of existing dates
            let newDates = hkDates.filter { hkDate in
                !existingDates.contains { abs(hkDate - Double($0)) <= fourHours }
            }
            
            // Insert the new dates into trkrData
            for newDate in newDates {
                let sql = "insert into trkrData (date, minpriv) values (\(Int(newDate)), 1)"
                to.toExecSql(sql: sql)
            }
            
            DBGLog("Inserted \(newDates.count) new dates into trkrData.")
            hkDispatchGroup.leave() // Leave the group after insertion is complete
        }

        // Wait for getHealthKitDates processing to complete before proceeding
        hkDispatchGroup.notify(queue: .main) { [self] in
            DBGLog("HealthKit dates processed, continuing with loadHKdata.")

            // Fetch dates from trkrData for processing
            let sql = """
            SELECT trkrData.date
            FROM trkrData
            WHERE NOT EXISTS (
                SELECT 1
                FROM voData
                WHERE voData.date = trkrData.date
                  AND voData.id = \(Int(vo.vid))
            )
            AND NOT EXISTS (
                SELECT 1
                FROM voHKfail
                WHERE voHKfail.date = trkrData.date
                  AND voHKfail.id = \(Int(vo.vid))
            );
            """
            let dateSet = to.toQry2AryI(sql: sql)
            
            DBGLog("Query complete, count is \(dateSet.count)")

            for dat in dateSet {
                dispatchGroup?.enter() // Enter the group for each query

                let targD = Date(timeIntervalSince1970: TimeInterval(dat))
                rthk.performHealthQuery(
                    displayName: srcName,
                    targetDate: dat,
                    specifiedUnit: nil
                ) { results in
                    if results.isEmpty {
                        print("No results found for \(targD).")
                        let sql = "insert into voHKfail (id, date) values (\(self.vo.vid), \(dat))"
                        to.toExecSql(sql: sql)
                    } else {
                        for result in results {
                            print("Target: \(targD) results - Date: \(result.date), Value: \(result.value), Unit: \(result.unit)")
                        }
                        let result = results.last!
                        let sql = "insert into voData (id, date, val) values (\(self.vo.vid), \(dat), \(result.value))"
                        to.toExecSql(sql: sql)
                    }

                    dispatchGroup?.leave() // Leave the group after this query is processed
                }
            }
            DBGLog("Done loadHKdata with \(dateSet.count) records.")
            dispatchGroup?.leave()  // done with enter before getHealthkitDates processing overall
        }
    }


    
    @objc func configAppleHealthView() {
        DBGLog("config Apple Health view")
        
        let hostingController = UIHostingController(
            rootView: ahViewController(
                selectedChoice: vo.optDict["ahSource"] ?? "None",
                onDismiss: { [self] updatedChoice in
                    vo.optDict["ahSource"] = "None" == updatedChoice ? nil : updatedChoice
                    if let button = ctvovcp?.scroll.subviews.first(where: { $0 is UIButton && $0.accessibilityIdentifier == "configtv_ahSelBtn" }) as? UIButton {
                        print("ahSelect view returned: \(updatedChoice) optDict is \(vo.optDict["ahSource"] ?? "nil")")
                        DispatchQueue.main.async {
                            button.setTitle(self.vo.optDict["ahSource"] ?? "Configure", for: .normal)
                            button.sizeToFit()
                        }
                    }
                    //print("ahSelect view returned: \(updatedChoice) optDict is \(vo.optDict["ahSource"] ?? "nil")")
                }
            )
        )
        hostingController.modalTransitionStyle = .flipHorizontal
        hostingController.modalPresentationStyle = .automatic
        
        // Present the hosting controller
        ctvovcp?.present(hostingController, animated: true)
    }
    
    override func voDrawOptions(_ ctvovc: configTVObjVC) {
        ctvovcp = ctvovc  // save reference so can display config gui
        
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)

        var labframe = ctvovc.configLabel("Start with last saved value: ", frame: frame, key: "swlLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "swlBtn",
            state: vo.optDict["nswl"] == "1",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        frame = ctvovc.yAutoscale(frame)

        //frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN

        labframe = ctvovc.configLabel("graph decimal places (-1 for auto): ", frame: frame, key: "numddpLab", addsv: true)

        frame.origin.x += labframe.size.width + SPACE
        let tfWidth = "99999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovc.lfHeight)

        frame = ctvovc.configTextField(
            frame,
            key: "numddpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(NUMDDPDFLT)",
            text: vo.optDict["numddp"],
            addsv: true)


        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        labframe = ctvovc.configLabel("Apple Health source: ", frame: frame, key: "ahsLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "ahsBtn",
            state: vo.optDict["ahksrc"] == "1",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        
        frame = ctvovc.configActionBtn(frame, key: "ahSelBtn", label: vo.optDict["ahSource"] ?? "Configure", target: self, action: #selector(configAppleHealthView))
        ctvovc.switchUpdate(okey: "ahksrc", newState: vo.optDict["ahksrc"] == "1")
        
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        
        labframe = ctvovc.configLabel("Other options:", frame: frame, key: "noLab", addsv: true)

        ctvovc.lasty = frame.origin.y + labframe.size.height + MARGIN

        super.voDrawOptions(ctvovc)
    }

    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        [self transformVO_num:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> vogd {
        return vogd(vo).initAsNum(vo)
    }
}
