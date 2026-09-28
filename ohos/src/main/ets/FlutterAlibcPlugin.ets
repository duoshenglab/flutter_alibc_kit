import {
  AbilityAware, AbilityPluginBinding, FlutterPlugin, FlutterPluginBinding,
  MethodCall, MethodCallHandler, MethodChannel, MethodResult
} from '@ohos/flutter_ohos';
import { Alibc, AlibcDegradeType, AlibcOpenType, AlibcShowParams, AlibcTaokeParams } from '@ohos/alibc';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';

interface LoginData {
  nick: string;
  avatarUrl: string;
  openId: string;
  openSid: string;
  topAccessToken: string;
  topAuthCode: string;
}

export default class FlutterAlibcPlugin implements FlutterPlugin, AbilityAware, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;

  getUniqueClassName(): string { return 'FlutterAlibcPlugin'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'flutter_alibc');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void { this.context = null; }

  static setAuthorizeWindowStage(stage: window.WindowStage): void {
    Alibc.setAuthorizeWindowStage(stage);
  }

  static onNewWant(want: Want): void {
    Alibc.onNewWant(want);
  }

  private callback(method: string, code: string, message: string, data?: Object): void {
    this.channel?.invokeMethod(method, {
      'errorCode': code,
      'errorMessage': message,
      'data': data ?? null
    });
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case 'getPlatformVersion':
        result.success('HarmonyOS');
        return;
      case 'initAlibc':
        if (this.context === null) {
          result.success({ 'errorCode': 'NO_ABILITY', 'errorMessage': 'UIAbility unavailable' });
          return;
        }
        Alibc.init({
          context: this.context,
          onSuccess: () => result.success({ 'errorCode': '0', 'errorMessage': 'success' }),
          onFailure: (code: number, msg: string) => result.success({
            'errorCode': code.toString(), 'errorMessage': msg
          })
        });
        return;
      case 'loginTaoBao':
        Alibc.login({
          onSuccess: (user) => {
            const data: LoginData = {
              nick: '',
              avatarUrl: user?.avatarUrl ?? '',
              openId: user?.openId ?? '',
              openSid: user?.openSid ?? '',
              topAccessToken: user?.topAccessToken ?? '',
              topAuthCode: user?.topAuthCode ?? ''
            };
            this.callback('AlibcTaobaoLogin', '0', 'success', data);
          },
          onFailure: (code: string, msg: string) => this.callback('AlibcTaobaoLogin', code, msg)
        });
        result.success(null);
        return;
      case 'authorize':
        const appName = call.argument('appName') as string;
        if (!appName) {
          result.success({ 'errorCode': 'INVALID_APP_NAME', 'errorMessage': 'appName is required' });
          return;
        }
        Alibc.authorize({
          appName,
          appLogoSrc: $r('app.media.icon'),
          appKey: Alibc.getAppKey(),
          onSuccess: (params) => result.success({
            'errorCode': '0',
            'errorMessage': 'success',
            'data': { 'accessToken': params.accessToken, 'expireTime': params.expireTime }
          }),
          onFailure: (code: string, msg: string) => result.success({
            'errorCode': code, 'errorMessage': msg
          })
        });
        return;
      case 'loginOut':
        Alibc.logout({ onComplete: () => {} });
        result.success(null);
        return;
      case 'openByUrl':
        this.openUrl(call, 'AlibcOpenURL', result);
        return;
      case 'taoKeLoginForCode':
        this.unsupported('AlibcTaokeLoginForCode', result);
        return;
      case 'taoKeLogin':
        this.unsupported('AlibcTaokeLogin', result);
        return;
      case 'qdByHide':
        this.unsupported('AlibcQdByHide', result);
        return;
      case 'openItemDetail':
        this.unsupported('AlibcOpenDetail', result);
        return;
      case 'openShop':
        this.unsupported('AlibcOpenShop', result);
        return;
      case 'openCart':
        this.unsupported('AlibcOpenCar', result);
        return;
      case 'closeAlibcWebview':
      case 'syncForTaoke':
      case 'useAlipayNative':
        result.success(null);
        return;
      default:
        result.notImplemented();
    }
  }

  private unsupported(callbackName: string, result: MethodResult): void {
    this.callback(callbackName, 'UNSUPPORTED', 'HarmonyOS SDK 1.0.1 has no matching API');
    result.success(null);
  }

  private openUrl(call: MethodCall, callbackName: string, result: MethodResult): void {
    const url = call.argument('url') as string;
    if (!url) {
      this.callback(callbackName, 'INVALID_URL', 'url is required');
      result.success(null);
      return;
    }
    const openType = call.argument('openType') as number;
    const schemeType = call.argument('schemeType') as number;
    const failMode = call.argument('nativeFailMode') as number;
    const showParams: AlibcShowParams = {
      openType: openType === 1 ? AlibcOpenType.Native : AlibcOpenType.Auto,
      clientType: schemeType === 0 ? 'tmall' : 'taobao',
      backUrl: (call.argument('backUrl') as string) ?? ''
    };
    if (call.argument('isNeedCustomNativeFailMode') as boolean) {
      showParams.degradeType = failMode === 0 ? AlibcDegradeType.H5 :
        failMode === 1 ? AlibcDegradeType.Download : AlibcDegradeType.NONE;
    }
    const rawTaoke = call.argument('taokeParams') as Map<string, Object> | null;
    let taokeParams: AlibcTaokeParams | undefined = undefined;
    if (rawTaoke) {
      const rawExt = rawTaoke.get('extParams') as Map<string, string> | undefined;
      taokeParams = {
        pid: (rawTaoke.get('pid') as string) ?? '',
        unionId: (rawTaoke.get('unionId') as string) ?? '',
        subPid: (rawTaoke.get('subPid') as string) ?? '',
        extParams: rawExt
      };
    }
    Alibc.openByUrl({
      url,
      showParams,
      taokeParams,
      onSuccess: (code: number, msg: string) => {
        this.callback(callbackName, code === 2000 ? '0' : code.toString(), msg);
      },
      onFailure: (code: number, msg: string) => {
        this.callback(callbackName, code.toString(), msg);
      }
    });
    result.success(null);
  }
}
