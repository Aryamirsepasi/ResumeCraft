//
//  AIReviewSheet.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import MarkdownUI

struct AIReviewSheet: View {
    @Bindable var viewModel: AIReviewViewModel
    var sectionOptions: [String]
    var sectionTextProvider: (String) -> String

    @State private var selectedSection: String = ""
    @State private var showJobDescriptionField = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose Resume Section") {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(sectionOptions, id: \.self) { section in
                            Text(section).tag(section)
                        }
                    }
                }
                Section("Section Preview") {
                    Text(sectionTextProvider(selectedSection))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: 80, alignment: .topLeading)
                        .lineLimit(4)
                        .padding(4)
                }
                Section("Job Description") {
                    ScrollView {
                        TextEditor(text: $viewModel.jobDescription)
                            .frame(height: 100)
                            .accessibilityLabel("Paste job description here")
                    }
                }
                if viewModel.isGenerating {
                    ProgressView("Analyzing...")
                        .frame(maxWidth: .infinity)
                } else if let feedback = viewModel.feedback {
                    Section("AI Feedback") {
                        ScrollView {
                            Markdown(feedback)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding(4)
                        }
                        .frame(minHeight: 80)
                    }
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)").foregroundColor(.red)
                }
            }
            .navigationTitle("Resume Feedback")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Analyze") {
                        viewModel.resumeSection = sectionTextProvider(selectedSection)
                        Task { await viewModel.requestFeedback() }
                    }
                    .disabled(selectedSection.isEmpty || viewModel.jobDescription.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityLabel("Close Sheet")
                }
            }
            .onAppear {
                selectedSection = sectionOptions.first ?? ""
            }
        }
    }
}
