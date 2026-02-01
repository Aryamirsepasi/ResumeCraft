import Foundation

enum ResumeDateFormatters {
  static let resumeMonthYearDE: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yyyy"
    formatter.locale = Locale(identifier: "de_DE")
    return formatter
  }()

  static let resumeMonthYearEN: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yyyy"
    formatter.locale = Locale(identifier: "en_US")
    return formatter
  }()
}

extension DateFormatter {
  static func resumeMonthYear(for language: ResumeLanguage) -> DateFormatter {
    switch language {
    case .german:
      return ResumeDateFormatters.resumeMonthYearDE
    case .english:
      return ResumeDateFormatters.resumeMonthYearEN
    }
  }
}
