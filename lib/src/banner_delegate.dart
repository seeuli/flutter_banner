import 'package:flutter/material.dart';

class BannerDelegate {
  BannerDelegate({
    this.autoLoop = false,
    this.infinite = true,
    this.decoration,
    this.onTap,
    this.disableLog = true,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 250),
    this.autoLoopInterval = const Duration(seconds: 3),
    this.scrollDirection = Axis.horizontal,
    this.bannerInsets = EdgeInsets.zero,
    this.indicatorInsets = const EdgeInsets.only(bottom: 12),
    @required this.childAtIndex,
  }): assert(childAtIndex != null);

  /// banner页数
  final ValueNotifier<int> numberOfBanners = ValueNotifier(0);
  /// 自动循环，设置为ture时忽略infinite属性，默认可无限循环；data长度小于2时无效；
  final bool autoLoop;
  /// 首尾切换效果跟其他页面一致(无限循环)，在不使用autoLoop时也可无限滚动；data长度小于2时无效
  final bool infinite;
  /// 翻页时间
  final Duration duration;
  /// 页面切换动画样式
  final Curve curve;
  /// 翻页间隔时间
  final Duration autoLoopInterval;
  /// 第 idx 位置元素
  final Widget Function(int) childAtIndex;
  /// 点击第 idx 位置元素
  final void Function(int) onTap;
  /// 滚动方向
  final Axis scrollDirection;
  /// banner间距
  final EdgeInsets bannerInsets;
  /// indicator 间距
  final EdgeInsets indicatorInsets;
  /// 背景色
  final BoxDecoration decoration;
  /// 禁用调试日志，默认true
  final bool disableLog;
}