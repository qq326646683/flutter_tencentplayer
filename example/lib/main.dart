import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer_example/download_page.dart';
import 'package:flutter_tencentplayer_example/full_video_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primaryColor: Colors.pink),
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (_) => ListPage(),
          'full': (_) => FullVideoPage(),
          'download': (_) => DownloadPage(),
        }
    );
  }
}

enum PlayType {
  network,
  asset,
  file,
  fileId,
}

String networkMp4 = 'http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4';
String liveUrl = 'http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8';
String assetPath = 'static/tencent1.mp4';

class ListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('腾讯播放器Demo'),),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('网络视频'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.network, dataSource: networkMp4,)));
            },
          ),
          ListTile(
            title: Text('直播'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.network, dataSource: liveUrl, showBottomWidget: false, showClearBtn: false,)));
            },
          ),
          ListTile(
            title: Text('asset视频'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.asset, dataSource: assetPath,)));
            },
          ),
          ListTile(
            title: Text('下载播放视频'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => DownloadPage()));
            },
          ),
        ],
      ),
    );
  }
}

