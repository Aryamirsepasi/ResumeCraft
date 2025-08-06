//
//  AIReviewSheet.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import MarkdownUI

struct AIReviewSheet: View {
  @Environment(AIReviewViewModel.self) private var viewModel
  var sectionOptions: [String]
  var sectionTextProvider: (String) -> String
  @State private var selectedSection: String = ""
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
            .frame(height: 80, alignment: .topLeading)
            .lineLimit(5)
            .padding(4)
        }
        Section("Job Description") {
          ScrollView {
            TextEditor(text: Binding(
              get: { viewModel.jobDescription },
              set: { viewModel.jobDescription = $0 }
            ))
            .frame(height: 120)
            .accessibilityLabel("Paste job description here")
            .background(Color.clear)
            .scrollContentBackground(.hidden)
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
            .frame(minHeight: 120)
          }
        } else if let error = viewModel.errorMessage {
          Text("Error: \(error)").foregroundColor(.red)
        }
      }
      .navigationTitle("Resume Feedback")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Analyze") {
            let text = sectionTextProvider(selectedSection)
            viewModel.resumeSection = text
            Task { await viewModel.requestFeedback() }
          }
          .disabled(selectedSection.isEmpty || viewModel.jobDescription.isEmpty)
        }
      }
      .onAppear { selectedSection = sectionOptions.first ?? "" }
    }
  }
}

struct AIReviewTabView: View {
  @Environment(ResumeEditorModel.self) private var resumeModel
  var sectionOptions: [String]
  var sectionTextProvider: (String) -> String

  var body: some View {
    NavigationStack {
      AIReviewSheet(
        sectionOptions: sectionOptions,
        sectionTextProvider: sectionTextProvider
      )
    }
  }
}
