//
//  PlayActionButtonStyle.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 07.04.25.
//

import SwiftUI

struct PlayActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title)
            .padding(8)
            .background {
                if configuration.isPressed {
                    Circle().fill(Color.gray.opacity(0.5))
                }
            }
    }
}
