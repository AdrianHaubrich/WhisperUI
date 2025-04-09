//
//  PrimaryButtonStyle.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 08.03.25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(
                Color.accentColor
                    .brightness(configuration.isPressed ? -0.1 : 0)
            )
            .cornerRadius(8)
    }
}

struct SmallPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundColor(.white)
            .background(
                Color.accentColor
                    .brightness(configuration.isPressed ? -0.1 : 0)
            )
            .cornerRadius(8)
    }
}
