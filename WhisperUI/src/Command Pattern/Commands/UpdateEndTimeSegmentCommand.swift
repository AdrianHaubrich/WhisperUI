//
//  UpdateEndTimeSegmentCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 17.03.25.
//

import Foundation
import OSLog

class UpdateEndTimeSegmentCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "UpdateEndTimeSegmentCommand")
    
    private let segment: TranscriptSegment
    private let newEndTime: Float
    
    init(segment: TranscriptSegment, newEndTime: Float) {
        self.segment = segment
        self.newEndTime = newEndTime
    }
    
    func execute(on transcript: inout Transcript) {
        self.logger.info("execute >>> update end time of segment (\(self.segment.id)) to \(self.newEndTime)")
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        transcript.segments[index].end = newEndTime
    }
    
    func undo(on transcript: inout Transcript) {
        self.logger.info("undo <<< update end time of segment (\(self.segment.id)) to \(self.segment.end)")
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        transcript.segments[index].end = segment.end
    }
}
