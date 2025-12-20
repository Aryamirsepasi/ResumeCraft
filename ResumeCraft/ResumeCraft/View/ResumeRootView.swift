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
        ProgressView("Lebenslauf wird geladen…")
          .task { await loadOrCreateResume() }
      }
    }
    .onAppear(perform: setupAIIfNeeded)
  }

  // Split TabView
  private func mainTabs(_ model: ResumeEditorModel) -> some View {
    TabView {
      homeTab(model)
        .tabItem { Label("Start", systemImage: "house") }

      aiReviewTab(model)
        .tabItem { Label("KI-Bewertung", systemImage: "sparkles") }
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
    let found = (try? context.fetch(descriptor)) ?? []
    if let primary = found.first {
      let merged = mergeResumesIfNeeded(primary: primary, others: Array(found.dropFirst()))
      migrateGermanFieldsIfNeeded(for: merged)
      resumeModel = ResumeEditorModel(resume: merged, context: context)
      scheduleMergeCheck()
    } else {
      let newResume = Resume()
      context.insert(newResume)
      try? context.save()
      resumeModel = ResumeEditorModel(resume: newResume, context: context)
    }
  }

  @MainActor
  private func scheduleMergeCheck() {
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      let descriptor = FetchDescriptor<Resume>(
        sortBy: [SortDescriptor(\.updated, order: .reverse)]
      )
      let refreshed = (try? context.fetch(descriptor)) ?? []
      guard let primary = refreshed.first, refreshed.count > 1 else { return }
      let merged = mergeResumesIfNeeded(primary: primary, others: Array(refreshed.dropFirst()))
      migrateGermanFieldsIfNeeded(for: merged)
      if resumeModel?.resume.id != merged.id {
        resumeModel = ResumeEditorModel(resume: merged, context: context)
      } else {
        resumeModel?.refreshAllModels()
      }
    }
  }

  @MainActor
  private func mergeResumesIfNeeded(primary: Resume, others: [Resume]) -> Resume {
    guard !others.isEmpty else { return primary }

    for resume in others {
      mergeResumeData(from: resume, into: primary)
      context.delete(resume)
    }

    primary.updated = .now
    dedupeAllSections(of: primary)
    try? context.save()
    return primary
  }

  private func mergeResumeData(from source: Resume, into target: Resume) {
    if let sourcePersonal = source.personal {
      if let targetPersonal = target.personal {
        if targetPersonal.firstName.isEmpty { targetPersonal.firstName = sourcePersonal.firstName }
        if targetPersonal.lastName.isEmpty { targetPersonal.lastName = sourcePersonal.lastName }
        if targetPersonal.email.isEmpty { targetPersonal.email = sourcePersonal.email }
        if targetPersonal.phone.isEmpty { targetPersonal.phone = sourcePersonal.phone }
        if targetPersonal.address.isEmpty { targetPersonal.address = sourcePersonal.address }
        if targetPersonal.linkedIn == nil { targetPersonal.linkedIn = sourcePersonal.linkedIn }
        if targetPersonal.website == nil { targetPersonal.website = sourcePersonal.website }
        if targetPersonal.github == nil { targetPersonal.github = sourcePersonal.github }
      } else {
        sourcePersonal.resume = target
        target.personal = sourcePersonal
      }
    }

    if let sourceSummary = source.summary {
      if let targetSummary = target.summary {
        if targetSummary.text.isEmpty { targetSummary.text = sourceSummary.text }
        targetSummary.isVisible = targetSummary.isVisible || sourceSummary.isVisible
      } else {
        sourceSummary.resume = target
        target.summary = sourceSummary
      }
    }

    if let sourceSkills = source.skills {
      var targetSkills = target.skills ?? []
      for item in sourceSkills {
        item.resume = target
        targetSkills.append(item)
      }
      target.skills = targetSkills
    }

    if let sourceExperiences = source.experiences {
      var targetExperiences = target.experiences ?? []
      for item in sourceExperiences {
        item.resume = target
        targetExperiences.append(item)
      }
      target.experiences = targetExperiences
    }

    if let sourceProjects = source.projects {
      var targetProjects = target.projects ?? []
      for item in sourceProjects {
        item.resume = target
        targetProjects.append(item)
      }
      target.projects = targetProjects
    }

    if let sourceEducations = source.educations {
      var targetEducations = target.educations ?? []
      for item in sourceEducations {
        item.resume = target
        targetEducations.append(item)
      }
      target.educations = targetEducations
    }

    if let sourceExtracurriculars = source.extracurriculars {
      var targetExtras = target.extracurriculars ?? []
      for item in sourceExtracurriculars {
        item.resume = target
        targetExtras.append(item)
      }
      target.extracurriculars = targetExtras
    }

    if let sourceLanguages = source.languages {
      var targetLanguages = target.languages ?? []
      for item in sourceLanguages {
        item.resume = target
        targetLanguages.append(item)
      }
      target.languages = targetLanguages
    }
  }

  @MainActor
  private func migrateGermanFieldsIfNeeded(for resume: Resume) {
    var didChange = false

    if let summary = resume.summary {
      if let textDe = summary.text_de, !textDe.isEmpty {
        if summary.text.isEmpty {
          summary.text = textDe
        }
        summary.text_de = nil
        didChange = true
      }
    }

    for exp in resume.experiences ?? [] {
      if let value = exp.title_de, !value.isEmpty {
        if exp.title.isEmpty { exp.title = value }
        exp.title_de = nil
        didChange = true
      }
      if let value = exp.company_de, !value.isEmpty {
        if exp.company.isEmpty { exp.company = value }
        exp.company_de = nil
        didChange = true
      }
      if let value = exp.location_de, !value.isEmpty {
        if exp.location.isEmpty { exp.location = value }
        exp.location_de = nil
        didChange = true
      }
      if let value = exp.details_de, !value.isEmpty {
        if exp.details.isEmpty { exp.details = value }
        exp.details_de = nil
        didChange = true
      }
    }

    for proj in resume.projects ?? [] {
      if let value = proj.name_de, !value.isEmpty {
        if proj.name.isEmpty { proj.name = value }
        proj.name_de = nil
        didChange = true
      }
      if let value = proj.details_de, !value.isEmpty {
        if proj.details.isEmpty { proj.details = value }
        proj.details_de = nil
        didChange = true
      }
      if let value = proj.technologies_de, !value.isEmpty {
        if proj.technologies.isEmpty { proj.technologies = value }
        proj.technologies_de = nil
        didChange = true
      }
    }

    for skill in resume.skills ?? [] {
      if let value = skill.name_de, !value.isEmpty {
        if skill.name.isEmpty { skill.name = value }
        skill.name_de = nil
        didChange = true
      }
      if let value = skill.category_de, !value.isEmpty {
        if skill.category.isEmpty { skill.category = value }
        skill.category_de = nil
        didChange = true
      }
    }

    for edu in resume.educations ?? [] {
      if let value = edu.school_de, !value.isEmpty {
        if edu.school.isEmpty { edu.school = value }
        edu.school_de = nil
        didChange = true
      }
      if let value = edu.degree_de, !value.isEmpty {
        if edu.degree.isEmpty { edu.degree = value }
        edu.degree_de = nil
        didChange = true
      }
      if let value = edu.field_de, !value.isEmpty {
        if edu.field.isEmpty { edu.field = value }
        edu.field_de = nil
        didChange = true
      }
      if let value = edu.details_de, !value.isEmpty {
        if edu.details.isEmpty { edu.details = value }
        edu.details_de = nil
        didChange = true
      }
    }

    for extra in resume.extracurriculars ?? [] {
      if let value = extra.title_de, !value.isEmpty {
        if extra.title.isEmpty { extra.title = value }
        extra.title_de = nil
        didChange = true
      }
      if let value = extra.organization_de, !value.isEmpty {
        if extra.organization.isEmpty { extra.organization = value }
        extra.organization_de = nil
        didChange = true
      }
      if let value = extra.details_de, !value.isEmpty {
        if extra.details.isEmpty { extra.details = value }
        extra.details_de = nil
        didChange = true
      }
    }

    for lang in resume.languages ?? [] {
      if let value = lang.name_de, !value.isEmpty {
        if lang.name.isEmpty { lang.name = value }
        lang.name_de = nil
        didChange = true
      }
      if let value = lang.proficiency_de, !value.isEmpty {
        if lang.proficiency.isEmpty { lang.proficiency = value }
        lang.proficiency_de = nil
        didChange = true
      }
      lang.proficiency = normalizeProficiency(lang.proficiency)
    }

    if didChange {
      resume.updated = .now
      try? context.save()
    }
  }

  private func normalizeProficiency(_ value: String) -> String {
    let normalized = norm(value)
    switch normalized {
    case "native":
      return "Muttersprache"
    case "fluent":
      return "Fließend"
    case "professional":
      return "Beruflich"
    case "intermediate":
      return "Fortgeschritten"
    case "basic":
      return "Grundkenntnisse"
    default:
      return value
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
              NSLocalizedDescriptionKey: "Text konnte nicht aus dem PDF extrahiert werden.",
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
                "Die KI konnte den Lebenslauftext nicht verarbeiten.",
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
        userInfo: [NSLocalizedDescriptionKey: "PDF konnte nicht geöffnet werden."]
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
        proficiency: lang.proficiency.isEmpty ? "Fließend" : lang.proficiency
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
      importError = "Importierte Daten konnten nicht gespeichert werden: \(error.localizedDescription)"
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
    let lowered = cleaned.lowercased()
    if lowered.contains("present")
      || lowered.contains("current")
      || lowered.contains("heute")
      || lowered.contains("aktuell")
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
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    let locales = [Locale(identifier: "en_US_POSIX"), Locale(identifier: "de_DE")]

    for locale in locales {
      formatter.locale = locale
      for format in formats {
        formatter.dateFormat = format
        if let date = formatter.date(from: cleaned) {
          return date
        }
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
      "muttersprache": 5,
      "fließend": 4,
      "fliessend": 4,
      "beruflich": 3,
      "fortgeschritten": 2,
      "grundkenntnisse": 1,
      "grundkenntnis": 1,
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
        formatter.locale = Locale(identifier: "de_DE")
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
    let name = dto.name.isEmpty ? (dto.name_de ?? "") : dto.name
    let category = dto.category.isEmpty ? (dto.category_de ?? "") : dto.category
    self.init(name: name, category: category)
    self.isVisible = dto.isVisible
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
    let title = dto.title.isEmpty ? (dto.title_de ?? "") : dto.title
    let organization = dto.organization.isEmpty ? (dto.organization_de ?? "") : dto.organization
    let details = dto.details.isEmpty ? (dto.details_de ?? "") : dto.details
    self.init(
      title: title,
      organization: organization,
      details: details
    )
    self.isVisible = dto.isVisible
  }
}

extension Language {
  convenience init(dto: LanguageDTO) {
    let name = dto.name.isEmpty ? (dto.name_de ?? "") : dto.name
    let rawProficiency = dto.proficiency.isEmpty ? (dto.proficiency_de ?? "") : dto.proficiency
    let proficiency = rawProficiency.isEmpty ? "Fließend" : rawProficiency
    self.init(name: name, proficiency: proficiency)
    self.isVisible = dto.isVisible
  }
}

extension Education {
  convenience init(dto: EducationDTO) {
    let school = dto.school.isEmpty ? (dto.school_de ?? "") : dto.school
    let degree = dto.degree.isEmpty ? (dto.degree_de ?? "") : dto.degree
    let field = dto.field.isEmpty ? (dto.field_de ?? "") : dto.field
    let details = dto.details.isEmpty ? (dto.details_de ?? "") : dto.details
    self.init(
      school: school,
      degree: degree,
      field: field,
      startDate: dto.startDate,
      endDate: dto.endDate,
      grade: dto.grade,
      details: details
    )
    self.isVisible = dto.isVisible
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
        "Fehler",
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
          ProgressView("PDF wird importiert…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.2))
        }
      }
  }
}
