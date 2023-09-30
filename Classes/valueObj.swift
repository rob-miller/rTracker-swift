//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// valueObj.swift
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
//  valueObj.swift
//  rTracker
//
//  Created by Robert Miller on 12/05/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import CoreFoundation
import UIKit

//#import "trackerObj.h"

// supported valueObj types ; note these defns tied to rTracker-resource vtypeNames array
let VOT_NUMBER = 0
let VOT_TEXT = 1
let VOT_TEXTB = 2
let VOT_SLIDER = 3
let VOT_CHOICE = 4
let VOT_BOOLEAN = 5
let VOT_FUNC = 6
let VOT_INFO = 7

let VOT_MAX = 7

// image not yet
// #define VOT_IMAGE	7

// max number of choices for VOT_CHOICE
//#define CHOICES 6
//#define CHOICEARR @[ @(0), @(1), @(2), @(3), @(4), @(5) ]
let CHOICES = 8
let CHOICEARR = [NSNumber(value: 0), NSNumber(value: 1), NSNumber(value: 2), NSNumber(value: 3), NSNumber(value: 4), NSNumber(value: 5), NSNumber(value: 6), NSNumber(value: 7)]

// supported graphs ; tied to valueObj:mapGraphType
let VOG_DOTS = 0
let VOG_BAR = 1
let VOG_LINE = 2
let VOG_DOTSLINE = 3
let VOG_PIE = 4
//histogram...
let VOG_NONE = 5
let VOG_MAX = 5

// supported colors ; tied to trackerObj:colorSet
// not used
let VOC_RED = 0
let VOC_GREEN = 0
let VOC_BLUE = 0
let VOC_CYAN = 0
let VOC_YELLOW = 0
let VOC_MAGENTA = 0
let VOC_ORANGE = 0
let VOC_PURPLE = 0
let VOC_BROWN = 0
let VOC_WHITE = 0
let VOC_LIGHTGRAY = 0
let VOC_DARK_GRAY = 0

let VOC_MAX = 0

// vo config checkbutton default states
let AUTOSCALEDFLT = true
let ASFROMZERODFLT = true
let SHRINKBDFLT = false
let EXPORTVALBDFLT = false
let INTEGERSTEPSBDFLT = false
let DEFAULTENABLEDBDFLT = false
let SLIDRSWLBDFLT = false
let TBNLDFLT = false
let TBNIDFLT = true
let TBHIDFLT = false
let GRAPHDFLT = true
let NSWLDFLT = false
let GRAPHLASTDFLT = true
let SETSTRACKERDATEDFLT = false

// vo config textfield default values
let SLIDRMINDFLT = 0.0
let SLIDRMAXDFLT = 100.0
let SLIDRDFLTDFLT = 50.0
//#define PRIVDFLT		0
let FREPDFLT = -1
let FDDPDFLT = 2
let BOOLVALDFLT = 1.0
let BOOLVALDFLTSTR = "1"
let BOOLBTNCOLRDFLTSTR = "1"
let INFOVALDFLT = 1.0
let INFOVALDFLTSTR = "1.0"
let INFOURLDFLTSTR = ""
let INFOSAVEDFLT = false

let NUMDDPDFLT = -1


protocol voProtocol: AnyObject {
    func getValCap() -> Int
    func update(_ instr: String) -> String
    func voDisplay(_ bounds: CGRect) -> UIView
    func voTVCell(_ tableView: UITableView) -> UITableViewCell
    func voTVCellHeight() -> CGFloat
    func voGraphSet() -> [String]
    func voDrawOptions(_ ctvovc: configTVObjVC)
    func loadConfig()
    func setOptDictDflts()
    func cleanOptDictDflts(_ key: String) -> Bool
    func updateVORefs(_ newVID: Int, old oldVID: Int)
    func dataEditVDidLoad(_ vc: UIViewController)
    func dataEditVWAppear(_ vc: UIViewController)
    func dataEditVWDisappear(_ vc: UIViewController)
    //- (void) dataEditVDidUnload;
    //- (void) dataEditFinished;
    //- (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate;
    func newVOGD() -> vogd
    //- (void) recalculate;
    func setFnVals(_ tDate: Int)
    func doTrimFnVals()
    func resetData()
    func mapValue2Csv() -> String
    func mapCsv2Value(_ inCsv: String) -> String
}

//extern const NSInteger kViewTag;
    let numGraphs: [AnyHashable]? = nil
    let textGraphs: [AnyHashable]? = nil
    let pickGraphs: [AnyHashable]? = nil
    let boolGraphs: [AnyHashable]? = nil
    // MARK: -
    // MARK: core object methods and support


class valueObj: NSObject, UITextFieldDelegate {

    var vid = 0

    private var _vtype = 0
    var vtype: Int {
        get {
            _vtype
        }
        set(vt) {
            // called for setting property vtype
            //DBGLog(@"setVtype - allocating vos");
            _vtype = vt // not self as this is set fn!
            var tvos: voState
            switch vt {
            case VOT_NUMBER:
                tvos = voNumber(vo: self)
                //value = [[NSMutableString alloc] initWithCapacity:10];
            case VOT_SLIDER:
                tvos = voSlider(vo: self)
                //value = [[NSMutableString alloc] initWithCapacity:10];
                //[self.value setString:@"0"];
            case VOT_BOOLEAN:
                tvos = voBoolean(vo: self)
                //value = [[NSMutableString alloc] initWithCapacity:1];
                //[self.value setString:@"0"];
            case VOT_CHOICE:
                tvos = voChoice(vo: self)
                vcolor = -1
                //value = [[NSMutableString alloc] initWithCapacity:1];
                //[self.value setString:@"0"];
            case VOT_TEXT:
                tvos = voText(vo: self)
                //value = [[NSMutableString alloc] initWithCapacity:32];
            case VOT_FUNC:
                tvos = voFunction(vo: self)
                //value = [[NSMutableString alloc] initWithCapacity:32];
                //[self.value setString:@""];
            /*
            		case VOT_IMAGE:
            			tvos = [[voImage alloc] initWithVO:self];
            			//value = [[NSMutableString alloc] initWithCapacity:64];
            			//[self.value setString:@""];
            			break;
                         */
            case VOT_TEXTB:
                tvos = voTextBox(vo: self)
                //value = [[NSMutableString alloc] initWithCapacity:96];
                //[self.value setString:@""];
            case VOT_INFO:
                tvos = voInfo(vo: self)
                vcolor = -1
                //value = [[NSMutableString alloc] initWithCapacity:1];
                //[self.value setString:@"0"];
            default:
                dbgNSAssert(false, String(format:"valueObj init vtype %ld not supported", vt))
                tvos = voNumber(vo: self) // to clear analyzer worry
                _vtype = VOT_NUMBER // consistency if we get here
            }
            // vos = nil
            vos = tvos //as voState //as? (voState & voProtocol)
            //var tval: String?
            //tval = String(repeating: "\0", count: vos?.getValCap() ?? 0)
            // value = nil
            _value = ""
            //[self.value release];   // clear retain count from alloc + retain
        }
    }
    var vpriv = 0
    var valueName: String?

    private var _value: String? = nil
    var value: String {
        get {
            dbgNSAssert(vos != nil, "accessing vo.value with nil vos")
            if _value == nil {
                _value = ""
            }
            _value = vos?.update(_value!)
            return _value!
        }
        set {
            _value = newValue
        }
    }
    var vcolor = 0
    var vGraphType = 0

    var optDict: [String : String] = [:]
    var vos: voState?  //(voState & voProtocol)?
    var vogd: vogd?  // (vogd & voProtocol)?
    var display: UIView?
    var useVO = false
    //@property (nonatomic) BOOL retrievedData;
    var parentTracker: trackerObj

    private var _switchUseVO: UISwitch?
    var switchUseVO: UISwitch? {
        if _switchUseVO == nil {
            _switchUseVO = UISwitch()  // UIButton(type: .custom)
            _switchUseVO?.frame = CGRect.zero
            _switchUseVO?.contentVerticalAlignment = .center
            _switchUseVO?.contentHorizontalAlignment = .center
            _switchUseVO?.tag = kViewTag
            _switchUseVO?.addTarget(self, action: #selector(switchAction(_:)), for: .valueChanged)
        }
        return _switchUseVO
    }

 //, retrievedData;
    /*
    override convenience init() {
        self.init(data: nil, in_vid: 0, in_vtype: 0, in_vname: "", in_vcolor: 0, in_vgraphtype: 0, in_vpriv: 0)
    }
     */
    init(
        data parentTO: trackerObj,
        in_vid: Int,
        in_vtype: Int,
        in_vname: String?,
        in_vcolor: Int,
        in_vgraphtype: Int,
        in_vpriv: Int
    ) {
        //DBGLog(@"init vObj with args vid: %d vtype: %d vname: %@",in_vid, in_vtype, in_vname);
        parentTracker = parentTO
        super.init()
        //self.useVO = YES;

        vid = in_vid
        vtype = in_vtype // sets useVO

        valueName = in_vname
        vcolor = in_vcolor
        vGraphType = in_vgraphtype
    }

    init(dict parentTO: trackerObj, dict: [AnyHashable : Any]?) {
        /*
        	DBGLog(@"init vObj with dict vid: %d vtype: %d vname: %@",
                   [(NSNumber*) [dict objectForKey:@"vid"] integerValue],
                   [(NSNumber*) [dict objectForKey:@"vtype"] integerValue],
                   (NSString*) [dict objectForKey:@"valueName"]);
             */
        parentTracker = parentTO
        super.init()
        useVO = true
        vid = (dict?["vid"] as? NSNumber)?.intValue ?? 0
        parentTracker.minUniquev(vid)
        valueName = dict?["valueName"] as? String
        //self.optDict = (NSMutableDictionary*) dict[@"optDict"];
        if let ld = dict {
            if let od = ld["optDict"] as? [String: String] {
                self.optDict = od
            }
        }

        vpriv = (dict?["vpriv"] as? NSNumber)?.intValue ?? 0
        vtype = (dict?["vtype"] as? NSNumber)?.intValue ?? 0
        // setting vtype sets vo.useVO through vos init
        vcolor = (dict?["vcolor"] as? NSNumber)?.intValue ?? 0
        vGraphType = (dict?["vGraphType"] as? NSNumber)?.intValue ?? 0
    }

    convenience init(parentOnly parentTO: trackerObj) {
        self.init(data: parentTO, in_vid: 0, in_vtype: 0, in_vname: "", in_vcolor: 0, in_vgraphtype: 0, in_vpriv: 0)
    }

    init(
        fromDB parentTO: trackerObj,
        in_vid: Int
    ) {
        parentTracker = parentTO
        super.init()
        //self.useVO = YES;

        vid = in_vid

        var sql = String(format: "select type, color, graphtype from voConfig where id=%ld", in_vid)

        var in_vtype: Int
        var in_vcolor: Int
        var in_vgraphtype: Int

        (in_vtype, in_vcolor, in_vgraphtype) = parentTO.toQry2IntIntInt(sql: sql)!

        vtype = in_vtype // sets useVO
        vcolor = in_vcolor
        vGraphType = in_vgraphtype

        sql = String(format: "select name from voConfig where id==%ld", in_vid)
        valueName = parentTO.toQry2Str(sql:sql)

    }

    // MARK: -
    // MARK: dictionary to/from

    func dictFromVO() -> [String : Any]? {
        /*
            NSNumber *myvid = [NSNumber numberWithInteger:self.vid];
            NSNumber *myvtype = [NSNumber numberWithInteger:self.vtype];
            NSNumber *myvpriv = [NSNumber numberWithInteger:self.vpriv];
            NSString *myvaluename = self.valueName;
            NSNumber *myvcolor = [NSNumber numberWithInteger:self.vcolor];
            NSNumber *myvgt = [NSNumber numberWithInteger:self.vGraphType];
            NSDictionary *myoptdict = self.optDict;

            DBGLog(@"vid %@  vtype %@  vpriv %@  valuename %@  vcolor %@  vgt %@  optdict  %@",
                   myvid, myvtype, myvpriv, myvaluename,myvcolor,myvgt,myoptdict);

            DBGLog(@"vid %@  vtype %@  vpriv %@  valuename %@  vcolor  %@ vgt  %@ optdict  %@",
                   [NSNumber numberWithInteger:self.vid],
                    [NSNumber numberWithInteger:self.vtype],
                    [NSNumber numberWithInteger:self.vpriv],
                    self.valueName,
                    [NSNumber numberWithInteger:self.vcolor],
                    [NSNumber numberWithInteger:self.vGraphType],
                    self.optDict
                   );
            */
        return [
            "vid": NSNumber(value: vid),
            "vtype": NSNumber(value: vtype),
            "vpriv": NSNumber(value: vpriv),
            "valueName": valueName ?? "",
            "vcolor": NSNumber(value: vcolor),
            "vGraphType": NSNumber(value: vGraphType),
            "optDict": optDict
        ]
    }
    
    func setOptDict(_ od: [String : String]) {
        optDict = od
    }

    func setOptDictKeyVal(key: String, val: String) {
        optDict[key] = val
    }
    //- (void) txtDTF:(BOOL)num;
    func csvValue() -> String? {
        return vos?.mapValue2Csv()
    }

    func resetData() {
        vos?.resetData()
        _value = ""

        //self.retrievedData = NO;
        // do self.useVO in vos resetData
        //DBGLog(@"vo resetData %@",self.valueName);
    }

    // MARK: -
    // MARK: display fn dispatch

    func display(_ bounds: CGRect) -> UIView? {
        if display != nil && display?.frame.size.width != bounds.size.width {
            display = nil
        }

        if display == nil {
            DBGLog(String("vo new display name:  \(valueName) currVal: .\(value)."))
            display = vos?.voDisplay(bounds)
            display?.tag = kViewTag
        }
        return display
    }

    func setTrackerDateToNow() {
        parentTracker.trackerDate = Date()
    }

    // MARK: -
    // MARK: switchUseVO support

    func enableVO() {
        if !useVO {
            useVO = true
            switchUseVO?.isOn = true
            //checkButtonUseVO?.setImage(UIImage(named: "checked.png"), for: .normal)
        }
    }

    func disableVO() {
        if useVO {
            useVO = false
            switchUseVO?.isOn = false
            //checkButtonUseVO?.setImage(UIImage(named: "unchecked.png"), for: .normal)
        }
    }

    // called when the cell enable switch value changes
    @objc func switchAction(_ sender: Any?) {
        DBGLog(String("switch ticked for \(valueName) new state= \(!useVO)"))
        //var checkImage: UIImage?

        // note: we don't use 'sender' because this action method can be called separate from the button (i.e. from table selection)
        //self.useVO = !self.useVO;

        //TODO: re-write to use voStates as appropriate, vos:update returns '' if disabled so could keep values or should clear .value here
        useVO.toggle()
        if useVO {
            // if new state=TRUE (toggle useVO and set)   // enableVO ... disableVO
            //checkImage = UIImage(named: "checked.png")
            //   do in update():
            if vtype == VOT_SLIDER {
                _value = "\((display as? UISlider)?.value ?? 0.0)"
            }
        } else {
            // new state = FALSE
            //checkImage = UIImage(named: "unchecked.png")
            if vtype == VOT_CHOICE {
                (display as? UISegmentedControl)?.selectedSegmentIndex = UISegmentedControl.noSegment
            } else if vtype == VOT_SLIDER {

                var sdflt = Float(optDict["sdflt", default: String("\(SLIDRDFLTDFLT)")])

                if optDict["slidrswlb"] == "1" {
                    // handle slider option 'starts with last'
                    let to = parentTracker
                    var sql = String(format: "select count(*) from voData where id=%ld and date<%d", vid, Int(to.trackerDate!.timeIntervalSince1970))
                    let v = to.toQry2Int(sql:sql) ?? 0
                    if v > 0 {
                        sql = String(format: "select val from voData where id=%ld and date<%d order by date desc limit 1;", vid, Int(to.trackerDate!.timeIntervalSince1970))
                        sdflt = to.toQry2Float(sql:sql)
                    }
                }

                (display as? UISlider)?.setValue(sdflt!, animated: true)
            }
        }

        NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)

        //checkButtonUseVO?.setImage(checkImage, for: .normal)

    }

    // MARK: -
    // MARK: utility methods

    func describe(_ od: Bool) {
        #if DEBUGLOG
        if od {
            DBGLog(String("value id \(vid) name \(valueName ?? "") type \(vtype) value >\(value)< optDict:"))
            for (key, value) in optDict {
                DBGLog(String(" \(key) = \(value) "))
            }
        } else {
            DBGLog(String("value id \(vid) name \(valueName ?? "") type \(vtype) value >\(value)<"))
        }
        #endif
    }

    //+ (NSArray *) graphsForVOT:(NSInteger)vot;
    //- (NSArray *) graphsForVOT:(NSInteger)vot;
    class func allGraphs() -> [AnyHashable]? {
        return ["dots", "bar", "line", "line+dots", "pie"]
    }

    class func mapGraphType(_ gts: String?) -> Int {
        if gts == "dots" {
            return VOG_DOTS
        }
        if gts == "bar" {
            return VOG_BAR
        }
        if gts == "line" {
            return VOG_LINE
        }
        if gts == "line+dots" {
            return VOG_DOTSLINE
        }
        if gts == "pie" {
            return VOG_PIE
        }
        if gts == "no graph" {
            return VOG_NONE
        }

        dbgNSAssert(false, String("mapGraphTypes: no match for \(gts)"))

        return 0
    }

    func validate() {
        let VOINF = String(format: String("t: \(parentTracker.trackerName) vo: \(Int(vid)) \(valueName)"))
        //DBGLog(@"%@",VOINF);

        if vtype < 0 {
            DBGErr(String("\(VOINF) invalid vtype (negative): \(vtype)"))
            vtype = 0
        } else if vtype > VOT_MAX {
            DBGErr(String("\(VOINF) invalid vtype (too large): \(vtype) max vtype= \(VOT_MAX)"))
            vtype = 0
        }

        if vpriv < 0 {
            DBGErr(String("\(VOINF) invalid vpriv (too low): \(vpriv) minpriv= \(MINPRIV), 0 accepted"))
            vpriv = MINPRIV
        } else if vpriv > MAXPRIV {
            DBGErr(String("\(VOINF) invalid vtype (too large): \(vpriv) maxpriv= \(MAXPRIV)"))
            vpriv = 0
        }

        if VOT_CHOICE != vtype && VOT_INFO != vtype {
            if vcolor < 0 {
                DBGErr(String("\(VOINF) invalid vcolor (negative): \(vcolor)"))
                vcolor = 0
            } else if vcolor > (rTracker_resource.colorSet().count - 1) {
                DBGErr(String("\(VOINF) invalid vcolor (too large): \(vcolor) max color= \(UInt(rTracker_resource.colorSet().count - 1))"))
                vcolor = 0
            }
        }

        if vGraphType < 0 {
            DBGErr(String("\(VOINF) invalid vGraphType (negative): \(vGraphType)"))
            vGraphType = 0
        } else if vGraphType > VOG_MAX {
            DBGErr(String("\(VOINF) invalid vGraphType (too large): \(vGraphType) max vGraphType= \(VOG_MAX)"))
            vGraphType = 0
        }

        if VOT_CHOICE == vtype {
            if -1 != vcolor {
                DBGErr(String("\(VOINF) invalid choice vcolor (not -1): \(vcolor)"))
                vcolor = -1
            }

            for i in 0..<CHOICES {
                let key = "cc\(i)"
                if let chc = optDict[key] {
                    let ncol = Int(chc)!
                    if ncol < 0 {
                        DBGErr(String("\(VOINF) invalid choice \(i) color (negative): \(ncol)"))
                        optDict[key] = "0"
                    } else if ncol > (rTracker_resource.colorSet().count - 1) {
                        DBGErr(String("\(VOINF) invalid choice \(i) color (too large): \(ncol) max color= \(UInt(rTracker_resource.colorSet().count) - 1))"))
                        optDict[key] = "0"
                    }
                }
            }
        }
        if VOT_INFO == vtype {
            if -1 != vcolor {
                DBGErr(String("\(VOINF) invalid info vcolor (not -1): \(vcolor)"))
                vcolor = -1
            }
        }

    }

    func getLabelSize() -> CGSize {
        let labelSize = valueName?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        return labelSize ?? CGSize.zero

        //return [self.valueName sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize]]}];
    }

    func getLongTitleSize() -> CGSize {
        var labelSize = CGSize(width: 0, height: 0)
        if optDict["longTitle"] != nil && ("" != optDict["longTitle"]) {
            var maxSize = rTracker_resource.getKeyWindowFrame().size
            maxSize.height = 9999
            maxSize.width -= 2 * MARGIN
            let lts = optDict["longTitle"]
            let ltrect = lts?.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [
                NSAttributedString.Key.font: PrefBodyFont
            ], context: nil)
            labelSize.height += (ltrect?.size.height ?? 0.0) - (ltrect?.origin.y ?? 0.0)
            labelSize.width = ltrect?.size.width ?? 0.0
        }
        return labelSize

        //return [self.valueName sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize]]}];
    }

    // specific to VOT_CHOICE with optional values - seach dictionary for value, return index
    func getChoiceIndex(forValue val: String?) -> Int {
        //DBGLog(@"gciv val=%@",val);
        let inValF = CGFloat(Float(val ?? "") ?? 0.0)
        var minValF: CGFloat = 0.0
        var maxValF: CGFloat = 0.0
        //CGFloat closestValF = 99999999999.9F;
        var closestNdx = -1
        var closestDistanceF: CGFloat = 99999999999.9

        let inVal = "\(Float(val ?? "") ?? 0.0)"
        for i in 0..<CHOICES {
            let key = "cv\(i)"
            var tstVal = optDict[key]
            //if (tstVal) { // bug - don't get to handling default value below - introduced jan/feb, removed 8 mar 2015
            if nil == tstVal {
                tstVal = "\(Float(i) + 1)" // added 7.iv.2013 - need default value
            } else {
                tstVal = "\(Float(tstVal ?? "") ?? 0.0)"
            }
            //DBGLog(@"gciv test against %d: %@",i,tstVal);
            if tstVal == inVal {
                return i
            }

            let tstValF = CGFloat(Float(tstVal ?? "") ?? 0.0)
            if minValF > tstValF {
                minValF = tstValF
            }
            if maxValF < tstValF {
                maxValF = tstValF
            }
            let testDistanceF = CGFloat(abs(Float(tstValF - inValF)))
            if testDistanceF < closestDistanceF {
                closestDistanceF = testDistanceF
                closestNdx = i
            }
            //}
        }

        //DBGLog(@"gciv: no match");
        if (-1 != closestNdx) && (inValF > minValF) && (inValF < maxValF) {
            return closestNdx
        }
        return CHOICES

    }
}

/*
//@class voState;
func f(_ x: Any) -> CGFloat {
    CGFloat(x)
}
*/
