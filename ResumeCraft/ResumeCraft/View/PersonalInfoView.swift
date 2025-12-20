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
    @State private var editingInfo: PersonalInfo?

    var body: some View {
        NavigationStack {
            Form {
                PersonalInfoSectionView(personal: model.personal)
            }
            .navigationTitle("Persönliche Daten")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Bearbeiten") {
                        // Ensure we open editor with freshest instance
                        editingInfo = model.personal
                    }
                    .accessibilityLabel("Persönliche Daten bearbeiten")
                }
            }
            .sheet(item: $editingInfo) { info in
                PersonalInfoEditorView(
                    info: info,
                    onSave: { updated in
                        model.personal.firstName = updated.firstName
                        model.personal.lastName = updated.lastName
                        model.personal.email = updated.email
                        model.personal.phone = updated.phone
                        model.personal.address = updated.address
                        model.personal.linkedIn = updated.linkedIn
                        model.personal.website = updated.website
                        model.personal.github = updated.github
                        editingInfo = nil
                        do {
                            try resumeModel.save()
                        } catch {
                            print("Error saving: \(error.localizedDescription)")
                        }
                    },
                    onCancel: { editingInfo = nil }
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
                .accessibilityLabel("Vorname")
            Text(personal.lastName)
                .accessibilityLabel("Nachname")
        }
        Section("Kontakt") {
            Text(personal.email)
                .accessibilityLabel("E-Mail")
            Text(personal.phone)
                .accessibilityLabel("Telefon")
            Text(personal.address)
                .accessibilityLabel("Adresse")
        }
        Section("Links") {
            if let linkedIn = personal.linkedIn, !linkedIn.isEmpty {
                Text(linkedIn).accessibilityLabel("LinkedIn")
            }
            if let website = personal.website, !website.isEmpty {
                Text(website).accessibilityLabel("Webseite")
            }
            if let github = personal.github, !github.isEmpty {
                Text(github).accessibilityLabel("GitHub")
            }
        }
    }
}
