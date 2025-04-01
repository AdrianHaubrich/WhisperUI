//
//  TranscriptRepository.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 31.03.25.
//

import Foundation
import SwiftUI
import SwiftData

protocol TranscriptRepository {
    func insertTranscript(_ transcript: Transcript) async
    func deleteTranscript(_ transcript: Transcript) async
    func fetchAllTranscripts() async -> [Transcript]
    func fetchTranscript(withId id: String) async -> Transcript?
    
    func save() async
}

/// Singleton that encapsulates SwiftData logic for Transcripts
final class SwiftDataTranscriptRepository: TranscriptRepository {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    @MainActor
    init() {
        self.modelContainer = try! ModelContainer(for: Transcript.self)
        self.modelContext = modelContainer.mainContext
    }
    
    func insertTranscript(_ transcript: Transcript) {
        modelContext.insert(transcript)

        do {
            try modelContext.save()
        } catch {
            print("Error saving transcript: \(error)")
        }
    }
    
    func deleteTranscript(_ transcript: Transcript) {
        modelContext.delete(transcript)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting transcript: \(error)")
        }
    }
    
    func fetchAllTranscripts() -> [Transcript] {
        let fetchDescriptor = FetchDescriptor<Transcript>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error fetching transcripts: \(error)")
            return []
        }
    }
    
    func fetchTranscript(withId id: String) -> Transcript? {
        let fetchDescriptor = FetchDescriptor<Transcript>(predicate: #Predicate<Transcript> { transcript in
            transcript.id == id
        })
        do {
            return try modelContext.fetch(fetchDescriptor).first
        } catch {
            print("Error fetching transcript with id \(id): \(error)")
            return nil
        }
    }
    
    func save() {
        try? modelContext.save()
    }
}
