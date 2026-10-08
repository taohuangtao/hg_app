import 'package:flutter/material.dart';

/// 标签页占位内容：黑底 + 居中标题。
///
/// 不使用 Scaffold，避免嵌套多层 Scaffold 影响全局布局与测试定位。
class TabPlaceholderPage extends StatelessWidget {
  const TabPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              fontFamily: 'Noto Sans SC',
            ),
          ),
        ),
      ),
    );
  }
}
