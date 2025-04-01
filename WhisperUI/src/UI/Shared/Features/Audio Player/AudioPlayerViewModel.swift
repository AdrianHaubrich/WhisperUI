//
//  AudioPlayerViewModel.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//


import SwiftUI
import AVFoundation

/// An observable object that manages audio playback and progress updates.
class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    init(fileURL: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    /// Seeks the audio playback to the given progress value (0.0 to 1.0).
    func seek(to progress: Double) {
        guard let audioPlayer = audioPlayer else { return }
        
        let newTime = audioPlayer.duration * progress
        audioPlayer.currentTime = newTime
        self.currentTime = newTime
        self.progress = progress
    }

    /// Seeks the audio playback to the specified time.
    func seek(timeInterval: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        audioPlayer.currentTime = timeInterval
        self.currentTime = timeInterval
        if audioPlayer.duration > 0 {
            self.progress = timeInterval / audioPlayer.duration
        }
    }
    
    deinit {
        timer?.invalidate()
    }

    /// Starts playback and begins updating the progress.
    func play() {
        guard let audioPlayer = audioPlayer, !audioPlayer.isPlaying else { return }
        audioPlayer.play()
        isPlaying = true
        startTimer()
    }

    /// Pause playback and keep progress.
    func pause() {
        guard let audioPlayer = audioPlayer, audioPlayer.isPlaying else { return }
        audioPlayer.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    /// Sets up a timer to update the progress bar based on the audio's current time.
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            if player.isPlaying {
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                self.currentTime = player.currentTime
                if player.currentTime >= player.duration {
                    self.isPlaying = false
                    self.timer?.invalidate()
                    self.timer = nil
                }
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    static func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


