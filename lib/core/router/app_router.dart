import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/main_shell_page.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainShellPage()),
    ],
  ),
);
