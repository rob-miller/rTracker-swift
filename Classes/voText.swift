//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voText.swift
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
//  voText.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit

class voText: voState, UITextFieldDelegate {
    /*{
        UITextField *dtf;
    }*/

    private var _dtf: UITextField?
    var dtf: UITextField {
        //safeDispatchSync({ [self] in
        if self._dtf != nil && self._dtf?.frame.size.width != vosFrame.size.width {
            self._dtf = nil // first time around thinks size is 320, handle larger devices
        }
        // })
        
        if nil == _dtf {
            DBGLog(String("init \(vo.valueName) : x=\(vosFrame.origin.x) y=\(vosFrame.origin.y) w=\(vosFrame.size.width) h=\(vosFrame.size.height)"))
            _dtf = UITextField(frame: vosFrame)
            

            _dtf?.textColor = .label
            _dtf?.backgroundColor = .secondarySystemBackground
            
            _dtf?.borderStyle = .roundedRect //Bezel;
            _dtf?.font = PrefBodyFont //[UIFont systemFontOfSize:17.0];
            _dtf?.autocorrectionType = .no // no auto correction support
            
            _dtf?.keyboardType = .default // use the full keyboard
            _dtf?.placeholder = "<enter text>"
            
            _dtf?.returnKeyType = .done
            
            _dtf?.clearButtonMode = .whileEditing // has a clear 'x' button to the right
            
            //dtf.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
            _dtf?.delegate = self // let us be the delegate so we know when the keyboard's "Done" button is pressed
            
            // Add an accessibility label that describes what the text field is for.
            _dtf?.accessibilityLabel = NSLocalizedString("NormalTextField", comment: "")
            _dtf?.text = ""
            _dtf?.addTarget(self, action: #selector(voNumber.textFieldDidChange(_:)), for: .editingChanged)
            
            _dtf?.accessibilityIdentifier = "\(self.tvn())_textfield"
        }
    
        return _dtf!
    }
    var startStr: String?
    private var localCtvovc: configTVObjVC?
    
    override func getValCap() -> Int {
        // NSMutableString size for value
        return 32
    }

    override func getNumVal() -> Double {
        if vo.value == "" {
            return 0.0
        }
        return 1.0
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //DBGLog(@"tf begin editing");
        startStr = textField.text
        vo.parentTracker.activeControl = textField
    }

    @objc func textFieldDidChange(_ textField: UITextField?) {
        //[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        //DBGLog(@"tf end editing");
        if startStr != textField.text {
            vo.value = textField.text ?? ""
            //textField.textColor = .label  //[UIColor blackColor];
            NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
            startStr = nil
        }
        vo.parentTracker.activeControl = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // the user pressed the "Done" button, so dismiss the keyboard
        //DBGLog(@"textField done: %@", textField.text);
        textField.resignFirstResponder()
        return true
    }

    override func resetData() {
        if nil != _dtf  && !vo.parentTracker.loadingDbData {
            // not self, do not instantiate
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

        _dtf = nil  // force recreate
        
        if vo.optDict["otsrc"] == "1" {
            if let xrslt = vo.vos?.getOTrslt() {
                vo.value = xrslt
            } else {
                vo.value = ""
            }
            addExternalSourceOverlay(to: dtf)  // no taps

        }
        if vo.value != dtf.text {
            safeDispatchSync({ [self] in
                dtf.text = vo.value
            })
            DBGLog(String("dtf: vo val= \(vo.value) dtf txt= \(dtf.text)"))
        }

        DBGLog(String("textfield voDisplay: \(dtf.text)"))
        return dtf
    }

    override func update(_ instr: String?) -> String {
        // Return input string if textfield isn't instantiated yet or if input string is non-empty
        if (nil == _dtf) || (instr?.isEmpty == false) {  /* NOT self.dtf as we want to test if is instantiated */
            return instr ?? ""
        }
        
        var textFieldContent: String = ""
        safeDispatchSync { [self] in
            textFieldContent = dtf.text ?? ""
        }
        return textFieldContent
    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {


        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {
        /*
            NSString *val = [self.vo.optDict objectForKey:key];
            if (nil == val) 
                return YES;
            if (([key isEqualToString:@"shrinkb"] && [val isEqualToString:(SHRINKBDFLT ? @"1" : @"0")])
                ) {
                [self.vo.optDict removeObjectForKey:key];
                return YES;
            }
            */
        return super.cleanOptDictDflts(key)
    }

    @objc func forwardToConfigOtherTrackerSrcView() {
        localCtvovc?.configOtherTrackerSrcView()
    }
    
    override func voDrawOptions(_ ctvovc: configTVObjVC) {
        
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)
        
        var labframe = ctvovc.configLabel(
            "Options:",
            frame: CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0),
            key: "gooLab",
            addsv: true)

        localCtvovc = ctvovc
        
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        labframe = ctvovc.configLabel("Other Tracker source: ", frame: frame, key: "otsLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "otsBtn",
            state: vo.optDict["otsrc"] == "1",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        let source = self.vo.optDict["otTracker"] ?? ""
        let value = self.vo.optDict["otValue"] ?? ""
        let str = (!source.isEmpty && !value.isEmpty) ? "\(source):\(value)" : "Configure"
        
        frame = ctvovc.configActionBtn(frame, key: "otSelBtn", label: str, target: self, action: #selector(forwardToConfigOtherTrackerSrcView))
        ctvovc.switchUpdate(okey: "otsrc", newState: vo.optDict["otsrc"] == "1")
        
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        
        labframe = ctvovc.configLabel("Other options:", frame: frame, key: "noLab", addsv: true)
        ctvovc.lasty += labframe.size.height + MARGIN
        super.voDrawOptions(ctvovc)
    }

    // MARK: -
    // MARK: graph display
    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        [self transformVO_note:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> vogd {
        return vogd(vo).initAsNote(vo)
    }
}
