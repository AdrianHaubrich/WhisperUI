//
//  AudioPlayerView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import SwiftUI

struct AudioPlayerCard: View {
    @Environment(AudioPlayerViewModel.self) var viewModel
    
    let fileURL: URL
    @Binding var currentTime: TimeInterval
    
    var body: some View {
        AudioPlayerView(fileURL: fileURL, currentTime: $currentTime)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(radius: 8)
            )
            .padding(.horizontal)
            .padding(.bottom, viewModel.isAudioFileInvalid ? 0 : 8)
    }
}

/// A SwiftUI view that displays an audio player with a progress bar and a play/stop button.
struct AudioPlayerView: View {
    @Environment(AudioPlayerViewModel.self) var viewModel
    
    let fileURL: URL
    @State private var isScrubbing: Bool = false
    @Binding private var currentTime: TimeInterval

    init(fileURL: URL, currentTime: Binding<TimeInterval>) { // FIXME: Binding triggers to ofen, which leads to resets of the time. Seems to be connected to the recreation of segments?
        self.fileURL = fileURL
        print("file in audio player is initially \(fileURL)")
        self._currentTime = currentTime // FIXME: overrides time on every load?
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack {
            if viewModel.isAudioFileInvalid {
                EmptyView()
            } else {
                VStack(spacing: 8) {
                    AudioPlayerSlider(isScrubbing: $isScrubbing)
                    
                    WaveformScrubber(url: self.fileURL, progress: $viewModel.progress)
                    .frame(height: isScrubbing ? 60 : 0) // ensured that the view is not recreated
                    
                    AudioPlayerControls(isScrubbing: $isScrubbing)
                }
                .padding()
            }
        }
        .task {
            await viewModel.load(fileURL: fileURL)
        }
        .onChange(of: fileURL) { oldValue, newValue in
            print("file in audio player changed to \(newValue)")
            
            Task {
                await viewModel.load(fileURL: newValue)
            }
        }
        .onChange(of: viewModel.currentTime, { _, newTime in
            self.currentTime = newTime
        })
        .onChange(of: currentTime) { _, newTime in
            // Only seek if the external change differs significantly from the viewModel's currentTime.
            if abs(newTime - viewModel.currentTime) > 0.1 {
                viewModel.seek(timeInterval: newTime)
            }
        }
    }
}

struct AudioPlayerSlider: View {
    @Environment(AudioPlayerViewModel.self) var viewModel
    @Binding var isScrubbing: Bool
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        Slider(value: $viewModel.progress, in: 0...1, onEditingChanged: { editing in
            withAnimation {
                isScrubbing = editing
            }
            if !editing {
                viewModel.seek(to: viewModel.progress)
            }
        })
    }
}

struct AudioPlayerControls: View {
    @Environment(AudioPlayerViewModel.self) var viewModel
    @Binding var isScrubbing: Bool
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        HStack {
            Text(AudioPlayerViewModel.formatTime(viewModel.currentTime))
            Spacer()
            if isScrubbing {
                Text(AudioPlayerViewModel.formatTime(viewModel.progress * viewModel.duration))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Button {
                    viewModel.jumpBackwards()
                } label: {
                    Label("Jump 5 seconds back", systemImage: "gobackward.5")
                        .labelStyle(.iconOnly)
                }.buttonStyle(PlayActionButtonStyle())
                
                Button {
                    if viewModel.isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                } label: {
                    Label(viewModel.isPlaying ? "Pause" : "Play", systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .labelStyle(.iconOnly)
                }.buttonStyle(PlayActionButtonStyle())
                
                Button {
                    viewModel.jumpForwards()
                } label: {
                    Label("Jump 5 seconds forward", systemImage: "goforward.5")
                        .labelStyle(.iconOnly)
                }.buttonStyle(PlayActionButtonStyle())
            }
            Spacer()
            Text("-\(AudioPlayerViewModel.formatTime(max(viewModel.duration - viewModel.currentTime, 0)))")
        }
    }
}



