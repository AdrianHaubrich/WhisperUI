//
//  TranscriptCommand.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import Foundation

protocol TranscriptCommand {
    func execute(on transcript: inout Transcript)
    func undo(on transcript: inout Transcript)
}
