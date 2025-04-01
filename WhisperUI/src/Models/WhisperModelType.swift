//
//  WhisperModelType.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 24.02.25.
//

import Foundation

enum WhisperModelType: String, CaseIterable {
    // case recommended = "recommended"
    case tiny = "openai_whisper-tiny"
    case base = "openai_whisper-base"
    case small = "openai_whisper-small"
    case largeV3 = "openai_whisper-large-v3"
}
