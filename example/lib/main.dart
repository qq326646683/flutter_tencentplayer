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

  DownloadController _downloadController;
  VoidCallback downloadListener;


  _MyAppState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
    downloadListener = () {
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


  String mu = 'http://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/gear2/prog_index.m3u8';

  String spe1 = 'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4';
  String spe2 = 'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4';
  String spe3 = 'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4';

  String testDownload = 'http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8';
  String downloadRes = '/storage/emulated/0/tencentdownload/txdownload/2c58873a5b9916f9fef5103c74f0ce5e.m3u8.sqlite';
  String downloadRes2 = '/storage/emulated/0/tencentdownload/txdownload/cf3e281653e562303c8c2b14729ba7f5.m3u8.sqlite';

  Future<void> initPlatformState() async {
    _controller = TencentPlayerController.network(
//  'http://img.ksbbs.com/asset/Mon_1703/05cacb4e02f9d9e.mp4')
//  'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4')
//  'http://file.jinxianyun.com/test.mp4',
//  'http://file.jinxianyun.com/2018-06-12_16_58_22.mp4')
//    '/storage/emulated/0/nellcache/txvodcache/fbe87034ba67b082c5b7ac2509cc9be7.mp4',
//              mu,
              spe3,
//        downloadRes2,
//    'static/tencent1.mp4',
    playerConfig:
            PlayerConfig(/*auth: {"appId": 1252463788, "fileId": '4564972819220421305'}*/))
//  'http://live.jinxianyun.com/live/test.flv?txSecret=43c9d5081bddf36b9879342daddadac4&txTime=5D3BB33F')
//  'rtmp://mobliestream.c3tv.com:554/live/goodtv.sdp')
    //http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(listener);


    _downloadController = DownloadController('/storage/emulated/0/tencentdownload', appId: 1252463788);
    _downloadController.addListener(downloadListener);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(listener);
    _downloadController.removeListener(downloadListener);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Container(
          padding: EdgeInsets.only(top: 30),
          height: 1000,
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
                  "播放网速：" + _controller.value.netSpeed.toString(),
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
                top: 170,
                child: Row(
                  children: <Widget>[
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(mu);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                          _controller.addListener(listener);
                        },
                        child: Text(
                          'm3u8点播',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlAAA
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(spe1);
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                          _controller.addListener(listener);
                        },
                        child: Text(
                          '普通点播',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlBBB
                                  ? Colors.red
                                  : Colors.blue),
                        ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 200,
                child: Row(
                  children: <Widget>[
                    Text('m3u8点播 : ', style: TextStyle(color: Colors.orange),),
                    FlatButton(
                      child: Text('标', style: TextStyle(color: _controller.value.bitrateIndex == 0 ? Colors.yellow : Colors.green),),
                      onPressed: () {
                        _controller.setBitrateIndex(0);
                      },
                    ),
                    FlatButton(
                      child: Text('高', style: TextStyle(color: _controller.value.bitrateIndex == 1 ? Colors.yellow : Colors.green),),
                      onPressed: () {
                        _controller.setBitrateIndex(1);
                      },
                    ),
                    FlatButton(
                      child: Text('超', style: TextStyle(color: _controller.value.bitrateIndex == 2 ? Colors.yellow : Colors.green),),
                      onPressed: () {
                        _controller.setBitrateIndex(2);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 230,
                child: Row(
                  children: <Widget>[
                    Text('普通点播 : ', style: TextStyle(color: Colors.orange),),
                    FlatButton(
                        onPressed: () {
                          _controller = TencentPlayerController.network(spe1, playerConfig: PlayerConfig(startTime: _controller.value.position.inSeconds));
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                          _controller.addListener(listener);

                        },
                        child: Text(
                          '标',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlB
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                        onPressed: () {
                          _controller =
                              TencentPlayerController.network(spe2, playerConfig: PlayerConfig(startTime: _controller.value.position.inSeconds));
                          _controller.initialize().then((_) {
                            setState(() {});
                          });
                          _controller.addListener(listener);

                        },
                        child: Text(
                          '高',
                          style: TextStyle(
                              color: _controller.dataSource == videoUrlG
                                  ? Colors.red
                                  : Colors.blue),
                        )),
                    FlatButton(
                      onPressed: () {
                        _controller =
                            TencentPlayerController.network(spe3, playerConfig: PlayerConfig(startTime: _controller.value.position.inSeconds));
                        _controller.initialize().then((_) {
                          setState(() {});
                        });
                        _controller.addListener(listener);

                      },
                      child: Text(
                        '超',
                        style: TextStyle(
                            color: _controller.dataSource == videoUrl
                                ? Colors.red
                                : Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 270,
                child: Container(
                  width: 370,
                  child: Column(
                    children: <Widget>[
                      FlatButton(
                          onPressed: () {
                            _downloadController.dowload("4564972819220421305", quanlity: 2);
                          },
                          child: Text(
                            'download1',
                            style: TextStyle(
                                color: Colors.blue),
                          ),
                      ),
                      FlatButton(
                        onPressed: () {
                          _downloadController.stopDownload("4564972819220421305");
                        },
                        child: Text(
                          'download1 - stop',
                          style: TextStyle(
                              color: Colors.blue),
                        ),
                      ),
                      FlatButton(
                        onPressed: () {
                          _downloadController.dowload(testDownload);
                        },
                        child: Text(
                          'download2',
                          style: TextStyle(
                              color: Colors.blue),
                        ),
                      ),
                      FlatButton(
                        onPressed: () {
                          _downloadController.stopDownload(testDownload);
                        },
                        child: Text(
                          'download2 - stop',
                          style: TextStyle(
                              color: Colors.blue),
                        ),
                      ),
                      Text('download info:'),
                      Text(_downloadController.value != null ? _downloadController.value.toString() : '')
                    ],
                  ),
                ),
              )
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
