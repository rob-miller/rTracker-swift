//
//  addTrackerController.swift
//  rTracker
//
//  from this screen the user creates or edits a tracker, by naming it and adding values.
//
//  Created by Robert Miller on 15/04/2010.
//  Copyright 2010-2021 Robert T. Miller. All rights reserved.
//

import UIKit


class addTrackerController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var tlist: trackerList?
    var tempTrackerObj: trackerObj?
    var saving = false

    // MARK: - UI Elements (now created in code)
    var tableView: UITableView!
    var toolbar: UIToolbar!
    var setupButton: UIBarButtonItem!
    var copyButton: UIBarButtonItem!

    var nameField: UITextField! // created in cellForRow for section 0
    var infoBtn: UIButton! // appears unused, preserved for possible future info button
    var itemCopyBtn: UIBarButtonItem! // mapped to copyButton

    var deleteIndexPath: IndexPath? // remember row to delete if user confirms in checkTrackerDelete alert
    var deleteVOs: [AnyHashable]? // VOs to be deleted on save
    var ttoRank: Int? = nil

    var modifying: Bool = false
    var isReorderingInProgress: Bool = false

    // MARK: -
    // MARK: core object methods and support

    deinit {
        DBGLog("atc: dealloc")
    }


    // MARK: -
    // MARK: view support

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
        if #available(iOS 26.0, *) {
            cancelBtn.hidesSharedBackground = true  // Remove white container background
        }
        navigationItem.leftBarButtonItem = cancelBtn
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "addTrkrCancel"

        let saveBtn = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(btnSave))
        if #available(iOS 26.0, *) {
            saveBtn.hidesSharedBackground = true  // Remove white container background
        }
        navigationItem.rightBarButtonItem = saveBtn
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "addTrkrSave"

        // MARK: - UI Setup: Table View
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.setEditing(true, animated: false)
        tableView.allowsSelection = true
        tableView.allowsSelectionDuringEditing = true
        tableView.separatorStyle = .none
        view.addSubview(tableView)

        // MARK: - UI Setup: Toolbar & Items

        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Setup button
        setupButton = UIBarButtonItem(title: "Setup", style: .plain, target: self, action: #selector(btnSetup(_:)))
        setupButton.accessibilityIdentifier = "addTrkrSetup"
        setupButton.accessibilityLabel = "Setup"
        setupButton.accessibilityHint = "Configure tracker settings"


        // Copy button
        copyButton = UIBarButtonItem(title: "Copy", style: .plain, target: self, action: #selector(btnCopy(_:)))
        copyButton.accessibilityIdentifier = "addTrkrCopy"
        copyButton.accessibilityLabel = "Copy"
        copyButton.accessibilityHint = "Duplicate last item"

        // Fill space
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [setupButton, flexibleSpace, copyButton]

        // MARK: - Constraints

        NSLayoutConstraint.activate([
            // TableView: pin to top, left, right, and above toolbar
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            // Toolbar: pin to left, right, bottom
            toolbar.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // For info button, if needed in future:
        infoBtn = UIButton(type: .infoLight)
        infoBtn.isHidden = true // currently not displayed

        // Logic for tracker object setup
        if tempTrackerObj == nil {
            let tto = trackerObj()
            tempTrackerObj = tto
            tempTrackerObj?.toid = tlist!.getUnique()
            title = "Add tracker"
            toolbar.isHidden = true
            modifying = false
        } else {
            toolbar.isHidden = false
            let titleLabel = UILabel()
            titleLabel.text = "Modify tracker"
            titleLabel.accessibilityHint = "left widget to enable delete button, center to modify value, right widget to change order"
            navigationItem.titleView = titleLabel
            modifying = true
        }

        setViewMode()

        saving = false

        // Swipe right gesture for saving
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)


        super.viewDidLoad() // NOTE: super should go at end due to UIKit expectations
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setViewMode()
        tableView.setNeedsDisplay()
        view.setNeedsDisplay()
    }

    override func viewWillAppear(_ animated: Bool) {
        DBGLog(String("atc: viewWillAppear, valObjTable count= \(tempTrackerObj?.valObjTable.count)"))
        tableView.reloadData()
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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

    // MARK: -
    // MARK: toolbar support

    @objc func btnCopy(_ sender: Any) {
        DBGLog("copy!")
        guard let lastVO = tempTrackerObj?.valObjTable.last as? valueObj else { return }
        let newVO = valueObj(dict: tempTrackerObj!, dict: lastVO.dictFromVO())
        newVO.vid = (tempTrackerObj?.getUnique())!
        tempTrackerObj?.addValObj(newVO)
        tableView.reloadData()
    }

    @objc func btnSetup(_ sender: Any) {
        let ctvovc = configTVObjVC()
        ctvovc.to = tempTrackerObj
        ctvovc.vo = nil
        ctvovc.modalPresentationStyle = .fullScreen
        ctvovc.modalTransitionStyle = .coverVertical
        present(ctvovc, animated: true)
    }


    // MARK: -
    // MARK: button press handlers

    @objc func btnCancel() {
        deleteVOs = nil
        navigationController?.popViewController(animated: true)
    }

    func delVOdb(_ vid: Int) {
        tempTrackerObj?.delVOdb(vid)
    }

    @objc func btnSaveSlowPart() {
        autoreleasepool {
            if modifying {
                let oldTracker = trackerObj(tempTrackerObj!.toid)
                var ahUpdated = false
                for ovo in oldTracker.valObjTable {
                    let ood = ovo.optDict
                    if let oaks = ood["ahksrc"] {
                        let oahs = ood["ahSource"], oahu = ood["ahUnit"], oahpd = ood["ahPrevD"], oahhm = ood["hrsmins"]
                        for nvo in tempTrackerObj!.valObjTable {
                            if nvo.vid == ovo.vid {
                                let nod = nvo.optDict
                                let nahs = nod["ahSource"], nahu = nod["ahUnit"], naks = nod["ahksrc"], nahpd = nod["ahPrevD"], nahhm = nod["hrsmins"]
                                if (nahs != oahs || nahu != oahu || naks != oaks || nahpd != oahpd || nahhm != oahhm) {
                                    ovo.vos?.clearHKdata()
                                    ahUpdated = true
                                }
                                break
                            }
                        }
                    }
                }
                if ahUpdated {
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
            saving = false
        }
    }

    @objc func btnSave() {
        DBGLog(String("btnSave was pressed! tempTrackerObj name= \(tempTrackerObj?.trackerName) toid= \(tempTrackerObj?.toid) tlist= \(tlist)"))
        if saving { return }
        saving = true

        if deleteVOs != nil {
            for vo in deleteVOs ?? [] {
                guard let vo = vo as? valueObj else { continue }
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

    // MARK: -
    // MARK: nameField support Methods

    @objc func nameFieldDone(_ sender: UIResponder) {
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
        if choice == 1 {
            let row = deleteIndexPath?.row ?? 0
            let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
            DBGLog(String("checkValObjDelete: will delete row \(row) name \(vo?.valueName) id \(vo?.vid)"))
            addDelVO(vo)
            delVOlocal(row)
        } else {
            tableView.reloadRows(at: [deleteIndexPath].compactMap { $0 }, with: .right)
        }
        deleteIndexPath = nil
    }

    func reloadVOcell(_ valueObj: valueObj) {
        if let index = tempTrackerObj?.valObjTable.firstIndex(where: { $0.vid == valueObj.vid }) {
            let indexPath = IndexPath(row: index, section: 1)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }

    func hideValueObj(_ valueObj: valueObj) {
        valueObj.optDict["hidden"] = "1"
        reloadVOcell(valueObj)
    }

    func unhideValueObj(_ valueObj: valueObj) {
        valueObj.optDict["hidden"] = "0"
        reloadVOcell(valueObj)
    }

    // MARK: -
    // MARK: Table View Data Source Methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            var rval = tempTrackerObj?.valObjTable.count ?? 0
            rval += 1  // Always add the "add another" row
            return rval
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 6.0
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let section = indexPath.section
        let row = indexPath.row

        if section == 0 || row == (tempTrackerObj?.valObjTable.count ?? 0) {
            return nil // No swipe actions for name field or add row
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            self?.tableView(tableView, commit: .delete, forRowAt: indexPath)
            completion(true)
        }

        guard let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj else {
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        let isHidden = vo.optDict["hidden"] == "1"

        let hideOrRevealAction = UIContextualAction(style: .normal, title: isHidden ? "Reveal" : "Hide") { [weak self] (action, view, completion) in
            guard let self = self else { return completion(false) }
            if isHidden {
                self.unhideValueObj(vo)
            } else {
                self.hideValueObj(vo)
            }
            completion(true)
        }
        hideOrRevealAction.backgroundColor = isHidden ? .systemGreen : .systemBlue
        hideOrRevealAction.image = UIImage(systemName: isHidden ? "eye" : "eye.slash")
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, hideOrRevealAction])
        return configuration
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        let section = indexPath.section
        if 0 == section {
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
            cell = tableView.dequeueReusableCell(withIdentifier: addTrackerController.tableViewNameCellID)
            if cell == nil {
                cell = UITableViewCell(
                    style: .default,
                    reuseIdentifier: addTrackerController.tableViewNameCellID)
                cell?.backgroundColor = nil
            } else {
                while let viewToRemove = cell?.contentView.viewWithTag(kViewTag) {
                    viewToRemove.removeFromSuperview()
                }
            }

            var rect = cell?.contentView.frame
            rect?.size.width = rTracker_resource.getKeyWindowWidth()

            nameField = UITextField(frame: CGRect(x: 10, y: 5, width: (rect?.size.width ?? 0.0) - 20, height: (rect?.size.height ?? 0.0) - 10))
            nameField.clearsOnBeginEditing = false
            nameField.delegate = self
            nameField.returnKeyType = .done
            nameField.addTarget(self, action: #selector(nameFieldDone(_:)), for: .editingDidEndOnExit)
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

            cell?.contentView.viewWithTag(kViewTag + 1)?.removeFromSuperview()

            cell?.backgroundColor = .clear
            cell?.textLabel?.textColor = .label
            cell?.detailTextLabel?.textColor = .label

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
                let isOtSource = vo?.optDict["otsrc"] == "1"
                let isAhkSource = vo?.optDict["ahksrc"] == "1"
                let isFn = vo?.vtype == VOT_FUNC
                let isIconTagged = isOtSource || isAhkSource || isFn
                cell?.textLabel?.text = vo?.valueName
                if isIconTagged {
                    let iconName = isOtSource ? "link" : isAhkSource ? "heart.text.square" : "function"
                    let sourceIndicator = UIImageView(image: UIImage(systemName: iconName))
                    sourceIndicator.tag = kViewTag + 1
                    sourceIndicator.tintColor = .systemBlue
                    sourceIndicator.contentMode = .scaleAspectFit
                    sourceIndicator.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
                    let cellIndentation: CGFloat = 15
                    sourceIndicator.frame.origin.x = cellIndentation - 14
                    sourceIndicator.center.y = (cell?.contentView.bounds.height ?? 0) * 0.35
                    cell?.contentView.addSubview(sourceIndicator)
                    cell?.textLabel?.frame.origin.x += 2
                }

                cell?.accessibilityIdentifier = "\(vo?.parentTracker.trackerName ?? "tNull")_\(vo?.valueName ?? "vNull")"
                cell?.accessoryType = .detailDisclosureButton

                if "0" == vo!.optDict["graph"] || vo!.vGraphType == VOG_NONE {
                    let vtypeNames = ValueObjectType.typeNames[vo!.vtype]
                    cell?.detailTextLabel?.text = "\(vtypeNames) - no graph"
                } else if VOT_CHOICE == vo!.vtype {
                    let vtypeNames = ValueObjectType.typeNames[vo!.vtype]
                    let voGraphSet = (vo?.vos?.voGraphSet())?[vo!.vGraphType]
                    cell?.detailTextLabel?.text = "\(vtypeNames) - \(voGraphSet!)"
                } else if VOT_INFO == vo!.vtype {
                    let vtypeNames = ValueObjectType.typeNames[vo!.vtype]
                    cell?.detailTextLabel?.text = "\(vtypeNames)"
                } else {
                    let vtypeNames = ValueObjectType.typeNames[vo!.vtype]
                    let voGraphSet = (vo?.vos?.voGraphSet())?[vo!.vGraphType]
                    let colorNames = rTracker_resource.colorNames[vo!.vcolor]
                    cell?.detailTextLabel?.text = "\(vtypeNames) - \(voGraphSet!) - \(colorNames)"
                }

                if vo?.optDict["hidden"] == "1" {
                    cell?.backgroundColor = hiddenColor
                }
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


    // Track when reordering begins
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        isReorderingInProgress = true

        // Allow move only within section 1 and within valid range
        if proposedDestinationIndexPath.section != 1 {
            return sourceIndexPath
        }

        let maxRow = (tempTrackerObj?.valObjTable.count ?? 1) - 1
        if proposedDestinationIndexPath.row > maxRow {
            return IndexPath(row: maxRow, section: 1)
        }

        return proposedDestinationIndexPath
    }

    func tableView(
        _ tableView: UITableView,
        moveRowAt fromIndexPath: IndexPath,
        to toIndexPath: IndexPath
    ) {
        let fromRow = fromIndexPath.row
        var toRow = toIndexPath.row
        let vo = (tempTrackerObj?.valObjTable)?[fromRow] as? valueObj
        tempTrackerObj?.valObjTable.remove(at: fromRow)
        if toRow > (tempTrackerObj?.valObjTable.count ?? 0) {
            toRow = tempTrackerObj?.valObjTable.count ?? 0
        }
        if let vo {
            tempTrackerObj?.valObjTable.insert(vo, at: toRow)
        }
        self.tableView.reloadData()

        // Re-enable selection after a longer delay to ensure reorder gesture is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isReorderingInProgress = false
        }
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
        if editingStyle == .delete {
            DBGLog(String("atc: delete row \(row) "))
            deleteIndexPath = indexPath

            let vo = (tempTrackerObj?.valObjTable)?[row] as? valueObj
            if (tempTrackerObj?.tDb == nil) || (tempTrackerObj?.toid == nil) {
                delVOlocal(row)
            } else if !(tempTrackerObj?.voHasData(vo?.vid ?? 0) ?? false) {
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
        }
    }

    func addValObj(_ vo: valueObj?) {
        var avc: addValObjController?
        avc = addValObjController(nibName: "addValObjController7", bundle: nil)
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


    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Don't highlight during reordering operations
        if isReorderingInProgress {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // Don't allow selection during reordering operations
        if isReorderingInProgress {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let section = indexPath.section
        tableView.deselectRow(at: indexPath, animated: true)
        if 0 == section {
            nameField.becomeFirstResponder()
        } else {
            addValObjR(row)
        }
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let row = indexPath.row

        // Block accessory button during reordering too
        if isReorderingInProgress {
            return
        }

        addValObjR(row)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }
        return true
    }
}
