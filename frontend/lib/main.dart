import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoclass/core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // ProviderScope is mandatory for Riverpod to store state
  runApp(
    const ProviderScope(
      child: PhotoClassApp(),
    ),
  );
}

class PhotoClassApp extends ConsumerWidget {
  const PhotoClassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Photo Classification Platform',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
