import XCTest

@testable import ResumeCraft

@MainActor
final class ResumeParsingServiceTests: XCTestCase {
    private let service = ResumeParsingService()

    func testExperienceParserHandlesCanonicalTwoLineAIOutput() {
        let text = """
        Senior iOS Engineer at Acme GmbH
        Berlin | Oct 2022 - Present
        • Led a SwiftUI migration that improved release stability by 35%.
        • Built onboarding and export workflows for thousands of resumes.
        """

        let jobs = service.extractExperience(from: text)

        XCTAssertEqual(jobs.count, 1)
        XCTAssertEqual(jobs.first?.title, "Senior iOS Engineer")
        XCTAssertEqual(jobs.first?.company, "Acme GmbH")
        XCTAssertEqual(jobs.first?.startDate, "Oct 2022")
        XCTAssertEqual(jobs.first?.endDate, "Present")
        XCTAssertTrue(jobs.first?.details.contains("SwiftUI migration") == true)
    }

    func testEducationParserHandlesCanonicalDegreeInstitutionThenDateOutput() {
        let text = """
        M.Sc. Computer Science from TU Berlin
        Oct 2020 - Sep 2022
        Thesis: On-device document understanding for career tools.
        """

        let entries = service.extractEducation(from: text)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.degree, "M.Sc. Computer Science")
        XCTAssertEqual(entries.first?.institution, "TU Berlin")
        XCTAssertEqual(entries.first?.startDate, "Oct 2020")
        XCTAssertEqual(entries.first?.endDate, "Sep 2022")
    }
}
