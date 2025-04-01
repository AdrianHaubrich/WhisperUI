//
//  UpdateSpeakerCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import Foundation
import OSLog

class UpdateSpeakerCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "UpdateSpeakerCommand")
    
    private let segment: TranscriptSegment
    private let oldSpeaker: Speaker
    private let newSpeaker: Speaker
    
    init(newSpeaker: Speaker, segment: TranscriptSegment) {
        self.segment = segment
        self.oldSpeaker = segment.speaker ?? Speaker(name: "unknown")
        self.newSpeaker = newSpeaker
    }
    
    func execute(on transcript: inout Transcript) {
        logger.info("execute >>> update segment (\(self.segment.id) with speaker: \(self.newSpeaker.name))")
        update(speaker: newSpeaker, in: &transcript)
    }
    
    func undo(on transcript: inout Transcript) {
        logger.info("undo <<< update segment (\(self.segment.id) with speaker: \(self.oldSpeaker.name))")
        update(speaker: oldSpeaker, in: &transcript)
    }
    
    private func update(speaker: Speaker, in transcript: inout Transcript) {
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        transcript.segments[index].speaker = speaker
    }
}
