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
import HealthKit
import SwiftUI
import UIKit

class voNumber: voState, UITextFieldDelegate, UIAdaptivePresentationControllerDelegate {

  private var _dtf: UITextField?
  lazy var rthk = rtHealthKit.shared
  private static var healthKitCache: [String: String] = [:]  // Cache by "sourceName-date"
  let noHKdataMsg = "No HealthKit data available"
  private var healthButton: UIButton?  // Store reference to health button for refreshing

  private func shouldShowZeroForNoData(unit: HKUnit?) -> Bool {
    guard let unit = unit else { return false }

    let unitString = unit.unitString

    // Time duration units (minutes, hours - for sleep, workouts, mindful minutes)
    if unitString == "min" || unitString == "hr" {
      return true
    }

    // Pure count units (for sleep cycles, segments, awakenings)
    if unitString == "count" {
      return true
    }

    // All other units (HRV milliseconds, heart rate bpm, blood pressure, etc.)
    return false
  }

  var dtf: UITextField {
    if _dtf?.frame.size.width != vosFrame.size.width {
      _dtf = nil  // first time around thinks size is 320, handle larger devices
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

    textField.borderStyle = .roundedRect  //Bezel;
    textField.font = PrefBodyFont  // [UIFont systemFontOfSize:17.0];
    textField.autocorrectionType = .no  // no auto correction support

    if vo.optDict["ahksrc"] == "1" || vo.optDict["otsrc"] == "1" {
      textField.placeholder = "<no data>"
    } else {
      textField.placeholder = "<enter number>"
    }
    textField.textAlignment = .right  // ios6 UITextAlignmentRight;
    //[dtf addTarget:self action:@selector(numTextFieldClose:) forControlEvents:UIControlEventTouchUpOutside];

    textField.keyboardType = .decimalPad  //number pad with decimal point but no done button     // use the number input only
    // no done button for number pad // _dtf.returnKeyType = UIReturnKeyDone;
    // need this from http://stackoverflow.com/questions/584538/how-to-show-done-button-on-iphone-number-pad Michael Laszlo
    // .applicationFrame deprecated ios9
    //let appWidth = Float(UIScreen.main.bounds.width)
    let accessoryView = createInputAccessoryView()

    textField.inputAccessoryView = accessoryView

    textField.clearButtonMode = .whileEditing  // has a clear 'x' button to the right

    //dtf.tag = kViewTag;        // tag this control so we can remove it later for recycled cells
    textField.delegate = self  // let us be the delegate so we know when the keyboard's "Done" button is pressed

    // Add an accessibility label that describes what the text field is for.
    textField.accessibilityHint = NSLocalizedString("enter a number", comment: "")
    textField.text = ""
    textField.accessibilityIdentifier = "\(self.tvn())_numberfield"
    textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

    return textField
  }

  private func createInputAccessoryView() -> UIView {
    // Create simple view container to avoid UIToolbar constraint conflicts
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
    containerView.backgroundColor = UIColor.systemBackground
    containerView.translatesAutoresizingMaskIntoConstraints = true
    containerView.autoresizingMask = [.flexibleWidth]

    // Add top border line to match toolbar appearance
    let borderLine = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0.5))
    borderLine.backgroundColor = UIColor.separator
    borderLine.autoresizingMask = [.flexibleWidth]
    containerView.addSubview(borderLine)

    // Create Done button using unified button system - use blue for secondary done (not primary save)
    let doneButtonItem = rTracker_resource.createDoneButton(target: self, action: #selector(selectDoneButton), accId: "number_done", preferYellow: false)
    if let doneButton = doneButtonItem.uiButton {
        doneButton.frame = CGRect(x: UIScreen.main.bounds.width - 70, y: 7, width: 60, height: 30)
        doneButton.autoresizingMask = [.flexibleLeftMargin]
        containerView.addSubview(doneButton)
    }

    // Create Minus button using unified button system
    let minusButtonItem = rTracker_resource.createActionButton(target: self, action: #selector(selectMinusButton), symbolName: "minus.forwardslash.plus", accId: "number_plusMinus", fallbackTitle: "±")
    if let minusButton = minusButtonItem.uiButton {
        minusButton.frame = CGRect(x: UIScreen.main.bounds.width - 140, y: 7, width: 60, height: 30)
        minusButton.autoresizingMask = [.flexibleLeftMargin]
        containerView.addSubview(minusButton)
    }

    return containerView
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
    DBGLog(
      String("tf end editing vid=\(Int(vo.vid)) vo.value=\(vo.value) tf.text=\(textField.text)"))

    if startStr != textField.text {
      vo.value = textField.text ?? ""
      //textField.textColor = [UIColor blackColor];
      //textField.backgroundColor = [UIColor whiteColor];
      NotificationCenter.default.post(
        name: NSNotification.Name(rtValueUpdatedNotification), object: self)
      startStr = nil
    }

    vo.parentTracker.activeControl = nil
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    // the user pressed the "Done" button, so dismiss the keyboard
    //DBGLog(@"textField done: %@  vid=%d", textField.text,self.vo.vid);
    // [self tfvoFinEdit:textField];  // textFieldDidEndEditing will be called, just dismiss kybd here
    DBGLog(
      String("tf should return vid=\(Int(vo.vid)) vo.value=\(vo.value) tf.text=\(textField.text)"))

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
    if nil != _dtf {  // && !vo.parentTracker.loadingDbData
      // not self as don't want to instantiate prematurely
      safeDispatchSync({ dtf.text = "" })
    }
    vo.useVO = true
  }

  override func voDisplay(_ bounds: CGRect) -> UIView {
    vosFrame = bounds
    // force recreate
    //_dtf = nil

    var targD = Date()  // now
    if vo.value == "" {
      if vo.optDict["nswl"] == "1" /* && ![to hasData] */ {  // nswl = number start with last
        // only if new entry
        let to = vo.parentTracker
        var sql = String(
          format: "select count(*) from voData where id=%ld and date<%d", Int(vo.vid),
          Int(to.trackerDate!.timeIntervalSince1970))
        let v = to.toQry2Int(sql: sql)
        if v > 0 {
          sql = String(
            format: "select val from voData where id=%ld and date<%d order by date desc limit 1;",
            Int(vo.vid), Int(to.trackerDate!.timeIntervalSince1970))
          let r = to.toQry2Str(sql: sql)
          dtf.textColor = .lightGray
          dtf.backgroundColor = .darkGray
          dtf.text = formatValueForDisplay(r)
        }
        //sql = nil;
      } else if vo.optDict["ahksrc"] == "1"
        && Int(vo.parentTracker.trackerDate!.timeIntervalSince1970) > self.MyTracker.lastDbDate
      {
        self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
        // apple healthkit source and trackerDate is newer than last in database (not historical = new record)
        if vo.optDict["ahPrevD"] ?? "0" == "1" {
          let calendar = Calendar.current
          targD = calendar.date(byAdding: .day, value: -1, to: targD) ?? targD
        }

        let haveUnit = vo.optDict["ahUnit"] != nil
        let cacheKey =
          "\(vo.optDict["ahSource"]!)-\(Int(targD.timeIntervalSince1970))-\(haveUnit ? vo.optDict["ahUnit"]! : "default")"

        if let cachedValue = Self.healthKitCache[cacheKey] {
          dtf.text = cachedValue
          DBGLog("\(vo.valueName!) -- cache hit for \(vo.optDict["ahSource"]!) returned: \(cachedValue)", color:.BLUE)
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
            healthKitResult = self?.formatValueForDisplay(result) ?? result
            Self.healthKitCache[cacheKey] = healthKitResult!
          } else {
            // Determine appropriate no-data display based on unit type
            let currentUnit = self?.vo.optDict["ahUnit"]
            let hkUnit: HKUnit? = {
              guard let unitStr = currentUnit, !unitStr.isEmpty else { return nil }
              return HKUnit(from: unitStr)
            }()

            // Use "0" for time/count units, empty string for physiological units
            // Empty string allows the ghosted placeholder "<no data>" to show
            healthKitResult = (self?.shouldShowZeroForNoData(unit: hkUnit) ?? false) ? "0" : ""
          }
          semaphore.signal()
        }

        semaphore.wait()  // warning about lower QoS wait is necessary or can return empty text field, but need to see the value

        // Apply the result synchronously on main thread
        dtf.text = healthKitResult
        self.vo.vos?.addExternalSourceOverlay(to: self.dtf)
        DBGLog("\(vo.valueName!) -- HK query for \(vo.optDict["ahSource"]!) targD \(targD) returned: \(healthKitResult ?? "nil")", color:.BLUE)

      } else if vo.optDict["otsrc"] == "1" {
        self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
        if let xrslt = vo.vos?.getOTrslt() {
          self.dtf.text = formatValueForDisplay(xrslt)
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
      dtf.text = formatValueForDisplay(vo.value)
      if vo.optDict["ahksrc"] == "1" || vo.optDict["otsrc"] == "1" {
        self.vo.vos?.addExternalSourceOverlay(to: self.dtf)  // no taps
        #if DEBUGLOG
          if vo.optDict["ahksrc"] == "1" {
            DBGLog("\(vo.valueName!) -- HK query for \(vo.optDict["ahSource"]!) load vo.value: \(dtf.text ?? "nil")", color:.BLUE)
          } else {
            DBGLog("\(vo.valueName!) -- OT query for \(vo.optDict["otTracker"]!) \(vo.optDict["otValue"]!) load vo.value: \(dtf.text ?? "nil")", color:.BLUE)
          }
        #endif

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
      minutes < 60
    else {
      return timeString
    }

    // Convert to total minutes (e.g., 1:30 -> 90)
    let totalMinutes = (hours * 60) + minutes
    return String(totalMinutes)
  }

  private func formatValueForDisplay(_ value: String?) -> String {
    guard let value = value, !value.isEmpty else { return value ?? "" }
    guard value != noHKdataMsg else { return value }

    if vo.optDict["hrsmins"] ?? "0" == "1", let numValue = Double(value) {
      let rv = Int(round(numValue))
      return String(format: "%d:%02d", rv / 60, rv % 60)
    }
    return value
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
      || ((key == "ahksrc")
        && ((val == (AHKSRCDFLT ? "1" : "0") || (vo.optDict["ahSource"] == nil))))  // unspecified ahSource disallowed
      || ((key == "ahAvg") && (val == (AHAVGDFLT ? "1" : "0")))
      || ((key == "ahFrequency") && (val == AHFREQUENCYDFLT))
      || ((key == "ahTimeFilter") && (val == AHTIMEFILTERDFLT))
      || ((key == "ahAggregation") && (val == AHAGGREGATIONDFLT))
      || ((key == "hrsmins") && (val == (HRSMINSDFLT ? "1" : "0")))
      || ((key == "ahPrevD") && (val == (AHPREVDDFLT ? "1" : "0")))
      || ((key == "autoscale") && (val == (AUTOSCALEDFLT ? "1" : "0")))
      || ((key == "numddp") && (Int(val ?? "") ?? 0 == NUMDDPDFLT))
    {
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

    // Part 2: Dates that don't have hkData status
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
    DBGLog(
      "Dates matching first part of query (no voData, no hkData status, newer than latest): \(firstPart.count)"
    )

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
    DBGLog(
      "Dates only in second part: \(secondPartOnly.count) \(formatSampleDates(secondPartOnly))")
    DBGLog("Dates in both parts: \(intersection.count)")

    // Look for dates far in the past or future that might be suspicious
    let now = Int(Date().timeIntervalSince1970)
    let oneYearAgo = now - 365 * 24 * 60 * 60
    let veryOldDates = combinedSet.filter { $0 < oneYearAgo }
    let futureDates = combinedSet.filter { $0 > now }

    DBGLog(
      "Very old dates (>1 year): \(veryOldDates.count) \(formatSampleDates(Array(veryOldDates)))")
    DBGLog("Future dates: \(futureDates.count) \(formatSampleDates(Array(futureDates)))")

    DBGLog("End debugging HealthKit date query")
  }

  override func loadHKdata(forDate date: Int?, dispatchGroup: DispatchGroup?) {
    // loads into database, not for current tracker record
    let to = vo.parentTracker
    let isAhPrevD = self.vo.optDict["ahPrevD"] ?? "0" == "1"

    guard let srcName = vo.optDict["ahSource"] else {
      DBGErr("no ahSource specified for valueObj \(vo.valueName ?? "no name")")
      return
    }

    // Compute queryConfig and hkObjectType here instead of in getHealthKitDates
    let calendar = Calendar.current
    guard let queryConfig = healthDataQueries.first(where: { $0.displayName == srcName }),
      let hkObjectType = queryConfig.makeSampleType()
    else {
      DBGLog("No HealthKit identifier found for display name: \(srcName)")
      dispatchGroup?.leave()
      return
    }

    DBGLog("load HealthKit data for valueObj \(vo.valueName ?? "no name") from source \(srcName)", color:.GREEN)

    // enter done at trackerObj before calling here -- dispatchGroup?.enter()  // wait for getHealthkitDates processing overall

    //*********
    // 1st determine if hk has date entries this tracker does not, if so identify and add them
    // if date specified it is refresh of current to historical date
    // if no date specified it is full refresh (no db entries) or just current
    //*********

    // Create a separate DispatchGroup for getHealthKitDates processing
    let hkDispatchGroup = DispatchGroup()

    // Declare newDates and matchedDates at method level so they're accessible throughout the method
    var newDates: Set<TimeInterval> = []
    var matchedDates: Set<TimeInterval> = []
    var transactionStarted = false
    var dataTransactionStarted = false
    #if DEBUGLOG
    var detailedLogging = false
    #endif

    hkDispatchGroup.enter()

    var specifiedStartDate: Date? = nil
    var specifiedEndDate: Date? = nil

    // if historical specified date, use it for start and end because single date refresh
    // else if database entries and specified date after, use the last db date as startDate and no end date to get all new
    // if no database entries, then wiped so full refresh, no start or end date.

    let sql = "select max(date) from voHKstatus where id = \(Int(vo.vid)) and stat = \(hkStatus.hkData.rawValue)"
    let lastDbDate = to.toQry2Int(sql: sql)
    DBGLog("last db date is \(lastDbDate > 0 ? i2ltd(lastDbDate) : "none") input date is \(date.map { $0 > 0 ? i2ltd($0) : "zero" } ?? "nil")")

    if lastDbDate > 0 {
        if let date = date {
            if date >= lastDbDate {
                // Future date: get all entries from last db date to now
                specifiedStartDate = Date(timeIntervalSince1970: TimeInterval(lastDbDate))
                specifiedEndDate = nil
            } else {
                // Historical date: find closest db dates before and after specified date
                let sqlBefore = "SELECT max(date) FROM voHKstatus WHERE id = \(Int(vo.vid)) AND stat = \(hkStatus.hkData.rawValue) AND date < \(date)"
                let sqlAfter = "SELECT min(date) FROM voHKstatus WHERE id = \(Int(vo.vid)) AND stat = \(hkStatus.hkData.rawValue) AND date > \(date)"

                let dateBefore = to.toQry2Int(sql: sqlBefore)
                let dateAfter = to.toQry2Int(sql: sqlAfter)

                specifiedStartDate = dateBefore > 0 ? Date(timeIntervalSince1970: TimeInterval(dateBefore)) : nil
                specifiedEndDate = dateAfter > 0 ? Date(timeIntervalSince1970: TimeInterval(dateAfter)) : nil
            }

            DBGLog(
                "Single date refresh: querying from \(specifiedStartDate.map { ltd($0) } ?? "nil") to \(specifiedEndDate.map { ltd($0) } ?? "nil")"
            )
        } else {
            specifiedStartDate = Date(timeIntervalSince1970: TimeInterval(lastDbDate))
        }
    }

    DBGLog(
      "Using specified start date: \(specifiedStartDate.map { ltd($0) } ?? "nil") and end date: \(specifiedEndDate.map { ltd($0) } ?? "nil")"
    )

    /*
    // think not needed because mergedates handles aggregationTime, processHealthWQuery handles sleep_hours

    // Only apply date adjustments if both dates are specified and window is less than 36 hours
    if let startDate = specifiedStartDate,
       let endDate = specifiedEndDate,
       endDate.timeIntervalSince(startDate) < (36 * 3600) {

        // Adjust start date for data types with aggregation boundaries (like sleep at 12:00 PM)
        // so move start date back to previous boundary to ensure we get all data
        // XXX end date is just plus 1 day from start date, probaly needs to be range based on nextdbdate or current date

        if let queryConfig = healthDataQueries.first(where: { $0.displayName == srcName }),
           let aggregationTime = queryConfig.aggregationTime,
           let currentStartDate = specifiedStartDate {
            let calendar = Calendar.current
            // Calculate the aggregation boundary time for the current start date
            let boundaryDate = calendar.date(bySettingHour: aggregationTime.hour ?? 12,
                                           minute: aggregationTime.minute ?? 0,
                                           second: 0,
                                           of: currentStartDate) ?? currentStartDate
            // Go back one day from boundary to ensure we capture data that gets aggregated to this boundary
            specifiedStartDate = calendar.date(byAdding: .day, value: -1, to: boundaryDate)
            specifiedEndDate = calendar.date(byAdding: .day, value: 1, to: specifiedStartDate!)
            // start is yesterday's aggregation boundary, end is one day later
            DBGLog("[\(srcName)] Adjusted dates for aggregation boundary to  start: \(specifiedStartDate.map { ltd($0) } ?? "nil") and end: \(specifiedEndDate.map { ltd($0) } ?? "nil")")
        }

        // Adjust dates for high-frequency data with sleep_hours time filter
        if queryConfig.aggregationType == .highFrequency,
           let timeFilter = vo.optDict["ahTimeFilter"],
           timeFilter == "sleep_hours",
           vo.optDict["ahFrequency"] ?? "daily" == "daily",
           let currentStartDate = specifiedStartDate {
            // Get start of tracker day in local time
            let trackerDay = calendar.startOfDay(for: currentStartDate)

            // Go back one day to get previous day at 00:00 local
            let previousDay = calendar.date(byAdding: .day, value: -1, to: trackerDay)!

            // Sleep starts at 23:00 previous day local (previous day + 23 hours)
            let sleepStart = calendar.date(byAdding: .hour, value: 23, to: previousDay)!

            // Sleep ends at 06:00 tracker day local (tracker day + 6 hours)
            let sleepEnd = calendar.date(byAdding: .hour, value: 6, to: trackerDay)!

            specifiedStartDate = sleepStart
            specifiedEndDate = sleepEnd
            DBGLog("[\(srcName)] Adjusted for sleep_hours time filter: \(ltd(sleepStart)) to \(ltd(sleepEnd))")
        }
    }
    */

    #if DEBUGLOG
    // Debug-only: Limit to recent data when no start date specified
    let USE_DEBUG_DATE_LIMIT = false  // Easy toggle
    if USE_DEBUG_DATE_LIMIT && specifiedStartDate == nil {
        // Use data from last N months/days/hours instead of querying from beginning of time
        // Format: "<number><unit>" where unit is 'h' (hours), 'd' (days), or 'm' (months)
        let debugPeriod = "2d"  // Examples: "3d", "2m", "36h"
        let calendar = Calendar.current

        let debugStartDate: Date?
        let periodDisplay: String

        // Parse the debug period string
        if let lastChar = debugPeriod.last,
           let valueStr = debugPeriod.dropLast().description as String?,
           let value = Int(valueStr) {

            switch lastChar {
            case "h":
                debugStartDate = calendar.date(byAdding: .hour, value: -value, to: Date())
                periodDisplay = "\(value) hour\(value == 1 ? "" : "s")"
            case "d":
                debugStartDate = calendar.date(byAdding: .day, value: -value, to: Date())
                periodDisplay = "\(value) day\(value == 1 ? "" : "s")"
            case "m":
                debugStartDate = calendar.date(byAdding: .month, value: -value, to: Date())
                periodDisplay = "\(value) month\(value == 1 ? "" : "s")"
            default:
                debugStartDate = nil
                periodDisplay = "invalid period"
            }
        } else {
            debugStartDate = nil
            periodDisplay = "invalid format"
        }

        if let debugStartDate = debugStartDate {
            specifiedStartDate = debugStartDate
            DBGLog("DEBUG OVERRIDE: No start date specified, limiting to \(periodDisplay) ago: \(ltd(debugStartDate))", color: .RED)
        } else {
            DBGErr("DEBUG OVERRIDE: Invalid period format '\(debugPeriod)' - use format like '3d', '2m', '36h'")
        }
    }
    #endif

    if specifiedStartDate == nil {
        // remind standard HealthKit date window
        DBGLog("[\(srcName)] no startdate, full refresh, Using effective window size: \(hkDateWindow) days")
    }

    // Adjust for ahPrevD if needed - shift both start and end dates back by 1 day for HK query
    if isAhPrevD {
        DBGLog("[\(srcName)] ahPrevD enabled: shifting start date back by 1 day")
        if let currentStartDate = specifiedStartDate {
            specifiedStartDate = calendar.date(byAdding: .day, value: -1, to: currentStartDate)
        }
        if let currentEndDate = specifiedEndDate {
            specifiedEndDate = calendar.date(byAdding: .day, value: -1, to: currentEndDate)
        }
        DBGLog("[\(srcName)] Adjusted dates for ahPrevD to  start: \(specifiedStartDate.map { ltd($0) } ?? "nil") and end: \(specifiedEndDate.map { ltd($0) } ?? "nil")")
    }
 
    //*****  Use HK to get start or end dates where not yet specified, otherwise use specified dates unchanged

    rthk.sampleDateRange(
      for: hkObjectType as HKSampleType, useStartDate: specifiedStartDate,
      useEndDate: specifiedEndDate
    ) { [self] hkStartDate, hkEndDate in
      // Calculate appropriate end date

      DBGLog(
        "[\(srcName)] querying from \(hkStartDate.map { ltd($0) } ?? "nil") to \(hkEndDate.map { ltd($0) } ?? "nil")"
      )

      guard let hkStartDate = hkStartDate, let hkEndDate = hkEndDate else {
        DBGLog("[\(srcName)] no hk data: start or end date is nil")
        hkDispatchGroup.leave()
        return
      }

      // Check if start date is after end date - invalid range
      if hkStartDate > hkEndDate {
        DBGLog(
          "[\(srcName)] no new hk data: start date \(ltd(hkStartDate)) is after end date \(ltd(hkEndDate))")
        hkDispatchGroup.leave()
        return
      }

      //***** At this point have valid start and end dates

      DBGLog("[\(srcName)] final HealthKit query date range: \(ltd(hkStartDate)) to \(ltd(hkEndDate))", color: .VIOLET)

      // if more than a hkDateWindow we need progress bar

      // Calculate number of date windows needed for chunked processing
      let daysBetween = max(1, calendar.dateComponents([.day], from: hkStartDate, to: hkEndDate).day ?? 1)
      let numberOfWindows = (daysBetween + hkDateWindow - 1) / hkDateWindow  // Round up
      DBGLog("[\(srcName)] total days: \(daysBetween), processing in \(numberOfWindows) windows of up to \(hkDateWindow) days each")

      to.refreshDelegate?.updateFullRefreshProgress(
        step: 0, phase: "loading dates for \(self.vo.valueName ?? "unknown")", totalSteps: numberOfWindows, threshold: 2)

      var allHKDates: [TimeInterval] = []
      let chunkDispatchGroup = DispatchGroup()

      //***** Process date ranges in chunks with rate limiting on background queue
      //***** get all HK entry dates in the specified range

      for windowIndex in 0..<numberOfWindows {
        chunkDispatchGroup.enter()

        DispatchQueue.global(qos: .userInitiated).async {
          // Add delay between chunks to prevent HealthKit overload
          if windowIndex > 0 {
            Thread.sleep(forTimeInterval: 0.01)  // 10ms between chunks
          }

          let windowStartDate =
            calendar.date(byAdding: .day, value: windowIndex * hkDateWindow, to: hkStartDate)
            ?? hkStartDate
          let windowEndDate: Date
          if windowIndex == numberOfWindows - 1 {
            // Last window - use actual end date
            windowEndDate = hkEndDate
          } else {
            // Use window size
            windowEndDate =
              calendar.date(
                byAdding: .day, value: (windowIndex + 1) * hkDateWindow, to: hkStartDate)
              ?? hkEndDate
          }

          // Log first, last, and every 10th window
          let shouldLog = (windowIndex == 0) || (windowIndex == numberOfWindows - 1) || ((windowIndex + 1) % 10 == 0)
          if shouldLog {
            DBGLog(
              "[\(srcName)] Processing HealthKit date window \(windowIndex + 1)/\(numberOfWindows): \(ltd(windowStartDate)) to \(ltd(windowEndDate))"
            )
          }

          self.rthk.getHealthKitDates(
            queryConfig: queryConfig, hkObjectType: hkObjectType as HKSampleType,
            startDate: windowStartDate, endDate: windowEndDate
          ) { hkDates in
            allHKDates.append(contentsOf: hkDates)
            //DBGLog("Retrieved \(hkDates.count) HK dates: \(hkDates.map { Date(timeIntervalSince1970: $0) })")
            DispatchQueue.main.async {
                to.refreshDelegate?.updateFullRefreshProgress()
            }
            chunkDispatchGroup.leave()
          }
        }
      }

      // Wait for all chunks to complete, then process combined results

      //***** now have all HK dates with entries for this source for thespecified/determined date range

      chunkDispatchGroup.notify(queue: .main) { [self] in
        to.refreshDelegate?.updateFullRefreshProgress(completed: true)
        let isAhPrevD = self.vo.optDict["ahPrevD"] ?? "0" == "1"

        // For ahPrevD, we need shift the HK result dates +1 day to be the dates they are recorded in the tracker database
        var datesToCheck = allHKDates
        if isAhPrevD {
            let now = Date()
            datesToCheck = allHKDates.compactMap { date in
                guard let shiftedDate = calendar.date(byAdding: .day, value: 1, to: Date(timeIntervalSince1970: date)),
                      shiftedDate <= now else { return nil }
                return shiftedDate.timeIntervalSince1970
            }
            DBGLog("ahPrevD enabled: checking \(datesToCheck.count) shifted dates against trkrData dates (future dates filtered)")
        }

        #if HKDEBUG
        #if DEBUGLOG
            if datesToCheck.count > 0 {
                DBGLog("  datesToCheck has \(datesToCheck.count) dates:")
                for (index, date) in datesToCheck.sorted().enumerated() {
                    DBGLog("    [\(index)]: \(i2ltd(Int(date)))")
                }
            }
        #endif
        #endif
        

        //***** now have HK entry dates for the specified time range as they will be entered in db.

        // Move heavy processing to background thread to avoid UI freeze
        DispatchQueue.global(qos: .userInitiated).async { [self] in
          let frequency = self.vo.optDict["ahFrequency"] ?? "daily"
          let timeFilter = self.vo.optDict["ahTimeFilter"]

          //***** map HK dates to where they should be in tracker database, generating new dates and matched dates.
          //** mergeResult and timeSlotResult both filter today/now entries for current tracker view.
          //***** here we may insert trackerDates even if just refreshing current day

          var datesToMerge = datesToCheck

          // For high-frequency daily data, collapse timestamps within timeFilter windows
          // Singleton frequency uses all_day (no time filter)
          if frequency == "daily" && queryConfig.aggregationType == .highFrequency {
            datesToMerge = self.collapseTimeFilterWindow(
              timestamps: datesToCheck,
              timeFilter: timeFilter
            )

            #if HKDEBUG
            #if DEBUGLOG
            if datesToMerge.count != datesToCheck.count {
              DBGLog(
                "[\(srcName)] highFrequency+daily: collapsed \(datesToCheck.count) timestamps to \(datesToMerge.count) using timeFilter '\(timeFilter ?? "all_day")'"
              )
              for (index, ts) in datesToMerge.sorted().enumerated() {
                DBGLog("  [\(index)]: \(i2ltd(Int(ts)))")
              }
            }
            #endif
            #endif

          }

          // ignore ahPrevD here.  these are the tracker dates to be in the database for the values whether specified day or previous day
          if frequency == "singleton" {
            // Singleton mode: match HK dates to existing tracker timestamps, or use 12:00 noon if no entry exists
            let result = handleSingletonMatching(datesToMerge: datesToMerge, tracker: to, srcName: srcName)
            newDates = result.newDates
            matchedDates = result.matchedDates
          } else if frequency == "daily" {
            let trackerHasTimeSrc = to.optDict["ahkTimeSrc"] != nil
            let isHighFrequency = queryConfig.aggregationType == .highFrequency

            // ahkTimeSrc is designed for discrete measurements (multiple blood pressure readings per day)
            // High-frequency data (HRV, heart rate) should always aggregate to a single daily value
            // regardless of ahkTimeSrc setting
            if trackerHasTimeSrc && !isHighFrequency {
              // ahkTimeSrc mode: Use actual timestamps with optimal matching for discrete measurements
              let result = handleHkTimeSrc(datesToMerge: datesToMerge, tracker: to, srcName: srcName)
              newDates = result.newDates
              matchedDates = result.matchedDates
            } else {
              // Normal mode or high-frequency: use mergeDates with 12:00 normalization
              let mergeResult = to.mergeDates(inDates: datesToMerge, aggregationTime: queryConfig.aggregationTime)
              newDates = mergeResult.newDates
              matchedDates = mergeResult.matchedDates
            }
          } else {
            // High-frequency data - use time slots
            let timeSlotResult = to.generateTimeSlots(from: datesToCheck, frequency: frequency, aggregationTime: queryConfig.aggregationTime)
            newDates = timeSlotResult.newDates
            matchedDates = timeSlotResult.matchedDates
          }

          #if DEBUGLOG
          let dlim = 6
          detailedLogging = (newDates.count < dlim || matchedDates.count < dlim) && (newDates.count + matchedDates.count < 2*dlim)

          if detailedLogging {
            if newDates.count < dlim {
              DBGLog("[\(srcName)] newDates (\(newDates.count)): \(newDates.map { i2ltd(Int($0)) })")
            }
            if matchedDates.count < dlim {
              DBGLog("[\(srcName)] matchedDates (\(matchedDates.count)): \(matchedDates.map { i2ltd(Int($0)) })")
            }
          }
          #endif

          // Insert the new dates into trkrData
          // trkrData is 'on conflict replace'
          // only update an existing row if the new minpriv is lower
          let priv = max(MINPRIV, self.vo.vpriv)  // priv needs to be at least minpriv if vpriv = 0

          // Start transaction for all database operations in this function
          to.toExecSql(sql: "BEGIN TRANSACTION")  // voNumber loadHKdata
          transactionStarted = true

          if newDates.count > 0 {
              // Build single INSERT statement on background thread
              var valuesList: [String] = []
              for newDate in newDates {
                  valuesList.append("(\(Int(newDate)), \(priv))")
              }

              let batchSQL = "INSERT INTO trkrData (date, minpriv) VALUES " + valuesList.joined(separator: ", ")
              to.toExecSql(sql: batchSQL)

              DBGLog("Inserted \(newDates.count) new dates into trkrData for \(srcName) (vid: \(self.vo.vid)).")

              ///*
              #if DEBUGLOG
              if newDates.count < 6 {
                DBGLog("New dates inserted: \(newDates.map { i2ltd(Int($0)) })")
                let now = Date()
                for newDate in newDates {
                    let date = Date(timeIntervalSince1970: newDate)
                    let timeStatus = date > now ? "FUTURE" : "PAST"
                    DBGLog("  Date \(i2ltd(Int(newDate))): \(timeStatus) (offset: \(date.timeIntervalSince(now)) seconds)")
                }
              }
            if matchedDates.count < 6 {
                DBGLog("matched dates : \(matchedDates.map { i2ltd(Int($0)) })")
                let now = Date()
                for matchDate in matchedDates {
                    let date = Date(timeIntervalSince1970: matchDate)
                    let timeStatus = date > now ? "FUTURE" : "PAST"
                    DBGLog("  Date \(i2ltd(Int(matchDate))): \(timeStatus) (offset: \(date.timeIntervalSince(now)) seconds)")
                }
              }
              #endif
              //*/
          }

          // Commit transaction immediately after synchronous trkrData inserts
          // This ensures the transaction closes before async HealthKit queries begin
          // and prevents "transaction within transaction" errors when processing multiple valueObjs sequentially
          if transactionStarted {
            to.toExecSql(sql: "COMMIT")  // voNumber loadHKdata - early commit after trkrData inserts
          }

          hkDispatchGroup.leave()  // Thread-safe, can be called from background thread
        }
      }
    }

    // 2nd log hk data entries for each date in voData and hkStatus

    // Wait for getHealthKitDates processing to complete before proceeding

    //***** tracker db now has all dates in trkrData for this source

    hkDispatchGroup.notify(queue: .main) { [self] in
      DBGLog("HealthKit dates for \(srcName) processed, continuing with loadHKdata.", color:.GREEN)
      
      // Combine newDates and matchedDates for processing through processHealthQuery
      // newDates and matchedDates are where the values go in the tracker database
      // for ahPrevD the hk query date is one day earlier than the tracker date

      let isAhPrevD = self.vo.optDict["ahPrevD"] ?? "0" == "1"
      var datesToProcess: [TimeInterval]

      if isAhPrevD {
        // newDates and matchedDates are the tracker dates for shifted hk dates, for ahPrevD we need to shift back to query the HK data for the day before
        let unshiftedNewDates = Set(newDates.compactMap { date in
          calendar.date(byAdding: .day, value: -1, to: Date(timeIntervalSince1970: date))?.timeIntervalSince1970
        })
        let unshiftedMatchedDates = Set(matchedDates.compactMap { date in
          calendar.date(byAdding: .day, value: -1, to: Date(timeIntervalSince1970: date))?.timeIntervalSince1970
        })
        datesToProcess = Array(unshiftedNewDates.union(unshiftedMatchedDates))
        DBGLog("ahPrevD enabled: shifted \(datesToProcess.count) dates back by -1 day for HealthKit queries")
      } else {
        // Normal mode: use dates as-is
        datesToProcess = Array(newDates.union(matchedDates))
      }

      DBGLog(
        "dates to process for \(srcName) (vid: \(vo.vid)): \(newDates.count) new + \(matchedDates.count) matched = \(datesToProcess.count) total"
      )
      if datesToProcess.count < 6 {
        DBGLog("  dates to process: \(datesToProcess.map { i2ltd(Int($0)) })")
      }

      // Progress bar threshold is 2x the effective window size to match the original 2:1 ratio
      let progressThreshold = hkDateWindow * 2
      to.refreshDelegate?.updateFullRefreshProgress(
        step: 0, phase: "loading data for \(self.vo.valueName ?? "unknown")", totalSteps: datesToProcess.count,
        threshold: progressThreshold)

      let calendar = Calendar.current
      let secondHKDispatchGroup = DispatchGroup()
      let frequency = self.vo.optDict["ahFrequency"] ?? "daily"

      #if DEBUGLOG
        let dataProcessingStartTime = CFAbsoluteTimeGetCurrent()
        var processedCount = 0
        let totalCount = datesToProcess.count
        DBGLog("[\(srcName)] Starting data processing phase: \(totalCount) records to process")
      #endif

      for _ in datesToProcess {
        secondHKDispatchGroup.enter()  // Enter the group for each query
      }

      // Start transaction for voData/voHKstatus inserts if we have dates to process
      // This transaction wraps all the INSERT operations that happen in processHealthQuery callbacks
      if datesToProcess.count > 0 {
        to.toExecSql(sql: "BEGIN TRANSACTION")  // voNumber loadHKdata - data inserts transaction
        dataTransactionStarted = true
      }

      // Process all dates asynchronously on background queue to prevent UI blocking
      DispatchQueue.global(qos: .userInitiated).async {
        // Process queries with rate limiting to prevent overwhelming HealthKit APIs
        for (index, dat) in datesToProcess.sorted().enumerated() {  // .sorted() is just to help debugging
          // Look up the query configuration to determine aggregationType
          guard healthDataQueries.first(where: { $0.displayName == srcName }) != nil
          else {
            DBGErr("No query configuration found for displayName: \(srcName)")
            continue
          }

          // Add delay every 5 operations to prevent HealthKit overload
          if index > 0 && index % 5 == 0 {
          //if index % 5 == 0 {
            Thread.sleep(forTimeInterval: 0.02)  // 20ms pause every 5 operations
          }

          // Use unified processHealthQuery for all cases

          self.processHealthQuery(
            timestamp: Int(dat),
            srcName: srcName,
            frequency: frequency,
            calendar: calendar,
            dispatchGroup: nil
          ) { [weak self] (result: String?) in
            // Ensure we have a valid self; if not, leave the group to avoid deadlock
            guard let self = self else {
              secondHKDispatchGroup.leave()
              return
            }
            // Dispatch database operations and UI updates to main thread
            DispatchQueue.main.async {
              let to = self.vo.parentTracker

              // Calculate storage date - shift hk query date forward to trackerdate if ahPrevD is enabled
              var storageDate = Int(dat)
              if self.vo.optDict["ahPrevD"] ?? "0" == "1" {
                // for ahPrevD we queried day N-1 for trackerDate N; now we need to shift the query date back to trackerDate N.
                  // rtm make this just be +3600*24
                if let shiftedDate = calendar.date(byAdding: .day, value: 1, to: Date(timeIntervalSince1970: TimeInterval(dat))) {
                  storageDate = Int(shiftedDate.timeIntervalSince1970)
                }
              }

              if let result = result {
                // Data found - insert into database
                // NOTE: For high-frequency data, 'dat' is the slot timestamp (e.g., 3pm) but 'result'
                // contains HealthKit data from the PREVIOUS interval (e.g., 2pm-3pm data).
                let sql =
                  "insert into voData (id, date, val) values (\(self.vo.vid), \(storageDate), '\(result)')"
                to.toExecSql(sql: sql)
                let statusSql =
                  "insert into voHKstatus (id, date, stat) values (\(self.vo.vid), \(storageDate), \(hkStatus.hkData.rawValue))"
                to.toExecSql(sql: statusSql)
                #if DEBUGLOG
                if detailedLogging {
                  DBGLog(
                    "Stored HK data value \(result) for \(self.vo.valueName ?? "unknown") on \(i2ltd(storageDate)) (vid: \(self.vo.vid))",
                    color: .GREEN
                  )
                }
                #endif
              } else {
                // No data found - record no data status
                let sql =
                  "insert into voHKstatus (id, date, stat) values (\(self.vo.vid), \(storageDate), \(hkStatus.noData.rawValue))"
                to.toExecSql(sql: sql)
                #if DEBUGLOG
                if detailedLogging {
                  DBGLog(
                    "No HK data for \(self.vo.valueName ?? "unknown") on \(i2ltd(storageDate)) (vid: \(self.vo.vid))",
                    color: .ORANGE
                  )
                }
                #endif
              }

              #if DEBUGLOG
                processedCount += 1
                // Log progress every 1000 records or on significant milestones for large datasets
                let shouldLog =
                  (processedCount % 1000 == 0) || (totalCount < 1000 && processedCount % 100 == 0)
                  || (processedCount == totalCount)
                if shouldLog {
                  let elapsed = CFAbsoluteTimeGetCurrent() - dataProcessingStartTime
                  let rate = elapsed > 0 ? Double(processedCount) / elapsed : 0
                  let percentage =
                    totalCount > 0 ? (Double(processedCount) / Double(totalCount)) * 100 : 0
                  DBGLog(
                    "[\(srcName)] Processing progress: \(processedCount)/\(totalCount) (\(String(format: "%.1f", percentage))%) - \(String(format: "%.1f", rate)) records/sec"
                  )
                }
              #endif

              // Update progress for each health query processed
              to.refreshDelegate?.updateFullRefreshProgress()
              secondHKDispatchGroup.leave()  // Leave the group when done
            }
          }
        }  // End for loop and background dispatch
      }  // End background dispatch block

      // wait on all processHealthQuery's to complete
      secondHKDispatchGroup.notify(queue: .main) { [self] in
        // Commit data insert transaction now that all async HealthKit queries completed
        if dataTransactionStarted {
          to.toExecSql(sql: "COMMIT")  // voNumber loadHKdata - data inserts transaction
        }

        // Move heavy database operations to background thread to avoid UI freeze
        DispatchQueue.global(qos: .userInitiated).async { [self] in
          // Start a new transaction for final cleanup operations
          // This is separate from the earlier transactions that already committed
          to.toExecSql(sql: "BEGIN TRANSACTION")  // voNumber loadHKdata - cleanup transaction

          // ensure trkrData has lowest priv if just added a lower privacy valuObj to a trkrData entry
          let priv = max(MINPRIV, self.vo.vpriv)  // priv needs to be at least minpriv if vpriv = 0
          let sql = """
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

          // Insert noData entries only for dates that were processed in this HealthKit session
          // This prevents historical manual data from being marked in voHKstatus
          let noDataSql = """
            INSERT INTO voHKstatus (id, date, stat)
            SELECT \(Int(vo.vid)), trkrData.date, \(hkStatus.noData.rawValue)
            FROM trkrData
            WHERE trkrData.date IN (\(datesToProcess.map { Int($0) }.map(String.init).joined(separator: ",")))
            AND NOT EXISTS (
              SELECT 1 FROM voHKstatus
              WHERE voHKstatus.date = trkrData.date
              AND voHKstatus.id = \(Int(vo.vid))
            );
            """
          to.toExecSql(sql: noDataSql)

          // Commit the cleanup transaction
          to.toExecSql(sql: "COMMIT")  // voNumber loadHKdata - cleanup transaction
          #if DEBUGLOG
            let totalElapsed = CFAbsoluteTimeGetCurrent() - dataProcessingStartTime
            let avgRate = totalElapsed > 0 ? Double(datesToProcess.count) / totalElapsed : 0
            DBGLog(
              "[\(srcName)] Data processing completed - \(datesToProcess.count) records in \(String(format: "%.3f", totalElapsed))s (avg \(String(format: "%.1f", avgRate)) records/sec)",
            )
          #endif
          DBGLog("Done loadHKdata for \(srcName) with \(datesToProcess.count) records.")
          
          // UI updates and completion callbacks - handles its own main thread dispatch
          to.refreshDelegate?.updateFullRefreshProgress(completed: true)
          dispatchGroup?.leave()  // Thread-safe, can be called from background thread
        }
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
      //DBGLog(
      //  "clearing date \(specificDate) \(Date(timeIntervalSince1970: TimeInterval(specificDate)))")

      // Check if there's actually a voHKstatus entry for this date and id before modifying database
      let checkSql = "select count(*) from voHKstatus where id = \(vo.vid) and date = \(specificDate)"
      if to.toQry2Int(sql: checkSql) > 0 {
        to.toExecSql(sql: "delete from voData where id = \(vo.vid) and date = \(specificDate)")
        to.toExecSql(sql: "delete from voHKstatus where id = \(vo.vid) and date = \(specificDate)")
      } else {
        // No voHKstatus entry found, skip database operations
        // return  // clear the cache anyway
      }

      // Clear cache entries for this specific date
      if let ahSource = vo.optDict["ahSource"] {
        let calendar = Calendar.current
        let targetDate = Date(timeIntervalSince1970: TimeInterval(specificDate))

        // Clear cache for the actual date
        let haveUnit = vo.optDict["ahUnit"] != nil
        let unitStr = haveUnit ? vo.optDict["ahUnit"]! : "default"
        let cacheKey = "\(ahSource)-\(specificDate)-\(unitStr)"
        Self.healthKitCache.removeValue(forKey: cacheKey)
        //DBGLog("Cleared cache key: \(cacheKey)")

        // If ahPrevD is enabled, also clear cache for previous day since that's what gets queried
        if vo.optDict["ahPrevD"] ?? "0" == "1" {
          if let prevDate = calendar.date(byAdding: .day, value: -1, to: targetDate) {
            let prevDateTimestamp = Int(prevDate.timeIntervalSince1970)
            let prevCacheKey = "\(ahSource)-\(prevDateTimestamp)-\(unitStr)"
            Self.healthKitCache.removeValue(forKey: prevCacheKey)
            //DBGLog("Cleared prevD cache key: \(prevCacheKey)")
          }
        }
      }
    } else {
      sql =
        "delete from voData where (id, date) in (select id, date from voHKstatus where id = \(vo.vid))"
      to.toExecSql(sql: sql)
      sql = "delete from voHKstatus where id = \(vo.vid)"
      to.toExecSql(sql: sql)

      // Clear all cache entries for this value object's ahSource
      if let ahSource = vo.optDict["ahSource"] {
        let keysToRemove = Self.healthKitCache.keys.filter { $0.hasPrefix("\(ahSource)-") }
        for key in keysToRemove {
          Self.healthKitCache.removeValue(forKey: key)
        }
        //DBGLog("Cleared \(keysToRemove.count) cache entries for ahSource: \(ahSource)")
      }
    }
  }

  @objc func showHealthStatus() {
    DBGLog("Show health status pressed from voNumber")

    // Present health status view without config instructions (user already at config screen)
    let healthStatusView = HealthStatusViewController(showConfigInstructions: false, onDismiss: { [weak self] in
      self?.refreshHealthButton()
    })
    let hostingController = UIHostingController(rootView: healthStatusView)
    hostingController.modalPresentationStyle = .pageSheet

    // Set delegate to refresh button on swipe dismissal
    hostingController.presentationController?.delegate = self

    // Present directly from ctvovcp (same pattern as configAppleHealthView)
    ctvovcp?.present(hostingController, animated: true, completion: {
      DBGLog("HealthStatusViewController presented")
    })
  }

  // MARK: - UIAdaptivePresentationControllerDelegate

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    // Refresh health button when HealthStatusViewController is dismissed via swipe
    DBGLog("Health status view dismissed via swipe from voNumber, refreshing button")
    refreshHealthButton()
  }

  private func refreshHealthButton() {
    guard let button = healthButton else { return }

    // Remove old button
    button.removeFromSuperview()

    // Create new button with updated status (skipAsyncUpdate to prevent database wipe)
    let healthButtonItem = rTracker_resource.createHealthButton(
      target: self,
      action: #selector(showHealthStatus),
      accId: "voNumber_health",
      skipAsyncUpdate: true
    )

    if let newButton = healthButtonItem.uiButton {
      // Use same frame as before
      newButton.frame = button.frame
      ctvovcp?.scroll.addSubview(newButton)
      self.healthButton = newButton  // Update reference
    }
  }

  @objc func configAppleHealthView() {
    DBGLog("config Apple Health view")

    rthk.updateAuthorisations(request:true) { [weak self] in
      guard let self = self else { return }

      // Wait for authorization update to complete before presenting view
      DBGLog("Authorization update completed, presenting ahViewController")

      let hostingController = UIHostingController(
        rootView: ahViewController(
          valueName: self.vo.valueName ?? "",
          selectedChoice: self.vo.optDict["ahSource"],
          selectedUnitString: self.vo.optDict["ahUnit"],
          ahPrevD: self.vo.optDict["ahPrevD"] ?? "0" == "1",
          ahkTimeSrc: self.MyTracker.optDict["ahkTimeSrc"] as? String == String(self.vo.vid),
          ahFrequency: self.vo.optDict["ahFrequency"] ?? AHFREQUENCYDFLT,
          ahTimeFilter: self.vo.optDict["ahTimeFilter"] ?? AHTIMEFILTERDFLT,
          ahAggregation: self.vo.optDict["ahAggregation"] ?? AHAGGREGATIONDFLT,
          onDismiss: {
            [self]
            updatedChoice, updatedUnit, updatedAhPrevD, updatedAhkTimeSrc, updatedAhFrequency,
            updatedAhTimeFilter, updatedAhAggregation in
            self.vo.optDict["ahSource"] = updatedChoice
            self.vo.optDict["ahUnit"] = updatedUnit
            self.vo.optDict["ahPrevD"] = updatedAhPrevD ? "1" : "0"
            self.vo.optDict["ahFrequency"] = updatedAhFrequency
            self.vo.optDict["ahTimeFilter"] = updatedAhTimeFilter
            self.vo.optDict["ahAggregation"] = updatedAhAggregation

            // Handle ahkTimeSrc at tracker level
            if updatedAhkTimeSrc {
              // Switch is ON: Set this vo as the time source
              self.MyTracker.optDict["ahkTimeSrc"] = String(self.vo.vid)
            } else {
              // Switch is OFF: Remove time source if it was this vo
              if self.MyTracker.optDict["ahkTimeSrc"] as? String == String(self.vo.vid) {
                self.MyTracker.optDict.removeValue(forKey: "ahkTimeSrc")
              }
            }

            if let button = self.ctvovcp?.scroll.subviews.first(where: {
              $0 is UIButton && $0.accessibilityIdentifier == "configtv_ahSelBtn"
            }) as? UIButton {
              DBGLog(
                "ahSelect view returned: \(updatedChoice ?? "nil") \(updatedUnit ?? "nil") optDict is \(self.vo.optDict["ahSource"] ?? "nil")  \(self.vo.optDict["ahUnit"] ?? "nil")"
              )
              DispatchQueue.main.async {
                button.setTitle(self.vo.optDict["ahSource"] ?? "Configure", for: .normal)
                button.sizeToFit()
              }
            }
            //DBGLog("ahSelect view returned: \(updatedChoice) optDict is \(self.vo.optDict["ahSource"] ?? "nil")")
          }
        )
      )
      hostingController.modalPresentationStyle = .fullScreen
      hostingController.modalTransitionStyle = .coverVertical

      // Present the hosting controller
      self.ctvovcp?.present(hostingController, animated: true)
    }
  }
  @objc func forwardToConfigOtherTrackerSrcView() {
    ctvovcp?.configOtherTrackerSrcView()
  }

  override func voDrawOptions(_ ctvovc: configTVObjVC) {
    ctvovcp = ctvovc  // save reference so can display config gui

    var frame = CGRect(x: MARGIN, y: ctvovc.lasty, width: 0.0, height: 0.0)

    var labframe = ctvovc.configLabel(
      "Start with last saved value: ", frame: frame, key: "swlLab", addsv: true)
    frame = CGRect(
      x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height,
      height: labframe.size.height)

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

    labframe = ctvovc.configLabel(
      "graph decimal places (-1 for auto): ", frame: frame, key: "numddpLab", addsv: true)

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
    frame = CGRect(
      x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height,
      height: labframe.size.height)

    frame = ctvovc.configSwitch(
      frame,
      key: "ahsBtn",
      state: vo.optDict["ahksrc"] == "1",
      addsv: true)

    // Add health status button next to switch (on same line, to the right)
    // UISwitch has intrinsic size ~51pt wide, use that instead of frame.size.width
    let healthButtonItem = rTracker_resource.createHealthButton(
      target: self,
      action: #selector(showHealthStatus),
      accId: "voNumber_health"
    )
    if let button = healthButtonItem.uiButton {
      let switchWidth: CGFloat = 80.0
      let healthBtnFrame = CGRect(
        x: frame.origin.x + switchWidth + SPACE,
        y: frame.origin.y,
        width: 30,
        height: frame.size.height
      )
      button.frame = healthBtnFrame
      ctvovc.scroll.addSubview(button)
      self.healthButton = button  // Store reference for later refresh
    }

    frame.origin.x = MARGIN
    frame.origin.y += MARGIN + frame.size.height

    frame = ctvovc.configActionBtn(
      frame, key: "ahSelBtn", label: vo.optDict["ahSource"] ?? "Configure", target: self,
      action: #selector(configAppleHealthView))
    ctvovc.switchUpdate(okey: "ahksrc", newState: vo.optDict["ahksrc"] == "1")

    frame.origin.x = MARGIN
    frame.origin.y += MARGIN + frame.size.height

    labframe = ctvovc.configLabel(
      "Other Tracker source: ", frame: frame, key: "otsLab", addsv: true)
    frame = CGRect(
      x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height,
      height: labframe.size.height)

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

    frame = ctvovc.configActionBtn(
      frame, key: "otSelBtn", label: str, target: self,
      action: #selector(forwardToConfigOtherTrackerSrcView))
    ctvovc.switchUpdate(okey: "otsrc", newState: vo.optDict["otsrc"] == "1")

    frame.origin.x = MARGIN
    frame.origin.y += MARGIN + frame.size.height

    labframe = ctvovc.configLabel("Other options:", frame: frame, key: "noLab", addsv: true)

    // Display minutes as hrs:mins switch
    frame.origin.x = MARGIN
    frame.origin.y += MARGIN + labframe.size.height

    labframe = ctvovc.configLabel("Display minutes as hrs:mins:", frame: frame, key: "hrsminsLab", addsv: true)

    frame = CGRect(x: labframe.size.width + MARGIN + SPACE, y: frame.origin.y, width: labframe.size.height, height: labframe.size.height)

    frame = ctvovc.configSwitch(
      frame,
      key: "hrsminsBtn",
      state: (vo.optDict["hrsmins"] == "1"),
      addsv: true)

    frame.origin.x = MARGIN
    frame.origin.y += MARGIN + frame.size.height

    ctvovc.lasty = frame.origin.y

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

  /// Handles singleton frequency: matches each HK date to closest tracker timestamp on same calendar day
  /// or creates new entry at 12:00 noon if no tracker entry exists for that day
  /// - Parameters:
  ///   - datesToMerge: HK sample dates (calendar days with HK data)
  ///   - tracker: The tracker object (for querying trkrData)
  ///   - srcName: Name of HK source (for logging)
  /// - Returns: Tuple of (newDates, matchedDates) sets
  private func handleSingletonMatching(
    datesToMerge: [TimeInterval],
    tracker: trackerObj,
    srcName: String
  ) -> (newDates: Set<TimeInterval>, matchedDates: Set<TimeInterval>) {

    let calendar = Calendar.current
    let now = Date()
    var matchedDates: Set<TimeInterval> = []
    let newDates: Set<TimeInterval> = []  // Never mutated in singleton mode - always empty

    // Optimization: Query ALL tracker timestamps once instead of per-day queries
    let allDatesSql = "SELECT date FROM trkrData ORDER BY date"
    let allTimestamps = tracker.toQry2AryI(sql: allDatesSql).map { TimeInterval($0) }

    // Group tracker timestamps by calendar day for fast lookup
    var timestampsByDay: [String: [TimeInterval]] = [:]
    for timestamp in allTimestamps {
      let date = Date(timeIntervalSince1970: timestamp)
      let components = calendar.dateComponents([.year, .month, .day], from: date)
      if let year = components.year, let month = components.month, let day = components.day {
        let dayKey = "\(year)-\(month)-\(day)"
        timestampsByDay[dayKey, default: []].append(timestamp)
      }
    }

    // Process each HK date
    for hkTimestamp in datesToMerge {
      let hkDate = Date(timeIntervalSince1970: hkTimestamp)
      guard hkDate <= now else { continue }  // Skip future dates

      // Get calendar day key for this HK timestamp
      let dayComponents = calendar.dateComponents([.year, .month, .day], from: hkDate)
      guard let year = dayComponents.year, let month = dayComponents.month, let day = dayComponents.day else {
        continue
      }
      let dayKey = "\(year)-\(month)-\(day)"

      // Fast dictionary lookup instead of database query
      guard let existingTimestamps = timestampsByDay[dayKey], !existingTimestamps.isEmpty else {
        // No tracker entry for this day - singleton does NOT create entries, skip
        //DBGLog("[\(srcName)] singleton: \(i2ltd(Int(hkTimestamp))) → SKIPPED (no trkrData for day)")
        continue
      }

      // Find closest tracker timestamp to the HK timestamp
      var closestTimestamp = existingTimestamps[0]
      var minDistance = abs(hkTimestamp - closestTimestamp)

      for trkrTimestamp in existingTimestamps {
        let distance = abs(hkTimestamp - trkrTimestamp)
        if distance < minDistance {
          minDistance = distance
          closestTimestamp = trkrTimestamp
        }
      }

      matchedDates.insert(closestTimestamp)
      DBGLog("[\(srcName)] singleton: \(i2ltd(Int(hkTimestamp))) → \(i2ltd(Int(closestTimestamp))) (Δ\(Int(minDistance/60))min)")
    }

    DBGLog("[\(srcName)] singleton: matched:\(matchedDates.count), new:\(newDates.count)")

    return (newDates: newDates, matchedDates: matchedDates)
  }

  /// Handles timestamp matching for trackers with ahkTimeSrc enabled
  /// Uses distance-sorted greedy algorithm to match HK samples to existing trkrData
  /// - Parameters:
  ///   - datesToMerge: HK sample timestamps to process
  ///   - tracker: The tracker object (for querying trkrData)
  ///   - srcName: Name of HK source (for logging)
  /// - Returns: Tuple of (newDates, matchedDates) sets
  private func handleHkTimeSrc(
    datesToMerge: [TimeInterval],
    tracker: trackerObj,
    srcName: String
  ) -> (newDates: Set<TimeInterval>, matchedDates: Set<TimeInterval>) {

    let calendar = Calendar.current
    let now = Date()

    // Get existing trkrData for same calendar day
    let dayComponents = calendar.dateComponents([.year, .month, .day],
      from: Date(timeIntervalSince1970: datesToMerge.first ?? 0))
    let dayStart = calendar.date(from: dayComponents)!
    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

    let existingDatesSql = """
      SELECT date FROM trkrData
      WHERE date >= \(Int(dayStart.timeIntervalSince1970))
      AND date < \(Int(dayEnd.timeIntervalSince1970))
      ORDER BY date
    """
    let existingTimestamps = tracker.toQry2AryI(sql: existingDatesSql).map { TimeInterval($0) }

    // Build candidate matches: all (hkSample, trkrDate, distance) pairs
    struct MatchCandidate {
      let hkTimestamp: TimeInterval
      let trkrTimestamp: TimeInterval
      let distance: TimeInterval
    }

    var candidates: [MatchCandidate] = []
    for hkTimestamp in datesToMerge {
      let hkDate = Date(timeIntervalSince1970: hkTimestamp)
      guard hkDate <= now else { continue }  // Skip future timestamps

      for trkrTimestamp in existingTimestamps {
        let distance = abs(hkTimestamp - trkrTimestamp)
        candidates.append(MatchCandidate(
          hkTimestamp: hkTimestamp,
          trkrTimestamp: trkrTimestamp,
          distance: distance
        ))
      }
    }

    // Sort by distance (shortest first) - KEY for optimal matching
    candidates.sort { $0.distance < $1.distance }

    // Greedy assignment: process shortest distances first
    var usedHkTimestamps = Set<TimeInterval>()
    var usedTrkrTimestamps = Set<TimeInterval>()
    var matchedDates: Set<TimeInterval> = []
    var newDates: Set<TimeInterval> = []

    for candidate in candidates {
      // If both timestamps are still available, match them
      if !usedHkTimestamps.contains(candidate.hkTimestamp) &&
         !usedTrkrTimestamps.contains(candidate.trkrTimestamp) {
        matchedDates.insert(candidate.trkrTimestamp)
        usedHkTimestamps.insert(candidate.hkTimestamp)
        usedTrkrTimestamps.insert(candidate.trkrTimestamp)

        #if DEBUGLOG
        if candidate.distance > 60 {
          DBGLog("  \(i2ltd(Int(candidate.hkTimestamp))) → \(i2ltd(Int(candidate.trkrTimestamp))) (Δ\(Int(candidate.distance/60))min)")
        }
        #endif
      }
    }

    // Any unmatched HK timestamps become new entries at their actual times
    for hkTimestamp in datesToMerge {
      let hkDate = Date(timeIntervalSince1970: hkTimestamp)
      guard hkDate <= now else { continue }

      if !usedHkTimestamps.contains(hkTimestamp) {
        newDates.insert(hkTimestamp)
        #if DEBUGLOG
        DBGLog("  \(i2ltd(Int(hkTimestamp))) → NEW (no unused trkrData)")
        #endif
      }
    }

    DBGLog("[\(srcName)] ahkTimeSrc: matched:\(matchedDates.count), new:\(newDates.count)")

    return (newDates: newDates, matchedDates: matchedDates)
  }

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

    // Get timeFilter for special handling
    let timeFilter = vo.optDict["ahTimeFilter"] ?? "all_day"

    // Calculate base start date from timestamp
    // Note: ahPrevD date shifting is now handled in loadHKdata by shifting storage dates forward
    let targetTimestamp = Date(timeIntervalSince1970: TimeInterval(timestamp))
    var startDate = targetTimestamp
    var endDate: Date? = nil

    // Singleton frequency: query ±2 hour window around target timestamp
    if frequency == "singleton" && queryConfig.aggregationType == .highFrequency {
      // Query ±2 hours around target timestamp for high-frequency data
      let windowHours = 2
      let windowStart = calendar.date(byAdding: .hour, value: -windowHours, to: targetTimestamp) ?? targetTimestamp
      let windowEnd = calendar.date(byAdding: .hour, value: windowHours, to: targetTimestamp) ?? targetTimestamp

      // Clamp to same calendar day boundaries
      let dayStart = calendar.startOfDay(for: targetTimestamp)
      let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
      startDate = max(windowStart, dayStart)
      endDate = min(windowEnd, dayEnd)
    } else {
      // Special handling for sleep_hours with daily frequency
      // Adjust startDate to 23:00 previous day to match the sleep hours window
      if timeFilter == "sleep_hours" && frequency == "daily" && queryConfig.aggregationType == .highFrequency {
        let trackerDay = calendar.startOfDay(for: startDate)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: trackerDay)!
        startDate = calendar.date(byAdding: .hour, value: 23, to: previousDay)!
      }

      // Calculate endDate for high-frequency processing
      // IMPORTANT: For high-frequency data, calculateEndDate returns a "backwards" endDate
      // (earlier than startDate) to indicate we want the interval BEFORE the slot timestamp.
      // This makes a 3pm slot represent 2pm-3pm data instead of 3pm-4pm data.
      // performHealthQuery will detect endDate < startDate and swap them for the HealthKit query.
      // EXCEPTION: sleep_hours with daily frequency returns proper forward endDate (06:00 tracker day)
      endDate = calculateEndDate(from: startDate, frequency: frequency, queryConfig: queryConfig, timeFilter: timeFilter)
    }

    // Prepare unit
    var unit: HKUnit? = nil
    if let unitString = vo.optDict["ahUnit"] {
      unit = HKUnit(from: unitString)
    }

    //DBGLog("Querying HealthKit for \(srcName) at \(ltd(startDate))" + (endDate != nil ? " to \(ltd(endDate!))" : "") + (unit != nil ? " unit: \(unit!)" : ""))

    // Make the query
    rthk.performHealthQuery(
      displayName: srcName,
      startDate: startDate,
      endDate: endDate,
      specifiedUnit: unit
    ) { allResults in
      let finalResult: rtHealthKit.HealthQueryResult?

      // Singleton frequency: find closest datapoint to target timestamp
      if frequency == "singleton" && queryConfig.aggregationType == .highFrequency {
        finalResult = self.findClosestResult(results: allResults, targetTimestamp: targetTimestamp)
      } else {
        // Normal processing: apply time filtering and aggregation
        let filteredResults = self.applyTimeFilter(
          results: allResults, timeFilter: self.vo.optDict["ahTimeFilter"] ?? "all_day")
        finalResult = self.applyAggregation(
          results: filteredResults, aggregation: self.vo.optDict["ahAggregation"] ?? "avg")
      }

      if let result = finalResult {
        /*
        DBGLog("aggregated result for \(srcName) at \(startDate) is \(result.value) \(result.unit) (timeFilter: \(self.vo.optDict["ahTimeFilter"] ?? "all_day"))")
        DBGLog("input set:")
        for result in filteredResults.sorted(by: { $0.date < $1.date }) {
          DBGLog("  \(result.date) \(result.value)")
        }
        */
        let formattedValue = self.formatHealthKitValue(result.value)
        completion(formattedValue)
      } else {
        completion(nil)
      }

      dispatchGroup?.leave()
    }
  }

  private func calculateEndDate(
    from startDate: Date, frequency: String, queryConfig: HealthDataQuery, timeFilter: String
  ) -> Date? {
    let calendar = Calendar.current

    // Special case: sleep_hours with daily frequency
    // startDate is 23:00 previous day, we need to return 06:00 tracker day
    if frequency == "daily" && timeFilter == "sleep_hours" && queryConfig.aggregationType == .highFrequency {
      // startDate is already at 23:00 previous day (adjusted in processHealthQuery)
      // Add 7 hours to get to 06:00 tracker day
      return calendar.date(byAdding: .hour, value: 7, to: startDate)
    }

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
    default: return nil  // daily, singleton - single point queries
    }

    // IMPORTANT: For high-frequency data, we want the interval BEFORE the slot timestamp
    // This makes a 3pm slot represent 2pm-3pm data instead of 3pm-4pm data
    // We return startDate - intervalHours, which will be detected and handled in performHealthQuery
    return calendar.date(byAdding: .hour, value: -intervalHours, to: startDate)
  }

  /// Finds the single closest HealthKit datapoint to a target timestamp
  /// Used by singleton frequency to pick one value per day
  /// - Parameters:
  ///   - results: All HealthKit results from the query (entire day)
  ///   - targetTimestamp: The tracker entry timestamp (from ahkTimeSrc or 12:00 noon)
  /// - Returns: The result with minimum time distance to target, or nil if no results
  private func findClosestResult(
    results: [rtHealthKit.HealthQueryResult],
    targetTimestamp: Date
  ) -> rtHealthKit.HealthQueryResult? {
    guard !results.isEmpty else { return nil }

    // Find result with minimum time distance
    var closestResult = results[0]
    var minDistance = abs(results[0].date.timeIntervalSince(targetTimestamp))

    for result in results {
      let distance = abs(result.date.timeIntervalSince(targetTimestamp))
      if distance < minDistance {
        minDistance = distance
        closestResult = result
      }
    }

    DBGLog("singleton: found closest HK datapoint at \(ltd(closestResult.date)) (Δ\(Int(minDistance/60))min from target \(ltd(targetTimestamp)))")

    return closestResult
  }

  private func applyTimeFilter(results: [rtHealthKit.HealthQueryResult], timeFilter: String)
    -> [rtHealthKit.HealthQueryResult]
  {
    return results.filter { result in
      // Extract local hour directly from UTC date (Calendar handles timezone conversion)
      let localHour = Calendar.current.component(.hour, from: result.date)
      //DBGLog("Filtering: \(ltd(result.date)) -> local hour \(localHour) for filter '\(timeFilter)'")

      switch timeFilter {
      case "morning": return localHour >= 6 && localHour < 10
      case "daytime": return localHour >= 10 && localHour < 18
      case "evening": return localHour >= 18 && localHour < 23
      case "sleep_hours": return localHour >= 23 || localHour < 6
      case "wake_hours": return localHour >= 6 && localHour < 23
      default: return true  // "all_day"
      }
    }
  }

  private func collapseTimeFilterWindow(
    timestamps: [TimeInterval],
    timeFilter: String?
  ) -> [TimeInterval] {
    // If no timeFilter specified, return input unchanged
    guard let timeFilter = timeFilter, timeFilter != "all_day" else {
      return timestamps
    }

    // Determine window bounds once
    let (windowStart, windowEnd): (Int, Int)
    switch timeFilter {
    case "morning":
      (windowStart, windowEnd) = (6, 10)
    case "daytime":
      (windowStart, windowEnd) = (10, 18)
    case "evening":
      (windowStart, windowEnd) = (18, 23)
    case "sleep_hours":
      (windowStart, windowEnd) = (23, 6)  // wraps midnight
    case "wake_hours":
      (windowStart, windowEnd) = (6, 23)
    default:
      return timestamps  // unknown filter - no change
    }

    let calendar = Calendar.current
    var result: [TimeInterval] = []
    var lastEntry: TimeInterval? = nil

    // Helper to check if hour is in window (handles midnight wrap)
    let isHourInWindow: (Int) -> Bool = { hour in
      if windowEnd > windowStart {
        // Same day window (e.g., 10-18)
        return hour >= windowStart && hour < windowEnd
      } else {
        // Crosses midnight (e.g., 23-6)
        return hour >= windowStart || hour < windowEnd
      }
    }

    // Process timestamps in order
    for timestamp in timestamps.sorted() {
      let date = Date(timeIntervalSince1970: timestamp)
      let localHour = calendar.component(.hour, from: date)

      if isHourInWindow(localHour) {
        // Store as last entry (overwrite any previous)
        lastEntry = timestamp
      } else {
        // Not in window - save the last entry if we have one
        if let entry = lastEntry {
          result.append(entry)
          lastEntry = nil  // Reset for next window
        }
      }
    }

    // Add final last entry if exists (for window that extends to end)
    if let entry = lastEntry {
      result.append(entry)
    }

    return result
  }

  private func applyAggregation(results: [rtHealthKit.HealthQueryResult], aggregation: String)
    -> rtHealthKit.HealthQueryResult?
  {
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
        aggregatedValue = (sortedValues[count / 2 - 1] + sortedValues[count / 2]) / 2.0
      } else {
        aggregatedValue = sortedValues[count / 2]
      }
    default:  // "avg"
      aggregatedValue = values.reduce(0.0, +) / Double(values.count)
    }

    return rtHealthKit.HealthQueryResult(
      date: lastResult.date, value: aggregatedValue, unit: lastResult.unit)
  }

  private func formatHealthKitValue(_ value: Double) -> String {
    if value.truncatingRemainder(dividingBy: 1) == 0 {
      return String(format: "%.0f", value)
    } else {
      return String(format: "%.2f", value)
    }
  }
}
