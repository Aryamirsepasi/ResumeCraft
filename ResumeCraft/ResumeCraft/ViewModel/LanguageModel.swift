//
//  LanguageModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class LanguageModel {
  private weak var resume: Resume?
  private let context: ModelContext

  init(resume: Resume, context: ModelContext) {
    self.resume = resume
    self.context = context
  }

  var items: [Language] {
    get {
      (resume?.languages ?? []).sorted {
        $0.orderIndex < $1.orderIndex
      }
    }
    set {
      for (idx, item) in newValue.enumerated() { item.orderIndex = idx }
      resume?.languages = newValue
    }
  }

  func add(_ language: Language) {
    language.resume = resume
    language.orderIndex = items.count
    context.insert(language)
    items.append(language)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }

  func update(_ language: Language, at index: Int) {
    guard items.indices.contains(index) else { return }
    language.resume = resume
    var copy = items
    copy[index] = language
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }

  func move(from source: IndexSet, to destination: Int) {
    var copy = items
    copy.move(fromOffsets: source, toOffset: destination)
    for (idx, item) in copy.enumerated() { item.orderIndex = idx }
    items = copy
  }
}
