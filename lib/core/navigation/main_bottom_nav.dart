import 'package:flutter/material.dart';

import 'main_tab.dart';

/// 全局共享的底部导航，只有一份实例，挂载在 [MainShellPage] 的 Scaffold 上。
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 与播放器布局保持一致，供外部复用，避免多处硬编码。
  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Container(
        color: const Color(0xFF222222),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (final tab in MainTab.values)
                      _BottomNavItem(
                        key: Key(tab.navItemKey),
                        label: tab.label,
                        selected: tab.index == currentIndex,
                        muted: tab.muted,
                        onTap: () => onTap(tab.index),
                      ),
                  ],
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 4,
                  child: Row(
                    children: [
                      Spacer(flex: 3),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: _EarnBadge(),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                const Positioned(
                  right: 21,
                  top: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B00),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 7, height: 7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.muted,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : muted
        ? const Color(0xFF747474)
        : const Color(0xFF878787);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: _NavText(
              label,
              size: 17,
              weight: selected ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _EarnBadge extends StatelessWidget {
  const _EarnBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 19,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const _NavText('赚钱', size: 10, weight: FontWeight.w800),
    );
  }
}

class _NavText extends StatelessWidget {
  const _NavText(
    this.text, {
    required this.size,
    required this.weight,
    this.color = Colors.white,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0,
        fontFamily: 'Noto Sans SC',
      ),
    );
  }
}
