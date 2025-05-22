//
//  voNumber.swift
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//
//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// voNumber.swift
/// Copyright 2010-2025 Robert T. Miller
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


import Foundation
import UIKit
import SwiftUI
import HealthKit

class voNumber: voState, UITextFieldDelegate {

    private var _dtf: UITextField?
    lazy var rthk = rtHealthKit.shared
    private static var healthKitCache: [String: String] = [:]  // Cache by "sourceName-date"
    let noHKdataMsg = "No HealthKit data available"
    
    var dtf: UITextField {
        if _dtf?.frame.size.width != vosFrame.size.width {
            _dtf = nil // first time around thinks size is 320, handle larger devices
        }
        
        if nil == _dtf {
            _dtf = createTextField()
        }
        return _dtf!
    }
    
    private func createTextField() -> UITextField {
        //DBGLog(String("init \(vo.valueName) : x=\(vosFrame.origin.x) y=\(vosFrame.origin.y) w=\(vosFrame.size.width) h=\(vosFrame.size.height)"))

        let textField = UITextField(frame: vosFrame)
        
        textField.textColor = .label
        textField.backgroundColor = .secondarySystemBackground
        
        textField.borderStyle = .roundedRect //Bezel;
        textField.font = PrefBodyFont // [UIFont systemFontOfSize:17.0];
        textField.autocorrectionType = .no // no auto correction support
        
        textField.placeholder = "<enter number>"
        textField.textAlignment = .right // ios6 UITextAlignmentRight;
        //[dtf addTarget:self action:@selector(numTextFieldClose:) forControlEvents:UIControlEventTouchUpOutside];
        
        
        textField.keyboardType = .decimalPad //number pad with decimal point but no done button     // use the number input only
        // no done button for number pad // _dtf.returnKeyType = UIReturnKeyDone;
        // need this from http://stackoverflow.com/questions/584538/how-to-show-done-button-on-iphone-number-pad Michael Laszlo
        // .applicationFrame deprecated ios9
        //let appWidth = Float(UIScreen.main.bounds.width)
        let accessoryView = createInputAccessoryView()
        
        textField.inputAccessoryView = accessoryView
        
        textField.clearButtonMode = .whileEditing // has a clear 'x' button to the right
        
        //dtf.tag = kViewTag;        // tag this control so we can remove it later for recycled cells
        textField.delegate = self // let us be the delegate so we know when the keyboard's "Done" button is pressed
        
        // Add an accessibility label that describes what the text field is for.
        textField.accessibilityHint = NSLocalizedString("enter a number", comment: "")
        textField.text = ""
        textField.accessibilityIdentifier = "\(self.tvn())_numberfield"
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        return textField
    }
    
    private func createInputAccessoryView() -> UIToolbar {
        let appWidth = Float(UIScreen.main.bounds.width)
        let accessoryView = UIToolbar(
            frame: CGRect(x: 0, y: 0, width: CGFloat(appWidth), height: CGFloat(0.1 * appWidth)))
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil)
        let done = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(selectDoneButton))
        let minus = UIBarButtonItem(
            title: "-",
            style: .plain,
            target: self,
            action: #selector(selectMinusButton))
        
        accessoryView.items = [space, done, space, minus, space]
        return accessoryView
    }
    
    var startStr: String?
    var ctvovcp: configTVObjVC?
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //DBGLog(@"number tf begin editing vid=%ld",(long)self.vo.vid);
        startStr = textField.text
        vo.parentTracker.activeControl = textField
    }

    @objc func textFieldDidChange(_ textField: UITextField?) {
        // not sure yet - lot of actions for every char when just want to enable 'save'
        //[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        DBGLog(String("vo.value= \(vo.value)"))
        DBGLog(String("tf.text= \(textField.text)"))
        DBGLog(String("tf end editing vid=\(Int(vo.vid)) vo.value=\(vo.value) tf.text=\(textField.text)"))

        if startStr != textField.text {
            vo.value = textField.text ?? ""
            //textField.textColor = [UIColor blackColor];
            //textField.backgroundColor = [UIColor whiteColor];
            NotificationCenter.default.post(name: NSNotification.Name(rtValueUpdatedNotification), object: self)
            startStr = nil
        }

        vo.parentTracker.activeControl = nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // the user pressed the "Done" button, so dismiss the keyboard
        //DBGLog(@"textField done: %@  vid=%d", textField.text,self.vo.vid);
        // [self tfvoFinEdit:textField];  // textFieldDidEndEditing will be called, just dismiss kybd here
        DBGLog(String("tf should return vid=\(Int(vo.vid)) vo.value=\(vo.value) tf.text=\(textField.text)"))

        textField.resignFirstResponder()
        return true
    }

    @objc func selectDoneButton() {
        dtf.resignFirstResponder()
    }

    @objc func selectMinusButton() {
        dtf.text = rTracker_resource.negateNumField(dtf.text)
    }

    override func resetData() {
        if nil != _dtf && !vo.parentTracker.loadingDbData {
            // not self as don't want to instantiate prematurely
            safeDispatchSync({dtf.text = ""})
        }
        vo.useVO = true
    }

    override func voDisplay(_ bounds: CGRect) -> UIView {
        vosFrame = bounds
        // force recreate
        //_dtf = nil
        
        var targD = Date()  // now
        if vo.value == "" {
            if (vo.optDict["nswl"] == "1") /* && ![to hasData] */ {  // nswl = number start with last
                // only if new entry
                let to = vo.parentTracker
                var sql = String(format: "select count(*) from voData where id=%ld and date<%d", Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
                let v = to.toQry2Int(sql:sql)
                if v > 0 {
                    sql = String(format: "select val from voData where id=%ld and date<%d order by date desc limit 1;", Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
                    let r = to.toQry2Str(sql:sql)
                    dtf.textColor = .lightGray
                    dtf.backgroundColor = .darkGray
                    dtf.text = r
                }
                //sql = nil;
            } else if vo.optDict["ahksrc"] == "1" && Int(vo.parentTracker.trackerDate!.timeIntervalSince1970) > self.MyTracker.lastDbDate{
                self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
                // apple healthkit source and trackerDate is newer than last in database (not historical = new record)
                if vo.optDict["ahPrevD"] ?? "0" == "1" {
                    let calendar = Calendar.current
                    targD = calendar.date(byAdding: .day, value: -1, to: targD) ?? targD
                }
                
                let haveUnit = vo.optDict["ahUnit"] != nil
                let cacheKey = "\(vo.optDict["ahSource"]!)-\(Int(targD.timeIntervalSince1970))-\(haveUnit ? vo.optDict["ahUnit"]! : "default")"

                if let cachedValue = Self.healthKitCache[cacheKey] {
                    dtf.text = cachedValue
                    return dtf
                }
                let unit = haveUnit ? HKUnit(from: vo.optDict["ahUnit"]!) : nil
                
                rthk.performHealthQuery(
                    displayName: vo.optDict["ahSource"]!,
                    targetDate: Int(targD.timeIntervalSince1970),
                    specifiedUnit: unit
                ) { results in
                    if results.isEmpty {
                        safeDispatchSync {
                            self.dtf.text = self.noHKdataMsg
                        }
                    } else {
                        // If value is exactly 0.0 for sleep-related metrics, display it as 0.0, not 'No HealthKit data'
                        var result = results.last!
                        
                        if results.count > 1 {
                            if self.vo.optDict["ahAvg"] ?? "1" == "1" {
                                // Compute the average value
                                let totalValue = results.reduce(0.0) { $0 + $1.value }
                                let averageValue = totalValue / Double(results.count)
                                
                                // Get the last date and unit
                                let lastResult = results.last!
                                let lastDate = lastResult.date
                                let lastUnit = lastResult.unit
                                
                                // Create the single element
                                let combinedResult = rtHealthKit.HealthQueryResult(date: lastDate, value: averageValue, unit: lastUnit)
                                
                                // Replace all elements with the single element
                                result = combinedResult
                            } else {
                                DBGWarn("\(self.vo.valueName!) multiple (\(results.count)) results for \(targD) no average can only use last")
                            }
                        }
                        
                        let formattedValue: String
                        
                        if self.vo.optDict["hrsmins"] ?? "0" == "1" {
                            let rv = round(result.value)
                            formattedValue = String(format: "%d:%02d", Int(rv)/60, Int(rv) % 60)
                        } else if result.value.truncatingRemainder(dividingBy: 1) == 0 {
                            // If the value is a whole number, format as an integer
                            formattedValue = String(format: "%.0f", result.value)
                        } else {
                            // Otherwise, format to two decimal places
                            formattedValue = String(format: "%.2f", result.value)
                        }
                        
                        // For sleep-awake categories or others where a zero value is meaningful,
                        // make sure we display it (even if it's 0.0) rather than showing 'No HealthKit data'

                        DispatchQueue.main.async {
                            self.dtf.text = "\(formattedValue)"
                            Self.healthKitCache[cacheKey] = formattedValue
                            self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
                            //DBGLog("\(self.vo.valueName!) dtf= \(formattedValue)")
                        }
                    }
                }
            } else if vo.optDict["otsrc"] == "1" {
                self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
                if let xrslt = vo.vos?.getOTrslt() {
                    self.dtf.text = xrslt
                    /*
                    self.dtf.isEnabled = false
                    self.dtf.textColor = UIColor.black // Much darker than default disabled color
                    self.dtf.backgroundColor = UIColor(white: 0.95, alpha: 1.0) // Light gray background
                     */
                } else {
                    self.dtf.text = ""
                }
            } else {
                dtf.text = ""
            }
        } else {
            DispatchQueue.main.async { [self] in
                dtf.backgroundColor = .secondarySystemBackground
                dtf.textColor = .label
                if vo.optDict["hrsmins"] ?? "0" == "1", let result = Double(vo.value) {
                    let ri = Int(round(result))
                    let formattedValue = String(format: "%d:%02d", ri/60, ri % 60)
                    dtf.text = formattedValue
                } else {
                    dtf.text = vo.value
                }
                if vo.optDict["ahksrc"] == "1" || vo.optDict["otsrc"] == "1" {
                    self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
                }
            }
        }

        return dtf
    }

    override func voTVCellHeight() -> CGFloat {
        return minLabelHeight(super.voTVCellHeight())
    }
    
    private func convertHrsMinsToDecimal(_ timeString: String) -> String {
        // Split the string on colon
        let components = timeString.components(separatedBy: ":")
        
        // If not in HH:MM format, return original string
        guard components.count == 2,
              let hours = Int(components[0].trimmingCharacters(in: .whitespaces)),
              let minutes = Int(components[1].trimmingCharacters(in: .whitespaces)),
              minutes < 60 else {
            return timeString
        }
        
        // Convert to total minutes (e.g., 1:30 -> 90)
        let totalMinutes = (hours * 60) + minutes
        return String(totalMinutes)
    }
    
    override func update(_ instr: String?) -> String {
        // if input string non-empty then return that, otherwise return the current text of the text field
        if let instr, !instr.isEmpty {
            return instr
        }
        
        guard _dtf != nil else {
            return ""
        }
        var text: String = ""
        safeDispatchSync { [self] in
            text = dtf.text ?? ""
        }
        
        if text.isEmpty || text == noHKdataMsg {
            return ""
        }
        
        return vo.optDict["hrsmins"] == "1" ? convertHrsMinsToDecimal(text) : text
    }

    override func voGraphSet() -> [String] {
        return voState.voGraphSetNum()
    }

    // MARK: -
    // MARK: options page

    override func setOptDictDflts() {

        if nil == vo.optDict["nswl"] {
            vo.optDict["nswl"] = NSWLDFLT ? "1" : "0"
        }

        if nil == vo.optDict["ahksrc"] {
            vo.optDict["ahksrc"] = AHKSRCDFLT ? "1" : "0"
        }
        
        if nil == vo.optDict["hrsmins"] {
            vo.optDict["hrsmins"] = HRSMINSDFLT ? "1" : "0"
        }
        if nil == vo.optDict["autoscale"] {
            vo.optDict["autoscale"] = AUTOSCALEDFLT ? "1" : "0"
        }

        if nil == vo.optDict["numddp"] {
            vo.optDict["numddp"] = "\(NUMDDPDFLT)"
        }

        return super.setOptDictDflts()
    }

    override func cleanOptDictDflts(_ key: String) -> Bool {

        let val = vo.optDict[key]
        if nil == val {
            return true
        }

        if ((key == "nswl") && (val == (NSWLDFLT ? "1" : "0")))
            || ((key == "ahksrc") && ((val == (AHKSRCDFLT ? "1" : "0") || (vo.optDict["ahSource"] == nil))))  // unspecified ahSource disallowed
            || ((key == "ahAvg") && (val == (AHAVGDFLT ? "1" : "0")))
            || ((key == "hrsmins") && (val == (HRSMINSDFLT ? "1" : "0")))
            || ((key == "ahPrevD") && (val == (AHPREVDDFLT ? "1" : "0")))
            || ((key == "autoscale") && (val == (AUTOSCALEDFLT ? "1" : "0")))
            || ((key == "numddp") && (Int(val ?? "") ?? 0 == NUMDDPDFLT)) {
            vo.optDict.removeValue(forKey: key)
            return true
        }

        if key == "ahSource" && (vo.optDict["ahksrc"] ?? "0") == "0" {  // clear ahSource value if ah source disabled
            vo.optDict.removeValue(forKey: key)
            return true
        }
        
        return super.cleanOptDictDflts(key)
    }
    
    // Function to get the timestamp for 00:00 on the same day as a given timestamp
    func startOfDay(fromTimestamp timestamp: Int) -> Int {
        // Convert timestamp to Date
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        
        // Get calendar and components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Create a new date with only year, month, and day components (sets time to 00:00:00)
        if let startOfDay = calendar.date(from: components) {
            // Convert back to timestamp (seconds)
            return Int(startOfDay.timeIntervalSince1970)
        }
        
        // Fallback in case of error (should not happen)
        return timestamp
    }

    // MARK: -
    // MARK: HealthKit
    
    func debugHealthKitDateQuery(tracker: trackerObj, valueObjID: Int) {
        let to = tracker
        let vid = valueObjID
        
        DBGLog("Begin debugging HealthKit date query for valueObj ID \(vid)")
        
        // Test 1: Get all dates in trkrData as the base set
        let allDatesSQL = "SELECT date FROM trkrData ORDER BY date DESC"
        let allDates = to.toQry2AryI(sql: allDatesSQL)
        DBGLog("Total trkrData dates: \(allDates.count)")
        
        // Test 2: Dates that already have voData entries for this valueObj
        let withVoDataSQL = """
        SELECT date FROM trkrData 
        WHERE EXISTS (
            SELECT 1 FROM voData 
            WHERE voData.date = trkrData.date 
            AND voData.id = \(vid)
        )
        ORDER BY date DESC
        """
        let withVoData = to.toQry2AryI(sql: withVoDataSQL)
        DBGLog("Dates with existing voData entries: \(withVoData.count)")
        
        // Test 3: Dates that have hkStatus entries with hkData status
        let withHkDataStatusSQL = """
        SELECT date FROM trkrData 
        WHERE EXISTS (
            SELECT 1 FROM voHKstatus 
            WHERE voHKstatus.date = trkrData.date 
            AND voHKstatus.stat = \(hkStatus.hkData.rawValue)
            AND voHKstatus.id = \(vid)
        )
        ORDER BY date DESC
        """
        let withHkDataStatus = to.toQry2AryI(sql: withHkDataStatusSQL)
        DBGLog("Dates with hkData status: \(withHkDataStatus.count)")
        
        // Test 4: Dates with any hkStatus entries (any status)
        let withAnyHkStatusSQL = """
        SELECT date FROM trkrData 
        WHERE EXISTS (
            SELECT 1 FROM voHKstatus 
            WHERE voHKstatus.date = trkrData.date 
            AND voHKstatus.id = \(vid)
        )
        ORDER BY date DESC
        """
        let withAnyHkStatus = to.toQry2AryI(sql: withAnyHkStatusSQL)
        DBGLog("Dates with any hkStatus: \(withAnyHkStatus.count)")
        
        // Test 5: Get the latest date with hkData status
        let latestHkDataSQL = """
        SELECT COALESCE(MAX(date), 0) FROM voHKstatus 
        WHERE id = \(vid) AND stat = \(hkStatus.hkData.rawValue)
        """
        let latestHkData = to.toQry2Int(sql: latestHkDataSQL)
        let latestHkDataDate = Date(timeIntervalSince1970: TimeInterval(latestHkData))
        DBGLog("Latest date with hkData status: \(latestHkData) (\(latestHkDataDate))")
        
        // Test 6: Dates newer than the latest hkData status
        let newerDatesSQL = """
        SELECT date FROM trkrData 
        WHERE date >= \(latestHkData)
        ORDER BY date DESC
        """
        let newerDates = to.toQry2AryI(sql: newerDatesSQL)
        DBGLog("Dates newer than latest hkData date: \(newerDates.count)")
        
        // Break down the original query into its components
        
        // Part 1: Dates that don't have voData
        let noVoDataSQL = """
        SELECT date FROM trkrData 
        WHERE NOT EXISTS (
            SELECT 1 FROM voData 
            WHERE voData.date = trkrData.date 
            AND voData.id = \(vid)
        )
        ORDER BY date DESC
        """
        let noVoData = to.toQry2AryI(sql: noVoDataSQL)
        DBGLog("Dates with no voData: \(noVoData.count)")
        
        // Part 2: Dates that don't have hkStatus.hkData
        let noHkDataStatusSQL = """
        SELECT date FROM trkrData 
        WHERE NOT EXISTS (
            SELECT 1 FROM voHKstatus 
            WHERE voHKstatus.date = trkrData.date 
            AND voHKstatus.stat = \(hkStatus.hkData.rawValue)
            AND voHKstatus.id = \(vid)
        )
        ORDER BY date DESC
        """
        let noHkDataStatus = to.toQry2AryI(sql: noHkDataStatusSQL)
        DBGLog("Dates with no hkData status: \(noHkDataStatus.count)")
        
        // Part 3: Dates with no voData, no hkData status, and newer than latest hkData
        let firstPartSQL = """
        SELECT date FROM trkrData 
        WHERE NOT EXISTS (
            SELECT 1 FROM voData 
            WHERE voData.date = trkrData.date 
            AND voData.id = \(vid)
        )
        AND NOT EXISTS (
            SELECT 1 FROM voHKstatus 
            WHERE voHKstatus.date = trkrData.date 
            AND voHKstatus.stat = \(hkStatus.hkData.rawValue)
            AND voHKstatus.id = \(vid)
        )
        AND date >= \(latestHkData)
        ORDER BY date DESC
        """
        let firstPart = to.toQry2AryI(sql: firstPartSQL)
        DBGLog("Dates matching first part of query (no voData, no hkData status, newer than latest): \(firstPart.count)")
        
        // Part 4: Dates with no hkStatus at all
        let secondPartSQL = """
        SELECT date FROM trkrData 
        WHERE NOT EXISTS (
            SELECT 1 FROM voHKstatus 
            WHERE voHKstatus.date = trkrData.date 
            AND voHKstatus.id = \(vid)
        )
        ORDER BY date DESC
        """
        let secondPart = to.toQry2AryI(sql: secondPartSQL)
        DBGLog("Dates matching second part of query (no hkStatus at all): \(secondPart.count)")
        
        // Show sample dates from each group
        func formatSampleDates(_ dates: [Int], max: Int = 5) -> String {
            guard !dates.isEmpty else { return "[]" }
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let samples = dates.prefix(max).map { date -> String in
                let dateObj = Date(timeIntervalSince1970: TimeInterval(date))
                return "\(date) (\(dateFormatter.string(from: dateObj)))"
            }
            
            return "[\(samples.joined(separator: ", "))\(dates.count > max ? ", ..." : "")]"
        }
        
        DBGLog("Sample dates from first part: \(formatSampleDates(firstPart))")
        DBGLog("Sample dates from second part: \(formatSampleDates(secondPart))")
        
        // Calculate the union of both parts to match the full query
        var combinedSet = Set<Int>()
        for date in firstPart { combinedSet.insert(date) }
        for date in secondPart { combinedSet.insert(date) }
        
        DBGLog("Total unique dates from combined parts: \(combinedSet.count)")
        
        // Determine which part contributes more to the result
        let firstPartOnly = firstPart.filter { !secondPart.contains($0) }
        let secondPartOnly = secondPart.filter { !firstPart.contains($0) }
        let intersection = firstPart.filter { secondPart.contains($0) }
        
        DBGLog("Dates only in first part: \(firstPartOnly.count) \(formatSampleDates(firstPartOnly))")
        DBGLog("Dates only in second part: \(secondPartOnly.count) \(formatSampleDates(secondPartOnly))")
        DBGLog("Dates in both parts: \(intersection.count)")
        
        // Look for dates far in the past or future that might be suspicious
        let now = Int(Date().timeIntervalSince1970)
        let oneYearAgo = now - 365*24*60*60
        let veryOldDates = combinedSet.filter { $0 < oneYearAgo }
        let futureDates = combinedSet.filter { $0 > now }
        
        DBGLog("Very old dates (>1 year): \(veryOldDates.count) \(formatSampleDates(Array(veryOldDates)))")
        DBGLog("Future dates: \(futureDates.count) \(formatSampleDates(Array(futureDates)))")
        
        DBGLog("End debugging HealthKit date query")
    }
    
    override func loadHKdata(forDate date: Int?, dispatchGroup: DispatchGroup?) {
        // loads into database, not for current tracker record
        let to = vo.parentTracker

        guard let srcName = vo.optDict["ahSource"] else {
            DBGErr("no ahSource specified for valueObj \(vo.valueName ?? "no name")")
            return
        }

        dispatchGroup?.enter()  // wait for getHealthkitDates processing overall
        
        
        // 1st determine if hk has date entries this tracker does not, if so identify and add them
        
        // Create a separate DispatchGroup for getHealthKitDates processing
        let hkDispatchGroup = DispatchGroup()

        hkDispatchGroup.enter()
        
        let sql = "select max(date) from voHKstatus where id = \(Int(vo.vid)) and stat = \(hkStatus.hkData.rawValue)"
        var lastDate = to.toQry2Int(sql: sql)
        if let specifiedDate = date {
            lastDate = startOfDay(fromTimestamp:specifiedDate)
            DBGLog("specifiedDate is \(specifiedDate)  \(Date(timeIntervalSince1970: TimeInterval(specifiedDate)))")
        }
        DBGLog("lastDate is \(Date(timeIntervalSince1970:TimeInterval(lastDate)))")
        rthk.getHealthKitDates(for: srcName, lastDate: lastDate) { hkDates in
            DBGLog("hk dates for \(srcName), ahAvg is \(self.vo.optDict["ahAvg"] ?? "1")")

            var newDates: [TimeInterval]
            if self.vo.optDict["ahAvg"] ?? "1" == "1" {
                newDates = to.mergeDates(inDates: hkDates)
            } else {
                newDates = hkDates
            }
            
            // Insert the new dates into trkrData
            // trkrData is 'on conflict replace'
            // only update an existing row if the new minpriv is lower
            let priv = max(MINPRIV, self.vo.vpriv)  // priv needs to be at least minpriv if vpriv = 0
            for newDate in newDates {
                // fix minpriv issues at end below
                let sql = "insert into trkrData (date, minpriv) values (\(Int(newDate)), \(priv))"
                to.toExecSql(sql: sql)
            }
            
            DBGLog("Inserted \(newDates.count) new dates into trkrData.")
            
            hkDispatchGroup.leave() // Leave the group after insertion is complete
        }

        // 2nd log hk data entries for each date in voData and hkStatus
        
        // Wait for getHealthKitDates processing to complete before proceeding
        hkDispatchGroup.notify(queue: .main) { [self] in
            DBGLog("HealthKit dates processed, continuing with loadHKdata.")
            
            // Fetch dates from trkrData for processing
            // will update where we don't have data sourced from healthkit already
            // since the last time valid data was loaded for this vid
            var sql = """
            SELECT trkrData.date
            FROM trkrData
            WHERE (NOT EXISTS (
                SELECT 1
                FROM voData
                WHERE voData.date = trkrData.date
                  AND voData.id = \(Int(vo.vid))
            )
            AND NOT EXISTS (
                SELECT 1
                FROM voHKstatus
                WHERE voHKstatus.date = trkrData.date
                  AND voHKstatus.stat = \(hkStatus.hkData.rawValue)
                  AND voHKstatus.id = \(Int(vo.vid))
            )
            AND trkrData.date >= (
                SELECT COALESCE(MAX(date), 0)
                FROM voHKstatus
                WHERE id = \(Int(vo.vid))
                  AND stat = \(hkStatus.hkData.rawValue)
            )) OR NOT EXISTS (
                SELECT 1 FROM voHKstatus
                WHERE voHKstatus.date = trkrData.date
                  AND voHKstatus.id = \(Int(vo.vid))
            );
            """
            // get dates where
            //   do not have voData and hkStatus not hkData and only looking at new data since last update
            //   or have trkrData entry but no hkStatus entry at all (refreshing current record or missing data)
            
            let dateSet = to.toQry2AryI(sql: sql)
            
            DBGLog("Query complete, count is \(dateSet.count)")
            //debugHealthKitDateQuery(tracker: to, valueObjID: vo.vid)
            
            let calendar = Calendar.current
            let secondHKDispatchGroup = DispatchGroup()
            for dat in dateSet.sorted() {  // .sorted() is just to help debugging
                let ddat = Date(timeIntervalSince1970: TimeInterval(dat))
                let components = calendar.dateComponents([.hour, .minute, .second], from: ddat)
                
                if vo.optDict["ahAvg"] ?? "0" == "1" && (components.hour != 12 || components.minute != 0 || components.second != 0) {
                    continue // Skip to the next entry if ahAvg and the time is not 12:00:00 noon
                }
                
                let prevDate = Int((calendar.date(byAdding: .day, value: -1, to: ddat))!.timeIntervalSince1970)
                
                secondHKDispatchGroup.enter() // Enter the group for each query

                let targD = Date(timeIntervalSince1970: TimeInterval(dat))
                var unit: HKUnit? = nil
                if let unitString = vo.optDict["ahUnit"] {
                    unit = HKUnit(from: unitString)
                }

                
                //DBGLog("calling phq \(srcName) date \(ddat)  prevD \(self.vo.optDict["ahPrevD"] ?? "nil") prevDate= \(prevDate)")
                
                rthk.performHealthQuery(
                    displayName: srcName,
                    targetDate: self.vo.optDict["ahPrevD"] ?? "0" == "1" ? prevDate : dat,
                    specifiedUnit: unit
                ) { results in
                    if results.isEmpty {
                        if self.vo.optDict["ahPrevD"] ?? "0" == "1" {
                            DBGLog("No results found for postDate \(prevDate).")
                        } else {
                            DBGLog("No results found - \(self.vo.valueName!) for \(targD).")
                        }
                        let sql = "insert into voHKstatus (id, date, stat) values (\(self.vo.vid), \(dat), \(hkStatus.noData.rawValue))"
                        to.toExecSql(sql: sql)
                    } else {
                        for result in results {
                            DBGLog("\(results.count) entries - \(self.vo.valueName!) TargetDate: \(targD) results - Date: \(result.date), Value: \(result.value), Unit: \(result.unit)")
                            break
                        }
                        
                        var result = results.last!
                        
                        /*
                        let rdate = result.date
                        // This line will help you set a conditional breakpoint
                        if Calendar.current.isDate(rdate, inSameDayAs: DateComponents(calendar: .current, year: 2025, month: 3, day: 23).date!) {
                            // Set your breakpoint on this line
                            DBGLog("Breakpoint will trigger here")
                        }
                         */
                        
                        if results.count > 1 {
                            if self.vo.optDict["ahAvg"] ?? "1" == "1" {
                                // Compute the average value
                                let totalValue = results.reduce(0.0) { $0 + $1.value }
                                let averageValue = totalValue / Double(results.count)
                                
                                // Get the last date and unit
                                let lastResult = results.last!
                                let lastDate = lastResult.date
                                let lastUnit = lastResult.unit
                                
                                // Create the single element
                                let combinedResult = rtHealthKit.HealthQueryResult(date: lastDate, value: averageValue, unit: lastUnit)
                                
                                // Replace all elements with the single element
                                result = combinedResult
                            } else {
                                DBGWarn("\(self.vo.valueName!) multiple (\(results.count)) results for \(targD) no average can only use last")
                            }
                        }
                        
                        let formattedValue: String
                        if result.value.truncatingRemainder(dividingBy: 1) == 0 {
                            // If the value is a whole number, format as an integer
                            formattedValue = String(format: "%.0f", result.value)
                        } else {
                            // Otherwise, format to two decimal places
                            formattedValue = String(format: "%.2f", result.value)
                        }

                        if false && self.vo.optDict["ahPrevD"] ?? "0" == "1" {  // if data is for previous day, set to next day, unless that is in future from today
                            var ddat = Date(timeIntervalSince1970: TimeInterval(dat))
                            if !calendar.isDateInToday(ddat) {
                                ddat = calendar.date(byAdding: .day, value: 1, to: ddat)!
                                let nextdat = Int(ddat.timeIntervalSince1970)
                                
                                var sql = "insert into voData (id, date, val) values (\(self.vo.vid), \(nextdat), \(formattedValue))"
                                to.toExecSql(sql: sql)
                                sql = "insert into voHKstatus (id, date, stat) values (\(self.vo.vid), \(nextdat), \(hkStatus.hkData.rawValue))"
                                to.toExecSql(sql: sql)
                                
                                // as this is going into day+1, possibly day+1 not in trkrdata but should be, and day-1 should be removed - done below
                                sql = "insert into trkrData (date, minpriv) values (\(nextdat), \(self.vo.vpriv))"

                                to.toExecSql(sql: sql)
                            }
                            // no insert if ahPrevD and dat is in today
                        } else {
                            var sql = "insert into voData (id, date, val) values (\(self.vo.vid), \(dat), \(formattedValue))"
                            to.toExecSql(sql: sql)
                            sql = "insert into voHKstatus (id, date, stat) values (\(self.vo.vid), \(dat), \(hkStatus.hkData.rawValue))"
                            to.toExecSql(sql: sql)
                        }
                    }

                    // Update progress
                    if let delegate = to.refreshDelegate, (date == nil || date == 0)  {
                        // Only update progress during a full refresh (indicated by delegate and not a specific date)
                        DispatchQueue.main.async {
                            delegate.updateFullRefreshProgress(step: 1, phase: nil)
                        }
                    }
                    
                    secondHKDispatchGroup.leave() // Leave the group after this query is processed
                }
            }
            
            secondHKDispatchGroup.notify(queue: .main) {[self] in
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
                DBGLog("Done loadHKdata with \(dateSet.count) records.")
                dispatchGroup?.leave()  // done with enter before getHealthkitDates processing overall
            }
        }
    }

    override func clearHKdata(forDate date: Int? = nil) {
        let to = vo.parentTracker
        var sql = ""
        if let specificDate = date {
            DBGLog("checking date \(specificDate) \(Date(timeIntervalSince1970: TimeInterval(specificDate)))")
            let haveHkData = to.toQry2Int(sql: "select 1 from voHKstatus where id = \(vo.vid) and date = \(specificDate)")
            if haveHkData == 1 {
                to.toExecSql(sql: "delete from voData where id = \(vo.vid) and date = \(specificDate)")
                to.toExecSql(sql: "delete from voHKstatus where id = \(vo.vid) and date = \(specificDate)")
            }
        } else {
            sql = "delete from voData where (id, date) in (select id, date from voHKstatus where id = \(vo.vid))"
            to.toExecSql(sql: sql)
            sql = "delete from voHKstatus where id = \(vo.vid)"
            to.toExecSql(sql: sql)
        }
    }
    
    @objc func configAppleHealthView() {
        DBGLog("config Apple Health view")
        
        let hostingController = UIHostingController(
            rootView: ahViewController(
                selectedChoice: vo.optDict["ahSource"],
                selectedUnitString: vo.optDict["ahUnit"],
                ahAvg: vo.optDict["ahAvg"] ?? "1" == "1",
                ahPrevD: vo.optDict["ahPrevD"] ?? "0" == "1",
                ahHrsMin: vo.optDict["hrsmins"] ?? "0" == "1",
                onDismiss: { [self] updatedChoice,updatedUnit, updatedAhAvg, updatedAhPrevD, updatedAhHrsMin  in
                    vo.optDict["ahSource"] = updatedChoice
                    vo.optDict["ahUnit"] = updatedUnit
                    vo.optDict["ahAvg"] = updatedAhAvg ? "1" : "0"
                    vo.optDict["ahPrevD"] = updatedAhPrevD ? "1" : "0"
                    vo.optDict["hrsmins"] = updatedAhHrsMin ? "1" : "0"
                    if let button = ctvovcp?.scroll.subviews.first(where: { $0 is UIButton && $0.accessibilityIdentifier == "configtv_ahSelBtn" }) as? UIButton {
                        DBGLog("ahSelect view returned: \(updatedChoice ?? "nil") \(updatedUnit ?? "nil") optDict is \(vo.optDict["ahSource"] ?? "nil")  \(vo.optDict["ahUnit"] ?? "nil")")
                        DispatchQueue.main.async {
                            button.setTitle(self.vo.optDict["ahSource"] ?? "Configure", for: .normal)
                            button.sizeToFit()
                        }
                    }
                    //DBGLog("ahSelect view returned: \(updatedChoice) optDict is \(vo.optDict["ahSource"] ?? "nil")")
                }
            )
        )
        hostingController.modalTransitionStyle = .flipHorizontal
        hostingController.modalPresentationStyle = .automatic
        
        // Present the hosting controller
        ctvovcp?.present(hostingController, animated: true)
    }
    @objc func forwardToConfigOtherTrackerSrcView() {
        ctvovcp?.configOtherTrackerSrcView()
    }
    
    override func voDrawOptions(_ ctvovc: configTVObjVC) {
        ctvovcp = ctvovc  // save reference so can display config gui
        
        var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)

        var labframe = ctvovc.configLabel("Start with last saved value: ", frame: frame, key: "swlLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "swlBtn",
            state: vo.optDict["nswl"] == "1",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height

        frame = ctvovc.yAutoscale(frame)

        //frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN

        labframe = ctvovc.configLabel("graph decimal places (-1 for auto): ", frame: frame, key: "numddpLab", addsv: true)

        frame.origin.x += labframe.size.width + SPACE
        let tfWidth = "99999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovc.lfHeight)

        frame = ctvovc.configTextField(
            frame,
            key: "numddpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(NUMDDPDFLT)",
            text: vo.optDict["numddp"],
            addsv: true)


        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        labframe = ctvovc.configLabel("Apple Health source: ", frame: frame, key: "ahsLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "ahsBtn",
            state: vo.optDict["ahksrc"] == "1",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        
        frame = ctvovc.configActionBtn(frame, key: "ahSelBtn", label: vo.optDict["ahSource"] ?? "Configure", target: self, action: #selector(configAppleHealthView))
        ctvovc.switchUpdate(okey: "ahksrc", newState: vo.optDict["ahksrc"] == "1")
        
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        labframe = ctvovc.configLabel("Other Tracker source: ", frame: frame, key: "otsLab", addsv: true)
        frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

        frame = ctvovc.configSwitch(
            frame,
            key: "otsBtn",
            state: vo.optDict["otsrc"] == "1",
            addsv: true)

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        let source = self.vo.optDict["otTracker"] ?? ""
        let value = self.vo.optDict["otValue"] ?? ""
        let str = (!source.isEmpty && !value.isEmpty) ? "\(source):\(value)" : "Configure"
        
        frame = ctvovc.configActionBtn(frame, key: "otSelBtn", label: str, target: self, action: #selector(forwardToConfigOtherTrackerSrcView))
        ctvovc.switchUpdate(okey: "otsrc", newState: vo.optDict["otsrc"] == "1")
        
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        
        labframe = ctvovc.configLabel("Other options:", frame: frame, key: "noLab", addsv: true)

        ctvovc.lasty = frame.origin.y + labframe.size.height + MARGIN

        super.voDrawOptions(ctvovc)
    }

    /*
    - (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

        [self transformVO_num:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];

    }
    */

    override func newVOGD() -> vogd {
        return vogd(vo).initAsNum(vo)
    }
}
