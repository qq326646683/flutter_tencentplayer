import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

class TencentPlayer extends StatefulWidget {
  static MethodChannel channel = const MethodChannel('flutter_tencentplayer')

    /// init方法是TencentPlayer 第一次加载的时候执行 并且只是执行一次
    ..invokeMethod<void>('init');

  final TencentPlayerController controller;

  TencentPlayer(this.controller);

  @override
  _TencentPlayerState createState() => new _TencentPlayerState();
}

class _TencentPlayerState extends State<TencentPlayer> {
  VoidCallback _listener;
  int _textureId;

  _TencentPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);

    print("TencentPlayer  initState");
  }

  @override
  void didUpdateWidget(TencentPlayer oldWidget) {
    //print("TencentPlayer  didUpdateWidget");
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    print("TencentPlayer  deactivate");
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null ? Container() : Texture(textureId: _textureId);
  }

  @override
  void dispose() {
    print("TencentPlayer  dispose");
    widget.controller.dispose();
    super.dispose();
  }
}
