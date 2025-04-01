//
//  HomePage.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import SwiftUI

struct HomePage: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
        
        NavigationSplitView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Select model")
                        .font(.headline)
                    DownloadModelView()
                    
                    Text("Transcripts")
                        .font(.headline)
                        .padding(.top)
                    Button("New Transcription") {
                        transcriptViewModel.navigateToNewTranscription()
                    }.buttonStyle(SecondaryButtonStyle())
                    
                    TranscriptListView()
                }
                .padding(.horizontal)
            }
#if os(macOS)
        .frame(width: 250)
#endif
        } detail: {
            VStack {
                switch transcriptViewModel.currentViewState {
                case .newTranscript:
                    NewTranscriptView()
                case .inTranscription:
                    TranscriptionLoadingView()
                case .editTranscription:
                    EditTranscriptView()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .navigationTitle("WhisperUI")
            .toolbar {
                Button("Undo", systemImage: "arrow.uturn.backward.circle") {
                    transcriptViewModel.undoLastOperation()
                }
                .disabled(!transcriptViewModel.isUndoAvailable)
                
                Button("Redo", systemImage: "arrow.uturn.forward.circle") {
                    transcriptViewModel.redoLastOperation()
                }
                .disabled(!transcriptViewModel.isRedoAvailable)
            }
        }
        .inspector(isPresented: $transcriptViewModel.isInspectorPresented) {
            Divider()
            ScrollView {
                SegmentInspector()
            }
            .toolbar {
                Spacer()
                Button("", systemImage: "sidebar.right") {
                    transcriptViewModel.isInspectorPresented.toggle()
                }
            }
        }
    }
    
}


struct NewTranscriptView: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        VStack {
            Spacer()
            FileImportView() { newPath in
                Task(priority: .userInitiated) {
                    transcriptViewModel.latestFilePath = newPath
                    await transcriptViewModel.transcribe(use: .largeV3, from: newPath)
                }
            }
            .padding()
            Spacer()
        }
    }
}

struct TranscriptionLoadingView: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        Text("Please wait while the transcription is in progress...")
    }
}

struct EditTranscriptView: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
        
        ScrollView {
            VStack {
                TranscriptEditor()
            }
            .padding(.top)
            .padding(.horizontal)
        }
        
        if let latestFilePath = transcriptViewModel.latestFilePath {
            AudioPlayerView(fileURL: latestFilePath, currentTime: $transcriptViewModel.currentTime)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .shadow(radius: 8)
                )
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
}
