//
//  TranscriptionModelService.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import Foundation

protocol TranscriptionModelService {
    func download(model: WhisperModelType, onProgressChange: @escaping (Progress) -> ()) async
    func delete(model: WhisperModelType) async
    static func getDownloadedModels() async throws -> Set<WhisperModelType>
}

actor WhisperKitModelService: TranscriptionModelService {
    let whisperKitWrapper: WhisperKitWrapper
    let modelDownloadService: ModelDownloadService
    
    init(whisperKitWrapper: WhisperKitWrapper,
         modelDownloadService: ModelDownloadService) {
        self.whisperKitWrapper = whisperKitWrapper
        self.modelDownloadService = modelDownloadService
    }
    
    func download(model: WhisperModelType, onProgressChange: @escaping (Progress) -> ()) async {
        do {
            let _ = try await modelDownloadService.downloadModel(model) { progress in
                onProgressChange(progress)
            }
        } catch {
            print("Failed download with: \(error)")
        }
    }
    
    func delete(model: WhisperModelType) async {
        let fileManager = FileManager.default
        do {
            let modelDirectoryUrl = try WhisperKitWrapper.getModelDirectoryUrl().appendingPathComponent(model.rawValue)
            if fileManager.fileExists(atPath: modelDirectoryUrl.path) {
                try fileManager.removeItem(at: modelDirectoryUrl)
                print("Model \(model.rawValue) deleted successfully.")
            } else {
                print("Model \(model.rawValue) not found.")
            }
        } catch {
            print("Failed to delete model \(model.rawValue) with error: \(error)")
        }
    }
    
    func prepare(model: WhisperModelType) async throws {
        try await whisperKitWrapper.prepare(model: model)
    }
    
    static func getDownloadedModels() async throws -> Set<WhisperModelType> {
        let fileManager = FileManager.default
        let directoryUrl = try WhisperKitWrapper.getModelDirectoryUrl()
        guard fileManager.fileExists(atPath: directoryUrl.path) else {
            return []
        }
        
        let modelNames = try fileManager.contentsOfDirectory(atPath: directoryUrl.path)
        var downloadedModels = Set<WhisperModelType>()
        for name in modelNames {
            if let model = WhisperModelType(rawValue: name) {
                downloadedModels.insert(model)
            }
        }
        
        return downloadedModels
    }
}
