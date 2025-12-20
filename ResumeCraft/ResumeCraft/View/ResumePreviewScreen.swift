//
//  ResumePreviewScreen.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ResumePreviewScreen: View {
    let resume: Resume
    @Environment(\.dismiss) private var dismiss

    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var showExportOptions = false
    @State private var isExporting = false
    @State private var showTooLongAlert = false

    var body: some View {
        NavigationStack {
            ResumePreviewView(resume: resume)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Label("Schließen", systemImage: "xmark")
                        }
                        .accessibilityLabel("Vorschau schließen")
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
                        .accessibilityLabel("Lebenslauf exportieren")
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
                    Text("Lebensläufe sollten nicht länger als zwei Seiten sein.")
                }
        }
    }

    private func exportPDF() {
        isExporting = true
        // Capture resume on the main actor before entering detached task
        let resumeToExport = resume
        Task.detached(priority: .userInitiated) {
            do {
                let pdf = try PDFExportService.export(resume: resumeToExport, fileName: "Lebenslauf.pdf")
                await MainActor.run {
                    pdfURL = pdf
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
