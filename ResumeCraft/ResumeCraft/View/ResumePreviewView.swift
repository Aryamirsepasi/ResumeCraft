//
//  ResumePreviewView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import PDFKit

/// Displays the resume as a real PDF using PDFKit so the preview
/// matches the exported PDF exactly (WYSIWYG).
struct ResumePreviewView: View {
    let resume: Resume
    let language: ResumeLanguage

    var body: some View {
        ResumePDFPreview(resume: resume, language: language)
            .background(Color(.systemGray6))
            .navigationTitle("Lebenslauf-Vorschau")
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Lebenslauf-Vorschau (Papier)"))
    }
}

/// UIViewRepresentable wrapping PDFKit's PDFView.
/// Generates an in-memory PDF using the same pipeline as export,
/// then displays it — ensuring pixel-perfect preview-export parity.
struct ResumePDFPreview: UIViewRepresentable {
    let resume: Resume
    let language: ResumeLanguage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.backgroundColor = .systemGray6
        pdfView.pageShadowsEnabled = true
        pdfView.accessibilityLabel = String(localized: "Lebenslauf-Vorschau (Papier)")
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        let signature = PreviewSignature(updated: resume.updated, language: language)
        guard context.coordinator.lastSignature != signature else { return }
        context.coordinator.lastSignature = signature

        let options = ExportOptions(pageSize: .a4, margins: .standard, outputLanguage: language)
        let attributedString = ResumePDFFormatter.attributedString(
            for: resume,
            pageWidth: options.pageSize.size.width,
            language: language
        )
        if let data = try? PDFExportService.pdfData(from: attributedString, options: options),
           let document = PDFDocument(data: data) {
            pdfView.document = document
        }
    }

    final class Coordinator {
        var lastSignature: PreviewSignature?
    }

    struct PreviewSignature: Equatable {
        let updated: Date
        let language: ResumeLanguage
    }
}
