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
        feedback = nil
        errorMessage = nil

        let focusLine = focusTags.isEmpty ? "" : """
        
        Pay special attention to these areas:
        \(focusTags.map { "- \($0)" }.joined(separator: "\n"))
        """

        let prompt = """
        You are an expert resume reviewer specializing in ATS optimization and career coaching.
        
        Analyze the following resume against the job description and provide specific, actionable feedback.
        
        Structure your response with:
        
        ## Strengths
        - What's working well in this resume
        
        ## Areas for Improvement  
        - Specific issues that need addressing
        - Consider clarity, impact, and ATS compatibility
        
        ## Suggested Rewrites
        - Provide "before → after" examples for key improvements
        - Focus on impact, metrics, and action verbs
        - Ensure ATS compatibility
        
        ## Keywords to Add
        - List relevant keywords from the job description that are missing
        - Suggest where to incorporate them naturally
        
        \(focusLine)
        
        Full Resume:
        \(resumeText)
        
        Job Description:
        \(jobDescription)
        
        Guidelines:
        - Be specific and constructive
        - Use bullet points for clarity
        - Provide concrete examples, not generic advice
        - Focus on measurable improvements
        - Consider the overall narrative and flow
        - Ensure consistency in formatting and style
        - Keep suggestions concise and actionable
        """

        do {
            let result = try await ai.processText(
                systemPrompt: """
                You are a professional resume coach with expertise in:
                - ATS (Applicant Tracking System) optimization
                - Industry-specific keywords and terminology
                - Quantifying achievements with metrics
                - Clear, impactful professional writing
                - Resume structure and formatting best practices
                
                Provide feedback that is:
                1. Specific and actionable
                2. Based on the content provided
                3. Focused on measurable improvements
                4. Constructive and encouraging
                5. Tailored to the specific job description
                
                Format your response in clear Markdown with headers and bullet points.
                """,
                userPrompt: prompt,
                images: [],
                streaming: false
            )
            
            if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw NSError(
                    domain: "AIReview",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No feedback was generated. Please try again."]
                )
            }
            
            feedback = result
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
}
