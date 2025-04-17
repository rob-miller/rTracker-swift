//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voInfo.swift
/// Copyright 2014-2021 Robert T. Miller
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
//  voInfo.swift
//  rTracker
//
//  Created by Robert Miller on 18/02/2014.
//  Copyright 2014 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit

class voInfo: voState {
    //@synthesize imageButton;


    // 25.i.14 allow assigned values so use default (10) size
    //- (int) getValCap {  // NSMutableString size for value
    //    return 1;
    //}
    /*
    - (UIImage *) boolBtnImage {
    	// default is not checked
    	return ( [self.vo.value isEqualToString:@""] ? [UIImage imageNamed:@"unchecked.png"] : [UIImage imageNamed:@"checked.png"] );
    }

    - (void)boolBtnAction:(UIButton *)imageButton
    {  // default is unchecked or nil // 25.i.14 use assigned val // was "so only certain is if =1" ?
    	if ([self.vo.value isEqualToString:@""]) {
            NSString *bv = [self.vo.optDict objectForKey:@"boolval"];
            //if (nil == bv) {
                //bv = BOOLVALDFLTSTR;
                //[self.vo.optDict setObject:bv forKey:@"boolval"];
            //}
    		[self.vo.value setString:bv];
    		[self.imageButton setImage:[UIImage imageNamed:@"checked.png"] forState: UIControlStateNormal];
    	} else {
    		[self.vo.value setString:@""];
    		[self.imageButton setImage:[UIImage imageNamed:@"unchecked.png"] forState: UIControlStateNormal];
    	}

    	//self.vo.display = nil; // so will redraw this cell only
    	[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
    }

    - (UIButton*) imageButton {
    	if (nil == imageButton) {
            imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
            imageButton.frame = self.vosFrame; //CGRectZero;
            imageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            imageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight; //Center;
            [imageButton addTarget:self action:@selector(boolBtnAction:) forControlEvents:UIControlEventTouchDown];		
            imageButton.tag = kViewTag;	// tag this view for later so we can remove it from recycled table cells
            [imageButton retain];  // rtm 06 feb 2012
    	}
        return imageButton;
    }
    */

    override func voDisplay(_ bounds: CGRect) -> UIView {
        /*    self.vosFrame = bounds;
        	[self.imageButton setImage:[self boolBtnImage] forState: UIControlStateNormal];

            DBGLog(@"bool voDisplay: %d", ([self.imageButton imageForState:UIControlStateNormal] == [UIImage imageNamed:@"checked.png"] ? 1 : 0) );
            DBGLog(@"bool data= %@",self.vo.value);
        	return self.imageButton;
         */
        return UIView()  // nil
    }

    override func voGraphSet() -> [String] {
        return [] //[NSArray arrayWithObjects:@"dots", @"bar", nil];
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
        if nil == vo.optDict["infoval"] {
            vo.optDict["infoval"] = INFOVALDFLTSTR
        }

        if nil == vo.optDict["infourl"] {
            vo.optDict["infourl"] = INFOURLDFLTSTR
        }

        if nil == vo.optDict["infosave"] {
            vo.optDict["infosave"] = INFOSAVEDFLT ? "1" : "0"
        }

        vo.optDict["graph"] = "0"
        vo.optDict["privacy"] = "\(PRIVDFLT)"

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if (((key == "infoval") && (INFOVALDFLTSTR == val)) /* ([val floatValue] == f(INFOVALDFLT))) */) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if (key == "infourl") && (INFOURLDFLTSTR == val?.trimmingCharacters(in: .whitespacesAndNewlines)) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if (key == "infosave") && (val == (INFOSAVEDFLT ? "1" : "0")) {
            vo.optDict.removeValue(forKey: key)
            return true
        }


        return super.cleanOptDictDflts(key)
    }

    override func update(_ instr: String?) -> String {
        let retval = vo.optDict["infoval"]
        if let retval {
            return retval
        }
        return INFOVALDFLTSTR
    }

    override func voDrawOptions(_ ctvovc: configTVObjVC?) {

        DBGLog(String("ctvovc frame \(ctvovc?.view.frame)"))
        var frame = CGRect(x: MARGIN, y: ctvovc?.lasty ?? 0.0, width: 0.0, height: 0.0)

        var labframe = ctvovc?.configLabel("reported value:", frame: frame, key: "ivLab", addsv: true)

        frame.origin.x = (labframe?.size.width ?? 0.0) + MARGIN + SPACE
        let tfWidth = "9999999999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovc?.lfHeight ?? 0.0)

        frame = ctvovc?.configTextField(
            frame,
            key: "ivalTF",
            target: nil,
            action: nil,
            num: true,
            place: INFOVALDFLTSTR,
            text: vo.optDict["infoval"],
            addsv: true) ?? CGRect.zero

        frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN

        labframe = ctvovc?.configLabel("Write value in database and CSV", frame: frame, key: "infosaveLab", addsv: true)
        frame = CGRect(x: (labframe?.size.width ?? 0.0) + MARGIN + SPACE, y: frame.origin.y, width: labframe?.size.height ?? 0.0, height: labframe?.size.height ?? 0.0)
        frame = ctvovc?.configSwitch(
            frame,
            key: "infosaveBtn",
            state: vo.optDict["infosave"] == "1",
            addsv: true) ?? CGRect.zero
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        labframe = ctvovc?.configLabel("URL:", frame: frame, key: "iurlLab", addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN
        frame.size.width = rTracker_resource.getVisibleSize(of:ctvovc).width - 2 * MARGIN //ctvovc.view.frame.size.width - (2*MARGIN) ;
        //frame.size.width = 2 * ctvovc.view.frame.size.width ;

        let tsize = vo.optDict["infourl"]?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        DBGLog(String("frame width \(frame.size.width)  tsize width \(tsize?.width)"))
        if (tsize?.width ?? 0.0) > (frame.size.width - (2 * MARGIN)) {
            frame.size.width = (tsize?.width ?? 0.0) + (4 * MARGIN)
        }

        frame = ctvovc?.configTextField(
            frame,
            key: "iurlTF",
            target: nil,
            action: nil,
            num: false,
            place: INFOURLDFLTSTR,
            text: vo.optDict["infourl"],
            addsv: true) ?? CGRect.zero


        ctvovc?.lasty = frame.origin.y + (labframe?.size.height ?? 0.0) + MARGIN + SPACE
        ctvovc?.lastx = ((ctvovc?.lastx ?? 0.0) < frame.origin.x + frame.size.width + MARGIN ? frame.origin.x + frame.size.width + MARGIN : ctvovc?.lastx) ?? 0.0

        //[super voDrawOptions:ctvovc];
    }

    /* rtm here : export value option -- need to parse and match value if choice did not match
     */

    override func mapCsv2Value(_ inCsv: String) -> String {

        if Double(vo.optDict["infoval"]!)! != Double(inCsv)! {
            vo.optDict["infoval"] = inCsv
        }
        return inCsv
    }
}
