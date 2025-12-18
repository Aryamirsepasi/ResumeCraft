import Foundation
import Observation

@MainActor
@Observable
final class PersistenceStatus {
  enum Backend: Equatable {
    case cloudKit(containerIdentifier: String)
    case local
    case inMemory
  }

  var backend: Backend
  var cloudKitInitializationError: String?
  var localInitializationError: String?

  init(
    backend: Backend,
    cloudKitInitializationError: String? = nil,
    localInitializationError: String? = nil
  ) {
    self.backend = backend
    self.cloudKitInitializationError = cloudKitInitializationError
    self.localInitializationError = localInitializationError
  }

  var isCloudKitEnabled: Bool {
    if case .cloudKit = backend { return true }
    return false
  }

  var buildConfiguration: String {
    #if DEBUG
      return "Debug"
    #else
      return "Release"
    #endif
  }
}
