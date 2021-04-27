import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'page/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(MyApp());
}

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
          'window': (_) => WindowVideoPage(),
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
String liveUrl1 = 'http://liteavapp.qcloud.com/live/liteavdemoplayerstreamid_demo1080p.flv';
String liveUrl2 = 'rtmp://58.200.131.2:1935/livetv/hunantv';
String assetPath = 'static/tencent1.mp4';

class ListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('腾讯播放器Demo'),),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('小窗视频'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => WindowVideoPage(playType: PlayType.network, dataSource: networkMp4,)));
            },
          ),
          ListTile(
            title: Text('网络视频'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.network, dataSource: networkMp4,)));
            },
          ),
          ListTile(
            title: Text('直播1'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.network, dataSource: liveUrl1, showBottomWidget: false, showClearBtn: false,)));
            },
          ),
          ListTile(
            title: Text('直播2'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.network, dataSource: liveUrl2, showBottomWidget: false, showClearBtn: false,)));
            },
          ),
          ListTile(
            title: Text('file视频'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FileVideoPage()));
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
          ListTile(
            title: Text('自动切换集'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => AutoChangeNextSourcePage()));
            },
          ),
          ListTile(
            title: Text('仿抖音'),
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => TiktokPage()));
            },
          ),
        ],
      ),
    );
  }
}

