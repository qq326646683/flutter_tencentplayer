import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer_example/util/common_util.dart';
import 'package:screen/screen.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

class AutoChangeNextSourcePage extends StatefulWidget {
  @override
  _AutoChangeNextSourcePageState createState() =>
      _AutoChangeNextSourcePageState();
}

class _AutoChangeNextSourcePageState extends State<AutoChangeNextSourcePage> {
  TencentPlayerController? controller;
  VoidCallback? listener;
  int currentIndex = 0;

  List<String> urlList = [
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4',
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4',
    'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4',
  ];

  _AutoChangeNextSourcePageState() {
    listener = () {
      if (!mounted) {
        return;
      }
      if (controller!.value.duration != Duration() && controller!.value.position == controller!.value.duration) {
        CommonUtils.throttle(_next, durationTime: 3000);
      }
      setState(() {});
    };
  }

  @override
  void initState() {
    super.initState();
    controller = TencentPlayerController.network(urlList[0]);
    controller!.initialize();
    controller!.addListener(listener!);
    Screen.keepOn(true);
  }

  @override
  void dispose() {
    super.dispose();
    controller!.removeListener(listener!);
    controller!.dispose();
    Screen.keepOn(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          /// 视频
          controller!.value.initialized
              ? AspectRatio(
                  aspectRatio: controller!.value.aspectRatio,
                  child: TencentPlayer(controller!),
                )
              : Image.asset('static/place_nodata.png'),
          Text('${currentIndex + 1}集')
        ],
      ),
    );
  }

  _next() {
    currentIndex++;
    controller?.removeListener(listener!);
    controller?.pause();
    controller = TencentPlayerController.network(urlList[currentIndex % 3]);
    controller?.initialize();
    controller?.addListener(listener!);
  }
}
