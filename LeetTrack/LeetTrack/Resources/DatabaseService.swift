import Foundation
import MongoDBService
import Combine

/// View-model that owns your MongoDBService and publishes the list of DB names
final class DatabaseViewModel: ObservableObject {
  @Published var databaseNames: [String] = []
  @Published var errorMessage: String? = nil

  private let service: MongoDBService

  init() {
    do {
      self.service = try MongoDBService()
      fetchDatabases()
    } catch {
      self.errorMessage = "Failed to init MongoDBService: \(error)"
      self.service = try! MongoDBService() // to satisfy non-optional, won't actually run
    }
  }

  private func fetchDatabases() {
    Task {
      do {
        let names = try await service.listDatabases()
        // switch back to main thread to update @Published
        await MainActor.run {
          self.databaseNames = names
        }
      } catch {
        await MainActor.run {
          self.errorMessage = "Error listing DBs: \(error)"
        }
      }
    }
  }
}
