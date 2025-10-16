//
//  rTrackerSceneDelegate.swift
//  rTracker
//
//  Created for Scene-based lifecycle adoption
//

import UIKit

class rTrackerSceneDelegate: NSObject, UIWindowSceneDelegate {

    var window: UIWindow?
    private var privacyScreenViewController: UIViewController?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Get the app delegate to access shared properties
        guard let appDelegate = UIApplication.shared.delegate as? rTrackerAppDelegate else { return }
        
        // Create window
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .systemBackground
        
        // Create root view controller and navigation controller
        let rootViewController = RootViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        
        // Set up the window
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        // Store references in app delegate for compatibility
        appDelegate.window = window
        appDelegate.navigationController = navigationController
        
        // Handle any launch URLs
        if let urlContext = connectionOptions.urlContexts.first {
            handleIncomingURL(urlContext.url)
        }
        
        // Handle shortcut items
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
        
        // Handle license acceptance and notifications after UI is set up
        DispatchQueue.main.async {
            self.handleInitialSettings(rootViewController: rootViewController, appDelegate: appDelegate)
            self.handleLicenseAcceptance(rootViewController: rootViewController, appDelegate: appDelegate)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        handleIncomingURL(urlContext.url)
    }
    
    private func handleIncomingURL(_ url: URL) {
        DBGLog("Received file via scene: \(url.lastPathComponent)")
        
        guard url.startAccessingSecurityScopedResource() else {
            DBGLog("Cannot access security scoped resource")
            return
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
            
            // Get the root view controller
            if let navController = window?.rootViewController as? UINavigationController,
               let rootVC = navController.viewControllers.first as? RootViewController {
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async {
                    rootVC.loadInputFiles()
                }
            }
        } catch {
            DBGErr("Error handling incoming file in scene: \(error.localizedDescription)")
        }
    }
    
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if let tidString = shortcutItem.userInfo?["tid"] as? String, 
           let tid = Int(tidString),
           let navController = window?.rootViewController as? UINavigationController,
           let rootController = navController.viewControllers.first as? RootViewController {
            rootController.doOpenTracker(tid)
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Unhide screen, rvc enterForeground refreshes the view
        DBGLog("will enter foreground - sceneDelegate")

        // Only dismiss the privacy screen, not all presented view controllers
        if let privacyScreen = privacyScreenViewController {
            privacyScreen.dismiss(animated: false, completion: nil)
            privacyScreenViewController = nil
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // hide screen in case private
        DBGLog("did enter background - sceneDelegate")

        let blankViewController = UIViewController()
        blankViewController.view.backgroundColor = UIColor.black
        blankViewController.modalPresentationStyle = .fullScreen

        // Assuming your launch image is named "LaunchScreenImg" in the asset catalog
        if let launchImage = UIImage(named: "LaunchScreenImg") {
            let imageView = UIImageView(frame: blankViewController.view.bounds)
            imageView.image = launchImage
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            blankViewController.view.addSubview(imageView)
            blankViewController.view.sendSubviewToBack(imageView)
        }

        // Store reference to privacy screen for targeted dismissal
        privacyScreenViewController = blankViewController
        window?.rootViewController?.present(blankViewController, animated: false, completion: nil)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Delegate to app delegate's logic
        if let appDelegate = UIApplication.shared.delegate as? rTrackerAppDelegate {
            appDelegate.applicationWillResignActive(UIApplication.shared)
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // update arrows on reminded trackers if needed
        NotificationCenter.default.post(name: .notifyOpenTrackerInApp, object: nil, userInfo: nil)
    }
    
    private func handleInitialSettings(rootViewController: RootViewController, appDelegate: rTrackerAppDelegate) {
        let sud = UserDefaults.standard
        
        if nil == sud.object(forKey: "reload_sample_trackers_pref") {
            rootViewController.initialPrefsLoad = true
            
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
    }
    
    private func checkAndShowBackupRequester(rootViewController: RootViewController, completion: (() -> Void)? = nil) {
        DBGLog("=== BACKUP REQUESTER CHECK ===")
        let sud = UserDefaults.standard
        let toldAboutSwipe = sud.bool(forKey: "toldAboutSwipe")
        let toldToBackup = sud.bool(forKey: "toldToBackup")
        let hasSignificantData = rootViewController.hasSignificantUserData()

        DBGLog("toldAboutSwipe = \(toldAboutSwipe)")
        DBGLog("toldToBackup = \(toldToBackup)")
        DBGLog("hasSignificantUserData = \(hasSignificantData)")
        DBGLog("Condition for backup requester: \(toldAboutSwipe) && !\(toldToBackup) && \(hasSignificantData) = \(toldAboutSwipe && !toldToBackup && hasSignificantData)")

        // Check if user has significant data worth backing up
        if toldAboutSwipe && !toldToBackup && hasSignificantData {
            DBGLog("=== SHOWING BACKUP REQUESTER ===")
            // Existing user with significant data who hasn't been told to backup
            // This only happens for users who never saw welcome sheet (upgrading from old version)

            // If user has custom trackers, mark as having seen welcome sheet
            if !rootViewController.hasOnlyDemoTrackers() {
                rTracker_resource.setShownWelcomeSheet(WELCOME_SHEET_VERSION)
                UserDefaults.standard.set(WELCOME_SHEET_VERSION, forKey: "shownWelcomeSheet")
                UserDefaults.standard.synchronize()
            }

            rootViewController.presentBackupRequester(completion: completion)
        } else {
            // Not showing backup requester, call completion immediately
            if toldAboutSwipe && toldToBackup {
                DBGLog("=== NOT SHOWING BACKUP REQUESTER (already told) ===")
                // Existing user who already backed up or saw welcome sheet
                // Mark as having seen welcome sheet if they have custom trackers
                if !rootViewController.hasOnlyDemoTrackers() {
                    rTracker_resource.setShownWelcomeSheet(WELCOME_SHEET_VERSION)
                    UserDefaults.standard.set(WELCOME_SHEET_VERSION, forKey: "shownWelcomeSheet")
                    UserDefaults.standard.synchronize()
                }
            } else {
                DBGLog("=== NOT SHOWING BACKUP REQUESTER ===")
                if !toldAboutSwipe {
                    DBGLog("Reason: Not yet told about swipe (user hasn't opened a tracker)")
                }
                if toldToBackup {
                    DBGLog("Reason: Already told to backup")
                }
                if !hasSignificantData {
                    DBGLog("Reason: No significant data to backup")
                }
            }
            // Call completion immediately since we're not showing anything
            completion?()
        }
    }

    private func handleLicenseAcceptance(rootViewController: RootViewController, appDelegate: rTrackerAppDelegate) {
        let sud = UserDefaults.standard
        if !sud.bool(forKey: "acceptLicense") {
            let freeMsg = "Copyright 2010-2025 Robert T. Miller\n\nrTracker is free and open source software, distributed under the Apache License, Version 2.0.\n\nrTracker is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n\nrTracker source code is available at https://github.com/rob-miller/rTracker-swift\n\nThe full Apache License is available at http://www.apache.org/licenses/LICENSE-2.0"

            let alert = UIAlertController(
                title: "rTracker is free software.",
                message: freeMsg,
                preferredStyle: .alert)

            let defaultAction = UIAlertAction(
                title: "Accept",
                style: .default,
                handler: { [weak self] action in
                    rTracker_resource.setAcceptLicense(true)
                    UserDefaults.standard.set(true, forKey: "acceptLicense")
                    UserDefaults.standard.synchronize()

                    appDelegate.pleaseRegister(forNotifications: rootViewController)

                    // Show backup requester FIRST, then welcome sheet in completion
                    // This ensures sequential presentation without conflicts
                    self?.checkAndShowBackupRequester(rootViewController: rootViewController) {
                        DBGLog("Backup requester dismissed or skipped - checking welcome sheet")

                        // After backup requester is dismissed (or skipped), check welcome sheet
                        let shownVersion = rTracker_resource.getShownWelcomeSheet()
                        let onlyDemos = rootViewController.hasOnlyDemoTrackers()

                        if shownVersion < WELCOME_SHEET_VERSION && onlyDemos {
                            DBGLog("=== CALLING presentWelcomeSheet() after backup requester ===")
                            rootViewController.presentWelcomeSheet()
                        } else {
                            DBGLog("Welcome sheet not needed")
                        }
                    }
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
        } else {
            // License already accepted - check if we need to show messages to existing users
            checkAndShowBackupRequester(rootViewController: rootViewController)
        }
    }
}
