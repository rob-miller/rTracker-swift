//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voSlider.swift
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
//  voSlider.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit

class voSlider: voState {

    private var _sliderCtl: UISlider?
    var sdflt: CGFloat = 0.0
    var sliderCtl: UISlider? {
        if _sliderCtl != nil && _sliderCtl?.frame.size.width != vosFrame.size.width {
            _sliderCtl = nil // first time around thinks size is 320, handle larger devices
        }

        if nil == _sliderCtl {
            // DBGLog(@"create sliderCtl");
            //CGRect frame = CGRectMake(174.0, 12.0, 120.0, kSliderHeight);

            _sliderCtl = UISlider(frame: vosFrame)
            _sliderCtl?.addTarget(self, action: #selector(sliderAction(_:)), for: .valueChanged)

            _sliderCtl?.addTarget(self, action: #selector(sliderTouchUp(_:)), for: .touchUpInside)
            _sliderCtl?.addTarget(self, action: #selector(sliderTouchUp(_:)), for: .touchUpOutside)
            _sliderCtl?.addTarget(self, action: #selector(sliderTouchDown(_:)), for: .touchDown)
            /*
                    if ([(NSString*) [self.vo.optDict objectForKey:@"integerstepsb"] isEqualToString:@"1"]) {
                        [sliderCtl addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
                        [sliderCtl addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
                    }
            */
            // in case the parent view draws with a custom color or gradient, use a transparent color
            _sliderCtl?.backgroundColor = .clear

            let smin = vo.optDict["smin"] ?? String(SLIDRMINDFLT)
            let smax = vo.optDict["smax"] ?? String(SLIDRMAXDFLT)
            sdflt = CGFloat((vo.optDict["sdflt"] as? NSString)?.doubleValue ?? Double(SLIDRDFLTDFLT))

            _sliderCtl?.minimumValue = Float(smin)!
            _sliderCtl?.maximumValue = Float(smax)!
            _sliderCtl?.isContinuous = true
            // Add an accessibility label that describes the slider.
            //[sliderCtl setAccessibilityLabel:NSLocalizedString(@"StandardSlider", @"")];
            _sliderCtl?.accessibilityLabel = "\(vo.valueName ?? "") slider"
            _sliderCtl?.accessibilityIdentifier = "\(self.tvn())_slider"

        }

        return _sliderCtl
    }

    override init(vo valo: valueObj) {
        super.init(vo: valo)
        vo.useVO = false
    }

    override func resetData() {
        vo.useVO = false
    }

    override func voTVCell(_ tableView: UITableView) -> UITableViewCell {
        return super.voTVEnabledCell(tableView)
    }

    override func voTVCellHeight() -> CGFloat {
        //return CELL_HEIGHT_TALL;
        DBGLog(String("\(sliderCtl!.frame.size.height) \(3 * MARGIN) \(vo.getLabelSize().height) \(vo.getLongTitleSize().height)"))
        return sliderCtl!.frame.size.height + (3 * MARGIN) + vo.getLabelSize().height + vo.getLongTitleSize().height
    }

    @objc func sliderAction(_ sender: UISlider?) {
        DBGLog(String("slider action value = \((sender)?.value ?? 0.0)"))
        /*
        	//
        	//[self.vo.value setString:[NSString stringWithFormat:@"%f",sender.value]];
            DBGLog(@"sender action value: %f",sender.value);
        	DBGLog(@"slider action value = %f", self.sliderCtl.value);
            DBGLog(@"prev val= %@",self.vo.value);
            DBGLog(@"tracking= %d  touchinside= %d",[sender isTracking], [sender isTouchInside]);
            //if (sender.value == 0.0f) {
            if ((![sender isTracking]) && [sender isTouchInside] && (sender.value == 0.0f)) {
                DBGLog(@"poo...");
                return;
            }
            */

        if !vo.useVO {
            vo.enableVO()
        }

        if vo.optDict["integerstepsb"] == "1" {
            let slider = sender
            let ival = Int(Double(Int(slider?.value ?? 0)) + 0.5)
            slider?.setValue(Float(ival), animated: true)
        }
        vo.value = "\(sliderCtl?.value ?? 0.0)"

        //DBGLog(@"slider action value = %f valstr= %@ vs dbl= %f", ((UISlider *)sender).value, self.vo.value, [self.vo.value doubleValue]);

        NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
    }

    /*
    - (void)sliderTouchUp:(UISlider *)sender
    {
        UISlider *slider = (UISlider *)sender;
        int ival = (int) slider.value + 0.5;

        [slider setValue:(float) ival animated:YES];
        [self.vo.value setString:[NSString stringWithFormat:@"%f",self.sliderCtl.value]];

        DBGLog(@"slider touch up value = %f", slider.value);
    	[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
    }
    */

    @objc func sliderTouchUp(_ sender: UISlider?) {
        vo.parentTracker.swipeEnable = true
        DBGLog("*********slider up")
    }

    @objc func sliderTouchDown(_ sender: UISlider?) {
        vo.parentTracker.swipeEnable = false
        DBGLog("********slider down")
    }

    override func voDisplay(_ bounds: CGRect) -> UIView {
        vosFrame = bounds

        #if DEBUGLOG
        let vals = vo.value
        let valf = CGFloat(Float(vo.value) ?? 0.0)
        //trackerObj *pto = self.vo.parentTracker;

        DBGLog(String("voDisplay slider \(vo.valueName ?? "") vals= \(vals) valf= \(valf) -> slider.valf= \(sliderCtl?.value ?? 0.0)"))
        #endif

        //DBGLog(@"parent tracker date= %@",pto.trackerDate);
        if vo.value == "" {
            if vo.optDict["slidrswlb"] == "1" {
                let to = vo.parentTracker
                var sql = String(format: "select count(*) from voData where id=%ld and date<%d", Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
                let v = to.toQry2Int(sql:sql) ?? 0
                if v > 0 {
                    sql = String(format: "select val from voData where id=%ld and date<%d order by date desc limit 1;", Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
                    sliderCtl?.value = to.toQry2Float(sql:sql) ?? 0.0
                }
            } else {
                sliderCtl?.setValue(Float(sdflt), animated: false)
            }
        } else if sliderCtl?.value != Float(vo.value) ?? 0.0 {
            //self.sliderCtl.value = [self.vo.value floatValue];
            sliderCtl?.setValue(Float(vo.value) ?? 0.0, animated: false)
        }
        DBGLog(String("sliderCtl voDisplay: \(sliderCtl?.value ?? 0.0)"))
        //NSLog(@"sliderCtl voDisplay: %f", self.sliderCtl.value);
        return sliderCtl!
    }

    /*
    - (UIView*) voDisplay:(CGRect) bounds {
        DBGLog(@"create sliderCtl");
        //CGRect frame = CGRectMake(174.0, 12.0, 120.0, kSliderHeight);
        CGRect frame = bounds;
        UISlider *sliderCtl = [[UISlider alloc] initWithFrame:frame];
        [sliderCtl addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];

        // in case the parent view draws with a custom color or gradient, use a transparent color
        sliderCtl.backgroundColor = [UIColor clearColor];

        NSNumber *nsmin = [self.vo.optDict objectForKey:@"smin"];
        NSNumber *nsmax = [self.vo.optDict objectForKey:@"smax"];
        NSNumber *nsdflt = [self.vo.optDict objectForKey:@"sdflt"];

        CGFloat smin = (nsmin ? [nsmin floatValue] : SLIDRMINDFLT);
        CGFloat smax = (nsmax ? [nsmax floatValue] : SLIDRMAXDFLT);
        CGFloat sdflt = (nsdflt ? [nsdflt floatValue] : SLIDRDFLTDFLT);

        sliderCtl.minimumValue = smin;
        sliderCtl.maximumValue = smax;
        sliderCtl.continuous = YES;
        // Add an accessibility label that describes the slider.
        [sliderCtl setAccessibilityLabel:NSLocalizedString(@"StandardSlider", @"")];

        sliderCtl.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells

        if ([self.vo.value isEqualToString:@""]) {
            sliderCtl.value = sdflt;  
            //[self.sliderCtl setValue:self.sdflt animated:NO];
        } else {
            sliderCtl.value = [self.vo.value floatValue];
            //[self.sliderCtl setValue:[self.vo.value floatValue] animated:NO];
        }

        return [sliderCtl autorelease];
    }
     */


    override func voGraphSet() -> [String] {
        return voState.voGraphSetNum()
    }

    override func setOptDictDflts() {
        if nil == vo.optDict["smin"] {
            vo.optDict["smin"] = String(format: "%3.1f", SLIDRMINDFLT)
        }
        if nil == vo.optDict["smax"] {
            vo.optDict["smax"] = String(format: "%3.1f", SLIDRMAXDFLT)
        }
        if nil == vo.optDict["sdflt"] {
            vo.optDict["sdflt"] = String(format: "%3.1f", SLIDRDFLTDFLT)
        }

        if nil == vo.optDict["integerstepsb"] {
            vo.optDict["integerstepsb"] = INTEGERSTEPSBDFLT ? "1" : "0"
        }
        if nil == vo.optDict["defaultenabledb"] {
            vo.optDict["defaultenabledb"] = DEFAULTENABLEDBDFLT ? "1" : "0"
        }

        if nil == vo.optDict["slidrswlb"] {
            vo.optDict["slidrswlb"] = SLIDRSWLBDFLT ? "1" : "0"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        guard let val = vo.optDict[key] else {
            return true
        }

        if ((key == "smin") && (Float(val) == f(SLIDRMINDFLT)))
            || ((key == "smax") && (Float(val) == f(SLIDRMAXDFLT)))
            || ((key == "sdflt") && (Float(val) == f(SLIDRDFLTDFLT))) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if (key == "integerstepsb") && (val == (INTEGERSTEPSBDFLT ? "1" : "0")) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if (key == "defaultenabledb") && (val == (DEFAULTENABLEDBDFLT ? "1" : "0")) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if (key == "slidrswlb") && (val == (SLIDRSWLBDFLT ? "1" : "0")) {
            vo.optDict.removeValue(forKey: key)
            return true
        }



        return super.cleanOptDictDflts(key)
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC) {
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)

        var labframe = ctvovc.configLabel("Slider range:", frame: frame, key: "srLab", addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += labframe.size.height + MARGIN

        labframe = ctvovc.configLabel("min:", frame: frame, key: "sminLab", addsv: true)

        frame.origin.x = labframe.size.width + MARGIN + SPACE
        let tfWidth = "9999999999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovc.lfHeight

        frame = ctvovc.configTextField(
            frame,
            key: "sminTF",
            target: nil,
            action: nil,
            num: true,
            place: String(format: "%3.1f", SLIDRMINDFLT),
            text: vo.optDict["smin"],
            addsv: true)

        frame.origin.x += tfWidth + MARGIN
        labframe = ctvovc.configLabel(" max:", frame: frame, key: "smaxLab", addsv: true)

        frame.origin.x += labframe.size.width + SPACE
        frame.size.width = tfWidth
        frame.size.height = ctvovc.lfHeight

        frame = ctvovc.configTextField(
            frame,
            key: "smaxTF",
            target: nil,
            action: nil,
            num: true,
            place: String(format: "%3.1f", SLIDRMAXDFLT),
            text: vo.optDict["smax"],
            addsv: true)

        frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = 8 * MARGIN

        labframe = ctvovc.configLabel("default:", frame: frame, key: "sdfltLab", addsv: true)

        frame.origin.x += labframe.size.width + SPACE
        frame.size.width = tfWidth
        frame.size.height = ctvovc.lfHeight

        frame = ctvovc.configTextField(
            frame,
            key: "sdfltTF",
            target: nil,
            action: nil,
            num: true,
            place: String(format: "%3.1f", SLIDRDFLTDFLT),
            text: vo.optDict["sdflt"],
            addsv: true)

        frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN
        //-- title label

        labframe = ctvovc.configLabel("Other options:", frame: frame, key: "soLab", addsv: true)


        frame.origin.x = MARGIN
        frame.origin.y += labframe.size.height + MARGIN

        labframe = ctvovc.configLabel("integer steps:", frame: frame, key: "sisLab", addsv: true)

        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configCheckButton(
            frame,
            key: "sisBtn",
            state: (vo.optDict["integerstepsb"] == "1") /* default:0 */,
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += labframe.size.height + MARGIN

        labframe = ctvovc.configLabel("starts with last:", frame: frame, key: "sswlLab", addsv: true)

        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configCheckButton(
            frame,
            key: "sswlBtn",
            state: (vo.optDict["slidrswlb"] == "1") /* default:0 */,
            addsv: true)



        /* 
             * need more thought here -- if slider is enabled by default, can't open and leave without asking to save ?
             *  /

            frame.origin.x = MARGIN;
        	frame.origin.y += labframe.size.height + MARGIN;

            labframe = [ctvovc configLabel:@"default enabled:" frame:frame key:@"sdeLab" addsv:YES];

            frame = (CGRect) {labframe.size.width+MARGIN+SPACE, frame.origin.y,labframe.size.height,labframe.size.height};

            frame = [ctvovc configCheckButton:frame
                                  key:@"sdeBtn"
                                state:[(self.vo.optDict)[@"defaultenabledb"] isEqualToString:@"1"] // default:0
                                addsv:YES
             ];
            */



        ctvovc.lasty = frame.origin.y + labframe.size.height + MARGIN
        super.voDrawOptions(ctvovc)
    }

    override func update(_ instr: String) -> String {
        // place holder so fn can update on access
        if vo.useVO {
            return instr
        }
        return ""
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
