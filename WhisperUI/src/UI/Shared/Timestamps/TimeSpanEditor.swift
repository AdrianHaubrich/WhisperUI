//
//  TimeSpanEditor.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct SegmentTimeSpanEditor: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    let segment: TranscriptSegment
    @State private var start: Float
    @State private var end: Float
    
    @State private var debounceTimerStart: Timer?
    @State private var debounceTimerEnd: Timer?
    @State private var shouldSkipNextStartTimeModelUpdate: Bool = false
    @State private var shouldSkipNextEndTimeModelUpdate: Bool = false
    
    init(segment: TranscriptSegment) {
        self.segment = segment
        self.start = segment.start
        self.end = segment.end
        self.shouldSkipNextStartTimeModelUpdate = true
        self.shouldSkipNextEndTimeModelUpdate = true
    }
    
    var body: some View {
        TimeSpanEditor(start: $start, end: $end) { goalType in
            if goalType == .start {
                start = Float(transcriptViewModel.currentTime)
            } else {
                end = Float(transcriptViewModel.currentTime)
            }
        }
        .onChange(of: segment, { oldValue, newValue in
            // Update start / end to selected segment
            self.shouldSkipNextStartTimeModelUpdate = true
            self.shouldSkipNextEndTimeModelUpdate = true
            self.start = segment.start
            self.end = segment.end
        })
        // Sync changes back to model
        .onChange(of: start) { oldValue, newValue in
            if shouldSkipNextStartTimeModelUpdate == true {
                self.shouldSkipNextStartTimeModelUpdate = false
                return
            }
            
            debounceTimerStart?.invalidate()
            
            // Sync changes back to model 0.5s after last change
            debounceTimerStart = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                transcriptViewModel.update(startTime: self.start, for: segment)
            }
        }.onChange(of: end) { oldValue, newValue in
            if shouldSkipNextEndTimeModelUpdate == true {
                // If we sync changes back from the model to the view, then we need to ensure that there is no update triggered. Otherwise it would produce a new update command which clears the redo stack.
                self.shouldSkipNextEndTimeModelUpdate = false
                return
            }
            
            debounceTimerEnd?.invalidate()
            
            // Sync changes back to model 0.5s after last change
            debounceTimerEnd = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                transcriptViewModel.update(endTime: self.end, for: segment)
            }
        }
        // Sync model changes back to view
        .onChange(of: self.segment.start) { oldValue, newValue in
            if self.start != newValue {
                self.shouldSkipNextStartTimeModelUpdate = true
                self.start = newValue
            }
        }.onChange(of: self.segment.end) { oldValue, newValue in
            if self.end != newValue {
                self.shouldSkipNextEndTimeModelUpdate = true
                self.end = newValue
            }
        }
    }
}

struct TimeSpanEditor: View {
    @Binding var start: Float
    @Binding var end: Float
    
    let onGoalTapped: (GoalType) -> ()
    
    enum GoalType {
        case start, end
    }
    
    var body: some View {
        VStack {
            TimepointEditor(timepoint: $start, label: "Start:") {
                onGoalTapped(.start)
            }
            TimepointEditor(timepoint: $end, label: "End:") {
                onGoalTapped(.end)
            }
        }.fixedSize(horizontal: true, vertical: false)
    }
}
