//
//  rtDocs.swift
//  rTracker
//
//  Created by Robert Miller on 23/09/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import Foundation

// MARK: - Documentation Data Structures

/// Represents a single documentation entry
struct rtDocEntry {
    let identifier: String      // Unique identifier for this entry
    let title: String           // Display title
    let description: String     // Main help text

    init(identifier: String, title: String, description: String) {
        self.identifier = identifier
        self.title = title
        self.description = description
    }
}

/// Main documentation manager class
class rtDocs {

    // MARK: - Singleton
    static let shared = rtDocs()
    private init() {
        // Initialize entries dictionary from static data
        for entry in Self.allEntries {
            entries[entry.identifier] = entry
        }
    }

    // MARK: - Documentation Storage
    private var entries: [String: rtDocEntry] = [:]

    // MARK: - Public API

    /// Get documentation entry by identifier
    func getEntry(_ identifier: String) -> rtDocEntry? {
        return entries[identifier]
    }

    /// Get multiple entries by identifiers
    func getEntries(_ identifiers: [String]) -> [rtDocEntry] {
        return identifiers.compactMap { entries[$0] }
    }

    // MARK: - Static Documentation Data

    static let allEntries: [rtDocEntry] = [
        // Page descriptions
        rtDocEntry(
            identifier: "page_function_overview",
            title: "Function Overview",
            description: "This page shows a summary of your function configuration including the range settings and formula. Use the Range and Definition tabs to modify your function."
        ),
        rtDocEntry(
            identifier: "page_function_range",
            title: "Function Range",
            description: "Set the range of entries your function will calculate over. The 'Previous' endpoint determines where the function starts looking for data, and 'Current' determines where it ends. The function will use all entries between these two points."
        ),
        rtDocEntry(
            identifier: "page_function_definition",
            title: "Function Definition",
            description: "Build your function by selecting operators and values from the picker and tapping 'add'. Use parentheses to group operations and create complex formulas."
        ),
        rtDocEntry(
            identifier: "value_choice",
            title: "Choice Configuration",
            description: "Configure a choice value that lets users select from a predefined list of options."
        ),
        rtDocEntry(
            identifier: "value_info",
            title: "Info Configuration",
            description: "Configure an info value that displays static text or calculated information."
        ),

        // Function operators
        rtDocEntry(
            identifier: "op_change_in",
            title: "change_in",
            description: "Calculates the difference between the last and first values in the range. The value in the first entry is subtracted from the value in the last entry. Example: change_in[odometer] in the Car tracker calculates distance traveled."
        ),
        rtDocEntry(
            identifier: "op_sum",
            title: "sum",
            description: "Adds up all values in the range. All non-empty values between the range endpoints are summed together. Example: sum[calories] totals daily calorie intake."
        ),
        rtDocEntry(
            identifier: "op_post_sum",
            title: "post-sum",
            description: "Sums values excluding the first entry in the range. Used when you want to exclude the starting value from the calculation. Example: post-sum[fuel] excludes initial tank reading for mileage calculation."
        ),
        rtDocEntry(
            identifier: "op_pre_sum",
            title: "pre-sum",
            description: "Sums values excluding the last entry in the range. Used when you want to exclude the ending value from the calculation. Example: pre-sum[purchases] excludes current transaction."
        ),
        rtDocEntry(
            identifier: "op_avg",
            title: "avg",
            description: "Calculates the average value. If the previous endpoint is a time unit (e.g. -2 weeks), the sum is divided by the number of time units; otherwise the sum is divided by the number of entries in the range. Example: avg[blood_pressure] calculates average reading over time."
        ),
        rtDocEntry(
            identifier: "op_min",
            title: "min",
            description: "Returns the minimum value in the range. Finds the smallest non-empty value between the range endpoints. Example: min[weight] finds lowest recorded weight.",
        ),
        rtDocEntry(
            identifier: "op_max",
            title: "max",
            description: "Returns the maximum value in the range. Finds the largest value between the range endpoints. Example: max[temperature] finds highest recorded temperature.",
        ),
        rtDocEntry(
            identifier: "op_count",
            title: "count",
            description: "Counts the number of entries in the range where the value has data stored. Empty entries are not counted. Example: count[exercise_sessions] counts workout days.",
        ),
        rtDocEntry(
            identifier: "op_old_new",
            title: "old/new",
            description: "Calculates the ratio of the first value to the last value in the range. Returns first_value / last_value. Example: old/new[weight] shows weight change ratio.",
        ),
        rtDocEntry(
            identifier: "op_new_old",
            title: "new/old",
            description: "Calculates the ratio of the last value to the first value in the range. Returns last_value / first_value. Example: new/old[savings] shows savings growth ratio.",
        ),
        rtDocEntry(
            identifier: "op_elapsed_weeks",
            title: "elapsed_weeks",
            description: "Calculates weeks between first and last entries with data for the specified value. Example: elapsed_weeks[project] tracks project duration.",
        ),
        rtDocEntry(
            identifier: "op_elapsed_days",
            title: "elapsed_days",
            description: "Calculates days between first and last entries with data for the specified value. Example: elapsed_days[treatment] tracks treatment duration.",
        ),
        rtDocEntry(
            identifier: "op_elapsed_hrs",
            title: "elapsed_hrs",
            description: "Calculates hours between first and last entries with data for the specified value. Example: elapsed_hrs[project] tracks project time.",
        ),
        rtDocEntry(
            identifier: "op_elapsed_mins",
            title: "elapsed_mins",
            description: "Calculates minutes between first and last entries with data for the specified value. Example: elapsed_mins[meeting] tracks meeting duration.",
        ),
        rtDocEntry(
            identifier: "op_elapsed_secs",
            title: "elapsed_secs",
            description: "Calculates seconds between first and last entries with data for the specified value. Example: elapsed_secs[timer] for precise timing.",
        ),
        rtDocEntry(
            identifier: "op_delay",
            title: "delay",
            description: "Returns the value from the first entry in the range. Use this to mark events after a delay. Example: delay[event_date] marks anniversary dates.",
        ),
        rtDocEntry(
            identifier: "op_round",
            title: "round",
            description: "Returns the rounded value from the current entry. Rounds to the nearest integer. Example: round[calculated_score] removes decimal places.",
        ),
        rtDocEntry(
            identifier: "op_classify",
            title: "classify",
            description: "Classifies values into categories based on predefined ranges or criteria. Used for categorizing numeric data into groups.",
        ),
        rtDocEntry(
            identifier: "op_not",
            title: "¬",
            description: "Logical NOT operator. Returns the opposite boolean value. Example: ¬[condition] returns false when condition is true.",
        ),

        // Arithmetic operators
        rtDocEntry(
            identifier: "op_plus",
            title: "+",
            description: "Addition operator. Adds two values together. Example: [value1] + [value2] sums the values.",
        ),
        rtDocEntry(
            identifier: "op_minus",
            title: "-",
            description: "Subtraction operator. Subtracts the second value from the first. Example: [value1] - [value2] finds the difference.",
        ),
        rtDocEntry(
            identifier: "op_multiply",
            title: "*",
            description: "Multiplication operator. Multiplies two values. Example: [hours] * [rate] calculates total cost.",
        ),
        rtDocEntry(
            identifier: "op_divide",
            title: "/",
            description: "Division operator. Divides the first value by the second. Example: [distance] / [time] calculates speed.",
        ),

        // Logical operators
        rtDocEntry(
            identifier: "op_and",
            title: "∧",
            description: "Logical AND operator. Returns true only when both values are true. Example: [condition1] ∧ [condition2].",
        ),
        rtDocEntry(
            identifier: "op_or",
            title: "∨",
            description: "Logical OR operator. Returns true when at least one value is true. Example: [condition1] ∨ [condition2].",
        ),
        rtDocEntry(
            identifier: "op_xor",
            title: "⊕",
            description: "Logical XOR operator. Returns true when exactly one value is true. Example: [condition1] ⊕ [condition2].",
        ),

        // Comparison operators
        rtDocEntry(
            identifier: "op_equal",
            title: "==",
            description: "Equality comparison. Returns true when both values are equal. Example: [value1] == [value2].",
        ),
        rtDocEntry(
            identifier: "op_not_equal",
            title: "!=",
            description: "Inequality comparison. Returns true when values are not equal. Example: [value1] != [value2].",
        ),
        rtDocEntry(
            identifier: "op_greater",
            title: ">",
            description: "Greater than comparison. Returns true when first value is greater than second. Example: [score] > [threshold].",
        ),
        rtDocEntry(
            identifier: "op_less",
            title: "<",
            description: "Less than comparison. Returns true when first value is less than second. Example: [value] < [limit].",
        ),
        rtDocEntry(
            identifier: "op_greater_equal",
            title: ">=",
            description: "Greater than or equal comparison. Returns true when first value is greater than or equal to second. Example: [score] >= [passing_grade].",
        ),
        rtDocEntry(
            identifier: "op_less_equal",
            title: "<=",
            description: "Less than or equal comparison. Returns true when first value is less than or equal to second. Example: [value] <= [maximum].",
        ),

        // Floor/ceiling
        rtDocEntry(
            identifier: "op_floor",
            title: "⌊",
            description: "Floor function. Returns the largest integer less than or equal to the value. Example: ⌊[price]⌋ rounds down to nearest dollar.",
        ),
        rtDocEntry(
            identifier: "op_ceiling",
            title: "⌈",
            description: "Ceiling function. Returns the smallest integer greater than or equal to the value. Example: ⌈[guests]⌉ rounds up for planning.",
        ),

        // Range endpoints
        rtDocEntry(
            identifier: "endpoint_months",
            title: "months",
            description: "Time offset in months. The previous endpoint will be the same time of day, but N months back. Example: '-2 months' means 2 months ago from the current entry time.",
        ),
        rtDocEntry(
            identifier: "endpoint_cal_months",
            title: "cal months",
            description: "Complete calendar months. The previous endpoint will be counted back by complete calendar months. Example: If current entry is Dec 12 with '-2 cal months', the previous endpoint will be 12:00 AM on Nov 1.",
        ),
        rtDocEntry(
            identifier: "endpoint_weeks",
            title: "weeks",
            description: "Time offset in weeks. The previous endpoint will be exactly N weeks (7 days) back from the current entry time.",
        ),
        rtDocEntry(
            identifier: "endpoint_days",
            title: "days",
            description: "Time offset in days. The previous endpoint will be exactly N days back from the current entry time.",
        ),
        rtDocEntry(
            identifier: "endpoint_hours",
            title: "hours",
            description: "Time offset in hours. The previous endpoint will be exactly N hours back from the current entry time.",
        ),
        rtDocEntry(
            identifier: "endpoint_minutes",
            title: "minutes",
            description: "Time offset in minutes. The previous endpoint will be exactly N minutes back from the current entry time.",
        ),

        // General features
        rtDocEntry(
            identifier: "feature_reminders",
            title: "Reminders",
            description: "Set up notifications to remind you to update your tracker at specified times or intervals."
        ),
        rtDocEntry(
            identifier: "feature_export",
            title: "Data Export",
            description: "Export your tracker data in various formats for analysis or backup."
        )
    ]
}
