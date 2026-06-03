import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  // ProviderScope is mandatory for Riverpod to store state
  runApp(
    const ProviderScope(
      child: PhotoClassApp(),
    ),
  );
}

// Global router configuration using GoRouter (excellent for Web URLs)
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/submit',
      builder: (context, state) => const PhotoSubmissionScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);

class PhotoClassApp extends StatelessWidget {
  const PhotoClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Photo Classification Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

//TODO: remove placeholder views and implement actual features.
// -----
// PLACEHOLDER VIEWS (To be moved to their feature folders later)
// -----

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity & Authentication')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Platform', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/submit'),
              child: const Text('Bypass Login -> Go to Photo Submission'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.go('/admin'),
              child: const Text('Bypass Login -> Go to Admin Panel'),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoSubmissionScreen extends StatelessWidget {
  const PhotoSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Submission View'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const Center(
        child: Text('Photo upload form & metadata fields go here', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard View'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const Center(
        child: Text('Admin metrics and filters go here', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}