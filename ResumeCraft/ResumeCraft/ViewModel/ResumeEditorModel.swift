//
//  ResumeEditorModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class ResumeEditorModel {
    private(set) var resume: Resume

    let personalModel: PersonalInfoModel
    let skillsModel: SkillsModel
    let experienceModel: ExperienceModel
    let projectsModel: ProjectsModel
    let educationModel: EducationModel
    let extracurricularModel: ExtracurricularModel
    let languageModel: LanguageModel

    let context: ModelContext

    init(resume: Resume, context: ModelContext) {
        self.resume = resume
        self.context = context

        // Eagerly attach personal if missing to avoid detached instance
        if let existing = resume.personal {
            self.personalModel = PersonalInfoModel(personal: existing)
        } else {
            let p = PersonalInfo()
            p.resume = resume
            self.personalModel = PersonalInfoModel(personal: p)
            resume.personal = p
        }

        self.skillsModel = SkillsModel(resume: resume)
        self.experienceModel = ExperienceModel(resume: resume)
        self.projectsModel = ProjectsModel(resume: resume)
        self.educationModel = EducationModel(resume: resume)
        self.extracurricularModel = ExtracurricularModel(resume: resume)
        self.languageModel = LanguageModel(resume: resume)
    }

    func save() throws {
        // Ensure personal
        personalModel.personal.resume = resume
        context.insert(personalModel.personal)
        resume.personal = personalModel.personal

        // Ensure resume set on each child, insert if needed
        for skill in resume.skills {
            if skill.resume == nil { skill.resume = resume }
            context.insert(skill)
        }
        for exp in resume.experiences {
            if exp.resume == nil { exp.resume = resume }
            context.insert(exp)
        }
        for proj in resume.projects {
            if proj.resume == nil { proj.resume = resume }
            context.insert(proj)
        }
        for edu in resume.educations {
            if edu.resume == nil { edu.resume = resume }
            context.insert(edu)
        }
        for ext in resume.extracurriculars {
            if ext.resume == nil { ext.resume = resume }
            context.insert(ext)
        }
        for lang in resume.languages {
            if lang.resume == nil { lang.resume = resume }
            context.insert(lang)
        }

        resume.updated = .now
        try context.save()
    }

    func refreshAllModels() {
        do {
            let id = self.resume.id
            let descriptor = FetchDescriptor<Resume>(
                predicate: #Predicate { $0.id == id }
            )
            if let updatedResume = try context.fetch(descriptor).first {
                self.resume = updatedResume
                if let personal = updatedResume.personal {
                    personalModel.personal = personal
                } else {
                    let p = PersonalInfo()
                    p.resume = updatedResume
                    personalModel.personal = p
                    updatedResume.personal = p
                }
                skillsModel.items = Array(updatedResume.skills)
                experienceModel.items = Array(updatedResume.experiences)
                educationModel.items = Array(updatedResume.educations)
                projectsModel.items = Array(updatedResume.projects)
                extracurricularModel.items = Array(updatedResume.extracurriculars)
                languageModel.items = Array(updatedResume.languages)
            }
        } catch {
            print("Error refreshing resume data: \(error.localizedDescription)")
        }
    }
}
