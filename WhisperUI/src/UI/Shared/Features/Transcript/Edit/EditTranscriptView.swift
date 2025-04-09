//
//  EditTranscriptView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.04.25.
//

import SwiftUI

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
