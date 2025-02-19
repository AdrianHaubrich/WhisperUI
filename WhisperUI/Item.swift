//
//  Item.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 19.02.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
