//
//  AudioPlayerView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import SwiftUI

/// A SwiftUI view that displays an audio player with a progress bar and a play/stop button.
struct AudioPlayerView: View {
    let fileURL: URL
    @StateObject private var viewModel: AudioPlayerViewModel
    @State private var isScrubbing: Bool = false
    
    @Binding private var currentTime: TimeInterval


    init(fileURL: URL, currentTime: Binding<TimeInterval>) {
        self.fileURL = fileURL
        self._currentTime = currentTime
        self._viewModel = StateObject(wrappedValue: AudioPlayerViewModel(fileURL: fileURL))
    }

    var body: some View {
        VStack(spacing: 8) {
            Slider(value: $viewModel.progress, in: 0...1, onEditingChanged: { editing in
                isScrubbing = editing
                if !editing {
                    viewModel.seek(to: viewModel.progress)
                }
            })
            
            HStack {
                Text(AudioPlayerViewModel.formatTime(viewModel.currentTime))
                Spacer()
                if isScrubbing {
                    Text(AudioPlayerViewModel.formatTime(viewModel.progress * viewModel.duration))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    // Play/Stop button toggles the audio playback
                    Button(viewModel.isPlaying ? "Pause" : "Play") {
                        if viewModel.isPlaying {
                            viewModel.pause()
                        } else {
                            viewModel.play()
                        }
                    }.buttonStyle(PrimaryButtonStyle())
                }
                Spacer()
                Text("-\(AudioPlayerViewModel.formatTime(max(viewModel.duration - viewModel.currentTime, 0)))")
            }
        }
        .padding()
        .onReceive(viewModel.$currentTime) { newTime in
            self.currentTime = newTime
        }
        .onChange(of: currentTime) { _, newTime in
            // Only seek if the external change differs significantly from the viewModel's currentTime.
            if abs(newTime - viewModel.currentTime) > 0.1 {
                viewModel.seek(timeInterval: newTime)
            }
        }
    }
}
