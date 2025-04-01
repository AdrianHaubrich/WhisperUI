//
//  TranscriptEditor.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

struct TranscriptEditor: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        LazyVStack {
            ForEach(transcriptViewModel.transcript.segments) { segment in
                TranscriptSegmentEditorView(segment: segment)
                Divider()
            }
        }
    }
}

struct TranscriptSegmentEditorView: View {
    @Environment(TranscriptViewModel.self) var transcriptViewModel
    let segmentId: String
    
    @State private var shouldSkipNextModelUpdate: Bool = false
    @State private var debounceTimer: Timer?
    @State private var baseline: String = ""
    @State private var text: String = ""
    
    var segment: TranscriptSegment? {
        transcriptViewModel.transcript.segments.first { $0.id == self.segmentId }
    }
    
    var diffAttributedText: NSAttributedString {
        return generateDiffAttributedText(currentText: self.text)
    }
    
    init(segment: TranscriptSegment) {
        self.segmentId = segment.id
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    SpeakerSelectionMenu(onSpeakerChange: { speaker in
                        guard let segment else { return }
                        transcriptViewModel.update(speaker: speaker, for: segment)
                    })
                    Text(segment?.speaker?.name ?? "unknown")
                        .font(.headline)
                    
                    Text("\(FormatterService.formatTime(segment?.start ?? 0)) - \(FormatterService.formatTime(segment?.end ?? 0))")
                        .font(.headline)
                        .foregroundStyle(Color.gray)
                }
                
                AttributedTextEditor(text: $text, attributedText: diffAttributedText, onFocus: {
                    DispatchQueue.main.async {
                        self.transcriptViewModel.selectedSegmentId = segmentId
                        self.transcriptViewModel.currentTime = TimeInterval(segment?.start ?? 0)
                    }
                })
                .frame(minHeight: 30)
                .padding(4)
            }
        }
        .padding(.top, 8)
        .onAppear {
            if text.isEmpty {
                self.shouldSkipNextModelUpdate = true
                text = segment?.text ?? ""
                baseline = segment?.text ?? ""
            }
        }
        .onChange(of: text) { _, newValue in
            if shouldSkipNextModelUpdate == true {
                // If we sync changes back from the model to $text, then we need to ensure that there is no update triggered. Otherwise it would produce a new update command which clears the redo stack.
                self.shouldSkipNextModelUpdate = false
                return
            }
            
            debounceTimer?.invalidate()
            
            // Sync changes back to model 0.5s after last change
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                guard let segment = segment else { return }
                transcriptViewModel.update(text: newValue, for: segment)
            }
        }
        .onChange(of: self.segment?.text) { oldValue, newValue in
            if self.text != newValue {
                self.shouldSkipNextModelUpdate = true
                self.text = newValue ?? ""
            }
        }
    }
    
    // TODO: Move to ViewModel
    /// Computes an attributed string that visually represents the differences between the current segment text and its baseline.
    ///
    /// This function performs a word-level diff using the Longest Common Subsequence (LCS) algorithm:
    /// 1. It splits both the `baseline` (original text) and the `current` text (from the segment) into arrays of words.
    /// 2. It builds a DP (dynamic programming) matrix to compute the LCS, which identifies the longest sequence of words that appears in both texts in the same order.
    /// 3. By backtracking through the DP matrix, it determines which words in the current text are unchanged (i.e. part of the LCS).
    /// 4. Finally, it constructs an attributed string where each word is colored.
    func generateDiffAttributedText(currentText: String) -> NSAttributedString {
        #if os(iOS)
        let defaultColor = UIColor.label
        let diffColor = UIColor.systemGreen
        #elseif os(macOS)
        let defaultColor = NSColor.labelColor
        let diffColor = NSColor.systemGreen
        #endif

        let result = NSMutableAttributedString()

        // Split baseline and current texts into words
        let baselineWords = baseline.components(separatedBy: " ")
        let currentWords = currentText.components(separatedBy: " ")

        let m = baselineWords.count
        let n = currentWords.count

        // Compute LCS matrix
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0..<m {
            for j in 0..<n {
                if baselineWords[i] == currentWords[j] {
                    dp[i + 1][j + 1] = dp[i][j] + 1
                } else {
                    dp[i + 1][j + 1] = max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        // Backtrack to determine which words are unchanged
        var unchangedIndices = Set<Int>()
        var i = m, j = n
        while i > 0 && j > 0 {
            if baselineWords[i - 1] == currentWords[j - 1] {
                unchangedIndices.insert(j - 1)
                i -= 1
                j -= 1
            } else if dp[i - 1][j] >= dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }

        // Build the attributed string with word-by-word colors
        for index in 0..<currentWords.count {
            let word = currentWords[index]
            let color = unchangedIndices.contains(index) ? defaultColor : diffColor
            result.append(NSAttributedString(string: word, attributes: [.foregroundColor: color]))
            // Append a space after each word except the last one
            if index < currentWords.count - 1 {
                result.append(NSAttributedString(string: " ", attributes: [.foregroundColor: color]))
            }
        }

        return result
    }
}
