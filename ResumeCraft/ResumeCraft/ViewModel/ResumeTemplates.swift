//
//  ResumeTemplates.swift
//  ResumeCraft
//
//  Resume templates for different industries and experience levels
//

import Foundation

enum ResumeTemplate: String, CaseIterable, Identifiable {
    case modern = "Modern"
    case traditional = "Klassisch"
    case tech = "Tech-Profil"
    case creative = "Kreativ"
    case academic = "Akademisch"
    case student = "Studierende/Berufseinstieg"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .modern:
            return "Sauberes, zeitgemäßes Design mit Akzentfarben und modernem Layout"
        case .traditional:
            return "Klassisches, professionelles Format für konservative Branchen"
        case .tech:
            return "Optimiert für Softwareentwicklung und Tech-Rollen"
        case .creative:
            return "Betont Kreativität mit einzigartigem Layout und visuellen Elementen"
        case .academic:
            return "Fokus auf Publikationen, Forschung und akademische Leistungen"
        case .student:
            return "Betont Ausbildung, Projekte und relevante Kurse"
        }
    }
    
    var icon: String {
        switch self {
        case .modern: return "doc.text.fill"
        case .traditional: return "doc.plaintext"
        case .tech: return "terminal.fill"
        case .creative: return "paintpalette.fill"
        case .academic: return "graduationcap.fill"
        case .student: return "book.fill"
        }
    }
    
    var sectionOrder: [ResumeSection] {
        switch self {
        case .modern, .traditional:
            return [.summary, .experience, .education, .skills, .projects, .languages, .miscellaneous]
        case .tech:
            return [.summary, .skills, .experience, .projects, .education, .languages, .miscellaneous]
        case .creative:
            return [.summary, .projects, .experience, .skills, .education, .miscellaneous]
        case .academic:
            return [.education, .summary, .experience, .projects, .skills, .miscellaneous]
        case .student:
            return [.education, .summary, .projects, .experience, .skills, .extracurricular, .miscellaneous]
        }
    }
    
    var recommendedSections: Set<ResumeSection> {
        switch self {
        case .modern, .traditional:
            return [.summary, .experience, .education, .skills]
        case .tech:
            return [.summary, .skills, .experience, .projects]
        case .creative:
            return [.summary, .projects, .experience, .skills]
        case .academic:
            return [.education, .summary, .experience]
        case .student:
            return [.education, .summary, .projects, .skills, .extracurricular]
        }
    }
}

enum ResumeSection: String, CaseIterable {
    case summary = "Zusammenfassung"
    case experience = "Berufserfahrung"
    case education = "Ausbildung"
    case skills = "Fähigkeiten"
    case projects = "Projekte"
    case languages = "Sprachen"
    case extracurricular = "Aktivitäten"
    case miscellaneous = "Sonstiges"
}

// MARK: - Template Recommendations

struct TemplateRecommendation {
    let template: ResumeTemplate
    let confidence: Double // 0.0 to 1.0
    let reasons: [String]
}

extension ResumeTemplate {
    /// Recommend templates based on resume content
    static func recommendations(for resume: Resume) -> [TemplateRecommendation] {
        var recommendations: [TemplateRecommendation] = []
        
        let experienceCount = (resume.experiences ?? []).filter(\.isVisible).count
        let projectCount = (resume.projects ?? []).filter(\.isVisible).count
        let educationCount = (resume.educations ?? []).filter(\.isVisible).count
        
        // Analyze for Tech template
        let techKeywords = [
            "software",
            "developer",
            "engineer",
            "programming",
            "code",
            "api",
            "cloud",
            "database",
            "entwickler",
            "ingenieur",
            "programmierung",
            "datenbank",
        ]
        let hasTechKeywords = resume.skills?.contains { skill in
            techKeywords.contains(where: { skill.name.lowercased().contains($0) })
        } ?? false
        
        if hasTechKeywords || projectCount > 2 {
            recommendations.append(.init(
                template: .tech,
                confidence: hasTechKeywords ? 0.9 : 0.7,
                reasons: [
                    "Technische Fähigkeiten erkannt",
                    "Mehrere Projekte (\(projectCount))",
                    "Für ATS-Systeme im Tech-Bereich optimiert"
                ]
            ))
        }
        
        // Student template
        if experienceCount <= 1 && educationCount >= 1 {
            recommendations.append(.init(
                template: .student,
                confidence: 0.85,
                reasons: [
                    "Wenig Berufserfahrung",
                    "Ausbildung im Fokus",
                    "Ideal für Einstiegspositionen"
                ]
            ))
        }
        
        // Academic template
        let academicKeywords = [
            "research",
            "publication",
            "phd",
            "postdoc",
            "professor",
            "lecturer",
            "forschung",
            "publikation",
            "promotion",
            "doktor",
            "dozent",
        ]
        let hasAcademicKeywords = resume.experiences?.contains { exp in
            academicKeywords.contains(where: { exp.title.lowercased().contains($0) })
        } ?? false
        
        if hasAcademicKeywords || educationCount > 2 {
            recommendations.append(.init(
                template: .academic,
                confidence: 0.85,
                reasons: [
                    "Akademische Rollen erkannt",
                    "Mehrere Abschlüsse",
                    "Betont Ausbildung und Forschung"
                ]
            ))
        }
        
        // Modern template (default good choice)
        recommendations.append(.init(
            template: .modern,
            confidence: 0.75,
            reasons: [
                "Vielseitig in vielen Branchen",
                "Klarer, professioneller Eindruck",
                "ATS-freundlich"
            ]
        ))
        
        // Sort by confidence
        return recommendations.sorted { $0.confidence > $1.confidence }
    }
}
