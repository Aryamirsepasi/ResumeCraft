import XCTest

@testable import ResumeCraft

@MainActor
final class ResumeScoringTests: XCTestCase {
    func testEnglishLanguageContentContributesToCompletenessAndQualityScoring() throws {
        let resume = Resume()
        resume.contentLanguage = .english

        let summary = Summary()
        summary.setText(
            "Experienced strategic iOS engineer who led SwiftUI platform work, built reliable document workflows, delivered measurable product improvements, and collaborated across design, engineering, and product teams.",
            for: .english
        )
        resume.summary = summary

        let experience = WorkExperience()
        experience.setTitle("Senior iOS Engineer", for: .english)
        experience.setCompany("Acme GmbH", for: .english)
        experience.setDetails(
            "Led a SwiftUI migration that improved release stability by 35% within six months.\nDelivered PDF import and export workflows used by thousands of resume authors.",
            for: .english
        )
        resume.experiences = [experience]

        let score = ResumeScoringEngine.calculate(for: resume)

        let completeness = try XCTUnwrap(score.categoryScores.first { $0.category == .completeness })
        let summaryCompleteness = try XCTUnwrap(
            completeness.details.first { $0.criterion == "Professionelle Zusammenfassung" }
        )
        let experienceCompleteness = try XCTUnwrap(
            completeness.details.first { $0.criterion == "Berufserfahrung" }
        )

        XCTAssertGreaterThan(summaryCompleteness.points, 0)
        XCTAssertGreaterThan(experienceCompleteness.points, 10)

        let contentQuality = try XCTUnwrap(score.categoryScores.first { $0.category == .contentQuality })
        let summaryQuality = try XCTUnwrap(
            contentQuality.details.first { $0.criterion == "Qualität der Zusammenfassung" }
        )
        XCTAssertGreaterThan(summaryQuality.points, 10)
    }
}
