import 'package:flutter/material.dart';

import '../../../core/navigation/main_tab.dart';
import '../../../core/widgets/tab_placeholder_page.dart';

/// 剧场标签页，当前为空页面占位。
class TheaterPage extends StatelessWidget {
  const TheaterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholderPage(
      key: Key(MainTab.theater.pageKey!),
      title: MainTab.theater.label,
    );
  }
}
