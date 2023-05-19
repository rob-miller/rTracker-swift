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
    var privacyValue = PRIVDFLT
var stashedPriv: NSNumber? = nil
var lastShow: TimeInterval = 0

class privacyV: UIView {
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

    private var _ttv: tictacV?
    var ttv: tictacV? {
        if _ttv == nil {
            _ttv = tictacV(pFrame: frame)
            _ttv?.tob = tob
        }
        return _ttv
    }

    private var _ppwv: ppwV?
    var ppwv: ppwV? {
        if nil == _ppwv {
            _ppwv = ppwV(parentView: parentView)
            //ppwv = [[ppwV alloc] initWithParentView:self];
            _ppwv?.tob = tob
            _ppwv?.parent = self
            _ppwv?.parentAction = #selector(ppwvResponse)

            _ppwv?.topy = (parentView?.frame.size.height ?? 0.0) - frame.size.height
            DBGLog("pv.y = %f  s.h = %f  ty= %f", parentView?.frame.size.height, frame.size.height, _ppwv?.topy)
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
            DBGLog("priv: setShowing %d -> %d  curr priv= %d", _showing, newState, privacyV.getPrivacyValue())
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
                        pwState = PWNEEDPASS
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

                let vc = UIApplication.shared.keyWindow?.rootViewController
                vc?.present(alert, animated: true)
            } else if PVNOSHOW != newState && PWNEEDPASS == pwState {
                // must set an initial password to use privacy features        
                _showing = PVNEEDPASS
                ppwv?.createPass(newState, cancel: PVNOSHOW) // recurse on input newState

                //[self.ppwv createPass:PVCONFIG cancel:PVNOSHOW]; // need more work // recurse on input newState, config on successful new pass
            } else if PVQUERY == newState {
                //self.hidden = NO;
                alpha = 1.0
                if PVNEEDPASS == _showing {
                    // if just created, pass is currently up, set up pvquery behind keyboard
                    pwState = PWKNOWPASS // just successfully created password so don't ask again
                    showPVQ(true)
                    //[self.ppwv hidePPWVAnimated:TRUE];  // don't hide and re-show
                    // crash[(RootViewController*) self.parentView refreshToolBar:YES];
                    //self.showing = PVCONFIG;
                } else {
                    //[UIView beginAnimations:nil context:NULL];
                    //[UIView setAnimationDuration:kAnimationDuration];

                    UIView.animate(withDuration: 0.2, animations: { [self] in
                        if PVCONFIG == self.showing {
                            ppwv?.hidePPWV(animated: false)
                            hideConfigBtns(true)
                            configBtn?.setTitle(CFGBTNCONFIG, for: .normal)
                        } else {
                            // only PVNOSHOW possible ?
                            showPVQ(true)
                        }
                    })
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
                UIView.animate(withDuration: 0.2, animations: { [self] in
                    if PVNEEDPASS == self.showing {
                        // if set pass is up, cancelled out of create
                        DBGLog("cancelled out of create pass")
                        ppwv?.hidePPWV(animated: false)
                        parentView?.setNeedsDisplay() //  privateBtn.title = @"private";
                    } else {

                        setPrivacyValue(MINPRIV + dbTestKey(Int(ttv?.key ?? 0))) // 14.ix.2011 privacy not 0

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
                if PWKNOWPASS == pwState || (PVCHECKPASS == _showing && ppwv?.ok == ppwv?.next) {
                    if PVCHECKPASS == _showing {
                        pwState = PWKNOWPASS // just successfully entered password so don't ask again
                        //	[self hideConfigBtns:FALSE];
                        //	[UIView beginAnimations:nil context:NULL];
                        //	[UIView setAnimationDuration:kAnimationDuration];
                        //	//[self.ppwv hidePPWVAnimated:FALSE];
                        //else {
                    }
                    hideConfigBtns(false)
                    //[UIView beginAnimations:nil context:NULL];
                    //[UIView setAnimationDuration:kAnimationDuration];
                    //}
                    UIView.animate(withDuration: 0.2, animations: { [self] in
                        ppwv?.changePass(PVCONFIG, cancel: PVCONFIG)
                        configBtn?.setTitle(CFGBTNLOCK, for: .normal)
                        setTTV()
                    })

                    //[UIView commitAnimations];
                    _showing = PVCONFIG
                    parent?.refreshToolBar(true)
                } else {
                    _showing = PVCHECKPASS
                    ppwv?.checkPass(PVCONFIG, cancel: PVQUERY)
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
            _clearBtn = getBtn(
                " Clear ",
                borg: CGPoint(x: frame.origin.x + (frame.size.width * (TICTACHRZFRAC / 2.0)), y: frame.size.height * TICTACVRTFRAC))
            _clearBtn?.addTarget(self, action: #selector(doClear(_:)), for: .touchUpInside)
            _clearBtn?.layer.cornerRadius = CGFloat(BTNRADIUS)
            //clearBtn.backgroundColor = [UIColor whiteColor];
        }
        return _clearBtn
    }

    private var _configBtn: UIButton?
    var configBtn: UIButton? {
        if _configBtn == nil {

            _configBtn = getBtn(
                CFGBTNCONFIG,
                borg: CGPoint(x: frame.origin.x + (frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0))), y: frame.size.height * TICTACVRTFRAC))

            /*
                     // use button title for state info
                    configBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
                    configBtn.frame = CGRectMake(self.frame.origin.x+(self.frame.size.width * (1.0f - (TICTACHRZFRAC/2.0f))),
                                                 self.frame.size.height * TICTACVRTFRAC,
                                                 44, 44);
                     */
            _configBtn?.addTarget(self, action: #selector(showConfig(_:)), for: .touchUpInside)
            _configBtn?.layer.cornerRadius = CGFloat(BTNRADIUS)
            //configBtn.backgroundColor = [UIColor whiteColor];
        }
        return _configBtn
    }
    //  PVCONFIG

    private var _saveBtn: UIButton?
    var saveBtn: UIButton? {
        if _saveBtn == nil {
            _saveBtn = getBtn(
                " Save ",
                borg: CGPoint(x: frame.origin.x + (frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0))), y: frame.size.height * ((1.0 - TICTACVRTFRAC) - (1.0 - TICTACHGTFRAC))))
            _saveBtn?.addTarget(self, action: #selector(saveConfig(_:)), for: .touchUpInside)
            _saveBtn?.layer.cornerRadius = CGFloat(BTNRADIUS)
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
        }
        return _showSlider
    }

    private var _ssValLab: UILabel?
    var ssValLab: UILabel? {
        if _ssValLab == nil {
            let lframe = CGRect(frame.origin.x + (frame.size.width * (TICTACHRZFRAC / 2.0))            // x= same as clearBtn
        , frame.size.height * ((1.0 - TICTACVRTFRAC) - (1.0 - TICTACHGTFRAC))            // y = same as saveBtn
        , "100".size(withAttributes: [
                NSAttributedString.Key.font: PrefBodyFont
            ]))
            lframe.origin.x -= lframe.size.width / 2.0
            _ssValLab = UILabel(frame: lframe)
            _ssValLab?.textAlignment = .right // ios6 UITextAlignmentRight;
            _ssValLab?.text = "2" // MINPRIV +1
            _ssValLab?.layer.cornerRadius = CGFloat(LBLRADIUS)
            _ssValLab?.isHidden = true
        }
        return _ssValLab
    }

    private var _nextBtn: UIButton?
    var nextBtn: UIButton? {
        if _nextBtn == nil {
            _nextBtn = getBtn(
                NXTBTNLBL,
                borg: CGPoint(x: frame.origin.x + (frame.size.width * (1.0 - (TICTACHRZFRAC / 2.0)))            // x= same as saveBtn
            , y: (TICTACVRTFRAC + TICTACHGTFRAC + TICTACVRTFRAC) * frame.size.height)) // y= same as showslider
            _nextBtn?.addTarget(self, action: #selector(adjustTTV(_:)), for: .touchUpInside)
            _nextBtn?.layer.cornerRadius = CGFloat(BTNRADIUS)
            _nextBtn?.isHidden = true
        }
        return _nextBtn
    }

    private var _prevBtn: UIButton?
    var prevBtn: UIButton? {
        if _prevBtn == nil {
            _prevBtn = getBtn(
                PRVBTNLBL,
                borg: CGPoint(x: frame.origin.x + (frame.size.width * (TICTACHRZFRAC / 2.0))            // x= same as clearBtn
            , y: (TICTACVRTFRAC + TICTACHGTFRAC + TICTACVRTFRAC) * frame.size.height)) // y= same as showslider
            _prevBtn?.addTarget(self, action: #selector(adjustTTV(_:)), for: .touchUpInside)
            _prevBtn?.layer.cornerRadius = CGFloat(BTNRADIUS)
            _prevBtn?.isHidden = true
        }
        return _prevBtn
    }

    class func getPrivacyValue() -> Int {
        return privacyValue
    }

    func setPrivacyValue(_ priv: Int) {
        privacyValue = priv
        DBGLog("updatePrivacy:%d", privacyV.getPrivacyValue())
        //[self.pvc.tableView reloadData ];
    }

    class func jumpMaxPriv() {
        if nil == stashedPriv {
            stashedPriv = NSNumber(value: privacyV.getPrivacyValue())
            DBGLog("stashed priv %@", stashedPriv)
        }

        //[self.privacyObj setPrivacyValue:MAXPRIV];  // temporary max privacy level so see all
        privacyValue = MAXPRIV
        DBGLog("priv jump!")
    }

    class func restorePriv() {
        if nil == stashedPriv {
            return
        }
        //if (YES == self.openUrlLock) {
        //    return;
        //}
        DBGLog("restore priv to %@", stashedPriv)
        //[self.privacyObj setPrivacyValue:[self.stashedPriv intValue]];  // return to privacy level
        privacyValue = stashedPriv?.intValue ?? 0
        stashedPriv = nil

    }

    func lockDown() -> Int {
        DBGLog("privObj: lockdown")
        let currP = privacyValue

        ttv?.showKey(0)
        setPrivacyValue(MINPRIV)

        if (PWNEEDPRIVOK != pwState) && (PWNEEDPASS != pwState) {
            // 27.v.2013 don't set to query if no pw setup yet
            pwState = PWQUERYPASS
        }

        showing = PVNOSHOW
        //if ([self.configBtn.currentTitle isEqualToString:CFGBTNLOCK]) {
        //	self.showing = PVQUERY;
        //}
        return currP
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

    init(parentView pv: UIView?) {
        DBGLog("privV enter parent= x=%f y=%f w=%f h=%f", pv?.frame.origin.x, pv?.frame.origin.y, pv?.frame.size.width, pv?.frame.size.height)
        //CGRect frame = CGRectMake(0.0f, pv.frame.size.height,pv.frame.size.width,(pv.frame.size.height * PVH));
        // like this but need to re-calc button positions too :-( CGRect frame = CGRectMake(pv.frame.size.width-320.0, pv.frame.size.height,320.0,171.0);
        let frame = CGRect(x: 0.0, y: pv?.frame.size.height ?? 0.0, width: 320.0, height: 171.0)
        DBGLog("privacyV: x=%f y=%f w=%f h=%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
        super.init(frame: frame)
        parentView = pv
        pwState = PWNEEDPRIVOK //PWNEEDPASS;
        let bg = UIImageView(image: UIImage(named: rTracker_resource.getLaunchImageName() ?? ""))

        addSubview(bg)
        sendSubviewToBack(bg)

        backgroundColor = .white

        layer.cornerRadius = 8
        showing = PVNOSHOW
        //self.hidden = YES;
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
        return tob?.toQry2Int(sql) ?? 0
    }

    func dbSetKey(_ key: Int, level lvl: Int) {
        var sql: String?

        if key != 0 {
            sql = "insert or replace into priv1 (key,lvl) values ('\(key)','\(lvl)');"
        } else {
            sql = "delete from priv1 where lvl=\(lvl);"
        }
        tob?.toExecSql(sql)

    }

    func dbGetKey(_ lvl: Int) -> UInt {
        let sql = "select key from priv1 where lvl=\(lvl);"
        return UInt(tob?.toQry2Int(sql) ?? 0)
    }

    func dbGetAdjacentKey(_ lvl: UnsafeMutablePointer<Int>?, nxt: Bool) -> UInt {
        var rkey: Int
        var sql: String?

        if nxt {
            if let lvl {
                sql = "select key, lvl from priv1 where lvl>\(lvl) order by lvl asc limit 1;"
            }
        } else {
            if let lvl {
                sql = "select key, lvl from priv1 where lvl<\(lvl) order by lvl desc limit 1;"
            }
        }
        DBGLog("getAdjacentVal: next=%d in lvl=%d", nxt, lvl)
        tob?.toQry2IntInt(UnsafeMutablePointer<Int>(mutating: &rkey), i2: lvl, sql: sql)
        DBGLog("getAdjacentVal: rtn lvl=%d  key=%d", lvl, rkey)
        return UInt(rkey)
    }

    // MARK: -
    // MARK: show / hide view

    func hideConfigBtns(_ state: Bool) {
        saveBtn?.isHidden = state
        nextBtn?.isHidden = state
        prevBtn?.isHidden = state
        showSlider?.isHidden = state
        ssValLab?.isHidden = state
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
        pwState = PWNEEDPRIVOK
        showing = PVNOSHOW
        setPrivacyValue(MINPRIV)
    }

    @objc func ppwvResponse() {
        DBGLog("ppwvResponse: transition to %d", ppwv?.next)

        showing = ppwv?.next ?? 0
    }

    func showPVQ(_ state: Bool) {
        DBGLog("parent v h= %f  pvh= %f  prod= %f", parentView?.frame.size.height, PVH, (parentView?.frame.size.height ?? 0.0) * PVH)
        DBGLog("x= %f  y= %f  w= %f  h= %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
        if state {
            // show
            lastShow = Date().timeIntervalSinceReferenceDate
            configBtn?.setTitle(CFGBTNCONFIG, for: .normal)
            //self.transform = CGAffineTransformMakeTranslation(0, -(self.parentView.frame.size.height * PVH));
            //self.transform = CGAffineTransformMakeTranslation(0, -(self.parentView.frame.size.height * PVH));
            transform = CGAffineTransform(translationX: 0, y: -(frame.size.height))
            //self.parentView.userInteractionEnabled=NO;  // sadly kills interaction for child view as well
        } else {
            // hide
            let thisHide = Date().timeIntervalSinceReferenceDate
            DBGLog("lastShow= %lf thisHide= %lf delta= %lf", lastShow, thisHide, (thisHide - lastShow))
            if (thisHide - lastShow) <= 0.6 {
                ttv?.showKey(0)
                setPrivacyValue(PRIVDFLT)
            }
            ppwv?.hide()

            //self.transform = CGAffineTransformMakeTranslation(0, (self.parentView.frame.size.height * PVH));
            //self.transform = CGAffineTransformMakeTranslation(0, (self.parentView.frame.size.height * PVH));
            transform = CGAffineTransform(translationX: 0, y: frame.size.height)
            //self.parentView.userInteractionEnabled=YES;
        }
    }

    // make ttv match slider
    func setTTV() {
        let lvl = Int((showSlider?.value ?? 0.0) + 0.5)
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
        ssValLab?.text = "\(Int((showSlider?.value ?? 0.0) + 0.5))"
    }

    @objc func showConfig(_ btn: UIButton?) {

        if btn?.currentTitle == CFGBTNCONFIG {
            showing = PVCONFIG
        } else if btn?.currentTitle == CFGBTNLOCK {
            showing = PVQUERY
        }
    }

    @objc func doClear(_ btn: UIButton?) {
        ttv?.showKey(0)
    }

    @objc func saveConfig(_ btn: UIButton?) {
        var ttvkey: UInt

        if (ttvkey = ttv?.key ?? 0) != 0 {
            // don't allow saving blank tt for a privacy level
            dbSetKey(Int(ttvkey), level: Int((showSlider?.value ?? 0.0) + 0.5))
        }
    }

    @objc func adjustTTV(_ btn: UIButton?) {
        var lvl = Int((showSlider?.value ?? 0.0) + 0.5)
        ///*
        var k: UInt
        var dir: Bool
        if btn?.currentTitle == NXTBTNLBL {
            // next
            dir = true
        } else {
            // prev
            dir = false
        }

        DBGLog("adjustTTv: slider lvl= %d dir=%d", lvl, dir)

        k = dbGetAdjacentKey(UnsafeMutablePointer<Int>(mutating: &lvl), nxt: dir)

        if k == 0 {
            // if getAdjacent failed = no next/prev key for curr slider value
            lvl = Int((showSlider?.value ?? 0.0) + 0.5) // got wiped so reload
            if 0 == dbGetKey(lvl) {
                // and no existing key for curr slider
                //k = 
                dbGetAdjacentKey(UnsafeMutablePointer<Int>(mutating: &lvl), nxt: !dir) // go for prev/next (opposite dir)
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