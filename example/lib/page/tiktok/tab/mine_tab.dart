import 'package:flutter/material.dart';

class MineTab extends StatefulWidget {
  @override
  _MineTabState createState() => _MineTabState();
}

class _MineTabState extends State<MineTab> with AutomaticKeepAliveClientMixin<MineTab>{
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Text('mine'),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

