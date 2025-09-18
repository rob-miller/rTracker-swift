//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// configTlistController.swift
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
//  configTlistController.swift
//  rTracker
//
//  from this screen the user can move, delete, copy, or select for edit (modify) one of the existing trackers
//
//  Created by Robert Miller on 06/05/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

///************
/// configTlistController.swift
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
//  configTlistController.swift
//  rTracker
//
//  Created by Robert Miller on 06/05/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import UIKit
import ZIPFoundation


let SegmentEdit = 0
let SegmentCopy = 1
let SegmentMoveDelete = 2


var selSegNdx = SegmentEdit
    // MARK: -
    // MARK: core object methods and support

class configTlistController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    //@interface configTlistController : UITableViewController
    /*
     {
    	trackerList *tlist;
    }
    */
    var tlist: trackerList?
    // UI element properties 
    @IBOutlet var tableView: UITableView!
    var deleteIndexPath: IndexPath? // remember row to delete if user confirms in checkTrackerDelete alert

    deinit {
        DBGLog("configTlistController dealloc")
    }

    // MARK: -
    // MARK: view support

    
    // Helper to create a ZIP file
    func createZipFile(at zipURL: URL, withFilesMatching pattern: String, in directory: URL) throws {
        // Remove existing ZIP file if it exists
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }

        // Create a ZIP archive with the throwing initializer
        let archive: Archive
        do {
            archive = try Archive(url: zipURL, accessMode: .create)
        } catch {
            throw NSError(domain: "ZIPFoundationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create archive: \(error.localizedDescription)"])
        }

        // Get matching files - filter based on extension pattern to match the actual files created
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { file in
                // Match the extension based on pattern
                if pattern == "*.csv" {
                    return file.pathExtension == "csv" || file.pathExtension == "rtcsv"
                } else if pattern == "*.rtrk" {
                    return file.pathExtension == "rtrk"
                }
                return false
            }
        
        // Log found files for debugging
        DBGLog("Found \(files.count) files matching pattern \(pattern)")
        for file in files {
            DBGLog("Adding to ZIP: \(file.lastPathComponent)")
        }

        // Add files to the ZIP archive
        for file in files {
            try archive.addEntry(with: file.lastPathComponent, fileURL: file)
        }
    }

    
    // Helper to present the file browser
    func presentFileBrowser(for fileURL: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true)
    }
    
    @objc func startExport() {
        autoreleasepool {
            tlist?.exportAll()
            
            safeDispatchSync({ [self] in
                rTracker_resource.finishProgressBar(view, navItem: navigationItem, disable: true)
            })
        }
    }
    
    @objc func startExportZip() {
        guard let tlist = self.tlist else {
            DBGLog("tlist is nil")
            return
        }
        guard let zipOption = self.zipOption,
               zipOption == .shareCsvZip || zipOption == .shareRtrkZip else {
             DBGLog("Invalid or nil zipOption")
             return
        }
        autoreleasepool {
            // this part is tlist?.exportAll()
            var ndx: Float = 1.0
            jumpMaxPriv() // reasonable to do this now with default encryption enabled

            let sql = "select id from toplevel" // ignore current (self) list because subject to privacy
            let idSet = tlist.toQry2AryI(sql: sql)
            let all = Float(idSet.count)

            for tid in idSet {
                let to = trackerObj(tid)
                if zipOption == .shareCsvZip {
                    _ = to.writeTmpCSV()
                } else {
                    _ = to.writeTmpRtrk(true)
                }

                rTracker_resource.setProgressVal(ndx / all)
                ndx += 1.0
            }

            restorePriv()
            
            // this part generates the .zip file
            let fpatho = rTracker_resource.ioFilePath(nil, access: false, tmp: true)
            let fpathu = URL(fileURLWithPath: fpatho)
            try? FileManager.default.createDirectory(atPath: fpatho, withIntermediateDirectories: false, attributes: nil)
            let zipFileName, fpattern: String
            if zipOption == .shareCsvZip {
                zipFileName = "rTracker_exportAllCsv.zip"
                fpattern = "*.csv"
            } else {
                zipFileName = "rTracker_exportAllRtrk.zip"
                fpattern = "*.rtrk"
            }
            
            // Log the temporary directory for debugging
            DBGLog("Temporary directory path: \(fpatho)")
            
            // List files in the directory to verify what's there
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: fpatho)
                DBGLog("Files in temporary directory before ZIP creation: \(contents)")
            } catch {
                DBGLog("Error listing directory contents: \(error.localizedDescription)")
            }

            let zipFileURL = URL(fileURLWithPath: fpatho).appendingPathComponent(zipFileName)
            
            do {
                try createZipFile(at: zipFileURL, withFilesMatching: fpattern, in: fpathu)
                
                // Verify ZIP file size after creation
                let attributes = try FileManager.default.attributesOfItem(atPath: zipFileURL.path)
                let fileSize = attributes[FileAttributeKey.size] as? UInt64 ?? 0
                DBGLog("Zip file created at: \(zipFileURL) with size: \(fileSize) bytes")
            } catch {
                DBGLog("Failed to create zip file: \(error.localizedDescription)")
            }
            
            safeDispatchSync({ [self] in
                rTracker_resource.finishProgressBar(view, navItem: navigationItem, disable: true)
                
                // Present the file browser for sharing
                //presentFileBrowser(for: zipFileURL)
                
                let activityViewController = UIActivityViewController(activityItems: [zipFileURL], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
                    // Ensure temporary files are cleaned up
                    do {
                        // Get the contents of the temp directory
                        let fileURLs = try FileManager.default.contentsOfDirectory(at: fpathu, includingPropertiesForKeys: nil)
                        
                        // Iterate and remove each file
                        for fileURL in fileURLs {
                            try FileManager.default.removeItem(at: fileURL)
                        }
                        
                        DBGLog("All files in the temp directory have been removed.")
                    } catch {
                        DBGLog("Failed to clear temp directory: \(error.localizedDescription)")
                    }
                }
                
                self.present(activityViewController, animated: true)
            })
        }
    }
    
    @objc func btnExport() {

        DBGLog("export all")
        let navframe = navigationController?.navigationBar.frame
        
        rTracker_resource.alert("exporting trackers",
                                msg: "_out.csv and _out.plist files are being saved to the rTracker Documents directory on this device\(rTracker_resource.getRtcsvOutput() ? " in rtCSV format" : "").  Access them through iTunes/Finder on your PC/Mac, or with a program like iExplorer from Macroplant.com.  Import by changing the names to _in.csv and _in.plist, and read about .rtcsv file import capabilities in the help pages.\n\nNote: All private (hidden) data has been saved to output files.",
                                vc: self) 
         
        rTracker_resource.startProgressBar(view, navItem: navigationItem, disable: true, yloc: (navframe?.size.height ?? 0.0) + (navframe?.origin.y ?? 0.0))

        Thread.detachNewThreadSelector(#selector(startExport), toTarget: self, with: nil)
    }

    func doExportZip() {
        DBGLog("export zip")
        let navframe = navigationController?.navigationBar.frame
        rTracker_resource.startProgressBar(view, navItem: navigationItem, disable: true, yloc: (navframe?.size.height ?? 0.0) + (navframe?.origin.y ?? 0.0))

        Thread.detachNewThreadSelector(#selector(startExportZip), toTarget: self, with: nil)
    }
    
    /*
    func getExportFilesBtn() -> UIBarButtonItem? {
        var exportBtn: UIBarButtonItem?
        exportBtn = UIBarButtonItem(
            title: "Export all to app directory",
            style: .plain,
            target: self,
            action: #selector(btnExport))
        if #available(iOS 26.0, *) {
            exportBtn?.hidesSharedBackground = true  // Remove white container background
        }
        
        exportBtn!.accessibilityIdentifier = "exportAll"
        exportBtn!.accessibilityLabel = "Export All"
        exportBtn!.accessibilityHint = "tap to save all trackers in rTracker's Documents folder"
        return exportBtn
    }
     */

      // Menu options
      enum MenuOption: String {
          case exportAll = "Export all to App directory"
          case shareCsvZip = "Share all .csv as .zip file"
          case shareRtrkZip = "Share all .rtrk with data as .zip file"
          case cancel = "Cancel"
      }
    
    var zipOption: MenuOption? = nil
    
    func handleMenuOption(_ option: MenuOption) {
        zipOption = option
        switch option {
        case .exportAll:
            btnExport()
        case .shareCsvZip:
            fallthrough
        case .shareRtrkZip:
            doExportZip()
        case .cancel:
            break
        }
    }
    
    
    
    @objc func btnMenu() {
        let alert = UIAlertController(title: "export all", message: nil, preferredStyle: .actionSheet)
        
        let options: [MenuOption] = [.shareCsvZip, .shareRtrkZip, .exportAll]
        
        
        for option in options {
            let action = UIAlertAction(title: option.rawValue, style: .default) { [self] _ in
                handleMenuOption(option)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: MenuOption.cancel.rawValue, style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    var _menuBtn: UIBarButtonItem?
    var menuBtn: UIBarButtonItem {
        if _menuBtn == nil {
            _menuBtn = UIBarButtonItem(
                barButtonSystemItem: .action,
                target: self,
                action: #selector(btnMenu))
            if #available(iOS 26.0, *) {
                _menuBtn!.hidesSharedBackground = true  // Remove white container background
            }
            
            _menuBtn!.accessibilityLabel = "Share Menu"
            _menuBtn!.accessibilityHint = "tap to show sharing options"
            _menuBtn!.accessibilityIdentifier = "trkrListMenu"
        }
        
        return _menuBtn!
    }
    
    
    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {

        title = "Edit trackers"

        navigationController?.setToolbarHidden(true, animated: false)
        navigationItem.setRightBarButton(menuBtn, animated: false)

        // doesn't work? navigationItem.backBarButtonItem!.accessibilityIdentifier = "configTlistReturn"
        
        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)
        rTracker_resource.setViewMode(self)

        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)
        
        modeSegment.accessibilityIdentifier = "configTlistMode"
        
        // Set accessibility properties for each segment by accessing the individual segments
        if let editSegment = modeSegment.subviews.indices.contains(SegmentEdit) ? modeSegment.subviews[SegmentEdit] : nil {
            editSegment.accessibilityIdentifier = "tlistModify"
            editSegment.accessibilityLabel = "Modify"
            editSegment.accessibilityHint = "select tracker to modify"
        }

        if let copySegment = modeSegment.subviews.indices.contains(SegmentCopy) ? modeSegment.subviews[SegmentCopy] : nil {
            copySegment.accessibilityIdentifier = "tlistCopy"
            copySegment.accessibilityLabel = "Copy"
            copySegment.accessibilityHint = "selected tracker will be duplicated at bottom of list"
        }

        if let moveDeleteSegment = modeSegment.subviews.indices.contains(SegmentMoveDelete) ? modeSegment.subviews[SegmentMoveDelete] : nil {
            moveDeleteSegment.accessibilityIdentifier = "tlistMoveDel"
            moveDeleteSegment.accessibilityLabel = "Move or Delete"
            moveDeleteSegment.accessibilityHint = "re-order or delete trackers"
        }

        super.viewDidLoad()
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        rTracker_resource.setViewMode(self)
        tableView.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    /*
    - (void)viewDidUnload {

    	DBGLog(@"configTlistController view didunload");

    	// Release any retained subviews of the main view.
    	// e.g. self.myOutlet = nil;

    	self.title = nil;
    	self.tlist = nil;
    	self.tableView = nil;
    	self.toolbarItems = nil;

    	[super viewDidLoad];

    }
    */

    override func viewWillAppear(_ animated: Bool) {

        DBGLog("ctlc: viewWillAppear")
        navigationController?.setToolbarHidden(true, animated: false)

        tableView.reloadData()
        selSegNdx = SegmentEdit // because mode select starts with default 'modify' selected

        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        DBGLog("ctlc: viewWillDisappear")

        tlist?.updateShortcutItems()

        //self.tlist = nil;

        super.viewWillDisappear(animated)
    }

    //- (IBAction) btnExport;

    // MARK: -
    // MARK: button press action methods

    @IBOutlet weak var modeSegment: UISegmentedControl!
    
    @IBAction func modeChoice(_ sender: UISegmentedControl) {
        selSegNdx = sender.selectedSegmentIndex
        switch selSegNdx {
        case SegmentEdit:
            //DBGLog(@"ctlc: set edit mode");
            tableView.setEditing(false, animated: true)
        case SegmentCopy:
            //DBGLog(@"ctlc: set copy mode");
            tableView.setEditing(false, animated: true)
        case SegmentMoveDelete:
            //DBGLog(@"ctlc: set move/delete mode");
            tableView.setEditing(true, animated: true)
        default:
            dbgNSAssert(false, "ctlc: segment index not handled")
        }
    }

    // MARK: -
    // MARK: delete tracker options methods

    func delTracker() {
        let row = deleteIndexPath?.row ?? 0
        DBGLog(String("checkTrackerDelete: will delete row \(UInt(row)) "))
        tlist?.deleteTrackerAllRow(row)
        tableView.deleteRows(
            at: [deleteIndexPath].compactMap { $0 },
            with: .fade)
        tlist?.reloadFromTLT()
    }

    func delTrackerRecords() {
        let row = deleteIndexPath?.row ?? 0
        DBGLog(String("checkTrackerDelete: will delete records only for row \(UInt(row))"))
        tlist?.deleteTrackerRecordsRow(row)
        tlist?.reloadFromTLT()
    }

    func handleCheckTrackerDelete(_ choice: Int) {
        //DBGLog(@"checkTrackerDelete buttonIndex= %d",buttonIndex);

        if choice == 0 {
            DBGLog("cancelled tracker delete")
            tableView.reloadRows(at: [deleteIndexPath].compactMap { $0 }, with: .right)
        } else if choice == 1 {
            delTracker()
        } else {
            delTrackerRecords()
            tableView.reloadRows(at: [deleteIndexPath].compactMap { $0 }, with: .right)
        }
        deleteIndexPath = nil
    }

    // MARK: -
    // MARK: Table view methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Customize the number of rows in the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tlist?.topLayoutNames.count ?? 0
    }

    // Customize the appearance of table view cells.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //DBGLog(@"rvc table cell at index %d label %@",[indexPath row],[self.tlist.topLayoutNames objectAtIndex:[indexPath row]]);
        
        let row = indexPath.row
        let toid = tlist?.getTIDfromIndex(row) ?? 0
        
        var cellIdentifier: String
        if selSegNdx == SegmentMoveDelete {
            cellIdentifier = "DeleteCell"
        } else {
            cellIdentifier = "Cell"
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        cell.backgroundColor = .clear
        if tlist?.isTrackerHidden(toid) ?? false {
            cell.backgroundColor = hiddenColor
        }
        // Configure the cell.

        cell.textLabel?.text = tlist!.topLayoutNames[row]
        cell.textLabel?.textColor = .label
        cell.accessibilityIdentifier = "configt_\(cell.textLabel!.text!)"
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let tn = (tlist?.topLayoutNames)?[row] as? String
        let tns = tn?.size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ])
        return (tns?.height ?? 0.0) + (2 * MARGIN)
    }

    func tableView(_ tableview: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(
        _ tableView: UITableView,
        moveRowAt fromIndexPath: IndexPath,
        to toIndexPath: IndexPath
    ) {

        let fromRow = fromIndexPath.row
        let toRow = toIndexPath.row

        DBGLog(String("ctlc: move row from \(UInt(fromRow)) to \(UInt(toRow))"))
        tlist?.reorderTLT(fromRow, toRow: toRow)
        tlist?.reorderDbFromTLT()

    }
    
    // Implement the swipe actions method to show both delete and hide/unhide
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only show swipe actions when in Move/Delete mode
        guard selSegNdx == SegmentMoveDelete else {
            return nil
        }
        
        // Get tracker ID for this row
        let row = indexPath.row
        let toid = tlist?.getTIDfromIndex(row) ?? 0
        
        // Create delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            self?.tableView(tableView, commit: .delete, forRowAt: indexPath)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        // Check if tracker is hidden
        let isHidden = tlist?.isTrackerHidden(toid) ?? false
        
        // Create hide/unhide action
        let hideAction = UIContextualAction(style: .normal, title: isHidden ? "Reveal" : "Hide") { [weak self] (action, view, completion) in
            if isHidden {
                self?.tlist?.unhideTracker(toid)
            } else {
                self?.tlist?.hideTracker(toid)
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        hideAction.backgroundColor = isHidden ? .systemGreen : .systemBlue
        hideAction.image = UIImage(systemName: isHidden ? "eye" : "eye.slash")
        
        // Configure swipe action
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, hideAction])
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Only handle delete case, hide/unhide is handled by swipe actions
        if editingStyle == .delete {
            deleteIndexPath = indexPath
            
            let tname = (tlist?.topLayoutNames)?[indexPath.row] as? String
            
            let toid = tlist?.getTIDfromIndex(indexPath.row) ?? 0
            let to = trackerObj(toid)
            let entries = to.countEntries()
            
            let title = "Delete tracker \(tname ?? "")"
            var msg: String?
            let btn0 = "Cancel"
            let btn1 = "Delete tracker"
            var btn2: String?
            
            if entries == 0 {
                msg = "Tracker \(tname ?? "") has no records."
                btn2 = nil
            } else {
                btn2 = "Remove records only"
                if entries == 1 {
                    msg = "Tracker \(tname ?? "") has 1 record."
                } else {
                    msg = "Tracker \(tname ?? "") has \(entries) records."
                }
            }
            
            let alert = UIAlertController(
                title: title,
                message: msg,
                preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: btn0, style: .default, handler: { [self] action in
                handleCheckTrackerDelete(0)
            })
            let deleteAction = UIAlertAction(title: btn1, style: .default, handler: { [self] action in
                handleCheckTrackerDelete(1)
            })
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            
            if let btn2 {
                let deleteRecordsAction = UIAlertAction(title: btn2, style: .default, handler: { [self] action in
                    handleCheckTrackerDelete(2)
                })
                alert.addAction(deleteRecordsAction)
            }
            
            
            present(alert, animated: true)
            
        }
    }

    // Override to support row selection in the table view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let row = indexPath.row
        //DBGLog(@"configTList selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);

        if selSegNdx == SegmentEdit {
            let toid = tlist?.getTIDfromIndex(row) ?? 0
            DBGLog(String("will config toid \(toid)"))

            let atc = addTrackerController()
            atc.tlist = tlist
            let tto = trackerObj(toid)
            atc.tempTrackerObj = tto
            atc.ttoRank = tlist!.toQry2Int(sql:"select rank from toplevel where id = '\(toid)'") // save to put temp tracker at this rank
            tto.removeTempTrackerData() // ttd array no longer valid if make any changes, can't be sure from here so wipe it

            navigationController?.pushViewController(atc, animated: true)
            //[atc.tempTrackerObj release]; // rtm 05 feb 2012 +1 alloc/init, +1 atc.temptto retain
        } else if selSegNdx == SegmentCopy {
            let toid = tlist?.getTIDfromIndex(row) ?? 0
            DBGLog(String("will copy toid \(toid)"))

            let oTO = trackerObj(toid)
            let nTO = tlist?.copy(toConfig: oTO)
            tlist?.add(toTopLayoutTable: nTO!)
            //[self.tlist loadTopLayoutTable];
            DispatchQueue.main.async(execute: { [self] in
                self.tableView.reloadData()
            })
        } else if selSegNdx == SegmentMoveDelete {
            DBGErr("selecteLogd for move/delete?")
        }
    }
}
