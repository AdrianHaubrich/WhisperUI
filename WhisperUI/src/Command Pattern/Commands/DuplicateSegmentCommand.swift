//
//  DuplicateSegmentCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 11.03.25.
//

import Foundation
import OSLog

class DuplicateSegmentCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "DuplicateSegmentCommand")
    private let segmentToDuplicate: TranscriptSegment
    private var newSegment: TranscriptSegment
    
    init(segmentToDuplicate: TranscriptSegment) {
        self.segmentToDuplicate = segmentToDuplicate
        self.newSegment = segmentToDuplicate
    }
    
    func execute(on transcript: inout Transcript) {
        logger.info("execute >>> duplicate segment (\(self.segmentToDuplicate.id))")
        guard let index = transcript.segments.firstIndex(of: segmentToDuplicate) else { return }
        
        let nextSegment = TranscriptService.getSegment(at: index + 1, from: transcript)
        newSegment.id = TranscriptService.generateNewIdWith(segment: segmentToDuplicate, and: nextSegment)
        transcript.segments.insert(newSegment, at: index + 1)
    }
    
    func undo(on transcript: inout Transcript) {
        logger.info("undo <<< duplicate segment (\(self.newSegment.id))")
        guard let index = transcript.segments.firstIndex(of: newSegment) else { return }
        transcript.segments.remove(at: index)
    }
}
