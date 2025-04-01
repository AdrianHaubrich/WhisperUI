//
//  WhisperKitWrapper.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import Foundation
import CoreML
import WhisperKit

protocol TranscriptionEngine {
    func transcribe(use model: WhisperModelType, from url: URL) async throws -> Transcript
}

enum WhisperKitWrapperError: Error {
    case whisperKitNotInitialized
    case unableToCreateWhisperKit
    case unableToAccessFilesystem
    case unableToAccessModelFileNames
    case unableToFindModelLocally
    case unableToFindModelLocallyDueToError
    case unableToSetModelDirectoryInWhisperKit
    case unableToPrewarmModel
    case unableToLoadModelsInWhisperKit
}

/// Takes care of encapsulating internal specifics of WhisperKit that need to be modified.
/// This is the only place where direct interaction with WhisperKit is supposed to happen.
actor WhisperKitWrapper: TranscriptionEngine {
    var whisperKit: WhisperKit?
    
    private static let modelStoragePath: String = "huggingface/models/argmaxinc/whisperkit-coreml"
    private var encoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    private var decoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    
    private var sampleLength: Double = 224
    private var concurrentWorkerCount: Double = 4
    private var chunkingStrategy: ChunkingStrategy = .vad
    private var currentChunks: [Int: (chunkText: [String], fallbacks: Int)] = [:]
    private var isStreamMode = false
    private var currentText: String = ""
    private var currentFallbacks: Int = 0
    private var currentDecodingLoops: Int = 0
    private var compressionCheckWindow: Double = 60
    
    
    func initKit(for model: WhisperModelType) async throws {
        // Create Config
        let config = WhisperKitConfig(
            computeOptions: getComputeOptions(),
            verbose: true,
            logLevel: .debug,
            prewarm: false,
            load: false,
            download: false)
        
        // Create WhisperKit instance
        var whisperKit: WhisperKit
        do {
            whisperKit = try await WhisperKit(config)
        } catch {
            throw WhisperKitWrapperError.unableToCreateWhisperKit
        }
        
        self.whisperKit = whisperKit
        
        try await prepare(model: model)
    }
}

// MARK: Transcribe
extension WhisperKitWrapper {
    func transcribeFile(path: String) async throws -> TranscriptionResult? {
        // Load and convert buffer in a limited scope
        Logging.debug("Loading audio file: \(path)")
        let loadingStart = Date()
        let audioFileSamples = try await Task {
            try autoreleasepool {
                try AudioProcessor.loadAudioAsFloatArray(fromPath: path)
            }
        }.value
        Logging.debug("Loaded audio file in \(Date().timeIntervalSince(loadingStart)) seconds")

        let transcription = try await transcribeAudioSamples(audioFileSamples)
        return transcription

        /*await MainActor.run {
            let currentText = ""
            guard let segments = transcription?.segments else {
                return
            }

            let tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
            let effectiveRealTimeFactor = transcription?.timings.realTimeFactor ?? 0
            let effectiveSpeedFactor = transcription?.timings.speedFactor ?? 0
            let currentEncodingLoops = Int(transcription?.timings.totalEncodingRuns ?? 0)
            let firstTokenTime = transcription?.timings.firstTokenTime ?? 0
            let modelLoadingTime = transcription?.timings.modelLoading ?? 0
            let pipelineStart = transcription?.timings.pipelineStart ?? 0
            let currentLag = transcription?.timings.decodingLoop ?? 0

            let confirmedSegments = segments
        }*/
    }
    
    func transcribeAudioSamples(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit else {
            throw WhisperKitWrapperError.whisperKitNotInitialized
        }

        let languageCode = "de" // Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = .transcribe
        // let seekClip: [Float] = [lastConfirmedSegmentEndSeconds]

        let options = DecodingOptions(
            verbose: true,
            task: task,
            language: languageCode,
            // temperature: Float(temperatureStart),
            // temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            // usePrefillPrompt: enablePromptPrefill,
            // usePrefillCache: enableCachePrefill,
            // skipSpecialTokens: !enableSpecialCharacters,
            // withoutTimestamps: !enableTimestamps,
            wordTimestamps: true,
            // clipTimestamps: seekClip,
            concurrentWorkerCount: Int(concurrentWorkerCount),
            chunkingStrategy: chunkingStrategy
        )
        
        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { [self] (progress: TranscriptionProgress) in
            //DispatchQueue.main.async { [self] in
            let fallbacks = Int(progress.timings.totalDecodingFallbacks)
            let chunkId = isStreamMode ? 0 : progress.windowId
            
            // First check if this is a new window for the same chunk, append if so
            var updatedChunk = (chunkText: [progress.text], fallbacks: fallbacks)
            if var currentChunk = currentChunks[chunkId], let previousChunkText = currentChunk.chunkText.last {
                if progress.text.count >= previousChunkText.count {
                    // This is the same window of an existing chunk, so we just update the last value
                    currentChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                    updatedChunk = currentChunk
                } else {
                    // This is either a new window or a fallback (only in streaming mode)
                    if fallbacks == currentChunk.fallbacks && isStreamMode {
                        // New window (since fallbacks havent changed)
                        updatedChunk.chunkText = [updatedChunk.chunkText.first ?? "" + progress.text]
                    } else {
                        // Fallback, overwrite the previous bad text
                        updatedChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                        updatedChunk.fallbacks = fallbacks
                        print("Fallback occured: \(fallbacks)")
                    }
                }
            }
            
            // Set the new text for the chunk
            currentChunks[chunkId] = updatedChunk
            let joinedChunks = currentChunks.sorted { $0.key < $1.key }.flatMap { $0.value.chunkText }.joined(separator: "\n")
            
            currentText = joinedChunks
            currentFallbacks = fallbacks
            currentDecodingLoops += 1
            //}


            // Check early stopping
            /*let currentTokens = progress.tokens
            let checkWindow = Int(compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    Logging.debug("Early stopping due to compression threshold")
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                Logging.debug("Early stopping due to logprob threshold")
                return false
            }*/
            return nil
        }

        let transcriptionResults: [TranscriptionResult] = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options,
            callback: decodingCallback
        )

        let mergedResults = mergeTranscriptionResults(transcriptionResults)

        return mergedResults
    }
    
    func transcribe(use model: WhisperModelType, from url: URL) async throws -> Transcript {
        print("Init transcribe")
        
        let transcription = try await transcribeFile(path: url.path())
        guard let transcription else {
            print("NO TRANSCRIPTION")
            return TranscriptFactory.makeTranscript(from: TranscriptError.unknownError)
        }
        
        /*let transcription: TranscriptionResult? = try? await whisperKit.transcribe(audioPath: url.path(), decodeOptions: DecodingOptions(task: .transcribe, language: "de"))
        
        guard let transcription = transcription else {
            return TranscriptFactory.makeTranscript(from: TranscriptError.noResultForPath(path: url.path()))
        }
        
        print("Transcription result (\(url.path())): \(transcription)")*/
        return TranscriptFactory.makeTranscript(from: transcription)
    }
}

// MARK: Prepare Model
extension WhisperKitWrapper {
    func prepare(model modelType: WhisperModelType) async throws {
        guard let whisperKit else {
            throw WhisperKitWrapperError.whisperKitNotInitialized
        }
        
        try await self.prepare(model: modelType, with: whisperKit)
    }
    
    private func prepare(model modelType: WhisperModelType, with whisperKit: WhisperKit) async throws {
       do {
           let isModelAvailableLocally = try WhisperKitWrapper.isModelAvailableLocally(modelType)
           
           guard isModelAvailableLocally else {
               throw WhisperKitWrapperError.unableToFindModelLocally
           }
       } catch WhisperKitWrapperError.unableToAccessModelFileNames {
           print("Unable to access file names while searching for model locally")
           throw WhisperKitWrapperError.unableToFindModelLocally
       } catch WhisperKitWrapperError.unableToFindModelLocally {
           print("Model not found locally. Needs to be downloaded first.")
           throw WhisperKitWrapperError.unableToFindModelLocally
       } catch  {
            throw WhisperKitWrapperError.unableToFindModelLocallyDueToError
        }
        
        // Set model directory in WhisperKit to ensure
        do {
            whisperKit.modelFolder = try getLocalFilePathToModel(modelType)
        } catch {
            throw WhisperKitWrapperError.unableToSetModelDirectoryInWhisperKit
        }
        
        // Prewarm model
        do {
            try await whisperKit.prewarmModels()
        } catch {
            throw WhisperKitWrapperError.unableToPrewarmModel
        }
        
        // Load model
        do {
            try await whisperKit.loadModels()
        } catch {
            throw WhisperKitWrapperError.unableToLoadModelsInWhisperKit
        }
    }
}

// MARK: Local availability
extension WhisperKitWrapper {
    static func isModelAvailableLocally(_ model: WhisperModelType) throws -> Bool {
        var locallyAvailableModels = Set<WhisperModelType>()
        
        let modelDirectoryPath = try? getModelDirectoryUrl().path
        guard let modelDirectoryPath else {
            return false
        }
        
        // Guard access to models directory
        guard FileManager.default.fileExists(atPath: modelDirectoryPath) else {
            return false
        }
        
        // Search models by filename in directory and add them to Set
        do {
            let downloadedModelNames = try FileManager.default.contentsOfDirectory(atPath: modelDirectoryPath)
            downloadedModelNames.forEach { modelName in
                if let whisperModel = WhisperModelType(rawValue: modelName) {
                    locallyAvailableModels.insert(whisperModel)
                }
            }
        } catch {
            throw WhisperKitWrapperError.unableToAccessModelFileNames
        }
        
        // Check if Set contains model
        return locallyAvailableModels.contains(model)
    }
    
    private func getLocalFilePathToModel(_ modelType: WhisperModelType) throws -> URL {
        return try getModelDirectoryUrl().appendingPathComponent(modelType.rawValue)
    }
    
    /// Get URL to directory which contains the ML models.
    private func getModelDirectoryUrl() throws -> URL {
        // Guard access to filesystem
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw WhisperKitWrapperError.unableToAccessFilesystem
        }
        
        return documents.appendingPathComponent(WhisperKitWrapper.modelStoragePath)
    }
    
    // Static helper function to get the model directory URL.
    static func getModelDirectoryUrl() throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "TranscriptionModelService", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to access documents directory."])
        }
        return documents.appendingPathComponent(modelStoragePath)
    }
}

// MARK: Compute Options
extension WhisperKitWrapper {
    func changeEncoder(computeOptions: MLComputeUnits) {
        self.encoderComputeUnits = computeOptions
    }
    
    func changeDecoder(computeOptions: MLComputeUnits) {
        self.decoderComputeUnits = computeOptions
    }
    
    private func getComputeOptions() -> ModelComputeOptions {
        return ModelComputeOptions(audioEncoderCompute: encoderComputeUnits, textDecoderCompute: decoderComputeUnits)
    }
}
