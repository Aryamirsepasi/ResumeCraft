//
//  ResumeComparison.swift
//  ResumeCraft
//
//  Compare resume versions to see changes over time
//

import Foundation
import SwiftData

struct ResumeSnapshot: Codable, Identifiable {
    let id: UUID
    let date: Date
    let personalInfoSnapshot: String
    let summarySnapshot: String
    let sectionsCount: SectionCounts
    let totalWordCount: Int
    
    struct SectionCounts: Codable {
        let experiences: Int
        let projects: Int
        let skills: Int
        let educations: Int
        let languages: Int
        let extracurriculars: Int
    }
}

extension ResumeSnapshot {
    /// Create a snapshot from the current resume state
    static func capture(from resume: Resume) -> ResumeSnapshot {
        let personalText = "\(resume.personal?.firstName ?? "") \(resume.personal?.lastName ?? "")"
        let summaryText = resume.summary?.text ?? ""
        
        let counts = SectionCounts(
            experiences: (resume.experiences ?? []).filter(\.isVisible).count,
            projects: (resume.projects ?? []).filter(\.isVisible).count,
            skills: (resume.skills ?? []).filter(\.isVisible).count,
            educations: (resume.educations ?? []).filter(\.isVisible).count,
            languages: (resume.languages ?? []).filter(\.isVisible).count,
            extracurriculars: (resume.extracurriculars ?? []).filter(\.isVisible).count
        )
        
        let fullText = ResumeTextFormatter.plainText(for: resume)
        let wordCount = fullText.split(separator: " ").count
        
        return ResumeSnapshot(
            id: UUID(),
            date: Date(),
            personalInfoSnapshot: personalText,
            summarySnapshot: summaryText,
            sectionsCount: counts,
            totalWordCount: wordCount
        )
    }
}

/// Stores and manages resume version history
@Model
final class ResumeHistory {
    var resumeIdString: String = ""
    private var snapshotsBlob: Data = Data()
    
    init(resumeIdString: String) {
        self.resumeIdString = resumeIdString
    }

    var snapshots: [ResumeSnapshot] {
        get {
            guard !snapshotsBlob.isEmpty else { return [] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode([ResumeSnapshot].self, from: snapshotsBlob)) ?? []
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            snapshotsBlob = (try? encoder.encode(newValue)) ?? Data()
        }
    }
    
    func addSnapshot(_ snapshot: ResumeSnapshot) {
        var current = snapshots
        current.append(snapshot)
        
        // Keep only last 20 snapshots
        if current.count > 20 {
            current.removeFirst(current.count - 20)
        }

        snapshots = current
    }
}

struct ResumeComparisonResult {
    let added: Changes
    let removed: Changes
    let modified: Changes
    let statistics: ComparisonStats
    
    struct Changes {
        var experiences: [String] = []
        var projects: [String] = []
        var skills: [String] = []
        var educations: [String] = []
    }
    
    struct ComparisonStats {
        let wordCountDelta: Int
        let sectionsDelta: Int
        let daysApart: Int
        
        var improvementSuggestion: String {
            if wordCountDelta > 50 {
                return "Der Lebenslauf ist deutlich umfangreicher geworden. Erwäge, auf 1–2 Seiten zu kürzen."
            } else if wordCountDelta < -50 {
                return "Der Lebenslauf ist kürzer geworden. Stelle sicher, dass zentrale Erfolge hervorgehoben werden."
            } else if sectionsDelta > 0 {
                return "Gut! Du hast weitere Inhaltsabschnitte ergänzt."
            } else {
                return "Die Länge des Lebenslaufs ist stabil."
            }
        }
    }
}

extension ResumeSnapshot {
    func compare(with other: ResumeSnapshot) -> ResumeComparisonResult {
        let wordDelta = self.totalWordCount - other.totalWordCount
        let sectionsDelta = (
            self.sectionsCount.experiences +
            self.sectionsCount.projects +
            self.sectionsCount.skills +
            self.sectionsCount.educations
        ) - (
            other.sectionsCount.experiences +
            other.sectionsCount.projects +
            other.sectionsCount.skills +
            other.sectionsCount.educations
        )
        
        let daysApart = Calendar.current.dateComponents([.day], from: other.date, to: self.date).day ?? 0
        
        let stats = ResumeComparisonResult.ComparisonStats(
            wordCountDelta: wordDelta,
            sectionsDelta: sectionsDelta,
            daysApart: daysApart
        )
        
        return ResumeComparisonResult(
            added: .init(),
            removed: .init(),
            modified: .init(),
            statistics: stats
        )
    }
}
