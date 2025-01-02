//
//  healthkitSupport.swift
//  rTracker
//
//  Created by Robert Miller on 02/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import Foundation
import HealthKit

let healthStore = HKHealthStore()

func isHealthKitAvailable() -> Bool {
    return HKHealthStore.isHealthDataAvailable()
}

func requestHealthKitPermission() {
    guard isHealthKitAvailable() else {
        // HealthKit is not available on this device
        return
    }

    let readTypes = Set([HKObjectType.quantityType(forIdentifier: .bodyMass)!])
    
    healthStore.requestAuthorization(toShare: nil, read: readTypes) { (success, error) in
        if !success {
            // Handle the error - authorization was not granted
        }
    }
}

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
            print("Body weight: \(weight) pounds")
        }
    }

    healthStore.execute(query)
}

import HealthKit

func readBodyWeight(from startDate: Date, to endDate: Date) {
    guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
        // The body mass type is not available
        return
    }

    // Create a date range predicate
    let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    
    // Create a sort descriptor to sort the samples by date in descending order
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    let query = HKSampleQuery(sampleType: bodyMassType, predicate: datePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, results, error) in
        guard let samples = results as? [HKQuantitySample] else {
            // Handle any errors or no results
            return
        }

        for sample in samples {
            let weight = sample.quantity.doubleValue(for: HKUnit.pound())
            let sampleDate = sample.startDate // The date when this sample was taken
            // Do something with the weight and date
            print("Body weight: \(weight) pounds, Date: \(sampleDate)")
        }
    }

    HKHealthStore().execute(query)
}


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
         print("Weight: \(weightInKilograms) kg, \(weightInPounds) lbs, \(weightInStones) st")
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
         print("An error occurred: \(error!.localizedDescription)")
         return
     }

     let count = statistics.sumQuantity()?.doubleValue(for: HKUnit.count())
     print("Total steps count in the given period: \(count ?? 0)")
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
         print("An error occurred: \(error!.localizedDescription)")
         return
     }
     
     statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
         let count = statistics.sumQuantity()?.doubleValue(for: HKUnit.count())
         print("Steps count for \(statistics.startDate): \(count ?? 0)")
     }
 }

 healthStore.execute(query)

 

 */
