//
//  PersonalInfoEditorView.swift
//  ResumeCraft
//
//  Created by Arya Mirsepasi on 27.07.25.
//

import SwiftUI

struct PersonalInfoEditorView: View {
    @Environment(ResumeEditorModel.self) private var resumeModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var linkedIn: String = ""
    @State private var website: String = ""
    @State private var github: String = ""
    @State private var selectedLanguage: ResumeLanguage = .defaultContent

    let info: PersonalInfo

    var onSave: (PersonalInfo, ResumeLanguage) -> Void
    var onCancel: () -> Void

    init(info: PersonalInfo, onSave: @escaping (PersonalInfo, ResumeLanguage) -> Void, onCancel: @escaping () -> Void) {
        self.info = info
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sprache") {
                    ResumeLanguagePicker(
                        titleKey: "Bearbeitungssprache",
                        selection: $selectedLanguage
                    )
                }
                Section("Name") {
                    TextField("Vorname", text: $firstName)
                    TextField("Nachname", text: $lastName)
                }
                Section("Kontakt") {
                    TextField("E-Mail", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Adresse", text: $address)
                }
                Section("Links") {
                    TextField("LinkedIn (optional)", text: $linkedIn)
                    TextField("Website (optional)", text: $website)
                    TextField("GitHub (optional)", text: $github)
                }
            }
            .navigationTitle("Persönliche Daten bearbeiten")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
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
                        onSave(updated, selectedLanguage)
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onAppear {
                selectedLanguage = resumeModel.resume.contentLanguage
                firstName = info.firstName
                lastName = info.lastName
                email = info.email
                phone = info.phone
                linkedIn = info.linkedIn ?? ""
                website = info.website ?? ""
                github = info.github ?? ""
                loadAddress(for: selectedLanguage)
            }
            .onChange(of: selectedLanguage) { _, newValue in
                resumeModel.resume.contentLanguage = newValue
                try? resumeModel.save()
                loadAddress(for: newValue)
            }
        }
    }

    private func loadAddress(for language: ResumeLanguage) {
        address = info.address(for: language, fallback: nil)
    }
}
