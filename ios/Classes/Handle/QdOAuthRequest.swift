import Foundation

struct QdOAuthRequest {
    let redirect: URLComponents
    let responseType: String
    let state: String?
    enum Invalid: Error { case url, parameters, callback }

    init(_ text: String) throws {
        guard let url = URLComponents(string: text), url.scheme == "https",
              url.host == "oauth.m.taobao.com", url.path == "/authorize",
              url.user == nil, url.password == nil, url.port == nil || url.port == 443 else { throw Invalid.url }
        let params = try Self.parameters(url.queryItems)
        guard let type = params["response_type"], ["code", "token"].contains(type),
              let client = params["client_id"], !client.isEmpty,
              let target = params["redirect_uri"], let redirect = URLComponents(string: target),
              ["https", "http"].contains(redirect.scheme ?? ""), redirect.host != nil,
              redirect.user == nil, redirect.password == nil, redirect.fragment == nil else { throw Invalid.parameters }
        self.redirect = redirect
        responseType = type
        state = params["state"]
        _ = try Self.parameters(redirect.queryItems)
    }

    func readCallback(_ url: URL) throws -> [String: String]? {
        guard let actual = URLComponents(url: url, resolvingAgainstBaseURL: false),
              actual.scheme == redirect.scheme, actual.host == redirect.host,
              Self.port(actual) == Self.port(redirect), actual.path == redirect.path,
              actual.user == nil, actual.password == nil else { return nil }
        var fragment = URLComponents()
        fragment.percentEncodedQuery = actual.percentEncodedFragment
        let params = try Self.parameters((actual.queryItems ?? []) + (fragment.queryItems ?? []))
        for (key, value) in try Self.parameters(redirect.queryItems) where params[key] != value { return nil }
        let key = responseType == "code" ? "code" : "access_token"
        guard !(params[key] ?? "").isEmpty || !(params["error"] ?? "").isEmpty else { return nil }
        if let state = state, params["state"] != state { throw Invalid.callback }
        return params
    }

    static func failingURL(_ error: NSError) -> URL? {
        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL { return url }
        if let text = error.userInfo[NSURLErrorFailingURLStringErrorKey] as? String {
            return URL(string: text)
        }
        return nil
    }

    private static func port(_ value: URLComponents) -> Int { value.port ?? (value.scheme == "https" ? 443 : 80) }
    private static func parameters(_ items: [URLQueryItem]?) throws -> [String: String] {
        var result: [String: String] = [:]
        for item in items ?? [] {
            guard result[item.name] == nil else { throw Invalid.parameters }
            result[item.name] = item.value ?? ""
        }
        return result
    }
}
