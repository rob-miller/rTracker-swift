//
//  healthKitData.swift
//  rTracker
//
//  Created by Robert Miller on 08/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import HealthKit

// Default HealthKit date window size for chunked loading to avoid memory issues
// High-frequency data (HRV, Heart Rate) should use smaller windows (1 day)
// Low-frequency data can use larger windows (32 days) for efficiency
let hkDateWindow = 32

enum MenuTab: String, CaseIterable {
    case metrics = "Metrics"
    case sleep = "Sleep"
    case workouts = "Workouts"

    var title: String { self.rawValue }

    var icon: String {
        switch self {
        case .metrics:
            return "ruler"
        case .sleep:
            return "powersleep"
        case .workouts:
            return "figure.run"
        }
    }
}

struct HealthDataQuery {
    enum SampleType {
        case quantity
        case category
        case workout
    }

    enum WorkoutMetric {
        case duration
        case totalEnergy
        case totalDistance
    }

    enum WorkoutCategory: String, CaseIterable {
        case cardio = "Cardio"
        case training = "Training"
        case sports = "Sports"
        case mindAndBody = "Mind & Body"
        case outdoor = "Outdoor"
        case wheelchair = "Wheel"
        case other = "Other"
    }

    let identifier: String                     // Unique HK identifier
    let displayName: String                    // User-friendly name for UI
    let categories: [Int]?                     // subcategories to filter sleep data
    let unit: [HKUnit]?                        // unit choice (optional)
    let needUnit: Bool                         // must specify unit or default to last saved
    let aggregationStyle: HKQuantityAggregationStyle // cumulative, discrete_options
    let customProcessor: ((HKSample) -> Double)? // custom processing logic (sleep aggregation)
    let aggregationType: AggregationType?      // custom grouping logic (night sleep)
    let aggregationTime: DateComponents?       // Optional time for aggregation (e.g., start/end of day). if specified, aggregate over supplied targDate +/- 10 hours
    let useEndDate: Bool                       // Use sample.endDate instead of startDate for interval-based measurements (e.g., overnight sleep data)
    let info: String?
    let sampleType: SampleType
    let workoutActivities: [HKWorkoutActivityType]?
    let workoutMetric: WorkoutMetric?
    let workoutLocation: HKWorkoutSessionLocationType?
    let workoutCategory: WorkoutCategory?
    let menuTab: MenuTab?                          // Optional override for menu placement

    enum AggregationType {
        case groupedByNight         // Sleep data - no averaging controls (single value per night)
        case highFrequency          // HRV, Heart Rate - many readings per day, need full controls
    }
    init(
        identifier: String,
        displayName: String,
        categories: [Int]? = nil,
        unit: [HKUnit]? = nil,
        needUnit: Bool,
        aggregationStyle: HKQuantityAggregationStyle,
        customProcessor: ((HKSample) -> Double)? = nil,
        aggregationType: AggregationType? = nil,
        aggregationTime: DateComponents? = nil,
        useEndDate: Bool = false,
        info: String? = nil,
        sampleType: SampleType = .quantity,
        workoutActivities: [HKWorkoutActivityType]? = nil,
        workoutMetric: WorkoutMetric? = nil,
        workoutLocation: HKWorkoutSessionLocationType? = nil,
        workoutCategory: WorkoutCategory? = nil,
        menuTab: MenuTab? = nil
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.categories = categories
        self.unit = unit
        self.needUnit = needUnit
        self.aggregationStyle = aggregationStyle
        self.customProcessor = customProcessor
        self.aggregationType = aggregationType
        self.aggregationTime = aggregationTime
        self.useEndDate = useEndDate
        self.info = info
        self.sampleType = sampleType
        self.workoutActivities = workoutActivities
        self.workoutMetric = workoutMetric
        self.workoutLocation = workoutLocation
        self.workoutCategory = workoutCategory
        self.menuTab = menuTab
    }
}

extension HealthDataQuery {
    func makeSampleType() -> HKSampleType? {
        switch sampleType {
        case .quantity:
            return HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier))
        case .category:
            return HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier))
        case .workout:
            return HKObjectType.workoutType()
        }
    }
}

private let baseHealthDataQueries: [HealthDataQuery] = [
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierBodyFatPercentage",
        displayName: "Body Fat %",
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
        displayName: "Sleep: Awake",
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
        info: nil,
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Core Sleep",
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
        info: "The user is in light or intermediate sleep.",
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "REM Sleep",
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
        info: nil,
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Deep Sleep",
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
        info: nil,
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep",
        categories: [HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue],
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue else {
                return 0
            }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "The user is asleep, but the specific stage isn't specified.  Includes Core, REM and Deep sleep, plus data from other apps.",
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Specified Sleep",
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
        info: "Defined as core sleep plus REM sleep plus deep sleep.",
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep: In Bed",
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
        info: nil,
        sampleType: .category
    ),
    // For counting Deep sleep segments
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Deep Sleep Segments",
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
        info: "Counts the number of Deep sleep segments during the night. Short gaps (up to \(MAXSLEEPSEGMENTGAP) minutes) of Core sleep within a Deep sleep period are still counted as a single segment.",
        sampleType: .category
    ),

    // For counting REM sleep segments
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "REM Sleep Segments",
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
        info: "Counts the number of REM sleep segments during the night. Short gaps (up to \(MAXSLEEPSEGMENTGAP) minutes) of Core sleep within a REM sleep period are still counted as a single segment.",
        sampleType: .category
    ),

    // For counting Awake segments
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Awake Segments",
        categories: [HKCategoryValueSleepAnalysis.awake.rawValue],
        unit: [HKUnit.count()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample,
                  categorySample.value == HKCategoryValueSleepAnalysis.awake.rawValue else {
                return 0
            }
            // The actual segment calculation will happen in a specialized processor
            return 1 // Return 1 to collect all awake samples for processing
        },
        aggregationType: .groupedByNight,
        aggregationTime: DateComponents(hour: 12, minute: 0), // 12:00 PM
        info: "Counts the number of awake segments during the night. Only awake periods of at least 2 minutes are counted as segments.",
        sampleType: .category
    ),

    // For counting sleep cycles (Deep followed by REM)
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep Cycles",
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
        info: "Counts complete sleep cycles, defined as a Deep sleep segment minutes) followed by a REM segment (both at least \(MINSLEEPSEGMENTDURATION) minutes).",
        sampleType: .category
    ),

    // For counting sleep transitions
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierSleepAnalysis",
        displayName: "Sleep Transitions",
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
        info: "Counts the number of transitions between different sleep stages (Core/Deep/REM/Awake) from sleep onset to waking up.",
        sampleType: .category
    ),
    HealthDataQuery(
        identifier: "HKCategoryTypeIdentifierMindfulSession",
        displayName: "Mindful Minutes",
        categories: nil,
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: true,
        aggregationStyle: .cumulative,
        customProcessor: { sample in
            guard let categorySample = sample as? HKCategorySample else { return 0 }
            return categorySample.endDate.timeIntervalSince(categorySample.startDate) / 60.0
        },
        aggregationType: nil,
        aggregationTime: DateComponents(hour: 23, minute: 59),
        info: nil,
        sampleType: .category,
        workoutCategory: .mindAndBody,
        menuTab: .workouts
    ),

    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierHeartRate",
        displayName: "Heart Rate",
        categories: nil,
        unit: [HKUnit(from: "count/min")],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: .highFrequency,
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
        aggregationType: .highFrequency,
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
        displayName: "Oxygen Saturation %",
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
        aggregationTime: nil,
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
        aggregationTime: nil,
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
        aggregationTime: nil,
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
        aggregationTime: nil,
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
        aggregationType: .highFrequency,
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
        aggregationType: .highFrequency,
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
        aggregationType: .highFrequency,
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
        aggregationType: .highFrequency,
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
        aggregationType: .highFrequency,
        aggregationTime: nil,
        info: nil
    ),
    HealthDataQuery(
        identifier: "HKQuantityTypeIdentifierAppleSleepingWristTemperature",
        displayName: "Sleeping Wrist Temperature",
        categories: nil,
        unit: [HKUnit.degreeCelsius(), HKUnit.degreeFahrenheit()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: .highFrequency,
        aggregationTime: DateComponents(hour: 12, minute: 0),
        useEndDate: true,
        info: nil,
        sampleType: .quantity,
        menuTab: .sleep
    ),
]

private struct WorkoutDescriptor {
    let type: HKWorkoutActivityType
    let name: String
    let category: HealthDataQuery.WorkoutCategory
    let supportsDistance: Bool
    let location: HKWorkoutSessionLocationType?
}

private let workoutDescriptors: [WorkoutDescriptor] = {
    var items: [WorkoutDescriptor] = [
        WorkoutDescriptor(type: .americanFootball, name: "American Football", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .archery, name: "Archery", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .australianFootball, name: "Australian Football", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .badminton, name: "Badminton", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .baseball, name: "Baseball", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .basketball, name: "Basketball", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .bowling, name: "Bowling", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .boxing, name: "Boxing", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .climbing, name: "Climbing", category: .outdoor, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .cricket, name: "Cricket", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .crossTraining, name: "Cross Training", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .curling, name: "Curling", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .cycling, name: "Cycling", category: .cardio, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .elliptical, name: "Elliptical", category: .cardio, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .equestrianSports, name: "Equestrian Sports", category: .outdoor, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .fencing, name: "Fencing", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .fishing, name: "Fishing", category: .outdoor, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .functionalStrengthTraining, name: "Functional Strength", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .golf, name: "Golf", category: .sports, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .gymnastics, name: "Gymnastics", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .handball, name: "Handball", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .hiking, name: "Hiking", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .hockey, name: "Hockey", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .hunting, name: "Hunting", category: .outdoor, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .lacrosse, name: "Lacrosse", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .martialArts, name: "Martial Arts", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .mindAndBody, name: "Mind & Body", category: .mindAndBody, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .paddleSports, name: "Paddle Sports", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .play, name: "Play", category: .other, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .preparationAndRecovery, name: "Preparation & Recovery", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .racquetball, name: "Racquetball", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .rowing, name: "Indoor Rowing", category: .cardio, supportsDistance: true, location: .indoor),
    WorkoutDescriptor(type: .rowing, name: "Rowing", category: .cardio, supportsDistance: true, location: .outdoor),
    WorkoutDescriptor(type: .rugby, name: "Rugby", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .running, name: "Running", category: .cardio, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .sailing, name: "Sailing", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .skatingSports, name: "Skating Sports", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .snowSports, name: "Snow Sports", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .soccer, name: "Soccer", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .softball, name: "Softball", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .squash, name: "Squash", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .stairClimbing, name: "Stair Climbing", category: .cardio, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .surfingSports, name: "Surfing Sports", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .swimming, name: "Swimming", category: .cardio, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .tableTennis, name: "Table Tennis", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .tennis, name: "Tennis", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .trackAndField, name: "Track & Field", category: .sports, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .traditionalStrengthTraining, name: "Strength Training", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .volleyball, name: "Volleyball", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .walking, name: "Walking", category: .cardio, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .waterFitness, name: "Water Fitness", category: .outdoor, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .waterPolo, name: "Water Polo", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .waterSports, name: "Water Sports", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .wrestling, name: "Wrestling", category: .sports, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .yoga, name: "Yoga", category: .mindAndBody, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .barre, name: "Barre", category: .mindAndBody, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .coreTraining, name: "Core Training", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .crossCountrySkiing, name: "Cross-Country Skiing", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .downhillSkiing, name: "Downhill Skiing", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .flexibility, name: "Flexibility", category: .mindAndBody, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .highIntensityIntervalTraining, name: "HIIT", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .jumpRope, name: "Jump Rope", category: .cardio, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .kickboxing, name: "Kickboxing", category: .training, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .pilates, name: "Pilates", category: .mindAndBody, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .snowboarding, name: "Snowboarding", category: .outdoor, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .stairs, name: "Stairs", category: .cardio, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .stepTraining, name: "Step Training", category: .cardio, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .wheelchairWalkPace, name: "Wheelchair Walk Pace", category: .wheelchair, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .wheelchairRunPace, name: "Wheelchair Run Pace", category: .wheelchair, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .mixedCardio, name: "Mixed Cardio", category: .cardio, supportsDistance: false, location: nil),
    WorkoutDescriptor(type: .handCycling, name: "Hand Cycling", category: .wheelchair, supportsDistance: true, location: nil),
    WorkoutDescriptor(type: .discSports, name: "Disc Sports", category: .sports, supportsDistance: false, location: nil),
        WorkoutDescriptor(type: .other, name: "Other", category: .other, supportsDistance: false, location: nil)
    ]

    if #available(iOS 14.0, *) {
        items.append(contentsOf: [
            WorkoutDescriptor(type: .taiChi, name: "Tai Chi", category: .mindAndBody, supportsDistance: false, location: nil),
            WorkoutDescriptor(type: .cardioDance, name: "Cardio Dance", category: .cardio, supportsDistance: false, location: nil),
            WorkoutDescriptor(type: .socialDance, name: "Social Dance", category: .mindAndBody, supportsDistance: false, location: nil)
        ])
    }

    if #available(iOS 16.0, *) {
        items.append(contentsOf: [
            WorkoutDescriptor(type: .fitnessGaming, name: "Fitness Gaming", category: .other, supportsDistance: false, location: nil),
            WorkoutDescriptor(type: .pickleball, name: "Pickleball", category: .sports, supportsDistance: false, location: nil)
        ])
    }

    return items
}()

private let workoutHealthDataQueries: [HealthDataQuery] = {
    func identifier(for descriptor: WorkoutDescriptor, metric: HealthDataQuery.WorkoutMetric) -> String {
        let metricSuffix: String
        switch metric {
        case .duration: metricSuffix = "Duration"
        case .totalEnergy: metricSuffix = "Energy"
        case .totalDistance: metricSuffix = "Distance"
        }
        let sanitized = descriptor.name.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "&", with: "")
        let locationSuffix: String
        switch descriptor.location {
        case .indoor: locationSuffix = "Indoor"
        case .outdoor: locationSuffix = "Outdoor"
        default: locationSuffix = ""
        }
        return "HKWorkoutActivityType\(sanitized)\(locationSuffix)\(metricSuffix)"
    }

    func displayName(for descriptor: WorkoutDescriptor, metric: HealthDataQuery.WorkoutMetric) -> String {
        let baseName = descriptor.name
        switch metric {
        case .duration: return "\(baseName) Duration"
        case .totalEnergy: return "\(baseName) Active Energy"
        case .totalDistance: return "\(baseName) Distance"
        }
    }

    var queries: [HealthDataQuery] = []

    for descriptor in workoutDescriptors {
        guard let _ = HKWorkoutActivityType(rawValue: descriptor.type.rawValue) else { continue }

        let durationQuery = HealthDataQuery(
            identifier: identifier(for: descriptor, metric: .duration),
            displayName: displayName(for: descriptor, metric: .duration),
            categories: nil,
            unit: [HKUnit.minute(), HKUnit.hour()],
            needUnit: false,
            aggregationStyle: .discreteArithmetic,
            customProcessor: nil,
            aggregationType: nil,
            aggregationTime: nil,
            info: nil,
            sampleType: .workout,
            workoutActivities: [descriptor.type],
            workoutMetric: .duration,
            workoutLocation: descriptor.location,
            workoutCategory: descriptor.category
        )
        queries.append(durationQuery)

        let energyQuery = HealthDataQuery(
            identifier: identifier(for: descriptor, metric: .totalEnergy),
            displayName: displayName(for: descriptor, metric: .totalEnergy),
            categories: nil,
            unit: [HKUnit.kilocalorie()],
            needUnit: false,
            aggregationStyle: .discreteArithmetic,
            customProcessor: nil,
            aggregationType: nil,
            aggregationTime: nil,
            info: nil,
            sampleType: .workout,
            workoutActivities: [descriptor.type],
            workoutMetric: .totalEnergy,
            workoutLocation: descriptor.location,
            workoutCategory: descriptor.category
        )
        queries.append(energyQuery)

        if descriptor.supportsDistance {
            let distanceQuery = HealthDataQuery(
                identifier: identifier(for: descriptor, metric: .totalDistance),
                displayName: displayName(for: descriptor, metric: .totalDistance),
                categories: nil,
                unit: [HKUnit.meter(), HKUnit.mile()],
                needUnit: false,
                aggregationStyle: .discreteArithmetic,
                customProcessor: nil,
                aggregationType: nil,
                aggregationTime: nil,
                info: nil,
                sampleType: .workout,
                workoutActivities: [descriptor.type],
                workoutMetric: .totalDistance,
                workoutLocation: descriptor.location,
                workoutCategory: descriptor.category
            )
            queries.append(distanceQuery)
        }
    }

    return queries.sorted { $0.displayName < $1.displayName }
}()

/*
private let rowingCombinedQueries: [HealthDataQuery] = [
    HealthDataQuery(
        identifier: "HKWorkoutActivityTypeRowingCombinedDuration",
        displayName: "Rowing Combined Duration",
        categories: nil,
        unit: [HKUnit.minute(), HKUnit.hour()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: "Merges indoor and outdoor rowing workouts for users who record distance indoors.",
        sampleType: .workout,
        workoutActivities: [.rowing],
        workoutMetric: .duration,
        workoutLocation: nil,
        workoutCategory: .cardio
    ),
    HealthDataQuery(
        identifier: "HKWorkoutActivityTypeRowingCombinedEnergy",
        displayName: "Rowing Combined Active Energy",
        categories: nil,
        unit: [HKUnit.kilocalorie()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: "Merges indoor and outdoor rowing workouts for users who record distance indoors.",
        sampleType: .workout,
        workoutActivities: [.rowing],
        workoutMetric: .totalEnergy,
        workoutLocation: nil,
        workoutCategory: .cardio
    ),
    HealthDataQuery(
        identifier: "HKWorkoutActivityTypeRowingCombinedDistance",
        displayName: "Rowing Combined Distance",
        categories: nil,
        unit: [HKUnit.meter(), HKUnit.mile()],
        needUnit: false,
        aggregationStyle: .discreteArithmetic,
        customProcessor: nil,
        aggregationType: nil,
        aggregationTime: nil,
        info: "Merges indoor and outdoor rowing workouts for users who record distance indoors.",
        sampleType: .workout,
        workoutActivities: [.rowing],
        workoutMetric: .totalDistance,
        workoutLocation: nil,
        workoutCategory: .cardio
    )
]
*/

let healthDataQueries: [HealthDataQuery] = baseHealthDataQueries + workoutHealthDataQueries // + rowingCombinedQueries

enum enableStatus: Int {
    case enabled = 1
    case notAuthorised = 2
    case notPresent = 3
    case hidden = 4
}
