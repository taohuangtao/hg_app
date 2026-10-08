import 'package:flutter/material.dart';

import '../../../core/navigation/main_tab.dart';
import '../../../core/widgets/tab_placeholder_page.dart';

/// 商城标签页，当前为空页面占位。
class MallPage extends StatelessWidget {
  const MallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TabPlaceholderPage(
      key: Key(MainTab.mall.pageKey!),
      title: MainTab.mall.label,
    );
  }
}
