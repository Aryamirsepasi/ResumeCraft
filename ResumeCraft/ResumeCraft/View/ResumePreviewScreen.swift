//
//  ResumePreviewScreen.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ResumePreviewScreen: View {
    let resume: Resume
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Environment(\.dismiss) private var dismiss

    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var showExportOptions = false
    @State private var isExporting = false
    @State private var showTooLongAlert = false
    @State private var outputLanguage: ResumeLanguage = .defaultOutput

    var body: some View {
        NavigationStack {
            ResumePreviewView(resume: resume, language: outputLanguage)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Schließen", systemImage: "xmark")
                        }
                        .accessibilityLabel(Text("Vorschau schließen"))
                    }
                    ToolbarItem(placement: .principal) {
                        ResumeLanguagePicker(
                            titleKey: "Ausgabesprache",
                            selection: $outputLanguage
                        )
                        .frame(maxWidth: 240)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                exportPDF()
                            } label: {
                                Label("Schnell-Export PDF", systemImage: "doc.fill")
                            }

                            Button {
                                showExportOptions = true
                            } label: {
                                Label("Exportoptionen...", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            if isExporting {
                                ProgressView()
                            } else {
                                Label("Exportieren", systemImage: "square.and.arrow.up")
                            }
                        }
                        .accessibilityLabel(Text("Lebenslauf exportieren"))
                    }
                }
                .sheet(isPresented: $showShareSheet, onDismiss: { pdfURL = nil }) {
                    if let pdfURL {
                        ShareSheet(item: pdfURL)
                    }
                }
                .sheet(isPresented: $showExportOptions) {
                    ExportOptionsView(resume: resume)
                }
                .alert("Lebenslauf zu lang", isPresented: $showTooLongAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(PDFExportError.resumeTooLong.localizedDescription)
                }
        }
        .onAppear {
            outputLanguage = resume.outputLanguage
        }
        .onChange(of: outputLanguage) { _, newValue in
            resume.outputLanguage = newValue
            try? resumeModel.save()
        }
    }

    private func exportPDF() {
        isExporting = true
        let language = outputLanguage

        // Build export options and attributed string on the main actor
        // (SwiftData @Model objects are not Sendable)
        var options = ExportOptions()
        options.outputLanguage = language
        options.fileName = language == .english ? "Resume" : "Lebenslauf"
        let attributedString = ResumePDFFormatter.attributedString(
            for: resume,
            pageWidth: options.pageSize.size.width,
            language: language
        )

        Task.detached(priority: .userInitiated) {
            do {
                let result = try PDFExportService.exportPDFFromAttributedString(
                    attributedString,
                    options: options
                )
                await MainActor.run {
                    pdfURL = result.url
                    showShareSheet = true
                    isExporting = false
                }
            } catch PDFExportError.resumeTooLong {
                await MainActor.run {
                    showTooLongAlert = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                }
            }
        }
    }
}


// ShareSheet wrapper for UIKit's UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    let item: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: [item],
            applicationActivities: nil
        )
        controller.excludedActivityTypes = [.assignToContact]
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
