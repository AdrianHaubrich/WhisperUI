//
//  DeleteSegmentCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 11.03.25.
//

import Foundation
import OSLog

class DeleteSegmentCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "DeleteSegmentCommand")
    
    private let segment: TranscriptSegment
    private var index: Int?
    
    init(segment: TranscriptSegment) {
        self.segment = segment
    }
    
    func execute(on transcript: inout Transcript) {
        self.logger.info("execute >>> delete segment (\(self.segment.id))")
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        self.index = index
        transcript.segments.remove(at: index)
    }
    
    func undo(on transcript: inout Transcript) {
        self.logger.info("undo <<< delete segment (\(self.segment.id))")
        guard let index else { return }
        transcript.segments.insert(segment, at: index)
    }
}
