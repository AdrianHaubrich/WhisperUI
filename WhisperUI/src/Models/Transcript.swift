//
//  Transcript.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import Foundation
import SwiftData

enum TranscriptError: Error {
    case notInitialized
    case noResultForPath(path: String)
    case unableToInitEngine(engine: String)
    case engineNotInitialized(engine: String)
    case unecxpectedError(error: Error)
    case unecxpectedErrorMessage(message: String)
    case unknownError
}

@Model
final class Transcript {
    var id: String
    var title: String
    var language: String
    var segments: [TranscriptSegment]
    var createdAt: Date
    var audioFilePath: String?
    
    @Transient var error: TranscriptError?
    
    init(id: String? = nil, title: String? = nil, language: String, segments: [TranscriptSegment], error: TranscriptError? = nil, createdAt: Date? = nil, audioFilePath: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.title = title ?? ""
        self.language = language
        self.segments = segments
        self.error = error
        self.createdAt = createdAt ?? Date()
        self.audioFilePath = audioFilePath
    }
}

// MARK: - Codable
extension Transcript: Codable {
    private enum CodingKeys: String, CodingKey {
        case title, language, segments, createdAt, audioFilePath
    }

    /// Decodable initializer
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let title = try container.decode(String.self, forKey: .title)
        let language = try container.decode(String.self, forKey: .language)
        let segments = try container.decode([TranscriptSegment].self, forKey: .segments)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let audioFilePath = try container.decode(String.self, forKey: .audioFilePath)
        
        // We’re not including `error` in the JSON, so pass `nil`
        self.init(title: title, language: language, segments: segments, error: nil, createdAt: createdAt, audioFilePath: audioFilePath)
    }

    /// Encodable method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(language, forKey: .language)
        try container.encode(segments, forKey: .segments)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(audioFilePath, forKey: .audioFilePath)
    }
}

// MARK: - JSON
extension Transcript {
    /// Converts the Transcript instance to a JSON string.
    func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding Transcript: \(error)")
            return nil
        }
    }
    
    /// Creates a Transcript instance from a JSON string.
    static func fromJSONString(_ json: String) -> Transcript? {
        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8) else {
            print("Invalid JSON string.")
            return nil
        }
        do {
            let transcript = try decoder.decode(Transcript.self, from: data)
            return transcript
        } catch {
            print("Error decoding Transcript: \(error)")
            return nil
        }
    }
}

// @Model
// final class TranscriptSegment: Identifiable {
struct TranscriptSegment: Identifiable {
    var id: String
    var start: Float
    var end: Float
    var tokens: [Int]
    var rawText: String
    var text: String
    var speaker: Speaker?
    
    init(
        id: String,
        start: Float,
        end: Float,
        tokens: [Int],
        rawText: String,
        text: String,
        speaker: Speaker? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.tokens = tokens
        self.rawText = rawText
        self.text = text
        self.speaker = speaker
    }
}

extension TranscriptSegment: Equatable {
    static func == (lhs: TranscriptSegment, rhs: TranscriptSegment) -> Bool {
        return lhs.id == rhs.id
    }
}

extension TranscriptSegment: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, start, end, tokens, rawText, text, speaker
    }
    
    /// Decodable convenience initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let start = try container.decode(Float.self, forKey: .start)
        let end = try container.decode(Float.self, forKey: .end)
        let tokens = try container.decode([Int].self, forKey: .tokens)
        let rawText = try container.decode(String.self, forKey: .rawText)
        let text = try container.decode(String.self, forKey: .text)
        let speaker = try container.decodeIfPresent(Speaker.self, forKey: .speaker)
        
        self.init(
            id: id,
            start: start,
            end: end,
            tokens: tokens,
            rawText: rawText,
            text: text,
            speaker: speaker
        )
    }
    
    /// Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start, forKey: .start)
        try container.encode(end, forKey: .end)
        try container.encode(tokens, forKey: .tokens)
        try container.encode(rawText, forKey: .rawText)
        try container.encode(text, forKey: .text)
        try container.encode(speaker, forKey: .speaker)
    }
}


// @Model
// final class Speaker: Hashable, Codable {
struct Speaker: Hashable, Codable {
    var name: String

    // MARK: - Initializer
    init(name: String) {
        self.name = name
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case name
    }
    
    /// Decodable convenience initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        self.init(name: name)
    }
    
    /// Encodable method
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}

/*struct TranscriptWords {
    var start: Float
    var end: Float
    var tokens: [Int]
    var probability: Float
    var word: String
}*/


struct EditedTranscript {
    var text: AttributedString
}
