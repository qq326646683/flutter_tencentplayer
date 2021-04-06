import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';


class TencentPlayerLoading extends StatelessWidget {
  TencentPlayerController? controller;
  double? iconW;

  TencentPlayerLoading({this.controller, this.iconW});

  @override
  Widget build(BuildContext context) {
    String tip = '';
    if (!controller!.value.initialized && controller!.value.errorDescription == null) {
      tip = '加载中...';
    } else if (controller!.value.errorDescription != null) {
      tip = controller!.value.errorDescription!;
    } else if(controller!.value.isLoading) {
      tip = '${controller!.value.netSpeed}kb/s';
    }
    if (!controller!.value.initialized || controller!.value.errorDescription != null || controller!.value.isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset('static/video_loading.png', width: this.iconW ?? _Style.loadingW, height: this.iconW ??_Style.loadingW,),
          SizedBox(height: 8,),
          Text(tip, style: TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),),
        ],
      );
    } else {
      return SizedBox();
    }
  }
}


class _Style {
  static double containerH = 211;
  static double fullScreenOnW = 21;
  static double loadingW = 30;
}
