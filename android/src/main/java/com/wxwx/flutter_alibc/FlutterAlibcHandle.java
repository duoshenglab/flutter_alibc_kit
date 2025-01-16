package com.wxwx.flutter_alibc;

import android.content.Intent;
import android.webkit.WebChromeClient;
import android.webkit.WebViewClient;
import com.alibaba.baichuan.android.trade.AlibcTrade;
import com.alibaba.baichuan.android.trade.AlibcTradeSDK;
import com.alibaba.baichuan.android.trade.callback.AlibcTradeInitCallback;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.android.trade.page.AlibcBasePage;
import com.alibaba.baichuan.android.trade.page.AlibcDetailPage;
import com.alibaba.baichuan.android.trade.page.AlibcMyCartsPage;
import com.alibaba.baichuan.android.trade.page.AlibcShopPage;
import com.alibaba.baichuan.trade.biz.AlibcTradeCallback;
import com.alibaba.baichuan.trade.biz.applink.adapter.AlibcFailModeType;
import com.alibaba.baichuan.trade.biz.context.AlibcResultType;
import com.alibaba.baichuan.trade.biz.context.AlibcTradeResult;
import com.alibaba.baichuan.trade.biz.core.taoke.AlibcTaokeParams;
import com.alibaba.baichuan.trade.biz.login.*;
import com.alibaba.baichuan.trade.biz.login.AlibcLogin;
import com.ali.auth.third.core.model.Session;
import com.alibaba.baichuan.trade.biz.login.AlibcLoginCallback;
import com.wxwx.flutter_alibc.web.WebViewActivity;
import java.util.*;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import android.app.Activity;

public class FlutterAlibcHandle {
    private MethodChannel methodChannel;
    public Activity activity;

    public FlutterAlibcHandle(MethodChannel methodChannel) {
        this.methodChannel = methodChannel;
    }

    public void disposed() {
        this.methodChannel = null;
        this.activity = null;
    }

    public interface CallBack {
        void failed(String str);

        void success(String str);
    }

    public static CallBack callBack;

    public void initAlibc(final MethodChannel.Result result) {
        AlibcTradeSDK.asyncInit(activity.getApplication(), new AlibcTradeInitCallback() {
            @Override
            public void onSuccess() {
                result.success(PluginResponse.success(null).toMap());
            }

            @Override
            public void onFailure(int code, String msg) {
                result.success(new PluginResponse(String.valueOf(code), msg, null).toMap());
            }
        });
    }

    public void loginTaoBao() {
        final AlibcLogin alibcLogin = AlibcLogin.getInstance();
        if (alibcLogin.isLogin()) {
            Session session = alibcLogin.getSession();
            Map<String, Object> userInfo = new HashMap<>();
            userInfo.put("nick", session.nick);
            userInfo.put("avatarUrl", session.avatarUrl);
            userInfo.put("openId", session.openId);
            userInfo.put("openSid", session.openSid);
            userInfo.put("topAccessToken", session.topAccessToken);
            userInfo.put("topAuthCode", session.topAuthCode);
            methodChannel.invokeMethod("AlibcTaobaoLogin", PluginResponse.success(userInfo).toMap());
            return;
        }
        alibcLogin.showLogin(new AlibcLoginCallback() {
            @Override
            public void onSuccess(int loginResult, String openId, String nickName) {
                Session session = alibcLogin.getSession();
                Map<String, Object> userInfo = new HashMap<>();
                userInfo.put("nick", session.nick);
                userInfo.put("avatarUrl", session.avatarUrl);
                userInfo.put("openId", session.openId);
                userInfo.put("openSid", session.openSid);
                userInfo.put("topAccessToken", session.topAccessToken);
                userInfo.put("topAuthCode", session.topAuthCode);
                methodChannel.invokeMethod("AlibcTaobaoLogin", PluginResponse.success(userInfo).toMap());
            }

            @Override
            public void onFailure(int code, String msg) {
                methodChannel.invokeMethod("AlibcTaobaoLogin", new PluginResponse(String.valueOf(code), msg, null).toMap());
            }
        });
    }

    public void logoutTaoBao(final MethodChannel.Result result) {
        AlibcLogin alibcLogin = AlibcLogin.getInstance();
        alibcLogin.logout(new AlibcLoginCallback() {
            @Override
            public void onSuccess(int code, String msg1, String msg2) {
                result.success(PluginResponse.success(null).toMap());
            }

            @Override
            public void onFailure(int code, String msg) {
                result.success(new PluginResponse(String.valueOf(code), msg, null).toMap());
            }
        });
    }

    public void taoKeLogin(final MethodCall call) {
        Map<String, Object> map = call.arguments();
        String url = call.argument("url");
        WebViewActivity.callBack = new WebViewActivity.Callback() {
            @Override
            public void success(String accessToken) {
                Map<String, Object> resMap = new HashMap<>();
                resMap.put("accessToken", accessToken);
                methodChannel.invokeMethod("AlibcTaokeLogin", PluginResponse.success(resMap).toMap());
            }

            @Override
            public void failed(String errorMsg) {
                methodChannel.invokeMethod("AlibcTaokeLogin", new PluginResponse("-1", errorMsg, null).toMap());
            }
        };
        Intent intent = new Intent(activity, WebViewActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.putExtra("url", url);
        intent.putExtra("arguments", (HashMap<String, Object>) map);
        activity.startActivity(intent);
    }

    public void taoKeLoginForCode(final MethodCall call) {
        Map<String, Object> map = call.arguments();
        String url = call.argument("url");
        WebViewActivity.callBack = new WebViewActivity.Callback() {
            @Override
            public void success(String accessToken) {
                Map<String, Object> resMap = new HashMap<>();
                resMap.put("code", accessToken);
                methodChannel.invokeMethod("AlibcTaokeLoginForCode", PluginResponse.success(resMap).toMap());
            }

            @Override
            public void failed(String errorMsg) {
                methodChannel.invokeMethod("AlibcTaokeLoginForCode", new PluginResponse("-1", errorMsg, null).toMap());
            }
        };
        Intent intent = new Intent(activity, WebViewActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.putExtra("url", url);
        intent.putExtra("arguments", (HashMap<String, Object>) map);
        activity.startActivity(intent);
    }

    public void qdByHide(final MethodCall call) {
        if (!AlibcLogin.getInstance().isLogin()) {
            return;
        }
        callBack = new CallBack() {
            @Override
            public void success(String code) {
                Map<String, Object> resMap = new HashMap<>();
                resMap.put("code", code);
                methodChannel.invokeMethod("AlibcQdByHide", PluginResponse.success(resMap).toMap());
            }

            @Override
            public void failed(String errorMsg) {
                methodChannel.invokeMethod("AlibcQdByHide", new PluginResponse("-1", errorMsg, null).toMap());
            }
        };

        String url = call.argument("url");
        Intent intent = new Intent(activity, QdHideActivity.class);
        intent.putExtra("url", url);
        activity.startActivity(intent);
    }

    public void openByUrl(final MethodCall call, final MethodChannel.Result result) {
        AlibcShowParams showParams = new AlibcShowParams();
        AlibcTaokeParams taokeParams = new AlibcTaokeParams("", "", "");

        showParams.setBackUrl(call.argument(PluginConstants.key_BackUrl));
        if (call.argument(PluginConstants.key_OpenType) != null) {
            showParams.setOpenType(PluginUtil.getOpenType(call.argument(PluginConstants.key_OpenType).toString()));
        }
        if (call.argument(PluginConstants.key_ClientType) != null) {
            showParams.setClientType(PluginUtil.getClientType(call.argument(PluginConstants.key_ClientType).toString()));
        }
        if (call.argument("taokeParams") != null) {
            taokeParams = PluginUtil.getTaokeParams((Map<String, Object>) call.argument("taokeParams"));
        }
        if ("false".equals(call.argument("isNeedCustomNativeFailMode"))) {
            showParams.setNativeOpenFailedMode(AlibcFailModeType.AlibcNativeFailModeNONE);
        } else if (call.argument(PluginConstants.key_NativeFailMode) != null) {
            showParams.setNativeOpenFailedMode(PluginUtil.getFailModeType(call.argument(PluginConstants.key_NativeFailMode).toString()));
        }

        String url = call.argument("url");
        AlibcTrade.openByUrl(activity, "", url, null, new WebViewClient(), new WebChromeClient(), showParams, taokeParams, new HashMap<>(), new AlibcTradeCallback() {
            @Override
            public void onTradeSuccess(AlibcTradeResult tradeResult) {
                Map<String, Object> results = new HashMap<>();
                if (tradeResult.resultType == AlibcResultType.TYPECART) {
                    results.put("type", 1);
                } else if (tradeResult.resultType == AlibcResultType.TYPEPAY) {
                    results.put("type", 0);
                    results.put("payFailedOrders", tradeResult.payResult.payFailedOrders);
                    results.put("paySuccessOrders", tradeResult.payResult.paySuccessOrders);
                }
                methodChannel.invokeMethod("AlibcOpenURL", PluginResponse.success(results).toMap());
            }

            @Override
            public void onFailure(int code, String msg) {
                methodChannel.invokeMethod("AlibcOpenURL", new PluginResponse(String.valueOf(code), msg, null).toMap());
            }
        });
    }

    public void openShop(final MethodCall call, final MethodChannel.Result result) {
        AlibcBasePage page = new AlibcShopPage(call.argument("shopId"));
        openByBizCode(page, "shop", "AlibcOpenShop", call, result);
    }

    public void openCart(final MethodCall call, final MethodChannel.Result result) {
        AlibcBasePage page = new AlibcMyCartsPage();
        openByBizCode(page, "cart", "AlibcOpenCar", call, result);
    }

    public void openItemDetail(final MethodCall call, final MethodChannel.Result result) {
        AlibcBasePage page = new AlibcDetailPage(call.argument("itemID"));
        openByBizCode(page, "detail", "AlibcOpenDetail", call, result);
    }

    private void openByBizCode(AlibcBasePage page, String type, String methodName, final MethodCall call, final MethodChannel.Result result) {
        AlibcShowParams showParams = new AlibcShowParams();
        AlibcTaokeParams taokeParams = new AlibcTaokeParams("", "", "");

        showParams.setBackUrl(call.argument(PluginConstants.key_BackUrl));
        if (call.argument(PluginConstants.key_OpenType) != null) {
            showParams.setOpenType(PluginUtil.getOpenType(call.argument(PluginConstants.key_OpenType).toString()));
        }
        if (call.argument(PluginConstants.key_ClientType) != null) {
            showParams.setClientType(PluginUtil.getClientType(call.argument(PluginConstants.key_ClientType).toString()));
        }
        if (call.argument("taokeParams") != null) {
            taokeParams = PluginUtil.getTaokeParams((Map<String, Object>) call.argument("taokeParams"));
        }
        if ("false".equals(call.argument("isNeedCustomNativeFailMode"))) {
            showParams.setNativeOpenFailedMode(AlibcFailModeType.AlibcNativeFailModeNONE);
        } else if (call.argument(PluginConstants.key_NativeFailMode) != null) {
            showParams.setNativeOpenFailedMode(PluginUtil.getFailModeType(call.argument(PluginConstants.key_NativeFailMode).toString()));
        }

        AlibcTrade.openByBizCode(activity, page, null, new WebViewClient(), new WebChromeClient(), type, showParams, taokeParams, new HashMap<>(), new AlibcTradeCallback() {
            @Override
            public void onTradeSuccess(AlibcTradeResult tradeResult) {
                Map<String, Object> results = new HashMap<>();
                if (tradeResult.resultType == AlibcResultType.TYPECART) {
                    results.put("type", 1);
                } else if (tradeResult.resultType == AlibcResultType.TYPEPAY) {
                    results.put("type", 0);
                    results.put("payFailedOrders", tradeResult.payResult.payFailedOrders);
                    results.put("paySuccessOrders", tradeResult.payResult.paySuccessOrders);
                }
                methodChannel.invokeMethod(methodName, PluginResponse.success(results).toMap());
            }

            @Override
            public void onFailure(int code, String msg) {
                methodChannel.invokeMethod(methodName, new PluginResponse(String.valueOf(code), msg, null).toMap());
            }
        });
    }

    public void syncForTaoke(final MethodCall call) {
        AlibcTradeSDK.setSyncForTaoke(call.argument("isSync"));
    }

    public void useAlipayNative(final MethodCall call) {
        // AlibcTradeSDK.setShouldUseAlipay(call.argument("isNeed"));
    }
}