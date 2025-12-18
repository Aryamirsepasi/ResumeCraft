//
//  ResumeScoring.swift
//  ResumeCraft
//
//  Comprehensive resume scoring system
//

import Foundation

// MARK: - Score Model

struct ResumeScore: Identifiable {
    let id = UUID()
    let overallScore: Int // 0-100
    let categoryScores: [CategoryScore]
    let grade: Grade
    let timestamp: Date
    
    struct CategoryScore: Identifiable {
        let id = UUID()
        let category: Category
        let score: Int // 0-100
        let weight: Double
        let details: [ScoreDetail]
        
        var weightedScore: Double {
            Double(score) * weight
        }
    }
    
    struct ScoreDetail {
        let criterion: String
        let points: Int
        let maxPoints: Int
        let feedback: String?
    }
    
    enum Category: String, CaseIterable {
        case completeness = "Completeness"
        case contentQuality = "Content Quality"
        case atsOptimization = "ATS Optimization"
        case formatting = "Formatting"
        case impact = "Impact & Metrics"
        
        var icon: String {
            switch self {
            case .completeness: return "checklist"
            case .contentQuality: return "text.quote"
            case .atsOptimization: return "magnifyingglass"
            case .formatting: return "doc.text"
            case .impact: return "chart.line.uptrend.xyaxis"
            }
        }
        
        var description: String {
            switch self {
            case .completeness:
                return "How complete is your resume information"
            case .contentQuality:
                return "Quality of writing and content depth"
            case .atsOptimization:
                return "Compatibility with applicant tracking systems"
            case .formatting:
                return "Structure and organization of content"
            case .impact:
                return "Use of metrics and quantifiable achievements"
            }
        }
    }
    
    enum Grade: String, CaseIterable {
        case a = "A"
        case b = "B"
        case c = "C"
        case d = "D"
        case f = "F"
        
        var color: String {
            switch self {
            case .a: return "green"
            case .b: return "blue"
            case .c: return "yellow"
            case .d: return "orange"
            case .f: return "red"
            }
        }
        
        var description: String {
            switch self {
            case .a: return "Excellent! Your resume is well-optimized"
            case .b: return "Good resume with minor improvements needed"
            case .c: return "Average - several areas need attention"
            case .d: return "Below average - significant improvements needed"
            case .f: return "Needs work - missing critical information"
            }
        }
        
        static func from(score: Int) -> Grade {
            switch score {
            case 90...100: return .a
            case 80..<90: return .b
            case 70..<80: return .c
            case 60..<70: return .d
            default: return .f
            }
        }
    }
}

// MARK: - Resume Scoring Engine

final class ResumeScoringEngine {
    
    // Category weights (must sum to 1.0)
    private static let weights: [ResumeScore.Category: Double] = [
        .completeness: 0.25,
        .contentQuality: 0.25,
        .atsOptimization: 0.20,
        .formatting: 0.15,
        .impact: 0.15
    ]
    
    /// Calculate comprehensive resume score
    static func calculate(for resume: Resume) -> ResumeScore {
        var categoryScores: [ResumeScore.CategoryScore] = []
        
        // Calculate each category
        categoryScores.append(calculateCompleteness(resume))
        categoryScores.append(calculateContentQuality(resume))
        categoryScores.append(calculateATSOptimization(resume))
        categoryScores.append(calculateFormatting(resume))
        categoryScores.append(calculateImpact(resume))
        
        // Calculate weighted overall score
        let overallScore = Int(categoryScores.reduce(0.0) { $0 + $1.weightedScore })
        let grade = ResumeScore.Grade.from(score: overallScore)
        
        return ResumeScore(
            overallScore: overallScore,
            categoryScores: categoryScores,
            grade: grade,
            timestamp: Date()
        )
    }
    
    // MARK: - Completeness Score (25%)
    
    private static func calculateCompleteness(_ resume: Resume) -> ResumeScore.CategoryScore {
        var details: [ResumeScore.ScoreDetail] = []
        var totalPoints = 0
        let maxTotal = 100
        
        // Personal Info (25 points)
        let personalScore = scorePersonalInfo(resume.personal)
        totalPoints += personalScore.points
        details.append(personalScore)
        
        // Summary (15 points)
        let summaryScore = scoreSummary(resume.summary)
        totalPoints += summaryScore.points
        details.append(summaryScore)
        
        // Work Experience (25 points)
        let expScore = scoreExperienceCompleteness(resume.experiences ?? [])
        totalPoints += expScore.points
        details.append(expScore)
        
        // Skills (15 points)
        let skillsScore = scoreSkillsCompleteness(resume.skills ?? [])
        totalPoints += skillsScore.points
        details.append(skillsScore)
        
        // Education (10 points)
        let eduScore = scoreEducationCompleteness(resume.educations ?? [])
        totalPoints += eduScore.points
        details.append(eduScore)
        
        // Optional sections (10 points)
        let optionalScore = scoreOptionalSections(resume)
        totalPoints += optionalScore.points
        details.append(optionalScore)
        
        let score = (totalPoints * 100) / maxTotal
        
        return ResumeScore.CategoryScore(
            category: .completeness,
            score: min(score, 100),
            weight: weights[.completeness]!,
            details: details
        )
    }
    
    private static func scorePersonalInfo(_ personal: PersonalInfo?) -> ResumeScore.ScoreDetail {
        guard let personal = personal else {
            return .init(criterion: "Personal Information", points: 0, maxPoints: 25,
                        feedback: "Add your contact information")
        }
        
        var points = 0
        
        // Name (5 points)
        if !personal.firstName.isEmpty && !personal.lastName.isEmpty { points += 5 }
        
        // Email (5 points)
        if !personal.email.isEmpty && personal.email.isValidEmail { points += 5 }
        
        // Phone (5 points)
        if !personal.phone.isEmpty { points += 5 }
        
        // LinkedIn (5 points)
        if let linkedIn = personal.linkedIn, !linkedIn.isEmpty { points += 5 }
        
        // Additional links (5 points)
        if personal.github != nil || personal.website != nil { points += 5 }
        
        var feedback: String? = nil
        if points < 25 {
            if personal.linkedIn?.isEmpty ?? true {
                feedback = "Add LinkedIn profile for better visibility"
            } else if personal.phone.isEmpty {
                feedback = "Add phone number for recruiter contact"
            }
        }
        
        return .init(criterion: "Personal Information", points: points, maxPoints: 25, feedback: feedback)
    }
    
    private static func scoreSummary(_ summary: Summary?) -> ResumeScore.ScoreDetail {
        guard let summary = summary, summary.isVisible, !summary.text.isEmpty else {
            return .init(criterion: "Professional Summary", points: 0, maxPoints: 15,
                        feedback: "Add a compelling professional summary")
        }
        
        let wordCount = summary.text.split(separator: " ").count
        var points = 0
        var feedback: String? = nil
        
        // Has summary (5 points)
        points += 5
        
        // Good length (5 points)
        if wordCount >= 30 && wordCount <= 100 {
            points += 5
        } else if wordCount > 100 {
            feedback = "Shorten summary to 50-100 words"
            points += 2
        } else {
            feedback = "Expand summary to 50-100 words"
            points += 2
        }
        
        // Quality indicators (5 points)
        let hasActionWords = ["developed", "led", "managed", "created", "achieved", "drove", "built"]
            .contains(where: { summary.text.lowercased().contains($0) })
        
        if hasActionWords {
            points += 5
        } else {
            feedback = feedback ?? "Include action verbs in your summary"
        }
        
        return .init(criterion: "Professional Summary", points: points, maxPoints: 15, feedback: feedback)
    }
    
    private static func scoreExperienceCompleteness(_ experiences: [WorkExperience]) -> ResumeScore.ScoreDetail {
        let visible = experiences.filter(\.isVisible)
        
        if visible.isEmpty {
            return .init(criterion: "Work Experience", points: 0, maxPoints: 25,
                        feedback: "Add work experience to strengthen your resume")
        }
        
        var points = 0
        var feedback: String? = nil
        
        // Has experience (10 points)
        points += 10
        
        // Multiple experiences (5 points)
        if visible.count >= 2 {
            points += 5
        } else {
            feedback = "Consider adding more work experience"
        }
        
        // Details present (10 points)
        let hasDetails = visible.allSatisfy { !$0.details.isEmpty }
        if hasDetails {
            points += 10
        } else {
            feedback = feedback ?? "Add details for all work experiences"
        }
        
        return .init(criterion: "Work Experience", points: points, maxPoints: 25, feedback: feedback)
    }
    
    private static func scoreSkillsCompleteness(_ skills: [Skill]) -> ResumeScore.ScoreDetail {
        let visible = skills.filter(\.isVisible)
        
        if visible.isEmpty {
            return .init(criterion: "Skills", points: 0, maxPoints: 15,
                        feedback: "Add relevant skills to your resume")
        }
        
        var points = 5 // Has skills
        var feedback: String? = nil
        
        // Good number of skills (5 points)
        if visible.count >= 5 && visible.count <= 15 {
            points += 5
        } else if visible.count > 15 {
            feedback = "Consider reducing to 8-12 most relevant skills"
            points += 2
        } else {
            feedback = "Add more relevant skills (aim for 8-12)"
            points += 2
        }
        
        // Skills are categorized (5 points)
        let categorized = visible.filter { !$0.category.isEmpty }
        if categorized.count >= visible.count / 2 {
            points += 5
        } else {
            feedback = feedback ?? "Categorize your skills for better organization"
        }
        
        return .init(criterion: "Skills", points: points, maxPoints: 15, feedback: feedback)
    }
    
    private static func scoreEducationCompleteness(_ educations: [Education]) -> ResumeScore.ScoreDetail {
        let visible = educations.filter(\.isVisible)
        
        if visible.isEmpty {
            return .init(criterion: "Education", points: 0, maxPoints: 10,
                        feedback: "Add your educational background")
        }
        
        var points = 5 // Has education
        
        // Has details (5 points)
        let hasDetails = visible.allSatisfy { !$0.degree.isEmpty && !$0.school.isEmpty }
        if hasDetails {
            points += 5
        }
        
        return .init(criterion: "Education", points: points, maxPoints: 10, feedback: nil)
    }
    
    private static func scoreOptionalSections(_ resume: Resume) -> ResumeScore.ScoreDetail {
        var points = 0
        
        // Projects (5 points)
        let hasProjects = !(resume.projects ?? []).filter(\.isVisible).isEmpty
        if hasProjects { points += 5 }
        
        // Languages (3 points)
        let hasLanguages = !(resume.languages ?? []).filter(\.isVisible).isEmpty
        if hasLanguages { points += 3 }
        
        // Extracurriculars (2 points)
        let hasExtracurriculars = !(resume.extracurriculars ?? []).filter(\.isVisible).isEmpty
        if hasExtracurriculars { points += 2 }
        
        return .init(criterion: "Optional Sections", points: points, maxPoints: 10, feedback: nil)
    }
    
    // MARK: - Content Quality Score (25%)
    
    private static func calculateContentQuality(_ resume: Resume) -> ResumeScore.CategoryScore {
        var details: [ResumeScore.ScoreDetail] = []
        var totalPoints = 0
        
        // Summary quality (30 points)
        let summaryQuality = scoreSummaryQuality(resume.summary)
        totalPoints += summaryQuality.points
        details.append(summaryQuality)
        
        // Experience descriptions (40 points)
        let expQuality = scoreExperienceQuality(resume.experiences ?? [])
        totalPoints += expQuality.points
        details.append(expQuality)
        
        // Project descriptions (30 points)
        let projQuality = scoreProjectQuality(resume.projects ?? [])
        totalPoints += projQuality.points
        details.append(projQuality)
        
        return ResumeScore.CategoryScore(
            category: .contentQuality,
            score: totalPoints,
            weight: weights[.contentQuality]!,
            details: details
        )
    }
    
    private static func scoreSummaryQuality(_ summary: Summary?) -> ResumeScore.ScoreDetail {
        guard let summary = summary, !summary.text.isEmpty else {
            return .init(criterion: "Summary Quality", points: 0, maxPoints: 30,
                        feedback: "Add a professional summary")
        }
        
        var points = 10 // Has summary
        let text = summary.text.lowercased()
        
        // No first person (10 points)
        let hasFirstPerson = text.contains("i ") || text.contains("my ") || text.contains(" me ")
        if !hasFirstPerson {
            points += 10
        }
        
        // Professional language (10 points)
        let professionalWords = ["professional", "experienced", "skilled", "expert", 
                                "proficient", "dedicated", "proven", "strategic"]
        if professionalWords.contains(where: { text.contains($0) }) {
            points += 10
        }
        
        return .init(criterion: "Summary Quality", points: points, maxPoints: 30, feedback: nil)
    }
    
    private static func scoreExperienceQuality(_ experiences: [WorkExperience]) -> ResumeScore.ScoreDetail {
        let visible = experiences.filter(\.isVisible)
        
        if visible.isEmpty {
            return .init(criterion: "Experience Quality", points: 0, maxPoints: 40,
                        feedback: "Add work experience")
        }
        
        var points = 10 // Has experience
        var feedback: String? = nil
        
        // Action verbs (15 points)
        let actionVerbs = ["led", "managed", "developed", "created", "built", "designed",
                         "implemented", "achieved", "drove", "increased", "reduced",
                         "launched", "optimized", "delivered", "spearheaded"]
        
        let hasActionVerbs = visible.contains { exp in
            actionVerbs.contains(where: { exp.details.lowercased().contains($0) })
        }
        
        if hasActionVerbs {
            points += 15
        } else {
            feedback = "Use strong action verbs (Led, Achieved, Built)"
        }
        
        // Detailed descriptions (15 points)
        let avgDetailLength = visible.map { $0.details.count }.reduce(0, +) / max(visible.count, 1)
        if avgDetailLength >= 150 {
            points += 15
        } else if avgDetailLength >= 50 {
            points += 8
            feedback = feedback ?? "Expand job descriptions with more details"
        }
        
        return .init(criterion: "Experience Quality", points: points, maxPoints: 40, feedback: feedback)
    }
    
    private static func scoreProjectQuality(_ projects: [Project]) -> ResumeScore.ScoreDetail {
        let visible = projects.filter(\.isVisible)
        
        if visible.isEmpty {
            return .init(criterion: "Project Quality", points: 15, maxPoints: 30,
                        feedback: "Consider adding projects")
        }
        
        var points = 15 // Has projects
        
        // Has descriptions (10 points)
        let hasDescriptions = visible.allSatisfy { !$0.details.isEmpty }
        if hasDescriptions { points += 10 }
        
        // Has technologies (5 points)
        let hasTech = visible.allSatisfy { !$0.technologies.isEmpty }
        if hasTech { points += 5 }
        
        return .init(criterion: "Project Quality", points: points, maxPoints: 30, feedback: nil)
    }
    
    // MARK: - ATS Optimization Score (20%)
    
    private static func calculateATSOptimization(_ resume: Resume) -> ResumeScore.CategoryScore {
        var details: [ResumeScore.ScoreDetail] = []
        var totalPoints = 0
        
        // Keyword density (40 points)
        let keywordScore = scoreKeywords(resume)
        totalPoints += keywordScore.points
        details.append(keywordScore)
        
        // Standard formatting (30 points)
        let formatScore = scoreATSFormatting(resume)
        totalPoints += formatScore.points
        details.append(formatScore)
        
        // No problematic content (30 points)
        let cleanScore = scoreCleanContent(resume)
        totalPoints += cleanScore.points
        details.append(cleanScore)
        
        return ResumeScore.CategoryScore(
            category: .atsOptimization,
            score: totalPoints,
            weight: weights[.atsOptimization]!,
            details: details
        )
    }
    
    private static func scoreKeywords(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let fullText = ResumeTextFormatter.plainText(for: resume).lowercased()
        
        // Common ATS keywords by category
        let technicalKeywords = ["python", "java", "javascript", "sql", "aws", "docker",
                                "kubernetes", "react", "node", "api", "database", "cloud"]
        let softKeywords = ["leadership", "communication", "teamwork", "problem-solving",
                           "analytical", "strategic", "collaborative", "innovative"]
        let actionKeywords = ["managed", "led", "developed", "implemented", "achieved",
                             "increased", "reduced", "improved", "designed", "built"]
        
        var points = 0
        
        // Technical keywords (15 points)
        let techCount = technicalKeywords.filter { fullText.contains($0) }.count
        points += min(techCount * 3, 15)
        
        // Soft skills keywords (10 points)
        let softCount = softKeywords.filter { fullText.contains($0) }.count
        points += min(softCount * 2, 10)
        
        // Action keywords (15 points)
        let actionCount = actionKeywords.filter { fullText.contains($0) }.count
        points += min(actionCount * 2, 15)
        
        var feedback: String? = nil
        if points < 20 {
            feedback = "Add more industry keywords to improve ATS matching"
        }
        
        return .init(criterion: "Keyword Optimization", points: points, maxPoints: 40, feedback: feedback)
    }
    
    private static func scoreATSFormatting(_ resume: Resume) -> ResumeScore.ScoreDetail {
        var points = 0
        
        // Standard section headers present (15 points)
        let hasStandardSections = resume.personal != nil &&
                                 (resume.experiences ?? []).contains(where: \.isVisible) &&
                                 (resume.skills ?? []).contains(where: \.isVisible)
        if hasStandardSections { points += 15 }
        
        // Contact info properly formatted (15 points)
        if let personal = resume.personal {
            if personal.email.isValidEmail { points += 5 }
            if !personal.phone.isEmpty { points += 5 }
            if !personal.firstName.isEmpty && !personal.lastName.isEmpty { points += 5 }
        }
        
        return .init(criterion: "ATS-Friendly Format", points: points, maxPoints: 30, feedback: nil)
    }
    
    private static func scoreCleanContent(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let fullText = ResumeTextFormatter.plainText(for: resume)
        var points = 30
        var feedback: String? = nil
        
        // Check for special characters that might confuse ATS
        let problematicChars = ["→", "•", "★", "●", "►", "◆"]
        if problematicChars.contains(where: { fullText.contains($0) }) {
            points -= 10
            feedback = "Some special characters may not parse well in ATS"
        }
        
        // Check for tables/graphics mention (we can't detect actual images)
        if fullText.lowercased().contains("see attached") ||
           fullText.lowercased().contains("portfolio:") {
            points -= 5
        }
        
        return .init(criterion: "Clean Content", points: max(points, 0), maxPoints: 30, feedback: feedback)
    }
    
    // MARK: - Formatting Score (15%)
    
    private static func calculateFormatting(_ resume: Resume) -> ResumeScore.CategoryScore {
        var details: [ResumeScore.ScoreDetail] = []
        var totalPoints = 0
        
        // Section organization (40 points)
        let orgScore = scoreSectionOrganization(resume)
        totalPoints += orgScore.points
        details.append(orgScore)
        
        // Bullet point usage (30 points)
        let bulletScore = scoreBulletUsage(resume)
        totalPoints += bulletScore.points
        details.append(bulletScore)
        
        // Length appropriateness (30 points)
        let lengthScore = scoreLength(resume)
        totalPoints += lengthScore.points
        details.append(lengthScore)
        
        return ResumeScore.CategoryScore(
            category: .formatting,
            score: totalPoints,
            weight: weights[.formatting]!,
            details: details
        )
    }
    
    private static func scoreSectionOrganization(_ resume: Resume) -> ResumeScore.ScoreDetail {
        var points = 0
        
        // Personal info first (10 points)
        if resume.personal != nil { points += 10 }
        
        // Summary present (10 points)
        if resume.summary?.isVisible == true { points += 10 }
        
        // Logical section presence (20 points)
        let hasExperience = !(resume.experiences ?? []).filter(\.isVisible).isEmpty
        let hasSkills = !(resume.skills ?? []).filter(\.isVisible).isEmpty
        let hasEducation = !(resume.educations ?? []).filter(\.isVisible).isEmpty
        
        if hasExperience { points += 8 }
        if hasSkills { points += 6 }
        if hasEducation { points += 6 }
        
        return .init(criterion: "Section Organization", points: points, maxPoints: 40, feedback: nil)
    }
    
    private static func scoreBulletUsage(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let experiences = (resume.experiences ?? []).filter(\.isVisible)
        var points = 15 // Base points
        var feedback: String? = nil
        
        // Check if experiences use line breaks (pseudo-bullets)
        let usesBullets = experiences.contains { exp in
            exp.details.contains("\n") || exp.details.contains("•")
        }
        
        if usesBullets {
            points += 15
        } else if !experiences.isEmpty {
            feedback = "Use bullet points to break up job descriptions"
        }
        
        return .init(criterion: "Bullet Point Usage", points: points, maxPoints: 30, feedback: feedback)
    }
    
    private static func scoreLength(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let fullText = ResumeTextFormatter.plainText(for: resume)
        let wordCount = fullText.split(separator: " ").count
        var points = 0
        var feedback: String? = nil
        
        // Ideal: 300-700 words
        if wordCount >= 300 && wordCount <= 700 {
            points = 30
        } else if wordCount >= 200 && wordCount <= 900 {
            points = 20
            if wordCount < 300 {
                feedback = "Resume could use more detail"
            } else {
                feedback = "Consider condensing to 1-2 pages"
            }
        } else if wordCount < 200 {
            points = 10
            feedback = "Resume is too short - add more content"
        } else {
            points = 10
            feedback = "Resume is too long - keep to 1-2 pages"
        }
        
        return .init(criterion: "Appropriate Length", points: points, maxPoints: 30, feedback: feedback)
    }
    
    // MARK: - Impact Score (15%)
    
    private static func calculateImpact(_ resume: Resume) -> ResumeScore.CategoryScore {
        var details: [ResumeScore.ScoreDetail] = []
        var totalPoints = 0
        
        // Quantifiable achievements (50 points)
        let metricsScore = scoreMetrics(resume)
        totalPoints += metricsScore.points
        details.append(metricsScore)
        
        // Strong action verbs (30 points)
        let verbScore = scoreActionVerbs(resume)
        totalPoints += verbScore.points
        details.append(verbScore)
        
        // Achievement focus (20 points)
        let achievementScore = scoreAchievementFocus(resume)
        totalPoints += achievementScore.points
        details.append(achievementScore)
        
        return ResumeScore.CategoryScore(
            category: .impact,
            score: totalPoints,
            weight: weights[.impact]!,
            details: details
        )
    }
    
    private static func scoreMetrics(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let experiences = (resume.experiences ?? []).filter(\.isVisible)
        let fullText = experiences.map(\.details).joined(separator: " ")
        
        var points = 0
        var feedback: String? = nil
        
        // Check for numbers
        let hasNumbers = fullText.contains(where: \.isNumber)
        if hasNumbers { points += 15 }
        
        // Check for percentages
        let hasPercentages = fullText.contains("%")
        if hasPercentages { points += 15 }
        
        // Check for dollar amounts
        let hasDollars = fullText.contains("$") || fullText.contains("revenue") ||
                        fullText.contains("budget") || fullText.contains("savings")
        if hasDollars { points += 10 }
        
        // Check for time metrics
        let hasTimeMetrics = fullText.lowercased().contains("month") ||
                            fullText.lowercased().contains("year") ||
                            fullText.lowercased().contains("week")
        if hasTimeMetrics { points += 10 }
        
        if points < 30 {
            feedback = "Add more metrics (%, $, numbers) to quantify your achievements"
        }
        
        return .init(criterion: "Quantifiable Metrics", points: points, maxPoints: 50, feedback: feedback)
    }
    
    private static func scoreActionVerbs(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let experiences = (resume.experiences ?? []).filter(\.isVisible)
        let fullText = experiences.map(\.details).joined(separator: " ").lowercased()
        
        let strongVerbs = ["led", "spearheaded", "pioneered", "transformed", "orchestrated",
                         "architected", "revolutionized", "accelerated", "maximized",
                         "championed", "launched", "drove", "delivered", "exceeded"]
        
        let verbCount = strongVerbs.filter { fullText.contains($0) }.count
        let points = min(verbCount * 6, 30)
        
        var feedback: String? = nil
        if points < 18 {
            feedback = "Use more powerful action verbs to describe achievements"
        }
        
        return .init(criterion: "Strong Action Verbs", points: points, maxPoints: 30, feedback: feedback)
    }
    
    private static func scoreAchievementFocus(_ resume: Resume) -> ResumeScore.ScoreDetail {
        let experiences = (resume.experiences ?? []).filter(\.isVisible)
        let fullText = experiences.map(\.details).joined(separator: " ").lowercased()
        
        var points = 0
        
        // Achievement words
        let achievementWords = ["achieved", "accomplished", "exceeded", "surpassed",
                               "won", "awarded", "recognized", "promoted", "increased",
                               "decreased", "improved", "saved", "generated"]
        
        let achievementCount = achievementWords.filter { fullText.contains($0) }.count
        points = min(achievementCount * 4, 20)
        
        var feedback: String? = nil
        if points < 12 {
            feedback = "Focus on achievements rather than responsibilities"
        }
        
        return .init(criterion: "Achievement Focus", points: points, maxPoints: 20, feedback: feedback)
    }
}

// MARK: - Score History

struct ScoreHistoryEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let overallScore: Int
    let grade: String
    
    init(from score: ResumeScore) {
        self.id = score.id
        self.date = score.timestamp
        self.overallScore = score.overallScore
        self.grade = score.grade.rawValue
    }
}
