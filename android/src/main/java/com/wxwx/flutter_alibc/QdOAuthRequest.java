package com.wxwx.flutter_alibc;

import java.net.URI;
import java.net.URLDecoder;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

/** Validates the configured OAuth request and only consumes its matching callback. */
final class QdOAuthRequest {
    final URI redirect;
    final String responseType;
    final String state;

    QdOAuthRequest(String url) {
        URI request = URI.create(url);
        if (!"https".equals(request.getScheme()) || !"oauth.m.taobao.com".equals(request.getHost())
                || !"/authorize".equals(request.getPath()) || request.getUserInfo() != null
                || (request.getPort() != -1 && request.getPort() != 443)) {
            throw new IllegalArgumentException("Expected https://oauth.m.taobao.com/authorize");
        }
        Map<String, String> params = parse(request.getRawQuery());
        responseType = params.get("response_type");
        if (!("code".equals(responseType) || "token".equals(responseType))
                || empty(params.get("client_id")) || empty(params.get("redirect_uri"))) {
            throw new IllegalArgumentException("response_type, client_id and redirect_uri are required");
        }
        redirect = URI.create(params.get("redirect_uri"));
        if (!("https".equals(redirect.getScheme()) || "http".equals(redirect.getScheme()))
                || redirect.getHost() == null || redirect.getUserInfo() != null
                || redirect.getRawFragment() != null) {
            throw new IllegalArgumentException("redirect_uri must be an HTTP(S) callback URL without fragment");
        }
        state = params.get("state");
    }

    Map<String, String> readCallback(String url) {
        URI actual;
        try { actual = URI.create(url); } catch (IllegalArgumentException e) { return null; }
        if (!Objects.equals(redirect.getScheme(), actual.getScheme())
                || !Objects.equals(redirect.getHost(), actual.getHost())
                || port(redirect) != port(actual)
                || !Objects.equals(redirect.getPath(), actual.getPath())
                || actual.getUserInfo() != null) return null;
        Map<String, String> params = parse(actual.getRawQuery());
        for (Map.Entry<String, String> item : parse(actual.getRawFragment()).entrySet()) {
            if (params.put(item.getKey(), item.getValue()) != null)
                throw new IllegalArgumentException("Duplicate callback parameter");
        }
        for (Map.Entry<String, String> item : parse(redirect.getRawQuery()).entrySet()) {
            if (!Objects.equals(params.get(item.getKey()), item.getValue())) return null;
        }
        String expected = "code".equals(responseType) ? "code" : "access_token";
        if (empty(params.get(expected)) && empty(params.get("error"))) return null;
        if (state != null && !Objects.equals(state, params.get("state")))
            throw new IllegalArgumentException("OAuth state does not match");
        return params;
    }

    private static boolean empty(String value) { return value == null || value.isEmpty(); }
    private static int port(URI uri) {
        return uri.getPort() == -1 ? ("https".equals(uri.getScheme()) ? 443 : 80) : uri.getPort();
    }
    private static Map<String, String> parse(String raw) {
        Map<String, String> params = new LinkedHashMap<>();
        if (raw == null || raw.isEmpty()) return params;
        for (String part : raw.split("&")) {
            if (part.isEmpty()) continue;
            String[] pair = part.split("=", 2);
            String key = decode(pair[0]);
            String value = pair.length == 2 ? decode(pair[1]) : "";
            if (params.put(key, value) != null)
                throw new IllegalArgumentException("Duplicate OAuth parameter");
        }
        return params;
    }
    private static String decode(String text) {
        try { return URLDecoder.decode(text, "UTF-8"); }
        catch (java.io.UnsupportedEncodingException e) { throw new AssertionError(e); }
    }
}
