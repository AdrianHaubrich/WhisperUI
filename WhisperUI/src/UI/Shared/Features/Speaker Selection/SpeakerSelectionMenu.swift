//
//  SpeakerSelectionMenu.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct SpeakerSelectionMenu: View {
    let onSpeakerChange: (Speaker) -> ()
    
    var body: some View {
        Menu {
            Button {
                onSpeakerChange(Speaker(name: "Interviewer"))
            } label: {
                Label("Interviewer", systemImage: "person")
            }
            Button {
                onSpeakerChange(Speaker(name: "Interviewee"))
            } label: {
                Label("Interviewee", systemImage: "person")
            }
        } label: {
            Image(systemName: "person.circle")
                .resizable()
                .frame(width: 20, height: 20)
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
        }.buttonStyle(ImageMenuButtonStyle())
    }
}
