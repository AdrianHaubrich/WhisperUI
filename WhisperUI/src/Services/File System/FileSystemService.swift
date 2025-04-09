//
//  FileSystemService.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import Foundation

actor FileSystemService {
    private let fileManager = FileManager.default

    // Returns the URL for the app's Documents directory.
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Returns the URL for the "selected-files" folder.
    private var selectedFilesDirectory: URL {
        documentsDirectory.appendingPathComponent("selected-files", isDirectory: true)
    }
    
    // Ensures that the "selected-files" folder exists.
    private func createSelectedFilesDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: selectedFilesDirectory.path) {
            try fileManager.createDirectory(at: selectedFilesDirectory,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
    }
}

// MARK: - Public API
extension FileSystemService {
    /// Returns the URL for a file in the "selected-files" directory given its file name.
    func getFileURL(for fileName: String) -> URL {
        return selectedFilesDirectory.appendingPathComponent(fileName)
    }
    
    /// Public entry point for copying a file into the selected-files directory.
    /// This method handles file coordination and security-scoped resource access.
    func copyFile(from originalURL: URL) async throws -> (url: URL, filename: String) {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var safeURL: URL?
        coordinator.coordinate(readingItemAt: originalURL, options: [], error: &coordinatorError) { url in
            safeURL = url
        }
        if let error = coordinatorError {
            throw error
        }
        guard let safeURL = safeURL else {
            throw NSError(domain: "FileSystemService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to coordinate file URL"])
        }
        
        if safeURL.startAccessingSecurityScopedResource() {
            defer { safeURL.stopAccessingSecurityScopedResource() }
            return try await copyFileUsingCopyItem(from: safeURL)
        } else {
            return try await streamCopyFileToSelectedFiles(from: safeURL)
        }
    }
}

// MARK: - Private Copy Methods
extension FileSystemService {
    /// Copies a file from the given URL into the "selected-files" folder using FileManager.copyItem.
    /// The new filename preserves the original name with a UUID appended before the file extension.
    private func copyFileUsingCopyItem(from originalURL: URL) async throws -> (url: URL, filename: String) {
        // Begin accessing the file's security-scoped resource.
        guard originalURL.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "FileSystemService",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to access security scoped resource"])
        }
        defer {
            originalURL.stopAccessingSecurityScopedResource()
        }

        try createSelectedFilesDirectoryIfNeeded()

        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let fileExtension = originalURL.pathExtension
        let uuidString = UUID().uuidString
        let newFilename = fileExtension.isEmpty ? "\(baseName)_\(uuidString)" : "\(baseName)_\(uuidString).\(fileExtension)"
        let destinationURL = selectedFilesDirectory.appendingPathComponent(newFilename)

        try fileManager.copyItem(at: originalURL, to: destinationURL)
        return (destinationURL, newFilename)
    }
    
    /// Copies a temporary file from the given URL into the "selected-files" folder by reading its data.
    private func copyTempFileToSelectedFiles(from originalURL: URL) async throws -> (url: URL, filename: String) {
        try createSelectedFilesDirectoryIfNeeded()

        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let fileExtension = originalURL.pathExtension
        let uuidString = UUID().uuidString
        let newFilename = fileExtension.isEmpty ? "\(baseName)_\(uuidString)" : "\(baseName)_\(uuidString).\(fileExtension)"
        let destinationURL = selectedFilesDirectory.appendingPathComponent(newFilename)

        let fileData = try Data(contentsOf: originalURL)
        try fileData.write(to: destinationURL)
        
        return (destinationURL, newFilename)
    }

    /// Copies a file from the given URL into the "selected-files" folder using a streaming approach for large files.
    /// This method reads and writes data in chunks to avoid loading the entire file into memory.
    private func streamCopyFileToSelectedFiles(from originalURL: URL) async throws -> (url: URL, filename: String) {
        try createSelectedFilesDirectoryIfNeeded()
        
        let baseName = originalURL.deletingPathExtension().lastPathComponent
        let fileExtension = originalURL.pathExtension
        let uuidString = UUID().uuidString
        let newFilename = fileExtension.isEmpty ? "\(baseName)_\(uuidString)" : "\(baseName)_\(uuidString).\(fileExtension)"
        let destinationURL = selectedFilesDirectory.appendingPathComponent(newFilename)
        
        fileManager.createFile(atPath: destinationURL.path, contents: nil, attributes: nil)
        
        let sourceHandle = try FileHandle(forReadingFrom: originalURL)
        let destinationHandle = try FileHandle(forWritingTo: destinationURL)
        let bufferSize = 64 * 1024
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                while true {
                    let data = sourceHandle.readData(ofLength: bufferSize)
                    if data.isEmpty {
                        break
                    }
                    destinationHandle.write(data)
                }
                sourceHandle.closeFile()
                destinationHandle.closeFile()
                continuation.resume(returning: ())
            }
        }
        
        return (destinationURL, newFilename)
    }
}
