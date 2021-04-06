import 'package:flutter/material.dart';
import 'package:flutter_forbidshot/flutter_forbidshot.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter_tencentplayer_example/util/common_util.dart';
import 'package:flutter_tencentplayer_example/util/time_util.dart';
import 'package:flutter_tencentplayer_example/util/widget_util.dart';
import 'package:screen/screen.dart';
class TencentPlayerGestureCover extends StatefulWidget {
  final TencentPlayerController controller;
  final bool showBottomWidget;
  final VoidCallback? behavingCallBack; //正在交互

  TencentPlayerGestureCover({
    required this.controller,
    this.showBottomWidget = true,
    this.behavingCallBack,
  });

  @override
  _TencentPlayerGestureCoverState createState() => _TencentPlayerGestureCoverState();
}

class _TencentPlayerGestureCoverState extends State<TencentPlayerGestureCover> {
  GlobalKey currentKey = GlobalKey();
  TencentPlayerController get controller => widget.controller;

  bool _controllerWasPlaying = false;
  bool showSeekText = false;
  bool? leftVerticalDrag;

  Duration? seekPos;

  //UI
  IconData iconData = Icons.volume_up;
  String text = '';

  @override
  Widget build(BuildContext context) {
    Duration? showDuration = seekPos != null ? seekPos : controller.value.position;

    return GestureDetector(
      key: currentKey,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ///跳转进度
            showSeekText && widget.showBottomWidget ? Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.width / 3),
              child: Container(
                width: 150,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0x7f000000),
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(TimeUtil.formatDuration(showDuration!), style: TextStyle(
                      color: Color(0xfffe373c),
                      fontSize: 18,
                    ),),
                    Text('/' + TimeUtil.formatDuration(controller.value.duration), style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),),
                  ],
                ),
              ),
            ): SizedBox(),
            ///亮度and音量
            leftVerticalDrag != null ? Container(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0x7f000000),
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(iconData, color: Color(0x88FE373C), size: 25,),
                  Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Text(text, style: TextStyle(
                      color: Color(0x88FE373C),
                      fontSize: 18,
                    )),
                  ),
                ],
              ),
            ): SizedBox()
          ],
        ),
      ),
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.initialized || !widget.showBottomWidget) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }
        setState(() {
          seekPos = controller.value.position;
          showSeekText = true;
        });
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.initialized || !widget.showBottomWidget) {
          return;
        }
        seekToAbsolutePosition(details.delta);
      },
      onHorizontalDragEnd: (DragEndDetails details) async {
        if (!widget.showBottomWidget) {
          return;
        }
        await controller.seekTo(seekPos!);
        seekPos = null;
        if (_controllerWasPlaying) {
          controller.play();
        }
        setState(() {
          showSeekText = false;
        });
      },
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
    );
  }

  void seekToAbsolutePosition(Offset delta) {
    if (seekPos == null) return;
    seekPos = seekPos! + Duration(milliseconds: 800) * delta.dx;
    if (seekPos! < Duration()) {
      seekPos = Duration();
    } else if (seekPos! > controller.value.duration) {
      seekPos = controller.value.duration;
    }
    if (mounted) setState(() {});
    /// 回调正在交互，用来做延迟隐藏cover
    CommonUtils.throttle(() {
      widget.behavingCallBack?.call();
    });
  }


  double currentVolume = 0.0;
  _onVerticalDragStart(DragStartDetails details) async {
    double width = WidgetUtil.findGlobalRect(currentKey)!.width;
    double xOffSet = WidgetUtil.globalOffsetToLocal(currentKey, details.globalPosition)!.dx;
    leftVerticalDrag = xOffSet / width <= 0.5;
    if (leftVerticalDrag == false) {
      currentVolume = await FlutterForbidshot.volume;
    }
  }

  _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (leftVerticalDrag == true) {
      double targetBright = ((await Screen.brightness) - details.delta.dy * 0.01).clamp(0.0, 1.0);
      Screen.setBrightness(targetBright);

      if (targetBright >= 0.66) {
        iconData = Icons.brightness_high;
      } else if(targetBright < 0.66 && targetBright > 0.33) {
        iconData = Icons.brightness_medium;
      } else {
        iconData = Icons.brightness_low;
      }

      text = (targetBright * 100).toStringAsFixed(0);
      if (mounted) setState(() {});

      CommonUtils.throttle(() {
        widget.behavingCallBack?.call();
      });
    } else if (leftVerticalDrag == false) {
      double targetVolume = (currentVolume - details.delta.dy * 0.01).clamp(0.0, 1.0);
      FlutterForbidshot.setVolume(targetVolume);

      if (targetVolume >= 0.66) {
        iconData = Icons.volume_up;
      } else if(targetVolume < 0.66 && targetVolume > 0.33) {
        iconData = Icons.volume_down;
      } else {
        iconData = Icons.volume_mute;
      }
      currentVolume = targetVolume;
      text = (targetVolume * 100).toStringAsFixed(0);
      if (mounted) setState(() {});

      CommonUtils.throttle(() {
        widget.behavingCallBack?.call();
      });
    }

  }

  _onVerticalDragEnd(DragEndDetails details) {
    leftVerticalDrag = null;
  }

}