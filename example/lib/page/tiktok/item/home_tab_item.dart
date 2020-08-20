import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

class HomeTabItem extends StatefulWidget {
  final int index;
  final String url;

  HomeTabItem(this.index, this.url);

  @override
  _HomeTabItemState createState() => _HomeTabItemState();
}

class _HomeTabItemState extends State<HomeTabItem> with AutomaticKeepAliveClientMixin<HomeTabItem>{
  String fileBase = 'http://file.jinxianyun.com/';
  TencentPlayerController controller;
  VoidCallback listener;

  _HomeTabItemState() {
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
    print('initState:${widget.index}:${widget.url}');
    controller = TencentPlayerController.network('$fileBase${widget.url}', playerConfig: PlayerConfig(loop: true))
      ..initialize()
      ..addListener(listener);
  }

  @override
  void dispose() {
    print('dispose:${widget.index}:${widget.url}');
    controller.removeListener(listener);
    controller.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return controller.value.initialized
        ? GestureDetector(
            onTap: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            },
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: TencentPlayer(controller),
                ),
                !controller.value.isPlaying ? Icon(Icons.play_arrow, size: 100, color: Colors.white70,): SizedBox(),
              ],
            ),
          )
        : Image.asset('static/place_nodata.png');
  }

  @override
  bool get wantKeepAlive => true;
}
