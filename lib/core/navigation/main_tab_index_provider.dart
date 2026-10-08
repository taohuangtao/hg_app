import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main_tab.dart';

/// 当前选中的底部导航标签索引。
///
/// 切换标签只更新索引，不做路由跳转，首页播放器因此常驻不被销毁。
final mainTabIndexProvider = NotifierProvider<MainTabIndexController, int>(
  MainTabIndexController.new,
);

class MainTabIndexController extends Notifier<int> {
  @override
  int build() => MainTab.home.index;

  void select(int index) {
    if (state == index) return;
    state = index;
  }
}
