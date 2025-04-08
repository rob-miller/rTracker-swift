//
//  healthKitData.swift
//  rTracker
//
//  Created by Robert Miller on 08/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

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
        aggregationTime: DateComponents(hour: 23, minute: 59), // midnight end of day
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
        aggregationTime: DateComponents(hour: 23, minute: 59), // midnight end of day
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
        aggregationTime: DateComponents(hour: 23, minute: 59), // midnight end of day
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
        aggregationTime: DateComponents(hour: 23, minute: 59), // midnight end of day
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
        aggregationTime: DateComponents(hour: 23, minute: 59), // midnight end of day
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
        aggregationTime: DateComponents(hour: 23, minute: 59), // midnight end of day
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
