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
        "Wirkung & Kennzahlen",
        "Klarheit & Prägnanz",
        "ATS-Optimierung",
        "Aktionsverben",
        "Schlüsselwörter",
        "Professioneller Ton",
        "Formatierung",
        "Gesamteindruck"
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
            .navigationTitle("KI-Lebenslaufprüfung")
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
                            Text("Komplette Lebenslaufprüfung")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text("Erhalte umfassendes KI-Feedback zu deinem gesamten Lebenslauf")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Privacy badge
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .font(.footnote)
                            Text("On-Device-Verarbeitung • Deine Daten bleiben privat")
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
            Label("Lebenslauf-Übersicht", systemImage: "doc.text")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatCard(
                    icon: "briefcase.fill",
                    title: "Berufserfahrung",
                    value: "\((resumeModel.resume.experiences ?? []).filter(\.isVisible).count)"
                )
                
                StatCard(
                    icon: "graduationcap.fill",
                    title: "Ausbildung",
                    value: "\((resumeModel.resume.educations ?? []).filter(\.isVisible).count)"
                )
                
                StatCard(
                    icon: "star.fill",
                    title: "Fähigkeiten",
                    value: "\((resumeModel.resume.skills ?? []).filter(\.isVisible).count)"
                )
            }
            
            // Character count
            let resumeText = ResumeTextFormatter.plainText(for: resumeModel.resume, language: resumeModel.resume.contentLanguage)
            Text("\(resumeText.count) Zeichen • ~\(resumeText.split(separator: " ").count) Wörter")
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
                Label("Stellenbeschreibung", systemImage: "briefcase.fill")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.jobDescription.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.footnote)
                }
            }
            
            Text("Füge die Stellenanzeige ein für gezielte Vorschläge")
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
                    Text("Stellenbeschreibung hier einfügen…")
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
            Label("Fokusbereiche (optional)", systemImage: "target")
                .font(.headline)
            
            Text("Wähle Bereiche für eine tiefere Analyse")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GlassEffectContainer(spacing: 4) {
                TagFlowLayout(hSpacing: 8, vSpacing: 8) {
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
                
                Text(viewModel.isGenerating ? "Lebenslauf wird analysiert..." : "KI-Review erstellen")
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
            
            Text("Dein gesamter Lebenslauf wird analysiert...")
                .font(.headline)
            
            Text("Diese umfassende Prüfung kann einen Moment dauern")
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
                Label("KI-Vorschläge", systemImage: "sparkles")
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
            
            Text("Review konnte nicht erstellt werden")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Erneut versuchen") {
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
            Button("Fertig") { dismiss() }
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
                        Label("So funktioniert es", systemImage: "sparkles")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Diese KI-gestützte Prüfung analysiert deinen gesamten Lebenslauf und liefert umfassendes Feedback zur Zielstelle.")
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Datenschutz zuerst", systemImage: "lock.shield.fill")
                            .font(.headline)
                        
                        Text("Die Verarbeitung erfolgt auf deinem Gerät. Deine Daten verlassen dein iPhone nicht und werden nicht an externe Server gesendet.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Empfehlungen", systemImage: "lightbulb.fill")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Füge die vollständige Stellenbeschreibung für beste Ergebnisse ein")
                            bulletPoint("Wähle Fokusbereiche für eine gezielte Analyse")
                            bulletPoint("Setze Vorschläge um, die zu deiner Erfahrung passen")
                            bulletPoint("Halte deinen Lebenslauf bei maximal 1–2 Seiten")
                            bulletPoint("Aktualisiere schrittweise basierend auf dem Feedback")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Feedback verstehen", systemImage: "doc.text.magnifyingglass")
                            .font(.headline)
                        
                        Text("Die KI liefert Vorschläge, keine Vorgaben. Nutze dein Urteil, welche Empfehlungen zu deiner Situation und deinen Zielen passen.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Über die KI-Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
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
        let resumeText = ResumeTextFormatter.plainText(for: resumeModel.resume, language: resumeModel.resume.contentLanguage)
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

private struct TagFlowLayout: Layout {
    var hSpacing: CGFloat
    var vSpacing: CGFloat

    init(hSpacing: CGFloat = 8, vSpacing: CGFloat = 8) {
        self.hSpacing = hSpacing
        self.vSpacing = vSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            // Wrap to next line if needed
            if x > 0 && x + size.width > maxWidth {
                x = 0
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + (x > 0 ? hSpacing : 0)
        }

        let finalHeight = y + rowHeight
        let finalWidth = maxWidth.isFinite ? maxWidth : x
        return CGSize(width: finalWidth, height: finalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxX = bounds.maxX
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > maxX {
                x = bounds.minX
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + hSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

private struct FocusTagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        let button = Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(minWidth: 140)
            .frame(height: 40)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        
        if #available(iOS 26, *) {
            button
                .glassEffect(
                    isSelected
                        ? .regular.tint(.accentColor).interactive()
                        : .regular.interactive(),
                    in: .capsule
                )
                .animation(.snappy, value: isSelected)
                .sensoryFeedback(.selection, trigger: isSelected)
        } else {
            button
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .animation(.snappy, value: isSelected)
                .sensoryFeedback(.selection, trigger: isSelected)
        }
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
