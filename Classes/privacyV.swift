//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// privacyV.swift
/// Copyright 2011-2021 Robert T. Miller
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
//  privacyV.swift
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import QuartzCore
import UIKit

// password states
// PWNEEDPRIVOK :  need to introduce privacy with the 'skip for now' requester
// PWNEEDPASS   :  need to set password (first usage)
// PWQUERYPASS  :  user has not authenticated yet for config controls
// PWKNOWPASS   :  user has authenticated with password

let PWNEEDPRIVOK = -2
let PWNEEDPASS = -1
let PWQUERYPASS = 0
let PWKNOWPASS = 1

// view states
//
// PVNOSHOW     :  not showing
// PVNEEDPASS   :  no password set, requester to set is showing
// PVQUERY      :  present tic-tack-toe query screen
// PVCHECKPASS  :  put up password requester prior to config open
// PVCONFIG     :  enable config controls
// PVSTARTUP    :

let PVNOSHOW = UInt(0)
let PVNEEDPASS = UInt(1 << 0)
let PVQUERY = UInt(1 << 1)
let PVCHECKPASS = UInt(1 << 2)
let PVCONFIG = UInt(1 << 3)
let PVSTARTUP = UInt(1 << 4)


let BTNRADIUS = 2
let LBLRADIUS = 4

let NXTBTNLBL = "  >  "
let PRVBTNLBL = "  <  "

// MARK: -
// MARK: singleton privacyValue support

private var _privacyValue: Int = PRIVDFLT
private var _jmpriv = false

var privacyValue: Int {
    get {
        return _privacyValue
    }
    set {
        _privacyValue = newValue
    }
}

var stashedPriv: NSNumber? = nil  // NSNumber so can check for nil
var lastShow: TimeInterval = 0

func jumpMaxPriv() {
    if nil == stashedPriv {
        stashedPriv = NSNumber(value: privacyValue)
    }

    //[self.privacyObj setPrivacyValue:MAXPRIV];  // temporary max privacy level so see all
    privacyValue = MAXPRIV
    _jmpriv = true
}

func restorePriv() {
    if nil == stashedPriv {
        return
    }


    privacyValue = stashedPriv?.intValue ?? 0
    stashedPriv = nil
    _jmpriv = false

}

class privacyV: UIView {
    
    func lockDown() -> Int {
        let currP = privacyValue

        ttv?.showKey(0)
        privacyValue = (MINPRIV)

        if (PWNEEDPRIVOK != pwState) && (PWNEEDPASS != pwState) {
            // 27.v.2013 don't set to query if no pw setup yet
            _pwState = PWQUERYPASS
        }

        showing = PVNOSHOW
        return currP
    }

    /*{
    	UIView *parentView;
        RootViewController *parent;
    	tictacV *ttv;
    	ppwV *ppwv;
    	tObjBase *tob;
    	unsigned int showing;
    	int pwState;
    }*/
    var parentView: UIView?
    var parent: RootViewController?
    var bottomBarHeight: CGFloat = 0.0  // Height of bottom bar (tab bar or toolbar)
    private var overlayView: UIView?  // Transparent overlay for tap-outside-to-dismiss
    
    private var _ttv: tictacV?
    var ttv: tictacV? {
        if _ttv == nil {
            _ttv = tictacV(pFrame: frame)
            _ttv?.tob = tob
        }
        return _ttv
    }
    var jmpriv: Bool {
        get {
            return _jmpriv
        }
        set {
            _jmpriv = newValue
        }
    }
    private var _ppwv: ppwV?
    var ppwv: ppwV? {
        if nil == _ppwv {
            _ppwv = ppwV(parentView: parentView!)
            //ppwv = [[ppwV alloc] initWithParentView:self];
            _ppwv!.tob = tob
            _ppwv!.parent = self
            _ppwv!.parentAction = #selector(ppwvResponse)
            // Update bottom bar height when creating ppwv
            if let tabBarHeight = parent?.tabBarController?.tabBar.frame.height {
                bottomBarHeight = tabBarHeight
            } else {
                bottomBarHeight = parent?.view.safeAreaInsets.bottom ?? 0
            }
            // Set initial topy - this will be adjusted based on privacy view state
            updatePpwvPosition()
        }
        return _ppwv
    }
    var tob: tObjBase?

    private var _showing: UInt = 0
    var showing: UInt {
        get {
            _showing
        }
        set(newState) {
            if (PVNOSHOW == _showing) && (PVNOSHOW == newState) {
                return // this happens when closing down.
            }

            //[(RootViewController*) self.parent refreshToolBar:YES];

            // (showing == newState)
            //	return;

            if PVNOSHOW != newState && PWNEEDPRIVOK == pwState {
                // first time if no password set, give some instructions
                let title = "Privacy"
                let msg = "This feature is for hiding trackers and values from display, with up to 99 filter levels.\nThe first step is to set a configuration password, then associate patterns with privacy levels as desired.\nThe password can be reset in System Preferences."
                let btn0 = "Let's go"
                let btn1 = "Skip for now"

                let alert = UIAlertController(
                    title: title,
                    message: msg,
                    preferredStyle: .alert)

                let defaultAction = UIAlertAction(
                    title: btn0,
                    style: .default,
                    handler: { [self] action in
                        _pwState = PWNEEDPASS
                        //self.showing = PVSTARTUP;
                        self.showing = PVQUERY
                    })

                let skipAction = UIAlertAction(
                    title: btn1,
                    style: .default,
                    handler: { action in
                    })

                alert.addAction(defaultAction)
                alert.addAction(skipAction)

                /*
                        UIViewController *vc;
                        UIWindow *w = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
                        w.rootViewController = [UIViewController new];
                        w.windowLevel = UIWindowLevelAlert +1;
                        [w makeKeyAndVisible];
                        vc = w.rootViewController;
                        //vc.modalPresentationStyle = UIModalPresentationFormSheet;

                        [vc presentViewController:alert animated:YES completion:nil];
                        */

                //let vc = UIApplication.shared.keyWindow?.rootViewController
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let window = windowScene!.windows.first
                let vc = window!.rootViewController
                vc?.present(alert, animated: true)
            } else if PVNOSHOW != newState && PWNEEDPASS == pwState {
                // must set an initial password to use privacy features
                _showing = PVNEEDPASS
                ppwv?.createPass(newState, cancel: PVNOSHOW) // recurse on input newState
                // Ensure ppwV appears on top of privacyV
                if let ppwv = _ppwv {
                    parentView?.bringSubviewToFront(ppwv)
                }

                //[self.ppwv createPass:PVCONFIG cancel:PVNOSHOW]; // need more work // recurse on input newState, config on successful new pass
            } else if PVQUERY == newState {
                DBGLog("Privacy view entering PVQUERY state")
                //self.hidden = NO;
                alpha = 1.0
                // Show overlay for tap-outside-to-dismiss
                showOverlay()
                if PVNEEDPASS == _showing {
                    // if just created, pass is currently up, set up pvquery behind keyboard
                    _pwState = PWKNOWPASS // just successfully created password so don't ask again
                    showPVQ(true)
                    //[self.ppwv hidePPWVAnimated:TRUE];  // don't hide and re-show
                    // crash[(RootViewController*) self.parentView refreshToolBar:YES];
                    //self.showing = PVCONFIG;
                } else {
                    //[UIView beginAnimations:nil context:NULL];
                    //[UIView setAnimationDuration:kAnimationDuration];
                    // Check if view is properly attached before animating
                    if superview == nil {
                        parentView?.addSubview(self)
                        parentView?.bringSubviewToFront(self)
                    }
                    UIView.animate(withDuration: 0.2, animations: { [self] in
                        if PVCONFIG == self.showing {
                            ppwv?.hidePPWV(animated: false)
                            hideConfigBtns(true)
                            // Show setup button, hide lock button
                            configBtn?.isHidden = false
                            lockBtn?.isHidden = true
                        } else {
                            // only PVNOSHOW possible ?
                            showPVQ(true)
                        }
                    })
                    // Ensure privacy view is above overlay
                    parentView?.bringSubviewToFront(self)
                    //[UIView commitAnimations];
                }
                if PVNEEDPASS == _showing {
                    _showing = PVQUERY
                    self.showing = PVCONFIG
                    return
                }
                _showing = PVQUERY
            } else if PVNOSHOW == newState {
                //[UIView beginAnimations:nil context:NULL];
                //[UIView setAnimationDuration:kAnimationDuration];
                // Hide overlay when dismissing privacy view
                hideOverlay()
                UIView.animate(withDuration: 0.2, animations: { [self] in
                    if PVNEEDPASS == self.showing {
                        // if set pass is up, cancelled out of create
                        ppwv?.hidePPWV(animated: false)
                        parentView?.setNeedsDisplay() //  privateBtn.title = @"private";
                    } else {

                        privacyValue = (MINPRIV + dbTestKey(Int(ttv?.key ?? 0))) // 14.ix.2011 privacy not 0

                        if PVCONFIG == self.showing {
                            ppwv?.hidePPWV(animated: false)
                            hideConfigBtns(true)
                        }
                        showPVQ(false)
                    }

                    //self.hidden = YES;
                    alpha = 0.0
                })
                //[UIView commitAnimations];

                _showing = PVNOSHOW
            } else if PVCONFIG == newState {
                DBGLog("Privacy view entering PVCONFIG state")
                if PWKNOWPASS == pwState || (PVCHECKPASS == _showing && ppwv!.ok == ppwv!.nextState) {
                    if PVCHECKPASS == _showing {
                        _pwState = PWKNOWPASS // just successfully entered password so don't ask again
                        //	[self hideConfigBtns:FALSE];
                        //	[UIView beginAnimations:nil context:NULL];
                        //	[UIView setAnimationDuration:kAnimationDuration];
                        //	//[self.ppwv hidePPWVAnimated:FALSE];
                        //else {
                    }
                    // Show overlay for tap-outside-to-dismiss
                    showOverlay()
                    hideConfigBtns(false)
                    //[UIView beginAnimations:nil context:NULL];
                    //[UIView setAnimationDuration:kAnimationDuration];
                    //}

                    // Set showing state BEFORE updating position so it uses correct positioning logic
                    _showing = PVCONFIG

                    UIView.animate(withDuration: 0.2, animations: { [self] in
                        updatePpwvPosition()  // Update position before showing password change
                        ppwv?.changePass(PVCONFIG, cancel: PVCONFIG)
                        // Show lock button, hide setup button
                        configBtn?.isHidden = true
                        lockBtn?.isHidden = false
                        setTTV()
                    })
                    // Ensure privacy view is above overlay
                    parentView?.bringSubviewToFront(self)
                    // Ensure ppwV appears on top of privacyV after animation
                    if let ppwv = _ppwv {
                        parentView?.bringSubviewToFront(ppwv)
                    }

                    //[UIView commitAnimations];
                    parent?.refreshToolBar(true)
                } else {
                    _showing = PVCHECKPASS
                    updatePpwvPosition()  // Update position before showing password check
                    ppwv?.checkPass(PVCONFIG, cancel: PVQUERY)
                    // Ensure ppwV appears on top of privacyV
                    if let ppwv = _ppwv {
                        parentView?.bringSubviewToFront(ppwv)
                    }
                }
            }
            parent?.refreshToolBar(true)
            //DBGLog(@"leaving setshowing, noshow= %d",(PVNOSHOW == showing));
        }
    }

    private var _pwState = 0
    var pwState: Int {
        if (PWNEEDPASS == _pwState) || (PWNEEDPRIVOK == _pwState) {
            if ppwv?.dbExistsPass() ?? false {
                _pwState = PWQUERYPASS
            }
        }
        return _pwState
    }
    // UI element properties 

    //  PVQUERY 

    private var _clearBtn: UIButton?
    var clearBtn: UIButton? {
        if _clearBtn == nil {
            _clearBtn = rTracker_resource.createActionButton(target: self, action: #selector(doClear(_:)), symbolName: "clear", accId: "clear", fallbackTitle: "Clear").uiButton

            // Let button use its intrinsic content size, then position
            let buttonSize = _clearBtn?.intrinsicContentSize ?? CGSize.zero

            // Set position - center horizontally at the intended location
            let centerX = self.frame.origin.x + (self.frame.size.width * (TICTACHRZFRAC / 2.0))
            let y = self.frame.size.height * TICTACVRTFRAC

            _clearBtn?.frame = CGRect(
                x: centerX - (buttonSize.width / 2.0),
                y: y,
                width: buttonSize.width,
                height: buttonSize.height
            )
        }
        return _clearBtn
    }

    private var _configBtn: UIButton?
    var configBtn: UIButton? {
        if _configBtn == nil {
            _configBtn = rTracker_resource.createSettingsButton(target: self, action: #selector(showConfig(_:)), accId: "setup").uiButton

            // Let button use its intrinsic content size, then position
            let buttonSize = _configBtn?.intrinsicContentSize ?? CGSize.zero

            // Set position - center horizontally at the intended location
            let centerX = self.frame.origin.x + (self.frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0)))
            let y = self.frame.size.height * TICTACVRTFRAC

            _configBtn?.frame = CGRect(
                x: centerX - (buttonSize.width / 2.0),
                y: y,
                width: buttonSize.width,
                height: buttonSize.height
            )
        }
        return _configBtn
    }

    private var _lockBtn: UIButton?
    var lockBtn: UIButton? {
        if _lockBtn == nil {
            _lockBtn = rTracker_resource.createActionButton(target: self, action: #selector(showConfig(_:)), symbolName: "lock.fill", accId: "lock", fallbackTitle: "Lock").uiButton

            // Let button use its intrinsic content size, then position
            let buttonSize = _lockBtn?.intrinsicContentSize ?? CGSize.zero

            // Set position - same as config button
            let centerX = self.frame.origin.x + (self.frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0)))
            let y = self.frame.size.height * TICTACVRTFRAC

            _lockBtn?.frame = CGRect(
                x: centerX - (buttonSize.width / 2.0),
                y: y,
                width: buttonSize.width,
                height: buttonSize.height
            )

            _lockBtn?.isHidden = true  // Initially hidden
        }
        return _lockBtn
    }
    //  PVCONFIG

    private var _saveBtn: UIButton?
    var saveBtn: UIButton? {
        if _saveBtn == nil {
            _saveBtn = rTracker_resource.createDoneButton(target: self, action: #selector(saveConfig(_:)), accId: "save").uiButton

            // Let button use its intrinsic content size, then position
            let buttonSize = _saveBtn?.intrinsicContentSize ?? CGSize.zero

            // Set position - center horizontally at the intended location
            let centerX = self.frame.origin.x + (self.frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0)))
            let y = self.frame.size.height * ((1.0 - TICTACVRTFRAC) - (1.0 - TICTACHGTFRAC))

            _saveBtn?.frame = CGRect(
                x: centerX - (buttonSize.width / 2.0),
                y: y,
                width: buttonSize.width,
                height: buttonSize.height
            )

            _saveBtn?.isHidden = true
        }
        return _saveBtn
    }

    private var _showSlider: UISlider?
    var showSlider: UISlider? {
        if _showSlider == nil {
            let sframe = CGRect(x: TICTACHRZFRAC * frame.size.width            // x orig = same as ttv
        , y: (TICTACVRTFRAC + TICTACHGTFRAC + TICTACVRTFRAC) * frame.size.height            // y orig = same below ttv as ttv is down from top
        , width: TICTACWIDFRAC * frame.size.width            // width = same as ttv
        , height: TICTACVRTFRAC * frame.size.height * 0.8) // height = 80% of dstance to ttv

            _showSlider = UISlider(frame: sframe)
            _showSlider?.backgroundColor = .clear
            _showSlider?.minimumValue = Float(MINPRIV + 1)
            _showSlider?.maximumValue = Float(MAXPRIV)
            //showSlider.continuous = FALSE;
            _showSlider?.addTarget(self, action: #selector(ssAction(_:)), for: .valueChanged)
            _showSlider?.isHidden = true
            
            _showSlider?.accessibilityLabel = "privacy level"
            _showSlider?.accessibilityIdentifier = "privlevel"
            _showSlider?.accessibilityHint = "higher is stronger, set pattern and save"
        }
        return _showSlider
    }

    func sliderVal() -> Int {
        return Int((showSlider?.value ?? 0.0) + 0.5)
    }
    
    func resetSlider() {
        _showSlider?.value = Float(MINPRIV + 1)
    }
    
    private var _ssValLab: UILabel?
    var ssValLab: UILabel? {
        let lfx = frame.origin.x + (frame.size.width * (TICTACHRZFRAC / 2.0))            // x= same as clearBtn
        let lfy = frame.size.height * ((1.0 - TICTACVRTFRAC) - (1.0 - TICTACHGTFRAC))           // y = same as saveBtn
        let lfsize = "1000".size(withAttributes: [NSAttributedString.Key.font: PrefBodyFont])
        if _ssValLab == nil {
            var lframe = CGRect(x:lfx, y:lfy, width:lfsize.width, height:lfsize.height)
            lframe.origin.x -= lframe.size.width / 2.0
            _ssValLab = UILabel(frame: lframe)
            _ssValLab?.textAlignment = .right // ios6 UITextAlignmentRight;
            _ssValLab?.text = "2" // MINPRIV +1
            _ssValLab?.layer.cornerRadius = CGFloat(LBLRADIUS)
            _ssValLab?.isHidden = true
            
            _ssValLab?.accessibilityHint = "current privacy level setting"
            _ssValLab?.accessibilityIdentifier = "plvl"
        }
        return _ssValLab
    }

    private var _nextBtn: UIButton?
    var nextBtn: UIButton? {
        if _nextBtn == nil {
            _nextBtn = rTracker_resource.createNavigationButton(target: self, action: #selector(adjustTTV(_:)), direction: .right, accId: "next", style: .circle).uiButton

            // Let button use its intrinsic content size, then position
            let buttonSize = _nextBtn?.intrinsicContentSize ?? CGSize.zero

            // Set position - center horizontally at the intended location
            let centerX = self.frame.origin.x + (self.frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0)))
            let y = (TICTACVRTFRAC + TICTACHGTFRAC + TICTACVRTFRAC) * self.frame.size.height

            _nextBtn?.frame = CGRect(
                x: centerX - (buttonSize.width / 2.0),
                y: y,
                width: buttonSize.width,
                height: buttonSize.height
            )

            _nextBtn?.isHidden = true
        }
        return _nextBtn
    }

    private var _prevBtn: UIButton?
    var prevBtn: UIButton? {
        if _prevBtn == nil {
            _prevBtn = rTracker_resource.createNavigationButton(target: self, action: #selector(adjustTTV(_:)), direction: .left, accId: "prev", style: .circle).uiButton

            // Let button use its intrinsic content size, then position
            let buttonSize = _prevBtn?.intrinsicContentSize ?? CGSize.zero

            // Set position - center horizontally at the intended location
            let centerX = self.frame.origin.x + (self.frame.size.width * (TICTACHRZFRAC / 2.0))
            let y = (TICTACVRTFRAC + TICTACHGTFRAC + TICTACVRTFRAC) * self.frame.size.height

            _prevBtn?.frame = CGRect(
                x: centerX - (buttonSize.width / 2.0),
                y: y,
                width: buttonSize.width,
                height: buttonSize.height
            )

            _prevBtn?.isHidden = true
        }
        return _prevBtn
    }

    // MARK: -
    // MARK: Overlay for tap-outside-to-dismiss

    private func setupOverlay() {
        guard let parentView = parentView else {
            DBGLog("setupOverlay: no parent view")
            return
        }

        if overlayView == nil {
            overlayView = UIView(frame: parentView.bounds)
            overlayView?.backgroundColor = UIColor.clear  // Transparent overlay
            overlayView?.alpha = 0.0  // Start hidden
            overlayView?.isUserInteractionEnabled = true  // Ensure it can receive touches

            // Add tap gesture to dismiss privacy view
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOverlayTap))
            tapGesture.cancelsTouchesInView = true  // Prevent touches from going to views below
            overlayView?.addGestureRecognizer(tapGesture)

            DBGLog("setupOverlay: created tap-outside-to-dismiss overlay")
        }
    }

    @objc private func handleOverlayTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: parentView)

        // If ppwV is visible, check if tap is within ppwV or privacy view bounds
        if showing == PVCHECKPASS, let ppwv = _ppwv {
            let ppwvFrame = ppwv.frame
            let privacyFrame = self.frame

            // Don't dismiss if tap is within ppwV or privacy view area
            if ppwvFrame.contains(tapLocation) || privacyFrame.contains(tapLocation) {
                DBGLog("handleOverlayTap: tap within ppwV or privacy view, ignoring")
                return
            }
        } else {
            // For non-password states, don't dismiss if tap is within privacy view
            let privacyFrame = self.frame
            if privacyFrame.contains(tapLocation) {
                DBGLog("handleOverlayTap: tap within privacy view, ignoring")
                return
            }
        }

        DBGLog("handleOverlayTap: tap outside views, dismissing privacy view")

        // Force keyboard to dismiss first to prevent reappearance issues
        parentView?.endEditing(true)

        // Dismiss privacy view when tapping outside
        showing = PVNOSHOW
    }

    private func showOverlay() {
        setupOverlay()
        guard let overlayView = overlayView, let parentView = parentView else { return }

        // Update overlay frame to cover full parent view
        overlayView.frame = parentView.bounds

        // Add overlay to parent view
        parentView.addSubview(overlayView)

        // Position overlay correctly based on ppwV visibility
        if showing == PVCHECKPASS, let ppwv = _ppwv {
            // When ppwV is visible, position overlay below both privacy view and ppwV
            // We'll use hit testing in the tap handler to avoid ppwV area
            parentView.insertSubview(overlayView, belowSubview: ppwv)
            DBGLog("showOverlay: ppwV visible, using hit testing to protect ppwV")
        } else {
            // Normal case: position overlay below privacy view but above other content
            parentView.insertSubview(overlayView, belowSubview: self)
        }

        // Animate overlay appearance
        UIView.animate(withDuration: 0.2) {
            overlayView.alpha = 1.0
        }
    }

    private func hideOverlay() {
        guard let overlayView = overlayView else { return }

        UIView.animate(withDuration: 0.2, animations: {
            overlayView.alpha = 0.0
        }, completion: { _ in
            overlayView.removeFromSuperview()
        })
    }

    // MARK: -
    // MARK: ppwV positioning management

    func updatePpwvPosition() {
        guard let _ppwv = _ppwv else { return }

        if showing == PVCONFIG || showing == PVCHECKPASS {
            // When privacy view is visible, position ppwV just above the privacy view
            // Use the actual current frame position of the privacy view
            _ppwv.topy = self.frame.origin.y  // Position ppwV bottom at privacy view top
            //DBGLog("updatePpwvPosition: PVCONFIG/PVCHECKPASS - ppwV.topy = \(_ppwv.topy), privacyV.frame.origin.y = \(self.frame.origin.y)")
        } else {
            // Default positioning - position above the bottom bar, ready to appear above keyboard
            // The ppwV should appear just above the tab bar/safe area when keyboard shows
            let parentHeight = parentView!.frame.size.height
            _ppwv.topy = parentHeight - bottomBarHeight
            //DBGLog("updatePpwvPosition: default - ppwV.topy = \(_ppwv.topy)")
        }
    }

    // MARK: -
    // MARK: core UIView object methods and support

    /*
    - (id)initWithFrame:(CGRect)frame {
        if ((self = [super initWithFrame:frame])) {
            // Initialization code
        }
        return self;
    }
    */

    // pvh hardcodes portrait keyboard height
    let PVH = 0.46

    init(parentView pv: RootViewController!) {

        // Calculate bottom bar height from safe area insets
        bottomBarHeight = pv.view.safeAreaInsets.bottom

        // Check for tab bar
        if let tabBarHeight = pv.tabBarController?.tabBar.frame.height {
            // Tab bar height includes safe area, so use it if available
            bottomBarHeight = tabBarHeight
        }

        // Check for toolbar
        if let toolbar = pv.navigationController?.toolbar, !toolbar.isHidden {
            let toolbarHeight = toolbar.frame.height
            if toolbarHeight > 0 && toolbarHeight < 200 {  // Sanity check
                bottomBarHeight = max(bottomBarHeight, toolbarHeight)
            }
        }

        // iOS 26 fix: Use parent view width instead of hardcoded 320, position below visible area
        let parentWidth = pv.view.frame.size.width > 0 ? pv.view.frame.size.width : 320.0

        // Calculate dynamic height based on content needs
        let topMargin = 30.0  // Space for top buttons (instead of 171 * 0.1 = 17.1)
        let tictacHeight = 102.0  // Keep tic-tac-toe space (similar to 171 * 0.6 = 102.6)
        let sliderSpace = 40.0  // Space for slider and controls
        let bottomButtonSpace = 50.0  // Space for bottom navigation buttons
        let bottomMargin = 20.0  // Bottom margin
        let dynamicHeight = topMargin + tictacHeight + sliderSpace + bottomButtonSpace + bottomMargin

        let frame = CGRect(x: 0.0, y: pv.view.frame.size.height, width: parentWidth, height: dynamicHeight)  // Start below visible area
        super.init(frame: frame)
        
        parent = pv
        parentView = pv.view
        _pwState = PWNEEDPRIVOK //PWNEEDPASS;

        backgroundColor = .secondarySystemBackground  // .clear  //.white

        layer.cornerRadius = 8
        clipsToBounds = false  // Allow buttons to extend beyond view bounds if needed
        showing = PVNOSHOW
        alpha = 1.0

        if let ttv {
            addSubview(ttv)
        }
        if let clearBtn {
            addSubview(clearBtn)
        }
        if let configBtn {
            addSubview(configBtn)
        }
        if let lockBtn {
            addSubview(lockBtn)
        }
        if let saveBtn {
            addSubview(saveBtn)
        }
        if let showSlider {
            addSubview(showSlider)
        }
        if let prevBtn {
            addSubview(prevBtn)
        }
        if let nextBtn {
            addSubview(nextBtn)
        }
        if let ssValLab {
            addSubview(ssValLab)
        }

        if let ttv {
            bringSubviewToFront(ttv)
        }

        parentView?.addSubview(self)
        parentView?.bringSubviewToFront(self)
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    - (void)drawRect:(CGRect)rect {
        // Drawing code
    }
    */


    // MARK: -
    // MARK: key value db interaction

    func dbTestKey(_ `try`: Int) -> Int {
        let sql = "select lvl from priv1 where key=\(`try`);"
        return tob!.toQry2Int(sql:sql)
    }

    func dbTestLvl(_ `try`: Int) -> Bool {
        let sql = "select count(*) from priv1 where lvl=\(`try`);"
        return tob!.toQry2Int(sql:sql) != 0
    }
    
    func dbSetKey(_ key: Int, level lvl: Int) {
        var sql: String?

        if key != 0 {
            sql = "insert or replace into priv1 (key,lvl) values ('\(key)','\(lvl)');"
        } else {
            sql = "delete from priv1 where lvl=\(lvl);"
        }
        tob!.toExecSql(sql:sql!)

    }

    #if TESTING
    func dbClrKeys() {
        tob!.toExecSql(sql:"delete from priv1;")
    }
    #endif
    
    func dbGetKey(_ lvl: Int) -> UInt {
        let sql = "select key from priv1 where lvl=\(lvl);"
        return UInt(tob!.toQry2Int(sql: sql))
    }

    func dbGetAdjacentKey(_ lvl: Int, nxt: Bool) -> (Int, Int) {
        var rkey: Int
        var lvlrslt: Int
        var sql: String?

        if nxt {
            sql = "select key, lvl from priv1 where lvl>\(lvl) order by lvl asc limit 1;"
        } else {
            sql = "select key, lvl from priv1 where lvl<\(lvl) order by lvl desc limit 1;"
        }
        (rkey, lvlrslt) = tob!.toQry2IntInt(sql: sql!)!
        return (rkey, lvlrslt)
    }

    // MARK: -
    // MARK: show / hide view

    func hideConfigBtns(_ state: Bool) {
        saveBtn?.isHidden = state
        nextBtn?.isHidden = state
        prevBtn?.isHidden = state
        showSlider?.isHidden = state
        ssValLab?.isHidden = state
        // Hide both config buttons when hiding config controls
        if state {
            configBtn?.isHidden = state
            lockBtn?.isHidden = state
        }
        // Note: When showing (state == false), specific button visibility
        // is handled by the calling context based on privacy state
    }

    func togglePrivacySetter() {
        if PVNOSHOW == showing {
            showing = PVQUERY
        } else {
            showing = PVNOSHOW
        }
    }

    func resetPw() {
        ppwv?.dbResetPass()
        _pwState = PWNEEDPRIVOK
        showing = PVNOSHOW
        privacyValue = MINPRIV
        ttv?.showKey(0)
        resetSlider()
    }

    @objc func ppwvResponse() {

        showing = ppwv!.nextState
    }

    func showPVQ(_ state: Bool) {

        // iOS 26 fix: Ensure view is still attached to parent
        if superview == nil {
            parentView?.addSubview(self)
            parentView?.bringSubviewToFront(self)
        }

        if state {
            // show - slide up so bottom of privacy view touches top of bottom bar
            lastShow = Date().timeIntervalSinceReferenceDate
            // Show setup button, hide lock button
            configBtn?.isHidden = false
            lockBtn?.isHidden = true

            // Calculate position: want bottom of our view to touch top of bottom bar
            // Our view starts at y = parentView.height (below screen)
            // We need to move up by (our height + bottom safe area) to position correctly
            //let parentHeight = parentView?.frame.size.height ?? 0
            let safeBottom = parentView?.safeAreaInsets.bottom ?? 0

            // The translation needed to position the view properly
            // Move up by our height plus the bottom safe area
            let translationY = -(frame.size.height + safeBottom)

            // Apply transform from identity
            transform = .identity
            transform = CGAffineTransform(translationX: 0, y: translationY)

            //self.parentView.userInteractionEnabled=NO;  // sadly kills interaction for child view as well
        } else {
            // hide - move back below screen
            let thisHide = Date().timeIntervalSinceReferenceDate
            if (thisHide - lastShow) <= 0.6 {
                ttv?.showKey(0)
                privacyValue = PRIVDFLT
            }
            ppwv?.hide()

            // Reset to identity transform (original position below screen)
            transform = .identity
            //self.parentView.userInteractionEnabled=YES;
        }
    }

    // make ttv match slider
    func setTTV() {
        let lvl = sliderVal()
        var k: UInt
        k = dbGetKey(lvl)
        if lvl > 0 {
            ttv?.showKey(k)
            showSlider?.value = Float(lvl)
            ssValLab?.text = "\(lvl)"
        }
    }

    // MARK: -
    // MARK: UI element target actions

    @objc func ssAction(_ sender: Any?) {
        ssValLab?.text = "\(sliderVal())"
    }

    @objc func showConfig(_ btn: UIButton?) {

        if btn?.accessibilityIdentifier == "setup" {
            showing = PVCONFIG
        } else if btn?.accessibilityIdentifier == "lock" {
            showing = PVQUERY
        }
    }

    @objc func doClear(_ btn: UIButton?) {
        ttv?.showKey(0)
    }

    @objc func saveConfig(_ btn: UIButton?) {
        let ttvkey: UInt = ttv!.key
        
        if ttvkey != 0 || dbTestLvl(sliderVal()) {
            // don't allow saving blank tt for a privacy level unless clearing that level
            dbSetKey(Int(ttvkey), level: sliderVal())
        } else {
            let alert = UIAlertController(
                title: "Set a pattern to save",
                message: "Set a pattern that will activate privacy level \(sliderVal()), then tap Save.",
                preferredStyle: .alert)

            let defaultAction = UIAlertAction(
                title: "OK",
                style: .default,
                handler: nil
            )
            alert.addAction(defaultAction)
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene!.windows.first
            let vc = window!.rootViewController
            vc?.present(alert, animated: true)        }
    }

    @objc func adjustTTV(_ btn: UIButton?) {
        var lvl = sliderVal()
        ///*
        var k: Int
        var dir: Bool
        if btn?.accessibilityIdentifier == "next" {
            // next
            dir = true
        } else {
            // prev
            dir = false
        }


        (k, lvl) = dbGetAdjacentKey(lvl, nxt: dir)

        if k == 0 {
            // if getAdjacent failed = no next/prev key for curr slider value
            lvl = sliderVal() // got wiped so reload
            if 0 == dbGetKey(lvl) {
                // and no existing key for curr slider
                //k = 
                (_, lvl) = dbGetAdjacentKey(lvl, nxt: !dir) // go for prev/next (opposite dir)
            }
        }
        //*/

        if lvl > 0 {
            showSlider?.value = Float(lvl)
            //[self.ttv showKey:k];
            setTTV() // display key if exists for slider value whatever it is now
            ssValLab?.text = "\(lvl)"
        }
    }

    func getBtn(_ btitle: String?, borg: CGPoint) -> UIButton? {
        let rbtn = UIButton(type: .roundedRect)
        var bframe: CGRect
        //if (kIS_LESS_THAN_IOS7) {
        //    bframe = (CGRect) {borg, [btitle sizeWithAttributes:@{NSFontAttributeName:PrefBodyFont}]};
        //} else {
        bframe = CGRect(origin: borg, size: btitle?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]) ?? CGSize.zero)
        //}
        bframe.origin.x -= bframe.size.width / 2.0 // center now we know btn title size
        rbtn.frame = bframe
        rbtn.setTitle(btitle, for: .normal)
        // doesn't work here : rbtn.layer.cornerRadius = BTNRADIUS;
        return rbtn
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

let CFGBTNCONFIG = " Setup "
let CFGBTNLOCK = " Lock  "
