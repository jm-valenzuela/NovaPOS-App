import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: NovaPosApp()));
}

class NovaPosApp extends ConsumerWidget {
  const NovaPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'NovaPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      routerConfig: router,
    );
  }
}
