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

let MINSLEEPSEGMENTDURATION = 3
let MAXSLEEPSEGMENTGAP = 12

class rtHealthKit: ObservableObject {   // }, XMLParserDelegate {
    static let shared = rtHealthKit()  // singleton class
    //--- Healthkit specific
    
    let healthStore = HKHealthStore()
    var tl : trackerList? = nil
    var dbInitialised = false;

    @Published var configurations: [HealthDataQuery] = []
    
    // Define a struct to hold the healthQuery results
    struct HealthQueryResult {
        let date: Date
        let value: Double
        let unit: HKUnit
    }
    
    init() {
        //super.init()
        DBGLog("rtHealthKit init called")
        tl = RootViewController.shared.tlist
        let sql = "select count(*) from rthealthkit"
        dbInitialised = (tl?.toQry2Int(sql:sql) ?? 0) != 0
        loadHealthKitConfigurations()
    }

    func earliestSampleDate(
        for sampleType: HKSampleType,
        useDate: Date?,
        completion: @escaping (Date) -> Void
    ) {
        // Return immediately with useDate if provided
        if let useDate = useDate {
            completion(useDate)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            if let error = error {
                DBGErr("Error querying earliest sample date: \(error.localizedDescription)")
                // Fall back to HealthKit introduction date (iOS 8, September 2014)
                let fallbackDate = Calendar.current.date(from: DateComponents(year: 2014, month: 9, day: 1)) ?? Date(timeIntervalSince1970: 1409529600)
                completion(fallbackDate)
                return
            }
            
            if let earliestDate = results?.first?.startDate {
                completion(earliestDate)
            } else {
                // No samples found, return current date
                completion(Date())
            }
        }
        healthStore.execute(query)
    }
    
    /// Determines the date range for HealthKit sample queries by using provided dates or querying HealthKit for the earliest/latest samples.
    /// This function provides flexible date range resolution - if both start and end dates are provided, it returns them immediately.
    /// If either date is missing, it queries HealthKit to find the actual earliest/latest sample dates for the specified sample type.
    /// The earliest date is adjusted by subtracting 1 second, and the latest date by adding 1 second to ensure complete data coverage.
    ///
    /// - Parameters:
    ///   - sampleType: The HealthKit sample type to query for date range determination
    ///   - useStartDate: Optional start date - if nil, queries for earliest sample date
    ///   - useEndDate: Optional end date - if nil, queries for latest sample date
    ///   - completion: Completion handler that receives the resolved start and end dates (both may be nil if no samples exist)
    func sampleDateRange(
        for sampleType: HKSampleType,
        useStartDate: Date?,
        useEndDate: Date?,
        completion: @escaping (Date?, Date?) -> Void
    ) {
        // Return immediately with provided dates if both are given
        if let useStartDate = useStartDate, let useEndDate = useEndDate {
            completion(useStartDate, useEndDate)
            return
        }
        
        let group = DispatchGroup()
        var earliestDate: Date?
        var latestDate: Date?
        
        // Use provided start date or query for earliest sample
        if let useStartDate = useStartDate {
            earliestDate = useStartDate
        } else {
            group.enter()
            let earliestSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let earliestQuery = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [earliestSortDescriptor]
            ) { _, results, error in
                if let error = error {
                    DBGErr("Error querying earliest sample date: \(error.localizedDescription)")
                } else if let sample = results?.first {
                    earliestDate = sample.startDate.addingTimeInterval(-1)
                }
                group.leave()
            }
            healthStore.execute(earliestQuery)
        }
        
        // Use provided end date or query for latest sample
        if let useEndDate = useEndDate {
            latestDate = useEndDate
        } else {
            group.enter()
            let latestSortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let latestQuery = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [latestSortDescriptor]
            ) { _, results, error in
                if let error = error {
                    DBGErr("Error querying latest sample date: \(error.localizedDescription)")
                } else if let sample = results?.first {
                    latestDate = sample.startDate.addingTimeInterval(1)
                }
                group.leave()
            }
            healthStore.execute(latestQuery)
        }
        
        group.notify(queue: .main) {
            completion(earliestDate, latestDate)  // returns nil if no data
        }
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
                                    case "Other":
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
                                                ])
                                    case "All":  // assume core will always be present at some point for all sleep
                                        fallthrough
                                    case "Total":  // previous name for core + deep + rem
                                        fallthrough
                                    case "Specified":
                                        fallthrough
                                    case "Core + Deep + REM":  // assume core will always be present at some point for total sleep
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
                                    if displayName == "Sleep" {
                                        predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                                    HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: []),
                                                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
                                                ])
                                    } else {
                                        DBGErr("No suffix found in displayName: \(displayName)")
                                        // Handle cases where there is no '-'
                                    }
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

    private func handleSleepAnalysisQuery(
        startDate: Date,
        endDate: Date,
        specifiedUnit: HKUnit,
        queryConfig: HealthDataQuery,
        completion: @escaping ([HealthQueryResult]) -> Void
    ) {
        //DBGLog("sleepAnalysisQuery startDate \(startDate) endDate \(endDate) name \(queryConfig.displayName)")
        guard let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            DBGLog("Unsupported sample type for sleep analysis.")
            completion([])
            return
        }

        // Start with base time predicate
        var predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        // Add category-specific filtering based on display name
        let displayName = queryConfig.displayName
        let components = displayName.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        
        if components.count > 1 {
            let suffix = components[1].trimmingCharacters(in: .whitespaces)
            switch suffix {
            case "In Bed":
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.inBed.rawValue)
                ])
            case "Deep":
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
                ])
            case "Core":
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepCore.rawValue)
                ])
            case "REM":
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue)
                ])
            case "Other":
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
                ])
            case "Awake":
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    predicate,
                    NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.awake.rawValue)
                ])
            // Special cases handling
            case "Specified", "All", "Total", "Core + Deep + REM":
                // Create a compound OR predicate for the multiple categories
                var categoryPredicates: [NSPredicate] = []
                
                // Add predicates for Core, REM, and Deep
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepCore.rawValue))
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue))
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue))
                
                // Combine these with OR and then AND with time predicate
                let categoriesOrPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: categoryPredicates)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoriesOrPredicate])
            
            case "Cycles", "Transitions":
                // Create a compound OR predicate for all sleep stage categories
                var categoryPredicates: [NSPredicate] = []
                
                // Add predicates for all relevant sleep stages
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepCore.rawValue))
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue))
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue))
                categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.awake.rawValue))
                
                // Combine these with OR and then AND with time predicate
                let categoriesOrPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: categoryPredicates)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoriesOrPredicate])
                
            // Handle other specialized cases
            case "Deep Segments", "REM Segments":
                // For segments, we need all related categories for proper segment detection
                var categoryPredicates: [NSPredicate] = []
                
                if suffix == "Deep Segments" {
                    // For Deep segments, include Deep and Core (can have Core gaps)
                    categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepDeep.rawValue))
                    categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepCore.rawValue))
                } else { // REM Segments
                    // For REM segments, include REM, Core, and possibly Awake (can have gaps)
                    categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepREM.rawValue))
                    categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepCore.rawValue))
                    categoryPredicates.append(NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.awake.rawValue))
                }
                
                // Combine with OR and then AND with time predicate
                let categoriesOrPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: categoryPredicates)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoriesOrPredicate])
                
            default:
                DBGLog("Unhandled sleep category suffix: \(suffix)")
            }
        } else if displayName == "Sleep" {
            // If it's just "Sleep" with no suffix
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                predicate,
                NSPredicate(format: "value == %d", HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
            ])
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
            guard error == nil else {
                DBGLog("Error querying HealthKit: \(error!.localizedDescription)")
                completion([])
                return
            }
            
            guard let categorySamples = samples as? [HKCategorySample] else {
                // No data was found - this could be because there's no data or because there's 0 time in this state
                // For sleep categories, we need to determine if there was any sleep data at all for this time period
                self.checkForAnySleepData(startDate: startDate, endDate: endDate) { hasSleepData in
                    if hasSleepData && self.isSleepCategoryQuery(queryConfig) {
                        // Sleep data exists, but no data for this specific category - this means 0 minutes
                        let result = HealthQueryResult(date: startDate, value: 0.0, unit: specifiedUnit)
                        DBGLog("No samples found for the \(queryConfig.displayName), but sleep data exists. Setting value to 0.")
                        completion([result])
                    } else {
                        // No sleep data at all exists for this period
                        DBGLog("No sleep data found for the specified time period.")
                        completion([])
                    }
                }
                return
            }
            
            var results: [HealthQueryResult] = []
            
            // Handle specialized sleep metrics
            switch queryConfig.displayName {
            case "Sleep - Deep Segments":
                let segmentCount = self.countSleepSegments(
                    samples: categorySamples,
                    targetValue: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    allowedGapValues: [ HKCategoryValueSleepAnalysis.asleepCore.rawValue: TimeInterval(MAXSLEEPSEGMENTGAP * 60)],
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
                        HKCategoryValueSleepAnalysis.asleepCore.rawValue: TimeInterval(MAXSLEEPSEGMENTGAP * 60),
                        HKCategoryValueSleepAnalysis.awake.rawValue: TimeInterval(2 * 60)
                    ],
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
                // Handle regular sleep analysis metrics
                switch queryConfig.aggregationStyle {
                case .cumulative:
                    var totalValue = categorySamples.reduce(0.0) { total, sample in
                        total + (queryConfig.customProcessor?(sample) ?? 0)
                    }
                    
                    //if totalValue != 0.0 {  // don't add 0 value records, e.g. from no deep sleep data when have in bed data
                    // actually this is correct - need to handle 0.0 time awake
                    // this allows HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue (sleep other) to insert spurious 0 values
                        if specifiedUnit == HKUnit.hour() {
                            totalValue /= 60.0
                        }
                        results.append(HealthQueryResult(date: startDate, value: totalValue, unit: specifiedUnit))
                    //}
                    
                case .discreteArithmetic:
                    if !categorySamples.isEmpty {
                        results = categorySamples.compactMap { sample in
                            var processedValue = queryConfig.customProcessor?(sample) ?? 0
                            if specifiedUnit == HKUnit.hour() {
                                processedValue /= 60.0
                            }
                            return HealthQueryResult(date: sample.startDate, value: processedValue, unit: specifiedUnit)
                        }
                    } else if self.isSleepCategoryQuery(queryConfig) {
                        // For sleep data with discrete arithmetic but no samples, still add a 0 result
                        // if we know there's sleep data in general
                        self.checkForAnySleepData(startDate: startDate, endDate: endDate) { hasSleepData in
                            if hasSleepData {
                                results.append(HealthQueryResult(date: startDate, value: 0.0, unit: specifiedUnit))
                            }
                        }
                    }
                    
                case .discreteEquivalentContinuousLevel:
                    fallthrough
                case .discreteTemporallyWeighted:
                    fallthrough
                default:
                    DBGErr("aggregation Style \(queryConfig.aggregationStyle) not handled")
                }
            }
            // DBGLog("have Sleep Analysis Query Results for \(queryConfig.displayName) : \(results)")
            

            completion(results)
            
        }
        
        healthStore.execute(query)
    }

    // Helper function to check if any sleep data exists for the time period
    private func checkForAnySleepData(startDate: Date, endDate: Date, completion: @escaping (Bool) -> Void) {
        guard let categoryType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: 1, sortDescriptors: nil) { (_, samples, _) in
            DispatchQueue.main.async {
                completion(samples?.count ?? 0 > 0)
            }
        }
        
        healthStore.execute(query)
    }

    // Helper function to check if a query is for a sleep category
    private func isSleepCategoryQuery(_ queryConfig: HealthDataQuery) -> Bool {
        return queryConfig.identifier == "HKCategoryTypeIdentifierSleepAnalysis"
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
        startDate: Date,
        endDate: Date? = nil,  // nil = single point query, Date = range query
        specifiedUnit: HKUnit?,
        completion: @escaping ([HealthQueryResult]) -> Void
    ) {
        guard let queryConfig = healthDataQueries.first(where: { $0.displayName == displayName }) else {
            DBGLog("No query configuration found for displayName: \(displayName)")
            completion([])
            return
        }

        let calendar = Calendar.current
        let finalStartDate: Date
        let finalEndDate: Date
        
        if let providedEndDate = endDate {
            // Range query - use provided dates
            finalStartDate = startDate
            finalEndDate = providedEndDate
        } else {
            // Single point query - calculate appropriate range
            if let aggregationTime = queryConfig.aggregationTime {
                // Define endDate as the startDate's day at the aggregationTime
                finalEndDate = calendar.date(bySettingHour: aggregationTime.hour ?? 0,
                                        minute: aggregationTime.minute ?? 0,
                                        second: aggregationTime.second ?? 0,
                                        of: startDate) ?? startDate

                // startDate is one day before endDate
                finalStartDate = calendar.date(byAdding: .day, value: -1, to: finalEndDate) ??
                            Date(timeIntervalSince1970: startDate.timeIntervalSince1970 - 86400)
            } else {
                // Default time range: ±12 hours around the startDate
                finalStartDate = Date(timeIntervalSince1970: startDate.timeIntervalSince1970 - 12 * 3600)
                finalEndDate = Date(timeIntervalSince1970: startDate.timeIntervalSince1970 + 12 * 3600)
            }
        }
        
        if queryConfig.identifier == "HKCategoryTypeIdentifierSleepAnalysis" {
            let unit = specifiedUnit ?? queryConfig.unit?.first ?? HKUnit.hour()
            handleSleepAnalysisQuery(startDate: finalStartDate, endDate: finalEndDate, specifiedUnit:unit, queryConfig: queryConfig, completion: completion)
        } else {
            handleQuantityTypeQuery(queryConfig: queryConfig, startDate: finalStartDate, endDate: finalEndDate, specifiedUnit: specifiedUnit, completion: completion)
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
            //DBGLog("hello")
        }
#endif
    }
    

    func getHealthKitDates(
        queryConfig: HealthDataQuery,
        hkObjectType: HKSampleType,
        startDate: Date,
        endDate: Date,
        completion: @escaping ([TimeInterval]) -> Void
    ) {
        // gets dates with HK data for specified query configuration within date range
        
        // Time predicate using provided date range
        let timePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
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
                //self.dbgTimestamps(queryConfig.displayName, timestamps)
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
                    //self.dbgTimestamps(queryConfig.displayName, timestamps)
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

                    // Aggregation time (e.g., 12:00 PM) noon is default for groupedByNight sleep
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
                    //self.dbgTimestamps(queryConfig.displayName, timestamps)
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
    
    func getHealthKitDataCount(
        for displayName: String,
        fromDate: Int?,
        completion: @escaping (Int) -> Void
    ) {
        // Fast count method - gets count of HK data points without fetching all samples
        
        // Find the query configuration for the given displayName
        guard let queryConfig = healthDataQueries.first(where: { $0.displayName == displayName }),
              let hkObjectType = queryConfig.identifier.hasPrefix("HKQuantityTypeIdentifier") ?
                HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: queryConfig.identifier)) :
                HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: queryConfig.identifier)) else {
            DBGLog("No HealthKit identifier found for display name: \(displayName)")
            completion(0)
            return
        }

        // Use same predicate logic as getHealthKitDates
        let startDate = (fromDate ?? 0 > 0 ? Date(timeIntervalSince1970: Double(fromDate!)) : Date.distantPast)
        let timePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        
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
                let categoryPredicate = NSPredicate(format: "value IN %@", categories)
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, categoryPredicate])
            }
        }
        
        switch queryConfig.aggregationStyle {
        case .discreteArithmetic:
            // For discrete data, use statistics query to get count efficiently
            if let quantityType = hkObjectType as? HKQuantityType {
                let statisticsQuery = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: []
                ) { _, statistics, error in
                    guard error == nil else {
                        DBGErr("Error counting HealthKit data: \(error!.localizedDescription)")
                        completion(0)
                        return
                    }
                    
                    // For discrete data, we need to count individual samples
                    // Statistics query doesn't give us sample count directly, so fall back to sample query
                    let sampleQuery = HKSampleQuery(sampleType: hkObjectType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                        guard error == nil else {
                            DBGErr("Error counting HealthKit samples: \(error!.localizedDescription)")
                            completion(0)
                            return
                        }
                        completion(samples?.count ?? 0)
                    }
                    self.healthStore.execute(sampleQuery)
                }
                healthStore.execute(statisticsQuery)
            } else {
                // For category types, count samples directly
                let sampleQuery = HKSampleQuery(sampleType: hkObjectType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    guard error == nil else {
                        DBGErr("Error counting HealthKit samples: \(error!.localizedDescription)")
                        completion(0)
                        return
                    }
                    completion(samples?.count ?? 0)
                }
                healthStore.execute(sampleQuery)
            }
            
        case .cumulative:
            if queryConfig.aggregationType == nil {
                // Use HKStatisticsCollectionQuery for daily aggregation - count the days
                guard let quantityType = hkObjectType as? HKQuantityType else {
                    DBGLog("Invalid quantity type for cumulative daily aggregation.")
                    completion(0)
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
                        DBGErr("Error fetching statistics: \(error?.localizedDescription ?? "Unknown error")")
                        completion(0)
                        return
                    }
                    
                    completion(statisticsCollection.statistics().count)
                }
                
                healthStore.execute(statsQuery)
            } else if queryConfig.aggregationType == .groupedByNight {
                // Group sleep data into nights - estimate based on date range
                guard let categoryType = hkObjectType as? HKCategoryType else {
                    DBGLog("Invalid category type for nightly grouping.")
                    completion(0)
                    return
                }
                
                // For sleep data, count samples and estimate nights
                let query = HKSampleQuery(sampleType: categoryType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    guard let samples = samples as? [HKCategorySample], error == nil else {
                        DBGErr("Error fetching sleep samples: \(error?.localizedDescription ?? "Unknown error")")
                        completion(0)
                        return
                    }
                    
                    if samples.isEmpty {
                        completion(0)
                        return
                    }
                    
                    // Estimate nights by grouping samples by date
                    let calendar = Calendar.current
                    let aggregationTime = queryConfig.aggregationTime ?? DateComponents(hour: 12, minute: 0)
                    
                    let groupedByAggregationTime = Dictionary(grouping: samples) { sample -> Date in
                        let startOfDay = calendar.startOfDay(for: sample.startDate)
                        let aggregationDate = calendar.date(bySettingHour: aggregationTime.hour ?? 0,
                                                            minute: aggregationTime.minute ?? 0,
                                                            second: aggregationTime.second ?? 0,
                                                            of: startOfDay)!
                        
                        if sample.startDate >= aggregationDate {
                            return calendar.date(byAdding: .day, value: 1, to: aggregationDate)!
                        } else {
                            return aggregationDate
                        }
                    }
                    
                    completion(groupedByAggregationTime.keys.count)
                }
                
                healthStore.execute(query)
                
            } else {
                DBGErr(".cumulative HealthDataQuery aggregationType \(queryConfig.aggregationType!) not handled")
                completion(0)
            }
        case .discreteEquivalentContinuousLevel:
            fallthrough
        case .discreteTemporallyWeighted:
            fallthrough
        default:
            DBGErr("aggregation Style \(queryConfig.aggregationStyle) not handled")
            completion(0)
        }
    }

}
