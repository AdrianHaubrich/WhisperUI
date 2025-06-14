//
//  AudioPlayerViewModel.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//


import SwiftUI
import AVFoundation

/// An observable object that manages audio playback and progress updates.
@Observable
class AudioPlayerViewModel {
    static let defaultJumpInterval: TimeInterval = 5
    
    var isPlaying: Bool = false
    var progress: Double = 0.0
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isAudioFileInvalid: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    init() {}
    
    func load(fileURL: URL) async {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            await MainActor.run {
                withAnimation {
                    isAudioFileInvalid = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation {
                    isAudioFileInvalid = true
                }
            }
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    /// Seeks the audio playback to the given progress value (0.0 to 1.0).
    @MainActor
    func seek(to progress: Double) {
        guard let audioPlayer = audioPlayer else { return }
        
        let newTime = audioPlayer.duration * progress
        audioPlayer.currentTime = newTime
        self.currentTime = newTime
        self.progress = progress
    }

    /// Seeks the audio playback to the specified time.
    @MainActor
    func seek(timeInterval: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        audioPlayer.currentTime = timeInterval
        self.currentTime = timeInterval
        if audioPlayer.duration > 0 {
            self.progress = timeInterval / audioPlayer.duration
        }
    }
    
    /// Jumps backwards in playback by the default number of seconds.
    @MainActor
    func jumpBackwards() {
        jumpBackwards(seconds: AudioPlayerViewModel.defaultJumpInterval)
    }
    
    /// Jumps backwards in playback by a given number of seconds.
    @MainActor
    func jumpBackwards(seconds: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        let newTime = max(audioPlayer.currentTime - seconds, 0)
        seek(timeInterval: newTime)
    }
    
    /// Jumps forwards in playback by the default number of seconds.
    @MainActor
    func jumpForwards() {
        jumpForwards(seconds: AudioPlayerViewModel.defaultJumpInterval)
    }
    
    /// Jumps forwards in playback by a given number of seconds.
    @MainActor
    func jumpForwards(seconds: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        let newTime = min(audioPlayer.currentTime + seconds, audioPlayer.duration)
        seek(timeInterval: newTime)
    }
    
    deinit {
        timer?.invalidate()
    }

    /// Starts playback and begins updating the progress.
    @MainActor
    func play() {
        guard let audioPlayer = audioPlayer, !audioPlayer.isPlaying else { return }
        audioPlayer.play()
        isPlaying = true
        startTimer()
    }

    /// Pause playback and keep progress.
    @MainActor
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
