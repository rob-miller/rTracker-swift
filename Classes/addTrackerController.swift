//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// addTrackerController.swift
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
//  addTrackerController.swift
//  rTracker
//
//  from this screen the user creates or edits a tracker, by naming it and adding values.
//
//  Created by Robert Miller on 15/04/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

///************
/// addTrackerController.swift
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
//  addTrackerController.swift
//  rTracker
//
//  Created by Robert Miller on 15/04/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import UIKit

var editMode = 0

class addTrackerController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var tlist: trackerList?
    var tempTrackerObj: trackerObj?
    var saving = false
    // UI element properties 
    @IBOutlet var tableView: UITableView!
    @IBOutlet var infoBtn: UIButton!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var itemCopyBtn: UIButton!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var segcEditTrackerEditItems: UISegmentedControl!
    var deleteIndexPath: IndexPath? // remember row to delete if user confirms in checkTrackerDelete alert
    var deleteVOs: [AnyHashable]? // VOs to be deleted on save
    var ttoRank: Int? = nil

    var modifying: Bool = false
    
    // MARK: -
    // MARK: core object methods and support

    deinit {
        DBGLog("atc: dealloc")
    }

    // MARK: -
    // MARK: view support

    //#define TEMPFILE @"tempTrackerObj_plist"

    func setViewMode() {
        rTracker_resource.setViewMode(self)

        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                // if darkMode
                tableView.backgroundColor = .systemBackground
                return
            }
        }

        tableView.backgroundColor = .clear
    }

    override func viewDidLoad() {

        DBGLog(String("atc: vdl tlist dbname= \(tlist?.dbName)")) // use backing ivar because don't want dbg msg to instantiate

        // cancel / save buttons on top nav bar -- can't seem to do in IB

        let cancelBtn = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(btnCancel))
        navigationItem.leftBarButtonItem = cancelBtn
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "addTrkrCancel"

        let saveBtn = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(btnSave))
        navigationItem.rightBarButtonItem = saveBtn
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "addTrkrSave"


        // list manage / configure segmented control on bottom toolbar
        configureToolbarItems()
        navigationController?.isToolbarHidden = true

        if tempTrackerObj == nil {
            // the temporary tracker obj we work with
            let tto = trackerObj()
            tempTrackerObj = tto
            //tempTrackerObj.trackerName = @"";
            //[self.tempTrackerObj init];
            tempTrackerObj?.toid = tlist!.getUnique()
            title = "Add tracker"
            toolbar.isHidden = true
            modifying = false
        } else {
            //title = "Modify tracker"
            toolbar.isHidden = false
            let titleLabel = UILabel()
            titleLabel.text = "Modify tracker"
            titleLabel.accessibilityHint = "left widget to enable delete button, center to modify value, right widget to change order"
            navigationItem.titleView = titleLabel

            modifying = true
            
            //toolbar.leftBarButtonItem?.accessibilityHint = "leave without saving"
            //toolbar.leftBarButtonItem?
        }

        tableView.setEditing(true, animated: true)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none

        // set graph paper background - not seen if darkMode, but still there

        let bg = UIImageView(image: rTracker_resource.get_background_image(self))
        bg.tag = BGTAG
        view.addSubview(bg)
        view.sendSubviewToBack(bg)

        setViewMode()

        saving = false

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)

        super.viewDidLoad()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    override func viewWillAppear(_ animated: Bool) {

        DBGLog(String("atc: viewWillAppear, valObjTable count= \(tempTrackerObj?.valObjTable.count)"))

        tableView.reloadData()
        toggleEdit(segcEditTrackerEditItems!)

        super.viewWillAppear(animated)

    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.

        //tempTrackerObj.colorSet = nil;
        //self.tempTrackerObj.votArray = nil;


    }

    override func viewWillDisappear(_ animated: Bool) {
        DBGLog(String("atc: viewWillDisappear, tracker name = \(tempTrackerObj?.trackerName)"))

        safeDispatchSync({ [self] in
            if (nameField.text?.count ?? 0) > 0 {
                tempTrackerObj?.trackerName = nameField.text
                DBGLog(String("adding val, save tf: \(tempTrackerObj?.trackerName) = \(nameField.text)"))
            }
        })

        super.viewWillDisappear(animated)

    }

    /*
    - (void) viewDidUnload {
    	DBGLog(@"atc: viewdidunload");
    	self.nameField = nil;
    	self.tlist = nil;
    	self.tempTrackerObj = nil;
    	self.table = nil;

    	self.title = nil;

    	self.navigationItem.rightBarButtonItem = nil;
    	self.navigationItem.leftBarButtonItem = nil;
    	[self setToolbarItems:nil
    				 animated:NO];

        self.deleteVOs=nil;

    	[super viewDidUnload];
    }
    */
    // MARK: -
    // MARK: toolbar support

    @IBAction func btnCopy(_ sender: Any) {
        DBGLog("copy!")

        let lastVO = tempTrackerObj?.valObjTable.last as? valueObj
        let newVO = valueObj(dict: tempTrackerObj!, dict: lastVO?.dictFromVO())
        newVO.vid = (tempTrackerObj?.getUnique())!
        tempTrackerObj?.addValObj(newVO)
        tableView.reloadData()

    }

    /*
    - (UIBarButtonItem *) itemCopyBtn {
        if (nil == _itemCopyBtn) {

            UIButton *cBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            NSString *title = @"Copy";
            cBtn.frame = CGRectMake(0, 0,
                                    ceilf( [title sizeWithAttributes:@{NSFontAttributeName:cBtn.titleLabel.font}].width ) +3,
                                    ceilf( [title sizeWithAttributes:@{NSFontAttributeName:cBtn.titleLabel.font}].height) +2);

            [cBtn setTitle:@"Copy" forState:UIControlStateNormal];
            [cBtn addTarget:self action:@selector(btnCopy) forControlEvents:UIControlEventTouchUpInside];
            _itemCopyBtn = [[UIBarButtonItem alloc] initWithCustomView:cBtn];
        }

        return _itemCopyBtn;
    }
    */

    /*
     frame.size.width = [label sizeWithFont:button.titleLabel.font].width + 4*SPACE;
    if (frame.origin.x == -1.0f) {
        frame.origin.x = self.view.frame.size.width - (frame.size.width + MARGIN); // right justify
    }
    button.frame = frame;
    */

    @IBAction func btnSetup(_ sender: Any) {
        let ctvovc = configTVObjVC()
        ctvovc.to = tempTrackerObj
        ctvovc.vo = nil
        ctvovc.modalTransitionStyle = .flipHorizontal
        //io6 [self presentModalViewController:ctvovc animated:YES];
        present(ctvovc, animated: true)
        // rtm 05 feb 2012 
    }

    func configureToolbarItems() {

        infoBtn.titleLabel?.font = .systemFont(ofSize: 28.0)


    }

    //@property (nonatomic,retain) UIActivityIndicatorView *spinner;
    // UISegmentedControl hidden because modify valueObjs accessible from move/del view
    // so this is not called
    @IBAction func toggleEdit(_ sender: UISegmentedControl) {
        editMode = sender.selectedSegmentIndex
        //[table reloadData];
        if editMode == 0 {
            tableView.setEditing(true, animated: true)
            itemCopyBtn.isEnabled = true
        } else {
            tableView.setEditing(false, animated: true)
            itemCopyBtn.isEnabled = false
        }

        //[table reloadRowsAtIndexPaths:[table indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationFade];
        DispatchQueue.main.async(execute: { [self] in
            tableView.reloadSections(NSIndexSet(index: 1) as IndexSet, with: .fade)
        })
    }

    // MARK: -
    // MARK: button press handlers
    /*
    - (IBAction)btnAddValue {
    DBGLog(@"btnAddValue was pressed!");
    }
    */
    @IBAction func btnCancel() {
        deleteVOs = nil

        navigationController?.popViewController(animated: true)
        //[rTracker_resource myNavPopTransition:self.navigationController animOpt:UIViewAnimationOptionTransitionCurlDown];


    }

    func delVOdb(_ vid: Int) {
        tempTrackerObj?.delVOdb(vid)
    }

    @objc func btnSaveSlowPart() {
        autoreleasepool {
            //[self.spinner performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:NO];

            // figure out if have changed HK data source here and clearHKdata() for the relevant vo
            if modifying {
                let oldTracker = trackerObj(tempTrackerObj!.toid)
                var ahUpdated = false
                for ovo in oldTracker.valObjTable {
                    let ood = ovo.optDict
                    if let oaks = ood["ahksrc"] {
                        let oahs = ood["ahSource"], oahu = ood["ahUnit"], oaha = ood["ahAvg"], oahpd = ood["ahPrevD"], oahhm = ood["hrsmins"]
                        for nvo in tempTrackerObj!.valObjTable {
                            if nvo.vid == ovo.vid {
                                let nod = nvo.optDict
                                let nahs = nod["ahSource"], nahu = nod["ahUnit"], naks = nod["ahksrc"], naha = nod["ahAvg"], nahpd = nod["ahPrevD"], nahhm = nod["hrsmins"]
                                if (nahs != oahs || nahu != oahu || naks != oaks || naha != oaha || nahpd != oahpd || nahhm != oahhm) {
                                    ovo.vos?.clearHKdata()
                                    ahUpdated = true
                                }
                                break  // break out of finding valObj in newTracker, still checking oldTracker
                            }
                        }
                    }
                }
                if ahUpdated {
                    // delete trkrData entries which no longer have associated voData
                    let sql = "delete from trkrdata where date not in (select date from voData where voData.date = trkrdata.date)"
                    oldTracker.toExecSql(sql: sql)
                }
            }
            tempTrackerObj?.saveConfig()

            tlist?.add(toTopLayoutTable: tempTrackerObj!, nrank: ttoRank)
            tlist?.loadTopLayoutTable()

            DispatchQueue.main.async(execute: { [self] in
                rTracker_resource.finishActivityIndicator(view, navItem: navigationItem, disable: true)
                navigationController?.popViewController(animated: true)
            })
            //[rTracker_resource myNavPopTransition:self.navigationController animOpt:UIViewAnimationOptionTransitionCurlDown];

            saving = false
        }

    }

    @IBAction func btnSave() {
        DBGLog(String("btnSave was pressed! tempTrackerObj name= \(tempTrackerObj?.trackerName) toid= \(tempTrackerObj?.toid) tlist= \(tlist)"))

        if saving {
            return
        }

        saving = true

        if deleteVOs != nil {
            for vo in deleteVOs ?? [] {
                guard let vo = vo as? valueObj else {
                    continue
                }
                delVOdb(vo.vid)
            }
            deleteVOs = nil
        }

        nameField.resignFirstResponder()

        if (nameField.text?.count ?? 0) > 0 {
            tempTrackerObj?.trackerName = nameField.text

            if tempTrackerObj?.toid == nil {
                tempTrackerObj?.toid = tlist?.getUnique() ?? 0
            }
            if 8 < (tempTrackerObj?.valObjTable.count ?? 0) {
                rTracker_resource.startActivityIndicator(view, navItem: navigationItem, disable: true, str: "Saving...")
            }

            Thread.detachNewThreadSelector(#selector(btnSaveSlowPart), toTarget: self, with: nil)
        } else {
            saving = false
            rTracker_resource.alert("Save Tracker", msg: "Please set a name for this tracker to save", vc: self)
        }
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnSave()
    }

    //- (void)configureToolbarItems;

    // MARK: -
    // MARK: nameField, privField support Methods

    @IBAction func nameFieldDone(_ sender: UIResponder) {
        sender.resignFirstResponder()
        if let nftxt = nameField.text {
            tempTrackerObj?.trackerName = rTracker_resource.sanitizeFileNameString(nftxt)
        }
    }

    // MARK: -
    // MARK: deleteValObj methods

    func delVOlocal(_ row: Int) {
        tempTrackerObj?.valObjTable.remove(at: row)
        tableView.deleteRows(
            at: [deleteIndexPath].compactMap { $0 },
            with: .fade)
    }

    func addDelVO(_ vo: valueObj?) {
        if deleteVOs == nil {
            deleteVOs = []
        }
        if let vo {
            deleteVOs?.append(vo)
        }
    }

    func handleCheckValObjDelete(_ choice: Int) {
        //DBGLog(@"checkValObjDelete buttonIndex= %d",buttonIndex);

        if choice == 1 {
            // yes delete
            let row = deleteIndexPath?.row ?? 0
            let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
            DBGLog(String("checkValObjDelete: will delete row \(row) name \(vo?.valueName) id \(vo?.vid)"))
            //[self delVOdb:vo.vid];
            addDelVO(vo)
            delVOlocal(row)
        } else {
            //DBGLog(@"check valobjdelete cancelled");
            tableView.reloadRows(at: [deleteIndexPath].compactMap { $0 }, with: .right)
        }
        deleteIndexPath = nil

    }

    /*
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        [self handleCheckValObjDelete:buttonIndex];
    }
    */

    // MARK: -
    // MARK: Table View Data Source Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return Int(1)
        } else {
            var rval = tempTrackerObj?.valObjTable.count ?? 0
            if editMode == 0 {
                rval += 1
            }
            return rval
        }

    }

    //- (NSInteger)tableView:(UITableView *)tableView numberOfSections: (UITableView *) tableView {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(2)
    }

    //TODO: tweak this to get section headers right ios7
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 6.0
        /*
            if (section == 0)
                return 6.0;
            else return UITableViewAutomaticDimension;
             */
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let section = indexPath.section
        if 0 == section {
            //CGSize tns = [self.tempTrackerObj.trackerName sizeWithAttributes:@{NSFontAttributeName:PrefBodyFont}];
            let tns = "Name this Tracker".size(withAttributes: [
                NSAttributedString.Key.font: PrefBodyFont
            ])
            return tns.height + (2 * MARGIN)
        } else {
            if row == (tempTrackerObj?.valObjTable.count ?? 0) {
                let vons = "add another thing to track".size(withAttributes: [
                    NSAttributedString.Key.font: PrefBodyFont
                ])
                return vons.height + (2 * MARGIN)
            } else {
                let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
                let vons = vo?.valueName?.size(withAttributes: [
                    NSAttributedString.Key.font: PrefBodyFont
                ])
                return (vons?.height ?? 0.0) + (2 * MARGIN) + 6.0
            }
        }
    }

        static let tableViewNameCellID = "nameCellID"
        static let tableViewValCellID = "valCellID"

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        let section = indexPath.section
        if section == 0 {
            // Name field section - code unchanged
            cell = tableView.dequeueReusableCell(withIdentifier: addTrackerController.tableViewNameCellID)
            if cell == nil {
                cell = UITableViewCell(
                    style: .default,
                    reuseIdentifier: addTrackerController.tableViewNameCellID)
                cell?.backgroundColor = nil
            } else {
                // the cell is being recycled, remove old embedded controls
                while let viewToRemove = cell?.contentView.viewWithTag(kViewTag) {
                    viewToRemove.removeFromSuperview()
                }
            }
            
            var rect = cell?.contentView.frame
            rect?.size.width = rTracker_resource.getKeyWindowWidth() // because ios 7.1 gets different width for cell
            
            nameField = UITextField(frame: CGRect(x: 10, y: 5, width: (rect?.size.width ?? 0.0) - 20, height: (rect?.size.height ?? 0.0) - 10))
            nameField.clearsOnBeginEditing = false
            nameField.delegate = self
            nameField.returnKeyType = .done
            nameField.addTarget(
                self,
                action: #selector(nameFieldDone(_:)),
                for: .editingDidEndOnExit)
            nameField.tag = kViewTag
            nameField.accessibilityIdentifier = "addTrkrName"
            
            cell?.contentView.addSubview(nameField)
            cell?.selectionStyle = .none
            nameField.font = PrefBodyFont
            nameField.text = tempTrackerObj?.trackerName
            nameField.textColor = .label
            nameField.attributedPlaceholder = NSAttributedString(string: "Name this Tracker", attributes: [
                .foregroundColor: UIColor.label
            ])
            nameField.backgroundColor = .secondarySystemBackground
            
            view.bringSubviewToFront(nameField)
     
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: addTrackerController.tableViewValCellID)
            if cell == nil {
                cell = UITableViewCell(
                    style: .subtitle,
                    reuseIdentifier: addTrackerController.tableViewValCellID)
            }
            
            // Remove any existing icon to prevent duplication
            cell?.contentView.viewWithTag(kViewTag + 1)?.removeFromSuperview()
            
            let row = indexPath.row
            if row == (tempTrackerObj?.valObjTable.count ?? 0) {
                if 0 == row {
                    cell?.detailTextLabel?.text = "Add an item or value to track"
                } else {
                    cell?.detailTextLabel?.text = "add another thing to track"
                }
                cell?.accessibilityIdentifier = "trkrAddValue"
                cell?.textLabel?.text = ""
            } else {
                let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
                
                // Check for external source
                let isOtSource = vo?.optDict["otsrc"] == "1"
                let isAhkSource = vo?.optDict["ahksrc"] == "1"
                let isFn = vo?.vtype == VOT_FUNC
                let isIconTagged = isOtSource || isAhkSource || isFn
                
                // Use standard text labeling
                cell?.textLabel?.text = vo?.valueName
                
                // For external sources, add a small icon to the left of the text
                if isIconTagged {
                    // Create a small icon to the left of the text
                    let iconName = isOtSource ? "link" : isAhkSource ? "heart.text.square" : "function"
                    let sourceIndicator = UIImageView(image: UIImage(systemName: iconName))
                    sourceIndicator.tag = kViewTag + 1
                    sourceIndicator.tintColor = .systemBlue
                    sourceIndicator.contentMode = .scaleAspectFit
                    
                    // Make the icon smaller (12x12) and position it better
                    sourceIndicator.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
                    
                    // Position the icon in the left margin of the cell
                    let cellIndentation: CGFloat = 15  // Standard cell indentation
                    sourceIndicator.frame.origin.x = cellIndentation - 14  // Position before text
                    sourceIndicator.center.y = (cell?.contentView.bounds.height ?? 0) * 0.35  // Align with main text, slightly above center
                    
                    cell?.contentView.addSubview(sourceIndicator)
                    
                    // Indent the main text slightly to avoid overlapping with the icon
                    cell?.textLabel?.frame.origin.x += 2
                }
                
                cell?.accessibilityIdentifier = "\(vo?.parentTracker.trackerName ?? "tNull")_\(vo?.valueName ?? "vNull")"
                cell?.accessoryType = .detailDisclosureButton
                
                if "0" == vo!.optDict["graph"] {
                    let vtypeNames = rTracker_resource.vtypeNames()[vo!.vtype]
                    cell?.detailTextLabel?.text = "\(vtypeNames) - no graph"
                    
                } else if VOT_CHOICE == vo!.vtype {
                    let vtypeNames = rTracker_resource.vtypeNames()[vo!.vtype]
                    let voGraphSet = (vo?.vos?.voGraphSet())?[vo!.vGraphType]
                    cell?.detailTextLabel?.text = "\(vtypeNames) - \(voGraphSet!)"
                } else if VOT_INFO == vo!.vtype {
                    let vtypeNames = rTracker_resource.vtypeNames()[vo!.vtype]
                    cell?.detailTextLabel?.text = "\(vtypeNames)"
                } else {
                    let vtypeNames = rTracker_resource.vtypeNames()[vo!.vtype]
                    let voGraphSet = (vo?.vos?.voGraphSet())?[vo!.vGraphType]
                    let colorNames = rTracker_resource.colorNames()[vo!.vcolor]
                    cell?.detailTextLabel?.text = "\(vtypeNames) - \(voGraphSet!) - \(colorNames)"
                }
            }
            cell?.backgroundColor = .clear
            if #available(iOS 13.0, *) {
                cell?.textLabel?.textColor = .label
                cell?.detailTextLabel?.textColor = .label
            }
        }
        return cell!
    }
    
    func tableView(_ tableview: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        if section == 0 {
            return false
        }
        let row = indexPath.row
        if row >= (tempTrackerObj?.valObjTable.count ?? 0) {
            return false
        }

        return true
    }

    func tableView(
        _ tableView: UITableView,
        moveRowAt fromIndexPath: IndexPath,
        to toIndexPath: IndexPath
    ) {
        let fromRow = fromIndexPath.row
        var toRow = toIndexPath.row

        #if DEBUGLOG
        let fromSection = fromIndexPath.section
        let toSection = toIndexPath.section
        DBGLog(String("atc: move row from \(UInt(fromSection)):\(UInt(fromRow)) to \(UInt(toSection)):\(UInt(toRow))"))
        #endif

        let vo = (tempTrackerObj?.valObjTable)?[fromRow] as? valueObj
        tempTrackerObj?.valObjTable.remove(at: fromRow)
        if toRow > (tempTrackerObj?.valObjTable.count ?? 0) {
            toRow = tempTrackerObj?.valObjTable.count ?? 0
        }
        if let vo {
            tempTrackerObj?.valObjTable.insert(vo, at: toRow)
        }

        // fail
        self.tableView.reloadData()
    }

    func tableView(_ tableview: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let section = indexPath.section
        if section == 0 {
            return .none
        } else {
            let row = indexPath.row
            if row >= (tempTrackerObj?.valObjTable.count ?? 0) {
                return .insert
            } else {
                return .delete
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        let row = indexPath.row
        // NSUInteger section = [indexPath section];  // in theory this only called on vals section
        if editingStyle == .delete {
            DBGLog(String("atc: delete row \(row) "))
            deleteIndexPath = indexPath

            let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
            if (tempTrackerObj?.tDb == nil) || (tempTrackerObj?.toid == nil) {
                delVOlocal(row)
            } else if !(tempTrackerObj?.voHasData(vo?.vid ?? 0) ?? false) {
                // no actual values stored in db for this valObj
                addDelVO(vo)
                delVOlocal(row)
            } else {
                let title = (vo?.valueName ?? "") + " has data"
                let msg = "Value \(vo?.valueName ?? "") has stored data, which will be removed when you Save this page."
                let btn0 = "Cancel"
                let btn1 = "Yes, delete"

                let alert = UIAlertController(
                    title: title,
                    message: msg,
                    preferredStyle: .alert)

                let cancelAction = UIAlertAction(title: btn0, style: .default, handler: { [self] action in
                    handleCheckValObjDelete(0)
                })
                let deleteAction = UIAlertAction(title: btn1, style: .default, handler: { [self] action in
                    handleCheckValObjDelete(1)
                })

                alert.addAction(cancelAction)
                alert.addAction(deleteAction)

                present(alert, animated: true)
            }
        } else if editingStyle == .insert {
            DBGLog(String("atc: insert row \(row) "))
            addValObj(nil)
            // else ??
        }
    }

    func addValObj(_ vo: valueObj?) {

        var avc: addValObjController?
        //if (kIS_LESS_THAN_IOS7) {
        //    avc = [[addValObjController alloc] initWithNibName:@"addValObjController" bundle:nil ];
        //} else {
        avc = addValObjController(nibName: "addValObjController7", bundle: nil)
        //}
        avc?.parentTrackerObj = tempTrackerObj
        avc?.tempValObj = vo
        avc?.stashVals()

        if let avc {
            navigationController?.pushViewController(avc, animated: true)
        }
    }

    func addValObjR(_ row: Int) {
        DBGLog(String("row= \(row) count= \(tempTrackerObj?.valObjTable.count)"))
        if row < (tempTrackerObj?.valObjTable.count ?? 0) {
            addValObj((tempTrackerObj?.valObjTable)?[row] as? valueObj)
        } else {
            addValObj(nil)
        }
    }

    ///*
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let row = indexPath.row
        let section = indexPath.section
        DBGLog(String("selected section \(section) row \(row) "))
        if 0 == section {
            nameField.becomeFirstResponder()
        } else {
            addValObjR(row)
        }

    }

    //*/


    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {


        let row = indexPath.row
        //NSUInteger section = [indexPath section];

        //DBGLog(@"accessory button tapped for section %d row %d ", section, row);

        addValObjR(row)

    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }

        // Return NO if you do not want the specified item to be editable.
        if editMode == 0 {
            return true
        } else {
            return false
        }
    }
}
