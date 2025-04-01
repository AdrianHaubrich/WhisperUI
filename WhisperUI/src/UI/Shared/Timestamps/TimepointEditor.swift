//
//  TimepointEditor.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct TimepointEditor: View {
    @Binding var timepoint: Float
    let label: String
    let onGoalTapped: () -> ()
    
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var milliseconds: Int = 0
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
            Spacer()
            TextField("m", value: $minutes, format: .number)
                .frame(width: 40)
            Text(":")
            TextField("sec", value: $seconds, format: .number)
                .frame(width: 40)
            Text(",")
            TextField("ms", value: $milliseconds, format: .number)
                .frame(width: 50)
            
            Button("", systemImage: "scope") {
                onGoalTapped()
            }
        }
        .onAppear {
            updateFieldsFromTimepoint()
        }
        .onChange(of: timepoint) { _, _ in
            updateFieldsFromTimepoint()
        }
        .onChange(of: minutes) { _, _ in updateTimepoint() }
        .onChange(of: seconds) { _, _ in updateTimepoint() }
        .onChange(of: milliseconds) { _, _ in updateTimepoint() }
    }
    
    private func updateFieldsFromTimepoint() {
        let totalMilliseconds = Int(timepoint * 1000)
        minutes = totalMilliseconds / 60000
        seconds = (totalMilliseconds % 60000) / 1000
        milliseconds = totalMilliseconds % 1000
    }
    
    private func updateTimepoint() {
        let mins = Int(minutes)
        let secs = Int(seconds)
        let ms = Int(milliseconds)
        let newTimepoint = Float(mins * 60) + Float(secs) + Float(ms) / 1000.0
        if abs(newTimepoint - timepoint) > 0.001 {
            timepoint = newTimepoint
        }
    }
}
