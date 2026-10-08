import 'package:flutter/material.dart';

import '../../../core/navigation/main_tab.dart';
import '../../../core/widgets/tab_placeholder_page.dart';

/// 赚钱标签页，当前为空页面占位。
class EarnPage extends StatelessWidget {
  const EarnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholderPage(
      key: Key(MainTab.earn.pageKey!),
      title: MainTab.earn.label,
    );
  }
}
