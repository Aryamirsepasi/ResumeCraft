//
//  ResumePreviewView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import UIKit

struct ResumePreviewView: View {
    let resume: Resume
    let language: ResumeLanguage

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.vertical, .horizontal]) {
                // Center the scaled paper in the scroll view
                HStack {
                    Spacer(minLength: 0)
                    A4PaperView {
                        ResumeA4PreviewView(resume: resume, language: language)
                            .frame(width: 595, height: 842)
                    }
                    .scaleEffect(0.85)
                    .frame(
                        width: 595 * 0.85,
                        height: 842 * 0.85,
                        alignment: .center
                    )
                    Spacer(minLength: 0)
                }
                .frame(
                    minWidth: geometry.size.width,
                    minHeight: geometry.size.height,
                    alignment: .center
                )
            }
            .background(Color(.systemGray6))
        }
        .navigationTitle("Lebenslauf-Vorschau")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Lebenslauf-Vorschau (Papier)")
    }
}

struct ResumeA4PreviewView: UIViewRepresentable {
    let resume: Resume
    let language: ResumeLanguage

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32) // Add padding
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .horizontal)
        textView.accessibilityLabel = "Lebenslauf-Vorschau"
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let pageWidth: CGFloat = 595
        uiView.attributedText = ResumePDFFormatter.attributedString(
            for: resume,
            pageWidth: pageWidth,
            language: language
        )
    }
}
