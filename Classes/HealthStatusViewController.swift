//
//  HealthStatusViewController.swift
//  rTracker
//
//  Created by Claude Code on 15/10/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//
///************
/// HealthStatusViewController.swift
/// Copyright 2025 Robert T. Miller
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

import SwiftUI
import HealthKit

/// SwiftUI view displaying Apple Health data source status and permission management
struct HealthStatusViewController: View {
    let showConfigInstructions: Bool
    let onDismiss: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    @State private var healthSources: [(name: String, hkid: String, status: Int)] = []
    @State private var isRefreshing = false
    @State private var showPermissionAlert = false
    @State private var permissionError: String?

    init(showConfigInstructions: Bool = true, onDismiss: (() -> Void)? = nil) {
        self.showConfigInstructions = showConfigInstructions
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top instruction text (conditional)
                if showConfigInstructions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configure number values using ⚙️ to load their values from Apple Health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .background(Color(.systemGroupedBackground))

                    Divider()
                }

                // Scrollable list of health sources
                List {
                    ForEach(healthSources, id: \.hkid) { source in
                        HStack {
                            statusIcon(for: source.status)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.name)
                                    .font(.body)

                                Text(statusText(for: source.status))
                                    .font(.caption)
                                    .foregroundColor(statusColor(for: source.status))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)

                // Bottom button
                VStack {
                    Divider()

                    Button(action: managePermissions) {
                        HStack {
                            Image(systemName: healthKitIcon)
                                .font(.system(size: 18))
                            Text("Manage Permissions")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                    .disabled(isRefreshing)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Apple Health Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss?()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHealthSources()
            }
            .alert("Permission Result", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = permissionError {
                    Text(error)
                } else {
                    Text("Health permissions have been updated. The status list will refresh.")
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func statusIcon(for status: Int) -> some View {
        switch status {
        case 1: // enabled
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 24))
        case 2: // notAuthorised
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 24))
        case 3: // notPresent
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 24))
        default: // hidden or unknown
            Image(systemName: "questionmark.circle")
                .foregroundColor(.gray)
                .font(.system(size: 24))
        }
    }

    private func statusText(for status: Int) -> String {
        switch status {
        case 1: return "Enabled"
        case 2: return "Not Authorized"
        case 3: return "No Data"
        default: return "Unknown"
        }
    }

    private func statusColor(for status: Int) -> Color {
        switch status {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .gray
        }
    }

    // MARK: - Data Loading

    private func loadHealthSources() {
        let tl = trackerList.shared
        let sql = "SELECT name, hkid, '' as dummy, disabled FROM rthealthkit WHERE disabled != 4 ORDER BY name"
        let results = tl.toQry2ArySSSI(sql: sql)

        // Group by hkid to show only one entry per unique HealthKit identifier
        // (e.g., all sleep variants share HKCategoryTypeIdentifierSleepAnalysis)
        var identifierMap: [String: (name: String, status: Int)] = [:]

        for result in results {
            let name = result.0
            let hkid = result.1
            let status = result.3

            // If we haven't seen this identifier yet, or if this is a better representative name
            if identifierMap[hkid] == nil {
                identifierMap[hkid] = (name: getDisplayName(for: hkid, currentName: name), status: status)
            }
        }

        healthSources = identifierMap.map { (name: $0.value.name, hkid: $0.key, status: $0.value.status) }
            .sorted { $0.name < $1.name }

        DBGLog("Loaded \(healthSources.count) unique health sources from \(results.count) total entries")
    }

    /// Returns a user-friendly display name for a HealthKit identifier
    private func getDisplayName(for identifier: String, currentName: String) -> String {
        // Map HealthKit identifiers to friendly display names
        switch identifier {
        case "HKCategoryTypeIdentifierSleepAnalysis":
            return "Sleep Analysis"
        case "HKCategoryTypeIdentifierMindfulSession":
            return "Mindful Session"
        default:
            // For other identifiers, use the current name from database
            return currentName
        }
    }

    // MARK: - Permission Management

    private func managePermissions() {
        isRefreshing = true
        permissionError = nil

        // Get all available health data queries
        let allQueries = healthDataQueries

        // Request authorization
        let rthk = rtHealthKit.shared
        rthk.requestHealthKitAuthorization(healthDataQueries: allQueries) { success, error in
            DispatchQueue.main.async {
                isRefreshing = false

                if let error = error {
                    permissionError = "Error: \(error.localizedDescription)"
                    showPermissionAlert = true
                } else if success {
                    // Trigger re-check of authorization status
                    rthk.updateAuthorisations(request: true) {
                        DispatchQueue.main.async {
                            // Reload the list after authorization check completes
                            loadHealthSources()
                            showPermissionAlert = true
                        }
                    }
                } else {
                    permissionError = "Permission request was not successful."
                    showPermissionAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HealthStatusViewController_Previews: PreviewProvider {
    static var previews: some View {
        HealthStatusViewController(showConfigInstructions: true)
    }
}
#endif
