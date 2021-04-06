import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';

class TencentPlayer extends StatefulWidget {
  static MethodChannel channel = const MethodChannel('flutter_tencentplayer')..invokeMethod<void>('init');

  final TencentPlayerController controller;

  TencentPlayer(this.controller);

  @override
  _TencentPlayerState createState() => new _TencentPlayerState();
}

class _TencentPlayerState extends State<TencentPlayer> {
  VoidCallback? _listener;
  int? _textureId = 0;

  _TencentPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId!;
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
    widget.controller.addListener(_listener!);
  }

  @override
  void didUpdateWidget(TencentPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.dataSource != widget.controller.dataSource) {
      if (Platform.isAndroid) oldWidget.controller.dispose();
    }
    oldWidget.controller.removeListener(_listener!);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener!);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener!);
  }

  @override
  Widget build(BuildContext context) {
    if (_textureId == null) {
      return Container();
    } else {
      if ((widget.controller.value.degree / 90).floor() == 0) {
        return Texture(textureId: _textureId!);
      } else {
        return RotatedBox(quarterTurns: (widget.controller.value.degree / 90).floor(), child: Texture(textureId: _textureId!));
      }
    }
  }
}
