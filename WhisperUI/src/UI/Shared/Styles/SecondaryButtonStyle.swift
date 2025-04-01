//
//  SecondaryButtonStyle.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(
                Color.gray.opacity(0.5)
                    .brightness(configuration.isPressed ? -0.1 : 0)
            )
            .cornerRadius(8)
    }
}
