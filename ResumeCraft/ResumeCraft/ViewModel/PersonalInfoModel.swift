//
//  PersonalInfoModel.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//
import SwiftUI

@Observable
final class PersonalInfoModel {
    var personal: PersonalInfo

    init(personal: PersonalInfo) {
        self.personal = personal
    }
}
