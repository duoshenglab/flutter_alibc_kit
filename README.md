# flutter_alibc

Flutter版本的阿里百川，原作者维护太慢，这个插件以后我自己维护，最新版本必须本地引入依赖了，所以之前版本的maven和pod源全部失效了。

苹果安卓测试没问题，已上架稳定运行四个多月。使用时记得升级最新版安全图，记得看下面的注意点。

# 百川SDK版本

```
Android标准版  4.1.0.1
iOS标准版      4.1.0.0 
```

# flutter版本要求
```
sdk: '>=2.12.0'
```


## 开始配置
### 工程性配置

参考[阿里百川官网](https://baichuan.taobao.com/docs/doc.htm?spm=a3c0d.7629140.0.0.a838be48k4hYDc&treeId=129&articleId=106383&docType=1)

Android: 注意在新版本gradle编译时,会强制校验远程仓库是否存在.pom文件, 阿里百川仓库目前缺少.pom文件, 因此目前先使用较低版本gradle

### 注意点

1. 该版本需使用V6版本的安全图片，V6版本的安全图片可在[百川套件平台](https://suite.baichuan.taobao.com/?spm=a3c0d.7629140.0.0.70e6be48TzC7BS)下载。
2. 通过第1步，重新下载V6版本的安全图，并把yw_1222.jpg文件名改为yw_1222_baichuan.jpg。

### 方法说明

* 头文件引入

``` dart
import 'package:alibc_kit/flutter_alibc.dart';
```

* 初始化

``` dart
 /**
   * 初始化
   * version:当前app版本
   * appName:当前app名称
   * result:{
   * errorCode,     //0为初始化成功，其他为失败
   * errorMessage,  //message
   * }
   */
var result = await FlutterAlibc.initAlibc(version:"",appName:"");
```

* 登录淘宝

``` dart
/**
   * 登录淘宝
   * result :{
   * errorCode,     //0为初始化成功，其他为失败
   * errorMessage,  //message
   * data:{					//登录成功的情况下返回data，为用户数据
   * 	//nick 用户昵称，avatarUrl 头像地址
	 *  nick,avatarUrl,openId,openSid,topAccessToken,topAuthCode
   * 	}
   * }
   * 备注：登录过会直接返回淘宝用户的信息，不会多次唤醒淘宝，请放心
   */
    FlutterAlibc.loginTaoBao(callback:(result){
        print("登录淘宝  ${result.data.nick} ${result.data.topAccessToken}");
    });
```

* 淘宝登出

``` dart
FlutterAlibc.loginOut();
```

* 淘客登录，二次授权获取access_token

``` dart
 /**
   * @description: 获取access_token
   * @param 
   * url:用于授权登录的url
   * openType:打开类型,默认auto
   * isNeedCustomNativeFailMode:是否需要设置唤端失败策略，默认false
   * nativeFailMode:唤端失败策略，默认None
   * schemeType:唤起哪个端，默认天猫
   * taokeParams:淘客数据
   * backUrl: 跳转回来的url
   * result: {"data":{"accessToken":"xxx"},"errorMessage":"成功","errorCode":"0"}//获取成功为token，获取失败为空字符串
   */
    FlutterAlibc.taoKeLogin(
        url:"",	//必须参数，用于授权登录的url
        openType : AlibcOpenType.AlibcOpenTypeAuto,
        isNeedCustomNativeFailMode : false,
        nativeFailMode :    AlibcNativeFailMode.AlibcNativeFailModeNone,
        schemeType : AlibcSchemeType.AlibcSchemeTmall,
        taokeParams : {},
        backUrl:"",
        callback: (result){
            print('淘客登录 ' + json.encode(result));
        },
    );
```

* 淘客登录，二次授权获取code

``` dart
 /**
   * @description: 获取code
   * @param 
   * url:用于授权登录的url
   * openType:打开类型,默认auto
   * isNeedCustomNativeFailMode:是否需要设置唤端失败策略，默认false
   * nativeFailMode:唤端失败策略，默认None
   * schemeType:唤起哪个端，默认天猫
   * taokeParams:淘客数据
   * backUrl: 跳转回来的url
   * result: {"data":{"code":"xxx"},"errorMessage":"成功","errorCode":"0"}//获取成功为code，获取失败为空字符串
   */
    FlutterAlibc.taoKeLoginForCode(
        url:"",	//必须参数，用于授权登录的url
        openType : AlibcOpenType.AlibcOpenTypeAuto,
        isNeedCustomNativeFailMode : false,
        nativeFailMode :    AlibcNativeFailMode.AlibcNativeFailModeNone,
        schemeType : AlibcSchemeType.AlibcSchemeTmall,
        taokeParams : {},
        backUrl:"",
        callback: (result){
            print('淘客登录 ' + json.encode(result));
        },
    );
```

* 唤起淘宝，openByUrl方式

``` dart
 /**
   * @description: 通过url打开,包括h5，唤起手淘等
   * @param 
   * url:目标url
   * openType:打开类型,默认auto
   * isNeedCustomNativeFailMode:是否需要设置唤端失败策略，默认false
   * nativeFailMode:唤端失败策略，默认None
   * schemeType:唤起哪个端，默认天猫
   * taokeParams:淘客数据
   * backUrl: 跳转回来的url
   * result: {
   *		errorCode,
   *		errorMessage,
   *		type,			//0为添加购物车，1为付款成功
   *		payResult,	//type为1时返回
   *  }
   */
   FlutterAlibc.openByUrl(
        url:"",	//必须参数
        openType : AlibcOpenType.AlibcOpenTypeAuto,
        isNeedCustomNativeFailMode : false,
        nativeFailMode :    AlibcNativeFailMode.AlibcNativeFailModeNone,
        schemeType : AlibcSchemeType.AlibcSchemeTmall,
        taokeParams : {},
        backUrl:"",
        callback: (result){
            print('openByURL ' + json.encode(result));
        },
  );
```

* 唤起淘宝，openItemDetail方式

``` dart
/**
   * @description: 打开商品详情
   * @param 
   * itemID 商品id，可以是真实的也可以是混淆的，必须参数
   * trackParam	需要额外追踪的业务数据
   * 其他同上
   * @return: 同openByUrl
   */
    FlutterAlibc.openItemDetail(
        itemID:"",	//必须参数
        openType : AlibcOpenType.AlibcOpenTypeAuto,
        isNeedCustomNativeFailMode : false,
        nativeFailMode :    AlibcNativeFailMode.AlibcNativeFailModeNone,
        schemeType : AlibcSchemeType.AlibcSchemeTmall,
        taokeParams : {},
        trackParam : {}, //需要额外追踪的业务数据
        backUrl:"",
        callback: (result){
            print('openItemDetail ' + json.encode(result));
        },
    );
```

* 打开店铺，openShop方式

``` dart
/**
   * @description: 打开店铺
   * @param 
   * shopId 店铺id，必须参数
   * 其他同上
   * result: 同openByUrl
   */
    FlutterAlibc.openShop(
        shopId:"",	//必须参数
        openType : AlibcOpenType.AlibcOpenTypeAuto,
        isNeedCustomNativeFailMode : false,
        nativeFailMode :    AlibcNativeFailMode.AlibcNativeFailModeNone,
        schemeType : AlibcSchemeType.AlibcSchemeTmall,
        taokeParams : {},
        trackParam : {}, //需要额外追踪的业务数据
        backUrl:"",
        callback: (result){
              print('openShop ' + json.encode(result));
        },
    );
```

* 打开购物车，openCart方式

``` dart
/**
   * @description: 打开购物车
   * @param 
   * 无必须参数
   * 其他同上
   * result: 同openByUrl
   */
    FlutterAlibc.openCart(
        openType : AlibcOpenType.AlibcOpenTypeAuto,
        isNeedCustomNativeFailMode : false,
        nativeFailMode :    AlibcNativeFailMode.AlibcNativeFailModeNone,
        schemeType : AlibcSchemeType.AlibcSchemeTmall,
        taokeParams : {},
        trackParam : {}, //需要额外追踪的业务数据
        backUrl:"",
        callback: (result){
              print('openShop ' + json.encode(result));
        },
    );
```


* 是否设置同步打点

``` dart
FlutterAlibc.syncForTaoke(true);
````

* 是否使用Native Alipay

``` dart
FlutterAlibc.useAlipayNative(true);
```

## Android 渠道备案 `qdByHide`

先成功调用 `initAlibc` 和 `loginTaoBao`，再调用渠道备案。插件复用百川登录态，
在透明 Activity 中加载 WebView，识别淘宝 OAuth 授权按钮并尝试自动提交。
Android SDK 4.1.0.4 的打开类型只有 Auto/Native，此接口固定使用 Auto，
其他打开类型参数为兼容已有 Dart 调用保留。淘宝服务端可能要求重新登录、验证码或额外交互，
遇到这些情况应使用可见授权流程，不保证每次都能静默完成。

```dart
// 放在 loginTaoBao 成功后的回调中；state 应为本次请求生成并保存的随机值。
final authUrl = Uri.https('oauth.m.taobao.com', '/authorize', {
  'response_type': 'code', // 或 token
  'client_id': '你的淘宝联盟APPKEY',
  'redirect_uri': 'https://你的域名/已登记的回调路径',
  'state': oauthState,
  'view': 'web',
});
FlutterAlibc.qdByHide(
  url: authUrl.toString(),
  taokeCallback: (result) {
    if (result['errorCode'] == '0') {
      final data = result['data'] as Map;
      final code = data['code'];
      final token = data['access_token'];
      // 将 code 或 token 传给服务端完成渠道备案；不要写入日志。
    } else {
      // result['errorCode'] / result['errorMessage'] 用于处理失败。
    }
  },
);
```

成功结果保持现有回调契约：`errorCode: "0"`，`data` 中包含 OAuth 回调参数，
如 `code`，或 `access_token` / `expires_in`。支持 query 和 fragment，保留 URL 解码后的完整值。
插件仅接受与请求中 redirect_uri 匹配的回调，并校验请求中的 state。
它会拦截结果导航并关闭 WebView，因此获取结果不依赖回调页面引入 `Baichuan.closeWebView()`；
回调 URL 仍须正确登记，服务端兑换 code/备案需由调用方完成。

失败码包括 `NOT_LOGGED_IN`、`INVALID_URL`、`INVALID_CALLBACK`、`AUTH_DENIED`、
`BUSY`、`TIMEOUT`、`CANCELLED`、`LOAD_FAILED`、`HTTP_ERROR`、`OPEN_FAILED`、
`START_FAILED`、`NO_ACTIVITY`、`PLATFORM_ERROR`，以及 SDK 原始错误码。
一次请求最多等待 30 秒，只回调一次；并发调用不会覆盖正在等待的回调。
回调地址支持 HTTP(S)，必须与 OAuth 请求内地址一致；该实现仅针对 Android。

本地验证：

```sh
flutter test
node android/tests/qd_authorize_test.js
javac -d /tmp/qd-tests android/src/main/java/com/wxwx/flutter_alibc/QdOAuthRequest.java android/src/test/java/com/wxwx/flutter_alibc/QdOAuthRequestTest.java
java -cp /tmp/qd-tests com.wxwx.flutter_alibc.QdOAuthRequestTest
```
