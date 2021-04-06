import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_forbidshot/flutter_forbidshot.dart';

class ForbidShotUtil {
  static bool? isCapture;
  static StreamSubscription<void>? subscription;

  static initForbid(BuildContext context) async {
    isCapture = await FlutterForbidshot.iosIsCaptured;
    _deal(context);
    if (Platform.isIOS) {
      subscription = FlutterForbidshot.iosShotChange.listen((event) {
        isCapture = !isCapture!;
        _deal(context);
      });
    }
    FlutterForbidshot.setAndroidForbidOn();
  }

  static _deal(BuildContext context) {
    if (isCapture == true) {
      Navigator.pop(context);
    }
  }

  static disposeForbid() {
    subscription?.cancel();
    subscription = null;
    FlutterForbidshot.setAndroidForbidOff();
  }
}