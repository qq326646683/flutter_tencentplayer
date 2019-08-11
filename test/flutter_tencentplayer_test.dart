import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_tencentplayer');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
//    expect(await FlutterTencentplayer.platformVersion, '42');
  });
}
