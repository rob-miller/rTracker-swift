# rTrackerAppDelegate Analysis Notes

## Purpose & Role
Main application delegate for rTracker iOS app, handling app lifecycle, notifications, URL schemes, and compatibility with both legacy and modern scene-based architectures.

## Key Classes/Structs/Protocols
- rTrackerAppDelegate - Main app delegate class with @main attribute
- Implements UIApplicationDelegate
- Uses UserNotifications framework for local notifications

## Important Methods/Functions
- application(_:didFinishLaunchingWithOptions:) - App initialization and setup
- registerForNotifications() - Sets up local notification permissions
- application(_:handleOpen:) - Processes incoming URL schemes (rTracker://)
- application(_:performActionFor:completionHandler:) - Handles 3D Touch shortcuts
- appWillEnterBackground/appWillEnterForeground - App state transition handling

## Dependencies & Relationships
- Works with rTrackerSceneDelegate for modern iOS 13+ scene management
- Contains compatibility properties (window, navigationController) for legacy code
- Integrates with rTracker_resource for shared app functionality
- Manages pendingTid for URL scheme processing

## Notable Patterns & Conventions
- **Modern App Entry Point**: Uses @main attribute instead of UIApplicationMain()
- **Dual Architecture Support**: Compatible with both legacy and scene-based app lifecycle
- **URL Scheme Handling**: Supports rTracker:// and rTracker://tid=N URLs
- **3D Touch Integration**: Quick actions for tracker access
- **Notification Management**: Local notification setup and permission handling

## Implementation Details
- **App Initialization**: Now uses @main attribute for modern Swift app entry point
- **Legacy Compatibility**: Maintains window and navigationController properties for existing code
- **Scene Integration**: Delegates window creation to rTrackerSceneDelegate for iOS 13+
- **Property Management**:
  - `var window: UIWindow?` (removed @IBOutlet - no longer XIB-connected)
  - `var navigationController: UINavigationController!` (removed @IBOutlet)
  - `var pendingTid: NSNumber?` for URL scheme processing
- **Notification Setup**: Configures UserNotifications framework for tracker reminders

## Current Issues & TODOs
- ✅ RESOLVED: Modernized app entry point with @main attribute
- ✅ RESOLVED: Removed XIB dependencies (@IBOutlet annotations)
- ✅ RESOLVED: Eliminated main.swift file (now uses @main)
- App now uses modern iOS 13+ scene-based architecture exclusively

## Recent Development History
- 2025-09-26: **APP INITIALIZATION MODERNIZATION**
  - **MAJOR**: Added @main attribute to class - now serves as app entry point
  - **Removed @IBOutlet annotations** from window and navigationController properties
  - **Eliminated main.swift dependency** - app uses modern @main pattern
  - **Maintained legacy compatibility** - properties still available for existing code
  - **Clean architecture**: App now uses scene-based lifecycle exclusively via rTrackerSceneDelegate
- 60d8b15: rm main.swift and mainwindow.xib (related to current modernization)
- 7d6b3ab: code cleanup
- 12c495c: initial implementation of help system - fn defn page
- fb2c382: disallow sleep when running devel from vscode
- 8b2955d: update to UIScene (original scene adoption)

## Last Updated
2025-09-26 - App initialization modernization: @main attribute and XIB dependency removal