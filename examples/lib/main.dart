import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_banner/banner_widget.dart';

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

  BannerWidget _bannerWidget;

  @override
  void initState() {
    super.initState();

    List<String> data = ['Page 0', 'Page 1', 'Page 2'];
    List<Color> colors = [Colors.amberAccent, Colors.blueAccent];
    _bannerWidget = BannerWidget(
      delegate: BannerDelegate(
        autoLoop: true,
        infinite: true,
        childAtIndex: (int idx) {
          return Container(
            color: colors[idx % 2],
            child: Center(
              child: Text(data[idx],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.cyan,
                ),
              ),
            )
          );
        },
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        onTap: (int index) {
          print('onTap $index');
        },
      ),
      onPageChange: (int _old, int _new) {
        print('onPageChange: $_old to $_new');
      },
      pageIndicator: PageIndicator(),
    );
    _bannerWidget.delegate.numberOfBanners.value = data.length;
    _bannerWidget.pageIndicator.numberOfPages.value = data.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.orangeAccent,
      body: Column(
        children: <Widget>[
          Center(
            child: Container(
              child: _bannerWidget,
              width: 200,
              height: 80,
            ),
          ),
          RaisedButton(
            child: Text('stop Loop'),
            onPressed: () {
              _bannerWidget.stopLoop();
            },
          ),
          RaisedButton(
            child: Text('start Loop'),
            onPressed: () {
              _bannerWidget.startLoop();
            },
          ),
        ]
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
