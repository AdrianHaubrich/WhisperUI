//
//  HomePage.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import SwiftUI

struct HomePage: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    
    var body: some View {
        @Bindable var transcriptViewModel = transcriptViewModel
        
        NavigationSplitView {
            HomeSidebar()
        } detail: {
            HomeDetail()
        }
        .inspector(isPresented: $transcriptViewModel.isInspectorPresented) {
            Divider()
            ScrollView {
                SegmentInspector()
            }
            .toolbar {
                Spacer()
                Button("", systemImage: "sidebar.right") {
                    transcriptViewModel.isInspectorPresented.toggle()
                }
            }
        }
    }
}
