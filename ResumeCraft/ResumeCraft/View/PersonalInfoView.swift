//
//  PersonalInfoView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI
import Observation

struct PersonalInfoView: View {
    @Bindable var model: PersonalInfoModel
    var resumeModel: ResumeEditorModel

    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    Text(model.personal.firstName)
                        .accessibilityLabel("First Name")
                    Text(model.personal.lastName)
                        .accessibilityLabel("Last Name")
                }
                Section("Contact") {
                    Text(model.personal.email)
                        .accessibilityLabel("Email")
                    Text(model.personal.phone)
                        .accessibilityLabel("Phone")
                    Text(model.personal.address)
                        .accessibilityLabel("Address")
                }
                Section("Links") {
                    if let linkedIn = model.personal.linkedIn, !linkedIn.isEmpty {
                        Text(linkedIn).accessibilityLabel("LinkedIn")
                    }
                    if let website = model.personal.website, !website.isEmpty {
                        Text(website).accessibilityLabel("Website")
                    }
                }
            }
            .navigationTitle("Personal Info")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEditor = true }
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
                        showEditor = false
                        try? resumeModel.save()
                    },
                    onCancel: { showEditor = false }
                )
            }
        }
    }
}
