package com.wxwx.flutter_alibc;

import android.os.Build;
import android.util.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FlutterAlibcPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

  private MethodChannel channel;
  private FlutterAlibcHandle handle;

  @Override
  public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
    System.out.println("FlutterAlibcPlugin: onAttachedToEngine ");
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_alibc");
    channel.setMethodCallHandler(this);
    handle = new FlutterAlibcHandle(channel);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("initAlibc")) {
      handle.initAlibc(result);
    } else if (call.method.equals("openItemDetail")) {
      handle.openItemDetail(call, result);
    } else if (call.method.equals("loginTaoBao")) {
      handle.loginTaoBao();
    } else if (call.method.equals("taoKeLogin")) {
      handle.taoKeLogin(call);
    } else if (call.method.equals("taoKeLoginForCode")) {
      handle.taoKeLoginForCode(call);
    } else if (call.method.equals("loginOut")) {
      handle.logoutTaoBao(result);
    } else if (call.method.equals("qdByHide")) {
      handle.qdByHide(call);
    } else if (call.method.equals("openByUrl")) {
      handle.openByUrl(call, result);
    } else if (call.method.equals("openShop")) {
      handle.openShop(call, result);
    } else if (call.method.equals("openCart")) {
      handle.openCart(call, result);
    } else if (call.method.equals("syncForTaoke")) {
      handle.syncForTaoke(call);
    } else if (call.method.equals("useAlipayNative")) {
      handle.useAlipayNative(call);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    System.out.println("FlutterAlibcPlugin: onDetachedFromEngine ");
    channel.setMethodCallHandler(null);
    handle.disposed();
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    System.out.println("FlutterAlibcPlugin: onAttachedToActivity ");
    handle.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    System.out.println("FlutterAlibcPlugin: onAttachedToActivity ");
    handle.activity = null;
  }
}