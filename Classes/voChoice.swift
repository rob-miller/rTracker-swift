//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voChoice.swift
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
//  voChoice.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import QuartzCore

class voChoice: voState {
    /*{
    	configTVObjVC *ctvovcp;
        UISegmentedControl *segmentedControl;
        BOOL processingTfDone;
        BOOL processingTfvDone;
    }*/
    var ctvovcp: configTVObjVC?

    private var _segmentedControl: UISegmentedControl?
    var segmentedControl: UISegmentedControl? {
        if _segmentedControl != nil && _segmentedControl?.frame.size.width != vosFrame.size.width {
            _segmentedControl = nil // first time around thinks size is 320, handle larger devices
        }

        if nil == _segmentedControl {
            //NSArray *segmentTextContent = [NSArray arrayWithObjects: @"0", @"one", @"two", @"three", @"four", nil];

            var i: Int
            var segmentTextContent: [AnyHashable] = []
            for i in 0..<CHOICES {
                let key = "c\(i)"
                let s = (vo?.optDict)?[key] as? String
                if (s != nil) && (s != "") {
                    segmentTextContent.append(s ?? "")
                }
            }
            //[segmentTextContent addObject:nil];

            //CGRect frame = bounds;
            _segmentedControl = UISegmentedControl(items: segmentTextContent)
            //_segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;  // resets segment widths to 0

            if ((vo?.optDict)?["shrinkb"] as? String) == "1" {
                /*
                            int j=0;
                            for (NSString *s in segmentTextContent) {
                                CGSize siz = [s sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize]]}];
                                [_segmentedControl setWidth:siz.width forSegmentAtIndex:j];
                                DBGLog(@"set width for seg %d to %f", j, siz.width);
                                j++;
                            }

                            // TODO: need to center control in subview for this
                            // */
                _segmentedControl?.apportionsSegmentWidthsByContent = true
            }

            _segmentedControl?.frame = vosFrame
            _segmentedControl?.addTarget(self, action: #selector(segmentAction(_:)), for: .valueChanged)

            _segmentedControl?.tag = kViewTag

            //        if ([self.vo.value isEqualToString:@""]) {
            //            self.segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment;
            //            [self.vo disableVO];
            //        } else {
            //            self.segmentedControl.selectedSegmentIndex = [self.vo.value integerValue];
            //        }
        }

        return _segmentedControl
    }
    var processingTfDone = false
    var processingTfvDone = false

    override init(vo valo: valueObj?) {
        super.init(vo: valo)
        processingTfDone = false
        vo?.useVO = false
    }

    override func resetData() {
        vo?.useVO = false
    }

    override func getValCap() -> Int {
        // NSMutableString size for value
        return 1
    }

    override func voTVCell(_ tableView: UITableView?) -> UITableViewCell? {
        return super.voTVEnabledCell(tableView)
        //return [super voTVCell:tableView];
    }

    override func voTVCellHeight() -> CGFloat {
        //return CELL_HEIGHT_TALL;
        return (segmentedControl?.frame.size.height ?? 0.0) + (3 * MARGIN) + (vo?.getLabelSize().height ?? 0.0) + (vo?.getLongTitleSize().height ?? 0.0)

    }

    func getValueForSegmentChoice() -> String? {
        //int i;
        var rslt = ""
        let segNdx = segmentedControl?.selectedSegmentIndex ?? 0
        if UISegmentedControl.noSegment != segNdx {

            let val = (vo?.optDict)?[String(format: "cv%lu", UInt(segNdx))] as? String
            if nil == val {
                rslt = String(format: "%lu", UInt(segNdx) + 1)
            } else {
                rslt = val ?? ""
            }
            #if DEBUGLOG
            let chTitle = segmentedControl?.titleForSegment(at: segNdx)
            DBGLog("get v for seg title %@ ndx %lu rslt %@", chTitle, UInt(segNdx), rslt) // why tf not just return fn on segNdx?
            #endif
            /*
                    for (i=0; i<CHOICES;i++) {
                        NSString *key = [NSString stringWithFormat:@"c%d",i];
                        NSString *val = [self.vo.optDict objectForKey:key];
                        if ([val isEqualToString:chTitle]) {
                            rslt = [NSString stringWithFormat:@"%d",i+1];  // disabled = 0 = no selection; all else gives value
                            break;
                        }
                    }
                    dbgNSAssert(i<CHOICES,@"segmentAction: failed to identify choice!");
            */
        }

        return rslt
    }

    func getSegmentIndexForValue() -> Int {
        return vo?.getChoiceIndex(forValue: vo?.value) ?? 0
        /*
            // doesn't display if e.g only choice 6 configured
            // rtm change with 'specify choice values' 24.xii.2012 return [self.vo.value integerValue]-1;
            NSString *currVal = self.vo.value;
            //DBGLog(@"gsiv val=%@",currVal);
            for (int i=0; i<CHOICES; i++) {
                NSString *key = [NSString stringWithFormat:@"cv%d",i];
                NSString *tstVal = [self.vo.optDict valueForKey:key];  
                if (nil == tstVal) {
                    tstVal = [NSString stringWithFormat:@"%d",i];  // added 7.iv.2013 - need default value
                }
                //DBGLog(@"gsiv test against %d: %@",i,tstVal);
                if ([tstVal isEqualToString:currVal]) {
                    return i;
                }
            }
            return CHOICES;
             */
    }

    /*
     - (void) reportscwid {
        int n;
        for (n=0; n< [segmentedControl numberOfSegments]; n++) {
            DBGLog(@"width of seg %d = %f", n, [segmentedControl widthForSegmentAtIndex:n]);
        }    
    }
    */

    @objc func segmentAction(_ sender: Any?) {
        if (sender?.selectedSegmentIndex == getSegmentIndexForValue()) && vo?.useVO ?? false {
            return
        }
        DBGLog("segmentAction: selected segment = %ld", Int(sender?.selectedSegmentIndex ?? 0))
        vo?.value = getValueForSegmentChoice()
        //TODO: vo.value setter should do enable/disable ?
        if !(vo?.useVO ?? false) {
            vo?.enableVO()
        }
        /*
            if ([@"" isEqual: self.vo.value]) {
                [self.vo disableVO];
            } else {
            	[self.vo enableVO];
            }
            */
        NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
    }

    override func voDisplay(_ bounds: CGRect) -> UIView? {


        vosFrame = bounds

        // set displayed segment from self.vo.value

        if vo?.value == "" {
            if UISegmentedControl.noSegment != segmentedControl?.selectedSegmentIndex {
                segmentedControl?.selectedSegmentIndex = UISegmentedControl.noSegment
                vo?.disableVO()
            }
        } else {
            let segNdx = getSegmentIndexForValue()
            if segmentedControl?.selectedSegmentIndex != segNdx {
                DBGLog("segmentedControl set value int: %ld str: %@ segNdx: %d", Int(vo?.value ?? "") ?? 0, vo?.value, segNdx)
                // during loadCSV, not matching the string will cause a new c%d dict entry, so can be > CHOICES
                if CHOICES > segNdx {
                    // normal case
                    segmentedControl?.selectedSegmentIndex = segNdx
                    //[self.segmentedControl setSelectedSegmentIndex:[self getSegmentIndexForValue]];
                } else {
                    // data can't be shown in buttons but it is there
                    // user must fix it, but it is all there to work with by save/edit csv and modify tracker
                    segmentedControl?.selectedSegmentIndex = UISegmentedControl.noSegment
                }
                vo?.enableVO()
            }
        }
        //[self.segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
        DBGLog("segmentedControl voDisplay: index %ld", Int(segmentedControl?.selectedSegmentIndex ?? 0))

        return segmentedControl
    }

    override func voGraphSet() -> [AnyHashable]? {
        return ["dots", "bar"]
    }

    @objc func ctfDone(_ tf: UITextField?) {
        if true == processingTfDone {
            return
        }
        processingTfDone = true

        var i = 0
        let key: String? = nil
        for key in ctvovcp?.wDict ?? [:] {
            guard let key = key as? key else {
                continue
            }
            if ((ctvovcp?.wDict)?[key ?? ""] as? UITextField) == tf {
                let kstr = Int8(key?.utf8CString ?? 0)
                sscanf(kstr, "%dtf", &i)
                break
            }
        }

        DBGLog("set choice %d: %@", i, tf?.text)
        tf?.text = tf?.text?.replacingOccurrences(of: "'", with: "") // these mess up sqlite -- could escape but lazy!
        tf?.text = tf?.text?.replacingOccurrences(of: "\"", with: "")
        (vo?.optDict)?["c\(i)"] = tf?.text
        let cc = "cc\(i)"

        let b = (ctvovcp?.wDict)?[String(format: "%dbtn", i)] as? UIButton
        if tf?.text == "" {
            b?.backgroundColor = .clear
            vo?.optDict?.removeValue(forKey: cc)
            //TODO: should offer to delete any stored data
        } else {
            let ncol = (vo?.optDict)?[cc] as? NSNumber

            if ncol == nil {
                let col = vo?.parentTracker?.nextColor ?? 0
                (vo?.optDict)?[cc] = NSNumber(value: col)
                b?.backgroundColor = rTracker_resource.colorSet()?[col] as? UIColor
            }
        }
        i += 1
        if i < CHOICES {
            (ctvovcp?.wDict)?[String(format: "%dtf", i)]?.becomeFirstResponder()
        } else {
            tf?.resignFirstResponder()
        }

        processingTfDone = false

    }

    //TODO: merge these two?
    @objc func ctfvDone(_ tf: UITextField?) {
        if true == processingTfvDone {
            return
        }
        processingTfvDone = true

        var i = 0
        let key: String? = nil
        for key in ctvovcp?.wDict ?? [:] {
            guard let key = key as? key else {
                continue
            }
            if ((ctvovcp?.wDict)?[key ?? ""] as? UITextField) == tf {
                let kstr = Int8(key?.utf8CString ?? 0)
                sscanf(kstr, "%dtfv", &i)
                break
            }
        }

        if "" != tf?.text {
            DBGLog("set choice value %d: %@", i, tf?.text)
            (vo?.optDict)?["cv\(i)"] = tf?.text
        } else {
            vo?.optDict?.removeValue(forKey: "cv\(i)")
        }

        //if (++i<CHOICES) {
        (ctvovcp?.wDict)?[String(format: "%dtf", i)]?.becomeFirstResponder()
        //} else {
        //	[tf resignFirstResponder];
        //}

        processingTfvDone = false

    }

    @objc func choiceColorButtonAction(_ btn: UIButton?) {
        var i = 0

        for key in ctvovcp?.wDict ?? [:] {
            guard let key = key as? String else {
                continue
            }
            if ((ctvovcp?.wDict)?[key] as? UIButton) == btn {
                let kstr = key.utf8CString as? UnsafePointer<Int8>
                sscanf(kstr, "%dbtn", &i)
                break
            }
        }

        let cc = "cc\(i)"
        let ncol = (vo?.optDict)?[cc] as? NSNumber
        if ncol == nil {
            // do nothing as no choice label set so button not active
        } else {
            var col = ncol?.intValue ?? 0
            col += 1
            if col >= (rTracker_resource.colorSet()?.count ?? 0) {
                col = 0
            }
            (vo?.optDict)?[cc] = NSNumber(value: col)
            btn?.backgroundColor = rTracker_resource.colorSet()?[col] as? UIColor
        }

    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {

        if nil == (vo?.optDict)?["shrinkb"] {
            (vo?.optDict)?["shrinkb"] = SHRINKBDFLT ? "1" : "0"
        }

        if nil == (vo?.optDict)?["exportvalb"] {
            (vo?.optDict)?["exportvalb"] = EXPORTVALBDFLT ? "1" : "0"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String?) -> Bool {

        let val = (vo?.optDict)?[key ?? ""] as? String
        if nil == val {
            return true
        }

        if (key == "shrinkb") && (val == SHRINKBDFLT ? "1" : "0") {
            vo?.optDict?.removeValue(forKey: key)
            return true
        }

        if (key == "exportvalb") && (val == EXPORTVALBDFLT ? "1" : "0") {
            vo?.optDict?.removeValue(forKey: key)
            return true
        }

        return super.cleanOptDictDflts(key)
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC?) {
        ctvovcp = ctvovc
        var frame = CGRect(x: MARGIN, y: ctvovc?.lasty ?? 0.0, width: 0.0, height: 0.0)

        var labframe = ctvovc?.configLabel("Choices:", frame: frame, key: "coLab", addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN

        let tfvWidth = "-88 ".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        let tfWidth = "888888888".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width

        frame.size.height = ctvovc?.lfHeight ?? 0.0 // self.labelField.frame.size.height; // lab.frame.size.height;

        var i: Int
        var j = 1
        for i in 0..<CHOICES {
            frame.size.width = tfvWidth

            frame = ctvovc?.configTextField(
                frame,
                key: String(format: "%dtfv", i),
                target: self,
                action: #selector(ctfvDone(_:)),
                num: true,
                place: "\(i + 1)",
                text: (vo?.optDict)?["cv\(i)"] as? String,
                addsv: true) ?? CGRect.zero

            frame.origin.x += MARGIN + tfvWidth
            frame.size.width = tfWidth

            frame = ctvovc?.configTextField(
                frame,
                key: String(format: "%dtf", i),
                target: self,
                action: #selector(ctfDone(_:)),
                num: false,
                place: "choice \(i + 1)",
                text: (vo?.optDict)?["c\(i)"] as? String,
                addsv: true) ?? CGRect.zero

            frame.origin.x += MARGIN + tfWidth

            //frame.size.height = 1.2* frame.size.height;
            frame.size.width = frame.size.height
            let btn = UIButton(type: .custom)
            btn.frame = frame
            btn.layer.cornerRadius = 8.0
            btn.layer.masksToBounds = true
            btn.layer.borderWidth = 1.0
            let cc = (vo?.optDict)?["cc\(i)"] as? NSNumber
            if cc == nil {
                btn.backgroundColor = .clear
            } else {
                btn.backgroundColor = rTracker_resource.colorSet()?[cc?.intValue ?? 0] as? UIColor
            }

            btn.titleLabel?.font = PrefBodyFont

            btn.addTarget(self, action: #selector(choiceColorButtonAction(_:)), for: .touchDown)
            (ctvovc?.wDict)?[String(format: "%dbtn", i)] = btn
            //[ctvovc.view addSubview:btn];
            ctvovc?.scroll.addSubview(btn)

            ctvovc?.lastx = ((ctvovc?.lastx ?? 0.0) < frame.origin.x + frame.size.width + MARGIN ? frame.origin.x + frame.size.width + MARGIN : ctvovc?.lastx) ?? 0.0

            frame.origin.x = MARGIN + (Double(j) * (tfvWidth + tfWidth + (ctvovc?.lfHeight ?? 0.0) + 3 * MARGIN))
            j = j != 0 ? 0 : 1 // j toggles 0-1
            frame.origin.y += Double(j) * ((2 * MARGIN) + (ctvovc?.lfHeight ?? 0.0))

            //frame.size.width = tfWidth;
            //frame.size.height = self.labelField.frame.size.height; // lab.frame.size.height;
        }

        //frame.origin.y -= MARGIN; // remove extra from end of loop, add one back for next line
        frame.origin.x = MARGIN

        //-- general options label

        labframe = ctvovc?.configLabel("Other options:", frame: frame, key: "goLab", addsv: true)

        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN

        labframe = ctvovc?.configLabel("Shrink buttons:", frame: frame, key: "csbLab", addsv: true)

        frame = CGRect(x: (labframe?.size.width ?? 0.0) + MARGIN + SPACE, y: frame.origin.y, width: labframe?.size.height ?? 0.0, height: labframe?.size.height ?? 0.0)

        frame = ctvovc?.configCheckButton(
            frame,
            key: "csbBtn",
            state: ((vo?.optDict)?["shrinkb"] == "1") /* default:0 */,
            addsv: true) ?? CGRect.zero

        // export values option

        frame.origin.x = MARGIN
        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN

        labframe = ctvovc?.configLabel("CSV read/write values (not labels):", frame: frame, key: "cevLab", addsv: true)

        frame = CGRect(x: (labframe?.size.width ?? 0.0) + MARGIN + SPACE, y: frame.origin.y, width: labframe?.size.height ?? 0.0, height: labframe?.size.height ?? 0.0)

        frame = ctvovc?.configCheckButton(
            frame,
            key: "cevBtn",
            state: ((vo?.optDict)?["exportvalb"] == "1") /* default:0 */,
            addsv: true) ?? CGRect.zero



        ctvovc?.lasty = frame.origin.y + frame.size.height + MARGIN
        ctvovc?.lastx = ((ctvovc?.lastx ?? 0.0) < frame.origin.x + frame.size.width + MARGIN ? frame.origin.x + frame.size.width + MARGIN : ctvovc?.lastx) ?? 0.0

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

    /* rtm here : export value option 
     */

    override func mapValue2Csv() -> String? {
        #if DEBUGLOG
        DBGLog(
            "val= %@ indexForval= %d obj= %@",
            vo?.value,
            getSegmentIndexForValue(),
            vo?.optDict?["c\(getSegmentIndexForValue())"])
        #endif
        if ((vo?.optDict)?["exportvalb"] as? String) == "1" {
            return vo?.value
        } else {
            return (vo?.optDict)?["c\(getSegmentIndexForValue())"] as? String
        }
    }

    /* rtm here : export value option -- need to parse and match value if choice did not match
     */

    override func mapCsv2Value(_ inCsv: String?) -> String? {
        var optDict = vo?.optDict
        if (optDict?["exportvalb"] as? String) == "1" {
            // we simply store the value, up to the user to provide a choice to match it
            return inCsv
        }
        var ndx: Int
        let count = optDict?.count ?? 0
        var maxc = -1
        var firstBlank = -1
        var lastColor = -1
        DBGLog("inCsv= %@", inCsv)
        for ndx in 0..<count {
            let key = "c\(ndx)"
            let val = optDict?[key] as? String
            if nil != val {
                maxc = ndx
                lastColor = (optDict?["cc\(ndx)"] as? NSNumber)?.intValue ?? 0
                if val == inCsv {
                    //DBGLog(@"matched, returning %d",ndx+1);
                    //return [NSString stringWithFormat:@"%d",ndx+1];    // found match, return 1-based index and be done
                    // change for can spec value for choice
                    DBGLog("matched, ndx=%d", ndx)
                    let key = "cv\(ndx)"
                    return optDict?[key] as? String
                } else if (-1 == firstBlank) && ("" == val) {
                    firstBlank = ndx
                }
            }
        }

        // did not find inCsv as an object in optDict for a c%d key.

        // is inCsv a digit from a pre-1.0.5 csv save file?
        // TODO: remove this because is only for upgrade to 1.0.5
        //int intval = [inCsv intValue];
        //if ((0<intval) && (intval < CHOICES+1)) {
        //    return inCsv;
        //}

        // need to add a new object to optDict

        // if any blanks, put it there. using maxc as ndx now
        if -1 != firstBlank {
            maxc = firstBlank // this position available
        } else {
            maxc += 1 // maxc is last one used because there were no blanks, so inc to next
        }

        optDict?["c\(maxc)"] = inCsv

        lastColor += 1
        if lastColor >= (rTracker_resource.colorSet()?.count ?? 0) {
            lastColor = 0
        }

        optDict?["cc\(maxc)"] = NSNumber(value: lastColor)

        DBGLog("created choice %@ choice c%d color %ld", inCsv, maxc, lastColor)

        maxc += 1 // +1 because value not 0-based, while c%d key is

        // for exportvalb=false, stored value is segment index
        return "\(maxc)"
    }
}