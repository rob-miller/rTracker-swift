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
    let unit: [HKUnit]?                          // unit choice (optional)
    let needUnit: Bool                          // must specify unit or default to last saved
    let aggregationStyle: HKQuantityAggregationStyle // cumulative, discrete_options
    let customProcessor: ((HKSample) -> Double)? // custom processing logic (sleep aggregation)
    let aggregationType: AggregationType?       // custom grouping logic (night sleep)
    let aggregationTime: DateComponents?       // Optional time for aggregation (e.g., start/end of day)

    enum AggregationType {
        //case discreteArithmetic     // Independent values
        //case cumulativeDaily        // Daily aggregation (e.g., calories)
        case groupedByNight         // Nightly grouping (e.g., sleep analysis)
    }
}

let healthDataQueries: [HealthDataQuery] = [
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyFatPercentage",
        displayName: "Body Fat %",
        unit: nil, // still a fractional value so special case handling
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeight",
        displayName: "Body Height",
        unit: [HKUnit.meter(), HKUnit(from: "cm"), HKUnit.foot(), HKUnit.inch()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyMass",
        displayName: "Body Weight",
        unit: [HKUnit.gramUnit(with: .kilo), HKUnit.pound(), HKUnit.stone()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyMassIndex",
        displayName: "Body Mass Index",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierLeanBodyMass",
        displayName: "Body Lean Mass",
        unit: [HKUnit.gramUnit(with: .kilo), HKUnit.pound(), HKUnit.stone()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil

    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWaistCircumference",
        displayName: "Body Waist Circumference",
        unit: [HKUnit.meter(), HKUnit(from: "cm"), HKUnit.foot(), HKUnit.inch()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil

    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Awake",
        unit: [HKUnit.hour(), HKUnit.minute()],
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
        aggregationTime: DateComponents(hour: 12, minute: 0) // 12:00 PM
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Core",
        unit: [HKUnit.hour(), HKUnit.minute()],
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
        aggregationTime: DateComponents(hour: 12, minute: 0) // 12:00 PM
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Deep",
        unit: [HKUnit.hour(), HKUnit.minute()],
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
        aggregationTime: DateComponents(hour: 12, minute: 0) // 12:00 PM
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - Total",
        unit: [HKUnit.hour(), HKUnit.minute()],
        needUnit: true,
        aggregationStyle: .cumulative, // Aggregates sleep data across intervals
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample else {
                return 0
            }
            // Include all sleep-related categories
            if categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
            }
            return 0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0) // 12:00 PM
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep - In Bed",
        unit: [HKUnit.hour(), HKUnit.minute()],
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
        aggregationTime: DateComponents(hour: 12, minute: 0) // 12:00 PM
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRate",
        displayName: "Heart Rate",
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
        displayName: "Heart Rate Variability SDNN",
        unit: [HKUnit.secondUnit(with: .milli)],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierRestingHeartRate",
        displayName: "Resting Heart Rate",
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRateRecoveryOneMinute",
        displayName: "Heart Rate Recovery - One Minute",
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodGlucose",
        displayName: "Blood Glucose",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierOxygenSaturation",
        displayName: "Oxygen Saturation",
        unit: [HKUnit.percent()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodGlucose",
        displayName: "Resting Heart Rate",
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyTemperature",
        displayName: "Basal Body Temperature",
        unit: [HKUnit.degreeCelsius(), HKUnit.degreeFahrenheit()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBasalBodyTemperature",
        displayName: "Body Temperature",
        unit: [HKUnit.degreeCelsius(), HKUnit.degreeFahrenheit()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodPressureSystolic",
        displayName: "Blood Pressure Systolic",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBloodPressureDiastolic",
        displayName: "Blood Pressure Diastolic",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierActiveEnergyBurned",
        displayName: "Active Energy Burned",
        unit: [HKUnit.largeCalorie()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0) // midnight
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBasalEnergyBurned",
        displayName: "Basal Energy Burned",
        unit: [HKUnit.largeCalorie()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0) // midnight
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStepCount",
        displayName: "Step Count",
        unit: nil,
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0) // midnight
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierFlightsClimbed",
        displayName: "Flights Climbed",
        unit: nil,
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0) // midnight
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierDistanceWalkingRunning",
        displayName: "Distance Walking/Running",
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0) // midnight
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierDistanceCycling",
        displayName: "Distance Cycling",
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .cumulative,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 00, minute: 0) // midnight
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierPhysicalEffort",
        displayName: "Stair Ascent Speed",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWorkoutEffortScore",
        displayName: "Workout Effort Score",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStairAscentSpeed",
        displayName: "Stair Ascent Speed",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierSixMinuteWalkTestDistance",
        displayName: "Walk Test Distance - 6 minute",
        unit: [HKUnit.meter(), HKUnit.foot(), HKUnit.yard()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWalkingSpeed",
        displayName: "Walking Speed",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWalkingStepLength",
        displayName: "Walking Step Length",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierWalkingAsymmetryPercentage",
        displayName: "Walking Asymmetry %",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStairAscentSpeed",
        displayName: "Stair Ascent Speed",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierStairDescentSpeed",
        displayName: "Stair Descent Speed",
        unit: nil,
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil
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
                            processQueryResult()
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
                        unit: unit,
                        needUnit: query.needUnit,
                        aggregationStyle: query.aggregationStyle,
                        customProcessor: query.customProcessor,
                        aggregationType: query.aggregationType,
                        aggregationTime: query.aggregationTime
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

    // Updated performHealthQuery function with modular structure

    private func handleSleepAnalysisQuery(
        startDate: Date,
        endDate: Date,
        specifiedUnit: HKUnit,
        queryConfig: HealthDataQuery,
        completion: @escaping ([HealthQueryResult]) -> Void
    ) {
        DBGLog("sleepAnalysisQuery startDate \(startDate)  endDate \(endDate) name \(queryConfig.displayName)")
        guard let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            DBGLog("Unsupported sample type for sleep analysis.")
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            guard error == nil else {
                DBGLog("Error querying HealthKit: \(error!.localizedDescription)")
                completion([])
                return
            }

            guard let categorySamples = samples else {
                DBGLog("No category samples found.")
                completion([])
                return
            }

            var results: [HealthQueryResult] = []

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

            completion(results)
        }

        healthStore.execute(query)
    }
    
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

            // Define startDate as 1 day before the targetDate at the aggregationTime
            startDate = calendar.date(byAdding: .day, value: -1, to: endDate) ??
                        Date(timeIntervalSince1970: TimeInterval(targetDate) - 86400) // Default to one day earlier
        } else {
            // Default time range: ±4 hours around the targetDate
            startDate = Date(timeIntervalSince1970: TimeInterval(targetDate) - 4 * 3600)
            endDate = Date(timeIntervalSince1970: TimeInterval(targetDate) + 4 * 3600)
        }
        
        if queryConfig.identifier == "HKCategoryTypeIdentifierSleepAnalysis" {
            let unit = specifiedUnit ?? queryConfig.unit?.first ?? HKUnit.hour()
            handleSleepAnalysisQuery(startDate: startDate, endDate: endDate, specifiedUnit:unit, queryConfig: queryConfig, completion: completion)
            //simpleSleepQuery(startDate: startDate, endDate: endDate, completion: completion)
        } else {
            handleQuantityTypeQuery(queryConfig: queryConfig, startDate: startDate, endDate: endDate, specifiedUnit: specifiedUnit, completion: completion)
        }
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

        // Debug

        
        let calendar = Calendar.current
        // Predicate for all time
        //let startDate = (lastDate ?? 0 > 0 ? Date(timeIntervalSince1970: Double(lastDate!)) : Date.distantPast)
        let specificDate = calendar.date(from: DateComponents(year: 2024, month: 9, day: 19, hour: 0, minute: 0, second: 0))
        let startDate = (lastDate ?? 0 > 0 ? Date(timeIntervalSince1970: Double(lastDate!)) : specificDate)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])

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
                    
                    /*
                    let groupedByNight = Dictionary(grouping: samples) { sample -> Date in
                        calendar.startOfDay(for: sample.startDate)
                    }
                    let timestamps = groupedByNight.keys.map { $0.timeIntervalSince1970 }
                     */

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
