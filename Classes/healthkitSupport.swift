//
//  healthkitSupport.swift
//  rTracker
//
//  Created by Robert Miller on 02/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//
//import ZIPFoundation

import Foundation
import HealthKit

struct HealthDataQuery {
    let identifier: String                     // Unique HK identifier
    let displayName: String                    // User-friendly name for UI
    let categories: [Int]?                     // subcategories to filter sleep data
    let unit: [HKUnit]?                          // unit choice (optional)
    let needUnit: Bool                          // must specify unit or default to last saved
    let aggregationStyle: HKQuantityAggregationStyle // cumulative, discrete_options
    let customProcessor: ((HKSample) -> Double)? // custom processing logic (sleep aggregation)
    let aggregationType: AggregationType?       // custom grouping logic (night sleep)
    let aggregationTime: DateComponents?       // Optional time for aggregation (e.g., start/end of day). if specified, aggregate over previous day at this time to current day at this time.  if not specified, aggregate over supplied targDate +/- 10 hours
    let info: String?
    
    enum AggregationType {
        //case discreteArithmetic     // Independent values
        //case cumulativeDaily        // Daily aggregation (e.g., calories)
        case groupedByNight         // Nightly grouping (e.g., sleep analysis)
    }
}

let MINSLEEPSEGMENTDURATION = 3
let MAXSLEEPSEGMENTGAP = 12

let healthDataQueries: [HealthDataQuery] = [
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyFatPercentage",
        displayName: "Body Fat %",
        categories: nil,
        unit: nil, // still a fractional value so special case handling
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeight",
        displayName: "Body Height",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit(from: "cm"), HKUnit.foot(), HKUnit.inch()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyMass",
        displayName: "Body Weight",
        categories: nil,
        unit: [HKUnit.gramUnit(with: .kilo), HKUnit.pound(), HKUnit.stone()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyMassIndex",
        displayName: "Body Mass Index",
        categories: nil,
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierLeanBodyMass",
        displayName: "Body Lean Mass",
        categories: nil,
        unit: [HKUnit.gramUnit(with: .kilo), HKUnit.pound(), HKUnit.stone()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWaistCircumference",
        displayName: "Body Waist Circumference",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit(from: "cm"), HKUnit.foot(), HKUnit.inch()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil

    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Awake",
        categories: [HKCategoryValueSleepAnalysis.awake.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.awake.rawValue else {
                return 0
            }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "This is the total time awake"
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Core",
        categories: [HKCategoryValueSleepAnalysis.asleepCore.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue else {
                return 0
            }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - REM",
        categories: [HKCategoryValueSleepAnalysis.asleepREM.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue else {
                return 0
            }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Deep",
        categories: [HKCategoryValueSleepAnalysis.asleepDeep.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue else {
                return 0
            }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Total",
        categories: [HKCategoryValueSleepAnalysis.asleepDeep.rawValue, HKCategoryValueSleepAnalysis.asleepREM.rawValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative, // Aggregates sleep data across intervals
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample else {
                return 0
            }
            // Include all sleep-related categories
            if categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                // ||
                // categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            {
                return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
            }
            return 0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "Defined as core sleep plus REM sleep plus deep sleep."
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - In Bed",
        categories: [HKCategoryValueSleepAnalysis.inBed.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.inBed.rawValue else {
                return 0
            }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: nil
    ),
    // For counting Deep sleep segments
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Deep Segments",
        categories: [HKCategoryValueSleepAnalysis.asleepDeep.rawValue],
        unit: [HKUnit.count()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue else {
                return 0
            }
            // The actual segment calculation will happen in a specialized processor
            return 1 // Return 1 to collect all Deep sleep samples for processing
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "Counts the number of Deep sleep segments during the night. Short gaps (up to \(MAXSLEEPSEGMENTGAP) minutes) of Core sleep within a Deep sleep period are still counted as a single segment."
    ),

    // For counting REM sleep segments
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - REM Segments",
        categories: [HKCategoryValueSleepAnalysis.asleepREM.rawValue],
        unit: [HKUnit.count()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue else {
                return 0
            }
            // The actual segment calculation will happen in a specialized processor
            return 1 // Return 1 to collect all REM sleep samples for processing
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "Counts the number of REM sleep segments during the night. Short gaps (up to \(MAXSLEEPSEGMENTGAP) minutes) of Core sleep within a REM sleep period are still counted as a single segment."
    ),

    // For counting sleep cycles (Deep followed by REM)
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Cycles",
        categories: [HKCategoryValueSleepAnalysis.asleepDeep.rawValue, HKCategoryValueSleepAnalysis.asleepREM.rawValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.awake.rawValue],
        unit: [HKUnit.count()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            // This is a placeholder - actual cycle detection needs all samples
            return 0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "Counts complete sleep cycles, defined as a Deep sleep segment minutes) followed by a REM segment (both at least \(MINSLEEPSEGMENTDURATION) minutes)."
    ),

    // For counting sleep transitions
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Transitions",
        categories: [HKCategoryValueSleepAnalysis.asleepDeep.rawValue, HKCategoryValueSleepAnalysis.asleepREM.rawValue, HKCategoryValueSleepAnalysis.asleepCore.rawValue, HKCategoryValueSleepAnalysis.awake.rawValue],
        unit: [HKUnit.count()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            // This is a placeholder - actual transition counting needs all samples
            return 0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "Counts the number of transitions between different sleep stages (Core/Deep/REM/Awake) from sleep onset to waking up."
    ),
    
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRate",
        displayName: "Heart Rate",
        categories: nil,
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
        displayName: "Heart Rate Variability SDNN",
        categories: nil,
        unit: [HKUnit.secondUnit(with: .milli)],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierRestingHeartRate",
        displayName: "Resting Heart Rate",
        categories: nil,
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRateRecoveryOneMinute",
        displayName: "Heart Rate Recovery - One Minute",
        categories: nil,
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodGlucose",
        displayName: "Blood Glucose",
        categories: nil,
        unit: [HKUnit.gramUnit(with: .milli).unitDivided(by: .literUnit(with: .deci))],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierOxygenSaturation",
        displayName: "Oxygen Saturation",
        categories: nil,
        unit: [HKUnit.percent()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodGlucose",
        displayName: "Resting Heart Rate",
        categories: nil,
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyTemperature",
        displayName: "Basal Body Temperature",
        categories: nil,
        unit: [HKUnit.degreeCelsius(), HKUnit.degreeFahrenheit()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBasalBodyTemperature",
        displayName: "Body Temperature",
        categories: nil,
        unit: [HKUnit.degreeCelsius(), HKUnit.degreeFahrenheit()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodPressureSystolic",
        displayName: "Blood Pressure Systolic",
        categories: nil,
        unit: [HKUnit.millimeterOfMercury()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodPressureDiastolic",
        displayName: "Blood Pressure Diastolic",
        categories: nil,
        unit: [HKUnit.millimeterOfMercury()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierActiveEnergyBurned",
        displayName: "Active Energy Burned",
        categories: nil,
        unit: [HKUnit.largeCalorie()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0), // midnight
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBasalEnergyBurned",
        displayName: "Basal Energy Burned",
        categories: nil,
        unit: [HKUnit.largeCalorie()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0), // midnight
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStepCount",
        displayName: "Step Count",
        categories: nil,
        unit: nil,
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0), // midnight
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierFlightsClimbed",
        displayName: "Flights Climbed",
        categories: nil,
        unit: nil,
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0), // midnight
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierDistanceWalkingRunning",
        displayName: "Distance Walking/Running",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0), // midnight
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierDistanceCycling",
        displayName: "Distance Cycling",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0), // midnight
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierPhysicalEffort",
        displayName: "Physical Effort",
        categories: nil,
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWorkoutEffortScore",
        displayName: "Workout Effort Score",
        categories: nil,
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStairAscentSpeed",
        displayName: "Stair Ascent Speed",
        categories: nil,
        unit: [HKUnit(from: "m/s")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStairDescentSpeed",
        displayName: "Stair Descent Speed",
        categories: nil,
        unit: [HKUnit(from: "m/s")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierSixMinuteWalkTestDistance",
        displayName: "Walk Test Distance - 6 minute",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWalkingSpeed",
        displayName: "Walking Speed",
        categories: nil,
        unit: [HKUnit(from: "m/s")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWalkingStepLength",
        displayName: "Walking Step Length",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWalkingAsymmetryPercentage",
        displayName: "Walking Asymmetry %",
        categories: nil,
        unit: [HKUnit.percent()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: nil
    ),
]

enum enableStatus: Int {
    case enabled = 1
    case notAuthorised = 2
    case notPresent = 3
    case hidden = 4
}

class rtHealthKit: ObservableObject {   // }, XMLParserDelegate {
    static let shared = rtHealthKit()  // singleton class
    //--- Healthkit specific
    
    let healthStore = HKHealthStore()
    var tl : trackerList? = nil
    var dbInitialised = false;

    @Published var configurations: [HealthDataQuery] = []
    
    init() {
        //super.init()
        DBGLog("rtHealthKit init called")
        tl = RootViewController.shared.tlist
        let sql = "select count(*) from rthealthkit"
        dbInitialised = (tl?.toQry2Int(sql:sql) ?? 0) != 0
        loadHealthKitConfigurations()
    }


    func updateAuthorisations(completion: @escaping () -> Void) {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            requestHealthKitAuthorization(healthDataQueries: healthDataQueries) { success, error in
                if let error = error {
                    DBGLog("HealthKit authorization failed with error: \(error.localizedDescription)")
                } else {
                    DBGLog("HealthKit authorization \(success ? "succeeded" : "failed").")
                }
                dispatchGroup.leave()
            }
            
            // this notify section is waiting until until leave() corresponding to enter() above is triggered
            dispatchGroup.notify(queue: .main) { [self] in
                let dispatchGroup3 = DispatchGroup()
                for query in healthDataQueries {
                    // Start a new group task for each query
                    dispatchGroup3.enter()
                    
                    var status: HKAuthorizationStatus = .notDetermined
                    var dataExists = false
                    
                    let processQueryResult: () -> Void = {
                        DispatchQueue.main.async {
                            DBGLog("\(query.identifier) \(query.displayName) data= \(dataExists)")
                            if status == .sharingAuthorized && dataExists {
                            }
                            
                            if status == .notDetermined {
                                DBGLog("\(query.displayName): Not Determined")
                            } else if status == .sharingAuthorized && dataExists {  // fix disabled column if in db otherwise no entry default is use
                                let sql = """
                                insert into rthealthkit (name, hkid, disabled) 
                                values ('\(query.displayName)','\(query.identifier)', \(enableStatus.enabled.rawValue)) 
                                on conflict(name) do update set disabled = \(enableStatus.enabled.rawValue);
                                """
                                self.tl?.toExecSql(sql: sql)
                                DBGLog("\(query.displayName): Authorized and Data Available")
                            } else if status == .sharingAuthorized && !dataExists {
                                let sql = """
                                insert into rthealthkit (name, hkid, disabled) 
                                values ('\(query.displayName)','\(query.identifier)', \(enableStatus.notPresent.rawValue)) 
                                on conflict(name) do update set disabled = \(enableStatus.notPresent.rawValue);
                                """
                                self.tl?.toExecSql(sql: sql)
                                DBGLog("\(query.displayName): Authorized but No Data Present")
                            } else { // .sharingDenied
                                let sql = """
                                insert into rthealthkit (name, hkid, disabled) 
                                values ('\(query.displayName)','\(query.identifier)', \(enableStatus.notAuthorised.rawValue)) 
                                on conflict(name) do update set disabled = \(enableStatus.notAuthorised.rawValue);
                                """
                                self.tl?.toExecSql(sql: sql)
                                DBGLog("\(query.displayName): Sharing Denied (\(status))")
                            }
                            dispatchGroup3.leave() // Mark this task as completed
                        }
                    }
                    if query.identifier.hasPrefix("HKQuantityTypeIdentifier"),
                       let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: query.identifier)) {
                        status = healthStore.authorizationStatus(for: quantityType)  // only checks write access, cannot query read access
                        
                        if (status == .sharingAuthorized || status == .sharingDenied) {  // reading denied same as reading no data present
                            status = .sharingAuthorized
                            let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: [])
                            let sampleQuery = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: nil) { (_, samples, _) in
                                DBGLog("\(query.identifier) \(query.displayName) \(samples?.count ?? -1)")
                                dataExists = (samples?.count ?? 0) > 0
                                processQueryResult()
                            }
                            healthStore.execute(sampleQuery)
                        } else {
                            processQueryResult()
                        }
                    } else if query.identifier.hasPrefix("HKCategoryTypeIdentifier"),
                              let categoryType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: query.identifier)) {
                        status = healthStore.authorizationStatus(for: categoryType)
                        
                        if (status == .sharingAuthorized || status == .sharingDenied) {
                            status = .sharingAuthorized
                            var predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: [])
                            
                            if query.identifier == "HKCategoryTypeIdentifierSleepAnalysis" {  // filter on sleep sample types
                                let displayName = query.displayName
                                let components = displayName.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
                                if components.count > 1 {
                                    let suffix = components[1].trimmingCharacters(in: .whitespaces) // Extract and trim the part after '-'
                                    switch suffix {
                                    case "In Bed":
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.inBed.rawValue)
                                                ])
                                    case "Deep":
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
                                                ])
                                    case "Total":  // assume core will always be present at some point for total sleep
                                        fallthrough
                                    case "Core":
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepCore.rawValue)
                                                ])
                                    case "REM":
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue)
                                                ])
                                    case "Awake":
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.awake.rawValue)
                                                ])
                                    // Add cases for the new sleep metrics
                                    case "Deep Segments":
                                        // For Deep Segments, check if any Deep sleep data exists
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
                                                ])
                                    case "REM Segments":
                                        // For REM Segments, check if any REM sleep data exists
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue)
                                                ])
                                    case "Cycles":
                                        // For Sleep Cycles, check if both Deep and REM sleep data exist
                                        // Since we need both, let's check for Deep sleep here (simplification)
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
                                                ])
                                    case "Transitions":
                                        // For Transitions, we'll just check if any sleep data exists
                                        // This is a simplified approach - ideally we'd check for multiple stages
                                        predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: [])
                                    default:
                                        DBGErr("Unhandled display name suffix: \(suffix)")
                                        // Handle other cases
                                    }
                                } else {
                                    DBGErr("No suffix found in displayName: \(displayName)")
                                    // Handle cases where there is no '-'
                                }
                                
                            }
                            let sampleQuery = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: 1, sortDescriptors: nil) { (_, samples, _) in
                                dataExists = (samples?.count ?? 0) > 0
                                
                                // Special handling for "Sleep - Cycles" which needs both Deep and REM
                                if query.displayName == "Sleep - Cycles" && dataExists {
                                    // We checked for Deep sleep above, now check for REM
                                    let remPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                        HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                        NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue)
                                    ])
                                    
                                    let remQuery = HKSampleQuery(sampleType: categoryType, predicate: remPredicate, limit: 1, sortDescriptors: nil) { (_, remSamples, _) in
                                        // Data exists only if both Deep and REM sleep data exist
                                        dataExists = dataExists && (remSamples?.count ?? 0) > 0
                                        processQueryResult()
                                    }
                                    self.healthStore.execute(remQuery)
                                } else {
                                    processQueryResult()
                                }
                            }
                            healthStore.execute(sampleQuery)
                        } else {
                            processQueryResult()
                        }
                    } else {
                        processQueryResult()
                    }
                }
                // Notify when all tasks are done
                dispatchGroup3.notify(queue: .main) {
                    DBGLog("updateAuthorisations All HealthKit queries completed.")
                    self.dbInitialised = true
                    completion() // Call the completion handler in loadHealthKitConfigurations
                }
            }
        }

    func requestHealthKitAuthorization(healthDataQueries: [HealthDataQuery], completion: @escaping (Bool, Error?) -> Void) {
        // Ensure HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        let healthStore = HKHealthStore()
        
        // Extract HKObjectTypes from healthDataQueries
        var readTypes: Set<HKObjectType> = []
        
        for query in healthDataQueries {
            if query.identifier.hasPrefix("HKQuantityTypeIdentifier") {
                if let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: query.identifier)) {
                    readTypes.insert(quantityType)
                }
            } else if query.identifier.hasPrefix("HKCategoryTypeIdentifier") {
                if let categoryType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: query.identifier)) {
                    readTypes.insert(categoryType)
                }
            }
        }
        
        // Request Authorization
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            completion(success, error)
        }
    }
    
    func loadHealthKitConfigurations() {
        let dispatchGroup2 = DispatchGroup()
        
        if !dbInitialised {
            dispatchGroup2.enter()
            DBGLog("load configs not dbinit so updateAuths")
            updateAuthorisations(completion: {
                dispatchGroup2.leave()
            })
            
            // Wait for updateAuthorisations to complete
            //dispatchGroup2.wait()
        }

        dispatchGroup2.notify(queue: .main) { [self] in
            // Query user preferences
            let sql = """
            SELECT name, hkid, custom_unit, disabled
            FROM rthealthkit;
            """
            let sqlConfig = tl!.toQry2ArySSSI(sql: sql)
            
            var userPreferences: [String: (hkid: String, customUnit: String?, disabled: Int)] = [:]
            for (n, k, u, d) in sqlConfig {
                userPreferences[n] = (k, u, d)
            }
            
            var localConfigurations: [HealthDataQuery] = []  // temporary storage
            
            // Merge with hardcoded table
            for query in healthDataQueries {
                var unit = query.unit
                var disabled = enableStatus.hidden.rawValue
                if let preference = userPreferences[query.displayName] {
                    disabled = preference.disabled
                    unit = preference.customUnit != "" ? [HKUnit(from: preference.customUnit!)] : query.unit
                }
                if disabled == enableStatus.enabled.rawValue {  // if the disabled field holds 'enabled'
                    localConfigurations.append(HealthDataQuery(
                        identifier: query.identifier,
                        displayName: query.displayName,
                        categories: query.categories,
                        unit: unit,
                        needUnit: query.needUnit,
                        aggregationStyle: query.aggregationStyle,
                        customProcessor: query.customProcessor,
                        aggregationType: query.aggregationType,
                        aggregationTime: query.aggregationTime,
                        info: query.info
                    ))
                }
            }
            
            // Assign to backing variable
            configurations = localConfigurations
        }
    }

    // Define a struct to hold the results
    struct HealthQueryResult {
        let date: Date
        let value: Double
        let unit: HKUnit
    }

    private func handleSleepAnalysisQuery(
        startDate: Date,
        endDate: Date,
        specifiedUnit: HKUnit,
        queryConfig: HealthDataQuery,
        completion: @escaping ([HealthQueryResult]) -> Void
    ) {
        DBGLog("sleepAnalysisQuery startDate \(startDate) endDate \(endDate) name \(queryConfig.displayName)")
        guard let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            DBGLog("Unsupported sample type for sleep analysis.")
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            guard error == nil else {
                DBGLog("Error querying HealthKit: \(error!.localizedDescription)")
                completion([])
                return
            }
            
            guard let categorySamples = samples as? [HKCategorySample] else {
                DBGLog("No category samples found.")
                completion([])
                return
            }
            
            var results: [HealthQueryResult] = []
            
            // Handle specialized sleep metrics
            switch queryConfig.displayName {
            case "Sleep - Deep Segments":
                let segmentCount = self.countSleepSegments(
                    samples: categorySamples,
                    targetValue: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    allowedGapValues: [ HKCategoryValueSleepAnalysis.asleepCore.rawValue: TimeInterval(MAXSLEEPSEGMENTGAP * 60)],  // 12 minutes of Core sleep
                    maxGapMinutes: MAXSLEEPSEGMENTGAP,
                    minDurationMinutes: MINSLEEPSEGMENTDURATION
                )
                if segmentCount > 0 {
                    results.append(HealthQueryResult(
                        date: startDate,
                        value: Double(segmentCount),
                        unit: specifiedUnit
                    ))
                }
                
            case "Sleep - REM Segments":
                let segmentCount = self.countSleepSegments(
                    samples: categorySamples,
                    targetValue: HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    allowedGapValues: [
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue: TimeInterval(MAXSLEEPSEGMENTGAP * 60),  // 12 minutes of Core sleep
                        HKCategoryValueSleepAnalysis.awake.rawValue: TimeInterval(2 * 60)          // 2 minutes of Awake
                    ],
                    maxGapMinutes: MAXSLEEPSEGMENTGAP,  // For backward compatibility
                    minDurationMinutes: MINSLEEPSEGMENTDURATION
                )
                if segmentCount > 0 {
                    results.append(HealthQueryResult(
                        date: startDate,
                        value: Double(segmentCount),
                        unit: specifiedUnit
                    ))
                }
                
            case "Sleep - Cycles":
                let cycleCount = self.countSleepCycles(
                    samples: categorySamples,
                    minSegmentMinutes: MINSLEEPSEGMENTDURATION
                )
                if cycleCount > 0 {
                    results.append(HealthQueryResult(
                        date: startDate,
                        value: Double(cycleCount),
                        unit: specifiedUnit
                    ))
                }
                
            case "Sleep - Transitions":
                let transitionCount = self.countSleepTransitions(samples: categorySamples)
                if transitionCount > 0 {
                    results.append(HealthQueryResult(
                        date: startDate,
                        value: Double(transitionCount),
                        unit: specifiedUnit
                    ))
                }
                
            default:
                // Handle regular sleep analysis metrics (using original code)
                switch queryConfig.aggregationStyle {
                case .cumulative:
                    var totalValue = categorySamples.reduce(0.0) { total, sample in
                        total + (queryConfig.customProcessor?(sample) ?? 0)
                    }
                    if totalValue > 0 {
                        if specifiedUnit == HKUnit.hour() {
                            totalValue /= 60.0
                        }
                        results.append(HealthQueryResult(date: startDate, value: totalValue, unit: specifiedUnit))
                    }
                case .discreteArithmetic:
                    results = categorySamples.compactMap { sample in
                        var processedValue = queryConfig.customProcessor?(sample) ?? 0
                        if specifiedUnit == HKUnit.hour() {
                            processedValue /= 60.0
                        }
                        return processedValue > 0 ? HealthQueryResult(date: sample.startDate, value: processedValue, unit: specifiedUnit) : nil
                    }
                case .discreteEquivalentContinuousLevel:
                    fallthrough
                case .discreteTemporallyWeighted:
                    fallthrough
                default:
                    DBGErr("aggregation Style \(queryConfig.aggregationStyle) not handled")
                }
            }
            
            completion(results)
        }
        
        healthStore.execute(query)
    }

    // Helper method to count sleep cycles (Deep followed by REM)
    private func countSleepCycles(samples: [HKCategorySample], minSegmentMinutes: Int) -> Int {
        guard !samples.isEmpty else {
            return 0
        }
        
        // Identify Deep and REM segments
        let deepSegments = identifySleepSegments(
            samples: samples,
            targetValue: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            allowedGapValues: [
                HKCategoryValueSleepAnalysis.asleepCore.rawValue: TimeInterval(MAXSLEEPSEGMENTGAP * 60)  // 12 minutes of Core sleep
            ],
            minDurationMinutes: minSegmentMinutes
        )
        
        let remSegments = identifySleepSegments(
            samples: samples,
            targetValue: HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            allowedGapValues: [
                HKCategoryValueSleepAnalysis.asleepCore.rawValue: TimeInterval(MAXSLEEPSEGMENTGAP * 60),  // 12 minutes of Core sleep
                HKCategoryValueSleepAnalysis.awake.rawValue: TimeInterval(2 * 60)          // 2 minutes of Awake
            ],
            minDurationMinutes: minSegmentMinutes
        )
        
        // Identify Awake segments of at least 2 minutes
        let awakeSegments = identifySleepSegments(
            samples: samples,
            targetValue: HKCategoryValueSleepAnalysis.awake.rawValue,
            allowedGapValues: [:], // No gaps allowed in awake segments
            minDurationMinutes: 2  // Only consider awake periods of 2+ minutes
        )
        
        // Create a combined list of all segment types
        enum SegmentType { case deep, rem, awake }
        
        struct TypedSegment {
            let segment: SleepSegment
            let type: SegmentType
            let index: Int
        }
        
        var combinedSegments: [TypedSegment] = []
        
        for (index, segment) in deepSegments.enumerated() {
            combinedSegments.append(TypedSegment(segment: segment, type: .deep, index: index))
        }
        
        for (index, segment) in remSegments.enumerated() {
            combinedSegments.append(TypedSegment(segment: segment, type: .rem, index: index))
        }
        
        for (index, segment) in awakeSegments.enumerated() {
            combinedSegments.append(TypedSegment(segment: segment, type: .awake, index: index))
        }
        
        // Sort the combined list by start time
        combinedSegments.sort { $0.segment.start < $1.segment.start }
        
        // Count Deep→REM transitions (no Awake segments between them)
        var cycleCount = 0
        if combinedSegments.count > 1 {
            for i in 0..<(combinedSegments.count - 1) {
                let current = combinedSegments[i]
                
                // Only consider Deep segments as potential cycle starts
                if current.type == .deep {
                    // Look at the next segment
                    let next = combinedSegments[i + 1]
                    
                    if next.type == .rem {
                        // Found a direct Deep→REM transition
                        cycleCount += 1
                    }
                }
            }
        }
        return cycleCount
    }
    
    
    

    // Helper struct to represent a sleep segment
    private struct SleepSegment {
        let start: Date
        let end: Date
        let duration: TimeInterval
        
        var durationMinutes: Double {
            return duration / 60.0
        }
    }

    // Helper method to identify sleep segments of a particular stage
     private func identifySleepSegments(
        samples: [HKCategorySample],
        targetValue: Int,
        allowedGapValues: [Int: TimeInterval], // Map of sleep stage values to maximum allowed gap durations
        minDurationMinutes: Int
    ) -> [SleepSegment] {
        guard !samples.isEmpty else { return [] }
        
        // Sort samples by start time
        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
        
        var segments: [SleepSegment] = []
        var currentSegmentStart: Date?
        var currentSegmentEnd: Date?
        //var lastTargetSampleEndDate: Date?
        var cumulativeGapDuration: TimeInterval = 0
        var lastSampleEndDate: Date?
        
        for sample in sortedSamples {
            if sample.value == targetValue {
                // Found a target sleep stage sample
                if currentSegmentStart == nil {
                    // This is the start of a new segment
                    currentSegmentStart = sample.startDate
                }
                currentSegmentEnd = sample.endDate
                //lastTargetSampleEndDate = sample.endDate
                lastSampleEndDate = sample.endDate
                cumulativeGapDuration = 0 // Reset cumulative gap since we found a target sample
            } else if currentSegmentStart != nil, let maxGapDuration = allowedGapValues[sample.value] {
                // This is a gap of an allowed sleep stage
                let thisSampleDuration = sample.endDate.timeIntervalSince(sample.startDate)
                
                // Check if there's no time gap between this sample and the previous sample
                let hasNoPrecedingGap = lastSampleEndDate != nil &&
                                        sample.startDate.timeIntervalSince(lastSampleEndDate!) <= 1 // Allow 1 second tolerance
                
                // Calculate the updated cumulative gap if we add this sample
                let updatedGapDuration = hasNoPrecedingGap ? cumulativeGapDuration + thisSampleDuration : thisSampleDuration
                
                // Check if the individual sample and cumulative gap are within limits
                //let maxGapMinutes = maxGapDuration / 60.0 // Convert to minutes for consistency
                let isIndividualGapValid = thisSampleDuration <= maxGapDuration
                let isCumulativeGapValid = updatedGapDuration <= maxGapDuration
                
                if isIndividualGapValid && isCumulativeGapValid {
                    // This is an acceptable gap, continue the current segment
                    cumulativeGapDuration = updatedGapDuration
                } else {
                    // Gap is too long, end the current segment
                    if let start = currentSegmentStart, let end = currentSegmentEnd {
                        let duration = end.timeIntervalSince(start)
                        if duration / 60.0 >= Double(minDurationMinutes) {
                            segments.append(SleepSegment(start: start, end: end, duration: duration))
                        }
                    }
                    currentSegmentStart = nil
                    currentSegmentEnd = nil
                    cumulativeGapDuration = 0
                }
                
                lastSampleEndDate = sample.endDate
            } else {
                // This is a different sleep stage, end the current segment
                if let start = currentSegmentStart, let end = currentSegmentEnd {
                    let duration = end.timeIntervalSince(start)
                    if duration / 60.0 >= Double(minDurationMinutes) {
                        segments.append(SleepSegment(start: start, end: end, duration: duration))
                    }
                }
                currentSegmentStart = nil
                currentSegmentEnd = nil
                cumulativeGapDuration = 0
            }
        }
        
        // Don't forget to add the last segment if it's still open
        if let start = currentSegmentStart, let end = currentSegmentEnd {
            let duration = end.timeIntervalSince(start)
            if duration / 60.0 >= Double(minDurationMinutes) {
                segments.append(SleepSegment(start: start, end: end, duration: duration))
            }
        }
        
        return segments
    }
     
    /*
    //-----
    
    private func identifySleepSegments(
        samples: [HKCategorySample],
        targetValue: Int,
        allowedGapValues: [Int: TimeInterval], // Map of sleep stage values to maximum allowed gap durations
        minDurationMinutes: Int
    ) -> [SleepSegment] {
        guard !samples.isEmpty else {
            DBGLog("identifySleepSegments: No samples provided for target value \(targetValue)")
            return []
        }
        
        // Check for Mar 1-2 night for debugging
        if let firstSample = samples.first {
            let calendar = Calendar.current
            let sampleDay = calendar.component(.day, from: firstSample.startDate)
            let sampleMonth = calendar.component(.month, from: firstSample.startDate)
            let sampleYear = calendar.component(.year, from: firstSample.startDate)
            
            if ((sampleDay == 1 && sampleMonth == 3) || (sampleDay == 2 && sampleMonth == 3)) && sampleYear == 2025 {
                DBGLog("⚠️ BREAKPOINT: Mar 1-2, 2025 data - examining \(samples.count) samples for target value \(targetValue) ⚠️")
                // Set breakpoint here
            }
        }
        
        // Sort samples by start time
        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
        
        DBGLog("identifySleepSegments: Processing \(sortedSamples.count) samples for target value \(targetValue)")
        DBGLog("identifySleepSegments: Min duration requirement: \(minDurationMinutes) minutes")
        DBGLog("identifySleepSegments: Allowed gap values: \(allowedGapValues.map { "[\($0): \(Int($1/60)) min]" }.joined(separator: ", "))")
        
        // Map sleep stage values to descriptive names for logging
        let stageDescriptions: [Int: String] = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue: "Core",
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue: "Deep",
            HKCategoryValueSleepAnalysis.asleepREM.rawValue: "REM",
            HKCategoryValueSleepAnalysis.awake.rawValue: "Awake",
            HKCategoryValueSleepAnalysis.inBed.rawValue: "InBed"
        ]
        
        // Log first 5 and last 5 samples to understand data boundaries
        if sortedSamples.count > 0 {
            DBGLog("identifySleepSegments: Time range - \(sortedSamples.first!.startDate) to \(sortedSamples.last!.endDate)")
            
            let samplesToLog = min(5, sortedSamples.count)
            DBGLog("identifySleepSegments: First \(samplesToLog) samples:")
            for i in 0..<samplesToLog {
                let sample = sortedSamples[i]
                let stageName = stageDescriptions[sample.value] ?? "Unknown(\(sample.value))"
                let durationMin = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                DBGLog("  [\(i+1)] \(stageName): \(sample.startDate) to \(sample.endDate) (\(String(format: "%.1f", durationMin)) min)")
            }
            
            if sortedSamples.count > 10 {
                DBGLog("identifySleepSegments: Last \(samplesToLog) samples:")
                for i in (sortedSamples.count - samplesToLog)..<sortedSamples.count {
                    let sample = sortedSamples[i]
                    let stageName = stageDescriptions[sample.value] ?? "Unknown(\(sample.value))"
                    let durationMin = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
                    DBGLog("  [\(i+1)] \(stageName): \(sample.startDate) to \(sample.endDate) (\(String(format: "%.1f", durationMin)) min)")
                }
            }
        }
        
        let targetStageName = stageDescriptions[targetValue] ?? "Unknown(\(targetValue))"
        DBGLog("identifySleepSegments: Identifying \(targetStageName) segments...")
        
        var segments: [SleepSegment] = []
        var currentSegmentStart: Date?
        var currentSegmentEnd: Date?
        var cumulativeGapDuration: TimeInterval = 0
        var lastSampleEndDate: Date?
        var segmentNumber = 0
        
        for (index, sample) in sortedSamples.enumerated() {
            let stageName = stageDescriptions[sample.value] ?? "Unknown(\(sample.value))"
            let durationMin = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            
            if sample.value == targetValue {
                // Found a target sleep stage sample
                if currentSegmentStart == nil {
                    // This is the start of a new segment
                    currentSegmentStart = sample.startDate
                    segmentNumber += 1
                    DBGLog("  [\(index+1)] Starting new \(targetStageName) segment #\(segmentNumber) at \(sample.startDate)")
                } else {
                    DBGLog("  [\(index+1)] Continuing \(targetStageName) segment #\(segmentNumber) with sample: \(sample.startDate) to \(sample.endDate) (\(String(format: "%.1f", durationMin)) min)")
                }
                
                currentSegmentEnd = sample.endDate
                lastSampleEndDate = sample.endDate
                
                if cumulativeGapDuration > 0 {
                    DBGLog("    Resetting cumulative gap (was \(String(format: "%.1f", cumulativeGapDuration/60)) min) - found target sample")
                    cumulativeGapDuration = 0
                }
            } else if currentSegmentStart != nil, let maxGapDuration = allowedGapValues[sample.value] {
                // This is a gap of an allowed sleep stage
                let thisSampleDuration = sample.endDate.timeIntervalSince(sample.startDate)
                
                // Check if there's no time gap between this sample and the previous sample
                let hasNoPrecedingGap = lastSampleEndDate != nil &&
                                       sample.startDate.timeIntervalSince(lastSampleEndDate!) <= 1 // Allow 1 second tolerance
                
                // Calculate the updated cumulative gap if we add this sample
                let updatedGapDuration = hasNoPrecedingGap ? cumulativeGapDuration + thisSampleDuration : thisSampleDuration
                
                // Check if the individual sample and cumulative gap are within limits
                let isIndividualGapValid = thisSampleDuration <= maxGapDuration
                let isCumulativeGapValid = updatedGapDuration <= maxGapDuration
                
                DBGLog("  [\(index+1)] Checking \(stageName) gap: \(sample.startDate) to \(sample.endDate) (\(String(format: "%.1f", durationMin)) min)")
                DBGLog("    Gap follows previous sample: \(hasNoPrecedingGap)")
                DBGLog("    Individual gap duration: \(String(format: "%.1f", thisSampleDuration/60)) min (max allowed: \(String(format: "%.1f", maxGapDuration/60)) min) - Valid: \(isIndividualGapValid)")
                DBGLog("    Cumulative gap duration would be: \(String(format: "%.1f", updatedGapDuration/60)) min (max allowed: \(String(format: "%.1f", maxGapDuration/60)) min) - Valid: \(isCumulativeGapValid)")
                
                if isIndividualGapValid && isCumulativeGapValid {
                    // This is an acceptable gap, continue the current segment
                    cumulativeGapDuration = updatedGapDuration
                    DBGLog("    ✓ Gap accepted - segment #\(segmentNumber) continues, cumulative gap now \(String(format: "%.1f", cumulativeGapDuration/60)) min")
                } else {
                    // Gap is too long, end the current segment
                    if let start = currentSegmentStart, let end = currentSegmentEnd {
                        let duration = end.timeIntervalSince(start)
                        let durationMin = duration / 60.0
                        
                        if durationMin >= Double(minDurationMinutes) {
                            segments.append(SleepSegment(start: start, end: end, duration: duration))
                            DBGLog("    ✓ Segment #\(segmentNumber) ended and SAVED: \(start) to \(end) (\(String(format: "%.1f", durationMin)) min)")
                        } else {
                            DBGLog("    ✗ Segment #\(segmentNumber) too short: \(String(format: "%.1f", durationMin)) min < minimum \(minDurationMinutes) min - DISCARDED")
                        }
                    }
                    
                    currentSegmentStart = nil
                    currentSegmentEnd = nil
                    cumulativeGapDuration = 0
                    DBGLog("    ✗ Gap too long - segment ended")
                }
                
                lastSampleEndDate = sample.endDate
            } else {
                // This is a different, non-allowed sleep stage
                if currentSegmentStart != nil {
                    DBGLog("  [\(index+1)] Found non-allowed stage (\(stageName)) - ending current segment #\(segmentNumber)")
                    
                    if let start = currentSegmentStart, let end = currentSegmentEnd {
                        let duration = end.timeIntervalSince(start)
                        let durationMin = duration / 60.0
                        
                        if durationMin >= Double(minDurationMinutes) {
                            segments.append(SleepSegment(start: start, end: end, duration: duration))
                            DBGLog("    ✓ Segment #\(segmentNumber) ended and SAVED: \(start) to \(end) (\(String(format: "%.1f", durationMin)) min)")
                        } else {
                            DBGLog("    ✗ Segment #\(segmentNumber) too short: \(String(format: "%.1f", durationMin)) min < minimum \(minDurationMinutes) min - DISCARDED")
                        }
                    }
                    
                    currentSegmentStart = nil
                    currentSegmentEnd = nil
                    cumulativeGapDuration = 0
                } else {
                    DBGLog("  [\(index+1)] Skipping non-target, non-allowed stage: \(stageName)")
                }
            }
        }
        
        // Don't forget to add the last segment if it's still open
        if let start = currentSegmentStart, let end = currentSegmentEnd {
            let duration = end.timeIntervalSince(start)
            let durationMin = duration / 60.0
            
            if durationMin >= Double(minDurationMinutes) {
                segments.append(SleepSegment(start: start, end: end, duration: duration))
                DBGLog("  ✓ Final segment #\(segmentNumber) SAVED: \(start) to \(end) (\(String(format: "%.1f", durationMin)) min)")
            } else {
                DBGLog("  ✗ Final segment #\(segmentNumber) too short: \(String(format: "%.1f", durationMin)) min < minimum \(minDurationMinutes) min - DISCARDED")
            }
        }
        
        DBGLog("identifySleepSegments: Found \(segments.count) valid \(targetStageName) segments")
        for (index, segment) in segments.enumerated() {
            let durationMin = segment.duration / 60.0
            DBGLog("  Segment #\(index+1): \(segment.start) to \(segment.end) (\(String(format: "%.1f", durationMin)) min)")
        }
        
        return segments
    }
    
    //-----
     */
    
    // Helper method to count segments of a particular sleep stage
    private func countSleepSegments(
        samples: [HKCategorySample],
        targetValue: Int,
        allowedGapValues: [Int: TimeInterval],
        maxGapMinutes: Int,
        minDurationMinutes: Int = 0 // Default to 0 to maintain backward compatibility
    ) -> Int {
        // Now simply use identifySleepSegments and count the resulting segments
        let segments = identifySleepSegments(
            samples: samples,
            targetValue: targetValue,
            allowedGapValues: allowedGapValues,
            minDurationMinutes: minDurationMinutes
        )
        
        return segments.count
    }
    // Helper method to count transitions between sleep stages
    private func countSleepTransitions(samples: [HKCategorySample]) -> Int {
        guard samples.count > 1 else { return 0 }
        
        // Sort samples by start time
        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
        
        var transitions = 0
        var lastValue: Int?
        
        for sample in sortedSamples {
            if let lastVal = lastValue, lastVal != sample.value {
                transitions += 1
            }
            lastValue = sample.value
        }
        
        return transitions
    }
    
    private func handleQuantityTypeQuery(
        queryConfig: HealthDataQuery,
        startDate: Date,
        endDate: Date,
        specifiedUnit: HKUnit?,
        completion: @escaping ([HealthQueryResult]) -> Void
    ) {
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: queryConfig.identifier)) else {
            DBGLog("Unsupported sample type for identifier: \(queryConfig.identifier)")
            completion([])
            return
        }

        //DBGLog("name \(queryConfig.displayName) identifier \(queryConfig.identifier)")
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            guard error == nil else {
                DBGLog("Error querying HealthKit: \(error!.localizedDescription)")
                completion([])
                return
            }

            guard let quantitySamples = samples as? [HKQuantitySample] else {
                DBGLog("No quantity samples found.")
                completion([])
                return
            }

            let results: [HealthQueryResult] = {
                let unit = specifiedUnit ?? queryConfig.unit?.first ?? HKUnit.count()
                switch queryConfig.aggregationStyle {
                case .discreteArithmetic:
                    return quantitySamples.compactMap { sample in
                        let value = sample.quantity.doubleValue(for: unit)
                        let adjustedValue = queryConfig.unit?.first == HKUnit.percent() ? value * 100 : value
                        return HealthQueryResult(date: sample.startDate, value: adjustedValue, unit: unit)
                    }

                case .cumulative:
                    let cumulativeValue = quantitySamples.reduce(0.0) { total, sample in
                        let value = sample.quantity.doubleValue(for: unit)
                        return total + value
                    }

                    if !quantitySamples.isEmpty {
                        return [HealthQueryResult(
                            date: quantitySamples.last?.startDate ?? startDate,
                            value: cumulativeValue,
                            unit: unit
                        )]
                    } else {
                        return []
                    }
                default:
                    DBGLog("Unsupported aggregation style for \(queryConfig.displayName)")
                    return []
                }
            }()

            completion(results)
        }

        healthStore.execute(query)
    }

    func performHealthQuery(
        displayName: String,
        targetDate: Int,
        specifiedUnit: HKUnit?,
        completion: @escaping ([HealthQueryResult]) -> Void
    ) {
        guard let queryConfig = healthDataQueries.first(where: { $0.displayName == displayName }) else {
            DBGLog("No query configuration found for displayName: \(displayName)")
            completion([])
            return
        }

        DBGLog("query name \(displayName)")
        let calendar = Calendar.current

        let startDate: Date
        let endDate: Date
        
        if let aggregationTime = queryConfig.aggregationTime {
            // Define endDate as the targetDate's day at the aggregationTime

            endDate = calendar.date(bySettingHour: aggregationTime.hour ?? 0,
                                    minute: aggregationTime.minute ?? 0,
                                    second: aggregationTime.second ?? 0,
                                    of: Date(timeIntervalSince1970: TimeInterval(targetDate))) ??
                     Date(timeIntervalSince1970: TimeInterval(targetDate))

            // startDate is one day before endDate
            startDate = calendar.date(byAdding: .day, value: -1, to: endDate) ??
                        Date(timeIntervalSince1970: TimeInterval(targetDate) - 86400) // Default to one day earlier
            
            DBGLog("startDate \(startDate)  endDate  \(endDate)")
            DBGLog("hello")
        } else {
            // Default time range: ±10 hours around the targetDate
            startDate = Date(timeIntervalSince1970: TimeInterval(targetDate) - 10 * 3600)
            endDate = Date(timeIntervalSince1970: TimeInterval(targetDate) + 10 * 3600)
        }
        
        if queryConfig.identifier == "HKCategoryTypeIdentifierSleepAnalysis" {
            let unit = specifiedUnit ?? queryConfig.unit?.first ?? HKUnit.hour()
            handleSleepAnalysisQuery(startDate: startDate, endDate: endDate, specifiedUnit:unit, queryConfig: queryConfig, completion: completion)
        } else {
            handleQuantityTypeQuery(queryConfig: queryConfig, startDate: startDate, endDate: endDate, specifiedUnit: specifiedUnit, completion: completion)
        }
    }

    func dbgTimestamps(_ displayName: String, _ timestamps:[TimeInterval]) {
#if DEBUGLOG
        // Sort the timestamps
        let sortedTimestamps = timestamps.sorted()

        // Early exit if there are no elements
        guard !sortedTimestamps.isEmpty else {
            DBGLog("\(displayName): No timestamps to display.")
            return
        }

        if let firstTimestamp = sortedTimestamps.first,
           let lastTimestamp = sortedTimestamps.last {

            // Configure the formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium

            let firstDateString = dateFormatter.string(from: Date(timeIntervalSince1970: firstTimestamp))
            let lastDateString = dateFormatter.string(from: Date(timeIntervalSince1970: lastTimestamp))

            DBGLog("getHkDates() \(displayName) \(firstDateString) to \(lastDateString)")
            DBGLog("hello")
        }
#endif
    }

    func getHealthKitDates(
        for displayName: String,
        lastDate: Int?,
        completion: @escaping ([TimeInterval]) -> Void
    ) {
        // gets dates with HK data for displayName query over all time, or since lastDate if lastDate > 0
        
        // Find the query configuration for the given displayName
        guard let queryConfig = healthDataQueries.first(where: { $0.displayName == displayName }),
              let hkObjectType = queryConfig.identifier.hasPrefix("HKQuantityTypeIdentifier") ?
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: queryConfig.identifier)) :
                HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: queryConfig.identifier)) else {
            DBGLog("No HealthKit identifier found for display name: \(displayName)")
            completion([])
            return
        }

        // debug date
        //let calendar = Calendar.current
        //let specificDate = calendar.date(from: DateComponents(year: 2024, month: 9, day: 19, hour: 0, minute: 0, second: 0))
        //let startDate = (lastDate ?? 0 > 0 ? Date(timeIntervalSince1970: Double(lastDate!)) : specificDate)
        
        // Predicate for all time
        let startDate = (lastDate ?? 0 > 0 ? Date(timeIntervalSince1970: Double(lastDate!)) : Date.distantPast)
        
        // Time predicate remains the same
        let timePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        
        // Handle the predicate creation differently based on type
        var predicate: NSPredicate = timePredicate
        
        if let categories = queryConfig.categories, !categories.isEmpty {
            if hkObjectType is HKCategoryType {
                // For category types, create separate predicates for each category and combine with OR
                let categoryPredicates = categories.map { categoryValue in
                    return HKQuery.predicateForCategorySamples(with: .equalTo, value: categoryValue)
                }
                
                // Combine all category predicates with OR
                let categoriesCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: categoryPredicates)
                
                // Combine time predicate with categories predicate using AND
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, categoriesCompoundPredicate])
            } else {
                // For non-category types, continue with your original approach
                // This shouldn't happen based on your data structure, but keeping it for safety
                let categoryPredicate = NSPredicate(format: "value IN %@", categories)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, categoryPredicate])
            }
        }

        
        switch queryConfig.aggregationStyle {
        case .discreteArithmetic:
            // Fetch all individual timestamps
            let query = HKSampleQuery(sampleType: hkObjectType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard let samples = samples else {
                    DBGLog("Error fetching samples: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                let timestamps = samples.map { $0.startDate.timeIntervalSince1970 }
                //self.dbgTimestamps(displayName, timestamps)
                completion(timestamps)
            }
            healthStore.execute(query)
            
        case .cumulative:
            if queryConfig.aggregationType == nil {
                // Use HKStatisticsCollectionQuery for daily aggregation
                guard let quantityType = hkObjectType as? HKQuantityType else {
                    DBGLog("Invalid quantity type for cumulative daily aggregation.")
                    completion([])
                    return
                }
                
                let calendar = Calendar.current
                let anchorDate = calendar.startOfDay(for: Date())
                let interval = DateComponents(day: 1)
                
                let statsQuery = HKStatisticsCollectionQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum,
                    anchorDate: anchorDate,
                    intervalComponents: interval
                )
                
                statsQuery.initialResultsHandler = { _, statisticsCollection, error in
                    guard let statisticsCollection = statisticsCollection else {
                        DBGLog("Error fetching statistics: \(error?.localizedDescription ?? "Unknown error")")
                        completion([])
                        return
                    }
                    
                    let timestamps = statisticsCollection.statistics().map { $0.startDate.timeIntervalSince1970 }
                    //self.dbgTimestamps(displayName, timestamps)
                    completion(timestamps)
                }
                
                healthStore.execute(statsQuery)
            } else if queryConfig.aggregationType == .groupedByNight {
                // Group sleep data into nights
                guard let categoryType = hkObjectType as? HKCategoryType else {
                    DBGLog("Invalid category type for nightly grouping.")
                    completion([])
                    return
                }
                
                let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    guard let samples = samples as? [HKCategorySample], error == nil else {
                        DBGLog("Error fetching sleep samples: \(error?.localizedDescription ?? "Unknown error")")
                        completion([])
                        return
                    }
                    
                    let calendar = Calendar.current

                    // Aggregation time (e.g., 12:00 PM)
                    let aggregationTime = queryConfig.aggregationTime ?? DateComponents(hour: 12, minute: 0)

                    let groupedByAggregationTime = Dictionary(grouping: samples) { sample -> Date in
                        let startOfDay = calendar.startOfDay(for: sample.startDate)
                        let aggregationDate = calendar.date(bySettingHour: aggregationTime.hour ?? 0,
                                                            minute: aggregationTime.minute ?? 0,
                                                            second: aggregationTime.second ?? 0,
                                                            of: startOfDay)!

                        // Decide whether the sample belongs to the next day or the same day
                        if sample.startDate >= aggregationDate {
                            // After the aggregation time, assign to 12:00 PM on the next day
                            return calendar.date(byAdding: .day, value: 1, to: aggregationDate)!
                        } else {
                            // Before the aggregation time, assign to 12:00 PM on the same day
                            return aggregationDate
                        }
                    }

                    let timestamps = groupedByAggregationTime.keys.map { $0.timeIntervalSince1970 }
                    self.dbgTimestamps(displayName, timestamps)
                    completion(timestamps)
                }
                
                healthStore.execute(query)
                
            } else {
                DBGErr(".cumulative HealthDataQuery aggregationType \(queryConfig.aggregationType!) not handled")
            }
        case .discreteEquivalentContinuousLevel:
            fallthrough
        case .discreteTemporallyWeighted:
            fallthrough
        default:
            DBGErr("aggregation Style \(queryConfig.aggregationStyle) not handled")
        }
    }


/*
 
 private func simpleSleepQuery(
     startDate: Date,
     endDate: Date,
     completion: @escaping ([rtHealthKit.HealthQueryResult]) -> Void
 ) {
     guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
         DBGLog("Sleep Analysis type not available.")
         completion([])
         return
     }

     let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
     let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
         guard let samples = samples as? [HKCategorySample], error == nil else {
             DBGLog("Error fetching sleep samples: \(error?.localizedDescription ?? "Unknown error")")
             completion([])
             return
         }

         DBGLog("Retrieved \(samples.count) sleep samples.")
         var results: [rtHealthKit.HealthQueryResult] = []

         samples.forEach { sample in
             DBGLog("Sample Start: \(sample.startDate), End: \(sample.endDate), Value: \(sample.value)")
             // Add each sample as a result with duration as the value
             let durationMinutes = sample.endDate.timeIntervalSince(sample.startDate) / 60.0
             results.append(
                 rtHealthKit.HealthQueryResult(
                     date: sample.startDate,
                     value: durationMinutes,
                     unit: HKUnit.minute()
                 )
             )
         }

         completion(results)
     }

     HKHealthStore().execute(query)
 }
 */
    /*
    func readBodyWeight() {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            // The body mass type is not available
            return
        }
        
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let samples = results as? [HKQuantitySample] else {
                // Handle any errors or no results
                return
            }
            
            for sample in samples {
                let weight = sample.quantity.doubleValue(for: HKUnit.pound())
                // Do something with the weight value
                DBGLog("Body weight: \(weight) pounds")
            }
        }
        
        healthStore.execute(query)
    }

    
    func readBodyWeight(from startDate: Date, to endDate: Date) {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            DBGLog(".bodyMass not available")
            // The body mass type is not available
            return
        }
        DBGLog("Reading body weight from \(startDate) to \(endDate)")
        // Create a date range predicate
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Create a sort descriptor to sort the samples by date in descending order
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: datePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard let samples = results as? [HKQuantitySample] else {
                // Handle any errors or no results
                DBGLog("no samples returned")
                return
            }
            
            if samples.count == 0 {
                DBGLog("no results for \(startDate) to \(endDate)")
            }
            for sample in samples {
                let weight = sample.quantity.doubleValue(for: HKUnit.pound())
                let sampleDate = sample.startDate // The date when this sample was taken
                // Do something with the weight and date
                DBGLog("Body weight: \(weight) pounds, Date: \(sampleDate)")
            }
        }
        
        HKHealthStore().execute(query)
    }
    */
    
    /*
    //----  extract xml from zip file
    
    
    func processExportXML(from zipFileURL: URL) {
        do {
            // Use the throwing initializer for Archive
            let archive = try Archive(url: zipFileURL, accessMode: .read)

            /*
            DBGLog("Files in ZIP Archive:")
            for entry in archive {
                DBGLog(entry.path)
            }
             */
            // Locate and extract `export.xml`
            if let entry = archive["apple_health_export/export.xml"] {
                var data = Data()
                _ = try archive.extract(entry, consumer: { chunk in
                    data.append(chunk)
                })

                DBGLog("Successfully extracted export.xml")
                parseExportXML(data: data)
            } else {
                DBGLog("export.xml not found in ZIP archive")
            }
        } catch {
            DBGLog("Failed to open ZIP archive: \(error)")
        }
    }
    
    func parseExportXML(data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self // Set up your XML parsing delegate
        if parser.parse() {
            DBGLog("XML parsing completed")
        } else {
            DBGLog("XML parsing failed: \(parser.parserError?.localizedDescription ?? "Unknown error")")
        }
    }
    

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String : String] = [:]) {
        DBGLog("Start element: \(elementName), attributes: \(attributes)")
        // Handle specific elements, such as "Record"
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        DBGLog("Found characters: \(string)")
        // Process text data within an element
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        DBGLog("End element: \(elementName)")
    }

     */
    
    /*
     
     let calendar = Calendar.current
     let endDate = Date() // today
     let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) // one year ago
     
     readBodyWeight(from: startDate!, to: endDate)
     
     let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
     let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, results, error) in
     guard let samples = results as? [HKQuantitySample] else { return }
     
     for sample in samples {
     // Example of converting the same sample into different units
     let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
     let weightInPounds = sample.quantity.doubleValue(for: HKUnit.pound())
     let weightInStones = sample.quantity.doubleValue(for: HKUnit.stone())
     
     // Use the weight in your app
     DBGLog("Weight: \(weightInKilograms) kg, \(weightInPounds) lbs, \(weightInStones) st")
     }
     }
     
     HKHealthStore().execute(query)
     
     import HealthKit
     
     let healthStore = HKHealthStore()
     let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
     
     let startDate = ... // Your start date
     let endDate = ... // Your end date
     let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
     
     let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, statistics, error in
     guard error == nil, let statistics = statistics else {
     DBGLog("An error occurred: \(error!.localizedDescription)")
     return
     }
     
     let count = statistics.sumQuantity()?.doubleValue(for: HKUnit.count())
     DBGLog("Total steps count in the given period: \(count ?? 0)")
     }
     
     healthStore.execute(query)
     
     
     
     let interval = DateComponents(day: 1) // Daily intervals
     
     let anchorDate = ... // Typically the start of the day for the start date
     let query = HKStatisticsCollectionQuery(quantityType: stepsType,
     quantitySamplePredicate: predicate,
     options: .cumulativeSum,
     anchorDate: anchorDate,
     intervalComponents: interval)
     
     query.initialResultsHandler = { query, results, error in
     guard let statsCollection = results else {
     DBGLog("An error occurred: \(error!.localizedDescription)")
     return
     }
     
     statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
     let count = statistics.sumQuantity()?.doubleValue(for: HKUnit.count())
     DBGLog("Steps count for \(statistics.startDate): \(count ?? 0)")
     }
     }
     
     healthStore.execute(query)
     
     
     
     */
}
