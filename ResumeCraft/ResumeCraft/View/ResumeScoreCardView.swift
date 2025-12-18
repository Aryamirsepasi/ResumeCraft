//
//  ResumeScoreCardView.swift
//  ResumeCraft
//
//  Visual score card showing resume quality breakdown
//

import SwiftUI

struct ResumeScoreCardView: View {
    let score: ResumeScore
    @State private var animateScore = false
    @State private var selectedCategory: ResumeScore.Category?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Score Card
                heroScoreCard
                
                // Category Breakdown
                categoryBreakdownSection
                
                // Detailed Feedback
                if let category = selectedCategory {
                    detailedFeedbackSection(for: category)
                }
                
                // Improvement Tips
                improvementTipsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Resume Score")
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateScore = true
            }
        }
    }
    
    // MARK: - Hero Score Card
    
    @ViewBuilder
    private var heroScoreCard: some View {
        VStack(spacing: 20) {
            // Circular Score
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 160, height: 160)
                
                // Score arc
                Circle()
                    .trim(from: 0, to: animateScore ? CGFloat(score.overallScore) / 100 : 0)
                    .stroke(
                        gradeGradient,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.6), value: animateScore)
                
                // Score text
                VStack(spacing: 4) {
                    Text("\(animateScore ? score.overallScore : 0)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(gradeColor)
                        .contentTransition(.numericText())
                    
                    Text(score.grade.rawValue)
                        .font(.title2.bold())
                        .foregroundStyle(gradeColor)
                }
            }
            
            // Grade description
            Text(score.grade.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Quick stats
            HStack(spacing: 24) {
                QuickStatView(
                    icon: "checkmark.circle.fill",
                    value: "\(strongCategoryCount)",
                    label: "Strong Areas",
                    color: .green
                )
                
                QuickStatView(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(improvementCount)",
                    label: "To Improve",
                    color: .orange
                )
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }
    
    // MARK: - Category Breakdown
    
    @ViewBuilder
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Breakdown")
                .font(.headline)
            
            ForEach(score.categoryScores) { categoryScore in
                CategoryScoreRow(
                    categoryScore: categoryScore,
                    isSelected: selectedCategory == categoryScore.category,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedCategory == categoryScore.category {
                                selectedCategory = nil
                            } else {
                                selectedCategory = categoryScore.category
                            }
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Detailed Feedback
    
    @ViewBuilder
    private func detailedFeedbackSection(for category: ResumeScore.Category) -> some View {
        if let categoryScore = score.categoryScores.first(where: { $0.category == category }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundStyle(categoryColor(for: categoryScore.score))
                    Text("\(category.rawValue) Details")
                        .font(.headline)
                    Spacer()
                    Button {
                        withAnimation { selectedCategory = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                
                ForEach(categoryScore.details.indices, id: \.self) { index in
                    let detail = categoryScore.details[index]
                    DetailRow(detail: detail)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
    
    // MARK: - Improvement Tips
    
    @ViewBuilder
    private var improvementTipsSection: some View {
        let tips = gatherImprovementTips()
        
        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Top Recommendations")
                        .font(.headline)
                }
                
                ForEach(tips.prefix(5), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    // MARK: - Helpers
    
    private var gradeColor: Color {
        switch score.grade {
        case .a: return .green
        case .b: return .blue
        case .c: return .yellow
        case .d: return .orange
        case .f: return .red
        }
    }
    
    private var gradeGradient: LinearGradient {
        switch score.grade {
        case .a:
            return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
        case .b:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
        case .c:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
        case .d:
            return LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        case .f:
            return LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var strongCategoryCount: Int {
        score.categoryScores.filter { $0.score >= 70 }.count
    }
    
    private var improvementCount: Int {
        score.categoryScores
            .flatMap(\.details)
            .filter { $0.feedback != nil }
            .count
    }
    
    private func categoryColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        default: return .red
        }
    }
    
    private func gatherImprovementTips() -> [String] {
        score.categoryScores
            .flatMap(\.details)
            .compactMap(\.feedback)
    }
}

// MARK: - Supporting Views

private struct QuickStatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CategoryScoreRow: View {
    let categoryScore: ResumeScore.CategoryScore
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: categoryScore.category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(scoreColor)
                }
                
                // Label and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryScore.category.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(categoryScore.category.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Score
                HStack(spacing: 8) {
                    Text("\(categoryScore.score)")
                        .font(.headline)
                        .foregroundStyle(scoreColor)
                    
                    Image(systemName: isSelected ? "chevron.up" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(isSelected ? scoreColor.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private var scoreColor: Color {
        switch categoryScore.score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        default: return .red
        }
    }
}

private struct DetailRow: View {
    let detail: ResumeScore.ScoreDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(detail.criterion)
                    .font(.subheadline.weight(.medium))
                
                Spacer()
                
                Text("\(detail.points)/\(detail.maxPoints)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scoreColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(scoreColor)
                        .frame(width: geo.size.width * progressPercent, height: 4)
                }
                .clipShape(Capsule())
            }
            .frame(height: 4)
            
            // Feedback if present
            if let feedback = detail.feedback {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    
                    Text(feedback)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.vertical, 8)
    }
    
    private var progressPercent: CGFloat {
        guard detail.maxPoints > 0 else { return 0 }
        return CGFloat(detail.points) / CGFloat(detail.maxPoints)
    }
    
    private var scoreColor: Color {
        let percent = Double(detail.points) / Double(max(detail.maxPoints, 1))
        switch percent {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
}

// MARK: - Compact Score Badge (for use elsewhere)

struct CompactScoreBadge: View {
    let score: Int
    let grade: ResumeScore.Grade
    
    var body: some View {
        HStack(spacing: 8) {
            // Mini circular score
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(score)")
                    .font(.caption2.bold())
                    .foregroundStyle(gradeColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Resume Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Text("Grade: \(grade.rawValue)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(gradeColor)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var gradeColor: Color {
        switch grade {
        case .a: return .green
        case .b: return .blue
        case .c: return .yellow
        case .d: return .orange
        case .f: return .red
        }
    }
}

// MARK: - Score Summary Row (for Settings)

struct ScoreSummaryRow: View {
    let resume: Resume
    @State private var score: ResumeScore?
    
    var body: some View {
        Group {
            if let score = score {
                NavigationLink {
                    ResumeScoreCardView(score: score)
                } label: {
                    CompactScoreBadge(score: score.overallScore, grade: score.grade)
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Calculating score...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .task {
            await calculateScore()
        }
    }
    
    @MainActor
    private func calculateScore() async {
        // Calculate on background to avoid UI blocking
        let calculatedScore = ResumeScoringEngine.calculate(for: resume)
        withAnimation {
            score = calculatedScore
        }
    }
}
