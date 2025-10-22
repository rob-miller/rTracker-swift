//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// rTracker-resource.swift
/// Copyright 2011-2025 Robert T. Miller
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
//  Copyright 2011-2025 Robert T. Miller. All rights reserved.
//

import AVFoundation
import AudioToolbox
import CoreText
import Foundation
import UIKit
import UserNotifications

// make sqlite db files available from itunes? (perhaps prefs option later)
let DBACCESS = false

let DBLRANDOM = Double(arc4random()) / 0x1_0000_0000

// tag for background view to un/hide
let BGTAG = 99
let hiddenColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.6)

let LABELMINHEIGHT = 31.0  // uiswitch minimum intrinsic height

// Settings/Configuration icon - centralized SF Symbol name
let settingsIcon = "gear"

// HealthKit/Apple Health icon - centralized SF Symbol name
let healthKitIcon = "heart.fill"

// Privacy icon - centralized SF Symbol name
let privacyIcon = "sunglasses"

func minLabelHeight(_ height: CGFloat) -> CGFloat {
  return max(height, LABELMINHEIGHT)
}

var keyboardIsShown = false
var currKeyboardView: UIView? = nil
var currKeyboardSaveFrame = CGRect.zero
var resigningActive = false
var loadingDemos = false

var hasAmPm = false
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

var separateDateTimePicker = SDTDFLT
var rtcsvOutput = RTCSVOUTDFLT
var savePrivate = SAVEPRIVDFLT
var acceptLicense = ACCEPTLICENSEDFLT

var toldAboutSwipe = false
var toldAboutSwipe2 = false
var toldAboutNotifications = false
var toldToBackup = false
var shownWelcomeSheet = 0  // Version number, 0 = never shown
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

// Sample code from iOS 7 Transistion Guide
// Loading Resources Conditionally
var _deviceSystemMajorVersion = {
  var _deviceSystemMajorVersion =
    Int(
      UIDevice.current.systemVersion.components(
        separatedBy: ".")[0]) ?? 0
  return _deviceSystemMajorVersion
}()

func DeviceSystemMajorVersion() -> Int {
  return _deviceSystemMajorVersion
}

func systemAudioCallback(_ ssID: SystemSoundID, _ clientData: UnsafeMutableRawPointer?) {
  AudioServicesRemoveSystemSoundCompletion(sound1)
  AudioServicesDisposeSystemSoundID(sound1)
}

class rTracker_resource: NSObject {
  static let shared = rTracker_resource()

  private override init() {
    super.init()
    // Additional setup if needed
  }

  var vhHKchange = false  // signify vo healthkit source changed and need to wipe data if saved later

  // For UIKit-based apps
  class func getSafeAreaInsets() -> UIEdgeInsets {
    // Get the active window scene
    if let windowScene = UIApplication.shared.connectedScenes.first(where: {
      $0.activationState == .foregroundActive
    }) as? UIWindowScene,
      let window = windowScene.windows.first(where: { $0.isKeyWindow })
    {
      return window.safeAreaInsets
    }
    return .zero
  }

  class func ioFilePath(_ fname: String?, access: Bool, tmp: Bool = false) -> String {
    var pathURL: URL

    if access {
      // File iTunes accessible - use Documents directory
      pathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    } else {
      // Files not accessible via iTunes - use Temporary directory
      if tmp {
        pathURL = FileManager.default.temporaryDirectory
      } else {
        pathURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
      }
    }

    if let filename = fname {
      // If a filename is provided, append it to the directory path
      return pathURL.appendingPathComponent(filename).path
    } else {
      // If no filename is provided, return the directory path
      return pathURL.path
    }
  }

  class func deleteFile(atPath fp: String) -> Bool {
    var err: Error?
    if true == FileManager.default.fileExists(atPath: fp) {
      DBGLog(String("deleting file at path \(fp)"))
      do {
        try FileManager.default.removeItem(atPath: fp)
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

  class func copyFileToInboxDirectory(from sourceURL: URL) {
    let fileManager = FileManager.default

    // Construct the target URL in the app's Documents/Inbox directory
    guard
      let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    else {
      DBGWarn("Failed to locate the Documents directory.")
      return
    }
    let inboxDirectory = documentsDirectory.appendingPathComponent("Inbox")
    let targetURL = inboxDirectory.appendingPathComponent(sourceURL.lastPathComponent)

    // Create the Inbox directory if it does not exist
    if !fileManager.fileExists(atPath: inboxDirectory.path) {
      do {
        try fileManager.createDirectory(
          at: inboxDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        DBGWarn("Failed to create the Inbox directory: \(error)")
        return
      }
    }

    // Copy the file from the source URL to the target URL
    do {
      if fileManager.fileExists(atPath: targetURL.path) {
        // Optional: Remove the existing file at the target location before copying
        try fileManager.removeItem(at: targetURL)
      }
      try fileManager.copyItem(at: sourceURL, to: targetURL)
      DBGLog("File copied successfully to \(targetURL.path)")
    } catch {
      DBGWarn("Failed to copy the file: \(error)")
    }
  }

  class func protectFile(_ fp: String?) -> Bool {
    do {
      try FileManager.default.setAttributes(
        [
          .protectionKey: FileProtectionType.complete
        ], ofItemAtPath: fp ?? "")
    } catch let err {
      DBGErr(String("Error protecting file: \(fp) error: \(err))"))
      return false
    }
    return true
  }

  class func initHasAmPm() {
    let formatStringForHours = DateFormatter.dateFormat(
      fromTemplate: "j", options: 0, locale: NSLocale.current)

    let containsA = (formatStringForHours as NSString?)?.range(of: "a")
    hasAmPm = containsA?.location != NSNotFound

  }

  class func countLines(_ str: String?) -> Int {

    var numberOfLines: Int
    var index: Int
    let stringLength = str?.count ?? 0

    index = 0
    numberOfLines = 0
    while index < stringLength {
      if let lineRange = (str as NSString?)?.lineRange(for: NSRange(location: index, length: 0)) {
        index = NSMaxRange(lineRange)
      }
      numberOfLines += 1
    }

    return numberOfLines
  }

  class func rtmx_getCheckButton(_ frame: CGRect) -> UIButton? {
    let _checkButton = UIButton(type: .custom)
    _checkButton.backgroundColor = .clear

    _checkButton.frame = frame  //CGRectZero;

    _checkButton.layer.cornerRadius = 8.0
    _checkButton.layer.masksToBounds = true
    _checkButton.layer.borderWidth = 1.0

    //[_checkButton setTitle:@"\u2714" forState:UIControlStateNormal];
    _checkButton.setTitle("", for: .normal)

    _checkButton.backgroundColor = .tertiarySystemBackground

    _checkButton.titleLabel?.font = PrefBodyFont
    _checkButton.contentVerticalAlignment = .center
    _checkButton.contentHorizontalAlignment = .center  //Center;;  // UIControlContentHorizontalAlignmentRight; //Center;

    return _checkButton
  }

  class func getSwitch(_ frame: CGRect) -> UISwitch? {
    let _switch = UISwitch()
    let swSize = _switch.intrinsicContentSize  // frame size is ignored for switch
    var frame = frame
    frame.origin.x = (frame.origin.x + frame.size.width) - swSize.width
    frame.origin.y = frame.origin.y + (frame.size.height - swSize.height) / 2

    _switch.frame = frame
    return _switch
  }

  class func rtmx_setCheck(_ cb: UIButton?, colr: UIColor?) {
    if let colr {
      cb?.backgroundColor = colr
    }
    cb?.setTitle("\u{2714}", for: .normal)
  }

  class func rtmx_clrCheck(_ cb: UIButton?, colr: UIColor?) {
    if let colr {
      cb?.backgroundColor = colr
    }
    cb?.setTitle("", for: .normal)
  }

  class func setSwitch(_ sw: UISwitch, colr: UIColor?) {
    if let colr {
      sw.onTintColor = colr
    }
    sw.isOn = true
  }

  class func clrSwitch(_ sw: UISwitch, colr: UIColor?) {
    if let colr {
      sw.backgroundColor = colr
    }
    sw.isOn = false

  }

  class func addTimedLabel(
    text: String, tag: Int, sv: UIView, ti: TimeInterval? = nil,
    viewController: UIViewController? = nil
  ) {
    // Sizing ------------------------------------------------------
    let font = UIFont.preferredFont(forTextStyle: .body)
    let hPad: CGFloat = 16  // horizontal padding
    let vPad: CGFloat = 8  // vertical padding
    let limit = sv.bounds.width * 0.8

    // Measure the string (multi-line aware)
    let boundingSize = CGSize(
      width: limit - 2 * hPad,
      height: .greatestFiniteMagnitude)

    let textRect = (text as NSString)
      .boundingRect(
        with: boundingSize,
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
      )
      .integral  // round up to whole pixels

    let labelSize = CGSize(
      width: textRect.width + 2 * hPad,
      height: textRect.height + 2 * vPad)

    // Label set-up -----------------------------------------------
    let label = UILabel(frame: CGRect(origin: .zero, size: labelSize))

    // Calculate dynamic Y position based on navigation bar height
    let yPosition: CGFloat = {
      if let vc = viewController,
        let navController = vc.navigationController
      {
        let navFrame = navController.navigationBar.frame
        let navBottom = navFrame.origin.y + navFrame.height
        return navBottom + 20  // 20 points margin below navigation bar
      } else {
        return 100  // Fallback to original hardcoded position
      }
    }()

    label.center = CGPoint(x: sv.center.x, y: yPosition)
    label.textAlignment = .center
    label.text = text
    label.backgroundColor = UIColor.systemGray.withAlphaComponent(0.7)
    label.textColor = UIColor.white
    label.layer.cornerRadius = 10
    label.clipsToBounds = true
    label.tag = tag
    sv.addSubview(label)

    if let ti = ti {
      Timer.scheduledTimer(withTimeInterval: ti, repeats: false) { _ in
        if let label = sv.viewWithTag(tag) {
          label.removeFromSuperview()
        }
      }
    }
  }

  class func removeLabels(view: UIView, labelIds: [Int]) {
    for lid in labelIds {
      if let label = view.viewWithTag(lid) {
        label.removeFromSuperview()
      }
    }
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

    if let alert {
      vcCpy?.present(alert, animated: true)
    }
  }

  class func topViewController(
    _ base: UIViewController? = UIApplication.shared.connectedScenes.filter({
      $0.activationState == .foregroundActive
    }).map({ $0 as? UIWindowScene }).compactMap({ $0 }).first?.windows.filter({ $0.isKeyWindow })
      .first?.rootViewController
  ) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      if let selected = tab.selectedViewController {
        return topViewController(selected)
      }
    }
    if let presented = base?.presentedViewController {
      return topViewController(presented)
    }
    return base
  }

  class func alert(_ title: String?, msg: String?, vc: UIViewController?) {
    var alert: UIAlertController?
    var vcCpy = vc
    safeDispatchSync({

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
        vcCpy = topViewController()  // rootViewController
      }
      //dispatch_async(dispatch_get_main_queue(), ^(void){
      DispatchQueue.main.async {
        if let alert {
          vcCpy?.present(alert, animated: true)
        }
      }
    })
  }

  // MARK: -
  // MARK: navcontroller view transition

  class func myNavPushTransition(
    _ navc: UINavigationController?, vc: UIViewController?, animOpt: Int
  ) {
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

  static let colorSet: [UIColor] = [
    UIColor.red,
    UIColor.systemGreen,  //green,
    UIColor.blue,
    UIColor.cyan,
    UIColor.yellow,
    UIColor.magenta,
    UIColor.orange,
    UIColor.purple,
    UIColor.brown,
    UIColor.white,
    UIColor.lightGray,
    UIColor.darkGray,
  ]

  static let colorNames: [String] = [
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
    "darkGray",
  ]

  // Spectrum-ordered colors for charts - no white, black, or grays
  static let colorSpectrum: [UIColor] = [
    UIColor.red,  // Red (700nm)
    UIColor.orange,  // Orange (620nm)
    UIColor.yellow,  // Yellow (580nm)
    UIColor.systemGreen,  // Green (530nm)
    UIColor.cyan,  // Cyan (490nm)
    UIColor.blue,  // Blue (470nm)
    UIColor.systemIndigo,  // Indigo (450nm)
    UIColor.purple,  // Purple (420nm)
    UIColor.magenta,  // Magenta (back to red spectrum)
  ]

  // vtypeNames array removed - now handled by ValueObjectType enum in valueObj.swift

  class func startActivityIndicator(
    _ view: UIView?, navItem: UINavigationItem?, disable: Bool, str: String?
  ) {
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

    // Create modern centered container
    let screenBounds = UIScreen.main.bounds
    let containerWidth: CGFloat = 200
    let containerHeight: CGFloat = 120
    let centerX = (screenBounds.width - containerWidth) / 2
    let centerY = (screenBounds.height - containerHeight) / 2

    outerView = UIView(
      frame: CGRect(x: centerX, y: centerY, width: containerWidth, height: containerHeight))
    outerView?.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
    outerView?.clipsToBounds = true
    outerView?.layer.cornerRadius = 16.0

    // Add subtle shadow for depth
    outerView?.layer.shadowColor = UIColor.black.cgColor
    outerView?.layer.shadowOffset = CGSize(width: 0, height: 2)
    outerView?.layer.shadowOpacity = 0.1
    outerView?.layer.shadowRadius = 8.0
    outerView?.layer.masksToBounds = false

    // Add subtle border
    outerView?.layer.borderWidth = 0.5
    outerView?.layer.borderColor = UIColor.separator.cgColor

    activityIndicator = UIActivityIndicatorView(style: .large)
    activityIndicator?.color = .systemBlue
    activityIndicator?.center = CGPoint(x: containerWidth / 2, y: 35)

    if let activityIndicator {
      outerView?.addSubview(activityIndicator)
    }
    activityIndicator?.startAnimating()

    // Improved label styling
    captionLabel = UILabel(frame: CGRect(x: 16, y: 65, width: containerWidth - 32, height: 40))
    captionLabel?.backgroundColor = .clear
    captionLabel?.textColor = .label
    captionLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    captionLabel?.adjustsFontSizeToFitWidth = true
    captionLabel?.minimumScaleFactor = 0.8
    captionLabel?.numberOfLines = 2
    captionLabel?.textAlignment = .center
    captionLabel?.text = str
    if let captionLabel {
      outerView?.addSubview(captionLabel)
    }

    if let outerView {
      view?.addSubview(outerView)
    }
    DBGLog("spinning")

  }

  class func finishActivityIndicator(_ view: UIView?, navItem: UINavigationItem?, disable: Bool) {
    DBGLog("stop spinner")

    safeDispatchSync({
      if disable {
        //[navItem setHidesBackButton:NO animated:YES];
        navItem?.rightBarButtonItem?.isEnabled = true
        view?.isUserInteractionEnabled = true
      }

      activityIndicator?.stopAnimating()

      outerView?.removeFromSuperview()
      outerView?.layer.removeFromSuperlayer()

      activityIndicator = nil
      captionLabel = nil
      outerView = nil
      activityIndicatorGoing = false
    })
    DBGLog("not spinning")
  }

  class func startProgressBar(
    _ view: UIView?, navItem: UINavigationItem?, disable: Bool, yloc: CGFloat
  ) {

    if disable {
      view?.isUserInteractionEnabled = false
      //[navItem setHidesBackButton:YES animated:YES];
      navItem?.leftBarButtonItem?.isEnabled = false
      navItem?.rightBarButtonItem?.isEnabled = false
    }

    progressBar = UIProgressView(progressViewStyle: .bar)
    var pbFrame = progressBar?.frame
    let vFrame = view?.frame
    pbFrame?.size.width = vFrame?.size.width ?? 0.0

    pbFrame?.origin.y = yloc
    //DBGLog(String("progressbar yloc= \(yloc)"))

    progressBar?.frame = pbFrame ?? CGRect.zero

    progressBarGoing = true
    if let progressBar {
      view?.addSubview(progressBar)
    }
  }

  class func setProgressVal(_ progressVal: Float) {
    localProgressVal = progressVal
    self.performSelector(
      onMainThread: #selector(updateProgressBar), with: nil, waitUntilDone: false)
  }

  @objc class func updateProgressBar() {
    progressBar?.progress = localProgressVal
  }

  //+ (void) updateProgressBar;
  class func stashProgressBarMax(_ total: Int) {
    localProgValTotal = Float(total)
    localProgValCurr = 0.0
  }

  class func bumpProgressBar() {
    localProgValCurr += 1.0
    self.setProgressVal(localProgValCurr / localProgValTotal)

  }

  @objc class func doFinishProgressBar() {
    if localDisable {
      localNavItem?.leftBarButtonItem?.isEnabled = true
      localNavItem?.rightBarButtonItem?.isEnabled = true
      localView?.isUserInteractionEnabled = true
    }

    progressBar?.removeFromSuperview()
    progressBar = nil
    progressBarGoing = false

  }

  class func finishProgressBar(_ view: UIView?, navItem: UINavigationItem?, disable: Bool) {
    if !progressBarGoing {
      return
    }
    localView = view
    localNavItem = navItem
    localDisable = disable
    self.performSelector(
      onMainThread: #selector(doFinishProgressBar), with: nil, waitUntilDone: true)
  }

  class func getSeparateDateTimePicker() -> Bool {
    return separateDateTimePicker
  }

  class func setSeparateDateTimePicker(_ sdt: Bool) {
    separateDateTimePicker = sdt
  }

  class func getRtcsvOutput() -> Bool {
    return rtcsvOutput
  }

  class func setRtcsvOutput(_ rtcsvOut: Bool) {
    rtcsvOutput = rtcsvOut
  }

  class func getSavePrivate() -> Bool {
    return savePrivate
  }

  class func setSavePrivate(_ savePriv: Bool) {
    savePrivate = savePriv
  }

  class func getAcceptLicense() -> Bool {
    return acceptLicense
  }

  class func setAcceptLicense(_ acceptLic: Bool) {
    acceptLicense = acceptLic
  }

  class func getToldAboutSwipe() -> Bool {
    return toldAboutSwipe
  }

  class func getToldAboutSwipe2() -> Bool {
    return toldAboutSwipe2
  }

  class func setToldAboutSwipe(_ toldSwipe: Bool) {
    toldAboutSwipe = toldSwipe
    //DBGLog(String("updateToldAboutSwipe:\(toldAboutSwipe)"))
  }

  class func setToldAboutSwipe2(_ toldSwipe2: Bool) {
    toldAboutSwipe2 = toldSwipe2
    //DBGLog(String("updateToldAboutSwipe2:\(toldAboutSwipe2)"))
  }

  class func getToldAboutNotifications() -> Bool {
    return toldAboutNotifications
  }

  class func setToldAboutNotifications(_ toldNotifications: Bool) {
    toldAboutNotifications = toldNotifications
    //DBGLog(String("updateToldAboutNotifications:\(toldAboutNotifications)"))
  }

  class func getToldToBackup() -> Bool {
    return toldToBackup
  }

  class func setToldToBackup(_ told: Bool) {
    toldToBackup = told
  }

  class func getShownWelcomeSheet() -> Int {
    return shownWelcomeSheet
  }

  class func setShownWelcomeSheet(_ version: Int) {
    shownWelcomeSheet = version
  }

  class func setNotificationsEnabled() {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings(completionHandler: { settings in
      if settings.authorizationStatus == .authorized {
        notificationsEnabled = true
      }
    })
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
      DBGErr(
        String("Unable to copy file \(oldFname) to \(newFname): \(error?.localizedDescription)"))
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
      DBGErr(String("Unable to delete file \(fname): \(error?.localizedDescription)"))
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
      DBGErr(
        String("Unable to move file \(oldFname) to \(newFname): \(error?.localizedDescription)"))
    }
  }

  // MARK: -
  // MARK: sql

  class func fromSqlStr(_ instr: String) -> String {
    let outstr = instr.replacingOccurrences(of: "''", with: "'")
    //DBGLog(@"in: %@  out: %@",instr,outstr);
    return outstr
  }

  class func toSqlStr(_ instr: String) -> String {
    //DBGLog(@"in: %@",instr);
    let outstr = instr.replacingOccurrences(of: "'", with: "''")
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
  }

  class func rrConfigTextField(
    _ frame: CGRect, key: String?, target: Any?, delegate: Any?, action: Selector, num: Bool,
    place: String?, text: String?
  ) -> UITextField? {
    DBGLog(
      String(
        " frame x \(frame.origin.x) y \(frame.origin.y) w \(frame.size.width)) h \(frame.size.height)"
      ))

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
      rtf?.textAlignment = .right  // ios6 UITextAlignmentRight;

      rtf?.keyboardType = .decimalPad  //number pad with decimal point but no done button 	// use the number input only
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

  // MARK: -
  // MARK: keyboard support

  class func calculateScreenOffset(of view: UIView?) -> CGFloat? {
    var currentView = view
    var totalYOrigin: CGFloat = 0.0

    while let unwrappedCurrentView = currentView {
      totalYOrigin += unwrappedCurrentView.frame.origin.y
      currentView = unwrappedCurrentView.superview
    }

    guard let initialView = view else { return nil }
    return totalYOrigin + initialView.frame.height
  }
  class func calculateBottomYCoordinate(of view: UIView?) -> CGFloat? {
    guard let view = view, let window = view.window else {
      return nil
    }

    let bottomLeftPointInLocalCoordinates = CGPoint(x: 0, y: view.bounds.height)

    if let cell = view as? UITableViewCell {
      if let tableView = cell.superview as? UITableView {
        let pointInTableView = cell.convert(bottomLeftPointInLocalCoordinates, to: tableView)
        let pointInWindow = tableView.convert(pointInTableView, to: tableView.window)
        return pointInWindow.y
      }
    }

    // view is not a UITableViewCell, or the superview is not a UITableView
    let bottomLeftPointInWindowCoordinates = view.convert(
      bottomLeftPointInLocalCoordinates, to: window)
    return bottomLeftPointInWindowCoordinates.y
  }

  @objc class func willShowKeyboard(_ n: Notification?, vwTarg: UIView?, vwScroll: UIView? = nil) {

    guard let vwTarg = vwTarg else {
      return
    }
    if keyboardIsShown {
      // need bit more logic to handle additional scrolling for another textfield
      return
    }

    let vwS = vwScroll ?? vwTarg
    DBGLog(String("handling keyboard will show"))
    currKeyboardView = vwS
    currKeyboardSaveFrame = vwS.frame

    let userInfo = n?.userInfo

    // get the size of the keyboard
    let boundsValue = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue  //FrameBeginUserInfoKey
    let keyboardOrigin = boundsValue?.cgRectValue.origin

    var viewFrame = vwS.frame
    let topk = keyboardOrigin!.y  // + keyboardSize!.height

    //if var boty = calculateScreenOffset(of: vwTarg) {
    if var boty = calculateBottomYCoordinate(of: vwTarg) {
      boty += MARGIN
      if boty <= topk {
        DBGLog(String("activeField visible, do nothing  boty= \(boty)  topk= \(topk)"))
      } else {
        DBGLog(String("activeField hidden, scroll up  boty= \(boty)  topk= \(topk)"))
        viewFrame.origin.y -= boty - topk

        UIView.animate(
          withDuration: 0.2,
          animations: {
            if vwS.responds(to: #selector(UIScrollView.flashScrollIndicators)) {
              // if is scrollview
              let sv = vwS as? UIScrollView
              var scrollPos = sv?.contentOffset
              scrollPos?.y += boty - topk
              sv?.contentOffset = scrollPos ?? CGPoint.zero
            } else {
              vwS.frame = viewFrame
            }
          })
      }
      keyboardIsShown = true
    }

  }

  class func willHideKeyboard() {
    //[UIView beginAnimations:nil context:NULL];
    //[UIView setAnimationBeginsFromCurrentState:YES];
    //[UIView setAnimationDuration:kAnimationDuration];
    UIView.animate(
      withDuration: 0.2,
      animations: {
        currKeyboardView?.frame = currKeyboardSaveFrame
      })
    //[UIView commitAnimations];

    keyboardIsShown = false
    currKeyboardView = nil
  }

  class func playSound(_ soundFileName: String?) {

    // Guard against nil filename
    guard let soundFileName = soundFileName else {
      DBGLog("Error: Sound filename is nil")
      return
    }

    guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
      DBGLog("Error: Unable to find resource with filename \(soundFileName)")
      return
    }

    DBGLog("soundfile = \(soundFileName) soundurl= \(soundURL)")

    var soundID: SystemSoundID = 0
    let result = AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
    if result != kAudioServicesNoError {
      DBGLog("Error creating audio system sound with ID: \(result)")
      return
    }

    AudioServicesAddSystemSoundCompletion(soundID, nil, nil, systemAudioCallback, nil)

    AudioServicesPlayAlertSound(soundID)
  }

  //---------------------------
  // MARK: -
  // MARK: launchImage support

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
      return .landscapeLeft  // could go further here
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
  }

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

  class func get_screen_size(_ vc: UIViewController?) -> CGSize {
    var result: CGSize = CGSize.zero

    let size = UIScreen.main.bounds.size
    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
    let orientation = windowScene!.interfaceOrientation

    if orientation.isLandscape {
      result.width = size.height
      result.height = size.width
    } else {
      result.width = size.width
      result.height = size.height
    }

    return result
  }

  class func sanitizeFileNameString(_ fileName: String) -> String {
    let illegalFileNameCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>")
    return fileName.components(separatedBy: illegalFileNameCharacters).joined(separator: "")
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
      vc?.navigationController?.toolbar.setBackgroundImage(
        nil, forToolbarPosition: .any, barMetrics: .default)
      return
    }
    //}

    bgView?.isHidden = false
    vc?.view.backgroundColor = .clear
    let img2 = rTracker_resource.get_background_image(vc)
    vc?.navigationController?.view.backgroundColor = rTracker_resource.get_background_color(vc)  // [UIColor colorWithPatternImage:img2];
    vc?.navigationController?.navigationBar.setBackgroundImage(img2, for: .default)
    vc?.navigationController?.toolbar.setBackgroundImage(
      img2, forToolbarPosition: .any, barMetrics: .default)
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

  // MARK: - Help System Functions

  /// Creates a modern info button for help
  class func createHelpInfoButton(target: Any?, action: Selector, accId: String) -> UIBarButtonItem {
    let button = UIButton(type: .infoDark)
    button.addTarget(target, action: action, for: .touchUpInside)
    button.accessibilityIdentifier = accId

    let buttonItem = UIBarButtonItem(customView: button)
    buttonItem.accessibilityIdentifier = accId
    if #available(iOS 26.0, *) {
      buttonItem.hidesSharedBackground = true
    }
    return buttonItem
  }

  /// Creates a help button with custom text
  class func createHelpButton(title: String, target: Any?, action: Selector, accId: String) -> UIBarButtonItem {
    let buttonItem = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
    buttonItem.accessibilityIdentifier = accId
    if #available(iOS 26.0, *) {
      buttonItem.hidesSharedBackground = true
    }
    return buttonItem
  }

  /// Generic button creation function for iOS 26 styled buttons
  class func createStyledButton(
    symbolName: String,
    target: Any?,
    action: Selector,
    accId: String,
    backgroundColor: UIColor = .systemBackground,
    symbolColor: UIColor = .label,
    borderColor: UIColor? = nil,
    borderWidth: CGFloat = 0,
    symbolSize: CGFloat = 22,
    fallbackSystemItem: UIBarButtonItem.SystemItem? = nil,
    fallbackTitle: String? = nil,
    legacyImageName: String? = nil
  ) -> UIBarButtonItem {
    if #available(iOS 26.0, *) {
      let button = UIButton(type: .system)

      var config = UIButton.Configuration.filled()
      config.baseBackgroundColor = backgroundColor
      config.cornerStyle = .capsule

      let symSize = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .regular)
      let image = UIImage(systemName: symbolName)?
        .applyingSymbolConfiguration(symSize)?
        .withTintColor(symbolColor, renderingMode: .alwaysOriginal)

      config.image = image
      button.configuration = config

      if let borderColor = borderColor, borderWidth > 0 {
        button.layer.borderWidth = borderWidth
        button.layer.borderColor = borderColor.cgColor
      }

      button.addTarget(target, action: action, for: .touchUpInside)
      button.accessibilityIdentifier = accId

      let buttonItem = UIBarButtonItem(customView: button)
      buttonItem.accessibilityIdentifier = accId
      buttonItem.hidesSharedBackground = true
      return buttonItem
    } else {
      // Pre-iOS 26: Use fallbacks

      // First check for legacy bespoke image (e.g., privacy button PNGs)
      if let imageName = legacyImageName {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: imageName), for: .normal)
        button.frame = CGRect(x: 0, y: 0,
                             width: (button.currentImage?.size.width ?? 0.0) * 1.5,
                             height: button.currentImage?.size.height ?? 0.0)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = accId
        let buttonItem = UIBarButtonItem(customView: button)
        buttonItem.accessibilityIdentifier = accId
        return buttonItem
      }

      // Otherwise use systemItem or title fallbacks
      let buttonItem: UIBarButtonItem
      if let systemItem = fallbackSystemItem {
        buttonItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: target, action: action)
      } else if let title = fallbackTitle {
        buttonItem = UIBarButtonItem(title: title, style: .plain, target: target, action: action)
      } else {
        // Default fallback
        buttonItem = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
      }
      buttonItem.accessibilityIdentifier = accId
      return buttonItem
    }
  }

  // MARK: - Privacy Screen Button Functions (consolidated)
  // Note: Privacy buttons now use createActionButton or createNavigationButton

  /// Creates a modern iOS 26 cancel button with X circle
  class func createCancelButton(target: Any?, action: Selector, accId: String) -> UIBarButtonItem {
    return createStyledButton(
      symbolName: "xmark.circle",
      target: target,
      action: action,
      accId: accId,
      fallbackTitle: "Cancel"
    )
  }

  // MARK: - UseTrackerController Button Functions (consolidated)
  // Note: UseTracker buttons now use createActionButton with specific symbols and colors

  /// Creates a modern iOS 26 done button - yellow checkmark for primary saves, blue for secondary
  class func createDoneButton(target: Any?, action: Selector, accId: String, preferYellow: Bool = true, symbolSize: CGFloat = 22) -> UIBarButtonItem {
    if preferYellow {
      // Primary save action - use yellow checkmark like createSaveButton
      let burntYellow = UIColor(red: 0.85, green: 0.7, blue: 0.05, alpha: 1.0)
      let yellowTintedWhite = UIColor(red: 1.0, green: 1.0, blue: 0.2, alpha: 1.0)

      return createStyledButton(
        symbolName: "checkmark",
        target: target,
        action: action,
        accId: accId,
        backgroundColor: burntYellow,
        symbolColor: yellowTintedWhite,
        borderColor: yellowTintedWhite,
        borderWidth: 1.0,
        symbolSize: symbolSize,
        fallbackSystemItem: .save
      )
    } else {
      // Secondary done action - blue checkmark circle
      return createStyledButton(
        symbolName: "checkmark.circle.fill",
        target: target,
        action: action,
        accId: accId,
        symbolColor: .systemBlue,
        symbolSize: symbolSize,
        fallbackSystemItem: .done
      )
    }
  }

  // NOTE: createMinusButton can now be replaced with:
  // createActionButton(target: target, action: action, symbolName: "minus.forwardslash.plus", symbolSize: 16, fallbackTitle: "±")

  // MARK: - Consolidated Core Button Functions

  /// Generic action button - replaces most specific button functions
  class func createActionButton(
    target: Any?,
    action: Selector,
    symbolName: String,
    accId: String,
    tintColor: UIColor = .label,
    symbolSize: CGFloat = 22,
    fallbackSystemItem: UIBarButtonItem.SystemItem? = nil,
    fallbackTitle: String? = nil
  ) -> UIBarButtonItem {
    return createStyledButton(
      symbolName: symbolName,
      target: target,
      action: action,
      accId: accId,
      symbolColor: tintColor,
      symbolSize: symbolSize,
      fallbackSystemItem: fallbackSystemItem,
      fallbackTitle: fallbackTitle
    )
  }

  /// Navigation button for all chevron-based navigation
  class func createNavigationButton(
    target: Any?,
    action: Selector,
    direction: NavigationDirection,
    accId: String,
    style: NavigationStyle = .plain
  ) -> UIBarButtonItem {
    let symbolName: String
    let fallbackTitle: String

    switch (direction, style) {
    case (.left, .plain):
      symbolName = "chevron.left"
      fallbackTitle = "<"
    case (.left, .circle):
      symbolName = "chevron.left.circle"
      fallbackTitle = "<"
    case (.right, .plain):
      symbolName = "chevron.right"
      fallbackTitle = ">"
    case (.right, .circle):
      symbolName = "chevron.right.circle"
      fallbackTitle = ">"
    }

    return createStyledButton(
      symbolName: symbolName,
      target: target,
      action: action,
      accId: accId,
      fallbackTitle: fallbackTitle
    )
  }

  enum NavigationDirection {
    case left
    case right
  }

  enum NavigationStyle {
    case plain
    case circle
  }

  /// Creates a settings/configuration button with gear icon
  class func createSettingsButton(target: Any?, action: Selector, accId: String) -> UIBarButtonItem {
    return createActionButton(
      target: target,
      action: action,
      symbolName: settingsIcon,
      accId: accId,
      fallbackSystemItem: .edit
    )
  }

  /// Creates an Apple Health status button with dynamic SF symbol based on HealthKit configuration state
  /// - Parameters:
  ///   - target: The target object for the button action
  ///   - action: The selector to call when button is tapped
  ///   - accId: Accessibility identifier for the button
  ///   - skipAsyncUpdate: If true, skip the async authorization check (default: false)
  /// - Returns: UIBarButtonItem with appropriate heart symbol state:
  ///   - "heart" (outline, red): Not configured or all hidden
  ///   - "heart.fill" (red): All sources enabled
  ///   - "arrow.trianglehead.clockwise.heart" (red): Some not authorized or no data
  class func createHealthButton(target: Any?, action: Selector, accId: String, skipAsyncUpdate: Bool = false) -> UIBarButtonItem {
    // Query database for HealthKit configuration status
    let tl = trackerList.shared
    let sql = "SELECT disabled FROM rthealthkit"
    let statuses = tl.toQry2AryI(sql: sql)

    func symbolFromStatuses(_ statuses: [Int]) -> String {
        // determine symbol based on db statuses
        // For read access, we cannot distinguish between 'not authorized' and 'no data'
        // So we only show: heart (nothing has data) or heart.fill (something has data)

        if statuses.isEmpty {
            return "heart"  // No HealthKit setup
        }

        let active = statuses.filter { $0 != 4 }  // Exclude hidden items

        if active.isEmpty {
            return "heart"  // All items are hidden
        }

        if active.contains(1) {
            return healthKitIcon  // At least one item has readable data (status 1)
        } else {
            return "heart"  // No items have data (all are status 2 or 3)
        }
    }

    let originalSymbol = symbolFromStatuses(statuses)
    DBGLog("createHealthButton: originalSymbol = \(originalSymbol), statuses = \(statuses)", color: .CYAN)

    let healthButton = createActionButton(
        target: target,
        action: action,
        symbolName: originalSymbol,
        accId: accId,
        tintColor: .systemRed,
        fallbackTitle: "❤️"
    )
    // now have db info based button ready for return

    // start a new thread to update it if healthkit authorisations have changed
    // (unless skipAsyncUpdate is true, which means we're refreshing after user interaction)
    if !skipAsyncUpdate {
      DispatchQueue.global(qos: .utility).async {
        let rthk = rtHealthKit.shared
        DBGLog("createHealthButton: Starting async updateAuthorisations", color: .CYAN)
        rthk.updateAuthorisations {
            // Re-read DB (after update) and compute new symbol
            let refreshed = tl.toQry2AryI(sql: sql)
            let newSymbol = symbolFromStatuses(refreshed)
            DBGLog("createHealthButton: After updateAuthorisations - originalSymbol=\(originalSymbol), newSymbol=\(newSymbol), refreshed statuses = \(refreshed)", color: .CYAN)

            guard newSymbol != originalSymbol else {
                DBGLog("createHealthButton: No change, skipping update", color: .CYAN)
                return
            }

            let fallbackTitle = (newSymbol == healthKitIcon ? "❤️" : "💔")
            DBGLog("healthkit access has changed, updating button to \(newSymbol) fallback \(fallbackTitle)", color: .ORANGE)

            DispatchQueue.main.async {
                DBGLog("createHealthButton: In main.async, attempting to update button icon to \(newSymbol)", color: .ORANGE)
                // healthbutton is a uibarbuttonitem with customview of uibutton
                if let btn = healthButton.customView as? UIButton {
                    DBGLog("createHealthButton: Found button, checking iOS version", color: .ORANGE)
                    if #available(iOS 26.0, *) {
                        DBGLog("createHealthButton: iOS 26+, using configuration update", color: .ORANGE)
                        // use configuration update
                        var config = btn.configuration
                        let symSize = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
                        let img = UIImage(systemName: newSymbol)?
                            .applyingSymbolConfiguration(symSize)?
                            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
                        config?.image = img
                        btn.configuration = config
                        DBGLog("createHealthButton: Configuration updated", color: .ORANGE)
                    } else {
                        DBGLog("createHealthButton: Pre-iOS 26, using fallback title update", color: .ORANGE)
                        // Pre-iOS26 fallback: update title
                        btn.setTitle(fallbackTitle, for: .normal)
                        btn.setImage(nil, for: .normal)
                        DBGLog("createHealthButton: Title/image updated", color: .ORANGE)
                    }
                } else {
                    DBGLog("createHealthButton: ERROR - customView is not UIButton!", color: .RED)
                }
            }
        }
      }
    } else {
      DBGLog("createHealthButton: Skipping async update (skipAsyncUpdate=true)", color: .CYAN)
    }

    // return the button which will update async if needed
    return healthButton
  }

  /// Shows help content in a popover or modal presentation
  class func showHelp(
    title: String, content: String, from sourceView: UIView?, in viewController: UIViewController,
    sourceRect: CGRect? = nil
  ) {

    let alertController = UIAlertController(title: title, message: content, preferredStyle: .alert)

    // For iPad, use popover presentation if source view is provided
    if let sourceView = sourceView, UIDevice.current.userInterfaceIdiom == .pad {
      alertController.modalPresentationStyle = .popover
      if let popover = alertController.popoverPresentationController {
        popover.sourceView = sourceView
        popover.sourceRect = sourceRect ?? sourceView.bounds
        popover.permittedArrowDirections = .any
      }
    }

    alertController.addAction(UIAlertAction(title: "OK", style: .default))
    viewController.present(alertController, animated: true)
  }

  /// Shows help content with attributed string formatting
  class func showHelpWithAttributedContent(
    title: String, content: NSAttributedString, from sourceView: UIView?,
    in viewController: UIViewController, sourceRect: CGRect? = nil
  ) {

    let alertController = UIAlertController(title: title, message: "", preferredStyle: .alert)

    // Set the attributed message
    alertController.setValue(content, forKey: "attributedMessage")

    // For iPad, use popover presentation if source view is provided
    if let sourceView = sourceView, UIDevice.current.userInterfaceIdiom == .pad {
      alertController.modalPresentationStyle = .popover
      if let popover = alertController.popoverPresentationController {
        popover.sourceView = sourceView
        popover.sourceRect = sourceRect ?? sourceView.bounds
        popover.permittedArrowDirections = .any
      }
    }

    alertController.addAction(UIAlertAction(title: "OK", style: .default))
    viewController.present(alertController, animated: true)
  }

  /// Shows guidance alert for enabling HealthKit access
  class func showHealthEnableGuidance(from viewController: UIViewController) {
    let alert = UIAlertController(
      title: "Enable Health Access",
      message: "If you tapped \"Don't Allow\", you can still enable access to your health data:\n\n1. Open the Apple Health app\n2. Tap your profile picture (top right)\n3. Tap Apps → rTracker\n4. Tap 'Turn On All'",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    viewController.present(alert, animated: true)
  }

  /// Shows contextual help composed from multiple documentation entries
  class func showContextualHelp(
    identifiers: [String], from sourceView: UIView?, in viewController: UIViewController,
    sourceRect: CGRect? = nil
  ) {

    let entries = rtDocs.shared.getEntries(identifiers)
    guard !entries.isEmpty else {
      showHelp(
        title: "Help", content: "No documentation available", from: sourceView, in: viewController,
        sourceRect: sourceRect)
      return
    }

    let title: String

    if entries.count == 1 {
      let entry = entries[0]
      title = entry.title
      showHelp(
        title: title, content: entry.description, from: sourceView, in: viewController,
        sourceRect: sourceRect)
    } else {
      // Use first entry's title as the main title
      title = entries[0].title

      // Create attributed string with proper bold formatting
      let attributedContent = NSMutableAttributedString()
      var shownEntries = Set<String>()

      for (index, entry) in entries.enumerated() {
        // Skip duplicates for second and subsequent entries
        if shownEntries.contains(entry.identifier) {
          continue
        }

        // Track this entry as shown
        shownEntries.insert(entry.identifier)

        if index > 0 {
          // Add spacing between sections
          attributedContent.append(NSAttributedString(string: "\n\n"))
        }

        if index == 0 {
          // First entry: no bold title, just description
          attributedContent.append(NSAttributedString(string: entry.description))
        } else {
          // Subsequent entries: bold title + description
          let boldTitle = NSAttributedString(
            string: entry.title + "\n",
            attributes: [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize + 3)]
          )
          attributedContent.append(boldTitle)
          //attributedContent.append(NSAttributedString(string: "\n"))
          attributedContent.append(NSAttributedString(string: entry.description))
        }
      }

      showHelpWithAttributedContent(
        title: title, content: attributedContent, from: sourceView, in: viewController,
        sourceRect: sourceRect)
    }
  }

  /// Shows help content for a single documentation entry
  class func showFormattedHelp(
    docEntry: rtDocEntry, from sourceView: UIView?, in viewController: UIViewController,
    sourceRect: CGRect? = nil
  ) {

    showHelp(
      title: docEntry.title, content: docEntry.description, from: sourceView, in: viewController,
      sourceRect: sourceRect)
  }

} // end of class rTracker_resource


// MARK: - UIBarButtonItem Extension when need UIButton access

extension UIBarButtonItem {
  /// Returns the underlying UIButton from customView for privacy views that need direct UIButton access
  var uiButton: UIButton? {
    return self.customView as? UIButton
  }
}
