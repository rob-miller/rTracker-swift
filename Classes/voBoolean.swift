//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voBoolean.swift
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
//  voBoolean.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit

class voBoolean: voState {

    private var _bSwitch: UISwitch?  // UIButton?
    var bSwitch: UISwitch? {

        if nil == _bSwitch {
            _bSwitch = rTracker_resource.getSwitch(vosFrame)
            _bSwitch?.addTarget(self, action: #selector(boolBtnAction(_:)), for: .valueChanged) // .touchDown)
            _bSwitch?.tag = kViewTag // tag this view for later so we can remove it from recycled table cells
            _bSwitch?.accessibilityIdentifier = "\(self.tvn())_switch"
        }
        return _bSwitch
    }

    private var localCtvovc: configTVObjVC?

    @objc func boolBtnAction(_ bSwitch: UIButton?) {
        // default is unchecked or nil // 25.i.14 use assigned val // was "so only certain is if =1" ?
        if vo.value == "" {
            let bv = vo.optDict["boolval"]
            //if (nil == bv) {
            //bv = BOOLVALDFLTSTR;
            //[self.vo.optDict setObject:bv forKey:@"boolval"];
            //}
            vo.value = bv!
            rTracker_resource.setSwitch(self.bSwitch!, colr: rTracker_resource.colorSet()[Int(vo.optDict["btnColr"]!)!])
            if "1" == vo.optDict["setstrackerdate"] {
                vo.setTrackerDateToNow()
            }
        } else {
            vo.value = ""
            rTracker_resource.clrSwitch(self.bSwitch!, colr: .tertiarySystemBackground)
        }

        //self.vo.display = nil; // so will redraw this cell only
        NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
    }

    override func voDisplay(_ bounds: CGRect) -> UIView {
        vosFrame = bounds

        if vo.optDict["otsrc"] == "1" {
            if let xrslt = vo.vos?.getOTrslt() {
                if xrslt.isEmpty {  // Empty string
                    vo.value = ""
                } else if let numericValue = Double(xrslt) { // It's a number in string form
                    vo.value = numericValue < 0.5 ? "" : "1"
                } else { // It's a non-empty text string that's not a number
                    vo.value = "1"
                }
            } else {  // xrslt is nil
                vo.value = ""
            }
            
            addExternalSourceOverlay(to: bSwitch!)  // no taps
        }
        if vo.value == "" {
            rTracker_resource.clrSwitch(bSwitch!, colr: .tertiarySystemBackground)
        } else {
            rTracker_resource.setSwitch(bSwitch!, colr: rTracker_resource.colorSet()[Int(vo.optDict["btnColr"]!)!])
        }

        DBGLog(String("bool data= \(vo.value)"))
        return bSwitch!
    }

    override func voGraphSet() -> [String] {
        return ["dots", "bar"]
    }

    // MARK: -
    // MARK: graph display
    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        [self transformVO_bool:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> vogd {
        return vogd(vo).initAsNum(vo)
    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {
        let bv = vo.optDict["boolval"]
        if (nil == bv) || ("" == bv) {
            vo.optDict["boolval"] = BOOLVALDFLTSTR
        }
        let std = vo.optDict["setstrackerdate"]
        if (nil == std) || ("" == std) {
            vo.optDict["setstrackerdate"] = SETSTRACKERDATEDFLT ? "1" : "0"
        }
        let bc = vo.optDict["btnColr"]
        if (nil == bc) || ("" == bc) {
            vo.optDict["btnColr"] = BOOLBTNCOLRDFLTSTR
        }
        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "boolval") && (Float(val!) == Float(BOOLVALDFLT)))
            || ((key == "setstrackerdate") && (val == (SETSTRACKERDATEDFLT ? "1" : "0")))
            || ((key == "btnColr") && (val == BOOLBTNCOLRDFLTSTR)) {
            vo.optDict.removeValue(forKey: key)
            //DBGLog(@"cleanDflt for bool: %@",key);
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    @objc func boolColorButtonAction(_ btn: UIButton?) {
        var col = Int(vo.optDict["btnColr"]!)!
        col += 1
        if col >= rTracker_resource.colorSet().count {
            col = 0
        }
        vo.optDict["btnColr"] = String(format: "%ld", col)
        btn?.backgroundColor = rTracker_resource.colorSet()[col]
    }
    
    @objc func forwardToConfigOtherTrackerSrcView() {
        localCtvovc?.configOtherTrackerSrcView()
    }
    
    override func voDrawOptions(_ ctvovc: configTVObjVC) {
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)

        var labframe = ctvovc.configLabel("stored value:", frame: frame, key: "bvLab", addsv: true)

        localCtvovc = ctvovc
        
        frame.origin.x = labframe.size.width + MARGIN + SPACE
        let tfWidth = "9999999999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovc.lfHeight)

        frame = ctvovc.configTextField(
            frame,
            key: "bvalTF",
            target: nil,
            action: nil,
            num: true,
            place: BOOLVALDFLTSTR,
            text: vo.optDict["boolval"],
            addsv: true)



        // sets tracker date option

        frame.origin.x = MARGIN
        frame.origin.y += labframe.size.height + MARGIN

        labframe = ctvovc.configLabel("Sets tracker date:", frame: frame, key: "stdLab", addsv: true)

        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "stdBtn",
            state: (vo.optDict["setstrackerdate"] == "1") /* default:0 */,
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += labframe.size.height + MARGIN

        labframe = ctvovc.configLabel("Active color:", frame: frame, key: "btnColrLab", addsv: true)

        frame.origin.x += labframe.size.width + MARGIN
        frame.size.width = frame.size.height

        let btn = UIButton(type: .custom)
        btn.frame = frame
        btn.layer.cornerRadius = 8.0
        btn.layer.masksToBounds = true
        btn.layer.borderWidth = 1.0
        var bc = vo.optDict["btnColr"]
        if bc == nil {
            bc = BOOLBTNCOLRDFLTSTR
            vo.optDict["btnColr"] = BOOLBTNCOLRDFLTSTR
        }
        btn.backgroundColor = rTracker_resource.colorSet()[Int(bc!)!]

        btn.titleLabel?.font = PrefBodyFont

        btn.addTarget(self, action: #selector(boolColorButtonAction(_:)), for: .touchDown)
        ctvovc.wDict["boolColrBtn"] = btn
        //[ctvovc.view addSubview:btn];
        ctvovc.scroll.addSubview(btn)


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

        ctvovc.lasty = frame.origin.y + labframe.size.height + MARGIN

        super.voDrawOptions(ctvovc)
    }
    
    override func voTVCellHeight() -> CGFloat {
        //return CELL_HEIGHT_TALL;
        DBGLog(String("\(bSwitch!.frame.size.height) \(3 * MARGIN) \(vo.getLabelSize().height) \(vo.getLongTitleSize().height)"))
        return bSwitch!.frame.size.height + MARGIN   // (3 * MARGIN) // + vo.getLabelSize().height + vo.getLongTitleSize().height
    }

    /* rtm here : export value option -- need to parse and match value if choice did not match
     */

    override func mapCsv2Value(_ inCsv: String) -> String {

        if Float(vo.optDict["boolval"] ?? "") != Float(inCsv) {
            vo.optDict["boolval"] = inCsv
        }
        return inCsv
    }
}
