//
//  UpdateStartTimeSegmentCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 17.03.25.
//

import Foundation
import OSLog

class UpdateStartTimeSegmentCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "UpdateStartTimeSegmentCommand")
    
    private let segment: TranscriptSegment
    private let newStartTime: Float
    
    init(segment: TranscriptSegment, newStartTime: Float) {
        self.segment = segment
        self.newStartTime = newStartTime
    }
    
    func execute(on transcript: inout Transcript) {
        self.logger.info("execute >>> update start time of segment (\(self.segment.id)) to \(self.newStartTime)")
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        transcript.segments[index].start = newStartTime
    }
    
    func undo(on transcript: inout Transcript) {
        self.logger.info("undo <<< update start time of segment (\(self.segment.id)) to \(self.segment.start)")
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        transcript.segments[index].start = segment.start
    }
}
