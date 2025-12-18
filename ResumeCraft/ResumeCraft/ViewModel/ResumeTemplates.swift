//
//  ResumeTemplates.swift
//  ResumeCraft
//
//  Resume templates for different industries and experience levels
//

import Foundation

enum ResumeTemplate: String, CaseIterable, Identifiable {
    case modern = "Modern"
    case traditional = "Traditional"
    case tech = "Tech Professional"
    case creative = "Creative"
    case academic = "Academic"
    case student = "Student/Entry Level"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .modern:
            return "Clean, contemporary design with accent colors and modern layout"
        case .traditional:
            return "Classic, professional format preferred by conservative industries"
        case .tech:
            return "Optimized for software engineering and tech roles"
        case .creative:
            return "Showcases creativity with unique layout and visual elements"
        case .academic:
            return "Emphasizes publications, research, and academic achievements"
        case .student:
            return "Highlights education, projects, and relevant coursework"
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
            return [.summary, .experience, .education, .skills, .projects, .languages]
        case .tech:
            return [.summary, .skills, .experience, .projects, .education, .languages]
        case .creative:
            return [.summary, .projects, .experience, .skills, .education]
        case .academic:
            return [.education, .summary, .experience, .projects, .skills]
        case .student:
            return [.education, .summary, .projects, .experience, .skills, .extracurricular]
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
    case summary = "Summary"
    case experience = "Work Experience"
    case education = "Education"
    case skills = "Skills"
    case projects = "Projects"
    case languages = "Languages"
    case extracurricular = "Activities"
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
        let skillCount = (resume.skills ?? []).filter(\.isVisible).count
        
        // Analyze for Tech template
        let techKeywords = ["software", "developer", "engineer", "programming", "code", "api", "cloud", "database"]
        let hasTechKeywords = resume.skills?.contains { skill in
            techKeywords.contains(where: { skill.name.lowercased().contains($0) })
        } ?? false
        
        if hasTechKeywords || projectCount > 2 {
            recommendations.append(.init(
                template: .tech,
                confidence: hasTechKeywords ? 0.9 : 0.7,
                reasons: [
                    "Technical skills detected",
                    "Multiple projects (\(projectCount))",
                    "Optimized for ATS systems in tech"
                ]
            ))
        }
        
        // Student template
        if experienceCount <= 1 && educationCount >= 1 {
            recommendations.append(.init(
                template: .student,
                confidence: 0.85,
                reasons: [
                    "Limited work experience",
                    "Education highlighted",
                    "Great for entry-level positions"
                ]
            ))
        }
        
        // Academic template
        let academicKeywords = ["research", "publication", "phd", "postdoc", "professor", "lecturer"]
        let hasAcademicKeywords = resume.experiences?.contains { exp in
            academicKeywords.contains(where: { exp.title.lowercased().contains($0) })
        } ?? false
        
        if hasAcademicKeywords || educationCount > 2 {
            recommendations.append(.init(
                template: .academic,
                confidence: 0.85,
                reasons: [
                    "Academic roles detected",
                    "Multiple degrees",
                    "Emphasizes education and research"
                ]
            ))
        }
        
        // Modern template (default good choice)
        recommendations.append(.init(
            template: .modern,
            confidence: 0.75,
            reasons: [
                "Versatile across industries",
                "Clean, professional appearance",
                "ATS-friendly"
            ]
        ))
        
        // Sort by confidence
        return recommendations.sorted { $0.confidence > $1.confidence }
    }
}
