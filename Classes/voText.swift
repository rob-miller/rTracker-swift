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
            
            if #available(iOS 13.0, *) {
                _dtf?.textColor = .label
                _dtf?.backgroundColor = .secondarySystemBackground
            } else {
                _dtf?.textColor = .black
                _dtf?.backgroundColor = .white
            }
            
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
        }
    
        return _dtf!
    }
    var startStr: String?

    override func getValCap() -> Int {
        // NSMutableString size for value
        return 32
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
            vo.value = textField.text
            //textField.textColor = [UIColor blackColor];
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
        if nil != _dtf {
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

        if vo.value != dtf.text {
            safeDispatchSync({ [self] in
                dtf.text = vo.value
            })
            DBGLog(String("dtf: vo val= \(vo.value) dtf txt= \(dtf.text)"))
        }

        DBGLog(String("textfield voDisplay: \(dtf.text)"))
        return dtf
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

    override func voDrawOptions(_ ctvovc: configTVObjVC?) {
        let labframe = ctvovc?.configLabel(
            "Options:",
            frame: CGRect(x: MARGIN, y: ctvovc?.lasty ?? 0.0, width: 0.0, height: 0.0),
            key: "gooLab",
            addsv: true)

        ctvovc?.lasty += (labframe?.size.height ?? 0.0) + MARGIN
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
