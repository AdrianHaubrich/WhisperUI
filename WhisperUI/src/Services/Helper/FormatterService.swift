//
//  FormatterService.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import Foundation

struct FormatterService {
    static func formatTime(_ time: Float) -> String {
        let totalMilliseconds = Int(time * 1000)
        let minutes = totalMilliseconds / 60000
        let seconds = (totalMilliseconds % 60000) / 1000
        let milliseconds = totalMilliseconds % 1000
        return String(format: "%02d:%02d,%03d", minutes, seconds, milliseconds)
    }
}
