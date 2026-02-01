//
//  ResumePDFFormatter.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import UIKit

struct ResumePDFFormatter {
  static func attributedString(
    for resume: Resume,
    pageWidth: CGFloat
  ) -> NSAttributedString {
    attributedString(for: resume, pageWidth: pageWidth, language: resume.outputLanguage)
  }

  static func attributedString(
    for resume: Resume,
    pageWidth: CGFloat,
    language: ResumeLanguage
  ) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let headerFont = UIFont.boldSystemFont(ofSize: 22)
    let sectionFont = UIFont.boldSystemFont(ofSize: 14)
    let bodyFont = UIFont.systemFont(ofSize: 10)
    let subFont = UIFont.systemFont(ofSize: 9)
    let gray = UIColor.gray
    let fallback = language.fallback
    let atWord = String(localized: "resume.label.at", locale: language.locale)
    let technologiesLabel = String(localized: "resume.label.technologies", locale: language.locale)
    let gradeLabel = String(localized: "resume.label.grade", locale: language.locale)

    // Name Header
    if let personal = resume.personal {
      let name = "\(personal.firstName) \(personal.lastName)\n"
      result.append(
        NSAttributedString(
          string: name,
          attributes: [
            .font: headerFont,
            .accessibilitySpeechLanguage: language.rawValue,
          ]
        )
      )
    }

      // Contact Info
      if let personal = resume.personal {
        let address = personal.address(for: language, fallback: fallback)
        let mainContactItems: [String?] = [
          personal.email,
          personal.phone,
          address,
        ]
        let mainContact = mainContactItems
          .compactMap { $0 }
          .filter { !$0.isEmpty }
          .joined(separator: " | ")

        let secondaryContactItems: [String?] = [
          personal.linkedIn,
          personal.website,
          personal.github,
        ]
        let secondaryContact = secondaryContactItems
          .compactMap { $0 }
          .filter { !$0.isEmpty }
          .joined(separator: " | ")

        if !mainContact.isEmpty {
          result.append(
            NSAttributedString(
              string: mainContact + "\n",
              attributes: [
                .font: subFont,
                .foregroundColor: gray,
              ]
            )
          )
        }
        if !secondaryContact.isEmpty {
          result.append(
            NSAttributedString(
              string: secondaryContact + "\n\n",
              attributes: [
                .font: subFont,
                .foregroundColor: gray,
              ]
            )
          )
        }
      }

    // Summary
    if let summary = resume.summary, summary.isVisible {
      let summaryText = summary.text(for: language, fallback: fallback)
        .trimmingCharacters(in: .whitespacesAndNewlines)
      if !summaryText.isEmpty {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        paragraphStyle.paragraphSpacing = 4
        result.append(
          NSAttributedString(
            string: "\(ResumeSection.summary.title(for: language))\n",
            attributes: [.font: sectionFont]
          )
        )
        result.append(
          NSAttributedString(
            string: summaryText + "\n\n",
            attributes: [.font: subFont, .paragraphStyle: paragraphStyle]
          )
        )
      }
    }

    // MARK: - Work Experience
    let visibleExperiences = (resume.experiences ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleExperiences.isEmpty {
      result.append(
        NSAttributedString(
          string: "\(ResumeSection.experience.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      for exp in visibleExperiences {
        let title = exp.title(for: language, fallback: fallback)
        let company = exp.company(for: language, fallback: fallback)
        let titleLine =
          "\(title) \(atWord) \(company)\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let location = exp.location(for: language, fallback: fallback)
        let dateRangeText = dateRange(exp.startDate, exp.endDate, exp.isCurrent, language: language)
        let dateLoc = location.isEmpty ? "\(dateRangeText)\n" : "\(location) | \(dateRangeText)\n"
        result.append(
          NSAttributedString(
            string: dateLoc,
            attributes: [
              .font: subFont,
              .foregroundColor: gray,
            ]
          )
        )
        let details = exp.details(for: language, fallback: fallback)
        if !details.isEmpty {
          result.append(
            NSAttributedString(
              string: details + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // Education
    let visibleEducations = (resume.educations ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleEducations.isEmpty {
      result.append(
        NSAttributedString(
          string: "\(ResumeSection.education.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      for edu in visibleEducations {
        let degree = edu.degree(for: language, fallback: fallback)
        let field = edu.field(for: language, fallback: fallback)
        let titleLine = field.isEmpty ? "\(degree)\n" : "\(degree) in \(field)\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let school = edu.school(for: language, fallback: fallback)
        let schoolLine =
          "\(school) | \(dateRange(edu.startDate, edu.endDate, false, language: language))\n"
        result.append(
          NSAttributedString(
            string: schoolLine,
            attributes: [
              .font: subFont,
              .foregroundColor: gray,
            ]
          )
        )
        let grade = edu.grade(for: language, fallback: fallback)
        if !grade.isEmpty {
          result.append(
            NSAttributedString(
              string:
                "\(gradeLabel): \(grade)\n",
              attributes: [
                .font: subFont,
                .foregroundColor: gray,
              ]
            )
          )
        }
        let details = edu.details(for: language, fallback: fallback)
        if !details.isEmpty {
          result.append(
            NSAttributedString(
              string: details + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // Skills - preserve orderIndex within categories
    let visibleSkills = (resume.skills ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })

    if !visibleSkills.isEmpty {
      result.append(
        NSAttributedString(
          string: "\(ResumeSection.skills.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      let grouped = Dictionary(grouping: visibleSkills) {
        $0.category(for: language, fallback: fallback)
      }
      for (category, skills) in grouped.sorted(by: { $0.key < $1.key }) {
        if !category.isEmpty {
          result.append(
            NSAttributedString(
              string: "\(category): ",
              attributes: [.font: bodyFont]
            )
          )
        }
        let names = skills
          .sorted(by: { $0.orderIndex < $1.orderIndex })
          .map { $0.name(for: language, fallback: fallback) }
          .joined(separator: ", ")
        result.append(
          NSAttributedString(string: names + "\n", attributes: [.font: bodyFont])
        )
      }
      result.append(NSAttributedString(string: "\n"))
    }

    // MARK: - Projects
    let visibleProjects = (resume.projects ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleProjects.isEmpty {
      result.append(
        NSAttributedString(
          string: "\(ResumeSection.projects.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      for proj in visibleProjects {
        let name = proj.name(for: language, fallback: fallback)
        var projectLine = name
        if let link = proj.link, !link.isEmpty {
          projectLine += " (\(link))"
        }
        projectLine += "\n"
        result.append(
          NSAttributedString(
            string: projectLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let technologies = proj.technologies(for: language, fallback: fallback)
        if !technologies.isEmpty {
          result.append(
            NSAttributedString(
              string: "\(technologiesLabel): \(technologies)\n",
              attributes: [
                .font: subFont,
                .foregroundColor: gray,
              ]
            )
          )
        }
        let details = proj.details(for: language, fallback: fallback)
        if !details.isEmpty {
          result.append(
            NSAttributedString(
              string: details + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // Languages
    let visibleLanguages = (resume.languages ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleLanguages.isEmpty {
      result.append(
        NSAttributedString(
          string: "\(ResumeSection.languages.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      let langs = visibleLanguages
        .map {
          let name = $0.name(for: language, fallback: fallback)
          let proficiency = $0.proficiency(for: language, fallback: fallback)
          return "\(name) (\(proficiency))"
        }
        .joined(separator: ", ")
      result.append(
        NSAttributedString(string: langs + "\n\n", attributes: [.font: bodyFont])
      )
    }

    // Extracurricular Activities
    let visibleExtracurriculars = (resume.extracurriculars ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleExtracurriculars.isEmpty {
      result.append(
        NSAttributedString(
          string:
            "\(ResumeSection.extracurricular.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      for ext in visibleExtracurriculars {
        let title = ext.title(for: language, fallback: fallback)
        let organization = ext.organization(for: language, fallback: fallback)
        let titleLine = organization.isEmpty
          ? "\(title)\n"
          : "\(title) \(atWord) \(organization)\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let details = ext.details(for: language, fallback: fallback)
        if !details.isEmpty {
          result.append(
            NSAttributedString(
              string: details + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    let miscText = resume.miscellaneous(for: language, fallback: fallback)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if !miscText.isEmpty {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 2
      paragraphStyle.paragraphSpacing = 4
      result.append(
        NSAttributedString(
          string: "\(ResumeSection.miscellaneous.title(for: language))\n",
          attributes: [.font: sectionFont]
        )
      )
      result.append(
        NSAttributedString(
          string: miscText + "\n\n",
          attributes: [.font: bodyFont, .paragraphStyle: paragraphStyle]
        )
      )
    }

    return result
  }

  private static func dateRange(
    _ start: Date,
    _ end: Date?,
    _ isCurrent: Bool,
    language: ResumeLanguage
  ) -> String {
    let present = String(localized: "resume.label.today", locale: language.locale)
    if isCurrent {
      return
        "\(DateFormatter.resumeMonthYear(for: language).string(from: start)) – \(present)"
    } else if let end = end {
      return
        "\(DateFormatter.resumeMonthYear(for: language).string(from: start)) – \(DateFormatter.resumeMonthYear(for: language).string(from: end))"
    } else {
      return "\(DateFormatter.resumeMonthYear(for: language).string(from: start))"
    }
  }
}
