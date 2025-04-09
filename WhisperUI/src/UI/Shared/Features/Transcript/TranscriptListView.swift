//
//  TranscriptListView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 31.03.25.
//

import SwiftUI
import SwiftData

struct TranscriptListView: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    @State var currentTranscript: Transcript?
    @State var isEditMode: Bool = false
    
    @FocusState private var isFocused: Bool
    
    // DateFormatter for human-readable date and time.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // e.g., Jan 1, 2025
        formatter.timeStyle = .short   // e.g., 3:45 PM
        return formatter
    }
    
    var body: some View {
        ForEach(transcriptViewModel.transcripts) { transcript in
            NavigationLink(value: TranscriptionViewState.editTranscription(transcript.id)) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Spacer()
                    }
                    
                    if isEditMode, currentTranscript == transcript {
                        TextField("Title", text: Binding(
                            get: { transcript.title },
                            set: { newTitle in
                                transcript.title = newTitle
                            }))
                        .onSubmit {
                            transcriptViewModel.updateTranscript(title: transcript.title)
                            currentTranscript = nil
                            isEditMode = false
                        }
                    } else {
                        Text(transcript.title.isEmpty ? "Untitled" : transcript.title)
                            .font(.headline)
                    }
                    
                    Text(dateFormatter.string(from: transcript.createdAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .task {
                await transcriptViewModel.loadTranscripts()
            }
        }
    }
}

struct TranscriptListView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptListView()
    }
}
