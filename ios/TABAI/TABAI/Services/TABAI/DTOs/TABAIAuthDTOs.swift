import Foundation

struct TABAISignInRequest: Codable {
    let email: String
    let password: String
}

struct TABAISignInResponse: Codable {
    let token: String?
    let accessToken: String?

    enum CodingKeys: String, CodingKey {
        case token
        case accessToken = "access_token"
    }
}

struct TABAIMeResponse: Codable {
    let id: String?
    let email: String?
    let name: String?
    let role: String?
}

struct TABAIMeEnvelope: Codable {
    let data: TABAIMeResponse
}
