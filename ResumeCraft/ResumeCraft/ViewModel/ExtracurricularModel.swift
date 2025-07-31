//
//  ExtracurricularModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import Foundation
import Observation

@Observable
final class ExtracurricularModel {
  private weak var resume: Resume?

  init(resume: Resume) {
    self.resume = resume
  }

  var items: [Extracurricular] {
    get { resume?.extracurriculars ?? [] }
    set { resume?.extracurriculars = newValue }
  }

  func add(_ activity: Extracurricular) {
    activity.resume = resume
    items.append(activity)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    items = copy
  }

  func update(_ activity: Extracurricular, at index: Int) {
    guard items.indices.contains(index) else { return }
    activity.resume = resume
    var copy = items
    copy[index] = activity
    items = copy
  }
}
