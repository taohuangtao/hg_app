import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final hiveInitializerProvider = FutureProvider<void>((ref) async {
  await Hive.initFlutter();
});
