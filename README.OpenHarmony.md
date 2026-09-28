# HarmonyOS 接入

插件的 `ohos/` 模块使用百川 HarmonyOS SDK 1.0.1（2026-04-08）的集成态 HSP。SDK 来自阿里百川官方包，存放在 `ohos/libs/alibc-default.tgz`。应用需要在 entry 的 `resources/base/media/` 放入对应 AppKey 的 V6 安全图片 `yw_1222.jpg`，并在 `module.json5` 配置 `taobaooauth<AppKey>`、`tbopen` 与 `tbaccount34692017`。

宿主 `EntryAbility` 需在 `onWindowStageCreate` 调用 `FlutterAlibcPlugin.setAuthorizeWindowStage(windowStage)`，在 `onNewWant` 调用 `FlutterAlibcPlugin.onNewWant(want)`；`initAlibc` 应在隐私同意后、其他百川接口前调用。应用 entry 需提供 `app.media.icon` 资源。

| Flutter 接口 | HarmonyOS 行为 |
| --- | --- |
| `initAlibc` | 调用 `Alibc.init`；错误码以字符串返回 |
| `loginTaoBao` / `loginOut` | 调用 `Alibc.login` / `Alibc.logout`；鸿蒙 SDK 不提供昵称，返回空字符串 |
| `authorize(appName: ...)` | 调用 `Alibc.authorize`，传入应用名、`$r('app.media.icon')` 与 `Alibc.getAppKey()`；成功返回 `accessToken`、`expireTime`，失败返回 SDK 的错误码和信息 |
| `openByUrl` | 调用 `Alibc.openByUrl`；成功回调表示唤端成功，不代表交易完成 |
| `taoKeLoginForCode` / `taoKeLogin` / `qdByHide` / 商品、店铺、购物车专用接口 | SDK 1.0.1 没有等价接口，回调 `UNSUPPORTED`；不会伪造授权 code |

```dart
final result = await FlutterAlibc.authorize(appName: '多省严选h');
if (result.isSuccess) {
  final token = result.accessToken!;
  final expireTime = result.expireTime;
  // 将 token 交给使用同一 AppKey 的后端授权接口处理。
}
```

鸿蒙授权返回的是 `accessToken`，不是 OAuth `code`。当前客户端 `/tbLogin` 和 `/web/tbAuth` 使用 AppKey `29134108` 的 code 换 token 流程，不能直接接收鸿蒙 AppKey `35405036` 的 token；服务端绑定流程需要与新应用凭证和淘宝联盟权限一起核对。

`closeAlibcWebview`、`syncForTaoke`、`useAlipayNative` 在鸿蒙上没有对应 SDK 接口。请在真机上验证初始化、授权成功与取消、手淘登录回跳和唤端。SDK 文档还要求 AppKey 经百川加白；安全图片必须与应用 Bundle Name 和 AppKey 匹配。

参考：[百川 SDK HarmonyOS 接入文档](https://developer.alibaba.com/docs/doc.htm?articleId=121845&docType=1&treeId=129)。
