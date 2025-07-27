//
//  LanguageModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation

@Observable
final class LanguageModel {
    var items: [Language]
    private weak var resume: Resume?

    init(resume: Resume) {
        self.resume = resume
        self.items = resume.languages
    }
    func add(_ language: Language) {
        items.append(language)
    }
    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    func update(_ language: Language, at index: Int) {
        guard items.indices.contains(index) else { return }
        items[index] = language
    }
}
