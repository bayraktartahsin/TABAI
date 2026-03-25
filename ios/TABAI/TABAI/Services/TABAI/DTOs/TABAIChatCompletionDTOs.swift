import Foundation

struct TABAIChatCompletionRequest: Codable {
    let model: String
    let stream: Bool
    let messages: [TABAIChatCompletionMessage]
}

struct TABAIChatCompletionMessage: Codable {
    let role: String
    let content: String
}

struct TABAIChatCompletionResponse: Codable {
    let choices: [TABAIChatCompletionChoice]
}

struct TABAIChatCompletionChoice: Codable {
    let message: TABAIChatCompletionMessage
}

struct TABAIStreamRequest: Codable {
    let token: String?
    let model: String
    let messages: [TABAIChatCompletionMessage]
    let attachments: [TABAIStreamAttachment]?
}

struct TABAIStreamAttachment: Codable {
}

struct TABAIStreamTokenEvent: Codable {
    let delta: String
}

struct TABAIStreamDoneEvent: Codable {
    let messageId: String?
    let finishReason: String?
    let chatId: String?
}

struct TABAIStreamErrorEvent: Codable {
    let message: String
}

struct TABAIStreamMetadataEvent: Codable {
    let poweredBy: String?
    let routeReason: String?
}
