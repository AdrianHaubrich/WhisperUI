//
//  SegmentInspector.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct TranscriptInspector: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    @State private var title: String = ""
    @State private var isTitleInEdit: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                HStack{
                    Spacer()
                }
                
                Text("Name")
                    .font(.headline)
                
                if isTitleInEdit {
                    HStack {
                        TextField("Title", text: $title)
                            .onSubmit {
                                transcriptViewModel.updateTranscript(title: title)
                                isTitleInEdit = false
                            }
                        
                        Button {
                            transcriptViewModel.updateTranscript(title: title)
                            isTitleInEdit = false
                        } label: {
                            Label("Change name", systemImage: "checkmark")
                                .labelStyle(.iconOnly)
                        }.buttonStyle(PrimaryButtonStyle())
                    }
                } else {
                    HStack {
                        if transcriptViewModel.transcript.title.isEmpty {
                            Text("Untitled")
                        } else {
                            Text(transcriptViewModel.transcript.title)
                        }
                        
                        Button {
                            isTitleInEdit = true
                            title = transcriptViewModel.transcript.title
                        } label: {
                            Label("Edit name", systemImage: "pencil")
                                .labelStyle(.iconOnly)
                        }.buttonStyle(PrimaryButtonStyle())
                    }
                }
                
                // TODO: Option to delete Transcript... (with audio file)
            }
        }
    }
}

struct SegmentInspector: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
        
        VStack {
            TranscriptInspector()
            
            VStack {
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
                        Text("Export preview")
                            .font(.headline)
                        Text(transcriptViewModel.exportPreview)
                    }
                    
                    Spacer().frame(height: 12)
                    
                }
            }
        }
    }
}
