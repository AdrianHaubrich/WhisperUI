//
//  DownloadModelView.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import SwiftUI

enum DownloadState {
    case notStarted
    case downloading
    case finished
    case cancelled
}

struct DownloadModelView: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    @State var downloadProgress: Progress?
    @State private var selectedModel: WhisperModelType = .largeV3
    
    var body: some View {
        Group {
            VStack {
                ModelPicker($selectedModel)
                
                if !isModelAlreadyDownloaded(selectedModel) &&
                    determineDownloadState(for: downloadProgress) == .notStarted {
                    Button("Download model") {
                        Task {
                            await self.transcriptViewModel.download(model: .largeV3) { progress in
                                self.downloadProgress = progress
                            }
                        }
                    }.buttonStyle(PrimaryButtonStyle())
                } else if isModelAlreadyDownloaded(selectedModel) {
                    Button("Delete model") {
                        Task {
                            await self.transcriptViewModel.delete(model: .largeV3)
                        }
                    }
                }
            }
            
            if determineDownloadState(for: downloadProgress) == .downloading {
                HStack {
                    Text("Downloading")
                    ProgressView("Download progress:", value: downloadProgress?.fractionCompleted)
                }
            }
        }
    }
    
    func determineDownloadState(for progress: Progress?) -> DownloadState {
        if progress == nil {
            return .notStarted
        }
        
        if let progress {
            if progress.isFinished {
                return .finished
            } else if progress.isCancelled {
                return .cancelled
            }
        }
        
        return .downloading
    }
    
    func isModelAlreadyDownloaded(_ model: WhisperModelType) -> Bool {
        let isAvailable = try? WhisperKitWrapper.isModelAvailableLocally(model)
        return isAvailable ?? false
    }
}




