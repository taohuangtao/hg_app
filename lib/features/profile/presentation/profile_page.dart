import 'package:flutter/material.dart';

import '../../../core/navigation/main_tab.dart';
import '../../../core/widgets/tab_placeholder_page.dart';

/// 我的标签页，当前为空页面占位。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholderPage(
      key: Key(MainTab.profile.pageKey!),
      title: MainTab.profile.label,
    );
  }
}
