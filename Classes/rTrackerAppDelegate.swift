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
        UIApplication.shared.isIdleTimerDisabled = true  // prevent sleep when running from vscode (xcode does its own way)
        #endif
        let sud = UserDefaults.standard
        sud.synchronize()

        // Settings initialization will be handled by SceneDelegate after UI setup
        rTracker_resource.setNotificationsEnabled()
        rTracker_resource.setToldAboutNotifications(sud.bool(forKey: "toldAboutNotifications"))

        let prod = Bundle.main.infoDictionary?["CFBundleName"]
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let bld = Bundle.main.infoDictionary?["CFBundleVersion"]
        DBGLog(String("product \(prod!) version \(ver!) build \(bld!)  db_ver \(RTDB_VERSION)  fn_ver \(RTFN_VERSION) samples_ver \(SAMPLES_VERSION) demos_ver \(DEMOS_VERSION)"))

        rTracker_resource.initHasAmPm()

        // License acceptance will be handled in scene delegate after UI is set up

        // Shortcut items will be handled in scene delegate
        // Store shortcut info for scene delegate to access
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            pendingTid = shortcutItem.userInfo?["tid"] as? NSNumber
        }

        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        DBGLog("Received file via AirDrop: \(url.lastPathComponent)")
        /*
        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            // Make sure to release the security-scoped resource when done
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        */
        
        guard url.startAccessingSecurityScopedResource() else {
            DBGLog("Cannot access security scoped resource")
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
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
            
            // Get the root view controller through navigation controller
            var rootVC: RootViewController?
            

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let navController = window.rootViewController as? UINavigationController,
               let viewController = navController.viewControllers.first as? RootViewController {
                rootVC = viewController
            }
            
            // Ensure UI updates happen on main thread after current operation completes
            DispatchQueue.main.async {
                rootVC?.loadInputFiles()
            }
            
            return true
        } catch {
            DBGErr("Error handling incoming file: \(error.localizedDescription)")
            return false
        }
    }
    
    // Scene URL handling moved to SceneDelegate
    
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
        
        // Get root controller through scene if available
        if let rootController = getRootController() {
            _ = rootController.privacyObj.lockDown()
            
            // Update badge count using new API
            let badgeCount = rootController.pendingNotificationCount()
            UNUserNotificationCenter.current().setBadgeCount(badgeCount) { error in
                if let error = error {
                    DBGLog("Failed to set badge count: \(error.localizedDescription)")
                }
            }
            
            // Handle rejectable tracker if needed
            if let navController = window?.rootViewController as? UINavigationController,
               let topController = navController.viewControllers.last {
                let rtSelector = NSSelectorFromString("rejectTracker")
                if topController.responds(to: rtSelector),
                   let trackerController = topController as? useTrackerController,
                   trackerController.rejectable != false {
                    navController.popViewController(animated: true)
                }
            }
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
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
        // App-level background handling - scene-specific UI hiding moved to SceneDelegate
        DBGLog("will enter background - appDelegate")
    }

    @objc func appWillEnterForeground() {
        // App-level foreground handling - scene-specific UI showing moved to SceneDelegate
        DBGLog("will enter foreground - appdelegate")
    }
    
    // MARK: - Scene Session Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = rTrackerSceneDelegate.self
        return config
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
