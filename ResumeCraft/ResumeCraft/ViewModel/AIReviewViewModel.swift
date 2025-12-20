import Foundation
import SwiftUI

@MainActor
@Observable
final class AIReviewViewModel {
    private let ai: any AIProvider

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
    
    func requestFeedback(resumeText: String) async {
        isGenerating = true
        isStreaming = true
        feedback = nil
        streamingFeedback = ""
        errorMessage = nil

        let focusLine = focusTags.isEmpty ? "" : """
        
        Bitte achte besonders auf diese Bereiche:
        \(focusTags.map { "- \($0)" }.joined(separator: "\n"))
        """

        let prompt = """
        Du bist ein:e Expert:in für Lebenslauf-Reviews mit Fokus auf ATS-Optimierung und Karriere-Coaching.
        
        Analysiere den folgenden Lebenslauf im Vergleich zur Stellenbeschreibung und gib konkrete, umsetzbare Hinweise.
        
        Strukturiere deine Antwort mit:
        
        ## Stärken
        - Was an diesem Lebenslauf gut funktioniert
        
        ## Verbesserungsbereiche
        - Konkrete Punkte, die angepasst werden sollten
        - Achte auf Klarheit, Wirkung und ATS-Kompatibilität
        
        ## Vorschläge zur Überarbeitung
        - Gib „vorher → nachher“-Beispiele für wichtige Verbesserungen
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

        do {
            // Try streaming first (better UX)
            let result = try await ai.processText(
                systemPrompt: """
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
                """,
                userPrompt: prompt,
                images: [],
                streaming: true  // Enable streaming for better UX
            )
            
            if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw NSError(
                    domain: "AIReview",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Es wurde kein Feedback erzeugt. Bitte versuche es erneut."]
                )
            }
            
            feedback = result
            streamingFeedback = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
        isStreaming = false
    }
    
    /// Request feedback with true streaming support (if AI provider supports it)
    func requestFeedbackStreaming(resumeText: String) async {
        // This would require updating AIProvider protocol to support AsyncSequence
        // For now, this is a placeholder for future enhancement
        isGenerating = true
        isStreaming = true
        feedback = nil
        streamingFeedback = ""
        errorMessage = nil
        
        // Implementation would stream tokens as they arrive
        // streamingFeedback would update in real-time
        
        isGenerating = false
        isStreaming = false
    }
}
