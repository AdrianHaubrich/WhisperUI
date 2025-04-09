//
//  HomePage.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 09.03.25.
//

import SwiftUI

struct HomePage: View {
    @Environment(InspectorViewModel.self) var inspectorViewModel
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
                VStack {
                    switch inspectorViewModel.currentInspector {
                    case .transcript:
                        TranscriptInspector()
                    case .transcriptSegment:
                        SegmentInspector()
                    case .none:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
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
