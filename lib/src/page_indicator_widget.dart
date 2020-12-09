import 'package:flutter/material.dart';

class PageIndicator extends StatefulWidget {

  PageIndicator({
    this.indicatorBuilder = PageIndicator.normalStyleBuilder,
    this.selectedIndicatorBuilder = PageIndicator.selectedStyleBuilder,
    this.padding = 10.0,
  }) :  assert(indicatorBuilder != null && selectedIndicatorBuilder != null);

  /// 总共多少页
  final ValueNotifier<int> numberOfPages = ValueNotifier(0);
  /// 每个Indicator的间距
  final double padding;
  /// 正常状态Indicator构建，默认为PageIndicator.builder函数，可自定义
  final Widget Function() indicatorBuilder;
  /// 选中的Indicator
  final Widget Function() selectedIndicatorBuilder;
  /// 页码变化通知，_PageIndicatorState监听页码变化而滚动
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  // 普通样式 
  static BoxDecoration _normalDecoration = BoxDecoration(
    color: Color(0x33000000), 
    borderRadius: BorderRadius.circular(6.0),
  );
  static IndicatorStyle normalIndicatorStyle = IndicatorStyle(Size(6.0, 6.0), _normalDecoration);
  
  static Widget normalStyleBuilder() {
    IndicatorStyle style = PageIndicator.normalIndicatorStyle;
    return Container(
      decoration: style.decoration,
      width: style.size.width,
      height: style.size.height,
    );
  }

  // 选中样式 
  static BoxDecoration _selectedDecoration = BoxDecoration(
    color: Color(0x99000000),
    borderRadius: BorderRadius.circular(6.0),
  );
  static IndicatorStyle selectedIndicatorStyle = IndicatorStyle(Size(6.0, 6.0), _selectedDecoration);

  static Widget selectedStyleBuilder() {
    IndicatorStyle style = PageIndicator.selectedIndicatorStyle;
    return Container(
      decoration: style.decoration,
      width: style.size.width,
      height: style.size.height,
    );
  }

  /// 更新当前展示的页数
  void updateCurrentPage(int page) => _currentPage.value = page;

  @override
  State<StatefulWidget> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  int _prePage = 0;
  List<Widget> _indicators = List();

  @override
  void initState() {
    super.initState();
    _createDots();
    widget._currentPage.addListener(_reload);
  }

  @override
  void dispose() {
    widget._currentPage.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        children: _children(),
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  // 页面数量没变化时更改page
  void _reload() {
    if (context == null || mounted == false)  return;
    if (_prePage < 0 || _prePage >= widget.numberOfPages.value) return;
    int curPage = widget._currentPage.value;
    if (curPage < 0 || curPage >= widget.numberOfPages.value) return;
    if (_prePage == curPage) return;

    // 交换 上一页(_prePage) 与 当前页(curPage) Indicator 位置
    Widget preWidget = _indicators[_prePage];
    Widget curWidget = _indicators[curPage];
    _indicators[curPage] = preWidget;
    _indicators[_prePage] = curWidget;
    // 更新索引
    _prePage = widget._currentPage.value;

    setState(() { });
  }

  // 创建Indicator圆点
  void _createDots() {
    _indicators.clear();
    for (int idx = 0; idx < widget.numberOfPages.value - 1; idx ++) {
      _indicators.add(widget.indicatorBuilder());
    }
    _indicators.insert(_prePage, widget.selectedIndicatorBuilder());
  }

  List<Widget> _children() {
    List<Widget> items = List();
    _indicators.forEach((indicator) {
      items.add(indicator);
      Container padding = Container(width: widget.padding,);
      items.add(padding);
    });
    items.removeLast(); // 移除最后添加的padding
    return items;
  }
}


class IndicatorStyle {
  IndicatorStyle(this.size, this.decoration)
    : assert(size != null && decoration != null);

  final Size size;
  final BoxDecoration decoration;
}