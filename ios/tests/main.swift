import Foundation
func require(_ value: @autoclosure () throws -> Bool, _ message: String) throws {
    if try !value() { fatalError(message) }
}
let request = try QdOAuthRequest("https://oauth.m.taobao.com/authorize?response_type=code&client_id=123&redirect_uri=https%3A%2F%2Fapi.example.com%2Fcallback&state=test")
try require(try request.readCallback(URL(string: "https://api.example.com/callback?code=a%3Db&state=test")!)?["code"] == "a=b", "decode code")
try require(try request.readCallback(URL(string: "https://evil.example.com/callback?code=a&state=test")!) == nil, "reject other origin")
try require(try request.readCallback(URL(string: "https://api.example.com/other?code=a&state=test")!) == nil, "reject other path")
try require(try request.readCallback(URL(string: "https://api.example.com/callback")!) == nil, "no premature success")
for url in ["https://api.example.com/callback?code=a&state=wrong", "https://api.example.com/callback?code=a&code=b&state=test"] {
    do { _ = try request.readCallback(URL(string: url)!); fatalError("invalid callback accepted") } catch {}
}
try require(try request.readCallback(URL(string: "https://api.example.com/callback?error=access_denied&state=test")!)?["error"] == "access_denied", "denial")
print("OAuth callback tests passed")
let callbackURL = URL(string: "https://api.example.com/callback?code=redirected&state=test")!
for info: [String: Any] in [
    [NSURLErrorFailingURLErrorKey: callbackURL],
    [NSURLErrorFailingURLStringErrorKey: callbackURL.absoluteString]
] {
    let error = NSError(domain: "WebKitErrorDomain", code: 102, userInfo: info)
    try require(try request.readCallback(QdOAuthRequest.failingURL(error)!)?["code"] == "redirected", "recover blocked OAuth redirect")
}
let unrelated = NSError(domain: "WebKitErrorDomain", code: 102,
    userInfo: [NSURLErrorFailingURLStringErrorKey: "https://evil.example.com/callback?code=a&state=test"])
try require(try request.readCallback(QdOAuthRequest.failingURL(unrelated)!) == nil, "blocked unrelated URL is not success")
try require(QdOAuthRequest.failingURL(NSError(domain: NSURLErrorDomain, code: -1009)) == nil, "missing failing URL")
print("Blocked redirect tests passed")
