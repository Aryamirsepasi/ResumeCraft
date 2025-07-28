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
    // Holds the main resume entity
    private(set) var resume: Resume
    
    // Section editor viewmodels
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
        self.personalModel = PersonalInfoModel(personal: resume.personal ?? PersonalInfo())
        self.skillsModel = SkillsModel(resume: resume)
        self.experienceModel = ExperienceModel(resume: resume)
        self.projectsModel = ProjectsModel(resume: resume)
        self.educationModel = EducationModel(resume: resume)
        self.extracurricularModel = ExtracurricularModel(resume: resume)
        self.languageModel = LanguageModel(resume: resume)
    }
    
    func save() throws {
        // Insert new objects into context and update relationships
        for skill in skillsModel.items {
            if skill.resume == nil {
                skill.resume = resume
            }
            context.insert(skill)
        }
        
        for experience in experienceModel.items {
            if experience.resume == nil {
                experience.resume = resume
            }
            context.insert(experience)
        }
        
        for project in projectsModel.items {
            if project.resume == nil {
                project.resume = resume
            }
            context.insert(project)
        }
        
        for education in educationModel.items {
            if education.resume == nil {
                education.resume = resume
            }
            context.insert(education)
        }
        
        for extracurricular in extracurricularModel.items {
            if extracurricular.resume == nil {
                extracurricular.resume = resume
            }
            context.insert(extracurricular)
        }
        
        for language in languageModel.items {
            if language.resume == nil {
                language.resume = resume
            }
            context.insert(language)
        }
        
        // Update the personal info relationship
        personalModel.personal.resume = resume
        context.insert(personalModel.personal)
        
        // Update relationships
        resume.personal = personalModel.personal
        resume.skills = skillsModel.items
        resume.experiences = experienceModel.items
        resume.projects = projectsModel.items
        resume.educations = educationModel.items
        resume.extracurriculars = extracurricularModel.items
        resume.languages = languageModel.items
        resume.updated = .now
        
        try context.save()
    }
    
    // Add this method to your ResumeEditorModel class
    func refreshAllModels() {
        do {
            let id = self.resume.id
            let descriptor = FetchDescriptor<Resume>(predicate: #Predicate { $0.id == id })
            if let updatedResume = try context.fetch(descriptor).first {
                self.resume = updatedResume
                if let personal = updatedResume.personal {
                    personalModel.personal = personal
                } else {
                    personalModel.personal = PersonalInfo()
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
