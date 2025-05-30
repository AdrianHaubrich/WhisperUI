//
//  TranscriptionLoadingView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.04.25.
//

import SwiftUI

struct TranscriptionLoadingView: View {
    @Environment(InspectorViewModel.self) var inspectorViewModel
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        Text("Please wait while the transcription is in progress...")
            .task {
                inspectorViewModel.currentInspector = .none
            }
    }
}
