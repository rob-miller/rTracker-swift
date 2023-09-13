//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// rTracker-resource.swift
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
//  rTracker-resource.swift
//  rTracker
//
//  Created by Rob Miller on 24/03/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import AudioToolbox
import CoreText
import Foundation
import UIKit
import UserNotifications

// make sqlite db files available from itunes? (perhaps prefs option later)
let DBACCESS = false

let DBLRANDOM = Double(arc4random()) / 0x100000000

// tag for background view to un/hide
let BGTAG = 99


// Sample code from iOS 7 Transistion Guide
// Loading Resources Conditionally
//NSUInteger DeviceSystemMajorVersion();
//#define kIS_LESS_THAN_IOS7 (DeviceSystemMajorVersion() < 7)
//#define kIS_LESS_THAN_IOS8 (DeviceSystemMajorVersion() < 8)



var keyboardIsShown = false
var currKeyboardView: UIView? = nil
var currKeyboardSaveFrame = CGRect.zero
var resigningActive = false
var loadingDemos = false
//---------------------------
    var hasAmPm = false
//---------------------------
    // MARK: -
    // MARK: activity indicator support
    var activityIndicator: UIActivityIndicatorView? = nil
var outerView: UIView?
var captionLabel: UILabel?
var activityIndicatorGoing = false
var progressBarGoing = false
var progressBar: UIProgressView? = nil
var localProgressVal: Float = 0.0
var localProgValTotal: Float = 0.0
var localProgValCurr: Float = 0.0
var localView: UIView?
var localNavItem: UINavigationItem?
var localDisable = false
//---------------------------
    // MARK: -
    // MARK: option settings to remember
    var separateDateTimePicker = SDTDFLT
var rtcsvOutput = RTCSVOUTDFLT
var savePrivate = SAVEPRIVDFLT
var acceptLicense = ACCEPTLICENSEDFLT
/*
     // can't set more than 4 :-(

    static NSUInteger SCICount=SCICOUNTDFLT;

    + (NSUInteger)getSCICount {
        return SCICount;
    }
    + (void)setSCICount:(NSUInteger)saveSCICount {
        SCICount = saveSCICount;
    }
    */

    /*
    static BOOL hideRTimes=HIDERTIMESDFLT;

     + (BOOL)getHideRTimes {
    	return hideRTimes;
    }

    + (void)setHideRTimes:(BOOL)hideRT {
    	hideRTimes = hideRT;
    	DBGLog(@"updateHideRTimes:%d",hideRTimes);
    }
    */
    var toldAboutSwipe = false
var toldAboutNotifications = false
var notificationsEnabled = false
var maintainerRqst = false

    //---------------------------

    // MARK: -
    // MARK: stash tracker
    var lastStashedTid = 0
// MARK: -
    // MARK: audio
    var sound1: SystemSoundID = 0
var bgColor: UIColor? = nil
var bgImage: UIImage? = nil


//#define SAFE_DISPATCH_SYNC(code) if ([NSThread isMainThread]) { code } else { dispatch_sync(dispatch_get_main_queue(), ^(void){ code }); }
/*
func safeDispatchSync(_ block: () -> ()) {
}
*/

// found syntax for this here :
// https://stackoverflow.com/questions/5225130/grand-central-dispatch-gcd-vs-performselector-need-a-better-explanation/5226271#5226271
// https://stackoverflow.com/a/8186206/2783487
func safeDispatchSync(_ block: () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync(execute: block)
    }
}


//---------------------------

// Sample code from iOS 7 Transistion Guide
// Loading Resources Conditionally
var _deviceSystemMajorVersion = {
var _deviceSystemMajorVersion = Int(UIDevice.current.systemVersion.components(
    separatedBy: ".")[0]) ?? 0
return _deviceSystemMajorVersion
}()


func DeviceSystemMajorVersion() -> Int {
    // `dispatch_once()` call was converted to a static variable initializer
    return _deviceSystemMajorVersion
}

func systemAudioCallback(_ ssID: SystemSoundID, _ clientData: UnsafeMutableRawPointer?) {
    AudioServicesRemoveSystemSoundCompletion(sound1)
    AudioServicesDisposeSystemSoundID(sound1)
}

class rTracker_resource: NSObject {
    //+ (void) safeDispatchSync:(dispatch_block_t) block ;

    //---------------------------

    class func ioFilePath(_ fname: String?, access: Bool) -> String {
        // nil acceptable for fname to just get docsdir
        var paths: [AnyHashable]?
        if access {
            paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path) // file itunes accessible
        } else {
            paths = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).map(\.path) // files not accessible
        }
        let docsDir = paths![0] as? String

        //DBGLog(@"ioFilePath= %@",[docsDir stringByAppendingPathComponent:fname] );

        if let fname {
            return URL(fileURLWithPath: docsDir!).appendingPathComponent(fname).path as String
        } else {
            return URL(fileURLWithPath: docsDir!).path
        }
    }

    class func deleteFile(atPath fp: String?) -> Bool {
        var err: Error?
        if true == FileManager.default.fileExists(atPath: fp ?? "") {
            DBGLog(String("deleting file at path \(fp)"))
            do {
                try FileManager.default.removeItem(atPath: fp ?? "")
            } catch let e {
                err = e
                DBGErr(String("Error deleting file: \(fp) error: \(err)"))
                return false
            }
            return true
        } else {
            DBGLog(String("request to delete non-existent file at path \(fp)"))
            return true
        }
    }

    class func protectFile(_ fp: String?) -> Bool {
        // not needed because NSFileProtectionComplete enabled at app level

        /*
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
            if (![[NSFileManager defaultManager] setAttributes:dict ofItemAtPath:fp error:&err]) {
            */

        do {
            try FileManager.default.setAttributes([
                .protectionKey: FileProtectionType.complete
            ], ofItemAtPath: fp ?? "")
        } catch let err {
            DBGErr(String("Error protecting file: \(fp) error: \(err))"))
            return false
        }
        return true
    }

    class func initHasAmPm() {
        let formatStringForHours = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: NSLocale.current)

        let containsA = (formatStringForHours as NSString?)?.range(of: "a")
        hasAmPm = containsA?.location != NSNotFound

    }

    //---------------------------

    // from http://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/TextLayout/Tasks/CountLines.html
    // Text Layout Programming Guide: Counting Lines of Text
    class func countLines(_ str: String?) -> Int {

        var numberOfLines: Int
        var index: Int
        let stringLength = str?.count ?? 0

        index = 0; numberOfLines = 0
        while index < stringLength {
            if let lineRange = (str as NSString?)?.lineRange(for: NSRange(location: index, length: 0)) {
                index = NSMaxRange(lineRange)
            }
            numberOfLines += 1
        }

        return numberOfLines
    }

    //---------------------------

    class func getCheckButton(_ frame: CGRect) -> UIButton? {
        let _checkButton = UIButton(type: .custom)
        _checkButton.backgroundColor = .clear

        _checkButton.frame = frame //CGRectZero;

        _checkButton.layer.cornerRadius = 8.0
        _checkButton.layer.masksToBounds = true
        _checkButton.layer.borderWidth = 1.0

        //[_checkButton setTitle:@"\u2714" forState:UIControlStateNormal];
        _checkButton.setTitle("", for: .normal)

        _checkButton.backgroundColor = .tertiarySystemBackground

        _checkButton.titleLabel?.font = PrefBodyFont
        _checkButton.contentVerticalAlignment = .center
        _checkButton.contentHorizontalAlignment = .center //Center;;  // UIControlContentHorizontalAlignmentRight; //Center;

        return _checkButton
    }

    class func setCheck(_ cb: UIButton?, colr: UIColor?) {
        if let colr {
            cb?.backgroundColor = colr
        }
        cb?.setTitle("\u{2714}", for: .normal)
    }

    class func clrCheck(_ cb: UIButton?, colr: UIColor?) {
        if let colr {
            cb?.backgroundColor = colr
        }
        cb?.setTitle("", for: .normal)
    }

    // MARK: -
    // MARK: generic alert
    //---------------------------
    class func alert_mt(_ title: String?, msg: String?, vc: UIViewController?) {
        var alert: UIAlertController?
        var vcCpy = vc
        // safeDispatchSync(^{
        alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)

        let defaultAction = UIAlertAction(
            title: "OK",
            style: .default,
            handler: { action in
            })

        alert?.addAction(defaultAction)

        if nil == vcCpy {
            let w = UIWindow(frame: UIScreen.main.bounds)
            w.rootViewController = UIViewController()
            w.windowLevel = UIWindow.Level(UIWindow.Level.alert.rawValue + 1)
            w.makeKeyAndVisible()
            vcCpy = w.rootViewController
        }
        //dispatch_async(dispatch_get_main_queue(), ^(void){
        if let alert {
            vcCpy?.present(alert, animated: true)
        }
        //});
        //});


    }

    class func alert(_ title: String?, msg: String?, vc: UIViewController?) {
        var alert: UIAlertController?
        var vcCpy = vc
        safeDispatchSync({
            //[rTracker_resource alert_mt:title msg:msg vc:vc];

            alert = UIAlertController(
                title: title,
                message: msg,
                preferredStyle: .alert)

            let defaultAction = UIAlertAction(
                title: "OK",
                style: .default,
                handler: { action in
                })

            alert?.addAction(defaultAction)

            if nil == vcCpy {
                /*
                let w = UIWindow(frame: UIScreen.main.bounds)
                w.rootViewController = UIViewController()
                w.windowLevel = UIWindow.Level(UIWindow.Level.alert.rawValue + 1)
                w.makeKeyAndVisible()
                 */
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let window = windowScene!.windows.first
                let rootViewController = window!.rootViewController
                vcCpy = rootViewController
            }
            //dispatch_async(dispatch_get_main_queue(), ^(void){
            DispatchQueue.main.async {
                if let alert {
                    vcCpy?.present(alert, animated: true)
                }
            }
            //});

        })

    }
    /*
    class func dismissAlertController(_ alertController: UIAlertController) {
        alertController.dismiss(animated: true, completion: nil)
    }

    class func doQuickAlert(title: String, msg: String, delay: Int, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        vc.present(alert, animated: true, completion: nil)
        //perform(#selector(dismissAlertController(_:)), with: alert, afterDelay: TimeInterval(delay))
         DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
             dismissAlertController(alert)
         }

    }
     */
    //---------------------------
    // MARK: -
    // MARK: navcontroller view transition

    // from http://freelancemadscience.squarespace.com/fmslabs_blog/2010/10/13/changing-the-transition-animation-for-an-uinavigationcontrol.html

    class func myNavPushTransition(_ navc: UINavigationController?, vc: UIViewController?, animOpt: Int) {
        if let view = navc?.view {
            UIView.transition(
                with: view,
                duration: 1.0,
                options: UIView.AnimationOptions(rawValue: UInt(animOpt)),
                animations: {
                    if let vc {
                        navc?.pushViewController(
                            vc,
                            animated: false)
                    }
                })
        }
    }

    class func myNavPopTransition(_ navc: UINavigationController?, animOpt: Int) {
        if let view = navc?.view {
            UIView.transition(
                with: view,
                duration: 1.0,
                options: UIView.AnimationOptions(rawValue: UInt(animOpt)),
                animations: {
                    navc?.popViewController(
                        animated: false)
                })
        }
    }

    //---------------------------

    class func colorSet() -> [UIColor] {
        return [
            UIColor.red,
            UIColor.green,
            UIColor.blue,
            UIColor.cyan,
            UIColor.yellow,
            UIColor.magenta,
            UIColor.orange,
            UIColor.purple,
            UIColor.brown,
            UIColor.white,
            UIColor.lightGray,
            UIColor.darkGray
        ]

    }

    class func colorNames() -> [String] {
        return [
            "red",
            "green",
            "blue",
            "cyan",
            "yellow",
            "magenta",
            "orange",
            "purple",
            "brown",
            "white",
            "lightGray",
            "darkGray"
        ]
    }

    class func vtypeNames() -> [String] {
        // indexes must match defns in valueObj.h 
        return [
            "number",
            "text",
            "textbox",
            "slider",
            "choice",
            "yes/no",
            "function",
            "info"
        ]
    }

    class func startActivityIndicator(_ view: UIView?, navItem: UINavigationItem?, disable: Bool, str: String?) {
        DBGLog("start spinner")
        var skip = false
        safeDispatchSync({
            if activityIndicatorGoing {
                skip = true
            }
            activityIndicatorGoing = true
        })
        if skip {
            return
        }

        if disable {
            view?.isUserInteractionEnabled = false
            //[navItem setHidesBackButton:YES animated:YES];
            navItem?.leftBarButtonItem?.isEnabled = false
            navItem?.rightBarButtonItem?.isEnabled = false
        }

        outerView = UIView(frame: CGRect(x: 75, y: 155, width: 170, height: 170))
        outerView?.backgroundColor = .secondarySystemBackground  // .clear  // .systemBackground // UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        outerView?.clipsToBounds = true
        outerView?.layer.cornerRadius = 10.0


        activityIndicator = UIActivityIndicatorView(style: .large)
        //activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray ];
        //activityIndicator.frame = CGRectMake(0.0, 0.0, 60.0, 60.0);
        activityIndicator?.frame = CGRect(x: 65, y: 40, width: activityIndicator?.bounds.size.width ?? 0.0, height: activityIndicator?.bounds.size.height ?? 0.0)

        //activityIndicator.backgroundColor = [UIColor blackColor];

        //activityIndicator.center = outerView.center;

        if let activityIndicator {
            outerView?.addSubview(activityIndicator)
        }
        activityIndicator?.startAnimating()

        captionLabel = UILabel(frame: CGRect(x: 20, y: 115, width: 130, height: 22))
        captionLabel?.backgroundColor = .clear
        captionLabel?.textColor = .label
        captionLabel?.adjustsFontSizeToFitWidth = true
        captionLabel?.textAlignment = .center // ios6 UITextAlignmentCenter;
        captionLabel?.text = str
        if let captionLabel {
            outerView?.addSubview(captionLabel)
        }

        //[activityIndicator performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:YES];

        if let outerView {
            view?.addSubview(outerView)
        }
        DBGLog("spinning")

    }

    class func finishActivityIndicator(_ view: UIView?, navItem: UINavigationItem?, disable: Bool) {
        DBGLog("stop spinner")

        //if (! activityIndicatorGoing) return;  // race condition, may not be set yet so ignore

        safeDispatchSync({
            if disable {
                //[navItem setHidesBackButton:NO animated:YES];
                navItem?.rightBarButtonItem?.isEnabled = true
                view?.isUserInteractionEnabled = true
            }

            //[activityIndicator stopAnimating];
            //activityIndicator?.performSelector(onMainThread: #selector(stopAnimating), with: nil, waitUntilDone: true)
            activityIndicator?.stopAnimating()


            outerView?.removeFromSuperview()

            activityIndicator = nil
            captionLabel = nil
            outerView = nil
            activityIndicatorGoing = false
        })
        DBGLog("not spinning")

    }

    class func startProgressBar(_ view: UIView?, navItem: UINavigationItem?, disable: Bool, yloc: CGFloat) {

        if disable {
            view?.isUserInteractionEnabled = false
            //[navItem setHidesBackButton:YES animated:YES];
            navItem?.leftBarButtonItem?.isEnabled = false
            navItem?.rightBarButtonItem?.isEnabled = false
        }

        //progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault ];
        progressBar = UIProgressView(progressViewStyle: .bar)
        var pbFrame = progressBar?.frame
        let vFrame = view?.frame
        pbFrame?.size.width = vFrame?.size.width ?? 0.0

        //pbFrame.origin.y = 70.0;
        pbFrame?.origin.y = yloc
        DBGLog(String("progressbar yloc= \(yloc)"))

        //pbFrame.size.height = 550;
        progressBar?.frame = pbFrame ?? CGRect.zero

        //progressBar.center = view.center;
        progressBarGoing = true
        if let progressBar {
            view?.addSubview(progressBar)
        }
        //[view bringSubviewToFront:progressBar];
        //[progressBar startAnimating];

        /*
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(updateProgressBar) 
                                                         name:rtProgressBarUpdateNotification 
                                                       object:nil];

          */
        //DBGLog(@"progressBar started");
    }

    class func setProgressVal(_ progressVal: Float) {
        localProgressVal = progressVal
        self.performSelector(onMainThread: #selector(updateProgressBar), with: nil, waitUntilDone: false)
    }

    @objc class func updateProgressBar() {
        progressBar?.progress = localProgressVal
        //DBGLog(@"progress bar updated: %f",localProgressVal);
    }

    //+ (void) updateProgressBar;
    class func stashProgressBarMax(_ total: Int) {
        localProgValTotal = Float(total)
        localProgValCurr = 0.0
    }

    class func bumpProgressBar() {
        localProgValCurr += 1.0
        self.setProgressVal(localProgValCurr / localProgValTotal)
        //DBGLog(@"setprogress %f", (localProgValCurr/localProgValTotal));
    }

    @objc class func doFinishProgressBar() {
        if localDisable {
            //[localNavItem setHidesBackButton:NO animated:YES];
            localNavItem?.leftBarButtonItem?.isEnabled = true
            localNavItem?.rightBarButtonItem?.isEnabled = true
            localView?.isUserInteractionEnabled = true
        }

        //[progressBar stopAnimating];

        progressBar?.removeFromSuperview()
        progressBar = nil
        progressBarGoing = false
        //DBGLog(@"progressbar finished");


    }

    class func finishProgressBar(_ view: UIView?, navItem: UINavigationItem?, disable: Bool) {
        if !progressBarGoing {
            return
        }
        localView = view
        localNavItem = navItem
        localDisable = disable
        self.performSelector(onMainThread: #selector(doFinishProgressBar), with: nil, waitUntilDone: true)
    }

    class func getSeparateDateTimePicker() -> Bool {
        return separateDateTimePicker
    }

    class func setSeparateDateTimePicker(_ sdt: Bool) {
        separateDateTimePicker = sdt
        //DBGLog(@"updateSeparateDateTimePicker:%d",separateDateTimePicker);
    }

    class func getRtcsvOutput() -> Bool {
        return rtcsvOutput
    }

    class func setRtcsvOutput(_ rtcsvOut: Bool) {
        rtcsvOutput = rtcsvOut
        //DBGLog(@"updateRtcsvOutput:%d",rtcsvOutput);
    }

    class func getSavePrivate() -> Bool {
        return savePrivate
    }

    class func setSavePrivate(_ savePriv: Bool) {
        savePrivate = savePriv
        //DBGLog(@"updateSavePrivate:%d",savePrivate);
    }

    class func getAcceptLicense() -> Bool {
        return acceptLicense
    }

    class func setAcceptLicense(_ acceptLic: Bool) {
        acceptLicense = acceptLic
        //DBGLog(@"updateAcceptLicense:%d",acceptLicense);
    }

    class func getToldAboutSwipe() -> Bool {
        return toldAboutSwipe
    }

    class func setToldAboutSwipe(_ toldSwipe: Bool) {
        toldAboutSwipe = toldSwipe
        DBGLog(String("updateToldAboutSwipe:\(toldAboutSwipe)"))
    }

    class func getToldAboutNotifications() -> Bool {
        return toldAboutNotifications
    }

    class func setToldAboutNotifications(_ toldNotifications: Bool) {
        toldAboutNotifications = toldNotifications
        DBGLog(String("updateToldAboutNotifications:\(toldAboutNotifications)"))
    }

    class func setNotificationsEnabled() {
        // if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        //safeDispatchSync(^{
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings(completionHandler: { settings in
            if settings.authorizationStatus == .authorized {
                notificationsEnabled = true
            }
        })
        // UIUserNotificationType types = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
        // return (types & UIUserNotificationTypeAlert);
        // }
        // else {
        // iOS 14 minimum now
        //    return [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
        // }
        //});
    }

    class func getNotificationsEnabled() -> Bool {
        return notificationsEnabled
    }

    class func getMaintainerRqst() -> Bool {
        return maintainerRqst
    }

    class func setMaintainerRqst(_ inMaintainerRqst: Bool) {
        maintainerRqst = inMaintainerRqst
        DBGLog(String("update maintainerRqst:\(maintainerRqst)"))
    }

    class func stashTracker(_ tid: Int) {
        let oldFname = "trkr\(tid).sqlite3"
        let newFname = "stash_trkr\(tid).sqlite3"
        var error: Error?

        DBGLog(String("stashing tracker \(tid)"))

        let fm = FileManager.default
        do {
            try fm.copyItem(
                atPath: rTracker_resource.ioFilePath(oldFname, access: DBACCESS),
                toPath: rTracker_resource.ioFilePath(newFname, access: DBACCESS))
        } catch let e {
            error = e
            DBGWarn(String("Unable to copy file \(oldFname) to \(newFname): \(error?.localizedDescription)"))
        }
    }

    class func rmStashedTracker(_ tid: Int) {
        var tid = tid
        if -1 == tid {
            return
        }
        if 0 == tid {
            if lastStashedTid != 0 {
                tid = lastStashedTid
            } else {
                return
            }
        }

        let fname = "stash_trkr\(tid).sqlite3"
        var error: Error?

        DBGLog(String("dumping stashed tracker \(tid)"))

        let fm = FileManager.default
        do {
            try fm.removeItem(atPath: rTracker_resource.ioFilePath(fname, access: DBACCESS))
        } catch let e {
            error = e
            DBGWarn(String("Unable to delete file \(fname): \(error?.localizedDescription)"))
        }
        lastStashedTid = 0

    }

    class func unStashTracker(_ tid: Int) {
        if -1 == tid {
            return
        }
        let oldFname = "stash_trkr\(tid).sqlite3"
        let newFname = "trkr\(tid).sqlite3"
        var error: Error?

        DBGLog(String("restoring stashed tracker \(tid)"))

        let fm = FileManager.default
        do {
            try fm.removeItem(atPath: rTracker_resource.ioFilePath(newFname, access: DBACCESS))
        } catch let e {
            error = e
            DBGLog(String("Unable to delete file \(newFname): \(error?.localizedDescription)"))
        }
        do {
            try fm.moveItem(
                atPath: rTracker_resource.ioFilePath(oldFname, access: DBACCESS),
                toPath: rTracker_resource.ioFilePath(newFname, access: DBACCESS))
        } catch let e {
            error = e
            DBGWarn(String("Unable to move file \(oldFname) to \(newFname): \(error?.localizedDescription)"))
        }
    }

    // MARK: -
    // MARK: sql


    class func fromSqlStr(_ instr: String?) -> String? {
        let outstr = instr?.replacingOccurrences(of: "''", with: "'")
        //DBGLog(@"in: %@  out: %@",instr,outstr);
        return outstr
    }

    class func toSqlStr(_ instr: String?) -> String? {
        //DBGLog(@"in: %@",instr);
        let outstr = instr?.replacingOccurrences(of: "'", with: "''")
        //DBGLog(@"in: %@  out: %@",instr,outstr);
        return outstr
    }

    // MARK: -

    class func negateNumField(_ text: String?) -> String? {
        var text = text

        text = text?.trimmingCharacters(in: .whitespaces)
        let range = (text as NSString?)?.range(of: "-")
        if NSNotFound == range?.location {
            return "-" + (text ?? "")
        } else {
            return text?.replacingOccurrences(of: "-", with: "")
        }

        //return [text stringByAppendingString:@"-"];
    }

    class func rrConfigTextField(_ frame: CGRect, key: String?, target: Any?, delegate: Any?, action: Selector, num: Bool, place: String?, text: String?) -> UITextField? {
        DBGLog(String(" frame x \(frame.origin.x) y \(frame.origin.y) w \(frame.size.width)) h \(frame.size.height)"))
        var rtf: UITextField?
        if num {
            rtf = numField(frame: frame) as UITextField
        } else {
            rtf = UITextField(frame: frame)
        }

        rtf?.clearsOnBeginEditing = false

        rtf?.delegate = delegate as? UITextFieldDelegate
        rtf?.returnKeyType = .done
        rtf?.borderStyle = .roundedRect
        rtf?.font = PrefBodyFont

        //dbgNSAssert((action != nil), "nil action")
        dbgNSAssert((target != nil), "nil action")

        rtf?.addTarget(target, action: action, for: .editingDidEndOnExit)
        //[rtf addTarget:target action:action forControlEvents:UIControlEventEditingDidEnd|UIControlEventEditingDidEndOnExit];
        rtf?.addTarget(target, action: action, for: .editingDidEnd)

        if num {

            //rtf.keyboardType = UIKeyboardTypeNumbersAndPunctuation;	// use the number input only
            rtf?.textAlignment = .right // ios6 UITextAlignmentRight;

            rtf?.keyboardType = .decimalPad //number pad with decimal point but no done button 	// use the number input only
            // no done button for number pad // _dtf.returnKeyType = UIReturnKeyDone;
            // need this from http://stackoverflow.com/questions/584538/how-to-show-done-button-on-iphone-number-pad Michael Laszlo
            // application frame deprecated ios9 float appWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
            let appWidth = Float(UIScreen.main.bounds.width)
            let accessoryView = UIToolbar(
                frame: CGRect(x: 0, y: 0, width: CGFloat(appWidth), height: CGFloat(0.1 * appWidth)))
            let space = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)
            let done = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: rtf,
                action: #selector(UIResponder.resignFirstResponder))

            let minus = UIBarButtonItem(
                title: "-",
                style: .plain,
                target: rtf,
                action: #selector(numField.minusKey))

            //[minus.action = [^{NSLog(@"Pressed the button");} copy] action:@selector(invoke) forControlEvents:UIControlEventTouchUpInside];

            //accessoryView.items = @[space, done, space];
            accessoryView.items = [space, done, space, minus, space]
            rtf?.inputAccessoryView = accessoryView
        }
        rtf?.placeholder = place

        if let text {
            rtf?.text = text
        }

        return rtf
    }

    //---------------------------------------
    /*
    + (CGSize)frameSizeForAttributedString:(NSAttributedString *)attributedString width:(CGFloat)width {
        CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
        //CGFloat width = YOUR_FIXED_WIDTH;

        CFIndex offset = 0, length;
        CGFloat y = 0;
        do {
            length = CTTypesetterSuggestLineBreak(typesetter, offset, width);
            CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(offset, length));

            CGFloat ascent, descent, leading;
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

            CFRelease(line);

            offset += length;
            y += ascent + descent + leading;
        } while (offset < [attributedString length]);

        CFRelease(typesetter);

        return CGSizeMake(width, ceil(y));
    }
     */
    //---------------------------------------

    // MARK: -
    // MARK: keyboard support

    class func willShowKeyboard(_ n: Notification?, view: UIView?, boty: CGFloat) {
        //var n = n

        if keyboardIsShown {
            // need bit more logic to handle additional scrolling for another textfield
            return
        }

        DBGLog(String("handling keyboard will show: \(n?.object)"))
        currKeyboardView = view
        currKeyboardSaveFrame = view?.frame ?? CGRect.zero

        let userInfo = n?.userInfo

        // get the size of the keyboard
        let boundsValue = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue //FrameBeginUserInfoKey
        let keyboardSize = boundsValue?.cgRectValue.size

        var viewFrame = view?.frame
        let topk = (viewFrame?.size.height ?? 0.0) - (keyboardSize?.height ?? 0.0) // - viewFrame.origin.y;

        if boty <= topk {
            DBGLog(String("activeField visible, do nothing  boty= \(boty)  topk= \(topk)"))
        } else {
            DBGLog(String("activeField hidden, scroll up  boty= \(boty)  topk= \(topk)"))
            viewFrame?.origin.y -= boty - topk

            //viewFrame.size.height -= self.navigationController.toolbar.frame.size.height;

            //[UIView beginAnimations:nil context:NULL];
            //[UIView setAnimationBeginsFromCurrentState:YES];
            //[UIView setAnimationDuration:kAnimationDuration];
            UIView.animate(withDuration: 0.2, animations: {
                if view?.responds(to: #selector(UIScrollView.flashScrollIndicators)) ?? false {
                    // if is scrollview
                    let sv = view as? UIScrollView
                    var scrollPos = sv?.contentOffset
                    scrollPos?.y += boty - topk
                    sv?.contentOffset = scrollPos ?? CGPoint.zero
                } else {
                    view?.frame = viewFrame ?? CGRect.zero
                }
            })

            //[UIView commitAnimations];
        }

        keyboardIsShown = true

    }

    class func willHideKeyboard() {
        //[UIView beginAnimations:nil context:NULL];
        //[UIView setAnimationBeginsFromCurrentState:YES];
        //[UIView setAnimationDuration:kAnimationDuration];
        UIView.animate(withDuration: 0.2, animations: {
            currKeyboardView?.frame = currKeyboardSaveFrame
        })
        //[UIView commitAnimations];

        keyboardIsShown = false
        currKeyboardView = nil
    }

    class func playSound(_ soundFileName: String?) {

        if nil == soundFileName {
            return
        }

        let soundURL = Bundle.main.url(
            forResource: soundFileName,
            withExtension: nil)

        DBGLog(String("soundfile = \(soundFileName) soundurl= \(soundURL)"))

        if let url = soundURL as CFURL? {
            AudioServicesCreateSystemSoundID(url, UnsafeMutablePointer<SystemSoundID>(mutating: &sound1))
        }
        AudioServicesAddSystemSoundCompletion(
            sound1,
            nil,
            nil,
            systemAudioCallback,
            nil)

        AudioServicesPlayAlertSound(sound1)
    }

    //---------------------------
    // MARK: -
    // MARK: launchImage support

    // figure out launchImage
    /*
    static BOOL getOrientEnabled=false;

    +(void) enableOrientationData
    {
        if (getOrientEnabled) return;
        //[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        getOrientEnabled=true;
    }
    +(void) disableOrientationData
    {
        if (! getOrientEnabled) return;
        //[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
        getOrientEnabled=false;
    }
    */
    class func isDeviceiPhone() -> Bool {
        //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

        if UIDevice.current.userInterfaceIdiom == .phone {
            return true
        }

        return false
    }

    //+(void)enableOrientationData;
    //+(void)disableOrientationData;
    class func isDeviceiPhone4() -> Bool {
        let size = UIScreen.main.bounds.size
        // iphone6+  414, 736
        // iphone6   375, 667
        // iphone 5s 320, 568
        // iphone 5  320, 568
        // iphone 4s 320, 480


        if (size.height == 480 && size.width == 320) || (size.height == 320 && size.width == 480) {
            return true
        }

        return false
    }

    class func isDeviceRetina() -> Bool {
        if UIScreen.main.responds(to: #selector(CADisplayLink.init(target:selector:))) && (UIScreen.main.scale == 2.0) {
            return true
        } else {
            return false
        }
    }

    class func getKeyWindowFrame() -> CGRect {
        var rframe: CGRect = CGRect.zero
        safeDispatchSync({
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            /*
            var window = UIApplication.shared.keyWindow
            if window == nil {
                window = UIApplication.shared.windows[0]
            }
             */
            rframe = window?.frame ?? CGRect.zero
        })

        return rframe
    }

    class func getOrientationFromWindow() -> UIDeviceOrientation {
        let f = rTracker_resource.getKeyWindowFrame()
        DBGLog(String("window : width \(f.size.width)   height \(f.size.height) "))
        if f.size.height > f.size.width {
            return .portrait
        }
        if f.size.width > f.size.height {
            return .landscapeLeft // could go further here
        }
        return .unknown
    }

    class func getKeyWindowWidth() -> CGFloat {
        return rTracker_resource.getKeyWindowFrame().size.width
    }

    let MAXDIM_4S = 480
    let MAXDIM_5 = 568
    let MAXDIM_6 = 667
    let MAXDIM_6P = 736

    class func getScreenMaxDim() -> CGFloat {
        let size = UIScreen.main.bounds.size
        return size.width > size.height ? size.width : size.height
    }

    class func getLaunchImageName() -> String? {
        return "LaunchScreenImg.png"

        /* no longer needed with story board
            NSArray *allPngImageNames = [[NSBundle mainBundle] pathsForResourcesOfType:@"png"
                                                    inDirectory:nil];

            for (NSString *imgName in allPngImageNames){
                DBGLog(@"imgName %@", imgName);
                // Find launch images
                if ([imgName containsString:@"LaunchImage"]){
                    UIImage *img = [UIImage imageNamed:imgName];
                    // Has image same scale and dimensions as our current device's screen?
                    if (img.scale == [UIScreen mainScreen].scale && CGSizeEqualToSize(img.size, [UIScreen mainScreen].bounds.size)) {
                        DBGLog(@"Found launch image for current device %@", img.description);
                        return imgName; //break;
                    }
                }
            }

            DBGLog(@"fail on launchimage name");
            return(@"LaunchScreenImg.png");
             */
    }

    ///***********************
    /// 640x1136   LaunchImage-568h@2x.png                iphone 5 retina
    /// LaunchImage-700-568h@2x.png
    /// LaunchImage-700-Landscape@2x~ipad.png
    /// LaunchImage-700-Landscape~ipad.png
    /// LaunchImage-700-Portrait@2x~ipad.png
    /// LaunchImage-700-Portrait~ipad.png
    /// LaunchImage-700@2x.png
    /// 2048x1496  LaunchImage-Landscape@2x~ipad.png      ipad landscape retina
    /// 1024x768   LaunchImage-Landscape~ipad.png         ipad landscape
    /// 1536x2008  LaunchImage-Portrait@2x~ipad.png       ipad portrait retina
    /// 768x1004   LaunchImage-Portrait~ipad.png          ipad portrait
    /// 768x1024
    /// 320x480    LaunchImage.png                        iphone 3gs
    /// 640x960    LaunchImage@2x.png                     iphone retina
    /// 750x1334   LaunchImage-800-667h@2x.png            iPhone 6
    /// 1242x2208  LaunchImage-800-Portrait-736h@3x.png   iPhone 6 Plus Portrait
    /// iphone6+  414, 736
    /// iphone6   375, 667
    /// iphone 5s 320, 568
    /// iphone 5  320, 568
    /// iphone 4s 320, 480
    /// ipad retina 768, 1024
    /// ipad air    768, 1024
    /// ipad2       768, 1024
    /// LaunchImage-568h@2x.png
    /// LaunchImage-700-568h@2x.png
    /// LaunchImage-700-Landscape@2x~ipad.png
    /// LaunchImage-700-Landscape~ipad.png
    /// LaunchImage-700-Portrait@2x~ipad.png
    /// LaunchImage-700-Portrait~ipad.png
    /// LaunchImage-700@2x.png
    /// LaunchImage-800-667h@2x.png
    /// LaunchImage-800-Landscape-736h@3x.png
    /// LaunchImage-800-Portrait-736h@3x.png
    /// LaunchImage-Landscape@2x~ipad.png
    /// LaunchImage-Landscape~ipad.png
    /// LaunchImage-Portrait@2x~ipad.png
    /// LaunchImage-Portrait~ipad.png
    /// LaunchImage.png
    /// LaunchImage@2x.png
    /// image name :
    /// The LaunchImages are special, and aren't actually an asset catalog on the device. If you look using iFunBox/iExplorer/etc (or on the simulator, or in the build directory) you can see the final names, and then write code to use them
    /// /Default-568h@2x.png
    /// /Default-667h-Landscap@2x.png
    /// /Default-667h@2x.png
    /// /Default-736h-Landscape@3x.png
    /// /Default-736h@3x.png
    /// /Default-iphone.png
    /// /Default-Landscape-ipad.png
    /// /Default-Landscape@2x-ipad.png
    /// /Default-Portrait-ipad.png
    /// /Default-Portrait@2x-ipad.png
    /// /Default.png
    /// /Default@2x-iphone.png
    /// /Default@2x.png
    /// /Default~iphone.png
    ///***********************

    // copied from http://www.creativepulse.gr/en/blog/2013/how-to-find-the-visible-width-and-height-in-an-ios-app
    class func getVisibleSize(of viewController: UIViewController?) -> CGSize {
        var result: CGSize = .zero

        let screenSize = UIScreen.main.bounds.size
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return result
        }

        let orientation = windowScene.interfaceOrientation
        
        if orientation.isLandscape {
            result.width = screenSize.height
            result.height = screenSize.width
        } else {
            result.width = screenSize.width
            result.height = screenSize.height
        }

        guard let viewController = viewController else { return result }
        let rootViewController = viewController.navigationController?.viewControllers.first

        if viewController == rootViewController {
            let statusBarManager = windowScene.statusBarManager
            let statusBarSize = statusBarManager?.statusBarFrame.size ?? .zero
            result.height -= min(statusBarSize.width, statusBarSize.height)
        }

        if let navigationController = viewController.navigationController {
            if viewController == rootViewController {
                let navigationBarSize = navigationController.navigationBar.frame.size
                result.height -= min(navigationBarSize.width, navigationBarSize.height)
            }

            if let toolbar = navigationController.toolbar {
                let toolbarSize = toolbar.frame.size
                result.height -= min(toolbarSize.width, toolbarSize.height)
            }
        }

        if let tabBarController = viewController.tabBarController {
            let tabBarSize = tabBarController.tabBar.frame.size
            result.height -= min(tabBarSize.width, tabBarSize.height)
        }

        return result
    }

    
    class func rtmx_get_visible_size(_ vc: UIViewController?) -> CGSize {
        var result: CGSize = CGSize.zero

        var size = UIScreen.main.bounds.size
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let orientation = windowScene!.interfaceOrientation
        /*
        // UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        let firstWindow = UIApplication.shared.windows.first
        let windowScene = firstWindow?.windowScene
        let orientation = windowScene?.interfaceOrientation
         */
        //if (UIInterfaceOrientationIsLandscape(vc.interfaceOrientation)) {
        if orientation.isLandscape {
            result.width = size.height
            result.height = size.width
        } else {
            result.width = size.width
            result.height = size.height
        }

        //DBGLog(@"gvs entry:  w= %f  h= %f",result.width, result.height);

        let rvc = (vc?.navigationController?.viewControllers)?[0]

        if vc == rvc {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            /*
            let firstWindow = UIApplication.shared.windows.first
            let windowScene = firstWindow?.windowScene
             */
            let uisbm = windowScene!.statusBarManager

            //size = [[UIApplication sharedApplication] statusBarFrame].size;
            size = uisbm?.statusBarFrame.size ?? CGSize.zero
            result.height -= CGFloat(min(size.width, size.height))

            //DBGLog(@"statusbar h= %f curr height= %f",size.height,result.height);
        }

        if vc?.navigationController != nil {
            if vc == rvc {
                size = vc?.navigationController?.navigationBar.frame.size ?? CGSize.zero
                result.height -= CGFloat(min(size.width, size.height))
                //DBGLog(@"navigationbar h= %f curr height= %f",size.height,result.height);
            }
            if vc?.navigationController?.toolbar != nil {
                size = vc?.navigationController?.toolbar.frame.size ?? CGSize.zero
                result.height -= CGFloat(min(size.width, size.height))
                //DBGLog(@"toolbar h= %f curr height= %f",size.height,result.height);
            }
        }

        if #available(iOS 11.0, *) {
            let sai = UIApplication.shared.delegate?.window??.safeAreaInsets
            result.height -= sai?.bottom ?? 0.0
        }

        if vc?.tabBarController != nil {
            size = vc?.tabBarController?.tabBar.frame.size ?? CGSize.zero
            result.height -= CGFloat(min(size.width, size.height))
            //DBGLog(@"tabbar h= %f curr height= %f",size.height,result.height);
        }

        //DBGLog(@"gvs exit:  w= %f  h= %f",result.width, result.height);

        return result
    }

    class func get_screen_size(_ vc: UIViewController?) -> CGSize {
        var result: CGSize = CGSize.zero

        let size = UIScreen.main.bounds.size
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let orientation = windowScene!.interfaceOrientation
        /*
        //UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        let firstWindow = UIApplication.shared.windows.first
        let windowScene = firstWindow?.windowScene
        let orientation = windowScene?.interfaceOrientation
         */
        //if (UIInterfaceOrientationIsLandscape(vc.interfaceOrientation)) {
        if orientation.isLandscape {
            result.width = size.height
            result.height = size.width
        } else {
            result.width = size.width
            result.height = size.height
        }

        return result
    }

    class func sanitizeFileNameString(_ fileName: String?) -> String? {
        let illegalFileNameCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>")
        return fileName?.components(separatedBy: illegalFileNameCharacters).joined(separator: "")
    }

    class func setViewMode(_ vc: UIViewController?) {

        var bgView: UIView?

        for subview in vc?.view.subviews ?? [] {
            if BGTAG == subview.tag {
                bgView = subview
                break
            }
        }

        //if #available(iOS 13.0, *) {
            if vc?.traitCollection.userInterfaceStyle == .dark {
                vc?.view.backgroundColor = .systemBackground
                bgView?.isHidden = true
                vc?.navigationController?.view.backgroundColor = nil
                vc?.navigationController?.navigationBar.backgroundColor = .tertiarySystemBackground
                vc?.navigationController?.toolbar.backgroundColor = .tertiarySystemBackground
                vc?.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
                vc?.navigationController?.toolbar.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
                return
            }
        //}

        bgView?.isHidden = false
        vc?.view.backgroundColor = .clear
        let img2 = rTracker_resource.get_background_image(vc)
        vc?.navigationController?.view.backgroundColor = rTracker_resource.get_background_color(vc) // [UIColor colorWithPatternImage:img2];
        vc?.navigationController?.navigationBar.setBackgroundImage(img2, for: .default)
        vc?.navigationController?.toolbar.setBackgroundImage(img2, forToolbarPosition: .any, barMetrics: .default)
    }

    class func get_background_color(_ vc: UIViewController?) -> UIColor? {
        if bgColor == nil {
            bgColor = UIColor(patternImage: rTracker_resource.get_background_image(vc)!)
        }
        return bgColor
    }

    class func get_background_image(_ vc: UIViewController?) -> UIImage? {
        if bgImage == nil {
            let vsize = rTracker_resource.get_screen_size(vc)
            let img = UIImage(named: rTracker_resource.getLaunchImageName() ?? "")
            //DBGLog(@"set backround image to %@",[rTracker_resource getLaunchImageName]);
            let bg = UIImageView(image: img)
            let scal = bg.frame.size.height / vsize.height
            if let CGImage = img?.cgImage {
                bgImage = UIImage(cgImage: CGImage, scale: scal, orientation: .up)
            }
        }
        return bgImage
    }
}
