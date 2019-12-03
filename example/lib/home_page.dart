import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer_example/video_play_page.dart';

var launch = MaterialApp(
  title: "App",
  home: HomePage(),
);

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('主界面'),
      ),
      body: Center(
          child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: RaisedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => VideoPlayPage()));
            },
            child: const Text('进入播放器')),
      )),
    );
  }
}
