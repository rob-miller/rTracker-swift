//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voState.swift
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
//  voState.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit



class voState: NSObject, voProtocol {

    var vo: valueObj
    var MyTracker: trackerObj
    var vosFrame = CGRect.zero
    weak var vc: UIViewController?

    init(vo valo: valueObj) {
        vo = valo
        MyTracker = vo.parentTracker
        super.init()

        vo.useVO = true
    }

    func getValCap() -> Int {
        // NSMutableString size for value
        return 10
    }
    
    func getNumVal() -> Double {
        return Double(vo.value) ?? 0
    }
    
    func update(_ instr: String) -> String {
        // place holder so fn can update on access; also confirm textfield updated
        // added return "" if disabled 30.vii.13
        if vo.useVO {
            return instr
        } else {
            return ""
        }
    }

    func loadConfig() {
    }

    func setOptDictDflts() {

        if nil == vo.optDict["graph"] {
            vo.optDict["graph"] = GRAPHDFLT ? "1" : "0"
        }
        if nil == vo.optDict["privacy"] {
            vo.optDict["privacy"] = "\(PRIVDFLT)"
        }
        if nil == vo.optDict["longTitle"] {
            vo.optDict["longTitle"] = ""
        }




    }

    func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "graph") && (val == (GRAPHDFLT ? "1" : "0"))) || ((key == "privacy") && (Int(val ?? "") ?? 0 == PRIVDFLT)) || ((key == "longTitle") && (val == "")) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        return false

        //if ( 
        //([key isEqualToString:@"autoscale"] && [val isEqualToString:(AUTOSCALEDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"shrinkb"] && [val isEqualToString:(SHRINKBDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"tbnl"] && [val isEqualToString:(TBNLDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"tbni"] && [val isEqualToString:(TBNIDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"tbhi"] && [val isEqualToString:(TBHIDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"graph"] && [val isEqualToString:(GRAPHDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"nswl"] && [val isEqualToString:(NSWLDFLT ? @"1" : @"0")])
        //||
        //([key isEqualToString:@"func"] && [val isEqualToString:@""])
        //||
        //([key isEqualToString:@"smin"] && ([val floatValue] == f(SLIDRMINDFLT)))
        //||
        //([key isEqualToString:@"smax"] && ([val floatValue] == f(SLIDRMAXDFLT)))
        //||
        //([key isEqualToString:@"sdflt"] && ([val floatValue] == f(SLIDRDFLTDFLT)))
        //||
        //([key isEqualToString:@"frep0"] && ([val intValue] == FREPDFLT))
        //||
        //([key isEqualToString:@"frep1"] && ([val intValue] == FREPDFLT))
        //||
        //([key isEqualToString:@"fnddp"] && ([val intValue] == FDDPDFLT))
        //||
        //([key isEqualToString:@"privacy"] && ([val intValue] == PRIVDFLT))
        //   ) {
        //}

        //return [self.vos cleanOptDictDflts:key];
    }

    @objc func longTitleSave(_ str: String?) {
        DBGLog(String("lts: \(str)"))
        vo.optDict["longTitle"] = str?.trimmingCharacters(in: .whitespaces)
    }

    func longTitleBtn() {
        DBGLog("long title")

        let vde = voDataEdit()
        vde.vo = nil
        vde.saveClass = self
        vde.saveSelector = #selector(longTitleSave(_:))
        vde.text = vo.optDict["longTitle"]

        //[self performSelector:vde.saveSelector withObject:@"foo" afterDelay:(NSTimeInterval)0];
        let navCon = UINavigationController(rootViewController: vde)
        vc?.present(navCon, animated: true)
    }

    func tvn() -> String {
        let tname = self.vo.parentTracker.trackerName ?? "tnull"
        let vname = self.vo.valueName ?? "vnull"
        return "\(tname)_\(vname)"
    }
    
    func voDrawOptions(_ ctvovc: configTVObjVC) {
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)
        var labframe = ctvovc.configLabel("Draw graph:", frame: frame, key: "ggLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        //-- draw graphs button

        _ = ctvovc.configCheckButton(
            frame,
            key: "ggBtn",
            state: !(vo.optDict["graph"] == "0"),
            addsv: true)

        //-- privacy level label

        frame.origin.x += frame.size.width + MARGIN + SPACE
        //frame.origin.y += MARGIN + frame.size.height;
        labframe = ctvovc.configLabel("Privacy level:", frame: frame, key: "gpLab", addsv: true)

        //-- privacy level textfield

        frame.origin.x += labframe.size.width + SPACE
        var tfWidth = "9999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovc.lfHeight  // self.labelField.frame.size.height; // lab.frame.size.height;

        _ = ctvovc.configTextField(
            frame,
            key: "gpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(PRIVDFLT)",
            text: vo.optDict["privacy"],
            addsv: true)

        //------

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        labframe = ctvovc.configLabel("Line at Y=", frame: frame, key: "gyLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        tfWidth = "9999999.99".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovc.lfHeight // self.labelField.frame.size.height; // lab.frame.size.height;

        _ = ctvovc.configTextField(
            frame,
            key: "gyTF",
            target: nil,
            action: nil,
            num: true,
            place: "0",
            text: vo.optDict["yline1"],
            addsv: true)

        //------

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        /* disable long title for now...
            self.vc = ctvovc;
            frame = [ctvovc configActionBtn:frame key:nil label:@"long title" target:self action:@selector(longTitleBtn)];
            */


        //------

        ctvovc.lasty = frame.origin.y + frame.size.height + MARGIN
        ctvovc.lastx = (ctvovc.lastx < frame.origin.x + frame.size.width + MARGIN ? frame.origin.x + frame.size.width + MARGIN : ctvovc.lastx)

    }

    func voDisplay(_ bounds: CGRect) -> UIView {
        dbgNSAssert(false, "voDisplay failed to dispatch")
        return UIView()
    }

    let LMARGIN = 60.0
    let RMARGIN = 10.0
    let BMARGIN = 7.0


    static let voTVEnabledCellCellIdentifier = "Cell1"

    func voTVEnabledCell(_ tableView: UITableView?) -> UITableViewCell {

        var bounds: CGRect = CGRect.zero
        var cell: UITableViewCell?
        let maxLabel = vo.parentTracker.maxLabel
        DBGLog(String("votvenabledcell maxLabel= w= \(maxLabel.width) h= \(maxLabel.height)"))

        cell = tableView?.dequeueReusableCell(withIdentifier: voState.voTVEnabledCellCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: voState.voTVEnabledCellCellIdentifier)
            cell?.selectionStyle = .none
            cell?.backgroundColor = nil
        } else {
            // the cell is being recycled, remove old embedded controls
            //var viewToRemove: UIView? = nil
            while let viewToRemove = cell?.contentView.viewWithTag(kViewTag) {
                viewToRemove.removeFromSuperview()
            }
        }


        //cell.accessoryType = UITableViewCellAccessoryCheckmark;

        // checkButton top row left

        //let checkImage = UIImage(named: "checked.png")

        bounds.origin.x = MARGIN
        bounds.origin.y = MARGIN
        /* changed to constant 30x30 7.iv.2013
        	bounds.size.width = checkImage.size.width ; //CHECKBOX_WIDTH; // cell.frame.size.width;
        	bounds.size.height = checkImage.size.height ; //self.tracker.maxLabel.height + 2*BMARGIN; //CELL_HEIGHT_TALL/2.0; //self.tracker.maxLabel.height + BMARGIN;
             */
        bounds.size.width = 30.0 // for checkbox
        bounds.size.height = 30.0


        vo.switchUseVO?.frame = bounds
        vo.switchUseVO?.tag = kViewTag
        //vo.switchUseVO?.backgroundColor = cell?.backgroundColor

        vo.switchUseVO?.accessibilityHint = "enable this control"
        vo.switchUseVO?.accessibilityIdentifier = "\(tvn())_enable"
        
        //if (! self.vo.retrievedData) {  // only show enable checkbox if this is data entry mode (not show historical)
        // 26 mar 2011 -- why not show for historical ?
        // 30 mar 2011 -- seems like switchUseVO should be correct state if use enablevo everywhere; else don't use it
        //let image = vo.useVO ? checkImage : UIImage(named: "unchecked.png")
        //let newImage = image?.stretchableImage(withLeftCapWidth: Int(12.0), topCapHeight: Int(0.0))
        //vo.switchUseVO?.setImage(newImage, for: .normal)
        
        vo.switchUseVO?.isOn = vo.useVO
        if let aswitchUseVO = vo.switchUseVO {
            cell?.contentView.addSubview(aswitchUseVO)
        }

        cell?.backgroundColor = .clear

        // cell label top row right

        let swSize = vo.switchUseVO?.intrinsicContentSize
        bounds.origin.x += (swSize?.width ?? 0.0) + MARGIN

        // [rTracker_resource getKeyWindowWidth] - maxLabel.width - LMARGIN - RMARGIN;
        let screenSize = UIScreen.main.bounds.size
        bounds.size.width = screenSize.width - (swSize?.width ?? 0.0) - (2.0 * MARGIN) //cell.frame.size.width - checkImage.size.width - (2.0*MARGIN);
        bounds.size.height = maxLabel.height + MARGIN //CELL_HEIGHT_TALL/2.0; //self.tracker.maxLabel.height + BMARGIN;


        let splitStrArr = vo.valueName?.components(separatedBy: "|")
        if 1 < (splitStrArr?.count ?? 0) {
            bounds.size.width /= 2.0
        }
        var label = UILabel(frame: bounds)
        label.tag = kViewTag
        //label.font = [UIFont boldSystemFontOfSize:18.0];
        label.font = PrefBodyFont
        var darkMode = false
        if #available(iOS 13.0, *) {
            label.textColor = .label
            darkMode = vc?.traitCollection.userInterfaceStyle == .dark
            label.backgroundColor = darkMode ? UIColor.systemBackground : UIColor.clear
        } else {
            label.textColor = .label
            label.backgroundColor = .clear
        }

        label.alpha = 1.0

        label.textAlignment = .left // ios6 UITextAlignmentLeft;
        //don't use - messes up for loarger displays -- label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin; // | UIViewAutoresizingFlexibleHeight;
        label.contentMode = .topLeft
        label.text = splitStrArr?[0] //self.vo.valueName;
        //label.enabled = YES;
        DBGLog(String("enabled text= \(label.text)"))


        cell?.contentView.addSubview(label)

        if 1 < (splitStrArr?.count ?? 0) {
            bounds.origin.x += bounds.size.width
            bounds.size.width -= 2.0 * MARGIN
            label = UILabel(frame: bounds)
            label.tag = kViewTag
            //label.font = [UIFont boldSystemFontOfSize:18.0];
            label.font = PrefBodyFont
            if #available(iOS 13.0, *) {
                label.textColor = .label
                label.backgroundColor = darkMode ? UIColor.systemBackground : UIColor.clear
            } else {
                label.textColor = .label
                label.backgroundColor = .clear
            }

            label.alpha = 1.0

            label.textAlignment = .right // ios6 UITextAlignmentLeft;
            // don't use - see above -- label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin; // | UIViewAutoresizingFlexibleHeight;
            label.contentMode = .topRight
            label.text = splitStrArr?[1] //self.vo.valueName;

            //label.enabled = YES;
            DBGLog(String("enabled text2= \(label.text)"))

            cell?.contentView.addSubview(label)
        }

        bounds.origin.y = maxLabel.height + (3.0 * MARGIN) //CELL_HEIGHT_TALL/2.0 + MARGIN; // 38.0f; //bounds.size.height; // + BMARGIN;
        bounds.size.height = /*CELL_HEIGHT_TALL/2.0 ; // */ maxLabel.height + (1.5 * MARGIN)

        bounds.size.width = screenSize.width - (2.0 * MARGIN) // cell.frame.size.width - (2.0f * MARGIN);
        bounds.origin.x = MARGIN // 0.0f ;  //= bounds.origin.x + RMARGIN;

        //DBGLog(@"votvenabledcell adding subview");
        if let aDisplay = vo.display(bounds) {
            cell?.contentView.addSubview(aDisplay)
        }
        return cell!

    }

    func voTVCellHeight() -> CGFloat {
        var labelSize = vo.getLabelSize()
        labelSize.height += vo.getLongTitleSize().height
        let maxLabel = vo.parentTracker.maxLabel

        if labelSize.width <= maxLabel.width || VOT_INFO == vo.vtype {
            //return CELL_HEIGHT_NORMAL;
            //return maxLabel.height + (2*MARGIN);
            return labelSize.height + (2 * MARGIN)
        } else {
            //return CELL_HEIGHT_TALL;
            return labelSize.height + maxLabel.height + (2 * MARGIN)
        }
    }

    //DBGLog(@"votvcell maxLabel= w= %f h= %f",maxLabel.width,maxLabel.height);

    static let voTVCellCellIdentifier = "Cell2"

    func voTVCell(_ tableView: UITableView) -> UITableViewCell {

        var bounds: CGRect = CGRect.zero
        var cell: UITableViewCell?

        let maxLabel = vo.parentTracker.maxLabel

        cell = tableView.dequeueReusableCell(withIdentifier: voState.voTVCellCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: voState.voTVCellCellIdentifier)
            cell?.selectionStyle = .none
            //DBGLog(@"new cell");
        } else {

            while let viewToRemove = cell?.contentView.viewWithTag(kViewTag) {
                //DBGLog(@"removing");
                viewToRemove.removeFromSuperview()
            }

        }

        cell?.backgroundColor = .clear

        bounds.origin.x = MARGIN
        bounds.origin.y = MARGIN

        let labelSize = vo.getLabelSize()
        let longTitleSize = vo.getLongTitleSize()

        //bounds.origin.y = labelSize.height - (MARGIN);

        if labelSize.width <= maxLabel.width {
            bounds.size.width = maxLabel.width
        } else {
            bounds.size.width = rTracker_resource.getKeyWindowWidth() - MARGIN - RMARGIN
        }
        bounds.size.height = labelSize.height // maxLabel.height; // labelSize.height;

        var label = UILabel(frame: bounds)
        label.tag = kViewTag
        label.font = PrefBodyFont

        label.textColor = .label
        let darkMode = vc?.traitCollection.userInterfaceStyle == .dark
        label.backgroundColor = darkMode ? UIColor.systemBackground : UIColor.clear

        label.alpha = 1.0
        label.textAlignment = .left

        //don't use - messes up for larger displays -- label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin; // | UIViewAutoresizingFlexibleHeight;
        label.contentMode = .topLeft
        label.text = vo.valueName
        //label.enabled = YES;

        DBGLog(String("cell text= \(label.text) label width= \(labelSize.width)  maxLabel width= \(maxLabel.width)"))

        cell?.contentView.addSubview(label)

        cell?.accessibilityIdentifier = "useT_\(vo.vos!.tvn())"
        
        if longTitleSize.height > 0 {
            DBGLog(String("longTitle:\(vo.optDict["longTitle"])"))

            bounds.origin.y += 3 * MARGIN // maxLabel.height + (3*MARGIN); // labelSize.height + MARGIN;
            bounds.size = longTitleSize

            label = UILabel(frame: bounds)
            label.tag = kViewTag
            label.font = PrefBodyFont
            label.textColor = .blue
            label.alpha = 1.0
            label.backgroundColor = .clear
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0 // remove any limit

            label.textAlignment = .left // ios6 UITextAlignmentLeft;
            //don't use - messes up for loarger displays -- label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin; // | UIViewAutoresizingFlexibleHeight;
            label.contentMode = .topLeft

            label.text = vo.optDict["longTitle"]

            cell?.contentView.addSubview(label)
        }

        if (labelSize.width > maxLabel.width) || longTitleSize.height > 0 {
            bounds.origin.x = cell!.frame.origin.x + MARGIN
            bounds.origin.y += bounds.size.height + MARGIN //   maxLabel.height + (2*MARGIN);
            bounds.size.width = rTracker_resource.getKeyWindowWidth() - MARGIN - RMARGIN
            bounds.size.height = maxLabel.height + MARGIN
        } else {
            bounds.origin.x = maxLabel.width + LMARGIN
            bounds.origin.y = MARGIN
            bounds.size.width = rTracker_resource.getKeyWindowWidth() - maxLabel.width - LMARGIN - RMARGIN // cell.frame.size.width - maxLabel.width - LMARGIN - RMARGIN;
            bounds.size.height = maxLabel.height + MARGIN

            //DBGLog(@"maxLabel: % f %f",self.tracker.maxLabel.width, self.tracker.maxLabel.height);
            //bounds.origin.y = bounds.size.height;// - BMARGIN;
        }

        //DBGLog(@"bounds= %f %f %f %f",bounds.origin.x,bounds.origin.y,bounds.size.width, bounds.size.height)	;
        if let aDisplay = vo.display(bounds) {
            cell?.contentView.addSubview(aDisplay)
        }
        return cell!
    }

    func dataEditVDidLoad(_ vc: UIViewController) {
    }

    func dataEditVWAppear(_ vc: UIViewController) {
    }

    func dataEditVWDisappear(_ vc: UIViewController) {
    }

    /*
    - (void) dataEditVDidUnload {
    }
    */

    //- (void) dataEditFinished {
    //}

    func voGraphSet() -> [String] {
        return ["dots"]
    }


    /*
    - (void) transformVO_num:(NSMutableArray *)xdat 
                        ydat:(NSMutableArray *)ydat 
                      dscale:(double)dscale 
                      height:(CGFloat)height 
                      border:(float)border 
                   firstDate:(int)firstDate;

    - (void) transformVO_note:(NSMutableArray *)xdat 
                        ydat:(NSMutableArray *)ydat 
                      dscale:(double)dscale 
                      height:(CGFloat)height 
                      border:(float)border 
                   firstDate:(int)firstDate;

    - (void) transformVO_bool:(NSMutableArray *)xdat 
                        ydat:(NSMutableArray *)ydat 
                      dscale:(double)dscale 
                      height:(CGFloat)height 
                      border:(float)border 
                   firstDate:(int)firstDate;
    */
    class func voGraphSetNum() -> [String] {
        return ["dots", "bar", "line", "line+dots"]
    }

    func updateVORefs(_ newVID: Int, old oldVID: Int) {
        // subclass overrides if need to do anything
    }

    func newVOGD() -> vogd {
        DBGErr("newVOGD with no handler!")
        return vogd(vo).initAsNum(vo)
    }

    /*
    - (void) recalculate {
    	// subclass overrides if need to do anything
    }
    */

    func setFnVals(_ tDate: Int) {
        // subclass overrides if need to do anything
    }

    func doTrimFnVals() {
        // subclass overrides if need to do anything
    }

    func resetData() {
        // subclass overrides if need to do anything
        vo.useVO = true
    }

    func mapValue2Csv() -> String? {
        return vo.value // subclass overrides if need to do anything - specifically for choice, textbox
    }

    func mapCsv2Value(_ inCsv: String) -> String {
        return inCsv // subclass overrides if need to do anything - specifically for choice
    }
    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {
        DBGErr(@"transformVO with no handler!");
    }

    - (void) transformVO_num:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {
    	//double dscale = d(self.bounds.size.width - (2.0f*BORDER)) / d(self.lastDate - self.firstDate);
    	double minVal,maxVal;

        trackerObj *myTracker = (trackerObj*) self.vo.parentTracker;

    	if ((self.vo.vtype == VOT_NUMBER || self.vo.vtype == VOT_FUNC) 
            && ([@"0" isEqualToString:[self.vo.optDict objectForKey:@"autoscale"]])
            ) { 
            //DBGLog(@"autoscale= %@", [self.vo.optDict objectForKey:@"autoscale"]);
    		minVal = [[self.vo.optDict objectForKey:@"gmin"] doubleValue];
    		maxVal = [[self.vo.optDict objectForKey:@"gmax"] doubleValue];
    	} else if (self.vo.vtype == VOT_SLIDER) {
    		NSNumber *nmin = [self.vo.optDict objectForKey:@"smin"];
    		NSNumber *nmax = [self.vo.optDict objectForKey:@"smax"];
    		minVal = ( nmin ? [nmin doubleValue] : d(SLIDRMINDFLT) );
    		maxVal = ( nmax ? [nmax doubleValue] : d(SLIDRMAXDFLT) );
    	} else if (self.vo.vtype == VOT_CHOICE) {
    		minVal = d(0);
    		maxVal = CHOICES+1;
    	} else {
    	sql = [NSString stringWithFormat:@"select min(val collate CMPSTRDBL) from voData where id=%d;",self.vo.vid];
    		minVal = [myTracker toQry2Double:sql];
    	sql = [NSString stringWithFormat:@"select max(val collate CMPSTRDBL) from voData where id=%d;",self.vo.vid];
    		maxVal = [myTracker toQry2Double:sql];
    	}

    	if (minVal == maxVal) {
    		minVal = 0.0f;
    	}
    	if (minVal == maxVal) {
    		minVal = 1.0f;
    	}

    	//double vscale = d(self.bounds.size.height - (2.0f*BORDER)) / (maxVal - minVal);
        double vscale = d(height - (2.0f*border)) / (maxVal - minVal);

    	NSMutableArray *i1 = [[NSMutableArray alloc] init];
    	NSMutableArray *d1 = [[NSMutableArray alloc] init];
    	myTracker.sql = [NSString stringWithFormat:@"select date,val from voData where id=%d order by date;",self.vo.vid];
    	[myTracker toQry2AryID:i1 d1:d1];
    	myTracker.sql=nil;

    	NSEnumerator *e = [d1 objectEnumerator];

    	for (NSNumber *ni in i1) {

    		NSNumber *nd = [e nextObject];

    		DBGLog(@"i: %@  f: %@",ni,nd);
    		double d = [ni doubleValue];		// date as int secs cast to float
    		double v = [nd doubleValue] ;		// val as float

    		d -= (double) firstDate; // self.firstDate;
    		d *= dscale;
    		v -= minVal;
    		v *= vscale;

    		d+= border; //BORDER;
    		v+= border; //BORDER;
            // done by doDrawGraph ? : why does this code run again after rotate to portrait?
    		DBGLog(@"num final: %f %f",d,v);
    		[xdat addObject:[NSNumber numberWithDouble:d]];
    		[ydat addObject:[NSNumber numberWithDouble:v]];

    	}

    	[i1 release];
    	[d1 release];
    }

    - (void) transformVO_note:(NSMutableArray *)xdat ydat:(NSMutableArray *) ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

    	//double dscale = d(self.bounds.size.width - (2.0f*BORDER)) / d(self.lastDate - self.firstDate);
        trackerObj *myTracker = (trackerObj*) self.vo.parentTracker;

    	NSMutableArray *i1 = [[NSMutableArray alloc] init];
    	myTracker.sql = [NSString stringWithFormat:@"select date from voData where id=%d and val not NULL order by date;",self.vo.vid];
    	[myTracker toQry2AryI:i1];
    	myTracker.sql=nil;

    	for (NSNumber *ni in i1) {

    		DBGLog(@"i: %@  ",ni);
    		double d = [ni doubleValue];		// date as int secs cast to float

    		d -= (double) firstDate;
    		d *= dscale;
    		d+= border;

    		[xdat addObject:[NSNumber numberWithDouble:d]];
    		[ydat addObject:[NSNumber numberWithFloat:(border + (height/10))]];   // DEFAULT_PT=BORDER+5

    	}
    	[i1 release];
    }

    - (void) transformVO_bool:(NSMutableArray *)xdat ydat:(NSMutableArray *) ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {
    	//double dscale = d(self.bounds.size.width - (2.0f*BORDER)) / d(self.lastDate - self.firstDate);
        trackerObj *myTracker = (trackerObj*) self.vo.parentTracker;

    	NSMutableArray *i1 = [[NSMutableArray alloc] init];
    	myTracker.sql = [NSString stringWithFormat:@"select date from voData where id=%d and val='1' order by date;",self.vo.vid];
    	[myTracker toQry2AryI:i1];
    	myTracker.sql=nil;

    	for (NSNumber *ni in i1) {

    		DBGLog(@"i: %@  ",ni);
    		double d = [ni doubleValue];		// date as int secs cast to float

    		d -= (double) firstDate;
    		d *= dscale;
    		d+= border;

    		[xdat addObject:[NSNumber numberWithDouble:d]];
    		[ydat addObject:[NSNumber numberWithFloat:(border + (height/10))]];   // DEFAULT_PT=BORDER+5

    	}
    	[i1 release];
    }
    */
}
