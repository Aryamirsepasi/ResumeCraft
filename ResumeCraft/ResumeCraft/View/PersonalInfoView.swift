//
//  PersonalInfoView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import Observation

struct PersonalInfoView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel
    @Bindable var model: PersonalInfoModel
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            Form {
                PersonalInfoSectionView(personal: model.personal)
            }
            .navigationTitle("Personal Info")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        // Ensure we open editor with freshest instance
                        showEditor = true
                    }
                    .accessibilityLabel("Edit Personal Info")
                }
            }
            .sheet(isPresented: $showEditor) {
                PersonalInfoEditorView(
                    info: model.personal,
                    onSave: { updated in
                        model.personal.firstName = updated.firstName
                        model.personal.lastName = updated.lastName
                        model.personal.email = updated.email
                        model.personal.phone = updated.phone
                        model.personal.address = updated.address
                        model.personal.linkedIn = updated.linkedIn
                        model.personal.website = updated.website
                        model.personal.github = updated.github
                        showEditor = false
                        do {
                            try resumeModel.save()
                        } catch {
                            print("Error saving: \(error.localizedDescription)")
                        }
                    },
                    onCancel: { showEditor = false }
                )
            }
        }
    }
}

struct PersonalInfoSectionView: View {
    let personal: PersonalInfo

    var body: some View {
        Section("Name") {
            Text(personal.firstName)
                .accessibilityLabel("First Name")
            Text(personal.lastName)
                .accessibilityLabel("Last Name")
        }
        Section("Contact") {
            Text(personal.email)
                .accessibilityLabel("Email")
            Text(personal.phone)
                .accessibilityLabel("Phone")
            Text(personal.address)
                .accessibilityLabel("Address")
        }
        Section("Links") {
            if let linkedIn = personal.linkedIn, !linkedIn.isEmpty {
                Text(linkedIn).accessibilityLabel("LinkedIn")
            }
            if let website = personal.website, !website.isEmpty {
                Text(website).accessibilityLabel("Website")
            }
            if let github = personal.github, !github.isEmpty {
                Text(github).accessibilityLabel("GitHub")
            }
        }
    }
}
