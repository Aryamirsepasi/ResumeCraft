import SwiftData
import XCTest

@testable import ResumeCraft

@MainActor
final class SwiftDataDeletionTests: XCTestCase {
    func testRemovingSkillDeletesPersistedChildObject() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let resume = Resume()
        context.insert(resume)

        let model = SkillsModel(resume: resume, context: context)
        model.add(Skill(name: "Swift", category: "iOS"))
        try context.save()

        model.remove(at: IndexSet(integer: 0))
        try context.save()

        let remainingSkills = try context.fetch(FetchDescriptor<Skill>())
        XCTAssertEqual(remainingSkills.count, 0)
        XCTAssertEqual(model.items.count, 0)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Resume.self,
            PersonalInfo.self,
            Summary.self,
            WorkExperience.self,
            Project.self,
            Skill.self,
            Education.self,
            Extracurricular.self,
            Language.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
