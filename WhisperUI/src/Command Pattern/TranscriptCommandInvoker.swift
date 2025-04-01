//
//  TranscriptCommandInvoker.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import Foundation

@Observable
final class TranscriptCommandInvoker {
    private var commandHistory: [TranscriptCommand] = []
    private var redoStack: [TranscriptCommand] = []
    
    var isUndoAvailable: Bool {
        !commandHistory.isEmpty
    }
    
    var isRedoAvailable: Bool {
        !redoStack.isEmpty
    }
    
    func execute(_ command: TranscriptCommand, on transcript: inout Transcript) {
        command.execute(on: &transcript)
        commandHistory.append(command)
        // Clear redo stack on new command execution
        redoStack.removeAll()
    }
    
    func undo(on transcript: inout Transcript) {
        guard let command = commandHistory.popLast() else { return }
        command.undo(on: &transcript)
        redoStack.append(command)
    }
    
    func redo(on transcript: inout Transcript) {
        guard let command = redoStack.popLast() else { return }
        command.execute(on: &transcript)
        commandHistory.append(command)
    }
}
