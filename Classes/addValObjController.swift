//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// addValObjController.swift
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
//  addValObjController.swift
//  rTracker
//
//  this screen supports create/edit of a value object, specifying its label, type and graph color/style
//
//  Created by Robert Miller on 12/05/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

///************
/// addValObjController.swift
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
//  addValObjController.swift
//  rTracker
//
//  Created by Robert Miller on 12/05/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import UIKit

var sizeVOTLabel = CGSize.zero
var sizeGTLabel = CGSize.zero
var colorCount = 0 // count of entries to show in center color picker spinner.
    // rtm swift let FONTSIZE = 20.0
    //#define FONTSIZE [UIFont labelFontSize]


    // MARK: -
    // MARK: core object methods and support

class addValObjController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    var tempValObj: valueObj?
    var parentTrackerObj: trackerObj? // this makes a retain cycle....
    var graphTypes: [AnyHashable]?
    var voOptDictStash: [String : String]?
    // UI element properties 
    @IBOutlet var labelField: UITextField!
    @IBOutlet var votPicker: UIPickerView!
    @IBOutlet var infoBtn: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    private var tmpVtype = 0
    private var tmpVcolor = 0
    private var tmpVGraphType = 0
    private var tmpVname: String?

    // setting to _foo breaks size calc for picker, think because is iboutlet?
    deinit {
        DBGLog("avoc dealloc")
    }
    init(nibName: String, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: -
    // MARK: view support

    //#define SCROLLVIEW_HEIGHT 100
    //#define SCROLLVIEW_WIDTH  320

    //#define SCROLLVIEW_CONTENT_HEIGHT 720
    //#define SCROLLVIEW_CONTENT_WIDTH  320

    override func viewDidLoad() {

        let cancelBtn = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(addTrackerController.btnCancel))
        cancelBtn.accessibilityIdentifier = "avoCancel"
        navigationItem.leftBarButtonItem = cancelBtn

        let saveBtn = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(addTrackerController.btnSave))
        saveBtn.accessibilityIdentifier = "avoSave"
        navigationItem.rightBarButtonItem = saveBtn


        //[self.navigationController setToolbarHidden:YES animated:YES];

        //UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
        /*
            UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [infoBtn setTitle:@"\u2699" forState:UIControlStateNormal];   // @"⚙"
             */
        infoBtn.titleLabel?.font = .systemFont(ofSize: 28.0)
        /*
            [infoBtn addTarget:self action:@selector(btnSetup) forControlEvents:UIControlEventTouchUpInside];
            infoBtn.frame = CGRectMake(0, 0, 44, 44);
            UIBarButtonItem *setupBtn = [[UIBarButtonItem alloc] initWithCustomView:infoBtn];
             */
        /*
             UIBarButtonItem *setupBtn = [[UIBarButtonItem alloc]
        								initWithTitle:@"Setup"
        								style:UIBarButtonItemStylePlain
        								target:self
        								action:@selector(btnSetup)];
            */

        //self.toolbarItems = @[setupBtn];


        sizeVOTLabel = addValObjController.maxLabel(fromArray: rTracker_resource.vtypeNames()) //self.parentTrackerObj.votArray];
        let allGraphs = valueObj.allGraphs()
        sizeGTLabel = addValObjController.maxLabel(fromArray: allGraphs)

        colorCount = rTracker_resource.colorSet().count

        // no effect after ios7 self.votPicker.showsSelectionIndicator = YES;

        if tempValObj == nil {
            tempValObj = valueObj(parentOnly: parentTrackerObj!)
            //self.graphTypes = nil;
            graphTypes = voState.voGraphSetNum() //[valueObj graphsForVOT:VOT_NUMBER];
            //[self updateScrollView:(NSInteger)VOT_NUMBER];
            safeDispatchSync({ [self] in
                votPicker.selectRow(parentTrackerObj?.nextColor ?? 0, inComponent: 1, animated: false)
            })
        } else {
            labelField.text = tempValObj!.valueName
            if 0 > tempValObj!.vcolor {
                tempValObj!.vcolor = 0 // paranoid in case switched from vot_info or vot_choice
            }
            votPicker.selectRow(tempValObj!.vcolor, inComponent: 1, animated: false) // first as no picker update effects
            votPicker.selectRow(tempValObj!.vtype, inComponent: 0, animated: false)
            update(forPickerRowSelect: tempValObj?.vtype ?? 0, inComponent: 0)
            votPicker.selectRow(tempValObj?.vGraphType ?? 0, inComponent: 2, animated: false)
            update(forPickerRowSelect: tempValObj?.vGraphType ?? 0, inComponent: 2)
            if VOT_INFO != tempValObj?.vtype {
                let g = allGraphs?[tempValObj?.vGraphType ?? 0] as? String
                graphTypes = tempValObj?.vos?.voGraphSet()

                var row = 0
                //while ( s = (NSString *) [e nextObject]) {
                for s in graphTypes ?? [] {
                    guard let s = s as? String else {
                        continue
                    }
                    if g == s {
                        break
                    }
                    row += 1
                }

                votPicker.reloadComponent(2)
                votPicker.selectRow(row, inComponent: 2, animated: false)
            }
        }

        title = "Configure Item"
        labelField.font = PrefBodyFont
        labelField.clearsOnBeginEditing = false
        labelField.delegate = self
        labelField.returnKeyType = .done
        //[self.labelField addTarget:self
        //			  action:@selector(labelFieldDone:)
        //	forControlEvents:UIControlEventEditingDidEndOnExit];
        //	DBGLog(@"frame: %f %f %f %f",self.labelField.frame.origin.x, self.labelField.frame.origin.y, self.labelField.frame.size.width, self.labelField.frame.size.height);

        // set graph paper background, unseen but still there if darkMode

        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)

        rTracker_resource.setViewMode(self)

        //[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:[rTracker_resource getLaunchImageName]]]];
        toolbar.isHidden = false
        navigationController?.isToolbarHidden = true

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)


        super.viewDidLoad()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        rTracker_resource.setViewMode(self)
        view.setNeedsDisplay()
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.

        //parentTrackerObj.colorSet = nil;
        //self.parentTrackerObj.votArray = nil;


    }

    /*
    - (void)viewDidUnload {
    	// Release any retained subviews of the main view.
    	// e.g. self.myOutlet = nil;

    	DBGLog(@"avoc didUnload");

    	self.votPicker = nil;
    	self.labelField = nil;
    	self.tempValObj = nil;
    	self.graphTypes = nil;
    	self.parentTrackerObj = nil;

    	self.navigationItem.rightBarButtonItem = nil;
    	self.navigationItem.leftBarButtonItem = nil;
    	//[self setToolbarItems:nil
    	//			 animated:NO];
    	self.title = nil;

    	[super viewDidUnload];
    }
    */

    override func viewWillAppear(_ animated: Bool) {

        DBGLog("avoc: viewWillAppear")

        if let tempValObj {
            //self.graphTypes = nil;
            graphTypes = tempValObj.vos?.voGraphSet()
            votPicker.reloadComponent(2) // in case added more graphtypes (eg tb count lines)
        }

        //[self.navigationController setToolbarHidden:NO animated:NO];

        super.viewWillAppear(animated)
    }

    // MARK: -
    // MARK: button press action methods

    func leave() {
        navigationController?.popViewController(animated: true)
    }

    //- (IBAction) btnSetup;
    func stashVals() {
        tmpVtype = tempValObj?.vtype ?? 0
        tmpVcolor = tempValObj?.vcolor ?? 0
        tmpVGraphType = tempValObj?.vGraphType ?? 0
        tmpVname = tempValObj?.valueName
    }

    func retrieveVals() {
        tempValObj?.vtype = tmpVtype
        tempValObj?.vcolor = tmpVcolor
        tempValObj?.vGraphType = tmpVGraphType
        tempValObj?.valueName = tmpVname
    }

    @IBAction func btnCancel() {
        //DBGLog(@"addVObjC: btnCancel was pressed!");
        retrieveVals()
        if voOptDictStash != nil {
            tempValObj!.optDict = voOptDictStash! // copyItems: true
            voOptDictStash = nil
        }
        leave()
    }

    @IBAction func btnSave() {
        //DBGLog(@"addVObjC: btnSave was pressed!");

        if (labelField.text?.count ?? 0) == 0 {
            rTracker_resource.alert("Save Item", msg: "Please set a name for this value to save", vc: self)
            return
        }
        
        if (VOT_CHOICE == tempValObj!.vtype) {
            if tempValObj!.optDict["c0"] == nil {
                rTracker_resource.alert("Save Choice", msg: "Please configure some choices to save (configure button at bottom)", vc: self)
                return
            }
        }
        /*
        if VOT_FUNC == tempValObj!.vtype {
            if tempValObj!.optDict["frep0"] == nil {
                rTracker_resource.alert("Save Function", msg: "Please configure function range (configure button at bottom)", vc: self)
                return
            }
        }
         */
        voOptDictStash = nil

        tempValObj!.valueName = labelField.text // in case neglected to 'done' keyboard
        labelField.resignFirstResponder()

        var row = votPicker.selectedRow(inComponent: 0)
        tempValObj!.vtype = row // works because vtype defs are same order as vtypeNames array entries
        row = votPicker.selectedRow(inComponent: 1)
        if (VOT_CHOICE == tempValObj!.vtype) || (VOT_INFO == tempValObj!.vtype) {
            tempValObj!.vcolor = -1 // choice color set in optDict per choice
        } else {
            tempValObj!.vcolor = row // works because vColor defs are same order as trackerObj.colorSet creator
        }

        if VOT_FUNC == tempValObj!.vtype {
            parentTrackerObj?.optDict["dirtyFns"] = "1"
        }

        row = votPicker.selectedRow(inComponent: 2)
        if VOT_INFO == tempValObj?.vtype {
            tempValObj?.vGraphType = VOG_NONE
        } else {
            tempValObj?.vGraphType = valueObj.mapGraphType((graphTypes)?[row] as? String)
        }

        if tempValObj?.vid == 0 {
            tempValObj?.vid = parentTrackerObj?.getUnique() ?? 0
        }

        // clear extraneous frv entries to keep db clean

        // no default fdlc so if set stays set - delete on del cons from fn

        //var v: Int?
        if let v = Int((tempValObj?.optDict["frep0"] ?? "")) {
            if v >= FREPDFLT {
                tempValObj?.optDict.removeValue(forKey: "frv0")
            }
        }
        if let v = Int(tempValObj?.optDict["frep1"] ?? "") {
            if v >= FREPDFLT {
                tempValObj?.optDict.removeValue(forKey: "frv1")
            }
        }
        if ((tempValObj?.optDict)?["autoscale"] as? String) == "0" {

            // override no autoscale if gmin, gmax both set and equal
            if let gminStr = self.tempValObj!.optDict["gmin"],
               let gmaxStr = self.tempValObj!.optDict["gmax"],
               let gmn = Double(gminStr),
               let gmx = Double(gmaxStr),
               gmn == gmx {
                self.tempValObj!.optDict["autoscale"] = "1"
            }
        }

        #if DEBUGLOG
        let selected = rTracker_resource.vtypeNames()[row]// [self.parentTrackerObj.votArray objectAtIndex:row];
        DBGLog(String("save label: \(tempValObj!.valueName) id: \(Int(tempValObj!.vid)) row: \(UInt(row)) = \(selected)"))
        #endif

        parentTrackerObj?.addValObj(tempValObj!)

        leave()
        //[self.navigationController popViewControllerAnimated:YES];
        //[parent.tableView reloadData];
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnSave()
    }

    @IBAction func btnSetup(_ sender: Any) {
        //DBGLog(@"addVObjC: config was pressed!");
        if (tempValObj?.vtype == VOT_FUNC) {
            let tvof = tempValObj!.vos as! voFunction
            if !tvof.checkVOs() {
                tvof.noVarsAlert()
                return
            }
        }
        let ctvovc = configTVObjVC(nibName: "configTVObjVC", bundle: nil)
        ctvovc.to = parentTrackerObj
        //[parentTrackerObj retain];
        ctvovc.vo = tempValObj
        if nil == voOptDictStash {
            voOptDictStash = tempValObj?.optDict // copyItems: true
        }
        //[tempValObj retain];
        ctvovc.modalTransitionStyle = .flipHorizontal
        //[self presentModalViewController:ctvovc animated:YES];
        present(ctvovc, animated: true)
    }

    // MARK: -
    // MARK: textField support Methods

    @IBAction func labelFieldDone(_ sender: UITextField) {
        sender.resignFirstResponder()
        tempValObj?.valueName = labelField.text
    }

    // MARK: -
    // MARK: utility routines

    class func maxLabel(fromArray arr: [AnyHashable]?) -> CGSize {
        var rsize = CGSize(width: 0.0, height: 0.0)
        //NSEnumerator *e = [arr objectEnumerator];
        //NSString *s;
        //while ( s = (NSString *) [e nextObject]) {
        for s in arr ?? [] {
            guard let s = s as? String else {
                continue
            }
            var tsize: CGSize
            //if (kIS_LESS_THAN_IOS7) {
            //    tsize = [s sizeWithFont:[UIFont systemFontOfSize:FONTSIZE]];
            //} else {
            let s1 = s + "  "
            tsize = s1.size(withAttributes: [
                NSAttributedString.Key.font: PrefBodyFont
            ])
            tsize.width = ceil(tsize.width)
            tsize.height = ceil(tsize.height)
            //}
            if tsize.width > rsize.width {
                rsize = tsize
            }
        }

        return rsize
    }

    // MARK: -
    // MARK: Picker Data Source Methods

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return rTracker_resource.vtypeNames().count//[self.parentTrackerObj.votArray count];
        case 1:
            //return [self.parentTrackerObj.colorSet count];
            return colorCount
        case 2:
            return graphTypes?.count ?? 0
        default:
            dbgNSAssert(false, "bad component for avo picker")
            return 0
        }
    }

    // MARK: Picker Delegate Methods

    let TEXTPICKER = 0
    #if TEXTPICKER

    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        switch component {
        case 0:
            return rTracker_resource.vtypeNames()?[row] as? String // [self.parentTrackerObj.votArray objectAtIndex:row];
        case 1:
            //return [self.paretntTrackerObj.colorSet objectAtIndex:row];
            return "color"
        case 2:
            return graphTypes?[row] as? String
        default:
            dbgNSAssert(0, "bad component for avo picker")
            return "boo."
        }
    }

    #else

    //let COLORSIDE = FONTSIZE
    let cgfFONTSIZE = CGFloat(FONTSIZE)
    let cgfCOLORSIDE = CGFloat(FONTSIZE)
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label: UILabel? = nil
        var frame: CGRect = CGRect.zero

        switch component {
        case 0:
            frame.size = sizeVOTLabel
            frame.size.width += cgfFONTSIZE
            frame.origin.x = 0.0
            frame.origin.y = 0.0
            label = UILabel(frame: frame)
            label?.backgroundColor = .clear //]greenColor];
            label?.text = rTracker_resource.vtypeNames()[row] // (self.parentTrackerObj.votArray)[row];
            label?.font = .boldSystemFont(ofSize: cgfFONTSIZE)
        case 1:
            frame.size.height = 1.2 * cgfCOLORSIDE
            frame.size.width = 2.0 * cgfCOLORSIDE
            frame.origin.x = 0.0
            frame.origin.y = 0.0
            label = UILabel(frame: frame)
            label?.backgroundColor = rTracker_resource.colorSet()[row]
        case 2:
            frame.size = sizeGTLabel
            frame.size.width += cgfFONTSIZE
            frame.origin.x = 0.0
            frame.origin.y = 0.0
            label = UILabel(frame: frame)
            label?.backgroundColor = .clear //greenColor];
            label?.text = (graphTypes)?[row] as? String
            label?.font = .boldSystemFont(ofSize: cgfFONTSIZE)
        default:
            dbgNSAssert(false, "bad component for avo picker")
            label = UILabel() // fix analysis warning
        }
        return label!

    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        //CGSize siz;
        switch component {
        case 0:
            return sizeVOTLabel.width + (2.0 * cgfFONTSIZE)
        case 1:
            return 3.0 * cgfCOLORSIDE
        case 2:
            return sizeGTLabel.width + (2.0 * cgfFONTSIZE)
        default:
            dbgNSAssert(false, "bad component for avo picker")
            return 0.0
        }
    }

    #endif

    func updateColorCount() {
        let oldcc = colorCount

        if tempValObj?.vtype == VOT_CHOICE {
            colorCount = 0
        } else if tempValObj?.vtype == VOT_INFO {
            colorCount = 0
        } else if tempValObj?.vGraphType == VOG_NONE {
            colorCount = 0
        } else if colorCount == 0 {
            colorCount = rTracker_resource.colorSet().count
        }

        if oldcc != colorCount {
            votPicker.reloadComponent(1)
        }
    }

    func update(forPickerRowSelect row: Int, inComponent component: Int) {
        if component == 0 {
            graphTypes = tempValObj?.vos?.voGraphSet()
            votPicker.reloadComponent(2)
            updateColorCount()
            //[self updateScrollView:row];
        } else if component == 1 {
        } else if component == 2 {
            updateColorCount()
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if labelField.isFirstResponder {
            labelField.resignFirstResponder()
        }
        if component == 0 {
            tempValObj?.vtype = row
        } else if component == 1 {
            tempValObj?.vcolor = row
        } else if component == 2 {
            tempValObj?.vGraphType = valueObj.mapGraphType((graphTypes)?[row] as? String)
        }

        update(forPickerRowSelect: row, inComponent: component)
    }
}
