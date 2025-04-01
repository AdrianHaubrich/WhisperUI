//
//  UpdateTextCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import Foundation
import OSLog

class UpdateTextCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "UpdateTextCommand")
    
    private let segment: TranscriptSegment
    private let oldText: String
    private let newText: String
    
    init(newText: String, segment: TranscriptSegment) {
        self.segment = segment
        self.oldText = segment.text
        self.newText = newText
    }
    
    func execute(on transcript: inout Transcript) {
        logger.info("execute >>> update segment (\(self.segment.id) with text: \(self.newText))")
        update(text: newText, in: &transcript)
    }
    
    func undo(on transcript: inout Transcript) {
        logger.info("undo <<< update segment (\(self.segment.id) with text: \(self.oldText))")
        update(text: oldText, in: &transcript)
    }
    
    private func update(text: String, in transcript: inout Transcript) {
        guard let index = transcript.segments.firstIndex(of: segment) else { return }
        transcript.segments[index].text = text
    }
}
