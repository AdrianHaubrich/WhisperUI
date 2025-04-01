//
//  AttributedTextEditor.swift
//  WhisperUI
//
//  Created by Adrian Haubrich on 10.03.25.
//

import SwiftUI

// Update AttributedTextEditor for iOS to accept an optional onFocus closure.
#if os(iOS)
import UIKit

// Updated custom UITextView that recalculates intrinsic content size
// and triggers onFocus when it becomes first responder.
class IntrinsicTextView: UITextView {
    // Closure to call when the text view gains focus.
    var onFocus: (() -> Void)?
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            onFocus?()
        }
        return result
    }
    
    override var intrinsicContentSize: CGSize {
        // Calculate height based on content.
        let size = self.sizeThatFits(CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }
}

struct AttributedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var attributedText: NSAttributedString
    var onFocus: (() -> Void)? = nil

    func makeUIView(context: Context) -> IntrinsicTextView {
        let textView = IntrinsicTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        // Set the onFocus closure on the text view.
        textView.onFocus = onFocus
        return textView
    }

    func updateUIView(_ uiView: IntrinsicTextView, context: Context) {
        let selectedRange = uiView.selectedRange
        uiView.attributedText = attributedText
        uiView.selectedRange = selectedRange
        uiView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocus: onFocus)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var onFocus: (() -> Void)?
        init(text: Binding<String>, onFocus: (() -> Void)?) {
            self.text = text
            self.onFocus = onFocus
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // This may be redundant if becomeFirstResponder is used,
            // but can be kept if desired.
            onFocus?()
        }
    }
}
#elseif os(macOS)
import AppKit

// Custom NSTextView subclass that overrides intrinsicContentSize
class IntrinsicNSTextView: NSTextView {
    // Closure to call when the text view gains focus.
    var onFocus: (() -> Void)?
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            onFocus?()
        }
        return result
    }
    
    override var intrinsicContentSize: NSSize {
        guard let textContainer = self.textContainer,
              let layoutManager = self.layoutManager else { return super.intrinsicContentSize }
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        // Add a small padding to the height if needed.
        return NSSize(width: NSView.noIntrinsicMetric, height: usedRect.height + 10)
    }
}

struct AttributedTextEditor: NSViewRepresentable {
    typealias NSViewType = IntrinsicNSTextView

    @Binding var text: String
    var attributedText: NSAttributedString
    var onFocus: (() -> Void)? = nil

    func makeNSView(context: Context) -> IntrinsicNSTextView {
        let textView = IntrinsicNSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.font = NSFont.systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        
        // Disable horizontal resizing to force full width usage.
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        
        // Configure the text container to use the text view's width.
        textView.textContainer?.containerSize = NSSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // Set the initial attributed text.
        textView.textStorage?.setAttributedString(attributedText)
        // Set the onFocus closure.
        textView.onFocus = onFocus
        return textView
    }

    @MainActor
    func updateNSView(_ nsView: IntrinsicNSTextView, context: Context) {
        let selectedRange = nsView.selectedRange()
        nsView.textStorage?.setAttributedString(attributedText)
        nsView.setSelectedRange(selectedRange)
        nsView.textContainer?.containerSize = NSSize(width: nsView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        nsView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocus: onFocus)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onFocus: (() -> Void)?
        init(text: Binding<String>, onFocus: (() -> Void)?) {
            self.text = text
            self.onFocus = onFocus
        }
        
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                text.wrappedValue = textView.string
            }
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            onFocus?()
        }
    }
}
#endif
