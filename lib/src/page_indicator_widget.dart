import 'package:flutter/material.dart';


class PageIndicator extends StatefulWidget {

  PageIndicator({
    this.indicatorBuilder = PageIndicator.normalStyleBuilder,
    this.selectedIndicatorBuilder = PageIndicator.selectedStyleBuilder,
    this.padding = 10.0,
    @required this.numberOfPages,
  }) :  assert(indicatorBuilder != null && selectedIndicatorBuilder != null),
        assert(numberOfPages != null && numberOfPages > 0);


  /// 总共多少页
  final int numberOfPages;
  /// 每个Indicator的间距
  final double padding;
  /// 正常状态Indicator构建，默认为PageIndicator.builder函数，可自定义
  final Widget Function() indicatorBuilder;
  /// 选中的Indicator
  final Widget Function() selectedIndicatorBuilder;
  /// 页码变化通知，_PageIndicatorState监听页码变化而滚动
  final ValueNotifier<int> currentPage = ValueNotifier(0);

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

  @override
  State<StatefulWidget> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  int _prePage = 0;
  List<Widget> _indicators = List();

  void reload() {
    if (context == null || mounted == false)  return;
    if (_prePage < 0 || _prePage >= widget.numberOfPages) return;
    int curPage = widget.currentPage.value;
    if (curPage < 0 || curPage >= widget.numberOfPages) return;
    if (_prePage == curPage) return;

    // 交换 上一页(_prePage) 与 当前页(curPage) Indicator 位置
    Widget preWidget = _indicators[_prePage];
    Widget curWidget = _indicators[curPage];
    _indicators[curPage] = preWidget;
    _indicators[_prePage] = curWidget;
    // 更新索引
    _prePage = widget.currentPage.value;

    setState(() { });
  }

  @override
  void initState() {
    super.initState();
    _prePage = widget.currentPage.value;
    for (int idx = 0; idx < widget.numberOfPages - 1; idx ++) {
      _indicators.add(widget.indicatorBuilder());
    }
    _indicators.insert(_prePage, widget.selectedIndicatorBuilder());
    widget.currentPage.addListener(reload);
  }

  @override
  void dispose() {
    super.dispose();
    widget.currentPage.removeListener(reload);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _children(),
      mainAxisAlignment: MainAxisAlignment.center,
    );
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