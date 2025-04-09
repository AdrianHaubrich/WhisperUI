//
//  NewTranscriptView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.04.25.
//

import SwiftUI

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
