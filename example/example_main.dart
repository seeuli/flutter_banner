import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../lib/banner_widget.dart';

void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  BannerDelegate _bannerDelegate;
  BannerWidget _bannerWidget;

  @override
  void initState() {
    super.initState();

    List<String> data = ['Page 0', 'Page 1', 'Page 2'];
    _bannerDelegate = BannerDelegate(
      autoLoop: true,
      infinite: true,
      childAtIndex: (int idx) {
        return Text(data[idx],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.cyan,
          ),
        );
      },
      numberOfBanners: data.length,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      onTap: (int index) {
        print('onTap $index');
      },
      width: 200,
      height: 60,
    );
    _bannerWidget = BannerWidget(
      delegate: _bannerDelegate,
      onPageChange: (int _old, int _new) {
        print('onPageChange: $_old to $_new');
      },
      pageIndicator: PageIndicator(numberOfPages: data.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.orangeAccent,
      body: Center(
        child: _bannerWidget,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
