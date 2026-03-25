import Foundation

protocol ModelsServiceProtocol {
    func fetchModels() async throws -> [ModelCatalog.Model]
}
