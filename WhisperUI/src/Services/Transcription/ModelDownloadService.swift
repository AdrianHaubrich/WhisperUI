//
//  ModelDownloadService.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 24.02.25.
//

import Foundation
import WhisperKit

/**
 A protocol that defines the interface for downloading Whisper models.
 
 Implementers of this protocol provide a method to download a model,
 reporting progress updates and returning the file URL of the downloaded model.
 */
protocol ModelDownloadService {
    func downloadModel(_ model: WhisperModelType, onProgressChange: @escaping (Progress) -> ()) async throws -> URL
}

/**
 An enumeration of errors that can occur during model download operations.
 */
enum ModelDownloadServiceError: Error {
    case invalidFilePathForModelDownload
}

/**
 An implementation of ModelDownloadService that uses WhisperKit to download models.
 
 This actor downloads the requested model from a remote repository and returns
 the local file URL upon a successful download.
 */
actor WhisperKitModelDownloadService: ModelDownloadService {
    let repoName: String = "argmaxinc/whisperkit-coreml"
    
    /**
     Downloads the specified Whisper model.
     
     - Parameters:
        - model: The model type to download.
        - onProgressChange: A closure that is called periodically with progress updates.
     - Returns: A URL pointing to the location of the downloaded model.
     - Throws: An error if the model cannot be downloaded or if the file path is invalid.
     */
    @discardableResult
    func downloadModel(_ model: WhisperModelType, onProgressChange: @escaping (Progress) -> ()) async throws -> URL {
        return try await Task.detached(priority: .userInitiated) { [repoName] in
            let filePathForModelFolder = try? await WhisperKit.download(variant: model.rawValue, from: repoName) { progress in
                onProgressChange(progress)
            }
            
            guard let filePathForModelFolder else {
                throw ModelDownloadServiceError.invalidFilePathForModelDownload
            }
            
            return filePathForModelFolder
        }.value
    }
}
