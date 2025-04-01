//
//  TranscriptionService.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import Foundation

protocol TranscriptionService {
    func transcribe(use model: WhisperModelType, from url: URL) async -> Transcript
}

actor MockTranscriptionService: TranscriptionService {
    func transcribe(use model: WhisperModelType, from url: URL) async -> Transcript {
        let mockSegments = [
            TranscriptSegment(
                id: UUID().uuidString,
                start: 0.0,
                end: 4.0,
                tokens: [101, 102, 103],
                rawText: "<|startoftranscript|><|transcribe|><|0.00|> Welcome, and thank you for joining us today.<|4.00|>",
                text: "Welcome, and thank you for joining us today.",
                speaker: Speaker(name: "Interviewer")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 4.0,
                end: 10.0,
                tokens: [104, 105, 106],
                rawText: "<|4.00|><|transcribe|><|4.00|> Thank you for having me. I'm excited to be here.<|10.00|>",
                text: "Thank you for having me. I'm excited to be here.",
                speaker: Speaker(name: "Interviewee")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 10.0,
                end: 16.0,
                tokens: [107, 108, 109],
                rawText: "<|10.00|><|transcribe|><|10.00|> Could you start by telling us a bit about your background?<|16.00|>",
                text: "Could you start by telling us a bit about your background?",
                speaker: Speaker(name: "Interviewer")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 16.0,
                end: 25.0,
                tokens: [110, 111, 112],
                rawText: "<|16.00|><|transcribe|><|16.00|> Absolutely, I've been working in software development for over 10 years, specializing in mobile applications.<|25.00|>",
                text: "Absolutely, I've been working in software development for over 10 years, specializing in mobile applications.",
                speaker: Speaker(name: "Interviewee")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 25.0,
                end: 31.0,
                tokens: [113, 114, 115],
                rawText: "<|25.00|><|transcribe|><|25.00|> What do you consider your biggest strength in this field?<|31.00|>",
                text: "What do you consider your biggest strength in this field?",
                speaker: Speaker(name: "Interviewer")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 31.0,
                end: 38.0,
                tokens: [116, 117, 118],
                rawText: "<|31.00|><|transcribe|><|31.00|> I believe my ability to quickly adapt to new technologies is my greatest asset.<|38.00|>",
                text: "I believe my ability to quickly adapt to new technologies is my greatest asset.",
                speaker: Speaker(name: "Interviewee")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 38.0,
                end: 44.0,
                tokens: [119, 120, 121],
                rawText: "<|38.00|><|transcribe|><|38.00|> And how do you handle challenging projects or tight deadlines?<|44.00|>",
                text: "And how do you handle challenging projects or tight deadlines?",
                speaker: Speaker(name: "Interviewer")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 44.0,
                end: 52.0,
                tokens: [122, 123, 124],
                rawText: "<|44.00|><|transcribe|><|44.00|> I prioritize effective communication and time management, ensuring all team members are aligned on the project goals.<|52.00|>",
                text: "I prioritize effective communication and time management, ensuring all team members are aligned on the project goals.",
                speaker: Speaker(name: "Interviewee")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 52.0,
                end: 56.0,
                tokens: [125, 126, 127],
                rawText: "<|52.00|><|transcribe|><|52.00|> Great insights. Thank you for sharing.<|56.00|>",
                text: "Great insights. Thank you for sharing.",
                speaker: Speaker(name: "Interviewer")
            ),
            TranscriptSegment(
                id: UUID().uuidString,
                start: 56.0,
                end: 60.0,
                tokens: [128, 129, 130],
                rawText: "<|56.00|><|transcribe|><|56.00|> Thank you for the opportunity.<|60.00|>",
                text: "Thank you for the opportunity.",
                speaker: Speaker(name: "Interviewee")
            )
        ]
        let mockTranscript = Transcript(
            language: "en",
            segments: mockSegments,
            error: nil
        )
        return mockTranscript
    }
}

actor WhisperKitService: TranscriptionService {
    let whisperKitWrapper: WhisperKitWrapper
    
    init(whisperKitWrapper: WhisperKitWrapper) {
        self.whisperKitWrapper = whisperKitWrapper
    }
    
    func transcribe(use model: WhisperModelType, from url: URL) async -> Transcript {
        var transcript: Transcript
        
        do {
            try await whisperKitWrapper.initKit(for: model)
            transcript = try await whisperKitWrapper.transcribe(use: model, from: url)
        } catch WhisperKitWrapperError.unableToCreateWhisperKit {
            transcript = TranscriptFactory.makeTranscript(from: TranscriptError.unableToInitEngine(engine: "WhisperKit"))
        } catch WhisperKitWrapperError.whisperKitNotInitialized {
            transcript = TranscriptFactory.makeTranscript(from: TranscriptError.engineNotInitialized(engine: "WhisperKit"))
        } catch {
            print("An unexpected error occured: \(error)")
            transcript = TranscriptFactory.makeTranscript(from: TranscriptError.unecxpectedError(error: error))
        }
        
        return transcript
    }
}
