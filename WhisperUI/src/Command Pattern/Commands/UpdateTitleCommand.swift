//
//  UpdateTitleCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 01.04.25.
//

import Foundation
import OSLog

class UpdateTitleCommand: TranscriptCommand {
    private let logger = Logger(subsystem: "com.whisperUI.TranscriptCommand", category: "UpdateTitleCommand")
    
    private let oldTitle: String
    private let newTitle: String
    
    init(oldTitle: String, newTitle: String) {
        self.oldTitle = oldTitle
        self.newTitle = newTitle
    }
    
    func execute(on transcript: inout Transcript) {
        logger.info("execute >>> change title to \(self.newTitle)")
        transcript.title = self.newTitle
    }
    
    func undo(on transcript: inout Transcript) {
        logger.info("undo <<< change name to \(self.oldTitle)")
        transcript.title = self.oldTitle
    }
}
