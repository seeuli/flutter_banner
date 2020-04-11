import 'dart:async';
import 'package:flutter/material.dart';

import 'banner_delegate.dart';
import 'page_indicator_widget.dart';

/// 实现思路：使用 n+2 个视图，在达到边界时滚动PageView到对应的页面。PageView的page不是真正的页码，页码需要单独计算。
/// 
///   * 边界1：当前页面为第0页，左滑切换到倒数第1页，此时调整PageView到倒数第二个位置，便于继续左滑；
/// 
///   * 边界2：当前索引为倒数第1页，右滑到第0页，此时调整PageView到第1个位置，便于继续右滑。
/// 
/// 其他实现方案：
/// 
///   1、同样采用 n+2 个视图的banner_view[https://github.com/yangxiaoweihn/BannerView]；
/// 
///   2、采用 n*IntegerMax 个视图的flutter_banner_swiper[https://github.com/liuwangle/flutter_banner_swiper]。
class BannerWidget extends StatefulWidget {

  BannerWidget({
    @required this.delegate,
    this.onPageChange,
    this.pageIndicator,
  }): assert(delegate != null);
  
  final BannerDelegate delegate;
  final void Function(int, int) onPageChange;
  /// 单页时隐藏 Indicator
  final PageIndicator pageIndicator;

  // 当前页码
  int get currentPage => _pageNotifier.value;
  final ValueNotifier<int> _pageNotifier = ValueNotifier(0);

  @override
  State<StatefulWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  /// 当前页码
  int _currentPage = 0;
  /// 构建PageView子视图
  List<Widget> _children = List();
  /// 保留最原始的数据，即根据数据源 widget.delegate.numberOfBanners 创建的widget
  List<Widget> _cache = List();
  /// PageView 页码控制
  PageController _pageController;
  /// 总页数
  int get _numberOfPages => widget.delegate.numberOfBanners;
  /// PageView 滚动页数。总页数请使用 _numberOfPages
  int get _pages => _infinite ? _numberOfPages + 2 : _numberOfPages;
  /// 当前索引，页码请使用_currentPage
  int _index = 0;
  /// _pageController.jumpToPage方法调用，调整PageView位置。
  bool _jumping = false;
  /// 是否无限滚动
  bool get _infinite => widget.delegate.infinite && _numberOfPages > 1;
  /// 是否自动滚动
  bool get _autoLoop => widget.delegate.autoLoop && _numberOfPages > 1;
  /// 自动滚动定时器
  Timer _autoLoopTimer;
  /// 是否用户拖拽
  bool _userDraging = false;
  /// 用户手势检测
  Timer _userGestureDetectorTimer;
  /// 用户手势检测次数计数。目前间隔50毫秒计数一次，累计 _needDetectorUserGestureTimes 次如果没有调用停止滚动，默认开启自动滚动定时器。
  /// 有可能检测 _needDetectorUserGestureTimes 次之后用户手指还在PageView上，但这时已经没有太大意义了。
  int _userGestureDetectorCounter = 0;
  /// 总共检测用户手势的次数
  final int _needDetectorUserGestureTimes = 30;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    for (int idx = 0; idx < _numberOfPages; idx ++) {
      Widget item = widget.delegate.childAtIndex(idx);
      _cache.add(item);
    }
    _children.addAll(_cache);

    if (_infinite || _autoLoop) {
      _children.insert(0, _cache.last);
      _children.add(_cache.first);
      _pageController = PageController(initialPage: 1);
      _index = 1;
    }
    else {
      _pageController = PageController();
    }

    if (_autoLoop) {
      _startAutoLoopTimer();
    }

    widget._pageNotifier.value = _currentPage;
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    _stopAutoLoopTimer();
    _stopUserGestureDetectorTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_numberOfPages == 0)  return Container(height: 0,);

    Widget contentWidget = _contentWidget();
    if (_autoLoop == false)   return contentWidget;

    return NotificationListener(
      child: contentWidget,
      onNotification: _notificationListener,
    );
  }

  void _startAutoLoopTimer() {
    if (_autoLoop == false || _autoLoopTimer != null) return;
    Duration autoLoopInterval = widget.delegate.autoLoopInterval ?? Duration(seconds: 3); 
    _autoLoopTimer = Timer.periodic(autoLoopInterval, (timer) {
      int page = _index + 1;
      _pageController.animateToPage(page,
        duration: widget.delegate.duration ?? Duration(milliseconds: 250), 
        curve: widget.delegate.curve ?? Curves.easeInOut,
      );
    });
  }

  void _stopAutoLoopTimer() {
    if (_autoLoop == false || _autoLoopTimer == null) return;
    _autoLoopTimer.cancel();
    _autoLoopTimer = null;
  }

  // 开启用户手势检测轮询
  void _startUserGestureDetectorTimer() {
    if (_autoLoop == false || _userGestureDetectorTimer != null)  return;
    _userGestureDetectorTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      _debugLog('Detector --- $_userDraging, $_userGestureDetectorCounter');
      if (_userDraging == false || _userGestureDetectorCounter >= _needDetectorUserGestureTimes) {
        _userDraging = false;
        _userGestureDetectorCounter = 0;
        _stopUserGestureDetectorTimer();
        _startAutoLoopTimer();
      }
      else {
        _userGestureDetectorCounter ++;
      }
    });
  }

  void _stopUserGestureDetectorTimer() {
    if (_autoLoop == false || _userGestureDetectorTimer == null)  return;
    _userGestureDetectorTimer.cancel();
    _userGestureDetectorTimer = null;
  }

  // UserScrollNotification 之后可能不会调用 ScrollEndNotification
  // 需要开启轮询检测用户当前是否还在拖拽
  bool _notificationListener(Notification noti) {
    if (noti is UserScrollNotification) {
      _debugLog('用户拖拽 --- ${noti.runtimeType}');
      if (_userDraging == false) {  // 用户开始触摸
        _userDraging = true;
      }
      else {
        _userGestureDetectorCounter = 0;  // 清空计数
      }
      // 用户拖拽需要一直检测手势是否移除，自动翻页定时器一直停止
      _startUserGestureDetectorTimer();
      _stopAutoLoopTimer();
    }
    else if (noti is ScrollStartNotification) { // 调用一次
      _debugLog('开始滚动 --- ${noti.runtimeType}');
    }
    else if (noti is ScrollUpdateNotification) {  // 滚动中多次调用
    }
    else if (noti is ScrollEndNotification) {
      _debugLog('结束滚动 --- ${noti.runtimeType}');
      if (_userDraging) {   // 停止滚动
        _stopUserGestureDetectorTimer();
        _userDraging = false;
        _startAutoLoopTimer();
      }
    }
    return false;
  }

  void _pageChange(int page) {
    int prePage = _currentPage;
    if (_infinite == false && _autoLoop == false) {
      _currentPage = page;
      if (widget.onPageChange != null) {
        widget.onPageChange(prePage, _currentPage);
      }
      widget._pageNotifier.value = _currentPage;
      _updateIndicator();
      return;
    }

    if (_jumping) {  // PageView自身滚动区域调整，这时不需要再次调用 widget.onPageChange。否则会调用多次
      _jumping = false;
      return;
    }
    if (_index == _pages - 2 && page == _pages - 1) {
      // 当前已是最后一页，但仍然向左拖拽。需要恢复到第0页。
      _index = 1;
      _currentPage = 0;
      _debugLog('_BannerWidgetState.jumpToPage 0 $page idx:$_index, page:$_currentPage');
      _jumping = true;
      Future.delayed(Duration(milliseconds: 250)).whenComplete(() {
        _pageController.jumpToPage(_index);
      });
    }
    else if (_index == 1 && page == 0) {
      // 当前是第0页，但仍然向右拖拽。需要恢复到最后一页。
      _index = _pages - 2;
      _currentPage = _numberOfPages - 1;
      _debugLog('_BannerWidgetState.jumpToPage 1, $page idx:$_index, page:$_currentPage');
      _jumping = true;
      Future.delayed(Duration(milliseconds: 250)).whenComplete(() {
        _pageController.jumpToPage(_index);
      });
    }
    else {
      _index = page;
      _currentPage = page - 1;
    }

    if (widget.onPageChange != null) {
      widget.onPageChange(prePage, _currentPage);
    }
    widget._pageNotifier.value = _currentPage;
    _updateIndicator();
    _debugLog('_BannerWidgetState._pageChange idx:$_index, page:$_currentPage');
  }

  void _updateIndicator() {
    if (widget.pageIndicator == null) return;
    widget.pageIndicator.currentPage.value = _currentPage;
  }

  void _debugLog(String log) {
    if (widget.delegate.disableLog) return;
    if (bool.fromEnvironment("dart.vm.product"))  return;
    debugPrint(log);
  }

  Widget _contentWidget() {
    Widget contentWidget = _cache.first;
    if (_numberOfPages > 1) {
      PageView pageView = PageView(
        scrollDirection: widget.delegate.scrollDirection ?? Axis.horizontal,
        children: _children,
        controller: _pageController,
        onPageChanged: _pageChange,
      );
      if (widget.pageIndicator != null) { // 展示 Indicator
        contentWidget = Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            pageView,
            _indicatorWidget(),
          ],
        );
      }
      else {
        contentWidget = pageView;
      }
    }

    return GestureDetector(
      child: Container(
        child: contentWidget,
        decoration: widget.delegate.decoration ?? BoxDecoration(color: Colors.white),
        width: widget.delegate.width,
        height: widget.delegate.height,
      ),
      onTap: () {
        if (widget.delegate.onTap == null)  return;
        widget.delegate.onTap(_currentPage);
      },
    );
  }

  Widget _indicatorWidget() {
    return Column(
      children: <Widget>[
        Expanded(child: Container()),
        Padding(
          padding: widget.delegate.indicatorInsets ?? EdgeInsets.only(bottom: 12),
          child: widget.pageIndicator,
        ),
      ],
    );
  }
}