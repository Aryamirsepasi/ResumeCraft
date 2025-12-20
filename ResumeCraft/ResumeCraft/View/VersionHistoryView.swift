//
//  VersionHistoryView.swift
//  ResumeCraft
//
//  Display and compare resume version history
//

import SwiftUI
import SwiftData

struct VersionHistoryView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Environment(\.modelContext) private var context
    
    @State private var history: ResumeHistory?
    @State private var selectedSnapshot: ResumeSnapshot?
    @State private var comparisonSnapshot: ResumeSnapshot?
    @State private var showComparison = false
    @State private var showSaveConfirmation = false
    
    var body: some View {
        Group {
            if let history = history, !history.snapshots.isEmpty {
                snapshotList(history.snapshots)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Versionsverlauf")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveSnapshot()
                } label: {
                    Label("Momentaufnahme speichern", systemImage: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showComparison) {
            if let selected = selectedSnapshot, let comparison = comparisonSnapshot {
                ComparisonSheet(
                    current: selected,
                    previous: comparison
                )
            }
        }
        .alert("Momentaufnahme gespeichert", isPresented: $showSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Dein aktueller Lebenslauf wurde im Versionsverlauf gespeichert.")
        }
        .task {
            await loadHistory()
        }
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Kein Versionsverlauf", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Speichere Momentaufnahmen deines Lebenslaufs, um Änderungen nachzuverfolgen.")
        } actions: {
            Button {
                saveSnapshot()
            } label: {
                Text("Aktuelle Version speichern")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Snapshot List
    
    @ViewBuilder
    private func snapshotList(_ snapshots: [ResumeSnapshot]) -> some View {
        List {
            // Current state section
            Section {
                CurrentStateRow(resume: resumeModel.resume)
            } header: {
                Text("Aktuell")
            }
            
            // History section
            Section {
                ForEach(snapshots.reversed()) { snapshot in
                    SnapshotRow(
                        snapshot: snapshot,
                        isSelected: selectedSnapshot?.id == snapshot.id,
                        onSelect: {
                            selectedSnapshot = snapshot
                        },
                        onCompare: { previous in
                            selectedSnapshot = snapshot
                            comparisonSnapshot = previous
                            showComparison = true
                        },
                        previousSnapshot: findPreviousSnapshot(for: snapshot, in: snapshots)
                    )
                }
            } header: {
                HStack {
                    Text("Vorherige Versionen")
                    Spacer()
                    Text("\(snapshots.count)/20")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Es werden bis zu 20 Momentaufnahmen gespeichert. Ältere Versionen werden automatisch entfernt.")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func loadHistory() async {
        let resumeIdString = String(describing: resumeModel.resume.id)
        
        let descriptor = FetchDescriptor<ResumeHistory>(
            predicate: #Predicate { $0.resumeIdString == resumeIdString }
        )
        
        if let existing = try? context.fetch(descriptor).first {
            history = existing
        } else {
            // Create new history
            let newHistory = ResumeHistory(resumeIdString: resumeIdString)
            context.insert(newHistory)
            try? context.save()
            history = newHistory
        }
    }
    
    private func saveSnapshot() {
        let snapshot = ResumeSnapshot.capture(from: resumeModel.resume)
        let resumeIdString = String(describing: resumeModel.resume.id)
        
        if history == nil {
            let newHistory = ResumeHistory(resumeIdString: resumeIdString)
            context.insert(newHistory)
            history = newHistory
        }
        
        history?.addSnapshot(snapshot)
        try? context.save()
        showSaveConfirmation = true
    }
    
    private func findPreviousSnapshot(for snapshot: ResumeSnapshot, in snapshots: [ResumeSnapshot]) -> ResumeSnapshot? {
        guard let index = snapshots.firstIndex(where: { $0.id == snapshot.id }),
              index > 0 else { return nil }
        return snapshots[index - 1]
    }
}

// MARK: - Current State Row

private struct CurrentStateRow: View {
    let resume: Resume
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Aktuelle Version")
                    .font(.headline)
                
                Text("Zuletzt aktualisiert \(resume.updated, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Section counts
            VStack(alignment: .trailing, spacing: 2) {
                let counts = sectionCounts
                Text("\(counts.total) Einträge")
                    .font(.caption.weight(.semibold))
                
                Text("\(wordCount) Wörter")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var sectionCounts: (total: Int, experiences: Int, skills: Int) {
        let exp = (resume.experiences ?? []).filter(\.isVisible).count
        let skills = (resume.skills ?? []).filter(\.isVisible).count
        let projects = (resume.projects ?? []).filter(\.isVisible).count
        let edu = (resume.educations ?? []).filter(\.isVisible).count
        return (exp + skills + projects + edu, exp, skills)
    }
    
    private var wordCount: Int {
        let text = ResumeTextFormatter.plainText(for: resume)
        return text.split(separator: " ").count
    }
}

// MARK: - Snapshot Row

private struct SnapshotRow: View {
    let snapshot: ResumeSnapshot
    let isSelected: Bool
    let onSelect: () -> Void
    let onCompare: (ResumeSnapshot) -> Void
    let previousSnapshot: ResumeSnapshot?
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main row
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.indigo)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.date, style: .date)
                        .font(.subheadline.weight(.semibold))
                    
                    Text(snapshot.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalItems) Einträge")
                        .font(.caption.weight(.semibold))
                    
                    Text("\(snapshot.totalWordCount) Wörter")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                    onSelect()
                }
            }
            
            // Expanded details
            if isExpanded {
                expandedDetails
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section breakdown
            HStack(spacing: 16) {
                SectionCountBadge(
                    icon: "briefcase.fill",
                    count: snapshot.sectionsCount.experiences,
                    label: "Positionen",
                    color: .orange
                )
                SectionCountBadge(
                    icon: "star.fill",
                    count: snapshot.sectionsCount.skills,
                    label: "Fähigkeiten",
                    color: .yellow
                )
                SectionCountBadge(
                    icon: "hammer.fill",
                    count: snapshot.sectionsCount.projects,
                    label: "Projekte",
                    color: .green
                )
                SectionCountBadge(
                    icon: "graduationcap.fill",
                    count: snapshot.sectionsCount.educations,
                    label: "Ausbildung",
                    color: .blue
                )
            }
            
            // Summary preview
            if !snapshot.summarySnapshot.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zusammenfassung (Vorschau)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Text(snapshot.summarySnapshot)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Compare button
            if let previous = previousSnapshot {
                Button {
                    onCompare(previous)
                } label: {
                    Label("Mit vorheriger vergleichen", systemImage: "arrow.left.arrow.right")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.indigo)
            }
        }
        .padding(.leading, 60)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    private var totalItems: Int {
        snapshot.sectionsCount.experiences +
        snapshot.sectionsCount.skills +
        snapshot.sectionsCount.projects +
        snapshot.sectionsCount.educations
    }
}

// MARK: - Section Count Badge

private struct SectionCountBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.caption.bold())
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Comparison Sheet

private struct ComparisonSheet: View {
    let current: ResumeSnapshot
    let previous: ResumeSnapshot
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    comparisonHeader
                    
                    // Statistics
                    statisticsSection
                    
                    // Changes breakdown
                    changesSection
                    
                    // Suggestion
                    suggestionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Versionsvergleich")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }
    
    private var comparison: ResumeComparisonResult {
        current.compare(with: previous)
    }
    
    @ViewBuilder
    private var comparisonHeader: some View {
        HStack(spacing: 20) {
            // Previous
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
                
                Text("Vorherige")
                    .font(.caption.weight(.semibold))
                
                Text(previous.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Arrow
            Image(systemName: "arrow.right")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            // Current
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                }
                
                Text("Aktuelle")
                    .font(.caption.weight(.semibold))
                
                Text(current.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Änderungen")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatisticCard(
                    title: "Wortanzahl",
                    value: "\(abs(comparison.statistics.wordCountDelta))",
                    trend: comparison.statistics.wordCountDelta >= 0 ? .up : .down,
                    icon: "text.word.spacing"
                )
                
                StatisticCard(
                    title: "Abschnitte",
                    value: "\(abs(comparison.statistics.sectionsDelta))",
                    trend: comparison.statistics.sectionsDelta >= 0 ? .up : .down,
                    icon: "list.bullet"
                )
                
                StatisticCard(
                    title: "Tage Abstand",
                    value: "\(comparison.statistics.daysApart)",
                    trend: .neutral,
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Abschnittsübersicht")
                .font(.headline)
            
            // Experience
            ChangeRow(
                label: "Berufserfahrung",
                icon: "briefcase.fill",
                oldValue: previous.sectionsCount.experiences,
                newValue: current.sectionsCount.experiences,
                color: .orange
            )
            
            // Skills
            ChangeRow(
                label: "Fähigkeiten",
                icon: "star.fill",
                oldValue: previous.sectionsCount.skills,
                newValue: current.sectionsCount.skills,
                color: .yellow
            )
            
            // Projects
            ChangeRow(
                label: "Projekte",
                icon: "hammer.fill",
                oldValue: previous.sectionsCount.projects,
                newValue: current.sectionsCount.projects,
                color: .green
            )
            
            // Education
            ChangeRow(
                label: "Ausbildung",
                icon: "graduationcap.fill",
                oldValue: previous.sectionsCount.educations,
                newValue: current.sectionsCount.educations,
                color: .blue
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Hinweis")
                    .font(.headline)
            }
            
            Text(comparison.statistics.improvementSuggestion)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Statistic Card

private struct StatisticCard: View {
    let title: String
    let value: String
    let trend: Trend
    let icon: String
    
    enum Trend {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                
                Image(systemName: trend.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(trend.color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Change Row

private struct ChangeRow: View {
    let label: String
    let icon: String
    let oldValue: Int
    let newValue: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(oldValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(newValue)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(changeColor)
                
                if oldValue != newValue {
                    Text(changeText)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(changeColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var changeColor: Color {
        if newValue > oldValue { return .green }
        if newValue < oldValue { return .red }
        return .secondary
    }
    
    private var changeText: String {
        let diff = newValue - oldValue
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }
}
