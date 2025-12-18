//
//  SmartSuggestionsListView.swift
//  ResumeCraft
//
//  Display actionable AI-powered suggestions for resume improvement
//

import SwiftUI

struct SmartSuggestionsListView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel
    @State private var suggestions: [SmartSuggestion] = []
    @State private var isLoading = true
    @State private var filterPriority: SmartSuggestion.Priority?
    @State private var filterType: SmartSuggestion.SuggestionType?
    @State private var dismissedSuggestions: Set<UUID> = []
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if filteredSuggestions.isEmpty {
                emptyStateView
            } else {
                suggestionsList
            }
        }
        .navigationTitle("Smart Suggestions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
        .task {
            await loadSuggestions()
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing your resume...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Suggestions", systemImage: "checkmark.seal.fill")
        } description: {
            if filterPriority != nil || filterType != nil {
                Text("No suggestions match your current filters.")
            } else {
                Text("Great job! Your resume looks well-optimized.")
            }
        } actions: {
            if filterPriority != nil || filterType != nil {
                Button("Clear Filters") {
                    withAnimation {
                        filterPriority = nil
                        filterType = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Suggestions List
    
    @ViewBuilder
    private var suggestionsList: some View {
        List {
            // Summary section
            summarySection
            
            // Grouped suggestions by section
            ForEach(groupedSuggestions.keys.sorted(), id: \.self) { section in
                Section {
                    ForEach(groupedSuggestions[section] ?? []) { suggestion in
                        SuggestionRow(
                            suggestion: suggestion,
                            onDismiss: {
                                withAnimation {
                                    _ = dismissedSuggestions.insert(suggestion.id)
                                }
                            }
                        )
                    }
                } header: {
                    Text(section)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Summary Section
    
    @ViewBuilder
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                // Priority breakdown
                HStack(spacing: 20) {
                    PriorityBadge(
                        priority: .critical,
                        count: countByPriority(.critical)
                    )
                    PriorityBadge(
                        priority: .high,
                        count: countByPriority(.high)
                    )
                    PriorityBadge(
                        priority: .medium,
                        count: countByPriority(.medium)
                    )
                    PriorityBadge(
                        priority: .low,
                        count: countByPriority(.low)
                    )
                }
                
                // Progress indicator
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Completion Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(dismissedSuggestions.count)/\(suggestions.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: geo.size.width * completionProgress)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Overview")
        }
    }
    
    // MARK: - Filter Menu
    
    @ViewBuilder
    private var filterMenu: some View {
        Menu {
            Section("Priority") {
                Button {
                    filterPriority = filterPriority == nil ? nil : nil
                } label: {
                    Label("All Priorities", systemImage: filterPriority == nil ? "checkmark" : "")
                }
                
                ForEach([SmartSuggestion.Priority.critical, .high, .medium, .low], id: \.self) { priority in
                    Button {
                        filterPriority = filterPriority == priority ? nil : priority
                    } label: {
                        Label(priority.displayName, systemImage: filterPriority == priority ? "checkmark" : "")
                    }
                }
            }
            
            Section("Type") {
                Button {
                    filterType = nil
                } label: {
                    Label("All Types", systemImage: filterType == nil ? "checkmark" : "")
                }
                
                ForEach(SmartSuggestion.SuggestionType.allCases, id: \.self) { type in
                    Button {
                        filterType = filterType == type ? nil : type
                    } label: {
                        Label(type.rawValue, systemImage: filterType == type ? "checkmark" : "")
                    }
                }
            }
            
            if !dismissedSuggestions.isEmpty {
                Section {
                    Button {
                        withAnimation {
                            dismissedSuggestions.removeAll()
                        }
                    } label: {
                        Label("Reset Dismissed", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .symbolVariant(filterPriority != nil || filterType != nil ? .fill : .none)
        }
    }
    
    // MARK: - Helpers
    
    private var filteredSuggestions: [SmartSuggestion] {
        suggestions
            .filter { !dismissedSuggestions.contains($0.id) }
            .filter { suggestion in
                if let priority = filterPriority {
                    return suggestion.priority == priority
                }
                return true
            }
            .filter { suggestion in
                if let type = filterType {
                    return suggestion.type == type
                }
                return true
            }
    }
    
    private var groupedSuggestions: [String: [SmartSuggestion]] {
        Dictionary(grouping: filteredSuggestions) { suggestion in
            suggestion.section ?? "General"
        }
    }
    
    private func countByPriority(_ priority: SmartSuggestion.Priority) -> Int {
        filteredSuggestions.filter { $0.priority == priority }.count
    }
    
    private var completionProgress: CGFloat {
        guard !suggestions.isEmpty else { return 0 }
        return CGFloat(dismissedSuggestions.count) / CGFloat(suggestions.count)
    }
    
    @MainActor
    private func loadSuggestions() async {
        // Small delay to show loading state
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let analyzedSuggestions = SmartSuggestionsEngine.analyze(resumeModel.resume)
        
        withAnimation {
            suggestions = analyzedSuggestions
            isLoading = false
        }
    }
}

// MARK: - Suggestion Row

private struct SuggestionRow: View {
    let suggestion: SmartSuggestion
    let onDismiss: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: typeIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(priorityColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(suggestion.title)
                            .font(.subheadline.weight(.semibold))
                        
                        Spacer()
                        
                        PriorityLabel(priority: suggestion.priority)
                    }
                    
                    Text(suggestion.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Description (expanded)
            if isExpanded {
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 48)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Actions
            if isExpanded && suggestion.actionable {
                HStack(spacing: 12) {
                    Button {
                        onDismiss()
                    } label: {
                        Label("Mark Done", systemImage: "checkmark.circle")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Spacer()
                }
                .padding(.leading, 48)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private var typeIcon: String {
        switch suggestion.type {
        case .missing: return "plus.circle"
        case .improvement: return "arrow.up.circle"
        case .ats: return "magnifyingglass"
        case .formatting: return "doc.text"
        case .length: return "textformat.size"
        case .impact: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Priority Badge

private struct PriorityBadge: View {
    let priority: SmartSuggestion.Priority
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(count > 0 ? priorityColor : .secondary)
            
            Text(priority.shortName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - Priority Label

private struct PriorityLabel: View {
    let priority: SmartSuggestion.Priority
    
    var body: some View {
        Text(priority.shortName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - Extensions

extension SmartSuggestion.Priority {
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var shortName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Med"
        case .low: return "Low"
        }
    }
}

extension SmartSuggestion.SuggestionType: CaseIterable {
    static var allCases: [SmartSuggestion.SuggestionType] {
        [.missing, .improvement, .ats, .formatting, .length, .impact]
    }
}
