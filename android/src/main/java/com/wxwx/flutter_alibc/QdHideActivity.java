package com.wxwx.flutter_alibc;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.WindowManager;
import android.webkit.CookieManager;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;

import com.alibaba.baichuan.android.trade.AlibcTrade;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.android.trade.model.OpenType;
import com.alibaba.baichuan.trade.biz.AlibcTradeCallback;
import com.alibaba.baichuan.trade.biz.context.AlibcTradeResult;
import com.alibaba.baichuan.trade.biz.core.taoke.AlibcTaokeParams;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/** Keeps an authenticated Baichuan WebView alive until an OAuth result or timeout. */
public class QdHideActivity extends Activity {
    interface Callback {
        void complete(String code, String message, Map<String, String> data);
    }
    private static final class Pending {
        final String id = UUID.randomUUID().toString();
        final String url;
        final Callback callback;
        Pending(String url, Callback callback) { this.url = url; this.callback = callback; }
    }
    private static Pending pending;
    private Pending request;
    private QdOAuthRequest oauth;
    private WebView webView;
    private String authorizeScript;
    private boolean completed;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable timeout = () -> complete("TIMEOUT", "渠道授权超时，请使用可见授权流程重试", null);

    static void start(Activity activity, String url, Callback callback) {
        if (pending != null) {
            callback.complete("BUSY", "已有渠道授权正在进行", null);
            return;
        }
        try { new QdOAuthRequest(url); }
        catch (RuntimeException e) {
            callback.complete("INVALID_URL", e.getMessage(), null);
            return;
        }
        Pending next = new Pending(url, callback);
        pending = next;
        try {
            activity.startActivity(new Intent(activity, QdHideActivity.class).putExtra("requestId", next.id));
        } catch (RuntimeException e) {
            pending = null;
            callback.complete("START_FAILED", "无法打开渠道授权窗口", null);
        }
    }

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        request = pending;
        if (request == null || !request.id.equals(getIntent().getStringExtra("requestId"))) {
            request = null;
            finish();
            return;
        }
        oauth = new QdOAuthRequest(request.url);
        getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE);
        WindowManager.LayoutParams attributes = getWindow().getAttributes();
        attributes.alpha = 0f;
        getWindow().setAttributes(attributes);
        webView = new WebView(this);
        FrameLayout container = new FrameLayout(this);
        container.addView(webView, new FrameLayout.LayoutParams(-1, -1));
        setContentView(container);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.getSettings().setDomStorageEnabled(true);
        webView.getSettings().setAllowFileAccess(false);
        webView.getSettings().setAllowContentAccess(false);
        CookieManager.getInstance().setAcceptCookie(true);
        if (android.os.Build.VERSION.SDK_INT >= 21)
            CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);
        handler.postDelayed(timeout, 30000);
        try {
            try (InputStream input = getAssets().open("qd_authorize.js")) {
                ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                byte[] bytes = new byte[4096];
                int count;
                while ((count = input.read(bytes)) != -1) buffer.write(bytes, 0, count);
                authorizeScript = buffer.toString("UTF-8");
            }
            openByUrl();
        } catch (Exception e) {
            complete("OPEN_FAILED", "无法加载渠道授权页面", null);
        }
    }

    private boolean consume(String url) {
        if (completed) return true;
        try {
            Map<String, String> data = oauth.readCallback(url);
            if (data == null) return false;
            if (data.containsKey("error")) complete("AUTH_DENIED", "淘宝渠道授权失败或被拒绝", null);
            else complete("0", "成功", data);
        } catch (IllegalArgumentException e) {
            complete("INVALID_CALLBACK", "授权回调校验失败：" + e.getMessage(), null);
        }
        return true;
    }

    private void openByUrl() {
        AlibcShowParams params = new AlibcShowParams();
        params.setOpenType(OpenType.Auto);
        params.setClientType("taobao");
        AlibcTrade.openByUrl(this, "", request.url, webView, new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return consume(url);
            }
            @Override public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                return req.isForMainFrame() && consume(req.getUrl().toString());
            }
            @Override public void onPageStarted(WebView view, String url, Bitmap icon) {
                if (consume(url)) view.stopLoading();
            }
            @Override public void onPageFinished(WebView view, String url) {
                if (!consume(url)) view.evaluateJavascript(authorizeScript, null);
            }
            @Override public void onReceivedError(WebView view, int code, String description, String failingUrl) {
                if (android.os.Build.VERSION.SDK_INT < 23)
                    complete("LOAD_FAILED", "渠道授权页面加载失败", null);
            }
            @Override public void onReceivedError(WebView view, WebResourceRequest req, WebResourceError error) {
                if (req.isForMainFrame()) complete("LOAD_FAILED", "渠道授权页面加载失败", null);
            }
            @Override public void onReceivedHttpError(WebView view, WebResourceRequest req, WebResourceResponse response) {
                if (req.isForMainFrame()) complete("HTTP_ERROR", "渠道授权页面 HTTP 错误", null);
            }
        }, new WebChromeClient(), params, new AlibcTaokeParams("", "", ""), new HashMap<>(),
                new AlibcTradeCallback() {
                    @Override public void onTradeSuccess(AlibcTradeResult result) {
                        // SDK opening success is not an OAuth authorization result.
                    }
                    @Override public void onFailure(int code, String message) {
                        complete(Integer.toString(code), "百川无法打开渠道授权页面", null);
                    }
                });
    }

    private void complete(String code, String message, Map<String, String> data) {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            handler.post(() -> complete(code, message, data));
            return;
        }
        if (completed || request == null) return;
        completed = true;
        handler.removeCallbacks(timeout);
        if (pending == request) pending = null;
        try { request.callback.complete(code, message, data); }
        finally { finish(); }
    }

    @Override public void onBackPressed() { complete("CANCELLED", "渠道授权已取消", null); }

    @Override protected void onDestroy() {
        complete("CANCELLED", "渠道授权窗口已关闭", null);
        handler.removeCallbacksAndMessages(null);
        if (webView != null) {
            webView.stopLoading();
            ((FrameLayout) webView.getParent()).removeView(webView);
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }
}
