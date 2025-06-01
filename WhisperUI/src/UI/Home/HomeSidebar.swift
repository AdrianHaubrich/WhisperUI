//
//  HomeSidebar.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.04.25.
//

import SwiftUI

struct HomeSidebar: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
   
        List(selection: $transcriptViewModel.currentViewState) {
            Section(header: Text("WhisperUI")) {
                NavigationLink(value: TranscriptionViewState.newTranscript) {
                    Label("New Transcription", systemImage: "waveform.badge.mic")
                }
                
                // TODO: View to monitor / manage a transcription that is in progress... maybe inside .newTranscription state...
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
    }
}
