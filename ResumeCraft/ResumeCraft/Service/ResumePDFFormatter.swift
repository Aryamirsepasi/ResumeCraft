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

    // MARK: - Language helpers
    let isGerman = Locale.current.language.languageCode?.identifier == "de"
    func localized(_ en: String, _ de: String?) -> String {
      if isGerman,
        let de,
        !de.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        return de
      }
      return en
    }

    // Name Header
    if let personal = resume.personal {
      let name = "\(personal.firstName) \(personal.lastName)\n"
      result.append(
        NSAttributedString(
          string: name,
          attributes: [
            .font: headerFont,
            .accessibilitySpeechLanguage: isGerman ? "de" : "en",
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
          .joined(separator: " · ")

        let secondaryContactItems: [String?] = [
          personal.linkedIn,
          personal.website,
          personal.github,
        ]
        let secondaryContact = secondaryContactItems
          .compactMap { $0 }
          .filter { !$0.isEmpty }
          .joined(separator: " · ")

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

    // Summary (with translation)
    if let summary = resume.summary, summary.isVisible {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = 2
      paragraphStyle.paragraphSpacing = 4
      result.append(
        NSAttributedString(
          string: NSLocalizedString("Summary", comment: "") + "\n",
          attributes: [.font: sectionFont]
        )
      )
      let summaryText = localized(summary.text, summary.text_de)
      result.append(
        NSAttributedString(
          string: summaryText
            .trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n",
          attributes: [.font: subFont, .paragraphStyle: paragraphStyle]
        )
      )
    }

    // Skills (with translation) - preserve orderIndex within categories
      let visibleSkills = (resume.skills ?? [])
          .filter(\.isVisible)
          .sorted(by: { $0.orderIndex < $1.orderIndex })

    if !visibleSkills.isEmpty {
      result.append(
        NSAttributedString(
          string: NSLocalizedString("Skills", comment: "") + "\n",
          attributes: [.font: sectionFont]
        )
      )
      let grouped = Dictionary(grouping: visibleSkills) {
        localized($0.category, $0.category_de)
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
          .map { localized($0.name, $0.name_de) }
          .joined(separator: ", ")
        result.append(
          NSAttributedString(string: names + "\n", attributes: [.font: bodyFont])
        )
      }
      result.append(NSAttributedString(string: "\n"))
    }

    // MARK: - Work Experience (with translations)
      let visibleExperiences = (resume.experiences ?? [])
                  .filter(\.isVisible)
                  .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleExperiences.isEmpty {
      result.append(
        NSAttributedString(
          string: NSLocalizedString("Work Experience", comment: "") + "\n",
          attributes: [.font: sectionFont]
        )
      )
      for exp in visibleExperiences {
        let titleLine =
          "\(localized(exp.title, exp.title_de)) at \(localized(exp.company, exp.company_de))\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let dateLoc =
          "\(localized(exp.location, exp.location_de)) · \(dateRange(exp.startDate, exp.endDate, exp.isCurrent, isGerman: isGerman))\n"
        result.append(
          NSAttributedString(
            string: dateLoc,
            attributes: [
              .font: subFont,
              .foregroundColor: gray,
            ]
          )
        )
        let detailsText = localized(exp.details, exp.details_de)
        if !detailsText.isEmpty {
          result.append(
            NSAttributedString(
              string: detailsText + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // MARK: - Projects (with translations)
      let visibleProjects = (resume.projects ?? [])
                 .filter(\.isVisible)
                 .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleProjects.isEmpty {
      result.append(
        NSAttributedString(
          string: NSLocalizedString("Projects", comment: "") + "\n",
          attributes: [.font: sectionFont]
        )
      )
      for proj in visibleProjects {
        var projectLine = localized(proj.name, proj.name_de)
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
        let techText = localized(proj.technologies, proj.technologies_de)
        if !techText.isEmpty {
          result.append(
            NSAttributedString(
              string: techText + "\n",
              attributes: [
                .font: subFont,
                .foregroundColor: gray,
              ]
            )
          )
        }
        let detailsText = localized(proj.details, proj.details_de)
        if !detailsText.isEmpty {
          result.append(
            NSAttributedString(
              string: detailsText + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // Education (with translations)
      let visibleEducations = (resume.educations ?? [])
                  .filter(\.isVisible)
                  .sorted(by: { $0.orderIndex < $1.orderIndex })
      
    if !visibleEducations.isEmpty {
      result.append(
        NSAttributedString(
          string: NSLocalizedString("Education", comment: "") + "\n",
          attributes: [.font: sectionFont]
        )
      )
      for edu in visibleEducations {
        let titleLine =
          "\(localized(edu.degree, edu.degree_de)) in \(localized(edu.field, edu.field_de))\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let schoolLine =
          "\(localized(edu.school, edu.school_de)) · \(dateRange(edu.startDate, edu.endDate, false, isGerman: isGerman))\n"
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
                NSLocalizedString("Grade", comment: "") + ": \(edu.grade)\n",
              attributes: [
                .font: subFont,
                .foregroundColor: gray,
              ]
            )
          )
        }
        let detailsText = localized(edu.details, edu.details_de)
        if !detailsText.isEmpty {
          result.append(
            NSAttributedString(
              string: detailsText + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // Extracurricular Activities (with translations)
      let visibleExtracurriculars = (resume.extracurriculars ?? [])
                  .filter(\.isVisible)
                  .sorted(by: { $0.orderIndex < $1.orderIndex })
      
    if !visibleExtracurriculars.isEmpty {
      result.append(
        NSAttributedString(
          string:
            NSLocalizedString("Extracurricular Activities", comment: "")
              + "\n",
          attributes: [.font: sectionFont]
        )
      )
      for ext in visibleExtracurriculars {
        let titleLine =
          "\(localized(ext.title, ext.title_de)) at \(localized(ext.organization, ext.organization_de))\n"
        result.append(
          NSAttributedString(
            string: titleLine,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 11)]
          )
        )
        let detailsText = localized(ext.details, ext.details_de)
        if !detailsText.isEmpty {
          result.append(
            NSAttributedString(
              string: detailsText + "\n",
              attributes: [.font: bodyFont]
            )
          )
        }
        result.append(NSAttributedString(string: "\n"))
      }
    }

    // Languages (with translations)
      let visibleLanguages = (resume.languages ?? [])
                  .filter(\.isVisible)
                  .sorted(by: { $0.orderIndex < $1.orderIndex })
    if !visibleLanguages.isEmpty {
      result.append(
        NSAttributedString(
          string: NSLocalizedString("Languages", comment: "") + "\n",
          attributes: [.font: sectionFont]
        )
      )
      let langs = visibleLanguages
        .map {
          "\(localized($0.name, $0.name_de)) (\(localized($0.proficiency, $0.proficiency_de)))"
        }
        .joined(separator: ", ")
      result.append(
        NSAttributedString(string: langs + "\n", attributes: [.font: bodyFont])
      )
    }

    return result
  }

  private static func dateRange(
    _ start: Date,
    _ end: Date?,
    _ isCurrent: Bool,
    isGerman: Bool
  ) -> String {
    let present = isGerman ? "Heute" : "Present"
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

extension DateFormatter {
  static let resumeMonthYear: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM yyyy"
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    return df
  }()
}
