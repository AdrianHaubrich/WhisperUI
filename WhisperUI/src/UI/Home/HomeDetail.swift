//
//  HomeDetail.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.04.25.
//

import SwiftUI

struct HomeDetail: View {
    @Environment(InspectorViewModel.self) var inspectorViewModel
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
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
}
