//
//  ResumePreviewView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct ResumePreviewView: View {
    let resume: Resume

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            A4PaperView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    Divider()
                    contactSection
                    if !resume.experiences.isEmpty {
                        sectionTitle("Work Experience")
                        ForEach(resume.experiences) { exp in
                            experienceSection(exp)
                        }
                    }
                    if !resume.projects.isEmpty {
                        sectionTitle("Projects")
                        ForEach(resume.projects) { proj in
                            projectSection(proj)
                        }
                    }
                    if !resume.extracurriculars.isEmpty {
                        sectionTitle("Extracurricular Activities")
                        ForEach(resume.extracurriculars) { ext in
                            extracurricularSection(ext)
                        }
                    }
                    if !resume.languages.isEmpty {
                        sectionTitle("Languages")
                        HStack {
                            ForEach(resume.languages) { lang in
                                Text("\(lang.name) (\(lang.proficiency))")
                                    .font(.callout)
                            }
                        }
                    }
                }
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundStyle(.black)
            }
        }
        .navigationTitle("Resume Preview")
        .background(Color(.systemGray6))
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(resume.personal?.firstName ?? "") \(resume.personal?.lastName ?? "")")
                .font(.system(size: 28, weight: .bold, design: .default))
                .padding(.bottom, 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Name: \(resume.personal?.firstName ?? "") \(resume.personal?.lastName ?? "")")
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let personal = resume.personal {
                if !personal.email.isEmpty { Text(personal.email) }
                if !personal.phone.isEmpty { Text(personal.phone) }
                if !personal.address.isEmpty { Text(personal.address) }
                if let linkedIn = personal.linkedIn, !linkedIn.isEmpty { Text(linkedIn) }
                if let website = personal.website, !website.isEmpty { Text(website) }
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.gray)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
    }

    private func experienceSection(_ exp: WorkExperience) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(exp.title)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text(exp.company)
                    .font(.system(size: 13))
            }
            HStack(spacing: 12) {
                Text(exp.location)
                    .font(.system(size: 12, weight: .regular))
                Text("\(dateRange(exp.startDate, exp.endDate, exp.isCurrent))")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            if !exp.details.isEmpty {
                Text(exp.details)
                    .font(.system(size: 12))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exp.title), \(exp.company), \(exp.location), \(dateRange(exp.startDate, exp.endDate, exp.isCurrent)), \(exp.details)")
    }

    private func projectSection(_ proj: Project) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(proj.name)
                    .font(.system(size: 13, weight: .bold))
                if let link = proj.link, !link.isEmpty {
                    Spacer()
                    Text(link)
                        .font(.system(size: 11))
                        .foregroundStyle(.blue)
                }
            }
            if !proj.technologies.isEmpty {
                Text(proj.technologies)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            if !proj.dscription.isEmpty {
                Text(proj.dscription)
                    .font(.system(size: 12))
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(proj.name), \(proj.technologies), \(proj.dscription), \(proj.link ?? "")")
    }

    private func extracurricularSection(_ ext: Extracurricular) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(ext.title)
                .font(.system(size: 13, weight: .semibold))
            Text(ext.organization)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
            if !ext.dscription.isEmpty {
                Text(ext.dscription)
                    .font(.system(size: 12))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ext.title) at \(ext.organization), \(ext.dscription)")
    }

    private func dateRange(_ start: Date, _ end: Date?, _ isCurrent: Bool) -> String {
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
