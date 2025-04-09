//
//  TranscriptViewModel.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

enum TranscriptionViewState: Hashable {
    case newTranscript
    case inTranscription
    case editTranscription(_ id: String)
}


enum Inspector {
    case none
    case transcript
    case transcriptSegment
}

@Observable
@MainActor
final class InspectorViewModel {
    public var currentInspector: Inspector = .none
}

@Observable
@MainActor
final class TranscriptViewModel {
    // MARK: Services
    private let whisperKitWrapper: WhisperKitWrapper
    private var transcriptionService: TranscriptionService
    private let transcriptionModelService: TranscriptionModelService
    
    // MARK: Repository
    private let transcriptRepository: TranscriptRepository
    
    // MARK: State
    private(set) var transcripts: [Transcript] = []
    private(set) var transcript: Transcript = TranscriptFactory.makeTranscript(from: TranscriptError.notInitialized)
    private let commandInvoker: TranscriptCommandInvoker = .init()
    
    private var isTranscriptionMockActive: Bool = true
    
    // MARK: View State
    public var currentViewState: TranscriptionViewState = .newTranscript
    
    public var isInspectorPresented: Bool = true
    public var latestFilePath: URL?
    public var selectedSegmentId: String = ""
    public var selectedSegmentIndex: Int {
        return transcript.segments.firstIndex(where: { $0.id == selectedSegmentId }) ?? 0
    }
    public var selectedSegment: TranscriptSegment? {
        return TranscriptService.getSegment(at: selectedSegmentIndex, from: transcript)
    }
    
    public var currentTime: TimeInterval = 0
    
    public var exportPreview: String {
        let text = transcript.segments.reduce(" ") { result, segment in
            result + formatSegmentText(segment: segment,
                                       includeLinebreaks: includeLinebreaks,
                                       includeTimestamps: includeTimestamps,
                                       includeSpeaker: includeSpeaker)
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var isUndoAvailable: Bool {
        commandInvoker.isUndoAvailable
    }
    
    public var isRedoAvailable: Bool {
        commandInvoker.isRedoAvailable
    }
    
    // MARK: Export Options
    // TODO: Track by service... (e.g. ExportTranscriptService)
    public var includeLinebreaks: Bool = true
    public var includeTimestamps: Bool = true
    public var includeSpeaker: Bool = true
    
    
    init(whisperKitWrapper: WhisperKitWrapper, transcriptRepository: TranscriptRepository) {
        self.whisperKitWrapper = whisperKitWrapper
        self.transcriptRepository = transcriptRepository
#if DEBUG
        self.transcriptionService = MockTranscriptionService()
        self.isTranscriptionMockActive = true
#else
        self.transcriptionService = WhisperKitService(whisperKitWrapper: whisperKitWrapper)
        self.isTranscriptionMockActive = false
#endif
        self.transcriptionModelService = WhisperKitModelService(whisperKitWrapper: whisperKitWrapper,
                                                                modelDownloadService: WhisperKitModelDownloadService())
    }
    
    func toggleTrancriptionMock() {
        self.transcriptionService = isTranscriptionMockActive ? MockTranscriptionService() : WhisperKitService(whisperKitWrapper: whisperKitWrapper)
    }
}

// MARK: - Transcribe
extension TranscriptViewModel {
    func transcribe(use model: WhisperModelType, from url: URL, with filename: String) async {
        self.currentViewState = .inTranscription
        self.transcript = await transcriptionService.transcribe(use: model, from: url)
        await self.insertCurrentTranscript()
        setAudioFilename(filename: filename)
        self.currentViewState = .editTranscription(self.transcript.id)
    }
    
    private func setAudioFilename(filename: String) {
        self.transcript.fileName = filename
        saveChanges()
    }
}

// MARK: - Manage Model
extension TranscriptViewModel {
    func download(model: WhisperModelType, onProgressChange: @escaping (Progress) -> ()) async {
        await transcriptionModelService.download(model: model, onProgressChange: onProgressChange)
    }
    
    func delete(model: WhisperModelType) async {
        await transcriptionModelService.delete(model: model)
    }
}

// MARK: - Load Transcript
extension TranscriptViewModel {
    func loadTranscript(with transcriptId: String) async {
        self.transcript = await transcriptRepository.fetchTranscript(withId: transcriptId) ?? TranscriptFactory.makeTranscript(from: TranscriptError.notInitialized)
        
        self.latestFilePath = await FileSystemService().getFileURL(for: transcript.fileName ?? "")
        print("Load audio with name: \(transcript.fileName ?? "no name") at filepath: \(self.latestFilePath?.path() ?? "no path")")
    }
}

// MARK: - Edit Transcript
extension TranscriptViewModel {
    func undoLastOperation() {
        commandInvoker.undo(on: &transcript)
        saveChanges()
    }
    
    func redoLastOperation() {
        commandInvoker.redo(on: &transcript)
        saveChanges()
    }
    
    func add(segment: TranscriptSegment, at index: Int) {
        let command = AddSegmentCommand(newSegment: segment, at: index)
        invokePersistentCommand(command: command)
    }
    
    func addNewSegment(after index: Int) {
        guard let segmentBefore: TranscriptSegment = TranscriptService.getSegment(at: index, from: transcript) else { return }
        let segmentAfter: TranscriptSegment? = TranscriptService.getSegment(at: index + 1, from: transcript)
        
        let newSegment = TranscriptSegment(id: TranscriptService.generateNewIdWith(segment: segmentBefore, and: segmentAfter),
                                           start: segmentBefore.end,
                                           end: segmentAfter?.start ?? segmentBefore.end,
                                           tokens: [],
                                           rawText: "",
                                           text: "",
                                           speaker: Speaker(name: "unknown"))
        
        add(segment: newSegment, at: index + 1)
    }
    
    func duplicateSegment(at index: Int) {
        guard let segment = TranscriptService.getSegment(at: index, from: transcript) else { return }
        let command = DuplicateSegmentCommand(segmentToDuplicate: segment)
        invokePersistentCommand(command: command)
    }
    
    func deleteSegment(at index: Int) {
        guard let segment = TranscriptService.getSegment(at: index, from: transcript) else { return }
        let command = DeleteSegmentCommand(segment: segment)
        invokePersistentCommand(command: command)
    }
    
    func combineWithNextSegment(at index: Int) {
        guard let currentSegment = TranscriptService.getSegment(at: index, from: transcript) else { return }
        guard let nextSegment = TranscriptService.getSegment(at: index + 1, from: transcript) else { return }
        
        let command = CombineWithNextSegmentCommand(currentSegment: currentSegment, nextSegment: nextSegment)
        invokePersistentCommand(command: command)
    }
    
    func alternateSpeakers() {
        let command = AlternateSpeakersForTranscriptCommand(speakers: [Speaker(name: "Interviewer"), Speaker(name: "Interviewee")])
        invokePersistentCommand(command: command)
    }
    
    func updateTranscript(title: String) {
        let command = UpdateTitleCommand(oldTitle: transcript.title, newTitle: title)
        invokePersistentCommand(command: command)
    }
    
    func update(speaker: Speaker, for segment: TranscriptSegment) {
        let command = UpdateSpeakerCommand(newSpeaker: speaker, segment: segment)
        invokePersistentCommand(command: command)
    }
    
    func update(text: String, for segment: TranscriptSegment) {
        let command = UpdateTextCommand(newText: text, segment: segment)
        invokePersistentCommand(command: command)
    }
    
    func update(startTime: Float, for segment: TranscriptSegment) {
        let command = UpdateStartTimeSegmentCommand(segment: segment, newStartTime: startTime)
        invokePersistentCommand(command: command)
    }
    
    func update(endTime: Float, for segment: TranscriptSegment) {
        let command = UpdateEndTimeSegmentCommand(segment: segment, newEndTime: endTime)
        invokePersistentCommand(command: command)
    }
    
    private func invokePersistentCommand(command: TranscriptCommand) {
        commandInvoker.execute(command, on: &transcript)
        saveChanges()
    }
    
    private func saveChanges() {
        Task {
            await transcriptRepository.save()
        }
    }
}

// MARK: - Export / Import Transcript
extension TranscriptViewModel {
    func formatSegmentText(segment: TranscriptSegment,
                           includeLinebreaks: Bool = true,
                           includeTimestamps: Bool = true,
                           includeSpeaker: Bool = true) -> String {
        let divider = "\n"
        let timestamps = "(\(FormatterService.formatTime(segment.start)) - \(FormatterService.formatTime(segment.end)))"
        let speaker = segment.speaker?.name ?? ""
        let text = segment.text
        
        return ""
        + (includeLinebreaks ? divider : " ")
        + (includeTimestamps ? "\(timestamps) " : "")
        + (includeSpeaker ? "\(speaker): " : "")
        + text
    }
    
    // TODO: execute via command
    public func copyExportableTranscript() {
#if os(iOS)
        UIPasteboard.general.string = transcript.getText()
#elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(exportPreview, forType: .string)
#endif
    }
    
    // TODO: execute via command
    public func importTranscriptFromClipboard() {
        // TODO: iOS
        let pasteboard = NSPasteboard.general
        let transcriptString = pasteboard.string(forType: .string)
        print("Importing transcript from pasteboard: \(transcriptString ?? "no content")")
        
        guard let transcriptString else { return }
        let newTranscript = TranscriptFactory.makeTranscript(from: transcriptString, with: self.transcript.id)
        self.transcript.segments = newTranscript.segments
        
        saveChanges()
    }
}

// MARK: - Transcript Repository
extension TranscriptViewModel {
    func insertCurrentTranscript() async {
        await transcriptRepository.insertTranscript(transcript)
        await self.loadTranscripts()
    }
    
    func loadTranscripts() async {
        self.transcripts = await transcriptRepository.fetchAllTranscripts()
    }
}
