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
    // UI element properties (now programmatically created)
    var labelField: UITextField!
    var votPicker: UIPickerView!
    var toolbar: UIToolbar!
    var typeLabel: UILabel!
    var graphLabel: UILabel!
    var containerView: UIView!
    private var tmpVtype = 0
    private var tmpVcolor = 0
    private var tmpVGraphType = 0
    private var tmpVname: String?

    // setting to _foo breaks size calc for picker, think because is iboutlet?
    deinit {
        DBGLog("avoc dealloc")
    }
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    // MARK: -
    // MARK: view support

    //#define SCROLLVIEW_HEIGHT 100
    //#define SCROLLVIEW_WIDTH  320

    //#define SCROLLVIEW_CONTENT_HEIGHT 720
    //#define SCROLLVIEW_CONTENT_WIDTH  320

    override func viewDidLoad() {

        let cancelBtn = rTracker_resource.createNavigationButton(target: self, action: #selector(addTrackerController.btnCancel), direction: .left)
        cancelBtn.accessibilityIdentifier = "avoCancel"
        navigationItem.leftBarButtonItem = cancelBtn

        let saveBtn = rTracker_resource.createDoneButton(target: self, action: #selector(addTrackerController.btnSave))
        saveBtn.accessibilityIdentifier = "avoSave"
        navigationItem.rightBarButtonItem = saveBtn

        // Create UI elements programmatically
        createUI()
        setupConstraints()
        connectActionsAndDelegates()

        sizeVOTLabel = addValObjController.maxLabel(fromArray: ValueObjectType.typeNames) //self.parentTrackerObj.votArray];
        let allGraphs = valueObj.allGraphs()
        sizeGTLabel = addValObjController.maxLabel(fromArray: allGraphs)

        colorCount = rTracker_resource.colorSet.count

        if tempValObj == nil {
            tempValObj = valueObj(parentOnly: parentTrackerObj!)
            // Set default graph type to 'no graph' for new valueObjs
            tempValObj?.vGraphType = VOG_NONE
            graphTypes = voState.voGraphSetNum() //[valueObj graphsForVOT:VOT_NUMBER];
            
            // Find the "no graph" row in graphTypes and select it
            var noGraphRow = 0
            if let graphTypes = graphTypes {
                for (index, graphType) in graphTypes.enumerated() {
                    if let graphTypeStr = graphType as? String, graphTypeStr == "no graph" {
                        noGraphRow = index
                        break
                    }
                }
            }
            
            safeDispatchSync({ [self] in
                votPicker.selectRow(parentTrackerObj?.nextColor ?? 0, inComponent: 1, animated: false)
                votPicker.selectRow(noGraphRow, inComponent: 2, animated: false)
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

    // MARK: - UI Creation Methods

    func createUI() {
        view.backgroundColor = .systemBackground

        // Create container view for label and text field
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Create "Label" label
        let nameLabel = UILabel()
        nameLabel.text = "Label"
        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)

        // Create text field
        labelField = UITextField()
        labelField.borderStyle = .roundedRect
        labelField.clearsOnBeginEditing = true
        labelField.font = UIFont.systemFont(ofSize: 12)
        labelField.minimumFontSize = 17
        labelField.accessibilityIdentifier = "valueName"
        labelField.accessibilityLabel = "value name"
        labelField.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(labelField)

        // Create Type label
        typeLabel = UILabel()
        typeLabel.text = "Type"
        typeLabel.font = UIFont.systemFont(ofSize: 17)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(typeLabel)

        // Create Graph label
        graphLabel = UILabel()
        graphLabel.text = "Graph"
        graphLabel.font = UIFont.systemFont(ofSize: 17)
        graphLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(graphLabel)

        // Create picker view
        votPicker = UIPickerView()
        votPicker.accessibilityHint = "left wheel sets value type"
        votPicker.accessibilityIdentifier = "avoPicker"
        votPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(votPicker)

        // Create toolbar
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Add modern edit button to toolbar
        let setupBtn = rTracker_resource.createActionButton(target: self, action: #selector(btnSetup(_:)), symbolName: "slider.horizontal.3", fallbackSystemItem: .edit)
        setupBtn.accessibilityLabel = "Setup"
        setupBtn.accessibilityHint = "Configure value object settings"
        toolbar.items = [setupBtn]

        // Container constraints
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            nameLabel.widthAnchor.constraint(equalToConstant: 50), // Fixed width for "Label" text

            labelField.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
            labelField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            labelField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            labelField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])
    }

    func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Container view
            containerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 187),
            containerView.heightAnchor.constraint(equalToConstant: 54),

            // Type label
            typeLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 80),
            typeLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 30),

            // Graph label
            graphLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -80),
            graphLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor),

            // Picker view
            votPicker.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            votPicker.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            votPicker.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 20),
            votPicker.heightAnchor.constraint(equalToConstant: 216),

            // Toolbar
            toolbar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    func connectActionsAndDelegates() {
        // Connect picker delegate and data source
        votPicker.delegate = self
        votPicker.dataSource = self

        // Connect text field action
        labelField.addTarget(self, action: #selector(labelFieldDone(_:)), for: .editingDidEndOnExit)
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

    override func viewWillAppear(_ animated: Bool) {

        DBGLog("avoc: viewWillAppear")

        if let tempValObj {
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
        if (labelField.text?.count ?? 0) == 0 {
            rTracker_resource.alert("Save Item", msg: "Please set a name for this value to save", vc: self)
            return
        }
        
        // ADD: Check for duplicate names
        let newName = labelField.text ?? ""
        if let parentObj = parentTrackerObj {
            for vo in parentObj.valObjTable {
                if vo.valueName == newName && vo.vid != tempValObj?.vid {
                    rTracker_resource.alert("Duplicate Name", msg: "A value with this name already exists. Please choose a different name.", vc: self)
                    return
                }
            }
        }
        
        if (VOT_CHOICE == tempValObj!.vtype) {
            if tempValObj!.optDict["c0"] == nil {
                rTracker_resource.alert("Save Choice", msg: "Please configure some choices to save (configure button at bottom)", vc: self)
                return
            }
        }

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
               let gmx = Double(gmaxStr) {
                if gmn == gmx {  // both set and equal then override
                    self.tempValObj!.optDict["autoscale"] = "1"
                }
            } else {  // not both set then override
                self.tempValObj!.optDict["autoscale"] = "1"
            }
        }

        #if DEBUGLOG
        let selected = ValueObjectType.typeNames[row]
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
        let ctvovc = configTVObjVC()
        ctvovc.to = parentTrackerObj
        //[parentTrackerObj retain];
        ctvovc.vo = tempValObj
        if nil == voOptDictStash {
            voOptDictStash = tempValObj?.optDict // copyItems: true
        }
        //[tempValObj retain];
        ctvovc.modalPresentationStyle = .fullScreen
        ctvovc.modalTransitionStyle = .coverVertical
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
            return ValueObjectType.typeNames.count//[self.parentTrackerObj.votArray count];
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
            return ValueObjectType.typeNames[row] // [self.parentTrackerObj.votArray objectAtIndex:row];
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
            label?.text = ValueObjectType.typeNames[row] // (self.parentTrackerObj.votArray)[row];
            label?.font = .boldSystemFont(ofSize: cgfFONTSIZE)
        case 1:
            frame.size.height = 1.2 * cgfCOLORSIDE
            frame.size.width = 2.0 * cgfCOLORSIDE
            frame.origin.x = 0.0
            frame.origin.y = 0.0
            label = UILabel(frame: frame)
            label?.backgroundColor = rTracker_resource.colorSet[row]
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
            colorCount = rTracker_resource.colorSet.count
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
