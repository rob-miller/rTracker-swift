//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// rTrackerAppDelegate.swift
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
//  rTrackerAppDelegate.swift
//  rTracker
//
//  Created by Robert Miller on 16/03/2010.
//  Copyright Robert T. Miller 2010. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class rTrackerAppDelegate: NSObject, UIApplicationDelegate {
    @IBOutlet var window: UIWindow?
    @IBOutlet var navigationController: UINavigationController!
    var pendingTid: NSNumber?
    var regNotifs: Bool = false

    // MARK: -
    // MARK: Application lifecycle

    func registerForNotifications() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        regNotifs = true
        center.requestAuthorization(
            options: options) { granted, error in
                // don't care if not granted
                //if (!granted) {
                //    DBGLog(@"notification authorization not granted");
                //}
                self.regNotifs = false  // avoid spurious applicationWillTerminate
                rTracker_resource.setNotificationsEnabled()
            }
    }

    func pleaseRegister(forNotifications rootViewController: RootViewController) {
        // ios 8.1 must register for notifications
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("8.0") {
            if !rTracker_resource.getNotificationsEnabled() {


                if !rTracker_resource.getToldAboutNotifications() {
                    // if not yet told

                    let alert = UIAlertController(
                        title: "Authorise notifications",
                        message: "Authorise notifications in the next window to enable tracker reminders.",
                        preferredStyle: .alert)

                    let defaultAction = UIAlertAction(
                        title: "OK",
                        style: .default,
                        handler: { [self] action in
                            registerForNotifications()

                            rTracker_resource.setToldAboutNotifications(true)
                            UserDefaults.standard.set(true, forKey: "toldAboutNotifications")
                            UserDefaults.standard.synchronize()
                        })

                    alert.addAction(defaultAction)
                    rootViewController.present(alert, animated: true)
                }
            }
        }

    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        #if !RELEASE
        DBGWarn(String("docs dir= \(rTracker_resource.ioFilePath(nil, access: true))"))
        #endif
        let sud = UserDefaults.standard
        sud.synchronize()

        let rootController = (navigationController.viewControllers)[0] as! RootViewController

        if nil == sud.object(forKey: "reload_sample_trackers_pref") {

            //((RootViewController *) [self.navigationController.viewControllers objectAtIndex:0]).initialPrefsLoad = YES;
            rootController.initialPrefsLoad = true

            let mainBundlePath = Bundle.main.bundlePath
            let settingsPropertyListPath = URL(fileURLWithPath: mainBundlePath).appendingPathComponent("Settings.bundle/Root.plist").path

            if let settingsPropertyList = NSDictionary(contentsOfFile: settingsPropertyListPath) as? [String: Any] {
                let preferenceArray = settingsPropertyList["PreferenceSpecifiers"] as? [[String : Any]]
                var registerableDictionary: [String : Any] = [:]

                for i in 0..<(preferenceArray?.count ?? 0) {
                    let key = preferenceArray?[i]["Title"] as? String

                    if let key {
                        let value = preferenceArray?[i]["DefaultValue"]
                        if let value {
                            registerableDictionary[key] = value
                        }
                    }
                }

                sud.register(defaults: registerableDictionary)
                sud.synchronize()

            } else {
                DBGLog("unable to open settings dictionary from rRoot.plist file")
            }
        }
        rTracker_resource.setNotificationsEnabled()
        rTracker_resource.setToldAboutNotifications(sud.bool(forKey: "toldAboutNotifications"))

        // Override point for customization after app launch    

        // fix 'Application windows are expected to have a root view controller at the end of application launch'
        //   as found in http://stackoverflow.com/questions/7520971

        //[self.window addSubview:[navigationController view]];

        let rootViewController = RootViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)

        window?.backgroundColor = .systemBackground

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        let prod = Bundle.main.infoDictionary?["CFBundleName"]
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let bld = Bundle.main.infoDictionary?["CFBundleVersion"]
        DBGLog(String("product \(prod!) version \(ver!) build \(bld!)  db_ver \(RTDB_VERSION)  fn_ver \(RTFN_VERSION) samples_ver \(SAMPLES_VERSION) demos_ver \(DEMOS_VERSION)"))

        rTracker_resource.initHasAmPm()

        DispatchQueue.main.async{
            if !sud.bool(forKey: "acceptLicense") {
                // race relying on rvc having set
                let freeMsg = "Copyright 2010-2023 Robert T. Miller\n\nrTracker is free and open source software, distributed under the Apache License, Version 2.0.\n\nrTracker is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n\nrTracker source code is available at https://github.com/rob-miller/rTracker-swift\n\nThe full Apache License is available at http://www.apache.org/licenses/LICENSE-2.0"
                
                let alert = UIAlertController(
                    title: "rTracker is free software.",
                    message: freeMsg,
                    preferredStyle: .alert)
                
                let defaultAction = UIAlertAction(
                    title: "Accept",
                    style: .default,
                    handler: { [self] action in
                        rTracker_resource.setAcceptLicense(true)
                        UserDefaults.standard.set(true, forKey: "acceptLicense")
                        UserDefaults.standard.synchronize()
                        
                        pleaseRegister(forNotifications: rootViewController)
                    })
                
                let recoverAction = UIAlertAction(
                    title: "Reject",
                    style: .default,
                    handler: { action in
                        exit(0)
                    })
                
                alert.addAction(defaultAction)
                alert.addAction(recoverAction)

                rootViewController.present(alert, animated: true)
            }
        }
        

        
        /*
            // for when actually not running, not just in background:
            UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
            if (nil != notification) {
                DBGLog(@"responding to local notification with msg : %@",notification.alertBody);
                //[rTracker_resource alert:@"launched with locNotification" msg:notification.alertBody];
                //NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
                //[sud synchronize];
                [rTracker_resource setToldAboutSwipe:[sud boolForKey:@"toldAboutSwipe"]];

                [rootController performSelectorOnMainThread:@selector(doOpenTrackerOC:) withObject:(notification.userInfo)[@"tid"] waitUntilDone:NO];
            }
        */

        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            if let tidString = shortcutItem.userInfo?["tid"] as? String, let tid = Int(tidString) {
                rootController.doOpenTracker(tid)
                return false // http://stackoverflow.com/questions/32634024/3d-touch-home-shortcuts-in-obj-c
                // When you return a value of NO, the system does not call the application:performActionForShortcutItem:completionHandler: method.
            }
        }

        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
       guard let bdn = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String else { return false }
       
       DBGLog("openURL \(url)")
       DBGLog("bundle id: \(bdn)")
       
       guard let rootController = getRootController() else {
           return false
       }
       
        var tid: Int = 0
        let urlas = url.absoluteString
        //let curl = urlas.cString(using: .utf8)
        let base = "\(bdn)://"
        let format = "\(base)tid=%d"
        let scanner = Scanner(string: urlas)
        let _ = scanner.scanUpToString("tid=")

        if !scanner.isAtEnd {
            scanner.currentIndex = scanner.string.index(scanner.currentIndex, offsetBy: "tid=".count)
        }

        // Finally, scan the integer value
        if scanner.scanInt(&tid) {
            DBGLog("curl=\(urlas) format=\(format) tid=\(tid)")
       
            let tlist = rootController.tlist
            tlist.loadTopLayoutTable()

            if tlist.topLayoutIDs.contains(tid) {
                rootController.doOpenTracker(tid)
            } else {
                rTracker_resource.alert("no tracker found", msg: "No tracker with ID \(tid) found in \(bdn).  Edit the tracker, tap the ⚙, and look in 'database info' for the tracker id.", vc: rootController)
            }
           
        } else if urlas == base {
            // do nothing because rTracker:// should open with default trackerList page
        } else if urlas.hasPrefix(base) || urlas.hasPrefix(base.lowercased()) {
            DBGLog("sscanf fail curl=\(urlas) format=\(format)")
            rTracker_resource.alert("bad URL", msg: "URL received was \(url.absoluteString) but should look like \(format)", vc: rootController)
        }
       
        return true
    }

    func quickAlert(_ title: String?, msg: String?) -> UIAlertController? {
        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)

        window?.rootViewController?.present(alert, animated: true)
        return alert
    }

    @objc func applicationWillTerminate(_ application: UIApplication) {
        // Save data if appropriate
        //DBGLog(@"rt app delegate: app will terminate");
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    /*
     // UIUserNotification deprecated iOS 10, see if we can just proceed without checking and silently fail?

    - (BOOL)checkNotificationTypeX:(UIUserNotificationType)type
    {
        UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];

        return (currentSettings.types & type);
    }

    - (BOOL)checkNotificationType:(UNAuthorizationOptions)type
    {
        BOOL retval = FALSE;
        // https://useyourloaf.com/blog/local-notifications-with-ios-10
        UNUserNotificationCenter *uncenter = [UNUserNotificationCenter currentNotificationCenter];
        [uncenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
          if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
            // Notifications not allowed
          }
        }];
        //[uncenter getNotificationSettingsWithCompletionHandler:(^{

        //})]
        UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        //[UNUserNotificationCenter getNotificationSettingsWithCompletionHandler:] and -[UNUserNotificationCenter getNotificationCategoriesWithCompletionHandler:]
        return (currentSettings.types & type);
    }
    */
    
    ///*
     // needs notification set above, still called after applicationWillResignActive()
    @objc func appWillEnterBackground() {
        // hide screen in case private
        DBGLog("will enter background - appDelegate")

        let blankViewController = UIViewController()
        blankViewController.view.backgroundColor = UIColor.black
        blankViewController.modalPresentationStyle = .fullScreen

        // Assuming your launch image is named "LaunchImage" in the asset catalog
        if let launchImage = UIImage(named: "LaunchScreenImg") {
            let imageView = UIImageView(frame: blankViewController.view.bounds)
            imageView.image = launchImage
            imageView.contentMode = .scaleAspectFill // Adjust as needed
            imageView.clipsToBounds = true

            // Add the image view as a subview
            blankViewController.view.addSubview(imageView)
            blankViewController.view.sendSubviewToBack(imageView) // Ensure it's behind any other views
        }
        
         let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
         let window = windowScene!.windows.first
         let rootViewController = window!.rootViewController!
         rootViewController.present(blankViewController, animated: false, completion: nil)
    }


    @objc func appWillEnterForeground() {
        // Unhide screen, rvc enterForeground refreshes the view
        DBGLog("will enter foreground - appdelegate")
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene!.windows.first
        let rootViewController = window!.rootViewController!
        rootViewController.dismiss(animated: false, completion: nil)
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        if regNotifs {
            return  // spurious event when registering for notifications
        }
        resigningActive = true
        // Save data if appropriate
        //DBGLog(@"rt app delegate: app will resign active");
        let rootController = (navigationController.viewControllers)[0]
        let topController = navigationController.viewControllers.last

        
        //DispatchQueue.main.async(execute: {
            _ = (rootController as? RootViewController)?.privacyObj.lockDown() // hiding is handled after startup - viewDidAppear() below
           // (rootController as? RootViewController)?.tableView?.reloadData()
        //})
        
        UIApplication.shared.isIdleTimerDisabled = false

        let rtSelector = NSSelectorFromString("rejectTracker")

        if topController?.responds(to: rtSelector) ?? false {
            // leaving so reject tracker if it is rejectable
            if (((topController as? useTrackerController)?.rejectable) != nil) {
                //[((useTrackerController *) topController) rejectTracker];
                navigationController.popViewController(animated: true)
            }
        }

        application.applicationIconBadgeNumber = (rootController as? RootViewController)?.pendingNotificationCount() ?? 0

        resigningActive = false
    }

    /*
    // does not make utc disappear before first visible
     - (void) applicationWillBecomeActive:(UIApplication *)application {
    	DBGLog(@"rt app delegate: app will become active");
        [self.navigationController.visibleViewController viewWillAppear:YES];
    }
    */

    /*
    - (void)applicationWillEnterForeground:(UIApplication *)application {
    }
    */

    func applicationDidBecomeActive(_ application: UIApplication) {
        // update arrows on reminded trackers if needed
        NotificationCenter.default.post(name: .notifyOpenTrackerInApp, object: nil, userInfo: nil)
    }
    
    func getRootController() -> RootViewController? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let navController = windowScene.windows.first!.rootViewController as? UINavigationController,
               let rootController = navController.viewControllers.first as? RootViewController {
                return rootController
            }
        }
        return nil
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // don't think this ever gets called with handler in didFinishLaunching
        if let rootController = getRootController() {
            if let tid = shortcutItem.userInfo?["tid"] as? Int {
                rootController.doOpenTracker(tid)
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        } else {
            completionHandler(false)
        }
    }
}
