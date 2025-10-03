//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// configTVObjVC.swift
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
//  configValObjVC.h
//  rTracker
//
//  This screen displays configuration options for a tracker or a specific value object type.  The 
//  class provides routines to support labels, checkboxes, textboxes, etc., while the specific arrangement is 
//  delegated to the tracker or valueObj with addTOFields: or addVOFields:
//
//  Created by Robert Miller on 09/10/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

///************
/// configTVObjVC.swift
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
//  configTVObjVC.swift
//  rTracker
//
//  Created by Robert Miller on 09/10/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import UIKit
import SwiftUI

extension UIView {
    func viewWithAccessibilityIdentifier(_ identifier: String) -> UIView? {
        if self.accessibilityIdentifier == identifier {
            return self
        }
        for subview in subviews {
            if let found = subview.viewWithAccessibilityIdentifier(identifier) {
                return found
            }
        }
        return nil
    }
}

class configTVObjVC: UIViewController, UITextFieldDelegate {

    var vdlConfigVO = false
    var to: trackerObj?
    var vo: valueObj?
    var voOptDictStash: [AnyHashable : Any]?

    var wDict: [String : Any] = [:] // widget dictionary, puts names on UI elements
    
    var lasty: CGFloat = 0.0
    var lastx: CGFloat = 0.0
    var saveFrame = CGRect.zero
    var lfHeight: CGFloat = 0.0
    // UI element properties
    var navBar: UINavigationBar!
    var toolBar: UIToolbar!
    var scroll: UIScrollView!
    var activeField: UITextField? //just a pointer, no retain
    var processingTfDone = false
    var rDates: [AnyHashable]?

    //BOOL keyboardIsShown;

    //CGFloat LFHeight;  // textfield height based on parent viewcontroller's xib

    // MARK: -
    // MARK: core object methods and support

    // override init() {
    //    super.init()
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        processingTfDone = false
        rDates = []
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        processingTfDone = false
        rDates = []
    }
    
    
    // MARK: -
    // MARK: view support


    /*
     // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
        if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
            // Custom initialization
        }
        return self;
    }
    */

    @objc func btnDone(_ btn: UIButton?) {
        if vdlConfigVO {
            // done editing value obj
            if vo?.vtype == VOT_FUNC {
                if !((vo?.vos as? voFunction)?.funcDone() ?? false) {
                    rTracker_resource.alert("Invalid Function", msg: "The function definition is not complete.\n  Please modify it so the '❌' does not show.", vc: self)
                    return
                }
            }
        } else {
            // done editing tracker obj
        }

        //ios6 [self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)
    }

    //- (IBAction) backgroundTap:(id)sender {
    //	[activeField resignFirstResponder];
    //}
    //
    /*
    - (UIScrollView*) scroll {
        if (_scroll == nil) {
            CGRect svrect= CGRectMake(0,0,
                                      //self.navBar.frame.size.height,
                                      self.view.frame.size.width,
                                      self.view.frame.size.height-(self.navBar.frame.size.height + self.toolBar.frame.size.height));
            _scroll = [[UIScrollView alloc] initWithFrame:svrect];
        }
        return _scroll;
    }
    */

    @objc func btnChoiceHelp() {
        rTracker_resource.showContextualHelp(
            identifiers: ["value_choice"],
            from: toolBar,
            in: self
        )
    }

    @objc func btnInfoHelp() {
        rTracker_resource.showContextualHelp(
            identifiers: ["value_info"],
            from: toolBar,
            in: self
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create UI elements programmatically
        setupViews()

        var name: String?
        if vo == nil {
            name = to?.trackerName
            vdlConfigVO = false
        } else {
            name = vo?.valueName
            vdlConfigVO = true
        }

        //DBGLog(@"nav controller= %@",self.navigationController);


        if (name == nil) || (name == "") {
            let vtypeNames = ValueObjectType.typeNames[vo?.vtype ?? 0]
            name = "<\(vtypeNames)>"
             // (self.to.votArray)[self.vo.vtype]];
        }
        navBar.items?.last?.title = "Configure \(name ?? "")"
        name = nil

        let tsize = "X".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        lfHeight = tsize.height + 4
        //self.LFHeight = 31.0f;

        //LFHeight = ((addValObjController *) [self parentViewController]).labelField.frame.size.height;

        //self.lasty = self.navBar.frame.origin.y + self.navBar.frame.size.height + MARGIN;
        lasty = 2
        lastx = 2

        if vo == nil {
            addTOFields()
        } else {
            addVOFields(vo?.vtype ?? 0)
        }
        //self.scroll.contentOffset = CGPointMake(0, -self.navBar.frame.size.height);
        var svsize = rTracker_resource.getVisibleSize(of:self)
        if svsize.width < lastx {
            svsize.width = lastx
        }
        scroll.contentSize = CGSize(width: svsize.width, height: lasty + (3 * MARGIN))
        //[self.view addSubview:self.scroll];

        let doneBtn = rTracker_resource.createSaveButton(target: self, action: #selector(btnDone(_:)))
        doneBtn.accessibilityLabel = "Done"
        doneBtn.accessibilityIdentifier = "configtvo_done"

        if vdlConfigVO && vo?.vtype == VOT_FUNC {
            (vo?.vos as? voFunction)?.funcVDL(self, donebutton: doneBtn)
        } else if vdlConfigVO && (VOT_CHOICE == vo?.vtype || VOT_INFO == vo?.vtype) {
            // help button links for choice and info types
            let flexibleSpaceButtonItem = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)

            var fnHelpButtonItem: UIBarButtonItem?
            if VOT_CHOICE == vo?.vtype {
                fnHelpButtonItem = rTracker_resource.createHelpInfoButton(target: self, action: #selector(btnChoiceHelp))
            } else {
                fnHelpButtonItem = rTracker_resource.createHelpInfoButton(target: self, action: #selector(btnInfoHelp))
            }

            var items: [UIBarButtonItem] = [doneBtn, flexibleSpaceButtonItem]

            if let fnHelpButtonItem = fnHelpButtonItem {
                items.append(fnHelpButtonItem)
            }

            toolBar.items = items
        } else {
            toolBar.items = [doneBtn]
        }

        // set graph paper background

        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)

        rTracker_resource.setViewMode(self)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)


    }

    func setupViews() {
        view.backgroundColor = .systemBackground

        // Create navigation bar
        navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        // Create toolbar
        toolBar = UIToolbar()
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolBar)

        // Create scroll view
        scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Navigation bar constraints
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Scroll view constraints
            scroll.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: toolBar.topAnchor),

            // Toolbar constraints
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // Create a navigation item for the navigation bar
        let navItem = UINavigationItem(title: "Configure")
        navBar.setItems([navItem], animated: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        rTracker_resource.setViewMode(self)
        view.setNeedsDisplay()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnDone(nil)
    }

    func registerForKeyboard() {
        // register for keyboard notifications
        keyboardIsShown = false
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: view.window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: view.window)
    }
    
    func deregisterForKeyboard() {
        //DBGLog(@"remove kybd will show notifcation");
        // unregister for keyboard notifications while not visible.
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        // unregister for keyboard notifications while not visible.
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil)

    }
    override func viewWillAppear(_ animated: Bool) {

        registerForKeyboard()
        navigationController?.setToolbarHidden(false, animated: false)

        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        deregisterForKeyboard()
        super.viewWillDisappear(animated)
    }

    /*
    // Override to allow orientations other than the default portrait orientation.
    - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
        // Return YES for supported orientations
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
    */

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUGLOG
        let touch = touches.first
        let touchPoint = touch?.location(in: view)
        DBGLog(String("I am touched at \(touchPoint!.x), \(touchPoint!.y)."))
        #endif

        activeField?.resignFirstResponder()
    }

    // MARK: -
    // MARK: textField support Methods

    func textFieldDidBeginEditing(_ textField: UITextField) {
        //DBGLog(@"tf begin editing");
        activeField = textField
    }

    /*
     choice textfields have custom action

    - (void)textFieldDidEndEditing:(UITextField *)textField
    {
    	//DBGLog(@"tf end editing");
        if ((nil != activeField) && 
            (NSOrderedSame == [@"choice" 
            [self tfDone:activeField];
        activeField = nil;
    }
    */




    // MARK: -
    // MARK: keyboard notifications

    @objc func keyboardWillShow(_ n: Notification?) {
        rTracker_resource.willShowKeyboard(n, vwTarg: activeField, vwScroll: scroll)
    }

    @objc func keyboardWillHide(_ n: Notification?) {
        //DBGLog(@"handling keyboard will hide");
        rTracker_resource.willHideKeyboard()
    }

    // MARK: -
    // MARK: config region support Methods

    // MARK: newWidget methods

    func configLabel(_ text: String, frame: CGRect, key: String, addsv: Bool) -> CGRect {
        var frame = frame
        //frame.size = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont labelFontSize]]}];
        frame.size = text.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        
        frame.size.height = minLabelHeight(frame.size.height)  


        let rlab = UILabel(frame: frame)
        rlab.font = PrefBodyFont
        rlab.text = text
        rlab.backgroundColor = .clear
        wDict[key] = rlab
        
        if addsv {
            scroll.addSubview(rlab)
        }

        let retFrame = rlab.frame

        return retFrame
    }

    @objc func configOtherTrackerSrcView() {
        DBGLog("config other tracker view")
        
        let hostingController = UIHostingController(
            rootView: otViewController(
                valueName: vo?.valueName ?? "",
                selectedTracker: vo?.optDict["otTracker"],
                selectedValue: vo?.optDict["otValue"],
                otCurrent: vo?.optDict["otCurrent"] ?? (OTCURRDFLT ? "1" : "0") == "1",
                callerTrackerName: to?.trackerName, // Pass the caller's tracker name
                onDismiss: { [self] updatedTracker, updatedValue, updatedOtCurrent in
                    vo?.optDict["otTracker"] = updatedTracker
                    vo?.optDict["otValue"] = updatedValue
                    vo?.optDict["otCurrent"] = updatedOtCurrent ? "1" : "0"
                    if let button = scroll.subviews.first(where: { $0 is UIButton && $0.accessibilityIdentifier == "configtv_otSelBtn" }) as? UIButton {
                        DBGLog("otSelect view returned: \(updatedTracker ?? "nil") \(updatedValue ?? "nil") optDict is \(vo?.optDict["otTracker"] ?? "nil")  \(vo?.optDict["otValue"] ?? "nil")")
                        DispatchQueue.main.async {
                            let source = self.vo?.optDict["otTracker"] ?? ""
                            let value = self.vo?.optDict["otValue"] ?? ""
                            let str = (!source.isEmpty && !value.isEmpty) ? "\(source):\(value)" : "Configure"
                            button.setTitle(str, for: .normal)
                            button.sizeToFit()
                        }
                    }
                    // Update privacy level based on the other tracker's privacy settings
                    if let xtName = updatedTracker, !xtName.isEmpty,
                       let xvName = updatedValue, !xvName.isEmpty {
                        // Get the other tracker's privacy level
                        let xto = trackerObj(trackerList.shared.getTIDfromNameDb(xtName)[0])
                        let xtpriv = xto.getPrivacyValue()
                        
                        // Get the other value's privacy level
                        let xvo = xto.getValObjByName(xvName)
                        let xvprivStr = xvo?.optDict["privacy"] as? String ?? "\(MINPRIV)"
                        let xvpriv = Int(xvprivStr) ?? MINPRIV
                        
                        // Use the higher privacy level
                        let newPrivacyLevel = max(xtpriv, xvpriv)
                        
                        // Update the privacy text field
                        if let privTextField = wDict["gpTF"] as? UITextField {
                            privTextField.text = "\(newPrivacyLevel)"
                            
                            // Trigger text field's editing changed event to ensure it recognizes the change
                            privTextField.sendActions(for: .editingChanged)
                            
                            // If you need to explicitly mark it as needing to be saved, you might need to
                            // add some additional code or a custom method here
                        }
                    }
                }
            )
        )
        hostingController.modalPresentationStyle = .fullScreen
        hostingController.modalTransitionStyle = .coverVertical
        
        // Present the hosting controller
        present(hostingController, animated: true)
    }
    
    func configSwitch(_ frame: CGRect, key: String, state: Bool, addsv: Bool) -> CGRect {
        // Switch control
        let switchControl = UISwitch(frame: frame)
        // Set the switch state
        switchControl.isOn = state

        // Store the switch in a dictionary if needed, similar to how the button was stored
        wDict[key] = switchControl

        // Add target action for the switch
        switchControl.addTarget(self, action: #selector(switchAction(_:)), for: .valueChanged)

        // Accessibility identifier setup
        if vo == nil {
            switchControl.accessibilityIdentifier = "\(to!.trackerName ?? "tnull")_\(key)"
        } else {
            switchControl.accessibilityIdentifier = "\(vo!.vos!.tvn())_\(key)"
        }

        // Adding the switch to the scroll view
        if addsv {
            scroll.addSubview(switchControl)
        }

        return frame
    }

    // ui updates for switch changes
    func switchUpdate(okey: String, newState: Bool) {
        if (okey == "ahksrc") {
            // number apple Health data source switch, enable config button depending on switch state
            if let button = scroll.subviews.first(where: { $0 is UIButton && $0.accessibilityIdentifier == "configtv_ahSelBtn" }) as? UIButton {
                button.isEnabled = newState
            }
        } else if (okey == "otsrc") {
            // other tracker data source switch, enable config button depending on switch state
            if let button = scroll.subviews.first(where: { $0 is UIButton && $0.accessibilityIdentifier == "configtv_otSelBtn" }) as? UIButton {
                button.isEnabled = newState
            }
        }
    }
    
    // The action method for the switch
    @objc func switchAction(_ sender: UISwitch) {
        // Handle the switch action here
        let key = sender.accessibilityIdentifier
        // Update your model or perform an action based on the switch's state
        DBGLog("Switch for \(key ?? "") is now \(sender.isOn ? "ON" : "OFF")")
        
        // If turning on Apple Health, turn off Other Tracker
        if sender == (wDict["ahsBtn"] as? UISwitch) && sender.isOn {
            if let otSwitch = wDict["otsBtn"] as? UISwitch, otSwitch.isOn {
                // Simply turn off the other tracker switch
                // Its switchAction will be called automatically and update everything
                otSwitch.isOn = false
                switchAction(otSwitch)
            }
        }
        // If turning on Other Tracker, turn off Apple Health
        else if sender == (wDict["otsBtn"] as? UISwitch) && sender.isOn {
            if let ahSwitch = wDict["ahsBtn"] as? UISwitch, ahSwitch.isOn {
                // Simply turn off the Apple Health switch
                // Its switchAction will be called automatically and update everything
                ahSwitch.isOn = false
                switchAction(ahSwitch)
            }
        }
        
        // Table-driven mapping for switch handling
        let switchMappings: [(switchKey: String, okey: String, dfltState: Bool)] = [
            ("nasBtn", "autoscale", AUTOSCALEDFLT),
            ("csbBtn", "shrinkb", SHRINKBDFLT),
            ("cevBtn", "exportvalb", EXPORTVALBDFLT),
            ("stdBtn", "setstrackerdate", SETSTRACKERDATEDFLT),
            ("sisBtn", "integerstepsb", INTEGERSTEPSBDFLT),
            ("sswlBtn", "slidrswlb", SLIDRSWLBDFLT),
            ("tbnlBtn", "tbnl", TBNLDFLT),
            ("tbniBtn", "tbni", TBNIDFLT),
            ("tbhiBtn", "tbhi", TBHIDFLT),
            ("ggBtn", "graph", GRAPHDFLT),
            ("swlBtn", "nswl", NSWLDFLT),
            ("ahsBtn", "ahksrc", AHKSRCDFLT),
            ("otsBtn", "otsrc", OTSRCDFLT),
            ("srBtn", "savertn", SAVERTNDFLT),
            ("calOnlyLastBtn", "calOnlyLast", CALONLYLASTDFLT),
            ("infosaveBtn", "infosave", INFOSAVEDFLT),
            ("hrsminsBtn", "hrsmins", HRSMINSDFLT)
        ]

        var okey: String?
        var dfltState: Bool?
        
        // Find matching switch in table
        for mapping in switchMappings {
            if sender == (wDict[mapping.switchKey] as? UISwitch) {
                okey = mapping.okey
                dfltState = mapping.dfltState
                break
            }
        }
        
        // Handle special cases
        if sender == (wDict["nasBtn"] as? UISwitch) {
            // valueObj autoscale special handling
            if ((vo?.optDict)?[okey!] as? String) == "0" {
                // will switch on
                removeGraphMinMax()
                //[self addGraphFromZero];  // ASFROMZERO
            } else {
                //[self removeGraphFromZero];
                addGraphMinMax() // ASFROMZERO
            }
        } else if sender == (wDict["strkBtn"] as? UISwitch) {
            // tracker enable streak reporting
            if sender.isOn {
                trackerList.shared.streakTracker(to!.toid)
            } else {
                trackerList.shared.unstreakTracker(to!.toid)
            }
        }
        
        if okey == nil && sender != (wDict["strkBtn"] as? UISwitch) {
            dbgNSAssert(false, "ckButtonAction cannot identify switch")
        }

        if let okey = okey, let dfltState = dfltState {
            let dflt = dfltState ? "1" : "0"
            let ndflt = dfltState ? "0" : "1"
            var newState : Bool = false
            
            if vo == nil {
                if to!.optDict[okey] as? String ?? "" == ndflt {
                    to!.optDict[okey] = dflt
                    newState = dfltState ? true : false // going to default state
                } else {
                    to!.optDict[okey] = ndflt
                    newState = dfltState ? false : true // going to not default state
                }
                
            } else {
                if (vo!.optDict[okey]) == ndflt {
                    vo!.optDict[okey] = dflt
                    newState = dfltState ? true : false // going to default state
                } else {
                    vo!.optDict[okey] = ndflt
                    newState = dfltState ? false : true // going to not default state
                }
                
            }
            switchUpdate(okey:okey, newState:newState)
            dbgNSAssert(newState == sender.isOn, "state mismatch on switch for key \(okey)")
        }
    }

    
    func configActionBtn(_ pframe: CGRect, key: String?, label: String?, target: Any?, action: Selector) -> CGRect {
        // button consisting of title only which starts an action like 'database info' or 'set reminders'
        // doesn't use rtracker-resource ios26 buttons because more bespoke, title only buttons without obvious sf symbol

        let button = UIButton(type: .roundedRect)
        var frame = pframe
        button.titleLabel?.font = PrefBodyFont
        if let font = button.titleLabel?.font {
            frame.size = label?.size(withAttributes: [
                NSAttributedString.Key.font: font
            ]) ?? CGSize.zero
            frame.size.width += 4 * SPACE
        }

        if frame.origin.x == -1.0 {
            frame.origin.x = view.frame.size.width - (frame.size.width + MARGIN) // right justify
        }
        button.frame = frame
        button.setTitle(label, for: .normal)

        if let key {
            wDict[key] = button
        }

        button.addTarget(target, action: action, for: .touchUpInside)

        button.accessibilityIdentifier = "configtv_\(key ?? label!)"
        //[self.view addSubview:button];
        scroll.addSubview(button)

        return frame
    }

    
    
    @objc func tfDone(_ tf: UITextField?) {
        if true == processingTfDone {
            return
        }
        processingTfDone = true

        // Table-driven mapping for text field handling
        let tfMappings: [(tfKey: String, okey: String, nkey: String?)] = [
            ("nminTF", "gmin", "nmaxTF"),
            ("nmaxTF", "gmax", nil),
            ("sminTF", "smin", "smaxTF"),
            ("smaxTF", "smax", "sdfltTF"),
            ("sdfltTF", "sdflt", nil),
            ("gpTF", "privacy", nil),
            ("gyTF", "yline1", nil),
            ("gmdTF", "graphMaxDays", nil),
            ("deTF", "dfltEmail", nil),
            ("fr0TF", "frv0", nil),
            ("fr1TF", "frv1", nil),
            ("fnddpTF", "fnddp", nil),
            ("numddpTF", "numddp", nil),
            ("bvalTF", "boolval", nil),
            ("ivalTF", "infoval", nil),
            ("iurlTF", "infourl", nil),
            (CTFKEY, LCKEY, nil)
        ]

        var okey: String? = nil
        var nkey: String? = nil
        
        // Find matching text field in table
        for mapping in tfMappings {
            if tf == (wDict[mapping.tfKey] as? UITextField) {
                okey = mapping.okey
                nkey = mapping.nkey
                break
            }
        }
        
        dbgNSAssert(okey != nil, "mtfDone cannot identify tf: \(tf?.accessibilityIdentifier ?? "unknown")")
        
        // Handle special privacy validation
        if tf == (wDict["gpTF"] as? UITextField) {
            let currPriv = privacyValue
            var newPriv = Int(tf?.text ?? "") ?? 1
            if newPriv > currPriv {
                //newPriv = currPriv;
                tf?.text = "\(currPriv)"
                let msg = "rTracker's privacy level is currently set to \(currPriv).  Setting an item to a higher privacy level than the current setting is disallowed."
                rTracker_resource.alert("Privacy higher than current", msg: msg, vc: self)
            }
            newPriv = Int(tf?.text ?? "") ?? 1
            if newPriv < PRIVDFLT {
                tf?.text = "\(PRIVDFLT)"
                let msg = "Setting a privacy level below \(PRIVDFLT) is disallowed."
                rTracker_resource.alert("Privacy setting too low", msg: msg, vc: self)
            }
        }


        if vo == nil {
            // tracker config
            DBGLog(String("to set \(okey): \(tf?.text)"))
            to!.optDict[okey!] = tf?.text
        } else {
            // valobj config
            DBGLog(String("vo set \(okey): \(tf?.text)"))
            vo!.optDict[okey!] = tf?.text
        }

        if let nkey, let nextField = wDict[nkey] as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            tf?.resignFirstResponder()
        }

        activeField = nil

        processingTfDone = false

    }

    func configTextField(_ pframe: CGRect, key: String?, target: Any?, action: Selector?, num: Bool, place: String?, text: String?, addsv: Bool) -> CGRect {


        var frame = pframe
        frame.origin.y -= TFXTRA
        frame.size.height = minLabelHeight(frame.size.height)
        
        let rtf = rTracker_resource.rrConfigTextField(
            frame,
            key: key,
            target: target ?? self,
            delegate: self,
            action: action ?? #selector(tfDone(_:)),
            num: num,
            place: place,
            text: text)

        wDict[key ?? ""] = rtf
        if vo == nil {
            rtf?.accessibilityIdentifier = "\(to?.trackerName ?? "tnull")_\(key!)"
        } else {
            rtf?.accessibilityIdentifier = "\(vo!.vos!.tvn())_\(key!)"
        }
        
        if addsv {
            if let rtf {
                scroll.addSubview(rtf)
            }
        }
        //[self.view addSubview:rtf];

        return frame
    }

    func configTextView(_ frame: CGRect, key: String?, text: String?) -> CGRect {
        /*
            if (frame.origin.x + frame.size.width > [rTracker_resource getKeyWindowWidth]) {
                frame.origin.x = MARGIN;
                frame.origin.y += MARGIN + frame.size.height;
            }
            */
        let rtv = UITextView(frame: frame)
        rtv.isEditable = false
        wDict[key ?? ""] = rtv

        rtv.text = text
        //[rtv scrollRangeToVisible: (NSRange) { (NSUInteger) ([text length]-1), (NSUInteger)1 }];  // works 1st time but text is cached so doesn't work subsequently

        //[self.view addSubview:rtv];
        rtv.accessibilityIdentifier = "configtv_\(key!)"
        scroll.addSubview(rtv)

        return frame
    }

    func configPicker(_ frame: CGRect, key: String?, caller: Any?) -> CGRect {
        var frame = frame
        let myPickerView = UIPickerView(frame: .zero)
        frame.size = myPickerView.sizeThatFits(.zero)
        frame.size.width = view.frame.size.width - (2 * MARGIN)
        myPickerView.frame = frame

        myPickerView.autoresizingMask = .flexibleWidth

        // this view controller is the data source and delegate
        myPickerView.delegate = caller as? UIPickerViewDelegate
        myPickerView.dataSource = caller as? UIPickerViewDataSource

        wDict[key ?? ""] = myPickerView
        if vo == nil {
            myPickerView.accessibilityIdentifier = "\(to!.trackerName ?? "tnull")_\(key!)"
        } else {
            myPickerView.accessibilityIdentifier = "\(vo!.vos!.tvn())_\(key!)"
        }
        DBGLog("picker acc id: \(myPickerView.accessibilityIdentifier!)")
        scroll.addSubview(myPickerView)

        return frame
    }

    // MARK: autoscale / graph min/max options

    func removeGraphMinMax() {
        // [UIView beginAnimations:nil context:NULL];
        // [UIView setAnimationBeginsFromCurrentState:YES];
        // [UIView setAnimationDuration:kAnimationDuration];

        UIView.animate(withDuration: 0.2, animations: { [self] in
            (wDict["nminLab"] as? UIView)?.removeFromSuperview()
            (wDict["nminTF"] as? UIView)?.removeFromSuperview()
            (wDict["nmaxLab"] as? UIView)?.removeFromSuperview()
            (wDict["nmaxTF"] as? UIView)?.removeFromSuperview()
        })

        // [UIView commitAnimations];
    }

    func addGraphMinMax() {

        UIView.animate(withDuration: 0.2, animations: { [self] in
            if let aWDict = wDict["nminLab"] as? UIView {
                scroll.addSubview(aWDict)
            }
            if let aWDict = wDict["nminTF"] as? UIView {
                scroll.addSubview(aWDict)
            }
            if let aWDict = wDict["nmaxLab"] as? UIView {
                scroll.addSubview(aWDict)
            }
            if let aWDict = wDict["nmaxTF"] as? UIView {
                scroll.addSubview(aWDict)
            }
        })

        //[UIView commitAnimations];
    }

    func yAutoscale(_ frame: CGRect) -> CGRect {
        var frame = frame
        var labframe: CGRect


        labframe = configLabel("Graph Y axis:", frame: frame, key: "ngLab", addsv: true)
        frame.origin.y += labframe.size.height + MARGIN

        labframe = configLabel("Auto Scale:", frame: frame, key: "nasLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        _ = configSwitch(
            frame,
            key: "nasBtn",
            state: !((vo!.optDict["autoscale"]) == "0"),
            addsv: true)

        //if (! autoscale) {  still need to calc lasty, make room before general options

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("min:", frame: frame, key: "nminLab", addsv: false)

        frame.origin.x = labframe.size.width + MARGIN + SPACE
        let tfWidth = "9999999999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(lfHeight) 

        _ = configTextField(
            frame,
            key: "nminTF",
            target: nil,
            action: nil,
            num: true,
            place: "<number>",
            text: (vo?.optDict)?["gmin"] /*was ngmin */ as? String,
            addsv: false)

        frame.origin.x += tfWidth + MARGIN
        labframe = configLabel(" max:", frame: frame, key: "nmaxLab", addsv: false)

        frame.origin.x += labframe.size.width + SPACE
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(lfHeight) 

        _ = configTextField(
            frame,
            key: "nmaxTF",
            target: nil,
            action: nil,
            num: true,
            place: "<number>",
            text: (vo?.optDict)?["gmax"] /* was ngmax */ as? String,
            addsv: false)

        if (vo!.optDict["autoscale"]) == "0" {
            addGraphMinMax()
        }

        frame.origin.y += MARGIN + frame.size.height
        return frame
    }

    // MARK: -
    // MARK: general opts for all

    @objc func notifyReminderView() {
        DBGLog("notify reminder view!")
        let nrvc = notifyReminderViewController(nibName: nil, bundle: nil)
        nrvc.tracker = to
        nrvc.modalPresentationStyle = .fullScreen
        nrvc.modalTransitionStyle = .coverVertical
        deregisterForKeyboard()
        present(nrvc, animated: true) {
            nrvc.dismissalHandler = { [weak self] in
                self?.registerForKeyboard()
            }
        }
    }

    // prefer don't do this - better to just reload plist
    // added plist/dict load code so match on vid and valueName='recover%d' will overwrite
    func recoverValuesBtn() {
        var recoverCount = 0
        let Ids = to!.toQry2AryI(sql: "select distinct id from voData order by id")
        for ni in Ids {
            if ni != to!.toQry2Int(sql:"select id from voConfig where id=\(ni)") {
                let recoverName = "recover\(ni)"
                let sql = "insert into voConfig (id, rank, type, name, color, graphtype,priv) values (\(ni), \(0), \(VOT_NUMBER), '\(recoverName)', \(0), \(VOG_DOTS), \(PRIVDFLT));"
                to?.toExecSql(sql:sql)
                recoverCount += 1
            }
        }
        var msg: String?
        if recoverCount != 0 {
            msg = "\(recoverCount)"
            to?.loadConfig()
        } else {
            msg = "no"
        }

        rTracker_resource.alert("Recovered Values", msg: (msg ?? "") + " values recovered", vc: self)

    }

    /*
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        if (0 != buttonIndex) {
            [self recoverValuesBtn];
        }
    }
    */
        
    @objc func setRemindersBtn() {
        to?.reminders2db()
        to?.setReminders()
    }

    func displayDbInfo() {
        var titleStr: String?
        rTracker_resource.setNotificationsEnabled()
        var sql = "select count(*) from trkrData"
        let dateEntries = to?.toQry2Int(sql:sql) ?? 0
        sql = "select count(*) from voData"
        let dataPoints = to?.toQry2Int(sql:sql) ?? 0
        sql = "select count(*) from voConfig"
        let itemCount = to?.toQry2Int(sql:sql) ?? 0

        titleStr = String(format: "tracker number %ld\n%d values\n%d date entries\n%d data points", Int(to?.toid ?? 0), itemCount, dateEntries, dataPoints)

        sql = "select count(*) from (select * from voData where id not in (select id from voConfig))"
        let orphanDatapoints = to?.toQry2Int(sql:sql) ?? 0

        if 0 < orphanDatapoints {
            titleStr = (titleStr ?? "") + "\n\(orphanDatapoints) missing item data points"
        }

        sql = "select count(*) from reminders"
        let reminderCount = to?.toQry2Int(sql:sql) ?? 0

        let scheduledReminderCount = rDates?.count ?? 0
        titleStr = (titleStr ?? "") + "\n\n\(reminderCount) stored reminders\n\(scheduledReminderCount) scheduled reminders"
        for date in rDates ?? [] {
            guard let date = date as? Date else {
                continue
            }
            titleStr = (titleStr ?? "") + "\n\(DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .short))"
        }

        if !rTracker_resource.getNotificationsEnabled() {
            titleStr = (titleStr ?? "") + "\n\n- Notifications Disabled -\nEnable in System Preferences."
        }

        let infoDict = Bundle.main.infoDictionary

        if let anInfoDict = infoDict?["CFBundleDisplayName"], let aAnInfoDict = infoDict?["CFBundleShortVersionString"], let aAAnInfoDict = infoDict?["CFBundleVersion"] {
            titleStr = (titleStr ?? "") + "\n\n\(anInfoDict) \(aAnInfoDict) [\(aAAnInfoDict)]\nhttps://github.com/rob-miller/rTracker-swift"
        }

        safeDispatchSync({ [self] in
            if 0 < orphanDatapoints {
                let alert = UIAlertController(
                    title: to?.trackerName,
                    message: titleStr,
                    preferredStyle: .alert)

                let defaultAction = UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { action in
                    })
                let recoverAction = UIAlertAction(
                    title: "recover missing items",
                    style: .default,
                    handler: { [self] action in
                        recoverValuesBtn()
                    })

                alert.addAction(defaultAction)
                alert.addAction(recoverAction)

                present(alert, animated: true)
            } else {
                rTracker_resource.alert(to?.trackerName, msg: titleStr, vc: self)
            }
        })
    }

    @objc func dbInfoBtn() {
        // wait for checking notifications, then display above

        rDates?.removeAll()

        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { [self] notifications in
            for i in 0..<notifications.count {
                let oneEvent = notifications[i]
                let userInfoCurrent = oneEvent.content.userInfo
                //DBGLog(@"pending reminder for %ld my tid %ld", (long) [userInfoCurrent[@"tid"] integerValue], (long) self.to.toid);
                if (userInfoCurrent["tid"] as? NSNumber)!.intValue == to?.toid {
                    let nextTD = (oneEvent.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                    //DBGLog(@"td = %@", nextTD);
                    if let nextTD {
                        rDates?.append(nextTD)
                    }
                }
            }
            displayDbInfo()
        })

    }

    //- (void) drawGeneralVoOpts 
    //{
    //}

    func drawGeneralToOpts() {
        guard let to = to else {
            return
        }
            
        var frame = CGRect(x: MARGIN, y: lasty, width: 0.0, height: 0.0)

        var labframe = configLabel("save returns to tracker list:", frame: frame, key: "srLab", addsv: true)

        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        //-- save returns to tracker list button

        frame = configSwitch(
            frame,
            key: "srBtn",
            state: !(to.optDict["savertn"] as? String ?? "" == "0"),  // default is true "1"
            addsv: true)

        //-- privacy level label

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Privacy level:", frame: frame, key: "gpLab", addsv: true)

        //-- privacy level textfield

        frame.origin.x += labframe.size.width + SPACE

        var tfWidth = "9999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(lfHeight)

        frame = configTextField(
            frame,
            key: "gpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(PRIVDFLT)",
            text: to.optDict["privacy"] as? String,
            addsv: true)

        //-- graph max _ days label

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Graph limit:", frame: frame, key: "glLab", addsv: true)

        //-- graph max _ days textfield

        frame.origin.x += labframe.size.width + SPACE

        tfWidth = "999999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(lfHeight)

        var gMaxDays = to.optDict["graphMaxDays"] as? String
        if gMaxDays == "0" {
            gMaxDays = ""
        }

        frame = configTextField(
            frame,
            key: "gmdTF",
            target: nil,
            action: nil,
            num: true,
            place: " ",
            text: gMaxDays,
            addsv: true)

        //-- graph max _ days label 2  

        frame.origin.x += tfWidth + SPACE
        frame = configLabel("days", frame: frame, key: "gl2Lab", addsv: true)


        //-- default email label

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Default email:", frame: frame, key: "deLab", addsv: true)

        //-- default email _ textfield

        frame.origin.x += labframe.size.width + SPACE
        frame.size.width = view.frame.size.width - (2 * SPACE) - labframe.size.width - MARGIN
        frame.size.height = minLabelHeight(lfHeight)

        let dfltEmail = to.optDict["dfltEmail"] as? String

        frame = configTextField(
            frame,
            key: "deTF",
            target: nil,
            action: nil,
            num: false,
            place: " ",
            text: dfltEmail,
            addsv: true)


        //-- streak enable
        
        
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Streak counter:", frame: frame, key: "gpLab", addsv: true)

        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)
        
        frame = configSwitch(
            frame,
            key: "strkBtn",
            state: trackerList.shared.isTrackerStreaked(to.toid),
            addsv: true)

        
        if nil == vo {

            frame.origin.x = MARGIN
            //frame.origin.x += frame.size.width + MARGIN + SPACE;
            frame.origin.y += MARGIN + frame.size.height

            if nil != to.dbName {

                // reminder config button:

                frame = configActionBtn(frame, key: nil, label: "Reminders", target: self, action: #selector(notifyReminderView))

                // dbInfo values button:

                frame.origin.x = MARGIN
                frame.origin.y += MARGIN + frame.size.height

                frame = configActionBtn(frame, key: nil, label: "database info", target: self, action: #selector(dbInfoBtn))

                // 'reset reminders' button

                frame.origin.x = MARGIN
                frame.origin.y += MARGIN + frame.size.height

                frame = configActionBtn(frame, key: nil, label: "set reminders", target: self, action: #selector(setRemindersBtn))
            } else {

                frame.origin.y += MARGIN + frame.size.height
                frame = configLabel("(Save to enable reminders)", frame: frame, key: "erLab", addsv: true)
            }
        }

        lasty = frame.origin.y + frame.size.height + (3 * MARGIN)
        lastx = frame.origin.x + frame.size.width + (3 * MARGIN)
    }

    func removeSVFields() {
        /*
         for key in wDict {
             //DBGLog(@"removing %@",key);
             (wDict[key] as? UIView).removeFromSuperview()
         }
         */
        wDict.values.compactMap({ $0 as? UIView }).forEach({ $0.removeFromSuperview() })
        wDict.removeAll()
        lasty = navBar.frame.origin.y + navBar.frame.size.height + MARGIN
    }

    func addVOFields(_ vot: Int) {
        vo?.vos?.voDrawOptions(self)
    }

    func addTOFields() {
        drawGeneralToOpts()
    }


}


