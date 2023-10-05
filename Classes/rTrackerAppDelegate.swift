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

    // MARK: -
    // MARK: Application lifecycle

    /*
    - (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
        [application registerForRemoteNotifications];
    }
    */
    func registerForNotifications() {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        center.requestAuthorization(
            options: options) { granted, error in
                // don't care if not granted
                //if (!granted) {
                //    DBGLog(@"notification authorization not granted");
                //}
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
                            //newMaintainer()
                        })

                    alert.addAction(defaultAction)
                    //rootController?.navigationController?.present(alert, animated: true)
                    rootViewController.present(alert, animated: true)
                }
            }


            //[rTracker_resource alert:@"" msg:@"Authorise notifications to use tracker reminders." vc:rootController];
        }

    }

    func newMaintainer() {
        let sud = UserDefaults.standard
        if !sud.bool(forKey: "maintainerRqst") {
            // if not yet told
            //let rootController = (navigationController.viewControllers)[0] as? RootViewController
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = windowScene!.windows.first
            let rootViewController = window!.rootViewController!
            let alert = UIAlertController(
                title: "rTracker is 10!",
                message: "rTracker is 10 years old and needs a new maintainer.",
                preferredStyle: .alert)

            let defaultAction = UIAlertAction(
                title: "OK",
                style: .default,
                handler: { action in
                    rTracker_resource.setMaintainerRqst(true)
                    UserDefaults.standard.set(true, forKey: "maintainerRqst")
                    UserDefaults.standard.synchronize()

                })

            alert.addAction(defaultAction)
            //rootController?.navigationController?.present(alert, animated: true)
            rootViewController.present(alert, animated: true)
        }
    }

    //- (void)applicationDidFinishLaunching:(UIApplication *)application {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {


        #if !RELEASE
        DBGWarn(String("docs dir= \(rTracker_resource.ioFilePath(nil, access: true))"))
        #endif
        let sud = UserDefaults.standard
        sud.synchronize()

        let rootController = (navigationController.viewControllers)[0] as? RootViewController

        if nil == sud.object(forKey: "reload_sample_trackers_pref") {

            //((RootViewController *) [self.navigationController.viewControllers objectAtIndex:0]).initialPrefsLoad = YES;
            rootController?.initialPrefsLoad = true

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

        //NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
        // docs say app openURL below is called anyway, so don't do here which is only if app not already open
        //
        // if (url != nil && [url isFileURL]) {
        //    [rootController handleOpenFileURL:url];
        //}
        //DBGLog(@"rt app delegate: app did finish launching");

        rTracker_resource.initHasAmPm()

        //if (![rTracker_resource getAcceptLicense]) {

        if !sud.bool(forKey: "acceptLicense") {
            // race relying on rvc having set
            let freeMsg = "Copyright 2010-2023 Robert T. Miller\n\nrTracker is free and open source software, distributed under the Apache License, Version 2.0.\n\nrTracker is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n\nrTracker source code is available at https://github.com/rob-miller/rTracker\n\nThe full Apache License is available at http://www.apache.org/licenses/LICENSE-2.0"

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

            //rootController?.navigationController?.present(alert, animated: true)
            rootViewController.present(alert, animated: true)
        } else {
            //newMaintainer()
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

                [rootController performSelectorOnMainThread:@selector(doOpenTracker:) withObject:(notification.userInfo)[@"tid"] waitUntilDone:NO];
            }
        */

        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("9.0") {
            let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem
            if nil != shortcutItem {
                rootController?.performSelector(onMainThread: #selector(RootViewController.doOpenTracker(_:)), with: (shortcutItem?.userInfo)?["tid"], waitUntilDone: false)
                return false // http://stackoverflow.com/questions/32634024/3d-touch-home-shortcuts-in-obj-c
            }
        }

        return true
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

        //if scanner.scanString(base, into: nil) && scanner.scanString("tid=", into: nil) && scanner.scanInt(&tid) {
            DBGLog("curl=\(urlas) format=\(format) tid=\(tid)")
       
            let tlist = rootController.tlist
            tlist.loadTopLayoutTable()

            if tlist.topLayoutIDs!.contains(tid) {
                rootController.performSelector(onMainThread: #selector(rootController.doOpenTracker(_:)), with: tid, waitUntilDone: false)
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

    /* no longer support responding to notifications / open as url

    - (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

        NSString *bdn = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

        DBGLog(@"openURL %@",url);
        DBGLog(@"bundle id: %@",bdn);

        RootViewController *rootController = (self.navigationController.viewControllers)[0];

        int tid;
        NSString *urlas = [url absoluteString];
        const char *curl = [urlas UTF8String];
        NSString *base = [NSString stringWithFormat:@"%@://",bdn];
        const char *format = [[NSString stringWithFormat:@"%@tid=%%d",base ] UTF8String];

        if (1 == sscanf(curl,format,&tid)) {   // correct match to URL scheme with tid
            DBGLog(@"curl=%s format=%s tid=%d",curl,format,tid);

            trackerList *tlist = rootController.tlist;
            [tlist loadTopLayoutTable];
            if ([tlist.topLayoutIDs containsObject:[NSNumber numberWithInt:tid]]) {
                [rootController performSelectorOnMainThread:@selector(doOpenTracker:) withObject:[NSNumber numberWithInt:tid] waitUntilDone:NO];
            } else {
                [rTracker_resource alert:@"no tracker found" msg:[NSString stringWithFormat:@"No tracker with ID %d found in %@.  Edit the tracker, tap the ⚙, and look in 'database info' for the tracker id.",tid,bdn] vc:rootController];
            }

        } else if ([urlas isEqualToString:base]) {
            // do nothing because rTracker:// should open with default trackerList page
        } else if ([urlas hasPrefix:base] || [urlas hasPrefix:[base lowercaseString]]) { // looks like our URL scheme but some errors
            DBGLog(@"sscanf fail curl=%s format=%s",curl,format);
            [rTracker_resource alert:@"bad URL" msg:[NSString stringWithFormat:@"URL received was %@ but should look like %s",[url absoluteString],format] vc:rootController];
        }

        return YES;

    }


    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        UIViewController *rootController = (self.navigationController.viewControllers)[0];
        if (0 == buttonIndex) {   // do nothing
        } else {                  // go to the pending tracker
            [rootController performSelectorOnMainThread:@selector(doOpenTracker:) withObject:self.pendingTid waitUntilDone:NO];
        }
    }
    */

    /*
    - (void)dismissAlertView:(UIAlertView *)alertView{
        [alertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    */
    func quickAlert(_ title: String?, msg: String?) -> UIAlertController? {
        //DBGLog(@"qalert title: %@ msg: %@",title,msg);
        /* deprecated ios 9.0
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:title message:msg
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:nil];
             [alert show];
             */
        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)

        window?.rootViewController?.present(alert, animated: true)
        return alert
    }

    /*
    @objc func dismiss(_ alertController: UIAlertController?) {
        alertController?.dismiss(
            animated: Bool(true))
    }

    func doQuickAlert(_ title: String?, msg: String?, delay: Int) {
        let alert = UIAlertController(
            title: title,
            message: msg,
            preferredStyle: .alert)
        window?.rootViewController?.present(alert, animated: true)
        perform(#selector(self.dismiss(_:)), with: alert, afterDelay: TimeInterval(delay))

    }
     */
    /*
    - (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {

        //

        DBGLog(@"notification from tid %@",[notification.userInfo objectForKey:@"tid"]);

        if ([application applicationState] == UIApplicationStateActive) {
            DBGLog(@"app is active!");
            [rTracker_resource playSound:notification.soundName];
            [self doQuickAlert:notification.alertAction msg:notification.alertBody delay:2];
        } else {
            RootViewController *rootController = (self.navigationController.viewControllers)[0];
            [rootController performSelectorOnMainThread:@selector(doOpenTracker:) withObject:(notification.userInfo)[@"tid"] waitUntilDone:NO];
        }
      }
    */


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

    func applicationWillResignActive(_ application: UIApplication) {
        resigningActive = true
        // Save data if appropriate
        //DBGLog(@"rt app delegate: app will resign active");
        let rootController = (navigationController.viewControllers)[0]
        let topController = navigationController.viewControllers.last

        _ = (rootController as? RootViewController)?.privacyObj.lockDown() // hiding is handled after startup - viewDidAppear() below
        UIApplication.shared.isIdleTimerDisabled = false

        let rtSelector = NSSelectorFromString("rejectTracker")

        if topController?.responds(to: rtSelector) ?? false {
            // leaving so reject tracker if it is rejectable
            if (((topController as? useTrackerController)?.rejectable) != nil) {
                //[((useTrackerController *) topController) rejectTracker];
                navigationController.popViewController(animated: true)
            }
        }
        //if ([self checkNotificationType:UIUserNotificationTypeBadge]) {  // minimum version is iOS 8 currently (14.iv.2016)
        // iOS >= 10 just silently fail?
        application.applicationIconBadgeNumber = (rootController as? RootViewController)?.pendingNotificationCount() ?? 0
        //}
        //[rTracker_resource disableOrientationData];
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
        // rootViewController needs to possibly load files
        // useTrackerController needs to detect if displaying a private tracker

        //DBGLog(@"rt app delegate: app did become active");

        //[(RootViewController *) [self.navigationController.viewControllers objectAtIndex:0] viewDidAppear:YES];

        //[rTracker_resource enableOrientationData];

        //-newMaintainer()

        //navigationController.visibleViewController?.viewDidAppear(true)

        //navigationController.visibleViewController?.beginAppearanceTransition(true, animated: true)

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

        if let rootController = getRootController() {
            if let tid = shortcutItem.userInfo?["tid"] as? Int {
                rootController.doOpenTracker(tid)
                //rootController.performSelector(onMainThread: #selector(RootViewController.doOpenTracker(_:)), with: NSNumber(value: tid), waitUntilDone: false)
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        } else {
            completionHandler(false)
        }
    }

    func xxapplication(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let rootController = (navigationController.viewControllers)[0] as? RootViewController
        rootController?.performSelector(onMainThread: #selector(RootViewController.doOpenTracker(_:)), with: (shortcutItem.userInfo)?["tid"], waitUntilDone: false)
    }
    // MARK: -
    // MARK: Memory management
}
