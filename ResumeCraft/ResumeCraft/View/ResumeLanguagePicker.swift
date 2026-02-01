import SwiftUI

struct ResumeLanguagePicker: View {
  let titleKey: LocalizedStringKey
  @Binding var selection: ResumeLanguage

  var body: some View {
    Picker(titleKey, selection: $selection) {
      ForEach(ResumeLanguage.allCases) { language in
        Text(language.displayName).tag(language)
      }
    }
    .pickerStyle(.segmented)
  }
}
