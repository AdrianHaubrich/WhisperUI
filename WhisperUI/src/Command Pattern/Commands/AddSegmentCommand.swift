//
//  AddSegmentCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import Foundation
import OSLog

class AddSegmentCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "AddSegmentCommand")
    
    private let newSegment: TranscriptSegment
    private let index: Int
    
    init(newSegment: TranscriptSegment, at index: Int) {
        self.newSegment = newSegment
        self.index = index
    }
    
    func execute(on transcript: inout Transcript) {
        logger.info("execute >>> insert segment (\(self.newSegment.id)) at \(self.index)")
        transcript.segments.insert(newSegment, at: index)
    }
    
    func undo(on transcript: inout Transcript) {
        guard let index = transcript.segments.firstIndex(of: newSegment) else { return }
        logger.info("undo <<< insert segment (\(self.newSegment.id)) from \(index)")
        transcript.segments.remove(at: index)
    }
}



