package com.wxwx.flutter_alibc.web;

import android.app.Activity;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import com.alibaba.baichuan.android.trade.AlibcTrade;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.trade.biz.AlibcTradeCallback;
import com.alibaba.baichuan.trade.biz.applink.adapter.AlibcFailModeType;
import com.alibaba.baichuan.trade.biz.context.AlibcTradeResult;
import com.alibaba.baichuan.trade.biz.core.taoke.AlibcTaokeParams;
import com.wxwx.flutter_alibc.PluginUtil;
import com.wxwx.flutter_alibc.R;
import java.net.URLDecoder;
import java.util.*;
import com.wxwx.flutter_alibc.PluginConstants;

public class WebViewActivity extends Activity {

    public static Callback callBack;

    public interface Callback {
        void success(String accessToken);
        void failed(String errorMsg);
    }

    @Override
    protected void onDestroy() {
        if (callBack != null) {
            callBack.failed("取消授权");
            callBack = null;
        }
        super.onDestroy();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.webview_activity);

        if (getIntent() != null) {
            String url = getIntent().getStringExtra("url");
            HashMap<String, Object> arguments = (HashMap<String, Object>) getIntent().getSerializableExtra("arguments");
            WebView webView = findViewById(R.id.webview);

            // 启用支持JavaScript
            webView.getSettings().setJavaScriptEnabled(true);

            // 启用支持DOM Storage
            webView.getSettings().setDomStorageEnabled(true);

            openByUrl(url, webView, arguments);
        }
    }

    private void openByUrl(String url, WebView webView, HashMap<String, Object> argument) {
        AlibcShowParams showParams = new AlibcShowParams();
        AlibcTaokeParams taokeParams = new AlibcTaokeParams("", "", "");

        showParams.setBackUrl(argument.get(PluginConstants.key_BackUrl).toString());

        if (argument.get(PluginConstants.key_OpenType) != null) {
            showParams.setOpenType(PluginUtil.getOpenType(argument.get(PluginConstants.key_OpenType).toString()));
        }
        if (argument.get(PluginConstants.key_ClientType) != null) {
            showParams.setClientType(PluginUtil.getClientType(argument.get(PluginConstants.key_ClientType).toString()));
        }
        if (argument.get("taokeParams") != null) {
            taokeParams = PluginUtil.getTaokeParams((HashMap<String, Object>) argument.get("taokeParams"));
        }
        if ("false".equals(argument.get("isNeedCustomNativeFailMode"))) {
            showParams.setNativeOpenFailedMode(AlibcFailModeType.AlibcNativeFailModeNONE);
        } else if (argument.get(PluginConstants.key_NativeFailMode) != null) {
            showParams.setNativeOpenFailedMode(PluginUtil.getFailModeType(argument.get(PluginConstants.key_NativeFailMode).toString()));
        }

        Map<String, String> trackParams = new HashMap<>();

        WebViewClient client = new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return false;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                Log.e("", "onPageStarted url : " + url);
                super.onPageStarted(view, url, favicon);

                if (url != null && url.contains("access_token=") && (url.contains("oauth.taobao.com") || url.contains("oauth.m.taobao.com"))) {
                    String accessToken = getURLParam("access_token", url);
                    Log.e("", "onPageStarted accessToken " + accessToken);
                    if (callBack != null) {
                        callBack.success(accessToken);
                        callBack = null;
                    }
                    finish();
                }
                if (url != null && url.contains("code=")) {
                    String code = getURLParam("code", url);
                    Log.e("", "onPageStarted code " + code);
                    if (callBack != null) {
                        callBack.success(code);
                        callBack = null;
                    }
                    finish();
                }
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                Log.e("", "onPageFinished url : " + url);
                super.onPageFinished(view, url);
            }

            @Override
            public void onLoadResource(WebView view, String url) {
                super.onLoadResource(view, url);
            }
        };

        AlibcTrade.openByUrl(this, "", url, webView, client, new WebChromeClient(),
            showParams, taokeParams, trackParams, new AlibcTradeCallback() {
                @Override
                public void onTradeSuccess(AlibcTradeResult tradeResult) {
                    // 不会回调
                }

                @Override
                public void onFailure(int code, String msg) {
                    // 不会回调
                }
            });
    }

    private String getURLParam(String paramKey, String url) {
        try {
            int startIndex = url.indexOf(paramKey);
            String subStr = url.substring(startIndex);
            String tempUrl = URLDecoder.decode(subStr, "UTF-8");
            int endIndex = tempUrl.indexOf("&");
            if (endIndex < 0) {
                endIndex = tempUrl.length();
            }
            subStr = tempUrl.substring(0, endIndex);
            startIndex = subStr.indexOf("=");
            subStr = subStr.substring(startIndex + 1);
            return subStr;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return "";
    }
}
