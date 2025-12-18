//
//  ResumeRootView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 06.08.25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit
import Vision
import CoreGraphics
import FoundationModels


private struct PreviewResume: Identifiable {
  let id = UUID()
  let resume: Resume
}

struct ResumeRootView: View {
  @Environment(\.modelContext) private var context

  // Shared AI dependencies from App environment
  @Environment(FoundationModelProvider.self) private var fmProvider

  @State private var previewResume: PreviewResume?
  @State private var resumeModel: ResumeEditorModel?

  @State private var showPreview = false
  @State private var showSettings = false
  @State private var showPDFPicker = false
  @State private var isImporting = false
  @State private var importError: String?
  @State private var showError = false
  @State private var errorMessage = ""

  @State private var aiReviewModel: AIReviewViewModel?

  private let parsingService = ResumeParsingService()

  var body: some View { content }

  // MARK: - Top-level content split

  private var content: some View {
    Group {
      if let resumeModel {
        mainTabs(resumeModel)
          .modifier(
            Modifiers(
              previewResume: $previewResume,
              showSettings: $showSettings,
              showPDFPicker: $showPDFPicker,
              importError: $importError,
              showError: $showError,
              errorMessage: $errorMessage,
              isImporting: $isImporting,
              importPDF: { url in
                showPDFPicker = false
                if let url { importPDF(url: url) }
              }
            )
          )
          // Ensure sheets (e.g. Settings) can access the same ResumeEditorModel
          .environment(resumeModel)
      } else {
        ProgressView("Loading Resume…")
          .task { await loadOrCreateResume() }
      }
    }
    .onAppear(perform: setupAIIfNeeded)
  }

  // Split TabView
  private func mainTabs(_ model: ResumeEditorModel) -> some View {
    TabView {
      homeTab(model)
        .tabItem { Label("Home", systemImage: "house") }

      aiReviewTab(model)
        .tabItem { Label("AI Review", systemImage: "sparkles") }
    }
  }

  private func homeTab(_ model: ResumeEditorModel) -> some View {
    HomeView(
      openPreview: { presentPreview() },
      importPDF: { showPDFPicker = true },
      openSettings: { showSettings = true }
    )
  }

  private func aiReviewTab(_ model: ResumeEditorModel) -> some View {
    Group {
      if let vm = aiReviewModel {
        AIReviewTabView()
          .environment(vm)
      } else {
        ProgressView()
      }
    }
  }

  // MARK: - Setup

  private func setupAIIfNeeded() {
    if aiReviewModel == nil {
      aiReviewModel = AIReviewViewModel(ai: fmProvider)
    }
  }

  private func presentPreview() {
    if let model = resumeModel {
      previewResume = PreviewResume(resume: model.resume)
    }
  }

  // MARK: - Data bootstrap

  @MainActor
  private func loadOrCreateResume() async {
    let descriptor = FetchDescriptor<Resume>(
      sortBy: [SortDescriptor(\.updated, order: .reverse)]
    )
    if let found = try? context.fetch(descriptor).first {
      resumeModel = ResumeEditorModel(resume: found, context: context)
    } else {
      let newResume = Resume()
      context.insert(newResume)
      try? context.save()
      resumeModel = ResumeEditorModel(resume: newResume, context: context)
    }
  }

  // MARK: - Import

  @MainActor
  private func importPDF(url: URL) {
    guard let model = resumeModel else { return }
    isImporting = true

    Task {
      var didStartAccessing = false
      defer {
        if didStartAccessing { url.stopAccessingSecurityScopedResource() }
        Task { @MainActor in isImporting = false }
      }

      if url.startAccessingSecurityScopedResource() {
        didStartAccessing = true
      }

      do {
        let rawText = try await extractTextFromPDF(url: url)
        if rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          throw NSError(
            domain: "PDFImport",
            code: 2,
            userInfo: [
              NSLocalizedDescriptionKey: "Could not extract text from PDF.",
            ]
          )
        }

        let structuredText = try await parsingService.canonicalize(
          text: rawText,
          ai: fmProvider
        )

        if structuredText.trimmingCharacters(in: .whitespacesAndNewlines)
          .isEmpty
        {
          throw NSError(
            domain: "PDFImport",
            code: 3,
            userInfo: [
              NSLocalizedDescriptionKey:
                "AI failed to process the resume text.",
            ]
          )
        }

        await MainActor.run {
          importStructuredData(structuredText: structuredText, model: model)
        }
        await Task.yield()
      } catch {
        await MainActor.run {
          importError = error.localizedDescription
        }
      }
    }
  }

  private func extractTextFromPDF(url: URL) async throws -> String {
    guard let pdf = PDFDocument(url: url) else {
      throw NSError(
        domain: "PDFImport",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not open PDF."]
      )
    }
    var fullText = ""
    for i in 0..<pdf.pageCount {
      guard let page = pdf.page(at: i) else { continue }
      if let text = page.string,
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        fullText += text + "\n"
      } else if let cgPage = page.pageRef {
        let images = cgPage.images
        for image in images {
          let handler = VNImageRequestHandler(cgImage: image, options: [:])
          let request = VNRecognizeTextRequest()
          try handler.perform([request])
          let recognized =
            (request.results)?
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? ""
          fullText += recognized + "\n"
        }
      }
    }
    return fullText
  }

  @MainActor
  private func importStructuredData(
    structuredText: String,
    model: ResumeEditorModel
  ) {
    let context = model.context
    let resume = model.resume

    let sections = parsingService.splitSections(from: structuredText)

    // Personal Info
    let contactSection =
      sections["contact"] ?? sections["personal information"] ?? ""
    let contact = parsingService.extractContactInfo(from: contactSection)

    if resume.personal == nil {
      let personal = PersonalInfo()
      context.insert(personal)
      resume.personal = personal
      personal.resume = resume
    }

    if let personalInfo = resume.personal {
      if let fullName = contact.name {
        let nameParts = fullName.components(separatedBy: " ")
        personalInfo.firstName = nameParts.first ?? ""
        personalInfo.lastName = nameParts.dropFirst().joined(separator: " ")
      }
      personalInfo.email = contact.email ?? personalInfo.email
      personalInfo.phone = contact.phone ?? personalInfo.phone
      personalInfo.address = contact.location ?? personalInfo.address
      personalInfo.linkedIn = contact.linkedIn ?? personalInfo.linkedIn
      personalInfo.website = contact.website ?? personalInfo.website
      personalInfo.github = contact.github ?? personalInfo.github
    }

    // Summary
    let summarySection =
      sections["summary"] ?? sections["profile"] ?? sections["about"] ?? ""
    let summaryText =
      summarySection.trimmingCharacters(in: .whitespacesAndNewlines)
    if !summaryText.isEmpty {
      if resume.summary == nil {
        let s = Summary(text: summaryText, isVisible: true)
        s.resume = resume
        context.insert(s)
        resume.summary = s
      } else {
        resume.summary?.text = summaryText
        resume.summary?.isVisible = true
      }
    }

    // Skills
    let skillsSection = sections["skills"] ?? sections["technical skills"] ?? ""
    let skillsArray = parsingService.extractSkills(from: skillsSection)
    for skillName in skillsArray where !skillName.isEmpty {
      let skill = Skill(name: skillName, category: "")
      skill.isVisible = true
      context.insert(skill)
      skill.resume = resume
      resume.skills = (resume.skills ?? []) + [skill]
    }

    // Experience
    let expSection = sections["experience"] ?? sections["work experience"] ?? sections["employment"] ?? ""
    let jobs = parsingService.extractExperience(from: expSection)
    for job in jobs where !job.title.isEmpty && !job.company.isEmpty {
      let experience = WorkExperience(
        title: job.title,
        company: job.company,
        location: "",
        startDate: parseDate(job.startDate),
        endDate: job.endDate?.lowercased() == "present" || job.endDate?.lowercased() == "current" ? nil : parseDate(job.endDate),
        isCurrent: job.endDate?.lowercased() == "present" || job.endDate?.lowercased() == "current",
        details: job.details
      )
      experience.isVisible = true
      context.insert(experience)
      experience.resume = resume
      resume.experiences = (resume.experiences ?? []) + [experience]
    }

    // Education
    let eduSection = sections["education"] ?? sections["academic background"] ?? ""
    let educations = parsingService.extractEducation(from: eduSection)
    for educ in educations where !educ.institution.isEmpty && !educ.degree.isEmpty {
      let education = Education(
        school: educ.institution,
        degree: educ.degree,
        field: "",
        startDate: parseDate(educ.startDate),
        endDate: parseDate(educ.endDate),
        grade: "",
        details: ""
      )
      education.isVisible = true
      context.insert(education)
      education.resume = resume
      resume.educations = (resume.educations ?? []) + [education]
    }

    // Projects
    let projSection = sections["projects"] ?? ""
    let projects = parsingService.extractProjects(from: projSection)
    for proj in projects where !proj.name.isEmpty {
      let project = Project(
        name: proj.name,
        details: proj.details,
        technologies: proj.technologies,
        link: proj.link
      )
      project.isVisible = true
      context.insert(project)
      project.resume = resume
      resume.projects = (resume.projects ?? []) + [project]
    }

    // Extracurriculars
    let extraSection = sections["extracurricular"] ?? sections["activities"] ?? ""
    let extras = parsingService.extractExtracurriculars(from: extraSection)
    for extra in extras where !extra.title.isEmpty {
      let extracurricular = Extracurricular(
        title: extra.title,
        organization: extra.organization,
        details: extra.details
      )
      extracurricular.isVisible = true
      context.insert(extracurricular)
      extracurricular.resume = resume
      resume.extracurriculars = (resume.extracurriculars ?? []) + [extracurricular]
    }

    // Languages
    let langSection = sections["languages"] ?? ""
    let languages = parsingService.extractLanguages(from: langSection)
    for lang in languages where !lang.name.isEmpty {
      let language = Language(
        name: lang.name,
        proficiency: lang.proficiency.isEmpty ? "Fluent" : lang.proficiency
      )
      language.isVisible = true
      context.insert(language)
      language.resume = resume
      resume.languages = (resume.languages ?? []) + [language]
    }

    // Update timestamp and dedupe
    resume.updated = Date()
    dedupeAllSections(of: resume)

    do {
      try context.save()
      model.refreshAllModels()
    } catch {
      importError = "Failed to save imported data: \(error.localizedDescription)"
    }
  }

  // Helper: Parse string date (month year / year) to Date, fallback to .now
  private func parseDate(_ string: String?) -> Date {
    guard let string = string, !string.isEmpty else { return Date() }

    // Clean up the date string
    let cleaned = string
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "–", with: "-")
      .replacingOccurrences(of: "—", with: "-")
      .replacingOccurrences(of: " to ", with: "-")

    // Check for "Present" or "Current"
    if cleaned.lowercased().contains("present")
      || cleaned.lowercased().contains("current")
    {
      return Date()
    }

    let formats = [
      "MMM yyyy",
      "MMMM yyyy",
      "MM/yyyy",
      "yyyy",
      "MMM yy",
      "MMMM yy",
      "MM/yy",
      "yy",
      "MMM. yyyy",
      "MMM.yyyy",
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
    if let yearMatch = cleaned.range(
      of: #"\b(19|20)\d{2}\b"#,
      options: .regularExpression
    ) {
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

  // MARK: - Deduplication

  private func dedupeAllSections(of resume: Resume) {
    resume.skills = dedupeSkills(resume.skills ?? [])
    resume.experiences = dedupeExperiences(resume.experiences ?? [])
    resume.projects = dedupeProjects(resume.projects ?? [])
    resume.educations = dedupeEducations(resume.educations ?? [])
    resume.extracurriculars = dedupeExtracurriculars(resume.extracurriculars ?? [])
    resume.languages = dedupeLanguages(resume.languages ?? [])

    // Reset continuous orderIndex across all sections after dedupe
    for (idx, item) in (resume.skills ?? []).enumerated() {
      item.orderIndex = idx
    }
    for (idx, item) in (resume.experiences ?? []).enumerated() {
      item.orderIndex = idx
    }
    for (idx, item) in (resume.projects ?? []).enumerated() {
      item.orderIndex = idx
    }
    for (idx, item) in (resume.educations ?? []).enumerated() {
      item.orderIndex = idx
    }
    for (idx, item) in (resume.extracurriculars ?? []).enumerated() {
      item.orderIndex = idx
    }
    for (idx, item) in (resume.languages ?? []).enumerated() {
      item.orderIndex = idx
    }
  }

  private func norm(_ s: String) -> String {
    s.trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .replacingOccurrences(
        of: #"\s+"#,
        with: " ",
        options: .regularExpression
      )
  }

  private func safeDateKey(_ date: Date?) -> String {
    guard let date else { return "-" }
    return DateFormatter.resumeMonthYear.string(from: date)
  }

  private func joinUniqueLines(_ a: String, _ b: String) -> String {
    if a.isEmpty { return b }
    if b.isEmpty { return a }
    let aLines = Set(a.split(separator: "\n").map { String($0) })
    let bLines = Set(b.split(separator: "\n").map { String($0) })
    let merged = Array(aLines.union(bLines)).sorted()
    return merged.joined(separator: "\n")
  }

  private func dedupeSkills(_ items: [Skill]) -> [Skill] {
    var seen: [String: Skill] = [:]
    var ordered: [Skill] = []
    for item in items {
      let key = norm(item.name) + "|" + norm(item.category)
      if let existing = seen[key] {
        existing.isVisible = existing.isVisible || item.isVisible
      } else {
        seen[key] = item
        ordered.append(item)
      }
    }
    return ordered
  }

  private func dedupeExperiences(_ items: [WorkExperience]) -> [WorkExperience] {
    var seen: [String: WorkExperience] = [:]
    var ordered: [WorkExperience] = []
    for item in items {
      let key = [
        norm(item.title),
        norm(item.company),
        safeDateKey(item.startDate),
      ].joined(separator: "|")

      if let existing = seen[key] {
        existing.isVisible = existing.isVisible || item.isVisible
        existing.details = joinUniqueLines(existing.details, item.details)
        if existing.location.isEmpty { existing.location = item.location }
        existing.isCurrent = existing.isCurrent || item.isCurrent
        if let e1 = existing.endDate, let e2 = item.endDate {
          existing.endDate = max(e1, e2)
        } else if existing.endDate == nil {
          existing.endDate = item.endDate
        }
      } else {
        seen[key] = item
        ordered.append(item)
      }
    }
    return ordered
  }

  private func dedupeProjects(_ items: [Project]) -> [Project] {
    var seen: [String: Project] = [:]
    var ordered: [Project] = []
    for item in items {
      let key = norm(item.name)
      if let existing = seen[key] {
        existing.isVisible = existing.isVisible || item.isVisible
        existing.details = joinUniqueLines(existing.details, item.details)
        let techA = Set(
          existing.technologies.split(separator: ",").map {
            norm(String($0))
          }.filter { !$0.isEmpty }
        )
        let techB = Set(
          item.technologies.split(separator: ",").map {
            norm(String($0))
          }.filter { !$0.isEmpty }
        )
        let mergedTech = Array(techA.union(techB)).sorted()
          .joined(separator: ", ")
        if !mergedTech.isEmpty { existing.technologies = mergedTech }
        if (existing.link ?? "").isEmpty, let link = item.link, !link.isEmpty {
          existing.link = link
        }
      } else {
        seen[key] = item
        ordered.append(item)
      }
    }
    return ordered
  }

  private func dedupeEducations(_ items: [Education]) -> [Education] {
    var seen: [String: Education] = [:]
    var ordered: [Education] = []
    for item in items {
      let key = [
        norm(item.school),
        norm(item.degree),
        safeDateKey(item.startDate),
      ].joined(separator: "|")

      if let existing = seen[key] {
        existing.isVisible = existing.isVisible || item.isVisible
        existing.details = joinUniqueLines(existing.details, item.details)
        if existing.field.isEmpty { existing.field = item.field }
        if existing.grade.isEmpty { existing.grade = item.grade }
        if let e1 = existing.endDate, let e2 = item.endDate {
          existing.endDate = max(e1, e2)
        } else if existing.endDate == nil {
          existing.endDate = item.endDate
        }
      } else {
        seen[key] = item
        ordered.append(item)
      }
    }
    return ordered
  }

  private func dedupeExtracurriculars(_ items: [Extracurricular]) -> [Extracurricular] {
    var seen: [String: Extracurricular] = [:]
    var ordered: [Extracurricular] = []
    for item in items {
      let key = norm(item.title) + "|" + norm(item.organization)
      if let existing = seen[key] {
        existing.isVisible = existing.isVisible || item.isVisible
        existing.details = joinUniqueLines(existing.details, item.details)
      } else {
        seen[key] = item
        ordered.append(item)
      }
    }
    return ordered
  }

  private func dedupeLanguages(_ items: [Language]) -> [Language] {
    var seen: [String: Language] = [:]
    var ordered: [Language] = []
    let rank: [String: Int] = [
      "native": 5,
      "fluent": 4,
      "professional": 3,
      "intermediate": 2,
      "basic": 1,
    ]

    func score(_ s: String) -> Int { rank[norm(s)] ?? 0 }

    for item in items {
      let key = norm(item.name)
      if let existing = seen[key] {
        existing.isVisible = existing.isVisible || item.isVisible
        if score(item.proficiency) > score(existing.proficiency) {
          existing.proficiency = item.proficiency
        }
      } else {
        seen[key] = item
        ordered.append(item)
      }
    }
    return ordered
  }
}

// MARK: - PDF Picker

struct PDFImportPicker: UIViewControllerRepresentable {
  var onPick: (URL?) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onPick: onPick)
  }

  func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [UTType.pdf]
    )
    picker.delegate = context.coordinator
    picker.allowsMultipleSelection = false
    return picker
  }

  func updateUIViewController(
    _: UIDocumentPickerViewController,
    context _: Context
  ) {}

  class Coordinator: NSObject, UIDocumentPickerDelegate {
    let onPick: (URL?) -> Void
    init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }
    func documentPicker(
      _: UIDocumentPickerViewController,
      didPickDocumentsAt urls: [URL]
    ) {
      onPick(urls.first)
    }

    func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
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

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let resumeMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
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
    self.isVisible = dto.isVisible
    self.name_de = dto.name_de
    self.category_de = dto.category_de
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
    self.isVisible = dto.isVisible
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
    self.isVisible = dto.isVisible
  }
}

extension Extracurricular {
  convenience init(dto: ExtracurricularDTO) {
    self.init(
      title: dto.title,
      organization: dto.organization,
      details: dto.details
    )
    self.isVisible = dto.isVisible
    self.title_de = dto.title_de
    self.organization_de = dto.organization_de
    self.details_de = dto.details_de
  }
}

extension Language {
  convenience init(dto: LanguageDTO) {
    self.init(name: dto.name, proficiency: dto.proficiency)
    self.isVisible = dto.isVisible
    self.name_de = dto.name_de
    self.proficiency_de = dto.proficiency_de
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
    self.isVisible = dto.isVisible
    self.school_de = dto.school_de
    self.degree_de = dto.degree_de
    self.field_de = dto.field_de
    self.details_de = dto.details_de
  }
}

private struct Modifiers: ViewModifier {
  @Binding var previewResume: PreviewResume?
  @Binding var showSettings: Bool
  @Binding var showPDFPicker: Bool
  @Binding var importError: String?
  @Binding var showError: Bool
  @Binding var errorMessage: String

  @Binding var isImporting: Bool

  let importPDF: (URL?) -> Void

  func body(content: Content) -> some View {
    content
      .sheet(item: $previewResume) { item in
        ResumePreviewScreen(resume: item.resume)
      }
      .sheet(isPresented: $showSettings) {
        SettingsView()
      }
      .sheet(isPresented: $showPDFPicker) {
        PDFImportPicker { url in importPDF(url) }
      }
      .alert(
        "Error",
        isPresented: Binding(
          get: { importError != nil || showError },
          set: { _ in importError = nil; showError = false }
        )
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(importError ?? errorMessage)
      }
      .overlay {
        if isImporting {
          ProgressView("Importing PDF…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
        }
      }
  }
}
