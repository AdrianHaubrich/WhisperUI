//
//  TranscriptService.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 11.03.25.
//

import Foundation

actor TranscriptService {
    // FIXME: Due to the precision of Doubles this could lead to duplicates
    static func generateNewIdWith(segment segmentBefore: TranscriptSegment, and segmentAfter: TranscriptSegment?) -> String {
        /*guard let segmentAfter else {
            return segmentBefore.id + 1
        }
        
        return (segmentBefore.id + segmentAfter.id) / 2*/
        
        return UUID().uuidString
    }
    
    static func getSegment(at index: Int, from transcript: Transcript) -> TranscriptSegment? {
        if transcript.segments.count - 1 < index {
            return nil
        }
        
        return transcript.segments[index]
    }
}
