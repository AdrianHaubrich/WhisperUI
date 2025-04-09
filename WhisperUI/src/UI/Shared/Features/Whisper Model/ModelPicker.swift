//
//  ModelPicker.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import SwiftUI

struct ModelPicker: View {
    @Binding var selectedModel: WhisperModelType
    @State var downloadedModels: Set<WhisperModelType> = []
    let TranscriptionModelService = WhisperKitModelService.self
    
    init(_ selectedModel: Binding<WhisperModelType>) {
        self._selectedModel = selectedModel
    }
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedModel) {
                ForEach(WhisperModelType.allCases, id: \.rawValue) { model in
                    Label(model.rawValue, systemImage: isDownloaded(model) ? "arrow.down.circle" : "circle.dotted")
                        .labelStyle(.titleAndIcon)
                        .tag(model)
                }
            }.pickerStyle(.automatic)
        }.task {
            if let models = try? await TranscriptionModelService.getDownloadedModels() {
                self.downloadedModels = models
            }
        }
    }
    
    func isDownloaded(_ model: WhisperModelType) -> Bool {
        return downloadedModels.contains(model)
    }
}
