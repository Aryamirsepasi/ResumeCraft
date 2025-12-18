//
//  SmartSuggestions.swift
//  ResumeCraft
//
//  Intelligent suggestions for improving resume content
//

import Foundation

struct SmartSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let priority: Priority
    let section: String?
    let actionable: Bool
    
    enum SuggestionType: String {
        case missing = "Missing Content"
        case improvement = "Improvement"
        case ats = "ATS Optimization"
        case formatting = "Formatting"
        case length = "Length"
        case impact = "Impact"
    }
    
    enum Priority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        var color: String {
            switch self {
            case .low: return "blue"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}

final class SmartSuggestionsEngine {
    
    /// Generate smart suggestions for a resume
    static func analyze(_ resume: Resume) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Check personal info completeness
        suggestions.append(contentsOf: analyzePersonalInfo(resume.personal))
        
        // Check summary
        suggestions.append(contentsOf: analyzeSummary(resume.summary))
        
        // Check work experience
        suggestions.append(contentsOf: analyzeExperiences(resume.experiences ?? []))
        
        // Check skills
        suggestions.append(contentsOf: analyzeSkills(resume.skills ?? []))
        
        // Check projects
        suggestions.append(contentsOf: analyzeProjects(resume.projects ?? []))
        
        // Check overall resume
        suggestions.append(contentsOf: analyzeOverall(resume))
        
        // Sort by priority
        return suggestions.sorted { $0.priority > $1.priority }
    }
    
    // MARK: - Section Analysis
    
    private static func analyzePersonalInfo(_ personal: PersonalInfo?) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        guard let personal = personal else {
            suggestions.append(.init(
                type: .missing,
                title: "Add Personal Information",
                description: "Your resume needs basic contact information",
                priority: .critical,
                section: "Personal Info",
                actionable: true
            ))
            return suggestions
        }
        
        if personal.linkedIn == nil || personal.linkedIn?.isEmpty == true {
            suggestions.append(.init(
                type: .missing,
                title: "Add LinkedIn Profile",
                description: "94% of recruiters use LinkedIn to evaluate candidates",
                priority: .high,
                section: "Personal Info",
                actionable: true
            ))
        }
        
        if personal.github == nil || personal.github?.isEmpty == true {
            // Check if this is likely a tech resume
            suggestions.append(.init(
                type: .improvement,
                title: "Consider Adding GitHub Profile",
                description: "GitHub showcases your coding projects and contributions",
                priority: .medium,
                section: "Personal Info",
                actionable: true
            ))
        }
        
        // Email validation
        if !personal.email.isEmpty && !personal.email.contains("@") {
            suggestions.append(.init(
                type: .formatting,
                title: "Check Email Format",
                description: "Email address appears to be invalid",
                priority: .critical,
                section: "Personal Info",
                actionable: true
            ))
        }
        
        return suggestions
    }
    
    private static func analyzeSummary(_ summary: Summary?) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        guard let summary = summary, !summary.text.isEmpty else {
            suggestions.append(.init(
                type: .missing,
                title: "Add Professional Summary",
                description: "A strong summary helps recruiters quickly understand your value",
                priority: .high,
                section: "Summary",
                actionable: true
            ))
            return suggestions
        }
        
        let wordCount = summary.text.split(separator: " ").count
        
        if wordCount < 20 {
            suggestions.append(.init(
                type: .length,
                title: "Expand Your Summary",
                description: "Aim for 50-100 words to effectively showcase your expertise",
                priority: .medium,
                section: "Summary",
                actionable: true
            ))
        } else if wordCount > 150 {
            suggestions.append(.init(
                type: .length,
                title: "Shorten Your Summary",
                description: "Keep your summary concise (50-100 words) for maximum impact",
                priority: .medium,
                section: "Summary",
                actionable: true
            ))
        }
        
        // Check for first-person pronouns
        let hasFirstPerson = summary.text.lowercased().contains("i ") || 
                            summary.text.lowercased().contains("my ") ||
                            summary.text.lowercased().contains("me ")
        
        if hasFirstPerson {
            suggestions.append(.init(
                type: .formatting,
                title: "Remove First-Person Pronouns",
                description: "Write in third person or implied first person (without 'I', 'my', 'me')",
                priority: .low,
                section: "Summary",
                actionable: true
            ))
        }
        
        return suggestions
    }
    
    private static func analyzeExperiences(_ experiences: [WorkExperience]) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        let visibleExperiences = experiences.filter(\.isVisible)
        
        if visibleExperiences.isEmpty {
            suggestions.append(.init(
                type: .missing,
                title: "Add Work Experience",
                description: "Work experience is crucial for most resumes",
                priority: .critical,
                section: "Work Experience",
                actionable: true
            ))
            return suggestions
        }
        
        // Check for quantifiable achievements
        let hasNumbers = visibleExperiences.contains { exp in
            exp.details.contains(where: \.isNumber) ||
            exp.details.contains("%") ||
            exp.details.contains("$")
        }
        
        if !hasNumbers {
            suggestions.append(.init(
                type: .impact,
                title: "Add Metrics to Achievements",
                description: "Quantify your impact with numbers, percentages, or dollar amounts",
                priority: .high,
                section: "Work Experience",
                actionable: true
            ))
        }
        
        // Check for action verbs
        let weakVerbs = ["responsible for", "helped", "worked on", "involved in", "assisted with"]
        let hasWeakVerbs = visibleExperiences.contains { exp in
            weakVerbs.contains(where: { exp.details.lowercased().contains($0) })
        }
        
        if hasWeakVerbs {
            suggestions.append(.init(
                type: .improvement,
                title: "Use Stronger Action Verbs",
                description: "Replace passive phrases with powerful action verbs (Led, Achieved, Drove, Built)",
                priority: .high,
                section: "Work Experience",
                actionable: true
            ))
        }
        
        // Check for bullet point style
        for exp in visibleExperiences {
            let bulletPoints = exp.details.components(separatedBy: "\n").filter { !$0.isEmpty }
            if bulletPoints.count == 1 && exp.details.count > 100 {
                suggestions.append(.init(
                    type: .formatting,
                    title: "Use Bullet Points",
                    description: "Break down responsibilities into clear bullet points for \(exp.title)",
                    priority: .medium,
                    section: "Work Experience",
                    actionable: true
                ))
                break // Only suggest once
            }
        }
        
        return suggestions
    }
    
    private static func analyzeSkills(_ skills: [Skill]) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        let visibleSkills = skills.filter(\.isVisible)
        
        if visibleSkills.isEmpty {
            suggestions.append(.init(
                type: .missing,
                title: "Add Skills Section",
                description: "Skills help ATS systems match your resume to job descriptions",
                priority: .critical,
                section: "Skills",
                actionable: true
            ))
            return suggestions
        }
        
        if visibleSkills.count < 5 {
            suggestions.append(.init(
                type: .improvement,
                title: "Add More Skills",
                description: "Include 8-12 relevant skills to improve ATS matching",
                priority: .medium,
                section: "Skills",
                actionable: true
            ))
        } else if visibleSkills.count > 20 {
            suggestions.append(.init(
                type: .ats,
                title: "Reduce Number of Skills",
                description: "Focus on 8-12 most relevant skills to avoid appearing unfocused",
                priority: .low,
                section: "Skills",
                actionable: true
            ))
        }
        
        // Check for skill categorization
        let categorized = visibleSkills.filter { !$0.category.isEmpty }
        if categorized.count < visibleSkills.count / 2 && visibleSkills.count > 6 {
            suggestions.append(.init(
                type: .formatting,
                title: "Categorize Your Skills",
                description: "Group skills by category (e.g., Programming Languages, Frameworks, Tools)",
                priority: .low,
                section: "Skills",
                actionable: true
            ))
        }
        
        return suggestions
    }
    
    private static func analyzeProjects(_ projects: [Project]) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        let visibleProjects = projects.filter(\.isVisible)
        
        if visibleProjects.isEmpty {
            suggestions.append(.init(
                type: .improvement,
                title: "Consider Adding Projects",
                description: "Projects demonstrate practical skills and initiative",
                priority: .low,
                section: "Projects",
                actionable: true
            ))
            return suggestions
        }
        
        // Check for project links
        let projectsWithLinks = visibleProjects.filter { $0.link != nil && !($0.link?.isEmpty ?? true) }
        
        if projectsWithLinks.count < visibleProjects.count {
            suggestions.append(.init(
                type: .improvement,
                title: "Add Links to Projects",
                description: "Include GitHub repos or live demos to showcase your work",
                priority: .medium,
                section: "Projects",
                actionable: true
            ))
        }
        
        return suggestions
    }
    
    private static func analyzeOverall(_ resume: Resume) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Check overall length
        let fullText = ResumeTextFormatter.plainText(for: resume)
        let wordCount = fullText.split(separator: " ").count
        
        if wordCount < 200 {
            suggestions.append(.init(
                type: .length,
                title: "Resume is Too Short",
                description: "Add more detail to reach 300-500 words for a one-page resume",
                priority: .high,
                section: nil,
                actionable: false
            ))
        } else if wordCount > 1000 {
            suggestions.append(.init(
                type: .length,
                title: "Resume is Too Long",
                description: "Aim for 1-2 pages (400-800 words) to keep recruiters engaged",
                priority: .medium,
                section: nil,
                actionable: false
            ))
        }
        
        // Check for dates
        let experiences = (resume.experiences ?? []).filter(\.isVisible)
        if experiences.count > 0 {
            let hasGaps = checkForEmploymentGaps(experiences)
            if hasGaps {
                suggestions.append(.init(
                    type: .improvement,
                    title: "Address Employment Gaps",
                    description: "Consider adding explanations for significant gaps in employment",
                    priority: .low,
                    section: "Work Experience",
                    actionable: true
                ))
            }
        }
        
        return suggestions
    }
    
    private static func checkForEmploymentGaps(_ experiences: [WorkExperience]) -> Bool {
        let sorted = experiences.sorted { $0.startDate > $1.startDate }
        
        for i in 0..<(sorted.count - 1) {
            let current = sorted[i]
            let next = sorted[i + 1]
            
            let currentEnd = current.endDate ?? Date()
            let nextStart = next.startDate
            
            let gap = Calendar.current.dateComponents([.month], from: nextStart, to: currentEnd).month ?? 0
            
            if gap > 6 {
                return true
            }
        }
        
        return false
    }
}
