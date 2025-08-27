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
        
        if vo.optDict["ahksrc"] == "1" || vo.optDict["otsrc"] == "1" {
            textField.placeholder = "<no data>"
        } else {
            textField.placeholder = "<enter number>"
        }
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
        if nil != _dtf {   // && !vo.parentTracker.loadingDbData
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
                let calendar = Calendar.current
                let semaphore = DispatchSemaphore(value: 0)
                var healthKitResult: String?
                
                processHealthQuery(
                    timestamp: Int(targD.timeIntervalSince1970),
                    srcName: vo.optDict["ahSource"]!,
                    frequency: vo.optDict["ahFrequency"] ?? "daily",
                    calendar: calendar
                ) { [weak self] result in
                    if let result = result {
                        // Handle hours:minutes formatting if needed
                        if self?.vo.optDict["hrsmins"] ?? "0" == "1", let numValue = Double(result) {
                            let rv = Int(round(numValue))
                            healthKitResult = String(format: "%d:%02d", rv/60, rv % 60)
                        } else {
                            healthKitResult = result
                        }
                        Self.healthKitCache[cacheKey] = healthKitResult!
                    } else {
                        healthKitResult = self?.noHKdataMsg
                    }
                    semaphore.signal()
                }
                
                semaphore.wait()  // warning about lower QoS wait is necessary or can return empty text field, but need to see the value
                
                // Apply the result synchronously on main thread
                dtf.text = healthKitResult
                self.vo.vos?.addExternalSourceOverlay(to: self.dtf)
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
        
        if nil == vo.optDict["ahFrequency"] {
            vo.optDict["ahFrequency"] = AHFREQUENCYDFLT
        }
        
        if nil == vo.optDict["ahTimeFilter"] {
            vo.optDict["ahTimeFilter"] = AHTIMEFILTERDFLT
        }
        
        // rtm think both of these are wrong with sleep special handling
        if nil == vo.optDict["ahAggregation"] {
            vo.optDict["ahAggregation"] = AHAGGREGATIONDFLT
            /*
            // For sleep data, use sum aggregation by default since sleep segments should be added together
            if let ahSource = vo.optDict["ahSource"], ahSource.hasPrefix("Sleep") {
                vo.optDict["ahAggregation"] = "sum"
            } else {
                vo.optDict["ahAggregation"] = AHAGGREGATIONDFLT
            }
             */
        }
        
        if nil == vo.optDict["ahPrevD"] {
            vo.optDict["ahPrevD"] = AHPREVDDFLT ? "1" : "0"
            /*
            // Sleep data needs ahPrevD=1 to query previous day's sleep data
            if let ahSource = vo.optDict["ahSource"], ahSource.hasPrefix("Sleep") {
                vo.optDict["ahPrevD"] = "1"
            } else {
                vo.optDict["ahPrevD"] = AHPREVDDFLT ? "1" : "0"
            }
             */
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
            || ((key == "ahFrequency") && (val == AHFREQUENCYDFLT))
            || ((key == "ahTimeFilter") && (val == AHTIMEFILTERDFLT))
            || ((key == "ahAggregation") && (val == AHAGGREGATIONDFLT))
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

        // Compute queryConfig and hkObjectType here instead of in getHealthKitDates
        let calendar = Calendar.current
        guard let queryConfig = healthDataQueries.first(where: { $0.displayName == srcName }),
              let hkObjectType = queryConfig.identifier.hasPrefix("HKQuantityTypeIdentifier") ?
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: queryConfig.identifier)) :
                HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: queryConfig.identifier)) else {
            DBGLog("No HealthKit identifier found for display name: \(srcName)")
            dispatchGroup?.leave()
            return
        }

        dispatchGroup?.enter()  // wait for getHealthkitDates processing overall
        
        
        // 1st determine if hk has date entries this tracker does not, if so identify and add them
        
        // Create a separate DispatchGroup for getHealthKitDates processing
        let hkDispatchGroup = DispatchGroup()

        hkDispatchGroup.enter()

        var specifiedStartDate: Date? = nil
        var specifiedEndDate: Date? = nil

        // if specified date, use it for start and end because single date refresh
        // if database entries, use the last one as startDate and test if start is after hk data
        // if no database entries, then wiped so full refresh
        if let specifiedDate = date {
            // For single date refresh, query from start of day to end of that specific date
            let startDate = Date(timeIntervalSince1970: TimeInterval(specifiedDate))
            specifiedStartDate = startDate
            specifiedEndDate = calendar.dateInterval(of: .day, for: startDate)?.end ??
                calendar.date(byAdding: .day, value: 1, to: startDate)
            DBGLog("Single date refresh: querying from \(specifiedStartDate?.description ?? "nil") to \(specifiedEndDate?.description ?? "nil")")
        } else {
            let sql = "select max(date) from voHKstatus where id = \(Int(vo.vid)) and stat = \(hkStatus.hkData.rawValue)" 
            let lastDbDate = to.toQry2Int(sql: sql)
            if lastDbDate > 0 {
                specifiedStartDate = Date(timeIntervalSince1970: TimeInterval(lastDbDate))
            }
        }
        DBGLog("Using specified start date: \(specifiedStartDate?.description ?? "nil") and end date: \(specifiedEndDate?.description ?? "nil")")
        #if DEBUGLOG
        let startTime = CFAbsoluteTimeGetCurrent()
        #endif
        
        // 
        rthk.sampleDateRange(for: hkObjectType as HKSampleType, useStartDate: specifiedStartDate, useEndDate: specifiedEndDate) { [self] hkStartDate, hkEndDate in
            // Calculate appropriate end date

            DBGLog("querying from \(hkStartDate?.description ?? "nil") to \(hkEndDate?.description ?? "nil")")
            
            guard let hkStartDate = hkStartDate, let hkEndDate = hkEndDate else {
                DBGLog("no hk data: start or end date is nil")
                hkDispatchGroup.leave()
                return
            }
            
            // Check if start date is after end date - invalid range
            if hkStartDate > hkEndDate {
                DBGLog("no new hk data: start date \(hkStartDate) is after end date \(hkEndDate)")
                hkDispatchGroup.leave()
                return
            }
            
            // Calculate number of date windows needed for chunked processing
            let daysBetween = calendar.dateComponents([.day], from: hkStartDate, to: hkEndDate).day ?? 0
            let numberOfWindows = (daysBetween + hkDateWindow - 1) / hkDateWindow // Round up
            
            to.refreshDelegate?.updateFullRefreshProgress(step: 0, phase: "loading dates for \(self.vo.valueName ?? "unknown")", totalSteps: numberOfWindows, threshold: 2)

            
            var allHKDates: [TimeInterval] = []
            let chunkDispatchGroup = DispatchGroup()
            
            // Process date ranges in chunks
            for windowIndex in 0..<numberOfWindows {
                chunkDispatchGroup.enter()
                
                let windowStartDate = calendar.date(byAdding: .day, value: windowIndex * hkDateWindow, to: hkStartDate) ?? hkStartDate
                let windowEndDate: Date
                if windowIndex == numberOfWindows - 1 {
                    // Last window - use actual end date
                    windowEndDate = hkEndDate
                } else {
                    // Use window size
                    windowEndDate = calendar.date(byAdding: .day, value: (windowIndex + 1) * hkDateWindow, to: hkStartDate) ?? hkEndDate
                }
                
                DBGLog("Processing HealthKit date window \(windowIndex + 1)/\(numberOfWindows): \(windowStartDate) to \(windowEndDate)")
                
                rthk.getHealthKitDates(queryConfig: queryConfig, hkObjectType: hkObjectType as HKSampleType, startDate: windowStartDate, endDate: windowEndDate) { hkDates in
                    allHKDates.append(contentsOf: hkDates)
                    to.refreshDelegate?.updateFullRefreshProgress(step: 1)
                    // Small yield to give main thread breathing room
                    Thread.sleep(forTimeInterval: 0.01)
                    chunkDispatchGroup.leave()
                }
            }
            
            // Wait for all chunks to complete, then process combined results
            chunkDispatchGroup.notify(queue: .main) { [self] in
                #if DEBUGLOG
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                DBGLog("HKPROFILE: chunked getHealthKitDates for \(srcName) (vid: \(self.vo.vid)) took \(String(format: "%.3f", timeElapsed))s, found \(allHKDates.count) dates")
                #endif

                var newDates: [TimeInterval]
                let frequency = self.vo.optDict["ahFrequency"] ?? "daily"
                
                if frequency == "daily" {
                    // Use original daily logic
                    newDates = to.mergeDates(inDates: allHKDates)
                } else {
                    // Generate time slots based on frequency
                    newDates = to.generateTimeSlots(from: allHKDates, frequency: frequency)
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
        }

        // 2nd log hk data entries for each date in voData and hkStatus
        
        // Wait for getHealthKitDates processing to complete before proceeding
        hkDispatchGroup.notify(queue: .main) { [self] in
            DBGLog("HealthKit dates for \(srcName) processed, continuing with loadHKdata.")
            // Fetch dates from trkrData for processing
            // will update where we don't have data sourced from healthkit already
            // since the last time valid data was loaded for this vid
            var sql = """
            SELECT trkrData.date
            FROM trkrData
            WHERE NOT EXISTS (
                SELECT 1 FROM voData 
                WHERE voData.date = trkrData.date 
                AND voData.id = \(Int(vo.vid))
            )
            AND NOT EXISTS (
                SELECT 1 FROM voHKstatus 
                WHERE voHKstatus.date = trkrData.date 
                AND voHKstatus.id = \(Int(vo.vid))
            );
            """
            // Process only dates that have not been attempted for HealthKit processing yet
            // AND have no manually entered data for this specific valueObj
            
            // For single date refresh, add date filter to only process the specified date
            if let specifiedDate = date {
                let specifiedTimestamp = startOfDay(fromTimestamp: specifiedDate)
                // Simply add the date filter as an AND condition - this will limit results effectively
                sql += " AND trkrData.date = \(specifiedTimestamp)"
                DBGLog("Added single date filter for timestamp: \(specifiedTimestamp) (\(Date(timeIntervalSince1970: TimeInterval(specifiedTimestamp))))")
            }
            
            let dateSet = to.toQry2AryI(sql: sql)
            
            DBGLog("dates to process for \(srcName) (vid: \(vo.vid)) Query complete, count is \(dateSet.count)")
            #if DEBUGLOG
            if dateSet.count > 10 {
                DBGLog("First 10 dates to process: \(Array(dateSet.prefix(10)).map { Date(timeIntervalSince1970: TimeInterval($0)) })")
                
                // Show max hkData date for this valueObj for debugging
                let maxHKDataSQL = "select max(date) from voHKstatus where id = \(Int(vo.vid)) and stat = \(hkStatus.hkData.rawValue)"
                let maxHKDataDate = to.toQry2Int(sql: maxHKDataSQL)
                DBGLog("Max hkData date for vid \(vo.vid): \(Date(timeIntervalSince1970: TimeInterval(maxHKDataDate)))")
                
                // Additional debug info for single date refresh
                if let specifiedDate = date {
                    let specifiedTimestamp = startOfDay(fromTimestamp: specifiedDate)
                    
                    // Check if there's a trkrData entry for this specific date
                    let trkrDataCheckSQL = "SELECT COUNT(*) FROM trkrData WHERE date = \(specifiedTimestamp)"
                    let trkrDataCount = to.toQry2Int(sql: trkrDataCheckSQL)
                    DBGLog("trkrData entries for specified date \(Date(timeIntervalSince1970: TimeInterval(specifiedTimestamp))): \(trkrDataCount)")
                    
                    // Check if there's existing voData for this valueObj and date
                    let voDataCheckSQL = "SELECT COUNT(*) FROM voData WHERE id = \(Int(vo.vid)) AND date = \(specifiedTimestamp)"
                    let voDataCount = to.toQry2Int(sql: voDataCheckSQL)
                    DBGLog("voData entries for vid \(vo.vid) on specified date: \(voDataCount)")
                    
                    // Check if there's existing voHKstatus for this valueObj and date
                    let hkStatusCheckSQL = "SELECT COUNT(*) FROM voHKstatus WHERE id = \(Int(vo.vid)) AND date = \(specifiedTimestamp)"
                    let hkStatusCount = to.toQry2Int(sql: hkStatusCheckSQL)
                    DBGLog("voHKstatus entries for vid \(vo.vid) on specified date: \(hkStatusCount)")
                }
            }
            #endif

            to.refreshDelegate?.updateFullRefreshProgress(step: 0, phase: "loading data for \(self.vo.valueName ?? "unknown")", totalSteps: dateSet.count, threshold: hqDateWindow)

            let calendar = Calendar.current
            let secondHKDispatchGroup = DispatchGroup()
            let frequency = self.vo.optDict["ahFrequency"] ?? "daily"
            
            for dat in dateSet.sorted() {  // .sorted() is just to help debugging
                // Look up the query configuration to determine aggregationType
                guard healthDataQueries.first(where: { $0.displayName == srcName }) != nil else {
                    DBGErr("No query configuration found for displayName: \(srcName)")
                    continue
                }
                
                // Use unified processHealthQuery for all cases
                secondHKDispatchGroup.enter() // Enter the group for each query
                self.processHealthQuery(
                    timestamp: dat,
                    srcName: srcName,
                    frequency: frequency,
                    calendar: calendar,
                    dispatchGroup: secondHKDispatchGroup
                ) { [weak self] result in
                    let to = self?.vo.parentTracker
                    
                    if let result = result {
                        // Data found - insert into database
                        let sql = "insert into voData (id, date, val) values (\(self?.vo.vid ?? 0), \(dat), \(result))"
                        to?.toExecSql(sql: sql)
                        let statusSql = "insert into voHKstatus (id, date, stat) values (\(self?.vo.vid ?? 0), \(dat), \(hkStatus.hkData.rawValue))"
                        to?.toExecSql(sql: statusSql)
                    } else {
                        // No data found - record no data status
                        let sql = "insert into voHKstatus (id, date, stat) values (\(self?.vo.vid ?? 0), \(dat), \(hkStatus.noData.rawValue))"
                        to?.toExecSql(sql: sql)
                    }
                    
                    // Update progress for each health query processed
                    to?.refreshDelegate?.updateFullRefreshProgress(step: 1)
                }
            }
            
            // wait on all processHealthQuery's to complete
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
                DBGLog("Done loadHKdata for \(srcName) with \(dateSet.count) records.")
                
                dispatchGroup?.leave()  // done with enter before getHealthkitDates processing overall
            }
        }
    }

    override func clearHKdata(forDate date: Int? = nil) {
        // Only clear HK data for valueObjs that are configured as HealthKit sources
        guard vo.optDict["ahksrc"] == "1" else {
            return
        }
        
        let to = vo.parentTracker
        var sql = ""
        if let specificDate = date {
            DBGLog("checking date \(specificDate) \(Date(timeIntervalSince1970: TimeInterval(specificDate)))")
            to.toExecSql(sql: "delete from voData where id = \(vo.vid) and date = \(specificDate)")
            to.toExecSql(sql: "delete from voHKstatus where id = \(vo.vid) and date = \(specificDate)")
            
            // Clear cache entries for this specific date
            if let ahSource = vo.optDict["ahSource"] {
                let calendar = Calendar.current
                let targetDate = Date(timeIntervalSince1970: TimeInterval(specificDate))
                
                // Clear cache for the actual date
                let haveUnit = vo.optDict["ahUnit"] != nil
                let unitStr = haveUnit ? vo.optDict["ahUnit"]! : "default"
                let cacheKey = "\(ahSource)-\(specificDate)-\(unitStr)"
                Self.healthKitCache.removeValue(forKey: cacheKey)
                DBGLog("Cleared cache key: \(cacheKey)")
                
                // If ahPrevD is enabled, also clear cache for previous day since that's what gets queried
                if vo.optDict["ahPrevD"] ?? "0" == "1" {
                    if let prevDate = calendar.date(byAdding: .day, value: -1, to: targetDate) {
                        let prevDateTimestamp = Int(prevDate.timeIntervalSince1970)
                        let prevCacheKey = "\(ahSource)-\(prevDateTimestamp)-\(unitStr)"
                        Self.healthKitCache.removeValue(forKey: prevCacheKey)
                        DBGLog("Cleared prevD cache key: \(prevCacheKey)")
                    }
                }
            }
        } else {
            sql = "delete from voData where (id, date) in (select id, date from voHKstatus where id = \(vo.vid))"
            to.toExecSql(sql: sql)
            sql = "delete from voHKstatus where id = \(vo.vid)"
            to.toExecSql(sql: sql)
            
            // Clear all cache entries for this value object's ahSource
            if let ahSource = vo.optDict["ahSource"] {
                let keysToRemove = Self.healthKitCache.keys.filter { $0.hasPrefix("\(ahSource)-") }
                for key in keysToRemove {
                    Self.healthKitCache.removeValue(forKey: key)
                }
                DBGLog("Cleared \(keysToRemove.count) cache entries for ahSource: \(ahSource)")
            }
        }
    }
    
    @objc func configAppleHealthView() {
        DBGLog("config Apple Health view")
        
        let hostingController = UIHostingController(
            rootView: ahViewController(
                selectedChoice: vo.optDict["ahSource"],
                selectedUnitString: vo.optDict["ahUnit"],
                ahPrevD: vo.optDict["ahPrevD"] ?? "0" == "1",
                ahHrsMin: vo.optDict["hrsmins"] ?? "0" == "1",
                ahFrequency: vo.optDict["ahFrequency"] ?? AHFREQUENCYDFLT,
                ahTimeFilter: vo.optDict["ahTimeFilter"] ?? AHTIMEFILTERDFLT,
                ahAggregation: vo.optDict["ahAggregation"] ?? AHAGGREGATIONDFLT,
                onDismiss: { [self] updatedChoice,updatedUnit, updatedAhPrevD, updatedAhHrsMin, updatedAhFrequency, updatedAhTimeFilter, updatedAhAggregation  in
                    vo.optDict["ahSource"] = updatedChoice
                    vo.optDict["ahUnit"] = updatedUnit
                    vo.optDict["ahPrevD"] = updatedAhPrevD ? "1" : "0"
                    vo.optDict["hrsmins"] = updatedAhHrsMin ? "1" : "0"
                    vo.optDict["ahFrequency"] = updatedAhFrequency
                    vo.optDict["ahTimeFilter"] = updatedAhTimeFilter
                    vo.optDict["ahAggregation"] = updatedAhAggregation
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
    
    // MARK: - Health Query Processing
    
    private func processHealthQuery(
        timestamp: Int,
        srcName: String,
        frequency: String,
        calendar: Calendar,
        dispatchGroup: DispatchGroup? = nil,
        completion: @escaping (String?) -> Void
    ) {
        // Look up the query configuration
        guard let queryConfig = healthDataQueries.first(where: { $0.displayName == srcName }) else {
            DBGErr("No query configuration found for displayName: \(srcName)")
            completion(nil)
            dispatchGroup?.leave()
            return
        }
        
        // Calculate base start date from timestamp
        let baseDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let startDate: Date
        
        // Handle ahPrevD option
        if vo.optDict["ahPrevD"] ?? "0" == "1" {
            startDate = calendar.date(byAdding: .day, value: -1, to: baseDate) ?? baseDate
        } else {
            startDate = baseDate
        }
        
        // Calculate endDate for high-frequency processing
        let endDate = calculateEndDate(from: startDate, frequency: frequency, queryConfig: queryConfig)
        
        // Prepare unit
        var unit: HKUnit? = nil
        if let unitString = vo.optDict["ahUnit"] {
            unit = HKUnit(from: unitString)
        }
        
        // Make the query
        rthk.performHealthQuery(
            displayName: srcName,
            startDate: startDate,
            endDate: endDate,
            specifiedUnit: unit
        ) { allResults in
            // Always apply time filtering and aggregation
            let filteredResults = self.applyTimeFilter(results: allResults, timeFilter: self.vo.optDict["ahTimeFilter"] ?? "all_day")
            let aggregatedResult = self.applyAggregation(results: filteredResults, aggregation: self.vo.optDict["ahAggregation"] ?? "avg")
            
            if let result = aggregatedResult {
                let formattedValue = self.formatHealthKitValue(result.value)
                completion(formattedValue)
            } else {
                completion(nil)
            }
            
            dispatchGroup?.leave()
        }
    }
    
    private func calculateEndDate(from startDate: Date, frequency: String, queryConfig: HealthDataQuery) -> Date? {
        // Return nil for daily/.groupedByNight (single point queries)
        guard queryConfig.aggregationType == .highFrequency else { return nil }
        
        let intervalHours: Int
        switch frequency {
        case "every_1h": intervalHours = 1
        case "every_2h": intervalHours = 2
        case "every_4h": intervalHours = 4
        case "every_6h": intervalHours = 6
        case "every_8h": intervalHours = 8
        case "twice_daily": intervalHours = 12
        default: return nil // daily
        }
        
        return Calendar.current.date(byAdding: .hour, value: intervalHours, to: startDate)
    }
    
    
    private func applyTimeFilter(results: [rtHealthKit.HealthQueryResult], timeFilter: String) -> [rtHealthKit.HealthQueryResult] {
        return results.filter { result in
            // Convert HealthKit UTC date to local time before filtering
            let localDate = result.date.toLocalTime()
            let localHour = Calendar.current.component(.hour, from: localDate)
            
            switch timeFilter {
            case "morning": return localHour >= 6 && localHour < 10
            case "daytime": return localHour >= 10 && localHour < 20
            case "evening": return localHour >= 20 && localHour < 23
            case "sleep_hours": return localHour >= 23 || localHour < 6
            case "wake_hours": return localHour >= 6 && localHour < 23
            default: return true // "all_day"
            }
        }
    }
    
    private func applyAggregation(results: [rtHealthKit.HealthQueryResult], aggregation: String) -> rtHealthKit.HealthQueryResult? {
        guard !results.isEmpty else { return nil }
        
        let values = results.map { $0.value }
        let lastResult = results.last!
        
        let aggregatedValue: Double
        switch aggregation {
        case "first":
            aggregatedValue = results.first!.value
        case "last":
            aggregatedValue = results.last!.value
        case "min":
            aggregatedValue = values.min()!
        case "max":
            aggregatedValue = values.max()!
        case "sum":
            aggregatedValue = values.reduce(0.0, +)
        case "median":
            let sortedValues = values.sorted()
            let count = sortedValues.count
            if count % 2 == 0 {
                aggregatedValue = (sortedValues[count/2 - 1] + sortedValues[count/2]) / 2.0
            } else {
                aggregatedValue = sortedValues[count/2]
            }
        default: // "avg"
            aggregatedValue = values.reduce(0.0, +) / Double(values.count)
        }
        
        return rtHealthKit.HealthQueryResult(date: lastResult.date, value: aggregatedValue, unit: lastResult.unit)
    }
    
    
    private func formatHealthKitValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.2f", value)
        }
    }
}

// MARK: - Date Extension for Timezone Handling
extension Date {
    func toLocalTime() -> Date {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        return Date(timeInterval: seconds, since: self)
    }
}
