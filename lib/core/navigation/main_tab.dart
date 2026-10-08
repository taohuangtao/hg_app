/// 底部导航的标签定义，作为标签文案、页面键名与索引的唯一来源。
enum MainTab { home, theater, mall, earn, profile }

extension MainTabX on MainTab {
  String get label {
    switch (this) {
      case MainTab.home:
        return '首页';
      case MainTab.theater:
        return '剧场';
      case MainTab.mall:
        return '商城';
      case MainTab.earn:
        return '赚钱';
      case MainTab.profile:
        return '我的';
    }
  }

  /// 未选中时是否使用更暗的灰色，保持与原设计一致的层级。
  bool get muted {
    switch (this) {
      case MainTab.home:
      case MainTab.theater:
        return false;
      case MainTab.mall:
      case MainTab.earn:
      case MainTab.profile:
        return true;
    }
  }

  /// 底部导航单项的测试键。
  String get navItemKey => 'bottom-nav-$name';

  /// 标签页面的测试键，首页沿用播放器内容，不需要额外页面键。
  String? get pageKey {
    switch (this) {
      case MainTab.home:
        return null;
      case MainTab.theater:
        return 'theater-page';
      case MainTab.mall:
        return 'mall-page';
      case MainTab.earn:
        return 'earn-page';
      case MainTab.profile:
        return 'profile-page';
    }
  }
}
