import 'package:flutter/material.dart';
import 'package:flutter_tencentplayer_example/page/tiktok/tab/home_tab.dart';
import 'package:flutter_tencentplayer_example/page/tiktok/tab/mine_tab.dart';

class TiktokPage extends StatefulWidget {
  @override
  _TiktokPageState createState() => _TiktokPageState();
}

class _TiktokPageState extends State<TiktokPage> with TickerProviderStateMixin{
  TabController? tabController;
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                HomeTab(),
                MineTab(),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            labelColor: Colors.pink,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: 'Home',),
              Tab(text: 'Mine',),
            ],
          )
        ],
      ),
    );
  }
}
