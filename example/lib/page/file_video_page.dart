import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer/flutter_tencentplayer.dart';
import 'package:flutter_tencentplayer_example/main.dart';
import 'package:flutter_tencentplayer_example/page/index.dart';
import 'package:image_picker/image_picker.dart';

class FileVideoPage extends StatefulWidget {
  @override
  _FileVideoPageState createState() => _FileVideoPageState();
}

class _FileVideoPageState extends State<FileVideoPage> {
  ImagePicker picker = ImagePicker();
  TencentPlayerController? controller;
  VoidCallback? listener;

  _FileVideoPageState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('播放本地file${controller?.value?.degree}'),
      ),
      body: controller?.value?.initialized == true
          ? GestureDetector(
              onTap: () {
                if (controller!.value.isPlaying) {
                  controller!.pause();
                } else {
                  controller!.play();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: TencentPlayer(controller!),
                  ),
                  !controller!.value.isPlaying
                      ? Icon(
                          Icons.play_arrow,
                          size: 100,
                          color: Colors.white70,
                        )
                      : SizedBox(),
                ],
              ),
            )
          : Image.asset('static/place_nodata.png'),
      floatingActionButton: FloatingActionButton(
        onPressed: _select,
        backgroundColor: Colors.pink,
        child: Icon(Icons.photo_size_select_actual),
      ),
    );
  }

  _select() async {
    PickedFile file = await picker.getVideo(source: ImageSource.gallery);
    print(file.path);
    initPlayer(file.path);
  }

  void initPlayer(String path) {
    controller = TencentPlayerController.file(path)
      ..initialize()
      ..addListener(listener!);
  }

  @override
  void dispose() {
    controller?.removeListener(listener!);
    controller?.dispose();
    super.dispose();
  }
}
