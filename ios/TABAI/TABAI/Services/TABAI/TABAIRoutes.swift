import Foundation

enum TABAIRoutes {
    static func apiRoot(baseURL: URL) -> URL {
        baseURL.appendingPathComponent("api/owui/api/v1", isDirectory: false)
    }

    static func signIn(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("auths/signin", isDirectory: false)
    }

    static func me(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("auths/me", isDirectory: false)
    }

    static func userMe(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("users/me", isDirectory: false)
    }

    static func userAltMe(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("user/me", isDirectory: false)
    }

    static func models(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("models", isDirectory: false)
    }

    static func chats(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("chats/", isDirectory: false)
    }

    static func chatDetail(baseURL: URL, id: String) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("chats/\(id)", isDirectory: false)
    }

    static func newChat(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("chats/new", isDirectory: false)
    }

    static func chatCompletions(baseURL: URL) -> URL {
        apiRoot(baseURL: baseURL).appendingPathComponent("api/v1/chat/completions", isDirectory: false)
    }

    static func chatStream(baseURL: URL) -> URL {
        baseURL.appendingPathComponent("api/chat/stream", isDirectory: false)
    }
}
