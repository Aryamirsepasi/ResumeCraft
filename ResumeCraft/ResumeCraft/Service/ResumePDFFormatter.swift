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
            .accessibilitySpeechLanguage: "de",
          ]
        )
      )
    }

      // Contact Info
      if let personal = resume.personal {
        let mainContactItems: [String?] = [
          personal.email,
          personal.phone,
          personal.address,
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
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 2
      paragraphStyle.paragraphSpacing = 4
      result.append(
        NSAttributedString(
          string: "Zusammenfassung\n",
          attributes: [.font: sectionFont]
        )
      )
      result.append(
        NSAttributedString(
          string: summary.text
            .trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n",
          attributes: [.font: subFont, .paragraphStyle: paragraphStyle]
        )
      )
    }

    // MARK: - Work Experience
    let visibleExperiences = (resume.experiences ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleExperiences.isEmpty {
      result.append(
        NSAttributedString(
          string: "Berufserfahrung\n",
          attributes: [.font: sectionFont]
        )
      )
      for exp in visibleExperiences {
        let titleLine =
          "\(exp.title) bei \(exp.company)\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let dateLoc =
          "\(exp.location) | \(dateRange(exp.startDate, exp.endDate, exp.isCurrent))\n"
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

    // Education
    let visibleEducations = (resume.educations ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleEducations.isEmpty {
      result.append(
        NSAttributedString(
          string: "Ausbildung\n",
          attributes: [.font: sectionFont]
        )
      )
      for edu in visibleEducations {
        let titleLine =
          "\(edu.degree) in \(edu.field)\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let schoolLine =
          "\(edu.school) | \(dateRange(edu.startDate, edu.endDate, false))\n"
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
              string:
                "Note: \(edu.grade)\n",
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

    // Skills - preserve orderIndex within categories
    let visibleSkills = (resume.skills ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })

    if !visibleSkills.isEmpty {
      result.append(
        NSAttributedString(
          string: "Fähigkeiten\n",
          attributes: [.font: sectionFont]
        )
      )
      let grouped = Dictionary(grouping: visibleSkills) {
        $0.category
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
          .map { $0.name }
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
          string: "Projekte\n",
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
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
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

    // Languages
    let visibleLanguages = (resume.languages ?? [])
      .filter(\.isVisible)
      .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleLanguages.isEmpty {
      result.append(
        NSAttributedString(
          string: "Sprachen\n",
          attributes: [.font: sectionFont]
        )
      )
      let langs = visibleLanguages
        .map {
          "\($0.name) (\($0.proficiency))"
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
            "Aktivitäten\n",
          attributes: [.font: sectionFont]
        )
      )
      for ext in visibleExtracurriculars {
        let titleLine =
          "\(ext.title) bei \(ext.organization)\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
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

    if let miscText = resume.miscellaneous?.trimmingCharacters(
      in: .whitespacesAndNewlines
    ), !miscText.isEmpty {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 2
      paragraphStyle.paragraphSpacing = 4
      result.append(
        NSAttributedString(
          string: "Sonstiges\n",
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
    _ isCurrent: Bool
  ) -> String {
    let present = "Heute"
    if isCurrent {
      return
        "\(DateFormatter.resumeMonthYear.string(from: start)) – \(present)"
    } else if let end = end {
      return
        "\(DateFormatter.resumeMonthYear.string(from: start)) – \(DateFormatter.resumeMonthYear.string(from: end))"
    } else {
      return "\(DateFormatter.resumeMonthYear.string(from: start))"
    }
  }
}
