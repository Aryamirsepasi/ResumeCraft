//
//  ResumeTextFormatter.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation

struct ResumeTextFormatter {
    static func plainText(for resume: Resume) -> String {
        var result = ""
        
        // MARK: - Personal Info
        if let personal = resume.personal {
            result += "\(personal.firstName) \(personal.lastName)\n"
            
            var contactItems: [String] = []
            if !personal.email.isEmpty { contactItems.append(personal.email) }
            if !personal.phone.isEmpty { contactItems.append(personal.phone) }
            if !personal.address.isEmpty { contactItems.append(personal.address) }
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
        if let summary = resume.summary, summary.isVisible, !summary.text.isEmpty {
            result += "ZUSAMMENFASSUNG\n"
            result += summary.text + "\n\n"
        }
        
        // MARK: - Work Experience
        let visibleExperiences = (resume.experiences ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleExperiences.isEmpty {
            result += "BERUFSERFAHRUNG\n"
            for exp in visibleExperiences {
                result += "\(exp.title) bei \(exp.company)\n"
                
                var locationDate = ""
                if !exp.location.isEmpty { locationDate += exp.location + " | " }
                locationDate += dateRange(exp.startDate, exp.endDate, exp.isCurrent)
                result += locationDate + "\n"
                
                if !exp.details.isEmpty {
                    result += exp.details + "\n"
                }
                result += "\n"
            }
        }
        
        // MARK: - Education
        let visibleEducations = (resume.educations ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleEducations.isEmpty {
            result += "AUSBILDUNG\n"
            for edu in visibleEducations {
                result += "\(edu.degree)"
                if !edu.field.isEmpty {
                    result += " in \(edu.field)"
                }
                result += "\n"
                
                result += "\(edu.school) | \(dateRange(edu.startDate, edu.endDate, false))\n"
                
                if !edu.grade.isEmpty {
                    result += "Note: \(edu.grade)\n"
                }
                
                if !edu.details.isEmpty {
                    result += edu.details + "\n"
                }
                result += "\n"
            }
        }

        // MARK: - Skills
        let visibleSkills = (resume.skills ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleSkills.isEmpty {
            result += "FÄHIGKEITEN\n"
            let grouped = Dictionary(grouping: visibleSkills) { $0.category }
            
            if grouped.keys.contains(where: { !$0.isEmpty }) {
                // Has categories
                for (category, skills) in grouped.sorted(by: { $0.key < $1.key }) {
                    let skillNames = skills.map { $0.name }.joined(separator: ", ")
                    if category.isEmpty {
                        result += skillNames + "\n"
                    } else {
                        result += "\(category): \(skillNames)\n"
                    }
                }
            } else {
                // No categories
                result += visibleSkills.map { $0.name }.joined(separator: ", ") + "\n"
            }
            result += "\n"
        }

        // MARK: - Projects
        let visibleProjects = (resume.projects ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleProjects.isEmpty {
            result += "PROJEKTE\n"
            for proj in visibleProjects {
                result += proj.name
                if let link = proj.link, !link.isEmpty {
                    result += " (\(link))"
                }
                result += "\n"
                
                if !proj.technologies.isEmpty {
                    result += "Technologien: \(proj.technologies)\n"
                }
                
                if !proj.details.isEmpty {
                    result += proj.details + "\n"
                }
                result += "\n"
            }
        }

        // MARK: - Languages
        let visibleLanguages = (resume.languages ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleLanguages.isEmpty {
            result += "SPRACHEN\n"
            result += visibleLanguages.map { "\($0.name) - \($0.proficiency)" }.joined(separator: ", ")
            result += "\n"
        }

        // MARK: - Extracurricular
        let visibleExtracurriculars = (resume.extracurriculars ?? [])
            .filter(\.isVisible)
            .sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if !visibleExtracurriculars.isEmpty {
            result += "AKTIVITÄTEN\n"
            for ext in visibleExtracurriculars {
                result += ext.title
                if !ext.organization.isEmpty {
                    result += " bei \(ext.organization)"
                }
                result += "\n"
                
                if !ext.details.isEmpty {
                    result += ext.details + "\n"
                }
                result += "\n"
            }
        }

        if let miscText = resume.miscellaneous?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ), !miscText.isEmpty {
            result += "SONSTIGES\n"
            result += miscText + "\n\n"
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func dateRange(_ start: Date, _ end: Date?, _ isCurrent: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        
        if isCurrent {
            return "\(formatter.string(from: start)) – Heute"
        } else if let end = end {
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        } else {
            return formatter.string(from: start)
        }
    }
}
