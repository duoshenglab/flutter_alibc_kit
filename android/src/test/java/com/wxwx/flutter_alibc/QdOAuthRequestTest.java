package com.wxwx.flutter_alibc;

public final class QdOAuthRequestTest {
    private static void check(boolean value) { if (!value) throw new AssertionError(); }
    public static void main(String[] args) {
        QdOAuthRequest code = new QdOAuthRequest("https://oauth.m.taobao.com/authorize?response_type=code&client_id=123&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback&state=s%2B1&view=web");
        check(code.readCallback("https://example.com/callback?code=a%3Db&state=s%2B1").get("code").equals("a=b"));
        check(code.readCallback("https://evil.com/callback?code=x&state=s%2B1") == null);
        check(code.readCallback("https://example.com/callback/other?code=x&state=s%2B1") == null);
        try { code.readCallback("https://example.com/callback?code=x&state=wrong"); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { }
        check(code.readCallback("https://example.com/callback?error=access_denied&state=s%2B1").get("error").equals("access_denied"));
        check(code.readCallback("https://example.com/callback") == null);
        QdOAuthRequest token = new QdOAuthRequest("https://oauth.m.taobao.com/authorize?response_type=token&client_id=123&redirect_uri=https%3A%2F%2Fexample.com%2Fcallback");
        check(token.readCallback("https://example.com/callback#access_token=a%3Db&expires_in=3600").get("access_token").equals("a=b"));
        check(token.readCallback("https://example.com/callback?code=x") == null);
        try { new QdOAuthRequest("https://evil.com/authorize?response_type=code&client_id=123&redirect_uri=https://example.com"); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { }
        try { code.readCallback("https://example.com/callback?code=x&code=y&state=s%2B1"); throw new AssertionError(); }
        catch (IllegalArgumentException expected) { }
        System.out.println("OAuth callback tests passed");
    }
}
