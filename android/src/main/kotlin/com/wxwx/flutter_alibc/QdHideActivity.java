package com.wxwx.flutter_alibc;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.NotificationCompat;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageButton;
import android.widget.TextView;

import com.ali.auth.third.login.LoginConstants;
import com.alibaba.baichuan.android.trade.AlibcTrade;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.android.trade.model.OpenType;
import com.alibaba.baichuan.trade.biz.AlibcTradeCallback;
import com.alibaba.baichuan.trade.biz.context.AlibcTradeResult;
import com.alibaba.baichuan.trade.biz.core.taoke.AlibcTaokeParams;
import com.alibaba.baichuan.trade.common.utils.AlibcLogger;
import com.alibaba.fastjson.JSONException;
import com.alibaba.fastjson.JSONObject;

import java.io.PrintStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

public class QdHideActivity extends Activity {
    private List<String> loadHistoryUrls = new ArrayList();
    private WebView webView;

    @Override // android.app.Activity
    protected void onCreate(Bundle bundle) {
        getWindow().addFlags(67108864);
        Log.i("SimpleComponentHolder", "openUrlByqd: fdsescc bdf");
        super.onCreate(bundle);
        Log.i("SimpleComponentHolder", "openUrlByqd: sdfdsfassfsdfsd bdf");
        requestWindowFeature(1);
        setContentView(R.layout.activity_qd_hide);
        Intent intent = getIntent();
        Log.i("SimpleComponentHolder", "openUrlByqd: sdfdsfassfsdfsd bdf");
        if (intent != null) {
            String stringExtra = intent.getStringExtra("url");
            WebView webView = (WebView) findViewById(R.id.webview);
            this.webView = webView;
            webView.getSettings().setJavaScriptEnabled(true);
            this.webView.getSettings().setDomStorageEnabled(true);
            ((TextView) findViewById(R.id.sdk_closed)).setOnClickListener(new View.OnClickListener() { // from class: com.uzk.UZKAlibcsdk.qdHideActivity.1
                @Override // android.view.View.OnClickListener
                public void onClick(View view) {
                    QdHideActivity.this.finish();
                }
            });
            ((ImageButton) findViewById(R.id.sdk_back)).setOnClickListener(new View.OnClickListener() { // from class: com.uzk.UZKAlibcsdk.qdHideActivity.2
                @Override // android.view.View.OnClickListener
                public void onClick(View view) {
                    if (QdHideActivity.this.webView.canGoBack()) {
                        if (QdHideActivity.this.loadHistoryUrls.size() > 1) {
                            String str = (String) QdHideActivity.this.loadHistoryUrls.get(QdHideActivity.this.loadHistoryUrls.size() - 2);
                            QdHideActivity.this.loadHistoryUrls.remove(QdHideActivity.this.loadHistoryUrls.size() - 1);
                            if (QdHideActivity.this.loadHistoryUrls.size() > 0) {
                                QdHideActivity.this.loadHistoryUrls.remove(QdHideActivity.this.loadHistoryUrls.size() - 1);
                            }
                            QdHideActivity.this.webView.loadUrl(str);
                        }
                        QdHideActivity.this.webView.goBack();
                        return;
                    }
                    QdHideActivity.this.finish();
                }
            });
            openByUrl(stringExtra, this.webView);
            ((TextView) findViewById(R.id.sdk_title)).setText("渠道备案");
        }
    }

    @Override // android.app.Activity
    protected void onStart() {
        super.onStart();
        setVisible(true);
    }

    @Override // android.app.Activity
    protected void onResume() {
        super.onResume();
    }

    @Override // android.app.Activity
    protected void onPause() {
        super.onPause();
        finish();
    }

    /* JADX INFO: Access modifiers changed from: private */
    public String getcode(String str) {
        try {
            return str.substring(str.indexOf("code"));
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }

    /* JADX INFO: Access modifiers changed from: private */
    public String getAccessToken(String str) {
        try {
            String substring = str.substring(str.indexOf("access_token"));
            PrintStream printStream = System.out;
            printStream.println("获取到code：" + substring);
            return substring;
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }

    private void openByUrl(String str, WebView webView) {
        AlibcShowParams alibcShowParams = new AlibcShowParams();
        alibcShowParams.setOpenType(OpenType.Native);
        alibcShowParams.setClientType("taobao");
        alibcShowParams.setBackUrl("alisdk://");
        AlibcTrade.openByUrl(this, "", str, webView, new WebViewClient() { // from class: com.uzk.UZKAlibcsdk.qdHideActivity.3
            @Override // android.webkit.WebViewClient
            public boolean shouldOverrideUrlLoading(WebView webView2, String str2) {
                if (str2.contains("code=") || str2.contains("code=")) {
                    String str3 = QdHideActivity.this.getcode(str2);
                    PrintStream printStream = System.out;
                    printStream.println("获取到code：" + str3);
                    JSONObject jSONObject = new JSONObject();
                    try {
                        jSONObject.put("status", (Object) true);
                        jSONObject.put("data", QdHideActivity.this.StringtoJson(str3));
                        jSONObject.put(NotificationCompat.CATEGORY_MESSAGE, (Object) "获取数据成功");
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }

                    if(FlutterAlibcHandle.Companion.getCallBack() != null) {
                        FlutterAlibcHandle.Companion.getCallBack().success(str3);
                    }

//                    AlibcsdkWXModule.onRegisterClientCallBack.invokeAndKeepAlive(jSONObject);
//                    if (qdHideActivity.callBack != null) {
//                        qdHideActivity.callBack.success(str3);
//                        CallBack unused = qdHideActivity.callBack = null;
//                    }
                    QdHideActivity.this.finish();
                } else {
                    System.out.println("没有获取到code");
                }
                if (str2.contains("access_token")) {
                    String accessToken = QdHideActivity.this.getAccessToken(str2);
                    PrintStream printStream2 = System.out;
                    printStream2.println("获取到access_token：" + accessToken);
                    JSONObject jSONObject2 = new JSONObject();
                    try {
                        jSONObject2.put("status", (Object) true);
                        jSONObject2.put("data", QdHideActivity.this.StringtoJson(accessToken));
                        jSONObject2.put(NotificationCompat.CATEGORY_MESSAGE, (Object) "获取数据成功");
                    } catch (JSONException e2) {
                        e2.printStackTrace();
                    }

                    if(FlutterAlibcHandle.Companion.getCallBack() != null) {
                        FlutterAlibcHandle.Companion.getCallBack().success(jSONObject2.toJSONString());
                    }
//                    AlibcsdkWXModule.onRegisterClientCallBack.invokeAndKeepAlive(jSONObject2);
//                    if (qdHideActivity.callBack != null) {
//                        qdHideActivity.callBack.success(accessToken);
//                        CallBack unused2 = qdHideActivity.callBack = null;
//                    }
                    QdHideActivity.this.finish();
                    return false;
                }
                System.out.println("没有获取到access_token");
                return false;
            }

            @Override // android.webkit.WebViewClient
            public void onLoadResource(WebView webView2, String str2) {
                super.onLoadResource(webView2, str2);
            }

            @Override // android.webkit.WebViewClient
            public void onPageFinished(WebView webView2, String str2) {
                super.onPageFinished(webView2, str2);
                webView2.loadUrl("javascript: document.getElementsByTagName('form')[0].submit();");
                System.out.println(str2);
            }
        }, new WebChromeClient() { // from class: com.uzk.UZKAlibcsdk.qdHideActivity.4
            @Override // android.webkit.WebChromeClient
            public void onReceivedTitle(WebView webView2, String str2) {
                super.onReceivedTitle(webView2, str2);
                ((TextView) QdHideActivity.this.findViewById(R.id.sdk_title)).setText(str2);
            }
        }, alibcShowParams, new AlibcTaokeParams("", "", ""), new HashMap(), new AlibcTradeCallback() { // from class: com.uzk.UZKAlibcsdk.qdHideActivity.5
            @Override // com.alibaba.baichuan.android.trade.callback.AlibcTradeCallback
            public void onTradeSuccess(AlibcTradeResult alibcTradeResult) {
                AlibcLogger.i("WebViewActivity", "request success");
            }

            @Override // com.alibaba.baichuan.android.trade.callback.AlibcTradeCallback
            public void onFailure(int i, String str2) {
                AlibcLogger.e("WebViewActivity", "code=" + i + ", msg=" + str2);
            }
        });
        finish();
    }

    @Override // android.app.Activity
    protected void onDestroy() {
        super.onDestroy();
    }

    /* JADX INFO: Access modifiers changed from: private */
    public Object StringtoJson(String str) {
        try {
            System.out.println("获取到url：" + str);
            String[] split = str.split(LoginConstants.AND);
            HashMap hashMap = new HashMap();
            for (String str2 : split) {
                String[] split2 = str2.split(LoginConstants.EQUAL);
                if(split2.length > 1) {
                    hashMap.put(split2[0], split2[1]);
                }
            }
            System.out.println("获取到code：" + hashMap);
            return hashMap;
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }
}