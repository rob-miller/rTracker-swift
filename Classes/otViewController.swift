//
//  otViewController.swift
//  rTracker
//
//  Created by Robert Miller on 05/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//
import SwiftUI

var _tlist: trackerList?
var tlist: trackerList {
    if _tlist == nil {
        _tlist = trackerList()  // Create the trackerList instance
    }
    return _tlist!
}

struct otViewController: View {
    var onDismiss: (String?, String?, Bool) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var currentTracker: String?
    @State private var currentValue: String?
    @State private var currentSwitch: Bool
    @State private var selectedSegment = 0
    var callerTrackerName: String? // Add this to store the caller's tracker name
    
    init(selectedTracker: String?, selectedValue: String?, otCurrent: Bool, callerTrackerName: String?, onDismiss: @escaping (String?, String?, Bool) -> Void) {
        self.onDismiss = onDismiss
        self._currentTracker = State(initialValue: selectedTracker)
        self._currentValue = State(initialValue: selectedValue)
        self._currentSwitch = State(initialValue: otCurrent)
        self.callerTrackerName = callerTrackerName
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Segmented Control
                Picker("Selection", selection: $selectedSegment) {
                    Text("Tracker").tag(0)
                    Text("Value").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedSegment) { newSegment in
                    if newSegment == 1 && currentTracker == nil {
                        selectedSegment = 0
                    }
                }
                
                // Picker (Choice Wheel) changes based on segmented control
                if selectedSegment == 0 {
                    trackerPicker
                } else {
                    valuePicker
                }
                
                // "Only Current Data" Toggle Switch
                Toggle("Only Current Data", isOn: $currentSwitch)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Data")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            onDismiss(currentTracker, currentValue, currentSwitch)
                            dismiss()
                        }) {
                            Text("\u{2611}")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Done")
                        .accessibilityIdentifier("otvc_done")
                    }
                }
            }
            .onAppear {
                // Set the first tracker if currentTracker is nil
                if currentTracker == nil {
                    let trackers = tlist.toQry2AryS(sql: "select name from toplevel where priv <= \(privacyValue)")
                    let filteredTrackers = trackers.filter { $0 != callerTrackerName }
                    if !filteredTrackers.isEmpty {
                        currentTracker = filteredTrackers[0]
                    }
                }
            }
        }
    }
    
    var trackerPicker: some View {
        // Get all trackers
        let allTrackers = tlist.toQry2AryS(sql: "select name from toplevel where priv <= \(privacyValue)")
        // Filter out the caller's tracker
        let filteredTrackers = allTrackers.filter { $0 != callerTrackerName }
        
        return VStack {
            Text("Select Tracker")
                .font(.headline)
                .padding(.bottom, 5)
            
            Picker("Choose tracker", selection: $currentTracker) {
                ForEach(filteredTrackers, id: \.self) { trackerName in
                    Text(trackerName).tag(trackerName as String?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .onChange(of: currentTracker) { newTracker in
                // Reset value when tracker changes
                currentValue = nil
            }
        }
    }
    
    var valuePicker: some View {
        let valueSet: [String] = {
            if let trackerName = currentTracker {
                let tid = tlist.getTIDfromNameDb(trackerName)[0]
                let to = trackerObj(tid)
                return to.toQry2AryS(sql: "select name from voConfig")
            } else {
                return []
            }
        }()
        
        return VStack {
            Text("Select Value")
                .font(.headline)
                .padding(.bottom, 5)
            
            if currentTracker == nil {
                Text("Please select a tracker first")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Picker("Choose value", selection: $currentValue) {
                    ForEach(valueSet, id: \.self) { valueName in
                        Text(valueName).tag(valueName as String?)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .onAppear {
                    // Set the first value if currentValue is nil and values are available
                    if currentValue == nil && !valueSet.isEmpty {
                        currentValue = valueSet[0]
                    }
                }
            }
        }
    }
}
