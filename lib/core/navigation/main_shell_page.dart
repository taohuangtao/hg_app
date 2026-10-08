import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/earn/presentation/earn_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/mall/presentation/mall_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/theater/presentation/theater_page.dart';
import 'main_bottom_nav.dart';
import 'main_tab_index_provider.dart';

/// 底部导航 Shell：所有标签页常驻在 IndexedStack 中，切换只改索引，不重建页面。
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  static const List<Widget> tabPages = [
    HomePage(),
    TheaterPage(),
    MallPage(),
    EarnPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: currentIndex, children: tabPages),
      bottomNavigationBar: MainBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainTabIndexProvider.notifier).select(index),
      ),
    );
  }
}
