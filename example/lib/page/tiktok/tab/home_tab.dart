import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer_example/page/tiktok/item/home_tab_item.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin<HomeTab>{
  List<String> data = [
    'F95C40DA159FFA548D9DB220D9028500.mp4',
    'D2574481259D9883A571EA05FF354ACB.mp4',
    '27654ADA709264F6C12C9D2D6CE43864.mp4',
    '6438BF272694486859D5DE899DD2D823.mp4',
  ];

  int focusIndex = 0;



  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemBuilder: (_, index) => HomeTabItem(index, data[index], isFocus: focusIndex == index),
      itemCount: data.length,
      onPageChanged: (int index) {
        setState(() {
          focusIndex = index;
        });
      },
    );
  }



  @override
  bool get wantKeepAlive => true;
}
