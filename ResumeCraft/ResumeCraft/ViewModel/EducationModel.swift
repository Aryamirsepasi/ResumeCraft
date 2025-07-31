//
//  EducationModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

@Observable
final class EducationModel {
  private weak var resume: Resume?

  init(resume: Resume) {
    self.resume = resume
  }

  var items: [Education] {
    get { resume?.educations ?? [] }
    set { resume?.educations = newValue }
  }

  func add(_ edu: Education) {
    edu.resume = resume
    items.append(edu)
  }

  func remove(at offsets: IndexSet) {
    var copy = items
    copy.remove(atOffsets: offsets)
    items = copy
  }
}
