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

    @objc func startExport() {
        autoreleasepool {
            tlist?.exportAll()
            safeDispatchSync({ [self] in
                rTracker_resource.finishProgressBar(view, navItem: navigationItem, disable: true)
            })
        }
    }

    @objc func btnExport() {

        DBGLog("export all")
        let navframe = navigationController?.navigationBar.frame
        rTracker_resource.alert("exporting trackers", msg: "_out.csv and _out.plist files are being saved to the rTracker Documents directory on this device.  Access them through iTunes on your PC/Mac, or with a program like iExplorer from Macroplant.com.  Import by changing the names to _in.csv and _in.plist, and read about .rtcsv file import capabilities in the help pages.", vc: self)
        rTracker_resource.startProgressBar(view, navItem: navigationItem, disable: true, yloc: (navframe?.size.height ?? 0.0) + (navframe?.origin.y ?? 0.0))

        Thread.detachNewThreadSelector(#selector(startExport), toTarget: self, with: nil)
    }

    func getExportBtn() -> UIBarButtonItem? {
        var exportBtn: UIBarButtonItem?
        exportBtn = UIBarButtonItem(
            title: "Export all",
            style: .plain,
            target: self,
            action: #selector(btnExport))
        return exportBtn
    }

    // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {

        title = "Edit trackers"

        /*
         #else
            // wipe orphans
        	UIBarButtonItem *exportBtn = [[UIBarButtonItem alloc]
        								  initWithTitle:@"wipe orphans"
        								  style:UIBarButtonItemStylePlain
        								  target:self
        								  action:@selector(btnWipeOrphans)];

        #endif
        */
        //NSArray *tbArray = [NSArray arrayWithObjects: exportBtn, nil];
        //self.toolbarItems = tbArray;
        navigationController?.setToolbarHidden(true, animated: false)
        navigationItem.setRightBarButton(getExportBtn(), animated: false)

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


    @IBAction func modeChoice(_ sender: UISegmentedControl) {
        let selSegNdx = sender.selectedSegmentIndex
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
        //[self.deleteTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.deleteIndexPath]
        //					   withRowAnimation:UITableViewRowAnimationFade];
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

    /*
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        [self handleCheckTrackerDelete:buttonIndex];
    }

    */

    // MARK: -
    // MARK: Table view methods

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Customize the number of rows in the table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tlist?.topLayoutNames?.count ?? 0
    }

    // Customize the appearance of table view cells.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //DBGLog(@"rvc table cell at index %d label %@",[indexPath row],[self.tlist.topLayoutNames objectAtIndex:[indexPath row]]);

        var cellIdentifier: String
        if selSegNdx == SegmentMoveDelete {
            cellIdentifier = "DeleteCell"
        } else {
            cellIdentifier = "Cell"
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        cell.backgroundColor = .clear

        // Configure the cell.
        let row = indexPath.row
        cell.textLabel?.text = tlist!.topLayoutNames![row] as? String
        cell.textLabel?.textColor = .label
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
        tlist?.reorderFromTLT()

    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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

    // Override to support row selection in the table view.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Navigation logic may go here -- for example, create and push another view controller.
        // AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
        // [self.navigationController pushViewController:anotherViewController animated:YES];
        // [anotherViewController release];

        let row = indexPath.row
        //DBGLog(@"configTList selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);

        if selSegNdx == SegmentEdit {
            let toid = tlist?.getTIDfromIndex(row) ?? 0
            DBGLog(String("will config toid \(toid)"))

            let atc = addTrackerController(nibName: "addTrackerController", bundle: nil)
            atc.tlist = tlist
            let tto = trackerObj(toid)
            atc.tempTrackerObj = tto
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
            DBGWarn("selected for move/delete?")
        }
    }
}
