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
        case missing = "Fehlender Inhalt"
        case improvement = "Verbesserung"
        case ats = "ATS-Optimierung"
        case formatting = "Formatierung"
        case length = "Länge"
        case impact = "Wirkung"
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
                title: "Persönliche Daten hinzufügen",
                description: "Dein Lebenslauf benötigt grundlegende Kontaktdaten",
                priority: .critical,
                section: "Persönliche Daten",
                actionable: true
            ))
            return suggestions
        }
        
        if personal.linkedIn == nil || personal.linkedIn?.isEmpty == true {
            suggestions.append(.init(
                type: .missing,
                title: "LinkedIn-Profil hinzufügen",
                description: "94 % der Recruiter nutzen LinkedIn zur Bewertung",
                priority: .high,
                section: "Persönliche Daten",
                actionable: true
            ))
        }
        
        if personal.github == nil || personal.github?.isEmpty == true {
            // Check if this is likely a tech resume
            suggestions.append(.init(
                type: .improvement,
                title: "GitHub-Profil hinzufügen",
                description: "GitHub zeigt deine Coding-Projekte und Beiträge",
                priority: .medium,
                section: "Persönliche Daten",
                actionable: true
            ))
        }
        
        // Email validation
        if !personal.email.isEmpty && !personal.email.contains("@") {
            suggestions.append(.init(
                type: .formatting,
                title: "E-Mail-Format prüfen",
                description: "Die E-Mail-Adresse scheint ungültig zu sein",
                priority: .critical,
                section: "Persönliche Daten",
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
                title: "Professionelle Zusammenfassung hinzufügen",
                description: "Eine starke Zusammenfassung hilft Recruitern, deinen Mehrwert schnell zu verstehen",
                priority: .high,
                section: "Zusammenfassung",
                actionable: true
            ))
            return suggestions
        }
        
        let wordCount = summary.text.split(separator: " ").count
        
        if wordCount < 20 {
            suggestions.append(.init(
                type: .length,
                title: "Zusammenfassung erweitern",
                description: "Ziele auf 50–100 Wörter, um deine Expertise wirksam darzustellen",
                priority: .medium,
                section: "Zusammenfassung",
                actionable: true
            ))
        } else if wordCount > 150 {
            suggestions.append(.init(
                type: .length,
                title: "Zusammenfassung kürzen",
                description: "Halte die Zusammenfassung knapp (50–100 Wörter) für maximale Wirkung",
                priority: .medium,
                section: "Zusammenfassung",
                actionable: true
            ))
        }
        
        // Check for first-person pronouns
        let lowered = summary.text.lowercased()
        let hasFirstPerson = lowered.contains("i ") || 
                            lowered.contains("my ") ||
                            lowered.contains("me ") ||
                            lowered.contains("ich ") ||
                            lowered.contains("mein ") ||
                            lowered.contains("meine ") ||
                            lowered.contains("mich ") ||
                            lowered.contains("mir ")
        
        if hasFirstPerson {
            suggestions.append(.init(
                type: .formatting,
                title: "Ich-Form vermeiden",
                description: "Schreibe in der dritten Person oder impliziten Ich-Form (ohne „ich“, „mein“, „mich“)",
                priority: .low,
                section: "Zusammenfassung",
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
                title: "Berufserfahrung hinzufügen",
                description: "Berufserfahrung ist für die meisten Lebensläufe entscheidend",
                priority: .critical,
                section: "Berufserfahrung",
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
                title: "Kennzahlen ergänzen",
                description: "Quantifiziere deinen Impact mit Zahlen, Prozenten oder Beträgen",
                priority: .high,
                section: "Berufserfahrung",
                actionable: true
            ))
        }
        
        // Check for action verbs
        let weakVerbs = [
            "responsible for",
            "helped",
            "worked on",
            "involved in",
            "assisted with",
            "zuständig für",
            "geholfen",
            "mitgearbeitet",
            "beteiligt",
            "unterstützt",
        ]
        let hasWeakVerbs = visibleExperiences.contains { exp in
            weakVerbs.contains(where: { exp.details.lowercased().contains($0) })
        }
        
        if hasWeakVerbs {
            suggestions.append(.init(
                type: .improvement,
                title: "Stärkere Aktionsverben nutzen",
                description: "Ersetze passive Formulierungen durch starke Aktionsverben (z. B. „geleitet“, „erreicht“, „vorangetrieben“, „aufgebaut“)",
                priority: .high,
                section: "Berufserfahrung",
                actionable: true
            ))
        }
        
        // Check for bullet point style
        for exp in visibleExperiences {
            let bulletPoints = exp.details.components(separatedBy: "\n").filter { !$0.isEmpty }
            if bulletPoints.count == 1 && exp.details.count > 100 {
                suggestions.append(.init(
                    type: .formatting,
                    title: "Aufzählungspunkte nutzen",
                    description: "Gliedere Aufgaben für \(exp.title) in klare Aufzählungspunkte",
                    priority: .medium,
                    section: "Berufserfahrung",
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
                title: "Fähigkeiten hinzufügen",
                description: "Fähigkeiten helfen ATS-Systemen, deinen Lebenslauf passenden Stellen zuzuordnen",
                priority: .critical,
                section: "Fähigkeiten",
                actionable: true
            ))
            return suggestions
        }
        
        if visibleSkills.count < 5 {
            suggestions.append(.init(
                type: .improvement,
                title: "Mehr Fähigkeiten hinzufügen",
                description: "Füge 8–12 relevante Fähigkeiten hinzu, um die ATS-Treffer zu verbessern",
                priority: .medium,
                section: "Fähigkeiten",
                actionable: true
            ))
        } else if visibleSkills.count > 20 {
            suggestions.append(.init(
                type: .ats,
                title: "Anzahl der Fähigkeiten reduzieren",
                description: "Konzentriere dich auf 8–12 wichtigste Fähigkeiten, um fokussiert zu wirken",
                priority: .low,
                section: "Fähigkeiten",
                actionable: true
            ))
        }
        
        // Check for skill categorization
        let categorized = visibleSkills.filter { !$0.category.isEmpty }
        if categorized.count < visibleSkills.count / 2 && visibleSkills.count > 6 {
            suggestions.append(.init(
                type: .formatting,
                title: "Fähigkeiten kategorisieren",
                description: "Gruppiere Fähigkeiten nach Kategorie (z. B. Programmiersprachen, Frameworks, Tools)",
                priority: .low,
                section: "Fähigkeiten",
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
                title: "Projekte erwägen",
                description: "Projekte zeigen praktische Fähigkeiten und Eigeninitiative",
                priority: .low,
                section: "Projekte",
                actionable: true
            ))
            return suggestions
        }
        
        // Check for project links
        let projectsWithLinks = visibleProjects.filter { $0.link != nil && !($0.link?.isEmpty ?? true) }
        
        if projectsWithLinks.count < visibleProjects.count {
            suggestions.append(.init(
                type: .improvement,
                title: "Links zu Projekten hinzufügen",
                description: "Füge GitHub-Repos oder Live-Demos hinzu, um deine Arbeit zu zeigen",
                priority: .medium,
                section: "Projekte",
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
                title: "Lebenslauf ist zu kurz",
                description: "Füge mehr Details hinzu, um ca. 300–500 Wörter für eine Seite zu erreichen",
                priority: .high,
                section: nil,
                actionable: false
            ))
        } else if wordCount > 1000 {
            suggestions.append(.init(
                type: .length,
                title: "Lebenslauf ist zu lang",
                description: "Ziele auf 1–2 Seiten (ca. 400–800 Wörter), um Recruiter zu halten",
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
                    title: "Beschäftigungslücken adressieren",
                    description: "Erwäge Erklärungen für größere Lücken im Lebenslauf",
                    priority: .low,
                    section: "Berufserfahrung",
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
