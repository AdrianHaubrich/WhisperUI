//
//  SpeakerSelectionPicker.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct SpeakerSelectionPicker: View {
    let speaker: Speaker
    let onSpeakerChange: (Speaker) -> ()
    
    var body: some View {
        Picker("", selection: bindSpeaker()) {
            Label("Interviewer", systemImage: "person")
                .labelStyle(.titleAndIcon)
                .tag(Speaker(name: "Interviewer"))
            Label("Interviewee", systemImage: "person")
                .labelStyle(.titleAndIcon)
                .tag(Speaker(name: "Interviewee"))
        }
        .pickerStyle(.automatic)
    }
    
    func bindSpeaker() -> Binding<Speaker> {
        return Binding {
            speaker
        } set: { newSpeaker in
            onSpeakerChange(newSpeaker)
        }

    }
}
