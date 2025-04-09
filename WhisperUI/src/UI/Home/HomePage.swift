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
            
            List(selection: $transcriptViewModel.currentViewState) {
                Section(header: Text("WhisperUI")) {
                    NavigationLink(value: TranscriptionViewState.newTranscript) {
                        Label("New Transcription", systemImage: "house")
                    }
                }
                .task {
                    await transcriptViewModel.loadTranscripts()
                }
            
                Section(header: Text("Select model")) {
                    DownloadModelView()
                }
                
                Section(header: Text("Transcripts")) {
                    TranscriptListView()
                }
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
                case .editTranscription(let transcriptId):
                    EditTranscriptView(transcriptId: transcriptId)
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
            FileImportView() { newPath, newFilename in
                Task(priority: .userInitiated) {
                    await transcriptViewModel.transcribe(use: .largeV3, from: newPath, with: newFilename)
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
    let transcriptId: String
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
        
        ScrollView {
            LazyVStack {
                TranscriptEditor()
            }
            .padding(.top)
            .padding(.horizontal)
        }
        .task {
            await transcriptViewModel.loadTranscript(with: transcriptId)
        }
        .onChange(of: transcriptId) { _, _ in
            Task {
                await transcriptViewModel.loadTranscript(with: transcriptId)
            }
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
