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
                tableView.backgroundColor = .secondarySystemBackground
                return
            }
        }

        tableView.backgroundColor = .clear
    }

    override func viewDidLoad() {

        DBGLog("atc: vdl tlist dbname= %@", tlist?.dbName) // use backing ivar because don't want dbg msg to instantiate

        // cancel / save buttons on top nav bar -- can't seem to do in IB

        let cancelBtn = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(btnCancel))
        navigationItem.leftBarButtonItem = cancelBtn


        let saveBtn = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(btnSave))
        navigationItem.rightBarButtonItem = saveBtn


        // list manage / configure segmented control on bottom toolbar
        configureToolbarItems()
        navigationController?.isToolbarHidden = true

        if tempTrackerObj == nil {
            // the temporary tracker obj we work with
            let tto = trackerObj()
            tempTrackerObj = tto
            //tempTrackerObj.trackerName = @"";
            //[self.tempTrackerObj init];
            tempTrackerObj?.toid = tlist?.getUnique() ?? 0
            //[self.tempTrackerObj release];  // rtm 05 feb 2012 +1 alloc/init +1 retained self.tempTrackerObj
            title = "Add tracker"
            toolbar.isHidden = true
        } else {
            title = "Modify tracker"
            toolbar.isHidden = false
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

    #if ADVERSION
    // handle rtPurchasedNotification
    @objc func updatePurchased(_ n: Notification?) {
        rTracker_resource.doQuickAlert("Purchase Successful", msg: "Thank you!", delay: 2, vc: self)
    }

    #endif

    override func viewWillAppear(_ animated: Bool) {

        DBGLog("atc: viewWillAppear, valObjTable count= %lu", UInt(tempTrackerObj?.valObjTable?.count ?? 0))

        tableView.reloadData()
        toggleEdit(segcEditTrackerEditItems)

        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(RootViewController.updatePurchased(_:)),
                name: NSNotification.Name(rtPurchasedNotification),
                object: nil)
        }
        #endif


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
        DBGLog("atc: viewWillDisappear, tracker name = %@", tempTrackerObj?.trackerName)

        safeDispatchSync({ [self] in
            if (nameField.text?.count ?? 0) > 0 {
                tempTrackerObj?.trackerName = nameField.text
                DBGLog("adding val, save tf: %@ = %@", tempTrackerObj?.trackerName, nameField.text)
            }
        })


        #if ADVERSION
        //unregister for purchase notices
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name(rtPurchasedNotification),
            object: nil)
        #endif

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

        let lastVO = tempTrackerObj?.valObjTable?.last as? valueObj
        let newVO = valueObj(dict: tempTrackerObj, dict: lastVO?.dictFromVO())
        newVO?.vid = tempTrackerObj?.getUnique() ?? 0
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
        ctvovc?.to = tempTrackerObj
        ctvovc?.vo = nil
        ctvovc?.modalTransitionStyle = .flipHorizontal
        //io6 [self presentModalViewController:ctvovc animated:YES];
        present(ctvovc, animated: true)
        // rtm 05 feb 2012 
    }

    func configureToolbarItems() {
        /*
            UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
        												initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
        												target:nil action:nil];

        	// Create and configure the segmented control
        	UISegmentedControl *editToggle = [[UISegmentedControl alloc]
        									  initWithItems:@[@"Edit tracker",
        													 @"Edit items"]];
        	editToggle.segmentedControlStyle = UISegmentedControlStyleBar;
        	editToggle.selectedSegmentIndex = 0;
        	editMode = 0;
        	[editToggle addTarget:self action:@selector(toggleEdit:)
        		 forControlEvents:UIControlEventValueChanged];

        	// Create the bar button item for the segmented control
        	UIBarButtonItem *editToggleButtonItem = [[UIBarButtonItem alloc]
        											 initWithCustomView:editToggle];

            //UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
            UIButton *infoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [infoBtn setTitle:@"⚙" forState:UIControlStateNormal];
         */
        infoBtn.titleLabel?.font = .systemFont(ofSize: 28.0)
        /*
            [infoBtn addTarget:self action:@selector(btnSetup) forControlEvents:UIControlEventTouchUpInside];
            infoBtn.frame = CGRectMake(0, 0, 44, 44);
            UIBarButtonItem *setupBtnItem = [[UIBarButtonItem alloc] initWithCustomView:infoBtn];
            */

        /*
        	UIBarButtonItem *setupBtnItem = [[UIBarButtonItem alloc]
        								 initWithTitle:@"Setup"
        								 style:UIBarButtonItemStylePlain
        								 target:self
        								 action:@selector(btnSetup)];
        	*/

        // Set our toolbar items
        /*
        	self.toolbarItems = @[setupBtnItem,
                                 flexibleSpaceButtonItem,
                                 editToggleButtonItem,
                                 flexibleSpaceButtonItem,
                                 //[self.itemCopyBtn autorelease], // analyze wants this but crashes later!
                                 self.itemCopyBtn];
            */

        //self.itemCopyBtn = nil;  // this stops crash, but lose control in toggleEdit() below
        //[itemCopyBtn release];


    }

    //@property (nonatomic,retain) UIActivityIndicatorView *spinner;
    @IBAction func toggleEdit(_ sender: Any) {
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
        var sql = String(format: "delete from voData where id=%ld;", vid)
        tempTrackerObj?.toExecSql(sql)
        sql = String(format: "delete from voConfig where id=%ld;", vid)
        tempTrackerObj?.toExecSql(sql)
    }

    @objc func btnSaveSlowPart() {
        autoreleasepool {
            //[self.spinner performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:NO];

            tempTrackerObj?.saveConfig()

            tlist?.add(toTopLayoutTable: tempTrackerObj)
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
        DBGLog("btnSave was pressed! tempTrackerObj name= %@ toid= %ld tlist= %x", tempTrackerObj?.trackerName, Int(tempTrackerObj?.toid ?? 0), UInt(tlist ?? 0))

        if saving {
            return
        }

        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            // can trigger on editing an existing tracker with more than 8 items
            if ADVER_ITEM_LIM < (tempTrackerObj?.valObjTable?.count ?? 0) {
                //[rTracker_resource buy_rTrackerAlert];
                rTracker_resource.replaceRtrackerA(self)
                return
            }
        }
        #endif

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
            if 8 < (tempTrackerObj?.valObjTable?.count ?? 0) {
                rTracker_resource.startActivityIndicator(view, navItem: navigationItem, disable: true, str: "Saving...")
            }

            Thread.detachNewThreadSelector(#selector(btnSaveSlowPart), toTarget: self, with: nil)
        } else {
            saving = false
            rTracker_resource.alert("save Tracker", msg: "Please set a name for this tracker to save", vc: self)
        }
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        btnSave()
    }

    //- (void)configureToolbarItems;

    // MARK: -
    // MARK: nameField, privField support Methods

    @IBAction func nameFieldDone(_ sender: Any) {
        sender.resignFirstResponder()
        if nameField.text != nil {
            tempTrackerObj?.trackerName = rTracker_resource.sanitizeFileNameString(nameField.text)
        }
    }

    // MARK: -
    // MARK: deleteValObj methods

    func delVOlocal(_ row: Int) {
        tempTrackerObj?.valObjTable?.remove(at: row)
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
            DBGLog("checkValObjDelete: will delete row %lu name %@ id %ld", UInt(row), vo?.valueName, Int(vo?.vid ?? 0))
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
            let rval = tempTrackerObj?.valObjTable?.count ?? 0
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
            if row == (tempTrackerObj?.valObjTable?.count ?? 0) {
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
            cell = tableView.dequeueReusableCell(withIdentifier: addTrackerController.tableViewNameCellID)
            if cell == nil {
                cell = UITableViewCell(
                    style: .default,
                    reuseIdentifier: addTrackerController.tableViewNameCellID)
                cell?.backgroundColor = nil
            } else {
                // the cell is being recycled, remove old embedded controls
                var viewToRemove: UIView? = nil
                while (viewToRemove = cell?.contentView.viewWithTag(kViewTag)) {
                    viewToRemove?.removeFromSuperview()
                }
            }

            //NSInteger row = [indexPath row];
            //if (row == 0) {

            //self.nameField = nil;
            //[_nameField release];
            //self.nameField = [[UITextField alloc] initWithFrame:CGRectMake(10,10,250,25) ];
            let rect = cell?.contentView.frame
            rect?.size.width = rTracker_resource.getKeyWindowWidth() // because ios 7.1 gets different width for cell
            #if !RELEASE
            // debug layout:
            //cell.backgroundColor = [UIColor orangeColor];
            #endif
            nameField = UITextField(frame: CGRect(x: 10, y: 5, width: (rect?.size.width ?? 0.0) - 20, height: (rect?.size.height ?? 0.0) - 10))
            nameField.clearsOnBeginEditing = false
            nameField.delegate = self
            nameField.returnKeyType = .done
            nameField.addTarget(
                self,
                action: #selector(nameFieldDone(_:)),
                for: .editingDidEndOnExit)
            nameField.tag = kViewTag
            cell?.contentView.addSubview(nameField)

            cell?.selectionStyle = .none
            nameField.font = PrefBodyFont
            nameField.text = tempTrackerObj?.trackerName

            if #available(iOS 13.0, *) {
                nameField.textColor = .label
                nameField.attributedPlaceholder = NSAttributedString(string: "Name this Tracker", attributes: [
                    .foregroundColor: UIColor.label
                ]) // @"Name this Tracker"
                nameField.backgroundColor = .systemBackground
            } else {
                nameField.textColor = .black
                nameField.attributedPlaceholder = NSAttributedString(string: "Name this Tracker", attributes: [
                    .foregroundColor: UIColor.darkGray
                ]) // @"Name this Tracker"
                nameField.backgroundColor = .white
            }

            view.bringSubviewToFront(nameField)
            // no help! self.nameField.layer.zPosition=10;
            //DBGLog(@"loaded section 0, %@ = %@",self.nameField.text , self.tempTrackerObj.trackerName);

            //		} else {   // row = 1
            //			cell.textLabel.text = @"privacy level:";
            //			self.privField = nil;
            //			privField = [[UITextField alloc] initWithFrame:CGRectMake(180,10,60,25) ];
            //			self.privField.borderStyle = UITextBorderStyleRoundedRect;
            //			self.privField.clearsOnBeginEditing = NO;
            //			[self.privField setDelegate:self];
            //			self.privField.returnKeyType = UIReturnKeyDone;
            //			[self.privField addTarget:self
            //						  action:@selector(privFieldDone:)
            //				forControlEvents:UIControlEventEditingDidEndOnExit];
            //			self.privField.tag = kViewTag;
            //			[cell.contentView addSubview:privField];
            //			
            //			cell.selectionStyle = UITableViewCellSelectionStyleNone;
            //		
            //			self.privField.text = self.tempTrackerObj.trackerName;
            //
            //			self.privField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;	// use the number input only
            //			self.privField.text = [NSString stringWithFormat:@"%d",self.tempTrackerObj.privacy];
            //			self.privField.placeholder = @"num";
            //			self.privField.textAlignment = UITextAlignmentRight;
            //		}
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: addTrackerController.tableViewValCellID)
            if cell == nil {
                cell = UITableViewCell(
                    style: .subtitle,
                    reuseIdentifier: addTrackerController.tableViewValCellID)
            }
            let row = indexPath.row
            if row == (tempTrackerObj?.valObjTable?.count ?? 0) {
                if 0 == row {
                    cell?.detailTextLabel?.text = "Add an item or value to track"
                } else {
                    cell?.detailTextLabel?.text = "add another thing to track"
                }
                cell?.textLabel?.text = ""
            } else {
                let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
                //DBGLog(@"starting section 1 cell for %@",vo.valueName);
                cell?.textLabel?.text = vo?.valueName
                cell?.accessoryType = .detailDisclosureButton
                //cell.detailTextLabel.text = [self.tempTrackerObj.votArray objectAtIndex:vo.vtype];
                /*
                            DBGLog(@"vtype %@",[rTracker_resource vtypeNames][vo.vtype]);
                            DBGLog(@"gtype %@",(vo.vos.voGraphSet)[vo.vGraphType]);
                            DBGLog(@"color %@",[rTracker_resource colorNames][vo.vcolor]);
                            */

                if "0" == (vo?.optDict)?["graph"] {
                    if let vtypeNames = rTracker_resource.vtypeNames()?[vo?.vtype ?? 0] {
                        cell?.detailTextLabel?.text = "\(vtypeNames) - no graph"
                    }
                } else if VOT_CHOICE == vo?.vtype {
                    if let vtypeNames = rTracker_resource.vtypeNames()?[vo?.vtype ?? 0], let voGraphSet = (vo?.vos?.voGraphSet())?[vo?.vGraphType ?? 0] {
                        cell?.detailTextLabel?.text = "\(vtypeNames) - \(voGraphSet)"
                    }
                } else if VOT_INFO == vo?.vtype {
                    if let vtypeNames = rTracker_resource.vtypeNames()?[vo?.vtype ?? 0] {
                        cell?.detailTextLabel?.text = "\(vtypeNames)"
                    }
                } else {
                    if let vtypeNames = rTracker_resource.vtypeNames()?[vo?.vtype ?? 0], let voGraphSet = (vo?.vos?.voGraphSet())?[vo?.vGraphType ?? 0], let colorNames = rTracker_resource.colorNames()?[vo?.vcolor ?? 0] {
                        cell?.detailTextLabel?.text = "\(vtypeNames) - \(voGraphSet) - \(colorNames)"
                    }
                }
            }

            cell?.backgroundColor = .clear
            if #available(iOS 13.0, *) {
                cell?.textLabel?.textColor = .label
                cell?.detailTextLabel?.textColor = .label
            }

            //DBGLog(@"loaded section 1 row %i : .%@. : .%@.",row, cell.textLabel.text, cell.detailTextLabel.text);
        }

        return cell!
    }

    func tableView(_ tableview: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        if section == 0 {
            return false
        }
        let row = indexPath.row
        if row >= (tempTrackerObj?.valObjTable?.count ?? 0) {
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
        DBGLog("atc: move row from %lu:%lu to %lu:%lu", UInt(fromSection), UInt(fromRow), UInt(toSection), UInt(toRow))
        #endif

        let vo = (tempTrackerObj?.valObjTable)?[fromRow] as? valueObj
        tempTrackerObj?.valObjTable?.remove(at: fromRow)
        if toRow > (tempTrackerObj?.valObjTable?.count ?? 0) {
            toRow = tempTrackerObj?.valObjTable?.count ?? 0
        }
        if let vo {
            tempTrackerObj?.valObjTable?.insert(vo, at: toRow)
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
            if row >= (tempTrackerObj?.valObjTable?.count ?? 0) {
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
            DBGLog("atc: delete row %lu ", UInt(row))
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
            DBGLog("atc: insert row %lu ", UInt(row))
            addValObj(nil)
            // else ??
        }
    }

    func addValObj(_ vo: valueObj?) {
        #if ADVERSION
        if !rTracker_resource.getPurchased() {
            if vo == nil {
                if ADVER_ITEM_LIM <= (tempTrackerObj?.valObjTable?.count ?? 0) {
                    //[rTracker_resource buy_rTrackerAlert];
                    rTracker_resource.replaceRtrackerA(self)
                    return
                }
            }
        }
        #endif
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
        DBGLog("row= %lu count= %lu", UInt(row), UInt(tempTrackerObj?.valObjTable?.count ?? 0))
        if row < (tempTrackerObj?.valObjTable?.count ?? 0) {
            addValObj((tempTrackerObj?.valObjTable)?[row] as? valueObj)
        } else {
            addValObj(nil)
        }
    }

    ///*
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let row = indexPath.row
        let section = indexPath.section
        DBGLog("selected section %lu row %lu ", UInt(section), UInt(row))
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