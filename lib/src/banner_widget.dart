import 'dart:async';
import 'package:flutter/material.dart';

import 'banner_delegate.dart';
export 'banner_delegate.dart';

import 'page_indicator_widget.dart';
export 'page_indicator_widget.dart';

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
/// 
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

  /// 轮播控制
  final ValueNotifier<bool> _stopLoopNotifier = ValueNotifier(false);
 
  /// 停止滚动
  void stopLoop() => _stopLoopNotifier.value = true;
 
  /// 开始滚动
  void startLoop() => _stopLoopNotifier.value = false;
 
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
  /// 页面动画持续时长
  Duration _pagingDuration;
  /// 总页数
  int get _numberOfPages => widget.delegate.numberOfBanners.value;
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
    _setup();
    widget._stopLoopNotifier.addListener(_loopControl);
    widget.delegate.numberOfBanners.addListener(_bannerTotalPagesChange);
    if (_autoLoop) {
      _startAutoLoopTimer();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stopAutoLoopTimer();
    _stopUserGestureDetectorTimer();
    widget._stopLoopNotifier.removeListener(_loopControl);
    widget.delegate.numberOfBanners.removeListener(_bannerTotalPagesChange);
    super.dispose();
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

  /// 初始化数据
  void _setup() {
    _children.clear();
    _cache.clear();
    _currentPage = 0;
    _jumping = false;
    _userDraging = false;
    _pagingDuration = widget.delegate.duration ?? Duration(milliseconds: 250);
    _userGestureDetectorCounter = 0;
    _stopUserGestureDetectorTimer();
    _stopAutoLoopTimer();

    for (int idx = 0; idx < _numberOfPages; idx ++) {
      Widget item = widget.delegate.childAtIndex(idx);
      _cache.add(item);
    }
    _children.addAll(_cache);

    if ((_infinite || _autoLoop) && _cache.length > 1) {
      _children.insert(0, _cache.last);
      _children.add(_cache.first);
      _pageController = PageController(initialPage: 1);
      _index = 1;
    }
    else {
      _pageController = PageController();
      _index = 0;
    }
    widget._pageNotifier.value = _currentPage;
  }

  /// 总页数变化，先停止定时器，然后如果需要再重新开启
  void _bannerTotalPagesChange() {
    _setup();
    if (context != null && mounted) {
      setState(() {});
    }
    if (_autoLoop) {
      _startAutoLoopTimer();
    }
  }

  /// 轮播控制
  void _loopControl() {
    if (widget._stopLoopNotifier.value == true || _numberOfPages < 2) {
      _stopAutoLoopTimer();
    }
    else {
      _startAutoLoopTimer();
    }
  }

  void _startAutoLoopTimer() {
    if (_autoLoop == false || _autoLoopTimer != null) return;
    Duration autoLoopInterval = widget.delegate.autoLoopInterval ?? Duration(seconds: 3); 
    _autoLoopTimer = Timer.periodic(autoLoopInterval, (timer) {
      int page = _index + 1;
      _pageController.animateToPage(page,
        duration: _pagingDuration, 
        curve: widget.delegate.curve ?? Curves.easeInOut,
      );
    });
  }

  void _stopAutoLoopTimer() {
    if (_autoLoopTimer == null) return;
    _autoLoopTimer?.cancel();
    _autoLoopTimer = null;
  }

  // 开启用户手势检测轮询
  void _startUserGestureDetectorTimer() {
    if (_autoLoop == false || _userGestureDetectorTimer != null)  return;
    _userGestureDetectorTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      _debugLog('_BannerWidgetState Detector --- $_userDraging, $_userGestureDetectorCounter');
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
    _userGestureDetectorTimer?.cancel();
    _userGestureDetectorTimer = null;
  }

  // UserScrollNotification 之后可能不会调用 ScrollEndNotification
  // 需要开启轮询检测用户当前是否还在拖拽
  bool _notificationListener(Notification noti) {
    if (noti is UserScrollNotification) {
      _debugLog('_BannerWidgetState User Drag --- ${noti.runtimeType}');
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
      _debugLog('_BannerWidgetState Start Scroll --- ${noti.runtimeType}');
    }
    else if (noti is ScrollUpdateNotification) {  // 滚动中多次调用
    }
    else if (noti is ScrollEndNotification) {
      _debugLog('_BannerWidgetState End Scroll --- ${noti.runtimeType}');
      if (_userDraging) {   // 停止滚动
        _stopUserGestureDetectorTimer();
        _userDraging = false;
        _startAutoLoopTimer();
      }
    }
    return false;
  }

  void _pageChange(int page) {
    if (_infinite == false && _autoLoop == false) {
      _pageChangeNotifier(_currentPage, page);
      return;
    }

    if (_jumping) {  // PageView自身滚动区域调整，这时不需要再次调用 widget.onPageChange。否则会调用多次
      _jumping = false;
      return;
    }
    if (_index == _pages - 2 && page == _pages - 1) {
      // 当前已是最后一页，但仍然向左拖拽（或定时器继续向右滚动）。需要恢复到第0页。
      _jumping = true;
      Future.delayed(_pagingDuration).whenComplete(() {
        _index = 1;
        _pageChangeNotifier(_currentPage, 0);
        _pageController.jumpToPage(_index);
        _debugLog('0 _BannerWidgetState.jumpToPage: $page, idx $_index, page $_currentPage');
      });
    }
    else if (_index == 1 && page == 0) {
      // 当前是第0页，但仍然向右拖拽。需要恢复到最后一页。
      _jumping = true;
      Future.delayed(_pagingDuration).whenComplete(() {
        _index = _pages - 2;
        _pageChangeNotifier(_currentPage, _numberOfPages - 1);
        _pageController.jumpToPage(_index);
        _debugLog('1 _BannerWidgetState.jumpToPage: $page, idx $_index, page $_currentPage');
      });
    }
    else {  // 正常滚动、定时器滚动
      _index = page;
      _pageChangeNotifier(_currentPage, page - 1);
      _debugLog('2 _BannerWidgetState.jumpToPage: $page, idx $_index, page $_currentPage');
    }
  }

  void _pageChangeNotifier(int prePage, int curPage) {
    _currentPage = curPage;
    widget._pageNotifier.value = _currentPage;
    if (widget.onPageChange != null) {
      widget.onPageChange(prePage, curPage);
    }
    widget.pageIndicator?.updateCurrentPage(_currentPage);
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
            Padding(
              padding: widget.delegate.bannerInsets,
              child: pageView,
            ),
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
        decoration: widget.delegate.decoration ?? BoxDecoration(color: Colors.white)
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