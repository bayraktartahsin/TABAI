import Foundation

struct TABAIModelsEnvelope: Codable {
    let data: [TABAIModelDTO]
}

struct TABAIModelDTO: Codable {
    let id: String
    let name: String?
}
