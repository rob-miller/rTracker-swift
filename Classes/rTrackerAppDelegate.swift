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

    let rtr = rTracker_resource.shared
    
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
                let freeMsg = "Copyright 2010-2025 Robert T. Miller\n\nrTracker is free and open source software, distributed under the Apache License, Version 2.0.\n\nrTracker is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n\nrTracker source code is available at https://github.com/rob-miller/rTracker-swift\n\nThe full Apache License is available at http://www.apache.org/licenses/LICENSE-2.0"
                
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
        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            // Make sure to release the security-scoped resource when done
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
            
            // Remove any existing file
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Read the data directly instead of trying to copy the file
            let data = try Data(contentsOf: url)
            
            // Write to your app's documents directory
            try data.write(to: destinationURL)
            
            DBGLog("File successfully saved to: \(destinationURL.path)")
            
            // Get the root view controller
            var rootVC: RootViewController?
            
            if #available(iOS 15.0, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let viewController = window.rootViewController as? RootViewController {
                    rootVC = viewController
                }
            } else {
                if let viewController = UIApplication.shared.windows.first?.rootViewController as? RootViewController {
                    rootVC = viewController
                }
            }
            
            // Trigger file loading
            rootVC?.loadInputFiles()
            
            return true
        } catch {
            DBGErr("Error handling incoming file: \(error.localizedDescription)")
            return false
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        
        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            // Make sure to release the security-scoped resource when done
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
            
            // Remove any existing file
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Read the data directly instead of trying to copy the file
            let data = try Data(contentsOf: url)
            
            // Write to your app's documents directory
            try data.write(to: destinationURL)
            
            DBGLog("File successfully saved to: \(destinationURL.path)")
            
            // Get the root view controller
            if let windowScene = scene as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController as? RootViewController {
                rootVC.loadInputFiles()
            }
        } catch {
            DBGErr("Error handling incoming file in scene: \(error.localizedDescription)")
        }
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

    func applicationWillResignActive(_ application: UIApplication) {
        if regNotifs {
            return  // spurious event when registering for notifications
        }
        resigningActive = true
        // Save data if appropriate
        //DBGLog(@"rt app delegate: app will resign active");
        let rootController = (navigationController.viewControllers)[0]
        let topController = navigationController.viewControllers.last

        _ = (rootController as? RootViewController)?.privacyObj.lockDown()

        UIApplication.shared.isIdleTimerDisabled = false

        let rtSelector = NSSelectorFromString("rejectTracker")

        if topController?.responds(to: rtSelector) ?? false {
            // leaving so reject tracker if it is rejectable
            if (((topController as? useTrackerController)?.rejectable) != nil) {
                //[((useTrackerController *) topController) rejectTracker];
                navigationController.popViewController(animated: true)
            }
        }

        // Update badge count using new API
        let badgeCount = (rootController as? RootViewController)?.pendingNotificationCount() ?? 0
        UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
            if let error = error {
                DBGLog("Failed to set badge count: \(error.localizedDescription)")
            }
        }

        resigningActive = false
    }

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
}
