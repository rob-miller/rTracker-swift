//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voState.swift
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
//  voState.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import Foundation
import UIKit



class voState: NSObject, voProtocol {
    var vo: valueObj
    var MyTracker: trackerObj
    var vosFrame = CGRect.zero
    weak var vc: UIViewController?

    init(vo valo: valueObj) {
        vo = valo
        MyTracker = vo.parentTracker
        super.init()

        vo.useVO = true
    }

    func getValCap() -> Int {
        // NSMutableString size for value
        return 10
    }
    
    func getNumVal() -> Double {
        return Double(vo.value) ?? 0
    }
    
    func update(_ instr: String?) -> String {
        // place holder so fn can update on access; also confirm textfield updated
        // added return "" if disabled 30.vii.13
        if vo.useVO {
            return instr ?? ""
        } else {
            return ""
        }
    }

    func loadConfig() {
    }

    func loadHKdata(forDate date: Int?, dispatchGroup: DispatchGroup?) {
    }
    
    func clearHKdata(forDate date: Int? = nil) {
    }
    
    func loadOTdata(forDate date: Int? = nil, dispatchGroup: DispatchGroup?) {
        let to = vo.parentTracker

        guard let xtName = vo.optDict["otTracker"] else {
            DBGErr("no otTracker specified for valueObj \(vo.valueName ?? "no name")")
            return
        }

        guard let xvName = vo.optDict["otValue"] else {
            DBGErr("no otValue specified for valueObj \(vo.valueName ?? "no name")")
            return
        }
        
        let xto: trackerObj
        let xvid: Int
        
        if xtName == to.trackerName {
            xto = to
            guard let xvo = xto.getValObjByName(xvName) else {
                DBGErr("no xvid for other tracker = self \(xtName) valueObj \(xvName)")
                return
            }
            xvid = xvo.vid
        } else {
            xto = trackerObj(trackerList.shared.getTIDfromNameDb(xtName)[0])
            if xvName == OTANYNAME {
                xvid = OTANYVID
            } else {
                let tempxvid = xto.toQry2Int(sql: "select id from voConfig where name = '\(xvName)'")
                if tempxvid == 0 {
                    DBGErr("no xvid for other tracker \(xtName) valueObj \(xvName)")
                    return
                }
                xvid = tempxvid
            }
        }
        dispatchGroup?.enter()  // wait for processing all OT data
        
        let xcd = vo.optDict["otCurrent"] == "1"

        var sql = "select max(date) from voOTstatus where id = \(Int(vo.vid)) and stat = \(otStatus.otData.rawValue)"
        let lastDate = to.toQry2Int(sql: sql)
        var prevDate = lastDate
        
        var myDates: [Int]
            
        // get all local tracker dates to populate
        if let specificDate = date {
            // If a specific date is provided, only query that date and if it exists
            myDates = to.toQry2AryI(sql: "select date from trkrData where date = \(specificDate)")
            prevDate = specificDate
        } else {
            // Original implementation - get all dates after lastDate
            myDates = to.toQry2AryI(sql: "select date from trkrData where date > \(lastDate) order by date asc")
        }
        
        for md in myDates {
            
            let selStr: String
            if xvid == OTANYVID {
                selStr = "1 from voData where date"
            } else {
                selStr = "val from voData where id = \(xvid) and date"
            }
            if xto.toid == to.toid {  // other tracker is self so exact date match
                sql = "select \(selStr) = \(md)"
            } else if xcd {
                sql = "select \(selStr) <= \(md) and date > \(prevDate)"
            } else {
                sql = "select \(selStr) <= \(md)"
            }
            let xval = xto.toQry2Str(sql: sql)
            if xval != "" {
                sql = "insert into voData (id, date, val) values (\(self.vo.vid), \(md), '\(xval)')"
                to.toExecSql(sql: sql)
                sql = "insert into voOTstatus (id, date, stat) values (\(self.vo.vid), \(md), \(otStatus.otData.rawValue))"
                to.toExecSql(sql: sql)
            } else {
                // No data found - create noData status (processed but no data available)
                DBGLog("no data for \(sql)")
                sql = "insert into voOTstatus (id, date, stat) values (\(self.vo.vid), \(md), \(otStatus.noData.rawValue))"
                to.toExecSql(sql: sql)
            }
            
            // Update progress tracking
             if let delegate = to.refreshDelegate, (date == nil || date == 0) {
                 // Only update progress during a full refresh (indicated by delegate and no specific date)
                 DispatchQueue.main.async {
                     delegate.updateFullRefreshProgress(step: 1, phase: nil, totalSteps: nil)
                 }
             }
            
            prevDate = md
        }
        
            
        // ensure trkrData has lowest priv if just added a lower privacy valuObj to a trkrData entry
        let priv = max(MINPRIV, self.vo.vpriv)  // priv needs to be at least minpriv if vpriv = 0
        sql = """
        UPDATE trkrData
        SET minpriv = \(priv)
        WHERE minpriv > \(priv)
          AND EXISTS (
            SELECT 1
            FROM voData
            WHERE voData.date = trkrData.date
              AND voData.id = \(Int(vo.vid))
          );
        """
        to.toExecSql(sql: sql)
        DBGLog("Done loadOTdata \(xtName) \(xvName) with \(myDates.count) records.")
        dispatchGroup?.leave()  // done with enter before getHealthkitDates processing overall
        
    }

    func clearOTdata(forDate date: Int? = nil) {
        let to = vo.parentTracker
        var sql = ""
        if let specificDate = date {
            to.toExecSql(sql: "delete from voData where id = \(vo.vid) and date = \(specificDate)")
            to.toExecSql(sql: "delete from voOTstatus where id = \(vo.vid) and date = \(specificDate)")
        } else {
            sql = "delete from voData where (id, date) in (select id, date from voOTstatus where id = \(vo.vid))"
            to.toExecSql(sql: sql)
            sql = "delete from voOTstatus where id = \(vo.vid)"
            to.toExecSql(sql: sql)
        }
    }
    
    
    func loadFNdata(dispatchGroup: DispatchGroup?) {
    }

    func clearFNdata(forDate date: Int? = nil) {
    }
    
    func setFNrecalc() {
    }
    
    func setOptDictDflts() {

        if nil == vo.optDict["graph"] {
            vo.optDict["graph"] = GRAPHDFLT ? "1" : "0"
        }
        if nil == vo.optDict["privacy"] {
            vo.optDict["privacy"] = "\(PRIVDFLT)"
        }

        if nil == vo.optDict["otCurrent"] {
            vo.optDict["otCurrent"] = OTCURRDFLT ? "1" : "0"
        }
        
        if nil == vo.optDict["otsrc"] {
            vo.optDict["otsrc"] = OTSRCDFLT ? "1" : "0"
        }

        if nil == vo.optDict["hrsmins"] {
            vo.optDict["hrsmins"] = HRSMINSDFLT ? "1" : "0"
        }
        
        if nil == vo.optDict["hidden"] {
            vo.optDict["hidden"] = HIDDENDFLT ? "1" : "0"
        }
    }

    func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "graph") && (val == (GRAPHDFLT ? "1" : "0")))
            || ((key == "privacy") && (Int(val ?? "") ?? 0 == PRIVDFLT))
            || ((key == "otCurrent") && (val == (OTCURRDFLT ? "1" : "0")))
            || ((key == "otsrc") && (val == (OTSRCDFLT ? "1" : "0")))
            || ((key == "hrsmins") && (val == (HRSMINSDFLT ? "1" : "0")))
            || ((key == "hidden") && (val == (HIDDENDFLT ? "1" : "0")))
        {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        return false

    }

    func tvn() -> String {
        let tname = self.vo.parentTracker.trackerName ?? "tnull"
        let vname = self.vo.valueName ?? "vnull"
        return "\(tname)_\(vname)"
    }
    
    func voDrawOptions(_ ctvovc: configTVObjVC) {
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)
        var labframe = ctvovc.configLabel("Draw graph:", frame: frame, key: "ggLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        //-- draw graphs button

        let switchFrame = ctvovc.configSwitch(
            frame,
            key: "ggBtn",
            state: !(vo.optDict["graph"] == "0"),
            addsv: true)

        //-- privacy level label

        frame.origin.x += frame.size.width + switchFrame.size.width  //  MARGIN + SPACE
        //frame.origin.y += MARGIN + frame.size.height;
        labframe = ctvovc.configLabel("Privacy level: ", frame: frame, key: "gpLab", addsv: true)

        //-- privacy level textfield

        frame.origin.x += labframe.size.width + SPACE
        var tfWidth = "9999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovc.lfHeight)

        _ = ctvovc.configTextField(
            frame,
            key: "gpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(PRIVDFLT)",
            text: vo.optDict["privacy"],
            addsv: true)

        //------

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        labframe = ctvovc.configLabel("Line at Y=", frame: frame, key: "gyLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        tfWidth = "9999999.99".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovc.lfHeight)

        _ = ctvovc.configTextField(
            frame,
            key: "gyTF",
            target: nil,
            action: nil,
            num: true,
            place: "0",
            text: vo.optDict["yline1"],
            addsv: true)

        ctvovc.lasty = frame.origin.y + frame.size.height + MARGIN
        ctvovc.lastx = (ctvovc.lastx < frame.origin.x + frame.size.width + MARGIN ? frame.origin.x + frame.size.width + MARGIN : ctvovc.lastx)

    }

    func voDisplay(_ bounds: CGRect) -> UIView {
        dbgNSAssert(false, "voDisplay failed to dispatch")
        return UIView()
    }

    func getOTrslt() -> String {
        let xtName = vo.optDict["otTracker"] ?? ""
        let xvName = vo.optDict["otValue"] ?? ""
        let xcd = vo.optDict["otCurrent"] == "1"
        if (!xtName.isEmpty && !xvName.isEmpty) {
            if xtName == MyTracker.trackerName {  // looking at self
                let xvo = MyTracker.getValObjByName(xvName)
                return xvo?.value ?? ""
            } else {
                let xto = trackerObj(trackerList.shared.getTIDfromNameDb(xtName)[0])
                let xvid: Int
                if xvName == OTANYNAME {
                    xvid = OTANYVID
                } else {
                    xvid = xto.toQry2Int(sql: "select id from voConfig where name = '\(xvName)'")
                }
                if xvid != 0 {  // 0 is not found, OTANYVID is -1
                    let to = vo.parentTracker
                    let td = to.trackerDate!.timeIntervalSince1970
                    var rslt = ""
                    let selStr: String
                    if xvid == OTANYVID {
                        selStr = "1 from trkrData where"
                    } else {
                        selStr = "val from voData where id = \(xvid) and"
                    }
                    if xcd {
                        let pd = to.prevDate()
                        if pd != 0 {
                            let sql = "select \(selStr) date <= \(td) and date > \(pd)"
                            rslt = xto.toQry2Str(sql: sql)
                        }
                    } else {
                        let sql = "select \(selStr) date <= \(td)"
                        rslt = xto.toQry2Str(sql: sql)
                    }
                    return rslt
                }
            }
        }
        return ""
    }

    func addExternalSourceOverlay(to control: UIView) {
        // Create a clear overlay that matches the control's bounds
        let overlayView = UIView(frame: control.bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = true
        
        // Make sure the overlay resizes with the control
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add a tap gesture that does nothing but capture the tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleExternalSourceTap(_:)))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Add overlay directly to the control
        control.addSubview(overlayView)
    }

    @objc func handleExternalSourceTap(_ gesture: UITapGestureRecognizer) {
        // This function simply captures taps and does nothing else
        // This prevents the tap from reaching the control underneath
    }
    
    let LMARGIN = 60.0
    let RMARGIN = 10.0
    let BMARGIN = 7.0


    func updateControlInCell(_ cell: UITableViewCell) {
        // Remove existing control
        let controlTag = kViewTag + 100
        if let existingControl = cell.contentView.viewWithTag(controlTag) {
            existingControl.removeFromSuperview()
        }
        
        // Calculate bounds based on cell type
        var bounds = CGRect.zero
        let maxLabel = self.vo.parentTracker.maxLabel
        
        // Check the cell type by looking for the switch control
        let isEnabledCell = cell.contentView.subviews.contains { view in
            return view is UISwitch && view.accessibilityIdentifier?.contains("\(tvn())_enable") == true
        }
        
        if isEnabledCell {
            // For two-row cells (enabled cells)
            let screenSize = UIScreen.main.bounds.size
            bounds.origin.y = maxLabel.height + (3.0 * MARGIN)
            bounds.size.height = maxLabel.height + (1.5 * MARGIN)
            bounds.size.width = screenSize.width - (2.0 * MARGIN)
            bounds.origin.x = MARGIN
        } else {
            // For single-row cells
            bounds.origin.x = maxLabel.width + LMARGIN
            bounds.origin.y = MARGIN
            bounds.size.width = rTracker_resource.getKeyWindowWidth() - maxLabel.width - LMARGIN - RMARGIN
            bounds.size.height = maxLabel.height + MARGIN
        }
        
        // Force recreation of display
        self.vo.display = nil
        
        // Create and add the new control with smooth transition
        if let newDisplay = self.vo.display(bounds) {
            newDisplay.tag = controlTag
            
            // Add with fade-in animation
            newDisplay.alpha = 0
            cell.contentView.addSubview(newDisplay)
            
            UIView.animate(withDuration: 0.15) {
                newDisplay.alpha = 1.0
            }
        }
    }
    
    
    static let voTVEnabledCellCellIdentifier = "Cell1"

    func voTVEnabledCell(_ tableView: UITableView?) -> UITableViewCell {
        var cell: UITableViewCell?
        let maxLabel = vo.parentTracker.maxLabel
        
        // Dequeue or create cell
        cell = tableView?.dequeueReusableCell(withIdentifier: voState.voTVEnabledCellCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: voState.voTVEnabledCellCellIdentifier)
            cell?.selectionStyle = .none
            cell?.backgroundColor = nil
        } else {
            // Remove any existing views with the label tag
            while let viewToRemove = cell?.contentView.viewWithTag(kViewTag) {
                viewToRemove.removeFromSuperview()
            }
            
            // Remove any existing control view
            if let controlView = cell?.contentView.viewWithTag(kViewTag + 100) {
                controlView.removeFromSuperview()
            }
        }
        
        cell?.backgroundColor = .clear
        
        // Setup the switch control
        var bounds = CGRect.zero
        bounds.origin.x = MARGIN
        bounds.origin.y = MARGIN
        bounds.size.width = 30.0 // for checkbox
        bounds.size.height = 30.0
        vo.switchUseVO?.frame = bounds
        vo.switchUseVO?.tag = kViewTag
        vo.switchUseVO?.accessibilityHint = "enable this control"
        vo.switchUseVO?.accessibilityIdentifier = "\(tvn())_enable"
        vo.switchUseVO?.isOn = vo.useVO
        
        if let aswitchUseVO = vo.switchUseVO {
            cell?.contentView.addSubview(aswitchUseVO)
        }
        
        // Setup the label(s)
        setupEnabledLabelForCell(cell!, switchWidth: vo.switchUseVO?.intrinsicContentSize.width ?? 0.0, maxLabel: maxLabel)
        
        // Setup control display in second row
        let screenSize = UIScreen.main.bounds.size
        bounds.origin.y = maxLabel.height + (3.0 * MARGIN)
        bounds.size.height = maxLabel.height + (1.5 * MARGIN)
        bounds.size.width = screenSize.width - (2.0 * MARGIN)
        bounds.origin.x = MARGIN
        
        if let aDisplay = vo.display(bounds) {
            aDisplay.tag = kViewTag + 100 // Special tag for controls
            cell?.contentView.addSubview(aDisplay)
        }
        
        return cell!
    }

    // Helper method for enabled cell labels
    private func setupEnabledLabelForCell(_ cell: UITableViewCell, switchWidth: CGFloat, maxLabel: CGSize) {
        var bounds = CGRect.zero
        bounds.origin.x = MARGIN + switchWidth + MARGIN
        bounds.origin.y = MARGIN
        
        let screenSize = UIScreen.main.bounds.size
        bounds.size.width = screenSize.width - switchWidth - (2.0 * MARGIN)
        bounds.size.height = maxLabel.height + MARGIN
        
        let splitStrArr = vo.valueName?.components(separatedBy: "|")
        let hasSplit = 1 < (splitStrArr?.count ?? 0)
        
        if hasSplit {
            bounds.size.width /= 2.0
        }
        
        // Check if this valueObj is icon tagged
        let isIconTagged = vo.optDict["otsrc"] == "1" || vo.optDict["ahksrc"] == "1" || vo.vtype == VOT_FUNC
        
        // First label (or only label if no split)
        let labelContainer = UIView(frame: bounds)
        labelContainer.tag = kViewTag
        
        let label = UILabel(frame: CGRect(
            x: isIconTagged ? 26 : 0,
            y: 0,
            width: isIconTagged ? bounds.size.width - 26 : bounds.size.width,
            height: bounds.size.height
        ))
        
        label.font = PrefBodyFont
        label.textColor = .label
        let darkMode = vc?.traitCollection.userInterfaceStyle == .dark
        label.backgroundColor = darkMode ? UIColor.systemBackground : UIColor.clear
        label.alpha = 1.0
        label.textAlignment = .left
        label.contentMode = .topLeft
        label.text = splitStrArr?[0]
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        
        labelContainer.addSubview(label)
        
        // Add source indicator if needed
        if isIconTagged {
            let iconName = vo.optDict["otsrc"] == "1" ? "link" : vo.optDict["ahksrc"] == "1" ? "heart.text.square" : "function"
            let sourceIndicator = UIImageView(image: UIImage(systemName: iconName))
            sourceIndicator.tintColor = .systemBlue
            sourceIndicator.contentMode = .scaleAspectFit
            sourceIndicator.frame = CGRect(x: 0, y: 0, width: 22, height: bounds.size.height)
            sourceIndicator.center.y = bounds.size.height / 2
            labelContainer.addSubview(sourceIndicator)
        }
        
        cell.contentView.addSubview(labelContainer)
        
        // Second label if split by |
        if hasSplit {
            bounds.origin.x += bounds.size.width
            bounds.size.width -= 2.0 * MARGIN
            
            let secondLabelContainer = UIView(frame: bounds)
            secondLabelContainer.tag = kViewTag
            
            let secondLabel = UILabel(frame: CGRect(
                x: 0,
                y: 0,
                width: bounds.size.width,
                height: bounds.size.height
            ))
            
            secondLabel.font = PrefBodyFont
            secondLabel.textColor = .label
            secondLabel.backgroundColor = darkMode ? UIColor.systemBackground : UIColor.clear
            secondLabel.alpha = 1.0
            secondLabel.textAlignment = .right
            secondLabel.contentMode = .topRight
            secondLabel.text = splitStrArr?[1]
            secondLabel.lineBreakMode = .byTruncatingTail
            secondLabel.numberOfLines = 1
            
            secondLabelContainer.addSubview(secondLabel)
            cell.contentView.addSubview(secondLabelContainer)
        }
    }
    
    func voTVCellHeight() -> CGFloat {
        let labelSize = vo.getLabelSize()
        let maxLabel = vo.parentTracker.maxLabel

        if labelSize.width <= maxLabel.width || VOT_INFO == vo.vtype {
            //return CELL_HEIGHT_NORMAL;
            //return maxLabel.height + (2*MARGIN);
            return labelSize.height + (2 * MARGIN)
        } else {
            //return CELL_HEIGHT_TALL;
            return labelSize.height + maxLabel.height + (2 * MARGIN)
        }
    }

    static let voTVCellCellIdentifier = "Cell2"
    
    func voTVCell(_ tableView: UITableView) -> UITableViewCell {
        var cell: UITableViewCell?
        let maxLabel = vo.parentTracker.maxLabel
        
        // Dequeue or create cell
        cell = tableView.dequeueReusableCell(withIdentifier: voState.voTVCellCellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: voState.voTVCellCellIdentifier)
            cell?.selectionStyle = .none
        } else {
            // Remove any existing views with the label/container tag
            while let viewToRemove = cell?.contentView.viewWithTag(kViewTag) {
                viewToRemove.removeFromSuperview()
            }
            
            // Remove any existing control view
            if let controlView = cell?.contentView.viewWithTag(kViewTag + 100) {
                controlView.removeFromSuperview()
            }
        }
         
        cell?.backgroundColor = .clear
        
        // Create the label portion
        setupLabelForCell(cell!, maxLabel: maxLabel)
        
        // Add control display
        var bounds = CGRect.zero
        bounds.origin.x = maxLabel.width + LMARGIN
        bounds.origin.y = MARGIN
        bounds.size.width = rTracker_resource.getKeyWindowWidth() - maxLabel.width - LMARGIN - RMARGIN
        bounds.size.height = maxLabel.height + MARGIN
        
        if let aDisplay = vo.display(bounds) {
            aDisplay.tag = kViewTag + 100 // Special tag for controls
            cell?.contentView.addSubview(aDisplay)
        }
        
        return cell!
    }

    // Helper method to setup the label portion of the cell
    private func setupLabelForCell(_ cell: UITableViewCell, maxLabel: CGSize) {
        var bounds = CGRect.zero
        bounds.origin.x = MARGIN
        bounds.origin.y = MARGIN
        bounds.size.width = maxLabel.width
        bounds.size.height = maxLabel.height
        
        let containerView = UIView(frame: bounds)
        containerView.tag = kViewTag
        
        let isIconTagged = vo.optDict["otsrc"] == "1" || vo.optDict["ahksrc"] == "1" || vo.vtype == VOT_FUNC
        
        let label = UILabel(frame: CGRect(
            x: isIconTagged ? 26 : 0,
            y: 0,
            width: isIconTagged ? bounds.size.width - 26 : bounds.size.width,
            height: bounds.size.height
        ))
        
        label.font = PrefBodyFont
        label.textColor = .label
        let darkMode = vc?.traitCollection.userInterfaceStyle == .dark
        label.backgroundColor = darkMode ? UIColor.systemBackground : UIColor.clear
        label.alpha = 1.0
        label.textAlignment = .left
        label.contentMode = .topLeft
        label.text = vo.valueName
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        
        containerView.addSubview(label)
        
        // Add source indicator if needed
        if isIconTagged {
            let iconName = vo.optDict["otsrc"] == "1" ? "link" : vo.optDict["ahksrc"] == "1" ? "heart.text.square" : "function"
            let sourceIndicator = UIImageView(image: UIImage(systemName: iconName))
            sourceIndicator.tintColor = .systemBlue
            sourceIndicator.contentMode = .scaleAspectFit
            sourceIndicator.frame = CGRect(x: 0, y: 0, width: 22, height: bounds.size.height)
            sourceIndicator.center.y = bounds.size.height / 2
            containerView.addSubview(sourceIndicator)
        }
        
        cell.contentView.addSubview(containerView)
        cell.accessibilityIdentifier = "useT_\(vo.vos!.tvn())"
    }
    
    func dataEditVDidLoad(_ vc: UIViewController) {
    }

    func dataEditVWAppear(_ vc: UIViewController) {
    }

    func dataEditVWDisappear(_ vc: UIViewController) {
    }

    /*
    - (void) dataEditVDidUnload {
    }
    */

    //- (void) dataEditFinished {
    //}

    func voGraphSet() -> [String] {
        return ["dots", "no graph"]
    }


    class func voGraphSetNum() -> [String] {
        return ["dots", "bar", "line", "line+dots", "no graph"]
    }

    func updateVORefs(_ newVID: Int, old oldVID: Int) {
        // subclass overrides if need to do anything
    }

    func newVOGD() -> vogd {
        DBGErr("newVOGD with no handler!")
        return vogd(vo).initAsNum(vo)
    }

    func setFnVal(_ tDate: Int, dispatchGroup: DispatchGroup? = nil) {
        // subclass overrides if need to do anything
    }

    func doTrimFnVals() {
        // subclass overrides if need to do anything
    }

    func resetData() {
        // subclass overrides if need to do anything
        vo.useVO = true
    }

    func mapValue2Csv() -> String? {
        return vo.value // subclass overrides if need to do anything - specifically for choice, textbox
    }

    func mapCsv2Value(_ inCsv: String) -> String {
        return inCsv // subclass overrides if need to do anything - specifically for choice
    }

}
