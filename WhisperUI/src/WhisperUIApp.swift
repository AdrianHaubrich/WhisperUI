//
//  WhisperUIApp.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 19.02.25.
//

import SwiftUI
import SwiftData

@main
struct WhisperUIApp: App {
    @State var transcriptViewModel: TranscriptViewModel
    @State var audioPlayerViewModel: AudioPlayerViewModel
    
    init() {
        transcriptViewModel = TranscriptViewModel(
            whisperKitWrapper: WhisperKitWrapper(),
            transcriptRepository: SwiftDataTranscriptRepository()
        )
        
        audioPlayerViewModel = AudioPlayerViewModel()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(transcriptViewModel)
        .environment(audioPlayerViewModel)
#if os(macOS)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Redo") {
                    transcriptViewModel.redoLastOperation()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!transcriptViewModel.isRedoAvailable)
                
                Button("Undo") {
                    transcriptViewModel.undoLastOperation()
                }
                .keyboardShortcut("z", modifiers: [.command])
                .disabled(!transcriptViewModel.isUndoAvailable)
            }
        }
#endif
    }
}
