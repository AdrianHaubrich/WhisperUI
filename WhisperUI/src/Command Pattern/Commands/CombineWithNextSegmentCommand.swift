//
//  CombineWithNextSegmentCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 11.03.25.
//

import Foundation
import OSLog

class CombineWithNextSegmentCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "CombineWithNextSegmentCommand")
    
    private let currentSegment: TranscriptSegment
    private let nextSegment: TranscriptSegment
    
    init(currentSegment: TranscriptSegment, nextSegment: TranscriptSegment) {
        self.currentSegment = currentSegment
        self.nextSegment = nextSegment
    }
    
    func execute(on transcript: inout Transcript) {
        self.logger.info("execute >>> combine segments (\(self.currentSegment.id)) and (\(self.nextSegment.id))")
        
        guard let indexOfNextSegment = transcript.segments.firstIndex(of: nextSegment) else { return }
        guard let indexOfCurrentSegment = transcript.segments.firstIndex(of: currentSegment) else { return }
        
        let newEnd = nextSegment.end
        let additionalText = nextSegment.text
        
        // Create new segment because the current segment needs to be immutable to enable undo feature
        var newSegment = currentSegment
        newSegment.end = newEnd
        newSegment.text += " " + additionalText
        
        transcript.segments.remove(at: indexOfCurrentSegment)
        transcript.segments.insert(newSegment, at: indexOfCurrentSegment)
        transcript.segments.remove(at: indexOfNextSegment)
    }
    
    func undo(on transcript: inout Transcript) {
        self.logger.info("undo <<< combine segments (\(self.currentSegment.id)) and (\(self.nextSegment.id))")
        
        guard let indexOfCurrentSegment = transcript.segments.firstIndex(of: currentSegment) else { return }
        
        transcript.segments.remove(at: indexOfCurrentSegment)
        transcript.segments.insert(currentSegment, at: indexOfCurrentSegment)
        transcript.segments.insert(nextSegment, at: indexOfCurrentSegment + 1)
    }
}
