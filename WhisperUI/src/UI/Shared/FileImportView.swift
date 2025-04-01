//
//  FileImportView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileImportView: View {
    let onFilepathChanged: (_ path: URL) -> ()
    
    @State private var lastFilePath: URL?
    
    var body: some View {
        VStack {
            FileImportDropArea() { path in
                handleFileChange(newPath: path)
            }
        }
    }
    
    private func handleFileChange(newPath: URL) {
        if lastFilePath == nil || lastFilePath != newPath {
            lastFilePath = newPath
            onFilepathChanged(newPath)
        }
    }
}

struct FileImportDropArea: View {
    let onFilepathChanged: (_ path: URL) -> ()
    @State private var fileSystemService = FileSystemService()
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 60))
                    .padding(.bottom, 4)
                Text("Drop file here or")
                    .font(.body)
                    .bold()
                
                FileImportButton(title: "select file") { path in
                    onFilepathChanged(path)
                }
            }
            .frame(width: 300, height: 300)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray, lineWidth: 2)
            )
            .onDrop(of: GlobalConfig.supportedFileTypes, isTargeted: nil) { providers in
                handleDrop(providers: providers)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.audio.identifier) { url, isInPlace, error in
                    if let error = error {
                        print("Error loading file: \(error.localizedDescription)")
                        return
                    }
                    guard let url = url else {
                        print("No file URL found")
                        return
                    }
                    
                    Task {
                        do {
                            let destinationURL = try await fileSystemService.copyFile(from: url)
                            await self.onFilepathChanged(destinationURL)
                        } catch {
                            print("Error copying file: \(error.localizedDescription)")
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

struct FileImportButton: View {
    @State private var isPresented: Bool = false
    @State private var allowsMultipleSelection: Bool = false
    @State private var fileSystemService = FileSystemService()
    
    let title: String
    let onFilepathChanged: (_ path: URL) -> ()
    
    var body: some View {
        Button(title) {
            isPresented.toggle()
        }
        .buttonStyle(PrimaryButtonStyle())
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: GlobalConfig.supportedFileTypes,
            allowsMultipleSelection: allowsMultipleSelection) { result in
                Task {
                    do {
                        if let originalURL = try result.get().first {
                            // Use the actor to copy the file.
                            let destinationURL = try await fileSystemService.copyFile(from: originalURL)
                            // Return the new file URL via the callback.
                            onFilepathChanged(destinationURL)
                        }
                    } catch {
                        print("Error handling file import: \(error.localizedDescription)")
                    }
                }
            }
    }
}
