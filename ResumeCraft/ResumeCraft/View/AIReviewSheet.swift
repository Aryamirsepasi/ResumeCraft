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
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingInfoSheet = false
    @State private var animateGradient = false
    
    // Focus tags that can be toggled
    @State private var selectedFocusTags: Set<String> = []
    private let availableFocusTags = [
        "Impact & Metrics",
        "Clarity & Concision", 
        "ATS Optimization",
        "Action Verbs",
        "Keywords",
        "Professional Tone",
        "Formatting",
        "Overall Flow"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Section with Context
                    heroSection
                    
                    // Resume Overview
                    resumeOverviewSection
                    
                    // Job Description Input
                    jobDescriptionSection
                    
                    // Focus Areas
                    focusAreasSection
                    
                    // Action Button
                    analyzeButton
                    
                    // Results Display
                    resultsSection
                }
                .padding()
            }
            .navigationTitle("AI Resume Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingInfoSheet) { infoSheet }
            .onAppear { 
                startGradientAnimation()
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.isGenerating)
        }
    }

    // MARK: - Hero Section
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Animated gradient background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: animateGradient 
                            ? [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]
                            : [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse)
                        
                        VStack(spacing: 8) {
                            Text("Full Resume Review")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text("Get comprehensive AI feedback on your entire resume")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Privacy badge
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .font(.footnote)
                            Text("On-device processing • Your data stays private")
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .padding(24)
                }
                .frame(height: 200)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
        }
    }
    
    // MARK: - Resume Overview Section
    
    @ViewBuilder
    private var resumeOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Resume Overview", systemImage: "doc.text")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "briefcase.fill",
                    title: "Experience",
                    value: "\((resumeModel.resume.experiences ?? []).filter(\.isVisible).count)"
                )
                
                StatCard(
                    icon: "graduationcap.fill",
                    title: "Education",
                    value: "\((resumeModel.resume.educations ?? []).filter(\.isVisible).count)"
                )
                
                StatCard(
                    icon: "star.fill",
                    title: "Skills",
                    value: "\((resumeModel.resume.skills ?? []).filter(\.isVisible).count)"
                )
            }
            
            // Character count
            let resumeText = ResumeTextFormatter.plainText(for: resumeModel.resume)
            Text("\(resumeText.count) characters • ~\(resumeText.split(separator: " ").count) words")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
    }
    
    // MARK: - Job Description Section
    
    @ViewBuilder
    private var jobDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Job Description", systemImage: "briefcase.fill")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.jobDescription.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.footnote)
                }
            }
            
            Text("Paste the job posting for tailored suggestions")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: Binding(
                get: { viewModel.jobDescription },
                set: { viewModel.jobDescription = $0 }
            ))
            .scrollContentBackground(.hidden)
            .padding(8)
            .frame(minHeight: 120, maxHeight: 200)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .topLeading) {
                if viewModel.jobDescription.isEmpty {
                    Text("Paste job description here...")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 16)
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
    }
    
    // MARK: - Focus Areas Section
    
    @ViewBuilder
    private var focusAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Focus Areas (Optional)", systemImage: "target")
                .font(.headline)
            
            Text("Select specific areas for deeper analysis")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(availableFocusTags, id: \.self) { tag in
                    FocusTagChip(
                        title: tag,
                        isSelected: selectedFocusTags.contains(tag),
                        action: {
                            if selectedFocusTags.contains(tag) {
                                selectedFocusTags.remove(tag)
                                viewModel.removeFocus(tag)
                            } else {
                                selectedFocusTags.insert(tag)
                                viewModel.appendFocus(tag)
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
    }
    
    // MARK: - Analyze Button
    
    @ViewBuilder
    private var analyzeButton: some View {
        Button(action: performAnalysis) {
            HStack(spacing: 12) {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                        .symbolEffect(.bounce, value: viewModel.isGenerating)
                }
                
                Text(viewModel.isGenerating ? "Analyzing Resume..." : "Generate AI Review")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .blue.opacity(0.3), radius: 10, y: 4)
        }
        .disabled(isAnalysisDisabled)
        .opacity(isAnalysisDisabled ? 0.6 : 1)
    }
    
    // MARK: - Results Section
    
    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.isGenerating {
            generatingView
        } else if let feedback = viewModel.feedback {
            feedbackView(feedback)
        } else if let error = viewModel.errorMessage {
            errorView(error)
        }
    }
    
    @ViewBuilder
    private var generatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing your entire resume...")
                .font(.headline)
            
            Text("This comprehensive review may take a moment")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .transition(.scale.combined(with: .opacity))
    }
    
    @ViewBuilder
    private func feedbackView(_ feedback: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("AI Suggestions", systemImage: "sparkles")
                    .font(.headline)
                
                Spacer()
                
                Button(action: copyFeedback) {
                    Image(systemName: "doc.on.doc")
                        .font(.footnote)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Divider()
            
            ScrollView {
                Markdown(feedback)
                    .markdownTextStyle {
                        ForegroundColor(.primary)
                        FontSize(14)
                    }
                    .markdownBlockStyle(\.heading1) { configuration in
                        configuration.label
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.vertical, 4)
                    }
                    .markdownBlockStyle(\.heading2) { configuration in
                        configuration.label
                            .font(.headline)
                            .padding(.vertical, 2)
                    }
                    .markdownBlockStyle(\.listItem) { configuration in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            configuration.label
                        }
                        .padding(.vertical, 2)
                    }
            }
            .frame(maxHeight: 400)
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 1.05).combined(with: .opacity)
        ))
    }
    
    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text("Unable to Generate Review")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.errorMessage = nil
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") { dismiss() }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
            }
        }
    }
    
    // MARK: - Info Sheet
    
    @ViewBuilder
    private var infoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("How it Works", systemImage: "sparkles")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("This AI-powered review analyzes your complete resume and provides comprehensive feedback tailored to your target job.")
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Privacy First", systemImage: "lock.shield.fill")
                            .font(.headline)
                        
                        Text("All processing happens on your device. Your resume data never leaves your iPhone and is not sent to any external servers.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Best Practices", systemImage: "lightbulb.fill")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Include the full job description for best results")
                            bulletPoint("Select focus areas for targeted analysis")
                            bulletPoint("Apply suggestions that align with your experience")
                            bulletPoint("Keep your resume to 1-2 pages maximum")
                            bulletPoint("Update based on feedback iteratively")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Understanding the Feedback", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        
                        Text("The AI provides suggestions, not requirements. Use your judgment to determine which recommendations best fit your unique situation and career goals.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("About AI Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingInfoSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startGradientAnimation() {
        withAnimation {
            animateGradient = true
        }
    }
    
    private func performAnalysis() {
        let resumeText = ResumeTextFormatter.plainText(for: resumeModel.resume)
        Task { 
            await viewModel.requestFeedback(resumeText: resumeText)
        }
    }
    
    private func copyFeedback() {
        if let feedback = viewModel.feedback {
            UIPasteboard.general.string = feedback
        }
    }
    
    private var isAnalysisDisabled: Bool {
        viewModel.jobDescription.isEmpty || 
        viewModel.isGenerating
    }
    
    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FocusTagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.accentColor.opacity(0.15))
                    : AnyShapeStyle(Color(UIColor.tertiarySystemBackground))
            )
            .foregroundColor(isSelected ? .accentColor : .primary)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color(UIColor.separator),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Tab View Wrapper

struct AIReviewTabView: View {
    var body: some View {
        NavigationStack {
            AIReviewSheet()
        }
    }
}
