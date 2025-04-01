//
//  TranscriptFactory.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import Foundation
import WhisperKit

struct TranscriptFactory {
    /// Creates a Transcript from a given TranscriptionResult.
    /// - Parameter result: The TranscriptionResult produced during transcription.
    /// - Returns: A Transcript that contains mapped segments, aggregated words, and the detected language.
    static func makeTranscript(from result: TranscriptionResult) -> Transcript {
        // Map each TranscriptionSegment to a TranscriptSegment using rawText
        let transcriptSegments: [TranscriptSegment] = result.segments.map { segment in
            // Remove metadata enclosed in <|...|> from the rawText to get clean text
            let cleanedText = segment.text.replacingOccurrences(of: "<\\|[^|]+\\|>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespaces)
            
            return TranscriptSegment(
                id: String(segment.id) + "_\(UUID().uuidString)",
                start: segment.start,
                end: segment.end,
                tokens: segment.tokens,
                rawText: segment.text,
                text: cleanedText
            )
        }
        
        // Create and return the Transcript with the aggregated text
        return Transcript(
            language: result.language,
            segments: transcriptSegments,
            error: nil
        )
    }
    
    static func makeTranscript(from exportedString: String, with id: String) -> Transcript {
        // Split the exported string by newlines and trim whitespace
        let lines = exportedString.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        var segments: [TranscriptSegment] = []
        
        // Regular expression pattern to match lines with optional timestamp and speaker.
        // Timestamp: Optional, in the format "(start - end)". Speaker: Optional, followed by a colon. Text: Required.
        let pattern = "^(?:\\(([^)]+)\\)\\s*)?(?:(.*?):\\s*)?(.*)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return Transcript(language: "de", segments: [], error: .unecxpectedError(error: NSError(domain: "RegexError", code: 0, userInfo: nil)))
        }
        
        for line in lines where !line.isEmpty {
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = regex.firstMatch(in: line, options: [], range: range), match.numberOfRanges >= 4,
               let textRange = Range(match.range(at: 3), in: line) {
                
                // Process timestamp if available, otherwise default to 0.0
                var start: Float = 0.0
                var end: Float = 0.0
                if let timestampsRange = Range(match.range(at: 1), in: line) {
                    let timestampsString = String(line[timestampsRange])
                    let times = timestampsString.components(separatedBy: " - ")
                    if times.count == 2 {
                        start = parseTime(String(times[0]))
                        end = parseTime(String(times[1]))
                    }
                }
                
                // Extract speaker if available
                var speaker: Speaker? = nil
                let speakerRange = match.range(at: 2)
                if speakerRange.location != NSNotFound, let rangeSpeaker = Range(speakerRange, in: line) {
                    let speakerName = String(line[rangeSpeaker])
                    if !speakerName.isEmpty {
                        speaker = Speaker(name: speakerName)
                    }
                }
                
                let text = String(line[textRange])
                let segment = TranscriptSegment(id: UUID().uuidString, start: start, end: end, tokens: [], rawText: text, text: text, speaker: speaker)
                segments.append(segment)
            }
        }
        
        return Transcript(id: id, language: "en", segments: segments, error: nil)
    }
    
    static func makeTranscript(from error: TranscriptError) -> Transcript {
        return Transcript(language: "", segments: [], error: error)
    }
    
    private static func parseTime(_ timeString: String) -> Float {
        // Replace comma with dot to handle timestamps like "00:52,000"
        let cleanedTimeString = timeString.replacingOccurrences(of: ",", with: ".")
        let components = cleanedTimeString.split(separator: ":").compactMap { Float($0) }
        if components.count == 2 {
            return components[0] * 60 + components[1]
        } else if components.count == 3 {
            return components[0] * 3600 + components[1] * 60 + components[2]
        }
        return 0.0
    }
}
