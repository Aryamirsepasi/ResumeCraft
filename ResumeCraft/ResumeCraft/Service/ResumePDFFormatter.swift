//
//  ResumePDFFormatter.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import UIKit

struct ResumePDFFormatter {
    static func attributedString(for resume: Resume, pageWidth: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let headerFont = UIFont.boldSystemFont(ofSize: 22)
        let sectionFont = UIFont.boldSystemFont(ofSize: 12)
        let bodyFont = UIFont.systemFont(ofSize: 10)
        let subFont = UIFont.systemFont(ofSize: 9)
        let gray = UIColor.gray

        // Name Header
        if let personal = resume.personal {
            let name = "\(personal.firstName) \(personal.lastName)\n"
            result.append(NSAttributedString(string: name, attributes: [.font: headerFont]))
        }

        // Contact Info
        if let personal = resume.personal {
            let contact = [personal.email, personal.phone, personal.address, personal.linkedIn, personal.website]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " · ") + "\n\n"
            result.append(NSAttributedString(string: contact, attributes: [.font: subFont, .foregroundColor: gray]))
        }

        // Work Experience
        if !resume.experiences.isEmpty {
            result.append(NSAttributedString(string: "Work Experience\n", attributes: [.font: sectionFont]))
            for exp in resume.experiences {
                let titleLine = "\(exp.title) at \(exp.company)\n"
                result.append(NSAttributedString(string: titleLine, attributes: [.font: bodyFont, .font: UIFont.boldSystemFont(ofSize: 13)]))
                let dateLoc = "\(exp.location) · \(dateRange(exp.startDate, exp.endDate, exp.isCurrent))\n"
                result.append(NSAttributedString(string: dateLoc, attributes: [.font: subFont, .foregroundColor: gray]))
                if !exp.details.isEmpty {
                    result.append(NSAttributedString(string: exp.details + "\n", attributes: [.font: bodyFont]))
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Projects
        if !resume.projects.isEmpty {
            result.append(NSAttributedString(string: "Projects\n", attributes: [.font: sectionFont]))
            for proj in resume.projects {
                var projectLine = proj.name
                if let link = proj.link, !link.isEmpty {
                    projectLine += " (\(link))"
                }
                projectLine += "\n"
                result.append(NSAttributedString(string: projectLine, attributes: [.font: bodyFont, .font: UIFont.boldSystemFont(ofSize: 13)]))
                if !proj.technologies.isEmpty {
                    result.append(NSAttributedString(string: proj.technologies + "\n", attributes: [.font: subFont, .foregroundColor: gray]))
                }
                if !proj.dscription.isEmpty {
                    result.append(NSAttributedString(string: proj.dscription + "\n", attributes: [.font: bodyFont]))
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Extracurricular Activities
        if !resume.extracurriculars.isEmpty {
            result.append(NSAttributedString(string: "Extracurricular Activities\n", attributes: [.font: sectionFont]))
            for ext in resume.extracurriculars {
                let titleLine = "\(ext.title) at \(ext.organization)\n"
                result.append(NSAttributedString(string: titleLine, attributes: [.font: bodyFont, .font: UIFont.boldSystemFont(ofSize: 13)]))
                if !ext.dscription.isEmpty {
                    result.append(NSAttributedString(string: ext.dscription + "\n", attributes: [.font: bodyFont]))
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Languages
        if !resume.languages.isEmpty {
            result.append(NSAttributedString(string: "Languages\n", attributes: [.font: sectionFont]))
            let langs = resume.languages.map { "\($0.name) (\($0.proficiency))" }.joined(separator: ", ")
            result.append(NSAttributedString(string: langs + "\n", attributes: [.font: bodyFont]))
        }

        return result
    }

    private static func dateRange(_ start: Date, _ end: Date?, _ isCurrent: Bool) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        if isCurrent {
            return "\(df.string(from: start)) – Present"
        } else if let end = end {
            return "\(df.string(from: start)) – \(df.string(from: end))"
        } else {
            return "\(df.string(from: start))"
        }
    }
}
