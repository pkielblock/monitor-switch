import Foundation

struct MonitorConfig: Decodable {
    let monitor: String
    let inputs: [Input]
}

struct Input: Decodable, Identifiable {
    let id: String
    let label: String
    let port: String
    let icon: String?
}

struct HTTPError: Error {
    let status: Int
}

/// Client for the monitor-switch server API (see README).
struct API {
    let base: URL

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    /// Accepts `https://host` or `http://192.168.x.x:7580`; returns nil for anything else.
    init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), ["http", "https"].contains(url.scheme), url.host() != nil else {
            return nil
        }
        base = url
    }

    func config() async throws -> MonitorConfig {
        let (data, response) = try await Self.session.data(from: base.appending(path: "api/config"))
        try check(response)
        return try JSONDecoder().decode(MonitorConfig.self, from: data)
    }

    func switchTo(_ id: String) async throws {
        var request = URLRequest(url: base.appending(path: "api/input/\(id)"))
        request.httpMethod = "POST"
        let (_, response) = try await Self.session.data(for: request)
        try check(response)
    }

    private func check(_ response: URLResponse) throws {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw HTTPError(status: status) }
    }
}
