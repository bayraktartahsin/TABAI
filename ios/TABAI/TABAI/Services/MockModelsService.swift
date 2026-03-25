import Foundation

struct MockModelsService: ModelsServiceProtocol {
    func fetchModels() async throws -> [ModelCatalog.Model] {
        ModelCatalog.load()?.models ?? []
    }
}
