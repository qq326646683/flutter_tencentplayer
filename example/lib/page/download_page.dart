import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer_example/page/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter_tencentplayer_example/main.dart';


class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  DownloadController? _downloadController;
  VoidCallback? downloadListener;

  List<String> urlList= [
    "http://1253131631.vod2.myqcloud.com/26f327f9vodgzp1253131631/f4bdff799031868222924043041/playlist.m3u8",
    "http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/68e3febf4564972819220421305/v.f220.m3u8",
  ];

  _DownloadPageState() {
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
    _init();
  }

  _init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    _downloadController = DownloadController(appDocPath);
    _downloadController!.addListener(downloadListener!);
    setState(() {
    });
  }

  @override
  void dispose() {
    super.dispose();
    _downloadController!.removeListener(downloadListener!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('下载播放视频'),),
      body: Column(
        children: [
          Text('(只支持腾讯的fileId/m3u8视频下载)'),
          Text('请先自行设置文件读写权限', style: TextStyle(color: Colors.red),),
          getItem(0),
          getItem(1),
        ],
      ),
    );
  }

  Widget getItem(int index) {
    if (_downloadController == null) {
      return SizedBox();
    }
    DownloadValue? value = _downloadController!.value[urlList[index]];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(getStatusTxt(value?.downloadStatus ?? '')),
                    SizedBox(width: 10,),
                    value != null ? Text('${((value.downloadSize)!/1024/1024).toStringAsFixed(2)}M/${((value.size)!/1024/1024).toStringAsFixed(2)}M') : SizedBox(),
                  ],
                ),
                SizedBox(width: 10,),
                value?.playPath != null ? GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => FullVideoPage(playType: PlayType.file, dataSource: value?.playPath, showClearBtn: false,)));
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Color(0xfffe373c)),
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                    child: Image.asset('static/player_play.png', color: Color(0xfffe373c),),
                  ),
                ): SizedBox(),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (value?.downloadStatus == 'progress') {
                  _downloadController!.pauseDownload(urlList[index]);
                } else {
                  _downloadController!.dowload(urlList[index]);
                }
              },
              child: Text(getBtnTxt(value?.downloadStatus ?? ''), style: TextStyle(color: Colors.blue),),
            ),
          ],
        ),
      ),
    );
  }

  String getStatusTxt(String downloadStatus) {
    String tip = '';
    switch (downloadStatus) {
      case 'start':
        tip = '开始下载中';
        break;
      case 'progress':
        tip = '下载中';
        break;
      case 'stop':
        tip = '已暂停';
        break;
      case 'complete':
        tip = '已完成';
        break;
      case 'error':
        tip = '下载出错';
    }
    return tip;
  }

  String getBtnTxt(String downloadStatus) {
    String tip = '开始下载';
    switch (downloadStatus) {
      case 'progress':
        tip = '暂停';
        break;
    }
    return tip;
  }

}
