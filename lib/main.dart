import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'pager_list.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EasyListView Demo',
        theme: ThemeData(accentColor: Colors.pinkAccent),
        home: MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PagerListView(
          headerBuilder: headerBuilder,
//          footerBuilder: footerBuilder,
          itemBuilder: itemBuilder,
          pagerBuilder: pageBuilder,
          useLoadMore: true,
          pageSize:20,
        ),
      );


  var headerBuilder = (context) => Container(
        color: Colors.blue,
        height: 100.0,
        alignment: AlignmentDirectional.center,
        child: Text(
          "This is header",
          style: TextStyle(
            fontSize: 24.0,
            color: Colors.white,
          ),
        ),
      );

  var footerBuilder = (context) => Container(
        color: Colors.green,
        height: 100.0,
        alignment: AlignmentDirectional.center,
        child: Text(
          "This is footer",
          style: TextStyle(
            fontSize: 24.0,
            color: Colors.white,
          ),
        ),
      );

  static List<Widget> sliverItems = List.generate(
    10,
    (index) => Container(
          color: Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0)
              .withOpacity(1.0),
          padding: EdgeInsets.all(8.0),
          height: 60.0,
          alignment: AlignmentDirectional.center,
          child: Text(
            "This is sliver item \nin CustomScrollView",
            style: TextStyle(color: Colors.white),
          ),
        ),
  );

  var itemBuilder = (context,data, index) =>  Container(
            height: 60.0,
            alignment: AlignmentDirectional.center,
            child: Text(
              data,
              style: TextStyle(color: Colors.black87),
            ),
        );


  Future<List<String>> pageBuilder(int page,List currentDatas) async {
    await Future.delayed(Duration(seconds: 0, milliseconds: 2000));
    List<String> dummyList = List();
    //测试第三页加载失败
    if(page == 3) {
      throw FormatException('处理失败，请重试');
    }

    // 测试空数据
//   if(page == 1) {
//     return dummyList;
//   }

    int start = 0;
    if(currentDatas != null && page > 1) {
      start = currentDatas.length;
    }
    for (int i = start; i < start + 20; i++) {
      dummyList.add('Item $i');
    }
    return dummyList;
  }

  var headerSliverBuilder = (context, _) => [
        SliverAppBar(
          expandedHeight: 120.0,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Container(
              child: Text(
                "Sliver App Bar",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ),
      ];
}
