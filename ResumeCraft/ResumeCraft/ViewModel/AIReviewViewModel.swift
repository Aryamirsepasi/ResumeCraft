import Foundation
import SwiftUI

enum AIReviewFocusArea: String, CaseIterable, Identifiable {
    case impactMetrics = "impactMetrics"
    case clarityConciseness = "clarityConciseness"
    case atsOptimization = "atsOptimization"
    case actionVerbs = "actionVerbs"
    case keywords = "keywords"
    case professionalTone = "professionalTone"
    case formatting = "formatting"
    case overallImpression = "overallImpression"

    var id: String { rawValue }

    var localizationKey: String.LocalizationValue {
        switch self {
        case .impactMetrics: return "ai.review.focus.impactMetrics"
        case .clarityConciseness: return "ai.review.focus.clarityConciseness"
        case .atsOptimization: return "ai.review.focus.atsOptimization"
        case .actionVerbs: return "ai.review.focus.actionVerbs"
        case .keywords: return "ai.review.focus.keywords"
        case .professionalTone: return "ai.review.focus.professionalTone"
        case .formatting: return "ai.review.focus.formatting"
        case .overallImpression: return "ai.review.focus.overallImpression"
        }
    }

    func title(for language: ResumeLanguage) -> String {
        String(localized: localizationKey, locale: language.locale)
    }
}

@MainActor
@Observable
final class AIReviewViewModel {
    private let ai: any AIProvider
    private var feedbackTask: Task<Void, Never>?
    private var feedbackTaskID: UUID?

    init(ai: any AIProvider) {
        self.ai = ai
    }

    var jobDescription: String = ""
    var focusTags: [String] = []

    var feedback: String?
    var isGenerating = false
    var errorMessage: String?

    // Streaming support
    var streamingFeedback: String = ""
    var isStreaming = false

    func appendFocus(_ tag: String) {
        if !focusTags.contains(tag) {
            focusTags.append(tag)
        }
    }

    func removeFocus(_ tag: String) {
        focusTags.removeAll { $0 == tag }
    }

    func startFeedback(resumeText: String, language: ResumeLanguage = .defaultContent) {
        cancelFeedback()
        let taskID = UUID()
        feedbackTaskID = taskID
        feedbackTask = Task { [resumeText, language] in
            await requestFeedback(resumeText: resumeText, language: language, taskID: taskID)
            if feedbackTaskID == taskID {
                feedbackTask = nil
                feedbackTaskID = nil
            }
        }
    }

    func cancelFeedback() {
        feedbackTask?.cancel()
        feedbackTask = nil
        feedbackTaskID = nil
        ai.cancel()
        isGenerating = false
        isStreaming = false
    }

    private func requestFeedback(
        resumeText: String,
        language: ResumeLanguage = .defaultContent,
        taskID: UUID? = nil
    ) async {
        isGenerating = true
        isStreaming = true
        feedback = nil
        streamingFeedback = ""
        errorMessage = nil

        let prompts = AIReviewPromptBuilder(
            language: language,
            focusTags: focusTags,
            jobDescription: jobDescription,
            resumeText: resumeText
        )

        do {
            let result = try await ai.processText(
                systemPrompt: prompts.systemPrompt,
                userPrompt: prompts.userPrompt,
                images: [],
                language: language,
                streaming: true
            )
            try Task.checkCancellation()

            if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let message = String(localized: "ai.error.noFeedback", locale: language.locale)
                throw NSError(
                    domain: "AIReview",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
            }

            feedback = result
            streamingFeedback = result
        } catch is CancellationError {
            ai.cancel()
        } catch {
            errorMessage = error.localizedDescription
        }

        if taskID == nil || feedbackTaskID == taskID {
            isGenerating = false
            isStreaming = false
        }
    }

    func requestFeedbackStreaming(resumeText: String, language: ResumeLanguage = .defaultContent) async {
        await requestFeedback(resumeText: resumeText, language: language)
    }
}

/// Builds AI review prompts in the user's selected language.
/// Keeps prompt content out of the ViewModel so adding a new language only
/// requires adding a case here.
private struct AIReviewPromptBuilder {
    let language: ResumeLanguage
    let focusTags: [String]
    let jobDescription: String
    let resumeText: String

    var systemPrompt: String {
        switch language {
        case .english:
            return englishSystemPrompt
        case .german:
            return germanSystemPrompt
        }
    }

    var userPrompt: String {
        switch language {
        case .english:
            return englishUserPrompt
        case .german:
            return germanUserPrompt
        }
    }

    // MARK: - English

    private var englishSystemPrompt: String {
        """
        You are a professional resume coach with expertise in:
        - ATS optimization (Applicant Tracking System)
        - Industry-specific keywords and terminology
        - Quantifying achievements with metrics
        - Clear, impactful professional language
        - Best practices for structure and formatting

        Your feedback is:
        1. Specific and actionable
        2. Aligned with the content provided
        3. Focused on measurable improvements
        4. Constructive and encouraging
        5. Tailored to the specific job description

        Respond in English and format the answer in clean Markdown with headings and bullet points.
        """
    }

    private var englishUserPrompt: String {
        let localizedFocusTags = focusTags.map { tag in
            AIReviewFocusArea(rawValue: tag)?.title(for: .english) ?? tag
        }
        let focusLine: String
        if localizedFocusTags.isEmpty {
            focusLine = ""
        } else {
            let bullets = localizedFocusTags.map { "- \($0)" }.joined(separator: "\n")
            focusLine = "\n\nPlease pay special attention to these areas:\n\(bullets)"
        }

        return """
        You are an expert resume reviewer focused on ATS optimization and career coaching.

        Analyze the following resume against the job description and provide concrete, actionable suggestions.

        Structure your response with:

        ## Strengths
        - What works well in this resume

        ## Areas to Improve
        - Specific points that should be adjusted
        - Focus on clarity, impact, and ATS compatibility

        ## Revision Suggestions
        - Give "before -> after" examples for important improvements
        - Focus on impact, metrics, and action verbs
        - Ensure ATS compatibility

        ## Keywords to Add
        - Name relevant keywords from the job description that are missing
        - Suggest where they can naturally fit
        \(focusLine)

        Full resume:
        \(resumeText)

        Job description:
        \(jobDescription)

        Guidelines:
        - Be specific and constructive
        - Use bullet points for clarity
        - Give concrete examples, not generic advice
        - Focus on measurable improvements
        - Watch the overall narrative and impression
        - Keep formatting and style consistent
        - Keep suggestions short and actionable
        """
    }

    // MARK: - German

    private var germanSystemPrompt: String {
        """
        Du bist ein professioneller Lebenslauf-Coach mit Expertise in:
        - ATS-Optimierung (Applicant Tracking System)
        - Branchenspezifischen Keywords und Terminologie
        - Quantifizierung von Erfolgen mit Kennzahlen
        - Klarer, wirkungsvoller professioneller Sprache
        - Best Practices für Struktur und Formatierung

        Dein Feedback ist:
        1. Spezifisch und umsetzbar
        2. Am bereitgestellten Inhalt ausgerichtet
        3. Auf messbare Verbesserungen fokussiert
        4. Konstruktiv und ermutigend
        5. Auf die konkrete Stellenbeschreibung zugeschnitten

        Antworte auf Deutsch und formatiere die Antwort in sauberem Markdown mit Überschriften und Bulletpoints.
        """
    }

    private var germanUserPrompt: String {
        let localizedFocusTags = focusTags.map { tag in
            AIReviewFocusArea(rawValue: tag)?.title(for: .german) ?? tag
        }
        let focusLine: String
        if localizedFocusTags.isEmpty {
            focusLine = ""
        } else {
            let bullets = localizedFocusTags.map { "- \($0)" }.joined(separator: "\n")
            focusLine = "\n\nBitte achte besonders auf diese Bereiche:\n\(bullets)"
        }

        return """
        Du bist ein:e Expert:in für Lebenslauf-Reviews mit Fokus auf ATS-Optimierung und Karriere-Coaching.

        Analysiere den folgenden Lebenslauf im Vergleich zur Stellenbeschreibung und gib konkrete, umsetzbare Hinweise.

        Strukturiere deine Antwort mit:

        ## Stärken
        - Was an diesem Lebenslauf gut funktioniert

        ## Verbesserungsbereiche
        - Konkrete Punkte, die angepasst werden sollten
        - Achte auf Klarheit, Wirkung und ATS-Kompatibilität

        ## Vorschläge zur Überarbeitung
        - Gib "vorher -> nachher"-Beispiele für wichtige Verbesserungen
        - Fokus auf Wirkung, Kennzahlen und Aktionsverben
        - Stelle ATS-Kompatibilität sicher

        ## Keywords zum Ergänzen
        - Nenne relevante Schlüsselwörter aus der Stellenbeschreibung, die fehlen
        - Schlage vor, wo sie natürlich eingebaut werden können
        \(focusLine)

        Vollständiger Lebenslauf:
        \(resumeText)

        Stellenbeschreibung:
        \(jobDescription)

        Vorgaben:
        - Sei spezifisch und konstruktiv
        - Nutze Bulletpoints für Klarheit
        - Gib konkrete Beispiele, keine allgemeinen Ratschläge
        - Fokus auf messbare Verbesserungen
        - Achte auf den roten Faden und den Gesamteindruck
        - Sorge für konsistentes Format und Stil
        - Halte Vorschläge kurz und umsetzbar
        """
    }
}
