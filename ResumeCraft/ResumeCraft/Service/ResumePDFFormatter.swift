//
//  ResumePDFFormatter.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import UIKit

struct ResumePDFFormatter {
    static func attributedString(for resume: Resume, pageWidth: CGFloat)
        -> NSAttributedString
    {
        let result = NSMutableAttributedString()
        let headerFont = UIFont.boldSystemFont(ofSize: 22)
        let sectionFont = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont = UIFont.systemFont(ofSize: 10)
        let subFont = UIFont.systemFont(ofSize: 9)
        let gray = UIColor.gray

        // Name Header
        if let personal = resume.personal {
            let name = "\(personal.firstName) \(personal.lastName)\n"
            result.append(
                NSAttributedString(
                    string: name,
                    attributes: [
                        .font: headerFont,
                        .accessibilitySpeechLanguage: "en",
                    ]
                )
            )
        }

        // Contact Info
        if let personal = resume.personal {
            let contactItems: [String?] = [
                personal.email,
                personal.phone,
                personal.address,
                personal.linkedIn,
                personal.website,
                personal.github,
            ]
            let contact = contactItems
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            if !contact.isEmpty {
                result.append(
                    NSAttributedString(
                        string: contact + "\n\n",
                        attributes: [
                            .font: subFont,
                            .foregroundColor: gray,
                        ]
                    )
                )
            }
        }

        // Skills
        if !resume.skills.filter(\.isVisible).isEmpty {
            let visibleSkills = resume.skills.filter(\.isVisible)
            result.append(
                NSAttributedString(
                    string: "Skills\n",
                    attributes: [.font: sectionFont]
                )
            )
            let grouped = Dictionary(grouping: visibleSkills, by: { $0.category })
            for (category, skills) in grouped.sorted(by: { $0.key < $1.key }) {
                if !category.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: "\(category): ",
                            attributes: [.font: bodyFont]
                        )
                    )
                }
                let names = skills.map { $0.name }.joined(separator: ", ")
                result.append(
                    NSAttributedString(
                        string: names + "\n",
                        attributes: [.font: bodyFont]
                    )
                )
            }
            result.append(NSAttributedString(string: "\n"))
        }

        // Work Experience
        if !resume.experiences.filter(\.isVisible).isEmpty {
            let visibleExperiences = resume.experiences.filter(\.isVisible)
            result.append(
                NSAttributedString(
                    string: "Work Experience\n",
                    attributes: [.font: sectionFont]
                )
            )
            for exp in visibleExperiences {
                let titleLine = "\(exp.title) at \(exp.company)\n"
                result.append(
                    NSAttributedString(
                        string: titleLine,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 11),
                        ]
                    )
                )
                let dateLoc =
                    "\(exp.location) · \(dateRange(exp.startDate, exp.endDate, exp.isCurrent))\n"
                result.append(
                    NSAttributedString(
                        string: dateLoc,
                        attributes: [
                            .font: subFont,
                            .foregroundColor: gray,
                        ]
                    )
                )
                if !exp.details.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: exp.details + "\n",
                            attributes: [.font: bodyFont]
                        )
                    )
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Projects
        if !resume.projects.filter(\.isVisible).isEmpty {
            let visibleProjects = resume.projects.filter(\.isVisible)
            result.append(
                NSAttributedString(
                    string: "Projects\n",
                    attributes: [.font: sectionFont]
                )
            )
            for proj in visibleProjects {
                var projectLine = proj.name
                if let link = proj.link, !link.isEmpty {
                    projectLine += " (\(link))"
                }
                projectLine += "\n"
                result.append(
                    NSAttributedString(
                        string: projectLine,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 11),
                        ]
                    )
                )
                if !proj.technologies.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: proj.technologies + "\n",
                            attributes: [
                                .font: subFont,
                                .foregroundColor: gray,
                            ]
                        )
                    )
                }
                if !proj.details.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: proj.details + "\n",
                            attributes: [.font: bodyFont]
                        )
                    )
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Education
        if !resume.educations.filter(\.isVisible).isEmpty {
            let visibleEducations = resume.educations.filter(\.isVisible)
            result.append(
                NSAttributedString(
                    string: "Education\n",
                    attributes: [.font: sectionFont]
                )
            )
            for edu in visibleEducations {
                let titleLine = "\(edu.degree) in \(edu.field)\n"
                result.append(
                    NSAttributedString(
                        string: titleLine,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 11),
                        ]
                    )
                )
                let schoolLine =
                    "\(edu.school) · \(dateRange(edu.startDate, edu.endDate, false))\n"
                result.append(
                    NSAttributedString(
                        string: schoolLine,
                        attributes: [
                            .font: subFont,
                            .foregroundColor: gray,
                        ]
                    )
                )
                if !edu.grade.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: "Grade: \(edu.grade)\n",
                            attributes: [
                                .font: subFont,
                                .foregroundColor: gray,
                            ]
                        )
                    )
                }
                if !edu.details.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: edu.details + "\n",
                            attributes: [.font: bodyFont]
                        )
                    )
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Extracurricular Activities
        if !resume.extracurriculars.filter(\.isVisible).isEmpty {
            let visibleExtracurriculars =
                resume.extracurriculars.filter(\.isVisible)
            result.append(
                NSAttributedString(
                    string: "Extracurricular Activities\n",
                    attributes: [.font: sectionFont]
                )
            )
            for ext in visibleExtracurriculars {
                let titleLine = "\(ext.title) at \(ext.organization)\n"
                result.append(
                    NSAttributedString(
                        string: titleLine,
                        attributes: [
                            .font: UIFont.boldSystemFont(ofSize: 11),
                        ]
                    )
                )
                if !ext.details.isEmpty {
                    result.append(
                        NSAttributedString(
                            string: ext.details + "\n",
                            attributes: [.font: bodyFont]
                        )
                    )
                }
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Languages
        if !resume.languages.filter(\.isVisible).isEmpty {
            let visibleLanguages = resume.languages.filter(\.isVisible)
            result.append(
                NSAttributedString(
                    string: "Languages\n",
                    attributes: [.font: sectionFont]
                )
            )
            let langs = visibleLanguages.map {
                "\($0.name) (\($0.proficiency))"
            }
            .joined(separator: ", ")
            result.append(
                NSAttributedString(
                    string: langs + "\n",
                    attributes: [.font: bodyFont]
                )
            )
        }

        return result
    }

    private static func dateRange(_ start: Date, _ end: Date?, _ isCurrent: Bool)
        -> String
    {
        if isCurrent {
            return "\(DateFormatter.resumeMonthYear.string(from: start)) – Present"
        } else if let end = end {
            return "\(DateFormatter.resumeMonthYear.string(from: start)) – \(DateFormatter.resumeMonthYear.string(from: end))"
        } else {
            return "\(DateFormatter.resumeMonthYear.string(from: start))"
        }
    }
}


extension DateFormatter {
    static let resumeMonthYear: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df
    }()
}
