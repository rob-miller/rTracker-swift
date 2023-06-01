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

class configTVObjVC: UIViewController, UITextFieldDelegate {
    /*
    {

    	BOOL vdlConfigVO;
    	trackerObj *to;
    	valueObj *vo;

    	NSMutableDictionary *wDict;  // widget dictionary

    	CGFloat lasty;
    	CGRect saveFrame;
    	CGFloat LFHeight;

        BOOL processingTfDone;

    }
    */
    var vdlConfigVO = false
    var to: trackerObj?
    var vo: valueObj?
    var voOptDictStash: [AnyHashable : Any]?

    var wDict: [String : Any] = [:]
    
    var lasty: CGFloat = 0.0
    var lastx: CGFloat = 0.0
    var saveFrame = CGRect.zero
    var lfHeight: CGFloat = 0.0
    // UI element properties
    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet weak var scroll: UIScrollView!
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
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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
        if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/choices.html") {
            UIApplication.shared.open(url, options: [:])
        }
    }

    @objc func btnInfoHelp() {
        if let url = URL(string: "http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/info.html") {
            UIApplication.shared.open(url, options: [:])
        }
    }

    override func viewDidLoad() {

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
            let vtypeNames = rTracker_resource.vtypeNames()[vo?.vtype ?? 0]
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
        var svsize = rTracker_resource.get_visible_size(self)
        if svsize.width < lastx {
            svsize.width = lastx
        }
        scroll.contentSize = CGSize(width: svsize.width, height: lasty + (3 * MARGIN))
        //[self.view addSubview:self.scroll];

        let doneBtn = UIBarButtonItem(
            title: "\u{2611}" /* ballot box with check */,
            style: .plain,
            target: self,
            action: #selector(btnDone(_:)))

        doneBtn.setTitleTextAttributes(
            [
                .font: UIFont.systemFont(ofSize: 28.0)
            // doesn't work?  ,NSForegroundColorAttributeName: [UIColor greenColor]
            ],
            for: .normal)

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
                fnHelpButtonItem = UIBarButtonItem(title: "Help", style: .plain, target: self, action: #selector(btnChoiceHelp))
            } else {
                fnHelpButtonItem = UIBarButtonItem(title: "Help", style: .plain, target: self, action: #selector(btnInfoHelp))
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


        super.viewDidLoad()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        rTracker_resource.setViewMode(self)
        view.setNeedsDisplay()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnDone(nil)
    }

    override func viewWillAppear(_ animated: Bool) {

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

        navigationController?.setToolbarHidden(false, animated: false)

        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
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

        // Release any cached data, images, etc that aren't in use.
    }

    /*
    - (void)viewDidUnload {
        [super viewDidUnload];
        // Release any retained subviews of the main view.
        // e.g. self.myOutlet = nil;

    	self.wDict = nil;
    	self.to = nil;
    	self.vo = nil;

    	self.toolBar = nil;
    	self.navBar = nil;

    }
    */

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
        //DBGLog(@"configTVObjVC keyboardwillshow");
        let boty = (activeField?.frame.origin.y ?? 0.0) + (activeField?.frame.size.height ?? 0.0) + MARGIN
        rTracker_resource.willShowKeyboard(n, view: scroll, boty: boty)
        //[rTracker_resource willShowKeyboard:n view:self.view boty:boty];

        /*
            if (keyboardIsShown) { // need bit more logic to handle additional scrolling for another textfield
                return;
            }

        	//DBGLog(@"handling keyboard will show");
        	self.saveFrame = self.view.frame;

            NSDictionary* userInfo = [n userInfo];

            // get the size of the keyboard
            NSValue* boundsValue = [userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey];
            CGSize keyboardSize = [boundsValue CGRectValue].size;

        	CGRect viewFrame = self.view.frame;
        	//DBGLog(@"k will show, y= %f",viewFrame.origin.y);
        	CGFloat boty = activeField.frame.origin.y + activeField.frame.size.height + MARGIN;

            CGFloat topk = viewFrame.size.height - keyboardSize.height;  // - viewFrame.origin.y;
        	if (boty <= topk) {
        		//DBGLog(@"activeField visible, do nothing  boty= %f  topk= %f",boty,topk);
        	} else {
        		//DBGLog(@"activeField hidden, scroll up  boty= %f  topk= %f",boty,topk);

        		viewFrame.origin.y -= (boty - topk);
        		//viewFrame.size.height -= self.toolBar.frame.size.height - MARGIN;
                viewFrame.size.height +=  MARGIN;

        		[UIView beginAnimations:nil context:NULL];
        		[UIView setAnimationBeginsFromCurrentState:YES];
        		[UIView setAnimationDuration:kAnimationDuration];

        		[self.view setFrame:viewFrame];

        		[UIView commitAnimations];
        	}

            keyboardIsShown = YES;
        	*/
    }

    @objc func keyboardWillHide(_ n: Notification?) {
        //DBGLog(@"handling keyboard will hide");
        rTracker_resource.willHideKeyboard()

        /*
        	[UIView beginAnimations:nil context:NULL];
        	[UIView setAnimationBeginsFromCurrentState:YES];
        	[UIView setAnimationDuration:kAnimationDuration];

        	[self.view setFrame:self.saveFrame];

        	[UIView commitAnimations];

            keyboardIsShown = NO;	
             */
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

        let rlab = UILabel(frame: frame)
        rlab.font = PrefBodyFont
        rlab.text = text
        rlab.backgroundColor = .clear

        // wDict[key] = rlab
        wDict[key] = rlab
        
        if addsv {
            scroll.addSubview(rlab)
        }
        //[self.view addSubview:rlab];

        let retFrame = rlab.frame

        return retFrame
    }

    @objc func checkBtnAction(_ btn: UIButton?) {
        var okey: String? = nil
        var dflt: String?
        var ndflt: String? = nil
        var img: String?
        var dfltState = AUTOSCALEDFLT

        if btn == (wDict["nasBtn"] as? UIButton) {
            okey = "autoscale"
            dfltState = AUTOSCALEDFLT
            if ((vo?.optDict)?[okey!] as? String) == "0" {
                // will switch on
                removeGraphMinMax()
                //[self addGraphFromZero];  // ASFROMZERO
            } else {
                //[self removeGraphFromZero];
                addGraphMinMax() // ASFROMZERO
            }
        } else if btn == (wDict["csbBtn"] as? UIButton) {
            okey = "shrinkb"
            dfltState = SHRINKBDFLT
        } else if btn == (wDict["cevBtn"] as? UIButton) {
            okey = "exportvalb"
            dfltState = EXPORTVALBDFLT
        } else if btn == (wDict["stdBtn"] as? UIButton) {
            okey = "setstrackerdate"
            dfltState = SETSTRACKERDATEDFLT
        } else if btn == (wDict["sisBtn"] as? UIButton) {
            okey = "integerstepsb"
            dfltState = INTEGERSTEPSBDFLT
        } else if btn == (wDict["sdeBtn"] as? UIButton) {
            okey = "defaultenabledb"
            dfltState = DEFAULTENABLEDBDFLT
        } else if btn == (wDict["sswlBtn"] as? UIButton) {
            okey = "slidrswlb"
            dfltState = SLIDRSWLBDFLT
        } else if btn == (wDict["tbnlBtn"] as? UIButton) {
            okey = "tbnl"
            dfltState = TBNLDFLT
        } else if btn == (wDict["tbniBtn"] as? UIButton) {
            okey = "tbni"
            dfltState = TBNIDFLT
        } else if btn == (wDict["tbhiBtn"] as? UIButton) {
            okey = "tbhi"
            dfltState = TBHIDFLT
        } else if btn == (wDict["ggBtn"] as? UIButton) {
            okey = "graph"
            dfltState = GRAPHDFLT
        } else if btn == (wDict["swlBtn"] as? UIButton) {
            okey = "nswl"
            dfltState = NSWLDFLT
        } else if btn == (wDict["srBtn"] as? UIButton) {
            okey = "savertn"
            dfltState = SAVERTNDFLT
        } else if btn == (wDict["graphLastBtn"] as? UIButton) {
            okey = "graphlast"
            dfltState = GRAPHLASTDFLT
        } else if btn == (wDict["infosaveBtn"] as? UIButton) {
            okey = "infosave"
            dfltState = INFOSAVEDFLT
        } else {
            dbgNSAssert(false, "ckButtonAction cannot identify btn")
            okey = "x" // make analyze happy
        }

        if dfltState == true {
            dflt = "1"
            ndflt = "0"
        } else {
            dflt = "0"
            ndflt = "1"
        }

        if vo == nil {
            if (to!.optDict[okey!] as! String) == ndflt {
                to!.optDict[okey!] = dflt
                img = dfltState ? "checked.png" : "unchecked.png" // going to default state
            } else {
                to!.optDict[okey!] = ndflt
                img = dfltState ? "unchecked.png" : "checked.png" // going to not default state
            }
        } else {
            if (vo!.optDict[okey!]) == ndflt {
                vo!.optDict[okey!] = dflt
                img = dfltState ? "checked.png" : "unchecked.png" // going to default state
            } else {
                vo!.optDict[okey!] = ndflt
                img = dfltState ? "unchecked.png" : "checked.png" // going to not default state
            }
        }
        btn?.setImage(UIImage(named: img ?? ""), for: .normal)

    }

    func configCheckButton(_ frame: CGRect, key: String?, state: Bool, addsv: Bool) -> CGRect {
        /*
            if (frame.origin.x + frame.size.width > [rTracker_resource getKeyWindowWidth]) {
                frame.origin.x = MARGIN;
                frame.origin.y += MARGIN + frame.size.height;
            }
            */

        let imageButton = UIButton(type: .custom)
        //imageButton.frame = CGRectInset(frame,-3,-3); // a bit bigger please
        imageButton.frame = frame
        imageButton.contentVerticalAlignment = .center
        imageButton.contentHorizontalAlignment = .right //Center;

        wDict[key ?? ""] = imageButton
        imageButton.addTarget(self, action: #selector(checkBtnAction(_:)), for: .touchUpInside)

        imageButton.setImage(
            UIImage(named: state ? "checked.png" : "unchecked.png"),
            for: .normal)

        if addsv {
            //[self.view addSubview:imageButton];
            scroll.addSubview(imageButton)
        }

        return frame
    }

    func configActionBtn(_ pframe: CGRect, key: String?, label: String?, target: Any?, action: Selector) -> CGRect {
        /*
            if (frame.origin.x + frame.size.width > [rTracker_resource getKeyWindowWidth]) {
                frame.origin.x = MARGIN;
                frame.origin.y += MARGIN + frame.size.height;
            }
            */

        let button = UIButton(type: .roundedRect)
        var frame = pframe
        button.titleLabel?.font = PrefBodyFont
        if let font = button.titleLabel?.font {
            frame.size.width = (label?.size(withAttributes: [
                NSAttributedString.Key.font: font
            ]).width ?? 0.0) + 4 * SPACE
        }

        if frame.origin.x == -1.0 {
            frame.origin.x = view.frame.size.width - (frame.size.width + MARGIN) // right justify
        }
        button.frame = frame
        button.setTitle(label, for: .normal)
        //imageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        //imageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight; //Center;

        if nil != key {
            wDict[key ?? ""] = button
        }

        button.addTarget(target, action: action, for: .touchUpInside)

        //[self.view addSubview:button];
        scroll.addSubview(button)

        return frame
    }

    @objc func tfDone(_ tf: UITextField?) {
        if true == processingTfDone {
            return
        }
        processingTfDone = true

        var okey: String? = nil
        var nkey: String? = nil
        if tf == (wDict["nminTF"] as? UITextField) {
            okey = "gmin"
            nkey = "nmaxTF"
        } else if tf == (wDict["nmaxTF"] as? UITextField) {
            okey = "gmax"
            nkey = nil
        } else if tf == (wDict["sminTF"] as? UITextField) {
            okey = "smin"
            nkey = "smaxTF"
        } else if tf == (wDict["smaxTF"] as? UITextField) {
            okey = "smax"
            nkey = "sdfltTF"
        } else if tf == (wDict["sdfltTF"] as? UITextField) {
            okey = "sdflt"
            nkey = nil
        } else if tf == (wDict["gpTF"] as? UITextField) {
            okey = "privacy"
            nkey = nil

            let currPriv = privacyValue
            var newPriv = Int(tf?.text ?? "") ?? 0
            if newPriv > currPriv {
                //newPriv = currPriv;
                tf?.text = "\(currPriv)"
                let msg = "rTracker's privacy level is currently set to \(currPriv).  Setting an item to a higher privacy level than the current setting is disallowed."
                rTracker_resource.alert("Privacy higher than current", msg: msg, vc: self)
            }
            newPriv = Int(tf?.text ?? "") ?? 0
            if newPriv < PRIVDFLT {
                tf?.text = "\(PRIVDFLT)"
                let msg = "Setting a privacy level below \(PRIVDFLT) is disallowed."
                rTracker_resource.alert("Privacy setting too low", msg: msg, vc: self)
            }
        } else if tf == (wDict["gyTF"] as? UITextField) {
            okey = "yline1"
            nkey = nil
        } else if tf == (wDict["gmdTF"] as? UITextField) {
            okey = "graphMaxDays"
            nkey = nil
        } else if tf == (wDict["deTF"] as? UITextField) {
            okey = "dfltEmail"
            nkey = nil
        } else if tf == (wDict["fr0TF"] as? UITextField) {
            okey = "frv0"
            nkey = nil
        } else if tf == (wDict["fr1TF"] as? UITextField) {
            okey = "frv1"
            nkey = nil
        } else if tf == (wDict["fnddpTF"] as? UITextField) {
            okey = "fnddp"
            nkey = nil
        } else if tf == (wDict["numddpTF"] as? UITextField) {
            okey = "numddp"
            nkey = nil
        } else if tf == (wDict["bvalTF"] as? UITextField) {
            okey = "boolval"
            nkey = nil
        } else if tf == (wDict["ivalTF"] as? UITextField) {
            okey = "infoval"
            nkey = nil
        } else if tf == (wDict["iurlTF"] as? UITextField) {
            okey = "infourl"
            nkey = nil
        } else if tf == (wDict[CTFKEY] as? UITextField) {
            okey = LCKEY
            nkey = nil
        } else {
            //dbgNSAssert(0,@"mtfDone cannot identify tf");
            okey = "x" // make analyze happy
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

        if let nkey {
            (wDict[nkey] as! UITextField).becomeFirstResponder()
        } else {
            tf?.resignFirstResponder()
        }

        activeField = nil

        processingTfDone = false

    }

    func configTextField(_ pframe: CGRect, key: String?, target: Any?, action: Selector?, num: Bool, place: String?, text: String?, addsv: Bool) -> CGRect {
        /*
            if (frame.origin.x + frame.size.width > [rTracker_resource getKeyWindowWidth]) {
                frame.origin.x = MARGIN;
                frame.origin.y += MARGIN + frame.size.height;
            }
            */

        var frame = pframe
        frame.origin.y -= TFXTRA
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
        scroll.addSubview(rtv)

        return frame
    }

    func configPicker(_ frame: CGRect, key: String?, caller: Any?) -> CGRect {
        var frame = frame
        let myPickerView = UIPickerView(frame: .zero)
        frame.size = myPickerView.sizeThatFits(.zero)
        frame.size.width = view.frame.size.width - (2 * MARGIN)
        frame.origin.y += frame.size.height / 4 // because origin of picker is centre line
        myPickerView.frame = frame
        //frame.size.height -= (frame.size.height/4);

        myPickerView.autoresizingMask = .flexibleWidth
        // no effect after ios7 myPickerView.showsSelectionIndicator = YES;	// note this is default to NO

        // this view controller is the data source and delegate
        myPickerView.delegate = caller as? UIPickerViewDelegate
        myPickerView.dataSource = caller as? UIPickerViewDataSource

        wDict[key ?? ""] = myPickerView
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
        /*
        	[UIView beginAnimations:nil context:NULL];
        	[UIView setAnimationBeginsFromCurrentState:YES];
        	[UIView setAnimationDuration:kAnimationDuration];
             */
        /*
        	[self.view addSubview:(self.wDict)[@"nminLab"]];
        	[self.view addSubview:(self.wDict)[@"nminTF"]];
        	[self.view addSubview:(self.wDict)[@"nmaxLab"]];
        	[self.view addSubview:(self.wDict)[@"nmaxTF"]];
        	*/

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

        _ = configCheckButton(
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
        frame.size.height = lfHeight // self.labelField.frame.size.height; // lab.frame.size.height;

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
        frame.size.height = lfHeight // self.labelField.frame.size.height; // lab.frame.size.height;

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

        return frame
    }

    // MARK: -
    // MARK: general opts for all

    @objc func notifyReminderView() {
        DBGLog("notify reminder view!")
        let nrvc = notifyReminderViewController(nibName: "notifyReminderViewController", bundle: nil)
        //nrvc.view.hidden = NO;
        nrvc.tracker = to
        nrvc.modalTransitionStyle = .flipHorizontal
        //if ( SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0") ) {
        present(nrvc, animated: true)
        //} else {
        //    [self presentModalViewController:nrvc animated:YES];
        //}
        //[self.navigationController pushViewController:nrvc animated:YES];




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

        titleStr = String(format: "tracker number %ld\n%d items\n%d date entries\n%d data points", Int(to?.toid ?? 0), itemCount, dateEntries, dataPoints)

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

        /*
                __block UIUserNotificationSettings* uns;
                safeDispatchSync(^{
                    uns = [[UIApplication sharedApplication] currentUserNotificationSettings];
                });
                if (! ([uns types] & (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge))) {
                */
        if !rTracker_resource.getNotificationsEnabled() {
            titleStr = (titleStr ?? "") + "\n\n- Notifications Disabled -\nEnable in System Preferences."
        }

        let infoDict = Bundle.main.infoDictionary

        if let anInfoDict = infoDict?["CFBundleDisplayName"], let aAnInfoDict = infoDict?["CFBundleShortVersionString"], let aAAnInfoDict = infoDict?["CFBundleVersion"] {
            titleStr = (titleStr ?? "") + "\n\n\(anInfoDict) \(aAnInfoDict) [\(aAAnInfoDict)]"
        }

        //#endif
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
        var frame = CGRect(x: MARGIN, y: lasty, width: 0.0, height: 0.0)

        var labframe = configLabel("save returns to tracker list:", frame: frame, key: "srLab", addsv: true)

        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)
        /*
            if (frame.origin.x + frame.size.width > [rTracker_resource getKeyWindowWidth]) {
                frame.origin.x = MARGIN;
                frame.origin.y += MARGIN + frame.size.height;
            }
            */
        //-- save returns to tracker list button

        frame = configCheckButton(
            frame,
            key: "srBtn",
            state: !((to!.optDict["savertn"] as? String) == "0"),
            addsv: true)

        //-- privacy level label

        frame.origin.x = MARGIN
        //frame.origin.x += frame.size.width + MARGIN + SPACE;
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Privacy level:", frame: frame, key: "gpLab", addsv: true)

        //-- privacy level textfield

        frame.origin.x += labframe.size.width + SPACE

        var tfWidth = "9999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = lfHeight // self.labelField.frame.size.height; // lab.frame.size.height;

        frame = configTextField(
            frame,
            key: "gpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(PRIVDFLT)",
            text: (to?.optDict)?["privacy"] as? String,
            addsv: true)

        //TODO: privacy values when password not set up....
        // if password not set could disable privacy setting here but have to pass pwset bool all over
        //  alternatively, don't allow setting privacy val higher than current?
        // ((UITextField*) [self.wDict objectForKey:@"gpTF"]).enabled = NO;

        //-- graph max _ days label

        frame.origin.x = MARGIN
        //frame.origin.x += frame.size.width + MARGIN + SPACE;
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Graph limit:", frame: frame, key: "glLab", addsv: true)

        //-- graph max _ days textfield

        frame.origin.x += labframe.size.width + SPACE

        tfWidth = "999999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = lfHeight // self.labelField.frame.size.height; // lab.frame.size.height;

        var gMaxDays = (to?.optDict)?["graphMaxDays"] as? String
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
        //labframe =
        frame = configLabel("days", frame: frame, key: "gl2Lab", addsv: true)


        //-- default email label

        frame.origin.x = MARGIN
        //frame.origin.x += frame.size.width + MARGIN + SPACE;
        frame.origin.y += MARGIN + frame.size.height
        labframe = configLabel("Default email:", frame: frame, key: "deLab", addsv: true)

        //-- default email _ textfield

        frame.origin.x += labframe.size.width + SPACE

        //tfWidth = [@"" sizeWithFont:PrefBodyFont].width;
        frame.size.width = view.frame.size.width - (2 * SPACE) - labframe.size.width - MARGIN
        frame.size.height = lfHeight // self.labelField.frame.size.height; // lab.frame.size.height;

        let dfltEmail = (to?.optDict)?["dfltEmail"] as? String

        frame = configTextField(
            frame,
            key: "deTF",
            target: nil,
            action: nil,
            num: false,
            place: " ",
            text: dfltEmail,
            addsv: true)


        if nil == vo {

            frame.origin.x = MARGIN
            //frame.origin.x += frame.size.width + MARGIN + SPACE;
            frame.origin.y += MARGIN + frame.size.height

            if nil != to?.dbName {

                // reminder config button:

                frame = configActionBtn(frame, key: nil, label: "Reminders", target: self, action: #selector(notifyReminderView))

                // dbInfo values button:

                frame.origin.x = MARGIN
                //frame.origin.x += frame.size.width + MARGIN + SPACE;
                frame.origin.y += MARGIN + frame.size.height

                frame = configActionBtn(frame, key: nil, label: "database info", target: self, action: #selector(dbInfoBtn))

                // 'reset reminders' button

                frame.origin.x = MARGIN
                //frame.origin.x += frame.size.width + MARGIN + SPACE;
                frame.origin.y += MARGIN + frame.size.height

                frame = configActionBtn(frame, key: nil, label: "set reminders", target: self, action: #selector(setRemindersBtn))
            } else {

                frame.origin.y += MARGIN + frame.size.height
                //labframe =
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
        /*

        	switch(vot) {
        		case VOT_NUMBER: 
        			// uilabel 'autoscale graph'   uibutton checkbutton
        			// uilabel 'graph min' uitextfield uilabel 'max' ; enabled/disabled by checkbutton
        			//[self drawNumOpts];
        			//[self drawGeneralVoOpts];
        			[self.vo.vos voDrawOptions:self];
        			break;
        		case VOT_TEXT:
        			//[self drawGenOptsOnly];
        			//[self drawGeneralVoOpts];
        			[self.vo.vos voDrawOptions:self];
        			break;
        		case VOT_TEXTB:
        			//[self drawTextbOpts];
        			//[self drawGeneralVoOpts];
        			[self.vo.vos voDrawOptions:self];
        			break;
        		case VOT_SLIDER:
        			// uilabel 'min' uitextfield uilabel 'max' uitextfield uilabel 'default' uitextfield
        			//[self drawSliderOpts];
        			//[self drawGeneralVoOpts];
        			[self.vo.vos voDrawOptions:self];
        			break;
        		case VOT_CHOICE:
        			// 6 rows uitextfield + button with color ; button cycles color on press ; button blank/off if no text in textfield
        			// uilabel 'dynamic width' uibutton checkbutton
        			//[self drawChoiceOpts];
        			//[self drawGeneralVoOpts];
        			[self.vo.vos voDrawOptions:self];
        			break;
        		case VOT_BOOLEAN:
        			[self.vo.vos voDrawOptions:self];
        			//[self drawGenOptsOnly];
        			//[self drawGeneralVoOpts];
        			break;
                    / *
        		case VOT_IMAGE:
        			//[self drawImageOpts];
        			[self.vo.vos voDrawOptions:self];
        			break;
                     * /
        		case VOT_FUNC:
        			// uitextfield for function, picker or buttons for available valObjs and functions?
        			//[self drawFuncOptsOverview];
        			//if ([self.to.valObjTable count] == 0) {
        				[self.vo.vos voDrawOptions:self];
        			//}
        			break;
                case VOT_INFO:
                    [self.vo.vos voDrawOptions:self];
                    break;
        		default:
        			break;
        	}
         */


    }

    func addTOFields() {

        drawGeneralToOpts()




    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    /*
    - (void) updateScrollView:(NSInteger) vot 
    {
    //	[UIView beginAnimations:nil context:NULL];
    //	[UIView setAnimationBeginsFromCurrentState:YES];
    //	[UIView setAnimationDuration:kAnimationDuration];

    	//[self removeSVFields];
    	[self addVOFields:vot];

    //	[UIView commitAnimations];
    }
    */
}

//  private methods including properties can go here!
