//
//  PersonalInfoEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct PersonalInfoEditorView: View {
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var linkedIn: String
    @State private var website: String
    @State private var github: String

    var onSave: (PersonalInfo) -> Void
    var onCancel: () -> Void

    init(info: PersonalInfo, onSave: @escaping (PersonalInfo) -> Void, onCancel: @escaping () -> Void) {
        _firstName = State(initialValue: info.firstName)
        _lastName = State(initialValue: info.lastName)
        _email = State(initialValue: info.email)
        _phone = State(initialValue: info.phone)
        _address = State(initialValue: info.address)
        _linkedIn = State(initialValue: info.linkedIn ?? "")
        _website = State(initialValue: info.website ?? "")
        _github = State(initialValue: info.github ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                Section("Contact") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $address)
                }
                Section("Links") {
                    TextField("LinkedIn (optional)", text: $linkedIn)
                    TextField("Website (optional)", text: $website)
                    TextField("GitHub (optional)", text: $github)
                }
            }
            .navigationTitle("Edit Personal Info")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = PersonalInfo(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            phone: phone,
                            address: address,
                            linkedIn: linkedIn.isEmpty ? nil : linkedIn,
                            website: website.isEmpty ? nil : website,
                            github: github.isEmpty ? nil : github
                        )
                        onSave(updated)
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
}
