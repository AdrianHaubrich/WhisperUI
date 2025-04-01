//
//  AlternateSpeakersForTranscriptCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 31.03.25.
//

import Foundation
import OSLog

class AlternateSpeakersForTranscriptCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "AlternateSpeakersForTranscriptCommand")
    private let speakers: [Speaker]
    private var oldSegments: [TranscriptSegment]?
    
    init(speakers: [Speaker]) {
        self.speakers = speakers
    }
    
    func execute(on transcript: inout Transcript) {
        logger.info("execute >>> alternate speakers for transcript")
        oldSegments = transcript.segments
        
        guard speakers.count > 0 else { return }
        var speakerIndex = 0
        for index in 0..<transcript.segments.count {
            transcript.segments[index].speaker = speakers[speakerIndex]
            speakerIndex = nextSpeakerIndex(speakers: speakers, speakerIndex: speakerIndex)
        }
    }
    
    private func nextSpeakerIndex(speakers: [Speaker], speakerIndex: Int) -> Int {
        if speakerIndex + 1 < speakers.count {
            return speakerIndex + 1
        }
        
        return 0
    }
    
    func undo(on transcript: inout Transcript) {
        logger.info("undo <<< alternate speakers for transcript")
        guard let oldSegments else { return }
        transcript.segments = oldSegments
    }
}
