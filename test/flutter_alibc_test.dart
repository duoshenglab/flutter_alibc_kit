import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alibc/flutter_alibc.dart';
import 'package:flutter_alibc/alibc_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_alibc');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'initAlibc') {
        return {'errorCode': '0', 'errorMessage': 'success'};
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('init result keeps the platform error contract', () async {
    final result = await FlutterAlibc.initAlibc(appName: '多省严选h');
    expect(result.errorCode, '0');
  });

  test('login failure callback accepts missing user data', () async {
    LoginModel? received;
    FlutterAlibc.loginTaoBao(loginCallback: (model) => received = model);
    await messenger.handlePlatformMessage(
      'flutter_alibc',
      const StandardMethodCodec().encodeMethodCall(const MethodCall(
        'AlibcTaobaoLogin',
        {'errorCode': 'AUTH_CANCEL', 'errorMessage': 'cancelled'},
      )),
      (_) {},
    );
    expect(received?.errorCode, 'AUTH_CANCEL');
    expect(received?.data, isNull);
  });

  test('authorize returns the SDK token and expiry', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'authorize');
      expect(call.arguments, {'appName': '多省严选h'});
      return {
        'errorCode': '0',
        'errorMessage': 'success',
        'data': {'accessToken': 'token-123', 'expireTime': '1234567890'}
      };
    });
    final result = await FlutterAlibc.authorize(appName: '多省严选h');
    expect(result.isSuccess, isTrue);
    expect(result.accessToken, 'token-123');
    expect(result.expireTime, '1234567890');
  });

  test('authorize exposes SDK failure without a token', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => {
      'errorCode': '1001',
      'errorMessage': 'cancelled',
    });
    final result = await FlutterAlibc.authorize(appName: '多省严选h');
    expect(result.isSuccess, isFalse);
    expect(result.errorCode, '1001');
    expect(result.errorMessage, 'cancelled');
    expect(result.accessToken, isNull);
  });

  test('openByUrl success without trade payload stays successful', () async {
    TradeResult? received;
    FlutterAlibc.openByUrl(
      url: 'https://s.click.taobao.com/example',
      callback: (value) => received = value,
    );
    await messenger.handlePlatformMessage(
      'flutter_alibc',
      const StandardMethodCodec().encodeMethodCall(const MethodCall(
        'AlibcOpenURL',
        {'errorCode': '0', 'errorMessage': 'opened'},
      )),
      (_) {},
    );
    expect(received?.errorCode, '0');
  });
}
