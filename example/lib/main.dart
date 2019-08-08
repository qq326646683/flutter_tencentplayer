import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TencentPlayerController _controller;
  VoidCallback listener;

  _MyAppState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  String videoUrl =
      'http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4.flv';
  String videoUrlB =
      'http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_550.flv';
  String videoUrlG =
      'http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_900.flv';
  String videoUrlAAA = 'http://file.jinxianyun.com/2018-06-12_16_58_22.mp4';
  String videoUrlBBB = 'http://file.jinxianyun.com/testhaha.mp4';

  Future<void> initPlatformState() async {
    _controller = TencentPlayerController.network(
//  'http://img.ksbbs.com/asset/Mon_1703/05cacb4e02f9d9e.mp4')
//  'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4')
//  'http://file.jinxianyun.com/test.mp4')
//  'http://file.jinxianyun.com/2018-06-12_16_58_22.mp4')
        videoUrlAAA,
        playerConfig:
            PlayerConfig(autoPlay: true, loop: true, cachePath: 'mnt/sdcard/'))
//  'http://live.jinxianyun.com/live/test.flv?txSecret=43c9d5081bddf36b9879342daddadac4&txTime=5D3BB33F')
//  'rtmp://mobliestream.c3tv.com:554/live/goodtv.sdp')
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(listener);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Center(
          child: Stack(
            children: <Widget>[
              _controller.value.initialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: TencentPlayer(_controller),
                    )
                  : Container(),
              Positioned(
                top: 100,
                child: Text(
                  "速度：" + _controller.value.netSpeed.toString(),
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              Positioned(
                top: 80,
                child: Text(
                  "错误：" + _controller.value.errorDescription.toString(),
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              Positioned(
                top: 60,
                child: Text(
                  "播放进度：" + _controller.value.position.toString(),
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              Positioned(
                top: 40,
                child: Text(
                  "缓冲进度：" + _controller.value.playable.toString(),
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              Positioned(
                top: 20,
                child: Text(
                  "总时长：" + _controller.value.duration.toString(),
                  style: TextStyle(color: Colors.pink),
                ),
              ),
              Positioned(
                top: 0,
                child: _controller.value.isLoading
                    ? CircularProgressIndicator()
                    : Container(),
              ),
              Positioned(
                top: 110,
                child: FlatButton(
                    onPressed: () {
                      _controller.seekTo(Duration(seconds: 5));
                    },
                    child: Text(
                      'seekTo 00:00:05',
                      style: TextStyle(color: Colors.blue),
                    )),
              ),
              Positioned(
                top: 140,
                child: Row(
                  children: <Widget>[
                    FlatButton(
                        onPressed: () {
                          _controller.setRate(1.0);
                        },
                        child: Text(
                          'setRate 1.0',
                          style: TextStyle(
                              color: _controller.value.rate == 1.0
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller.setRate(1.5);
                        },
                        child: Text(
                          'setRate 1.5',
                          style: TextStyle(
                              color: _controller.value.rate == 1.5
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller.setRate(2.0);
                        },
                        child: Text(
                          'setRate 2.0',
                          style: TextStyle(
                              color: _controller.value.rate == 2.0
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Column(
                  children: <Widget>[
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(videoUrlAAA);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                        },
                        child: Text(
                          '视频1',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlAAA
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(videoUrlBBB);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                        },
                        child: Text(
                          '视频2',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlBBB
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(videoUrlB);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                        },
                        child: Text(
                          '标清',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlB
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(videoUrlG);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                        },
                        child: Text(
                          '高清',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlG
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(videoUrl);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                        },
                        child: Text(
                          '超清',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrl
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }
}
