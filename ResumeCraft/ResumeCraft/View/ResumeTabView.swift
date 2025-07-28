//
//  ResumeTabView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import PDFKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import Vision

struct ResumeTabView: View {
    @Environment(\.modelContext) private var context
    @State private var resumeModel: ResumeEditorModel?
    @State private var showPreview = false
    @State private var showFeedbackSheet = false
    @State private var showSettings = false
    @State private var showPDFPicker = false
    @State private var isImporting = false
    @State private var importError: String?
    
    @MainActor
    private var mlxService = MLXService()
    @MainActor
    private let aiReviewModel: AIReviewViewModel
    
    private let parsingService = ResumeParsingService()
    
    init() {
        let service = MLXService()
        mlxService = service
        aiReviewModel = AIReviewViewModel(mlxService: service)
    }
    
    private let feedbackSections = [
        "Personal Info", "Skills", "Work Experience", "Projects", "Extracurricular", "Languages",
    ]
    
    private func sectionText(for name: String) -> String {
        guard let model = resumeModel else { return "" }
        switch name {
        case "Personal Info":
            let p = model.resume.personal
            return "\(p?.firstName ?? "") \(p?.lastName ?? ""), \(p?.email ?? ""), \(p?.phone ?? ""), \(p?.address ?? "")"
        case "Skills":
            let skills = model.resume.skills.map { skill in
                skill.category.isEmpty ? skill.name : "\(skill.name) (\(skill.category))"
            }
            return skills.joined(separator: "\n")
        case "Work Experience":
            let experiences = model.resume.experiences.map { "\($0.title), \($0.company): \($0.details)" }
            return experiences.joined(separator: "\n")
        case "Projects":
            let projects = model.resume.projects.map { "\($0.name): \($0.details)" }
            return projects.joined(separator: "\n")
        case "Education":
            let educations = model.resume.educations.map { "\($0.degree) in \($0.field), \($0.school): \($0.details)" }
            return educations.joined(separator: "\n")
        case "Extracurricular":
            let extracurriculars = model.resume.extracurriculars.map { "\($0.title): \($0.details)" }
            return extracurriculars.joined(separator: "\n")
        case "Languages":
            let languages = model.resume.languages.map { "\($0.name) (\($0.proficiency))" }
            return languages.joined(separator: ", ")
        default:
            return ""
        }
    }
    
    private var personalTab: some View {
        if let model = resumeModel {
            AnyView(
                PersonalInfoView(model: model.personalModel, resumeModel: model)
                    .tabItem {
                        Label("Personal", systemImage: "person")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var skillsTab: some View {
        if let model = resumeModel {
            AnyView(
                SkillsListView(model: model.skillsModel, resumeModel: model)
                    .tabItem {
                        Label("Skills", systemImage: "list.bullet")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var experienceTab: some View {
        if let model = resumeModel {
            AnyView(
                ExperienceListView(model: model.experienceModel, resumeModel: model)
                    .tabItem {
                        Label("Experience", systemImage: "briefcase")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var projectsTab: some View {
        if let model = resumeModel {
            AnyView(
                ProjectsListView(model: model.projectsModel, resumeModel: model)
                    .tabItem {
                        Label("Projects", systemImage: "hammer.fill")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var educationTab: some View {
        if let model = resumeModel {
            AnyView(
                EducationListView(model: model.educationModel, resumeModel: model)
                    .tabItem {
                        Label("Education", systemImage: "graduationcap")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var extracurricularTab: some View {
        if let model = resumeModel {
            AnyView(
                ExtracurricularListView(model: model.extracurricularModel, resumeModel: model)
                    .tabItem {
                        Label("Activities", systemImage: "star.fill")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var languagesTab: some View {
        if let model = resumeModel {
            AnyView(
                LanguagesListView(model: model.languageModel, resumeModel: model)
                    .tabItem {
                        Label("Languages", systemImage: "globe")
                    }
            )
        } else {
            AnyView(EmptyView())
        }
    }
    
    var body: some View {
        Group {
            if resumeModel != nil {
                TabView {
                    personalTab
                    skillsTab
                    experienceTab
                    projectsTab
                    educationTab
                    extracurricularTab
                    languagesTab
                }
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            showPreview = true
                        } label: {
                            Label("Preview", systemImage: "doc.text.magnifyingglass")
                        }
                        .accessibilityLabel("Preview")
                        
                        Spacer(minLength: 0)
                        
                        Button {
                            showFeedbackSheet = true
                        } label: {
                            Label("Get Feedback", systemImage: "sparkle.magnifyingglass")
                        }
                        .accessibilityLabel("Get Feedback")
                        
                        Spacer(minLength: 0)
                        
                        Button {
                            showPDFPicker = true
                        } label: {
                            Label("Import PDF", systemImage: "doc.richtext")
                        }
                        .accessibilityLabel("Import PDF Resume")
                        .accessibilityHint("Import your resume as a PDF and auto-fill the app sections.")
                        
                        Spacer(minLength: 0)
                        
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
                .sheet(isPresented: $showPreview) {
                    if let model = resumeModel {
                        ResumePreviewScreen(resume: model.resume)
                    }
                }
                .sheet(isPresented: $showFeedbackSheet) {
                    AIReviewSheet(
                        viewModel: aiReviewModel,
                        sectionOptions: feedbackSections,
                        sectionTextProvider: sectionText
                    )
                }
                .sheet(isPresented: $showSettings) {
                    NavigationStack { ModelManagementView() }
                }
                .sheet(isPresented: $showPDFPicker) {
                    PDFImportPicker { url in
                        showPDFPicker = false
                        if let url = url {
                            importPDF(url: url)
                        }
                    }
                }
                .alert("Import Error", isPresented: Binding(get: { importError != nil }, set: { _ in importError = nil })) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(importError ?? "")
                }
                .overlay {
                    if isImporting {
                        ProgressView("Importing PDF…")
                            .accessibilityLabel("Importing PDF")
                            .accessibilityHint("Please wait while your PDF is processed.")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    }
                }
            } else {
                ProgressView("Loading Resume…")
                    .task {
                        let descriptor = FetchDescriptor<Resume>(sortBy: [SortDescriptor(\.updated, order: .reverse)])
                        if let found = try? context.fetch(descriptor).first {
                            resumeModel = ResumeEditorModel(resume: found, context: context)
                        } else {
                            let newResume = Resume()
                            context.insert(newResume)
                            try? context.save()
                            resumeModel = ResumeEditorModel(resume: newResume, context: context)
                        }
                    }
            }
        }
    }
    
    private func importPDF(url: URL) {
        guard let model = resumeModel else { return }
        isImporting = true
        Task {
            var didStartAccessing = false
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
                isImporting = false
            }
            if url.startAccessingSecurityScopedResource() {
                didStartAccessing = true
            }
            
            do {
                // Step 1: Extract raw text from PDF
                let rawText = try await extractTextFromPDF(url: url)
                if rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw NSError(domain: "PDFImport", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Could not extract text from PDF."])
                }
                
                // Step 2: Use AI to canonicalize/structure the text
                let structuredText = try await parsingService.canonicalize(text: rawText, mlxService: mlxService)
                if structuredText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    throw NSError(domain: "PDFImport", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: "AI failed to process the resume text."])
                }
                
                await MainActor.run {
                    // Get the ModelContext
                    let context = model.context
                    let resume = model.resume
                    
                    // Step 3: Parse the structured text using rule-based parser
                    let sections = parsingService.splitSections(from: structuredText)
                    
                    // --- Personal Info ---
                    let contactSection = sections["contact"] ?? sections["personal information"] ?? ""
                    let contact = parsingService.extractContactInfo(from: contactSection)
                    
                    // Create personal info if it doesn't exist
                    if resume.personal == nil {
                        let personal = PersonalInfo()
                        resume.personal = personal
                    }
                    
                    let pModel = resume.personal!
                    
                    // Handle name parsing properly
                    if let fullName = contact.name {
                        let nameParts = fullName.components(separatedBy: " ")
                        pModel.firstName = nameParts.first ?? ""
                        pModel.lastName = nameParts.dropFirst().joined(separator: " ")
                    }
                    pModel.email = contact.email ?? pModel.email
                    pModel.phone = contact.phone ?? pModel.phone
                    pModel.address = contact.location ?? pModel.address
                    pModel.linkedIn = contact.linkedIn ?? pModel.linkedIn
                    
                    // --- Skills ---
                    let skillsSection = sections["skills"] ?? sections["technical skills"] ?? ""
                    let skillsArray = parsingService.extractSkills(from: skillsSection)
                    
                    for skillName in skillsArray where !skillName.isEmpty {
                        let skill = Skill(name: skillName, category: "")
                        resume.skills.append(skill)  // Add to relationship
                        skill.resume = resume  // Connect to parent - this is important for SwiftData
                        context.insert(skill)  // Insert into context
                    }
                    
                    // --- Experience ---
                    let expSection = sections["experience"] ?? sections["work experience"] ?? sections["employment"] ?? ""
                    let jobs = parsingService.extractExperience(from: expSection)
                    
                    for job in jobs where !job.title.isEmpty && !job.company.isEmpty {
                        let experience = WorkExperience(
                            title: job.title,
                            company: job.company,
                            location: "",
                            startDate: parseDate(job.startDate),
                            endDate: job.endDate?.lowercased() == "present" ? nil : parseDate(job.endDate),
                            isCurrent: job.endDate?.lowercased() == "present",
                            details: job.details
                        )
                        resume.experiences.append(experience)  // Add to relationship
                        experience.resume = resume  // Connect to parent
                        context.insert(experience)  // Insert into context
                    }
                    
                    // --- Education ---
                    let eduSection = sections["education"] ?? sections["academic background"] ?? ""
                    let educs = parsingService.extractEducation(from: eduSection)
                    
                    for educ in educs where !educ.institution.isEmpty && !educ.degree.isEmpty {
                        let education = Education(
                            school: educ.institution,
                            degree: educ.degree,
                            field: "",
                            startDate: parseDate(educ.startDate),
                            endDate: parseDate(educ.endDate),
                            grade: "",
                            details: ""
                        )
                        resume.educations.append(education)  // Add to relationship
                        education.resume = resume  // Connect to parent
                        context.insert(education)  // Insert into context
                    }
                    
                    // --- Projects ---
                    let projSection = sections["projects"] ?? ""
                    let projects = parsingService.extractProjects(from: projSection)
                    
                    for proj in projects where !proj.name.isEmpty {
                        let project = Project(
                            name: proj.name,
                            details: proj.details,
                            technologies: proj.technologies,
                            link: proj.link
                        )
                        resume.projects.append(project)  // Add to relationship
                        project.resume = resume  // Connect to parent
                        context.insert(project)  // Insert into context
                    }
                    
                    // --- Extracurriculars ---
                    let extraSection = sections["extracurricular"] ?? sections["activities"] ?? ""
                    let extras = parsingService.extractExtracurriculars(from: extraSection)
                    
                    for extra in extras where !extra.title.isEmpty {
                        let extracurricular = Extracurricular(
                            title: extra.title,
                            organization: extra.organization,
                            details: extra.details
                        )
                        resume.extracurriculars.append(extracurricular)  // Add to relationship
                        extracurricular.resume = resume  // Connect to parent
                        context.insert(extracurricular)  // Insert into context
                    }
                    
                    // --- Languages ---
                    let langSection = sections["languages"] ?? ""
                    let langs = parsingService.extractLanguages(from: langSection)
                    
                    for lang in langs where !lang.name.isEmpty {
                        let language = Language(
                            name: lang.name,
                            proficiency: lang.proficiency.isEmpty ? "Fluent" : lang.proficiency
                        )
                        resume.languages.append(language)  // Add to relationship
                        language.resume = resume  // Connect to parent
                        context.insert(language)  // Insert into context
                    }
                    
                    // Update timestamp
                    resume.updated = Date()
                    
                    // Save all changes
                    do {
                        try context.save()
                        
                        // IMPORTANT: Refresh the view models to reflect the new data
                        model.refreshAllModels()
                    } catch {
                        importError = "Failed to save imported data: \(error.localizedDescription)"
                    }
                }
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                }
            }
        }
    }
            
            // Helper: Parse string date (month year / year) to Date, fallback to .now
            private func parseDate(_ string: String?) -> Date {
                guard let string = string, !string.isEmpty else { return Date() }
                
                // Clean up the date string
                let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "–", with: "-")
                    .replacingOccurrences(of: "—", with: "-")
                    .replacingOccurrences(of: " to ", with: "-")
                
                // Check for "Present" or "Current"
                if cleaned.lowercased().contains("present") || cleaned.lowercased().contains("current") {
                    return Date()
                }
                
                let formats = [
                    "MMM yyyy", "MMMM yyyy", "MM/yyyy", "yyyy",
                    "MMM yy", "MMMM yy", "MM/yy", "yy",
                    "MMM. yyyy", "MMM.yyyy"
                ]
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: cleaned) {
                        return date
                    }
                }
                
                // Try to extract year if all else fails
                if let yearMatch = cleaned.range(of: #"\b(19|20)\d{2}\b"#, options: .regularExpression) {
                    let yearStr = String(cleaned[yearMatch])
                    if let year = Int(yearStr) {
                        var components = DateComponents()
                        components.year = year
                        components.month = 1
                        components.day = 1
                        return Calendar.current.date(from: components) ?? Date()
                    }
                }
                
                return Date()
            }
            
            private func extractTextFromPDF(url: URL) async throws -> String {
                guard let pdf = PDFDocument(url: url) else {
                    throw NSError(domain: "PDFImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF."])
                }
                var fullText = ""
                for i in 0 ..< pdf.pageCount {
                    guard let page = pdf.page(at: i) else { continue }
                    if let text = page.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        fullText += text + "\n"
                    } else if let cgPage = page.pageRef {
                        // Fallback: Use Vision for scanned PDFs
                        let images = cgPage.images
                        for image in images {
                            let handler = VNImageRequestHandler(cgImage: image, options: [:])
                            let request = VNRecognizeTextRequest()
                            try handler.perform([request])
                            let recognized = (request.results)?
                                .compactMap { $0.topCandidates(1).first?.string }
                                .joined(separator: "\n") ?? ""
                            fullText += recognized + "\n"
                        }
                    }
                }
                return fullText
            }
        }
        
        // MARK: - PDF Picker
        
        struct PDFImportPicker: UIViewControllerRepresentable {
            var onPick: (URL?) -> Void
            
            func makeCoordinator() -> Coordinator {
                Coordinator(onPick: onPick)
            }
            
            func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
                let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
                picker.delegate = context.coordinator
                picker.allowsMultipleSelection = false
                return picker
            }
            
            func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
            
            class Coordinator: NSObject, UIDocumentPickerDelegate {
                let onPick: (URL?) -> Void
                init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }
                func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                    onPick(urls.first)
                }
                
                func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
                    onPick(nil)
                }
            }
        }
        
        // AIResumeImport using DTOs
        struct AIResumeImport: Decodable {
            let personal: PersonalInfoDTO
            let skills: [SkillDTO]
            let experiences: [WorkExperienceDTO]
            let projects: [ProjectDTO]
            let extracurriculars: [ExtracurricularDTO]
            let languages: [LanguageDTO]
        }
        
        // MARK: - PDFPage+Images (for Vision fallback)
        
        import CoreGraphics
        
        extension CGPDFPage {
            var images: [CGImage] {
                var images: [CGImage] = []
                let rect = getBoxRect(.mediaBox)
                let renderer = UIGraphicsImageRenderer(size: rect.size)
                let img = renderer.image { ctx in
                    let context = ctx.cgContext
                    context.saveGState()
                    context.translateBy(x: 0, y: rect.size.height)
                    context.scaleBy(x: 1, y: -1)
                    context.drawPDFPage(self)
                    context.restoreGState()
                }
                if let cg = img.cgImage { images.append(cg) }
                return images
            }
        }
        
        // Mapping Extensions
        
        extension PersonalInfo {
            convenience init(dto: PersonalInfoDTO) {
                self.init(
                    firstName: dto.firstName,
                    lastName: dto.lastName,
                    email: dto.email,
                    phone: dto.phone,
                    address: dto.address,
                    linkedIn: dto.linkedIn,
                    website: dto.website,
                    github: dto.github
                )
            }
        }
        
        extension Skill {
            convenience init(dto: SkillDTO) {
                self.init(name: dto.name, category: dto.category)
            }
        }
        
        extension WorkExperience {
            convenience init(dto: WorkExperienceDTO) {
                self.init(
                    title: dto.title,
                    company: dto.company,
                    location: dto.location,
                    startDate: dto.startDate,
                    endDate: dto.endDate,
                    isCurrent: dto.isCurrent,
                    details: dto.details
                )
            }
        }
        
        extension Project {
            convenience init(dto: ProjectDTO) {
                self.init(
                    name: dto.name,
                    details: dto.details,
                    technologies: dto.technologies,
                    link: dto.link
                )
            }
        }
        
        extension Extracurricular {
            convenience init(dto: ExtracurricularDTO) {
                self.init(
                    title: dto.title,
                    organization: dto.organization,
                    details: dto.details
                )
            }
        }
        
        extension Language {
            convenience init(dto: LanguageDTO) {
                self.init(name: dto.name, proficiency: dto.proficiency)
            }
        }
        
        extension Education {
            convenience init(dto: EducationDTO) {
                self.init(
                    school: dto.school,
                    degree: dto.degree,
                    field: dto.field,
                    startDate: dto.startDate,
                    endDate: dto.endDate,
                    grade: dto.grade,
                    details: dto.details
                )
            }
        }
