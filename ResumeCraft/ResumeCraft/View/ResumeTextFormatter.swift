//
//  ResumeTextFormatter.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation

struct ResumeTextFormatter {
    static func plainText(for resume: Resume) -> String {
        plainText(for: resume, language: resume.outputLanguage)
    }

    static func plainText(for resume: Resume, language: ResumeLanguage) -> String {
        var result = ""
        let fallback = language.fallback
        let atWord = String(localized: "resume.label.at", locale: language.locale)
        let technologiesLabel = String(localized: "resume.label.technologies", locale: language.locale)
        let gradeLabel = String(localized: "resume.label.grade", locale: language.locale)
        
        // MARK: - Personal Info
        if let personal = resume.personal {
            result += "\(personal.firstName) \(personal.lastName)\n"
            
            var contactItems: [String] = []
            if !personal.email.isEmpty { contactItems.append(personal.email) }
            if !personal.phone.isEmpty { contactItems.append(personal.phone) }
            let address = personal.address(for: language, fallback: fallback)
            if !address.isEmpty { contactItems.append(address) }
            if !contactItems.isEmpty {
                result += contactItems.joined(separator: " | ") + "\n"
            }
            
            var links: [String] = []
            if let linkedIn = personal.linkedIn, !linkedIn.isEmpty { links.append(linkedIn) }
            if let website = personal.website, !website.isEmpty { links.append(website) }
            if let github = personal.github, !github.isEmpty { links.append(github) }
            if !links.isEmpty {
                result += links.joined(separator: " | ") + "\n"
            }
            result += "\n"
        }
        
        // MARK: - Summary
        if let summary = resume.summary, summary.isVisible {
            let summaryText = summary.text(for: language, fallback: fallback)
            if !summaryText.isEmpty {
                let header = ResumeSection.summary.title(for: language).uppercased(with: language.locale)
                result += "\(header)\n"
                result += summaryText + "\n\n"
            }
        }
        
        // MARK: - Work Experience
        let visibleExperiences = (resume.experiences ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleExperiences.isEmpty {
            let header = ResumeSection.experience.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            for exp in visibleExperiences {
                let title = exp.title(for: language, fallback: fallback)
                let company = exp.company(for: language, fallback: fallback)
                result += "\(title) \(atWord) \(company)\n"
                
                var locationDate = ""
                let location = exp.location(for: language, fallback: fallback)
                if !location.isEmpty { locationDate += location + " | " }
                locationDate += dateRange(exp.startDate, exp.endDate, exp.isCurrent, language: language)
                result += locationDate + "\n"
                
                let details = exp.details(for: language, fallback: fallback)
                if !details.isEmpty {
                    result += details + "\n"
                }
                result += "\n"
            }
        }
        
        // MARK: - Education
        let visibleEducations = (resume.educations ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleEducations.isEmpty {
            let header = ResumeSection.education.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            for edu in visibleEducations {
                let degree = edu.degree(for: language, fallback: fallback)
                let field = edu.field(for: language, fallback: fallback)
                result += "\(degree)"
                if !field.isEmpty {
                    result += " in \(field)"
                }
                result += "\n"
                
                let school = edu.school(for: language, fallback: fallback)
                result += "\(school) | \(dateRange(edu.startDate, edu.endDate, false, language: language))\n"
                
                let grade = edu.grade(for: language, fallback: fallback)
                if !grade.isEmpty {
                    result += "\(gradeLabel): \(grade)\n"
                }
                
                let details = edu.details(for: language, fallback: fallback)
                if !details.isEmpty {
                    result += details + "\n"
                }
                result += "\n"
            }
        }

        // MARK: - Skills
        let visibleSkills = (resume.skills ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleSkills.isEmpty {
            let header = ResumeSection.skills.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            let grouped = Dictionary(grouping: visibleSkills) { $0.category(for: language, fallback: fallback) }
            
            if grouped.keys.contains(where: { !$0.isEmpty }) {
                // Has categories
                for (category, skills) in grouped.sorted(by: { $0.key < $1.key }) {
                    let skillNames = skills.map { $0.name(for: language, fallback: fallback) }.joined(separator: ", ")
                    if category.isEmpty {
                        result += skillNames + "\n"
                    } else {
                        result += "\(category): \(skillNames)\n"
                    }
                }
            } else {
                // No categories
                result += visibleSkills.map { $0.name(for: language, fallback: fallback) }.joined(separator: ", ") + "\n"
            }
            result += "\n"
        }

        // MARK: - Projects
        let visibleProjects = (resume.projects ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleProjects.isEmpty {
            let header = ResumeSection.projects.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            for proj in visibleProjects {
                let name = proj.name(for: language, fallback: fallback)
                result += name
                if let link = proj.link, !link.isEmpty {
                    result += " (\(link))"
                }
                result += "\n"
                
                let technologies = proj.technologies(for: language, fallback: fallback)
                if !technologies.isEmpty {
                    result += "\(technologiesLabel): \(technologies)\n"
                }
                
                let details = proj.details(for: language, fallback: fallback)
                if !details.isEmpty {
                    result += details + "\n"
                }
                result += "\n"
            }
        }

        // MARK: - Languages
        let visibleLanguages = (resume.languages ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleLanguages.isEmpty {
            let header = ResumeSection.languages.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            result += visibleLanguages.map {
                let name = $0.name(for: language, fallback: fallback)
                let proficiency = $0.proficiency(for: language, fallback: fallback)
                return "\(name) - \(proficiency)"
            }.joined(separator: ", ")
            result += "\n"
        }

        // MARK: - Extracurricular
        let visibleExtracurriculars = (resume.extracurriculars ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleExtracurriculars.isEmpty {
            let header = ResumeSection.extracurricular.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            for ext in visibleExtracurriculars {
                let title = ext.title(for: language, fallback: fallback)
                let organization = ext.organization(for: language, fallback: fallback)
                result += title
                if !organization.isEmpty {
                    result += " \(atWord) \(organization)"
                }
                result += "\n"
                
                let details = ext.details(for: language, fallback: fallback)
                if !details.isEmpty {
                    result += details + "\n"
                }
                result += "\n"
            }
        }

        let miscText = resume.miscellaneous(for: language, fallback: fallback)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !miscText.isEmpty {
            let header = ResumeSection.miscellaneous.title(for: language).uppercased(with: language.locale)
            result += "\(header)\n"
            result += miscText + "\n\n"
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func dateRange(_ start: Date, _ end: Date?, _ isCurrent: Bool, language: ResumeLanguage) -> String {
        let formatter = DateFormatter.resumeMonthYear(for: language)
        let present = String(localized: "resume.label.today", locale: language.locale)
        if isCurrent {
            return "\(formatter.string(from: start)) – \(present)"
        } else if let end = end {
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        } else {
            return formatter.string(from: start)
        }
    }
}
