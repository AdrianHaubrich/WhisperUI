//
//  SegmentInspector.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct SegmentInspector: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
        
        VStack {
            if transcriptViewModel.selectedSegmentId != "" {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        HStack{
                            Spacer()
                        }
                        Text("Time")
                            .font(.headline)
                        if let segment = transcriptViewModel.selectedSegment {
                            SegmentTimeSpanEditor(segment: segment)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Spacer()
                        }
                        Text("Speaker")
                            .font(.headline)
                        if let segment = transcriptViewModel.selectedSegment {
                            SpeakerSelectionPicker(speaker: segment.speaker ?? Speaker(name: "unknown")) { newSpeaker in
                                transcriptViewModel.update(speaker: newSpeaker, for: segment)
                            }
                        }
                        
                        Button("Alternate speakers") {
                            DispatchQueue.main.async {
                                transcriptViewModel.alternateSpeakers()
                            }
                        }.buttonStyle(SecondaryButtonStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Spacer()
                        }
                        Text("Edit segment")
                            .font(.headline)
                        Button("Combine with next segment") {
                            DispatchQueue.main.async {
                                transcriptViewModel.combineWithNextSegment(at: transcriptViewModel.selectedSegmentIndex)
                            }
                        }.buttonStyle(SecondaryButtonStyle())
                        
                        Button("Duplicate segment") {
                            DispatchQueue.main.async {
                                transcriptViewModel.duplicateSegment(at: transcriptViewModel.selectedSegmentIndex)
                            }
                        }.buttonStyle(SecondaryButtonStyle())
                        
                        Button("Add new segment") {
                            DispatchQueue.main.async {
                                transcriptViewModel.addNewSegment(after: transcriptViewModel.selectedSegmentIndex)
                            }
                        }.buttonStyle(SecondaryButtonStyle())
                        
                        Button("Delete segment") {
                            DispatchQueue.main.async {
                                transcriptViewModel.deleteSegment(at: transcriptViewModel.selectedSegmentIndex)
                            }
                        }.buttonStyle(SecondaryButtonStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Spacer()
                        }
                        Text("Export")
                            .font(.headline)
                        
                        Toggle("Include Linebreaks", isOn: $transcriptViewModel.includeLinebreaks)
                        Toggle("Include Timestamps", isOn: $transcriptViewModel.includeTimestamps)
                        Toggle("Include Speaker", isOn: $transcriptViewModel.includeSpeaker)
                        
                        Button("Copy transcript") {
                            transcriptViewModel.copyExportableTranscript()
                        }.buttonStyle(PrimaryButtonStyle())
                        
                        Button("Import transcript") {
                            DispatchQueue.main.async {
                                transcriptViewModel.importTranscriptFromClipboard()
                            }
                        }.buttonStyle(SecondaryButtonStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        HStack{
                            Spacer()
                        }
                        Text("Live preview")
                            .font(.headline)
                        Text(transcriptViewModel.transcriptLivePreview)
                    }
                    
                    Spacer().frame(height: 12)
                    
                }.padding(.horizontal)
            } else {
                Text("Select a segment...")
            }
        }
    }
}
