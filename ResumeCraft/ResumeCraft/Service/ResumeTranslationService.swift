import Foundation
import SwiftData
import Translation

@MainActor
struct ResumeTranslationService {

    /// Direction the translation should run.
    /// In this codebase the "primary" fields hold the German content; `_en`
    /// fields hold the English translation.
    enum Direction {
        case germanToEnglish
        case englishToGerman

        var sourceLanguage: Locale.Language {
            switch self {
            case .germanToEnglish: return Locale.Language(identifier: "de")
            case .englishToGerman: return Locale.Language(identifier: "en")
            }
        }

        var targetLanguage: Locale.Language {
            switch self {
            case .germanToEnglish: return Locale.Language(identifier: "en")
            case .englishToGerman: return Locale.Language(identifier: "de")
            }
        }
    }

    enum Mode {
        case missingOnly
        case refreshAll
    }

    private static func stableID(_ model: any PersistentModel) -> String {
        "\(model.persistentModelID.hashValue)"
    }

    /// Builds translation requests for fields whose destination side is empty,
    /// or all non-empty source fields when explicitly refreshing translations.
    static func buildRequests(
        from resume: Resume,
        direction: Direction = .germanToEnglish,
        mode: Mode = .missingOnly
    ) -> [TranslationSession.Request] {
        var requests: [TranslationSession.Request] = []

        func isEmpty(_ value: String?) -> Bool {
            guard let value else { return true }
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        /// Source text for a (german, english) pair, or nil if no work to do.
        func source(german: String, english: String?) -> String? {
            switch direction {
            case .germanToEnglish:
                guard !isEmpty(german) else { return nil }
                guard mode == .refreshAll || isEmpty(english) else { return nil }
                return german
            case .englishToGerman:
                guard !isEmpty(english) else { return nil }
                guard mode == .refreshAll || isEmpty(german) else { return nil }
                return english
            }
        }

        func add(_ value: String?, id: String) {
            guard let value else { return }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            requests.append(.init(sourceText: trimmed, clientIdentifier: id))
        }

        // PersonalInfo
        if let personal = resume.personal {
            add(source(german: personal.address, english: personal.address_en), id: "personal.address")
        }

        // Summary
        if let summary = resume.summary {
            add(source(german: summary.text, english: summary.text_en), id: "summary.text")
        }

        // Miscellaneous
        add(source(german: resume.miscellaneous ?? "", english: resume.miscellaneous_en), id: "resume.miscellaneous")

        // Work Experiences
        for exp in (resume.experiences ?? []) {
            let key = stableID(exp)
            add(source(german: exp.title, english: exp.title_en), id: "exp.\(key).title")
            add(source(german: exp.company, english: exp.company_en), id: "exp.\(key).company")
            add(source(german: exp.location, english: exp.location_en), id: "exp.\(key).location")
            add(source(german: exp.details, english: exp.details_en), id: "exp.\(key).details")
        }

        // Projects
        for proj in (resume.projects ?? []) {
            let key = stableID(proj)
            add(source(german: proj.name, english: proj.name_en), id: "proj.\(key).name")
            add(source(german: proj.details, english: proj.details_en), id: "proj.\(key).details")
            add(source(german: proj.technologies, english: proj.technologies_en), id: "proj.\(key).technologies")
        }

        // Skills
        for skill in (resume.skills ?? []) {
            let key = stableID(skill)
            add(source(german: skill.name, english: skill.name_en), id: "skill.\(key).name")
            add(source(german: skill.category, english: skill.category_en), id: "skill.\(key).category")
        }

        // Education
        for edu in (resume.educations ?? []) {
            let key = stableID(edu)
            add(source(german: edu.school, english: edu.school_en), id: "edu.\(key).school")
            add(source(german: edu.degree, english: edu.degree_en), id: "edu.\(key).degree")
            add(source(german: edu.field, english: edu.field_en), id: "edu.\(key).field")
            add(source(german: edu.details, english: edu.details_en), id: "edu.\(key).details")
            add(source(german: edu.grade, english: edu.grade_en), id: "edu.\(key).grade")
        }

        // Extracurriculars
        for extra in (resume.extracurriculars ?? []) {
            let key = stableID(extra)
            add(source(german: extra.title, english: extra.title_en), id: "extra.\(key).title")
            add(source(german: extra.organization, english: extra.organization_en), id: "extra.\(key).organization")
            add(source(german: extra.details, english: extra.details_en), id: "extra.\(key).details")
        }

        // Languages
        for lang in (resume.languages ?? []) {
            let key = stableID(lang)
            add(source(german: lang.name, english: lang.name_en), id: "lang.\(key).name")
            add(source(german: lang.proficiency, english: lang.proficiency_en), id: "lang.\(key).proficiency")
        }

        return requests
    }

    /// Applies translated responses back to the resume, writing into the
    /// destination side determined by the direction.
    static func applyTranslations(
        _ responses: [TranslationSession.Response],
        to resume: Resume,
        direction: Direction = .germanToEnglish
    ) {
        let lookup = Dictionary(
            responses.compactMap { resp in
                resp.clientIdentifier.map { ($0, resp.targetText) }
            },
            uniquingKeysWith: { _, last in last }
        )

        func translated(_ id: String) -> String? {
            guard let text = lookup[id] else { return nil }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        /// Writes a translated value into the correct field for the direction.
        /// - For DE→EN we write into the `_en` setter.
        /// - For EN→DE we write into the German primary setter.
        func writeString(
            _ value: String?,
            german germanWriter: (String) -> Void,
            english englishWriter: (String) -> Void
        ) {
            guard let value else { return }
            switch direction {
            case .germanToEnglish:
                englishWriter(value)
            case .englishToGerman:
                germanWriter(value)
            }
        }

        // PersonalInfo
        if let personal = resume.personal {
            writeString(
                translated("personal.address"),
                german: { personal.address = $0 },
                english: { personal.address_en = $0 }
            )
        }

        // Summary
        if let summary = resume.summary {
            writeString(
                translated("summary.text"),
                german: { summary.text = $0 },
                english: { summary.text_en = $0 }
            )
        }

        // Miscellaneous
        writeString(
            translated("resume.miscellaneous"),
            german: { resume.miscellaneous = $0 },
            english: { resume.miscellaneous_en = $0 }
        )

        // Work Experiences
        for exp in (resume.experiences ?? []) {
            let key = stableID(exp)
            writeString(translated("exp.\(key).title"),
                       german: { exp.title = $0 },
                       english: { exp.title_en = $0 })
            writeString(translated("exp.\(key).company"),
                       german: { exp.company = $0 },
                       english: { exp.company_en = $0 })
            writeString(translated("exp.\(key).location"),
                       german: { exp.location = $0 },
                       english: { exp.location_en = $0 })
            writeString(translated("exp.\(key).details"),
                       german: { exp.details = $0 },
                       english: { exp.details_en = $0 })
        }

        // Projects
        for proj in (resume.projects ?? []) {
            let key = stableID(proj)
            writeString(translated("proj.\(key).name"),
                       german: { proj.name = $0 },
                       english: { proj.name_en = $0 })
            writeString(translated("proj.\(key).details"),
                       german: { proj.details = $0 },
                       english: { proj.details_en = $0 })
            writeString(translated("proj.\(key).technologies"),
                       german: { proj.technologies = $0 },
                       english: { proj.technologies_en = $0 })
        }

        // Skills
        for skill in (resume.skills ?? []) {
            let key = stableID(skill)
            writeString(translated("skill.\(key).name"),
                       german: { skill.name = $0 },
                       english: { skill.name_en = $0 })
            writeString(translated("skill.\(key).category"),
                       german: { skill.category = $0 },
                       english: { skill.category_en = $0 })
        }

        // Education
        for edu in (resume.educations ?? []) {
            let key = stableID(edu)
            writeString(translated("edu.\(key).school"),
                       german: { edu.school = $0 },
                       english: { edu.school_en = $0 })
            writeString(translated("edu.\(key).degree"),
                       german: { edu.degree = $0 },
                       english: { edu.degree_en = $0 })
            writeString(translated("edu.\(key).field"),
                       german: { edu.field = $0 },
                       english: { edu.field_en = $0 })
            writeString(translated("edu.\(key).details"),
                       german: { edu.details = $0 },
                       english: { edu.details_en = $0 })
            writeString(translated("edu.\(key).grade"),
                       german: { edu.grade = $0 },
                       english: { edu.grade_en = $0 })
        }

        // Extracurriculars
        for extra in (resume.extracurriculars ?? []) {
            let key = stableID(extra)
            writeString(translated("extra.\(key).title"),
                       german: { extra.title = $0 },
                       english: { extra.title_en = $0 })
            writeString(translated("extra.\(key).organization"),
                       german: { extra.organization = $0 },
                       english: { extra.organization_en = $0 })
            writeString(translated("extra.\(key).details"),
                       german: { extra.details = $0 },
                       english: { extra.details_en = $0 })
        }

        // Languages
        for lang in (resume.languages ?? []) {
            let key = stableID(lang)
            writeString(translated("lang.\(key).name"),
                       german: { lang.name = $0 },
                       english: { lang.name_en = $0 })
            writeString(translated("lang.\(key).proficiency"),
                       german: { lang.proficiency = $0 },
                       english: { lang.proficiency_en = $0 })
        }
    }
}
