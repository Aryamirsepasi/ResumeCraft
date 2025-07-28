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
                            Label("Close", systemImage: "xmark")
                        }
                        .accessibilityLabel("Close Preview")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Button {
                                exportPDF()
                            } label: {
                                Label("Export PDF", systemImage: "square.and.arrow.up")
                            }
                            .accessibilityLabel("Export Resume as PDF")
                        }
                    }
                }
                .sheet(isPresented: $showShareSheet, onDismiss: { pdfURL = nil }) {
                    if let pdfURL {
                        ShareSheet(item: pdfURL)
                    }
                }
                .alert("Resume Too Long", isPresented: $showTooLongAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Resumes should not be more than two pages.")
                }
        }
    }

    private func exportPDF() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let pdf = try PDFExportService.export(
                    resume: resume
                )
                DispatchQueue.main.async {
                    pdfURL = pdf
                    showShareSheet = true
                    isExporting = false
                }
            } catch PDFExportError.resumeTooLong {
                DispatchQueue.main.async {
                    showTooLongAlert = true
                    isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
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
