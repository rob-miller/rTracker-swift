//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// ppwV.swift
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
//  ppw.h
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

///************
/// ppwV.swift
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
//  ppw.m
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import QuartzCore
import UIKit

/*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    - (void)drawRect:(CGRect)rect {
        // Drawing code
    }
    */
    var ObservingKeyboardNotification = false

class ppwV: UIView, UITextFieldDelegate {
    /*{
    	tObjBase *tob;
    	id parent;
    	SEL parentAction;
    	CGFloat topy;     // top of privacyV
    	unsigned int ok;
    	unsigned int cancel;
    	unsigned int next;

    	UIView *parentView;

        UITextField *activeField;
        //CGRect saveFrame;

    }*/
    var tob: tObjBase?
    var parent: UIView?
    var parentAction: Selector?
    var tbh: CGFloat = 0.0
    var topy: CGFloat = 0.0
    var ok: UInt = 0
    var cancel: UInt = 0
    var nextState: UInt = 0
    var parentView: UIView?
    var activeField: UITextField?
    //@property (nonatomic) CGRect saveFrame;

    // UI elements

    private var _topLabel: UILabel?
    var topLabel: UILabel? {
        if nil == _topLabel {
            //if (kIS_LESS_THAN_IOS7) {
            //    _topLabel = [[UILabel alloc] initWithFrame:[self genFrame:0.05f]];
            //} else {
            _topLabel = UILabel(frame: genFrame(0.15))
            //}
            //[topLabel setHidden:TRUE];
            _topLabel?.backgroundColor = .clear
            if let _topLabel {
                addSubview(_topLabel)
            }
        }
        return _topLabel
    }

    private var _topTF: UITextField?
    var topTF: UITextField? {
        if nil == _topTF {
            _topTF = UITextField(frame: genFrame(0.4))
            //[topTF setHidden:TRUE];
            _topTF?.backgroundColor = .systemBackground
            _topTF?.returnKeyType = .done
            _topTF?.autocapitalizationType = .none
            _topTF?.clearButtonMode = .whileEditing
            _topTF?.delegate = self
            _topTF?.layer.cornerRadius = 4
            _topTF?.borderStyle = .line

            if let _topTF {
                addSubview(_topTF)
            }
        }
        return _topTF
    }

    private var _cancelBtn: UIButton?
    var cancelBtn: UIButton? {
        if nil == _cancelBtn {
            let ttl = " Cancel "
            _cancelBtn = UIButton(type: .roundedRect)
            _cancelBtn?.setTitle(ttl, for: .normal)
            var f = CGRect.zero
            f.origin.x = 0.4 * frame.size.width
            f.origin.y = 0.65 * frame.size.height
            f.size = ttl.size(withAttributes: [
                NSAttributedString.Key.font: PrefBodyFont
            ])
            _cancelBtn?.frame = f
            //DBGLog(@"cancel frame: x: %f  y: %f  w: %f  h: %f",f.origin.x,f.origin.y,f.size.width,f.size.height);
            _cancelBtn?.addTarget(self, action: #selector(cancelp), for: .touchDown)

            if let _cancelBtn {
                addSubview(_cancelBtn)
            }
        }
        return _cancelBtn
    }

    //,saveFrame;


    // UITextField *activeField;
    //BOOL keyboardIsShown=NO;
    // CGRect saveFrame;

    init(parentView pv: UIView) {

        var frame: CGRect = CGRect.zero
        safeDispatchSync({
            frame = pv.frame
        })
        DBGLog(String("ppwV parent: x=\(frame.origin.x) y=\(frame.origin.y) w=\(frame.size.width) h=\(frame.size.height)"))

        //frame.origin.x = 0.0
        //frame.origin.y = 372.0
        frame.size.width = 320.0
        frame.size.height = 130.0
        DBGLog(String("ppwV: x=\(frame.origin.x) y=\(frame.origin.y) w=\(frame.size.width) h=\(frame.size.height)"))

        //tbh = par.navigationController!.toolbar.frame.height
        //topy = pv.frame.size.height - (frame.size.height + tbh)
        
        super.init(frame: frame)
        /*
        let bg = UIImageView(image: UIImage(named: rTracker_resource.getLaunchImageName() ?? ""))
        addSubview(bg)
        sendSubviewToBack(bg)
         */
        backgroundColor = .secondarySystemBackground // .clear

        layer.cornerRadius = 8
        parentView = pv

        //keyboardIsShown = NO;
        activeField = nil
        isHidden = true

        toggleKeyboardNotifications(true)

        //DBGLog(@"ppwv add view; parent has %d subviews",[pv.subviews count]);
        //[pv addSubview:self];

        pv.insertSubview(self, at: pv.subviews.count - 1) // 9.iii.14 change from -1 probably due to keyboard view
        // 15.xii.14 -2 back to -1
        //[pv addSubview:self];    // <- try for debug!
        // Initialization code
    }

    func toggleKeyboardNotifications(_ newState: Bool) {
        //if (resigningActive) newState=NO;  // regardless of input we should not be watching notification if resigningActive - except this happens on initial app start because initWithParentView called way early
        if newState == ObservingKeyboardNotification {
            return
        }
        if newState {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow(_:)),
                name: UIResponder.keyboardWillShowNotification,
                object: window)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(configTVObjVC.keyboardWillHide(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: window)
            ObservingKeyboardNotification = true
            DBGLog("*** watching keyboard notifications")
        } else {
            NotificationCenter.default.removeObserver(
                self,
                name: UIResponder.keyboardWillShowNotification,
                object: window)
            // unregister for keyboard notifications while not visible.
            NotificationCenter.default.removeObserver(
                self,
                name: UIResponder.keyboardWillHideNotification,
                object: window)
            ObservingKeyboardNotification = false
            DBGLog("*** STOP watching keyboard notifications")
        }
    }

    // MARK: -
    // MARK: external api

    func hide() {

        var f = frame
        //f.origin.y = ((UIView*)self.parent).frame.origin.y + ((UIView*)self.parent).frame.size.height;  // why different with privacyV ????
        //f.origin.y = ((UIView*)self.parent).frame.origin.y + ((UIView*)self.parent).frame.size.height;  // why different with privacyV ????

        f.origin.y = parentView?.frame.size.height ?? 0.0 // self.topy + self.frame.size.height;
        frame = f
        isHidden = true

        // unregister for keyboard notifications while not visible.
        toggleKeyboardNotifications(false)
    }

    func show() {

        var f = frame
        isHidden = false
        DBGLog(String("show: topy= \(topy)  f= \(f.origin.x) \(f.origin.y) \(f.size.width) \(f.size.height)"))

        f.origin.y = topy - frame.size.height

        toggleKeyboardNotifications(true)

        frame = f
    }

    @objc func keyboardWillShow(_ n: Notification?) {
        rTracker_resource.willShowKeyboard(n, vwTarg: self)
    }

    @objc func keyboardWillHide(_ n: Notification?) {
        DBGLog("handling keyboard will hide")
        rTracker_resource.willHideKeyboard()
    }

    func hidePPWV(animated: Bool) {
        //DBGLog(@"hide ppwv anim=%d",animated);
        if animated {
            //[UIView beginAnimations:nil context:NULL];
            //[UIView setAnimationDuration:kAnimationDuration];
            UIView.animate(withDuration: 0.2, animations: { [self] in
                hide()
                topTF?.resignFirstResponder()
            })
        } else {

            hide()

            //	[self.topLabel setHidden:TRUE];
            //	[self.topTF setHidden:TRUE];
            topTF?.resignFirstResponder()
        }
        //if (animated) {
        //	[UIView commitAnimations];
        //}

        //self.hidden = YES;
    }

    // MARK: -
    // MARK: show the different requesters

    func setUpPass(_ okState: UInt, cancel cancelState: UInt) {
        ok = okState
        cancel = cancelState
        //[self.topLabel setHidden:FALSE];
        topTF?.text = ""
        //[self.topTF setHidden:FALSE];
        //[self.cancelBtn setHidden:FALSE];
    }

    func showPassRqstr() {

        //[UIView beginAnimations:nil context:NULL];
        //[UIView setAnimationDuration:kAnimationDuration];

        UIView.animate(withDuration: 0.2, animations: {
            self.show()
        }) {(_) in
            // Code to be executed after the animation completes
            self.topTF?.becomeFirstResponder()
        }
            

        //[UIView commitAnimations];
    }

    func checkPass(_ okState: UInt, cancel cancelState: UInt) {
        //DBGLog(@"ppwv check pass");
        setUpPass(okState, cancel: cancelState)
        topLabel?.text = "Please enter password:"
        topTF?.addTarget(self, action: #selector(testp), for: .editingDidEnd)
        cancelBtn?.addTarget(self, action: #selector(cancelp), for: .touchDown)

        showPassRqstr()
    }

    let SetPassTxt = "Please set a password:"

    func createPass(_ okState: UInt, cancel cancelState: UInt) {
        DBGLog("ppwv create pass")
        setUpPass(okState, cancel: cancelState)

        topLabel?.text = SetPassTxt
        topTF?.addTarget(self, action: #selector(setp), for: .editingDidEnd)
        cancelBtn?.addTarget(self, action: #selector(cancelp), for: .touchDown)

        showPassRqstr()

    }

    //#pragma change password

    let ChangePassTxt = "Replace password:"

    @objc func cpSetTopLabel() {
        topLabel?.text = ChangePassTxt
    }

    @objc func changePAction() {
        //[self.topTF resignFirstResponder];
        //DBGLog(@"change p to .%@.",self.topTF.text);
        if !dbTestPass(topTF?.text) {
            // skip if the same (spurious editingdidend event on start)
            setp()
            topLabel?.text = "password changed"
            perform(#selector(cpSetTopLabel), with: nil, afterDelay: 1.0)
        }
    }

    func changePass(_ okState: UInt, cancel cancelState: UInt) {
        //DBGLog(@"ppwv change pass");
        setUpPass(okState, cancel: cancelState)
        cpSetTopLabel()
        topTF?.removeTarget(self, action: nil, for: .editingDidEnd)
        topTF?.addTarget(self, action: #selector(changePAction), for: .editingDidEnd)

        //[UIView beginAnimations:nil context:NULL];
        //[UIView setAnimationDuration:kAnimationDuration];
        UIView.animate(withDuration: 0.2, animations: { [self] in
            show()
        })
        //[UIView commitAnimations];
    }

    // MARK: -
    // MARK: password db interaction : password and key table creation as necessary

    func dbExistsPass() -> Bool {
        var sql = "create table if not exists priv0 (key integer primary key, val text);"
        tob?.toExecSql(sql:sql)
        sql = "select count(*) from priv0 where key=0;"
        if tob?.toQry2Int(sql:sql) != 0 {
            DBGLog("password exists")
            return true
        } else {
            DBGLog("password does not exist")
            sql = "create table if not exists priv1 (key integer primary key, lvl integer unique);"
            tob?.toExecSql(sql:sql)

            return false
        }
    }

    func dbTestPass(_ `try`: String?) -> Bool {
        let sql = "select val from priv0 where key=0;"
        // no empty or whitespace only passwords
        if !((`try`?.trimmingCharacters(in: .whitespaces).count ?? 0) > 0) {
            return false
        }

        let dbPass = rTracker_resource.fromSqlStr(tob?.toQry2Str(sql:sql))
        if dbPass == "" {
            return false // if here then dbquery failed
        }

        if `try` == rTracker_resource.fromSqlStr(tob?.toQry2Str(sql:sql)) {
            return true
        } else {
            return false
        }
    }

    func dbSetPass(_ pass: String?) {
        if !((pass?.trimmingCharacters(in: .whitespaces).count ?? 0) > 0) {
            return // no empty or whitespace-only passwords
        }

        let sql = "insert or replace into priv0 (key,val) values (0,'\(rTracker_resource.toSqlStr(pass) ?? "")');"
        tob?.toExecSql(sql:sql)
    }

    func dbResetPass() {
        let sql = "delete from priv0 where key=0;"
        tob?.toExecSql(sql:sql)
        DBGLog("password reset")
    }

    // MARK: button Actions

    @objc func setp() {
        DBGLog(String("enter tf= .\(topTF?.text ?? "")."))
        if !((topTF?.text?.trimmingCharacters(in: .whitespaces).count ?? 0) > 0) {
            // "" not valid password, or cancel
            nextState = cancel
        } else {
            dbSetPass(topTF?.text)
            nextState = ok
        }
        if (topLabel?.text != ChangePassTxt) && (topLabel?.text != SetPassTxt) {
            hide()
        }

        //[self.parent performSelector:self.parentAction];
        let imp = parent!.method(for: parentAction)
        let funcp = unsafeBitCast(imp, to: (@convention(c) (AnyObject, Selector) -> Void).self) // : ((Any?, Selector) -> Void)? = imp
        funcp(parent!, parentAction!)
    }

    @objc func cancelp() {
        topTF?.text = ""
        topTF?.resignFirstResponder() // closing topTF triggers setp action above
    }

    @objc func testp() {
        //DBGLog(@"testp: %@",self.topTF.text);
        if dbTestPass(topTF?.text) {
            nextState = ok
        } else {
            nextState = cancel
            hide()
        }

        topTF?.resignFirstResponder() // ???

        //[self.parent performSelector:self.parentAction];
        let imp = parent!.method(for: parentAction)
        let funcp = unsafeBitCast(imp, to: (@convention(c) (AnyObject, Selector) -> Void).self)  // : ((Any?, Selector) -> Void)? = imp
        funcp(parent!, parentAction!)
    }

    // MARK: -
    // MARK: UI element getters

    func genFrame(_ vert: CGFloat) -> CGRect {
        var f = frame
        f.origin.x = 0.05 * f.size.width
        f.origin.y = vert * f.size.height
        f.size.width *= 0.9
        f.size.height = "X".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).height * 1.2
        //DBGLog(@"genframe: x: %f  y: %f  w: %f  h: %f",f.origin.x,f.origin.y,f.size.width,f.size.height);
        return f
    }

    // MARK: -
    // MARK: keyboard notifications


    func textFieldDidBeginEditing(_ textField: UITextField) {
        DBGLog("ppwv: tf begin editing")
        activeField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        DBGLog("ppwv: tf end editing")
        activeField = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // the user pressed the "Done" button, so dismiss the keyboard
        DBGLog(String("textField done: \(textField.text ?? "")"))
        //[target ppwvResponse];
        //[target performSelector:action];

        textField.resignFirstResponder()
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        #if DEBUGLOG
        let touch = touches.first
        let touchPoint = touch?.location(in: self)
        DBGLog(String("I am touched at \(touchPoint!.x), \(touchPoint!.y)."))
        #endif

        resignFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
