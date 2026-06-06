import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photoclass/features/auth/view_models/auth_view_model.dart';
import 'package:photoclass/features/auth/views/user_profile_screen.dart';
import 'features/auth/views/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/photo_submission/views/photo_submission_screen.dart';

void main() {
  // ProviderScope is mandatory for Riverpod to store state
  runApp(
    const ProviderScope(
      child: PhotoClassApp(),
    ),
  );
}

// 1. Reactive Listener that handles notifications when AuthViewModel state alters
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

// 2. Center-managed routing layer equipped with security route guarding rules
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Pull down the active state of our auth view model
      final authState = ref.read(authViewModelProvider);
      final bool isLoggedIn = authState.value != null;
      final bool isAtLoginScreen = state.matchedLocation == '/';

      // Guard Rule A: If not logged in and trying to go to a private area -> move to login
      if (!isLoggedIn && !isAtLoginScreen) {
        return '/';
      }

      // Guard Rule B: If logged in and trying to go to login screen -> Forward to workspace
      if (isLoggedIn && isAtLoginScreen) {
        return '/submit';
      }

      return null; // Fall through cleanly to requested path if rules pass
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/submit', builder: (context, state) => const PhotoSubmissionScreen()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const UserProfileScreen()),
    ],
  );
});

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

//TODO: remove placeholder views and implement actual features.
// -----
// PLACEHOLDER VIEWS (To be moved to their feature folders later)
// -----

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard View'),
        actions: [
          TextButton(
            child: const Text('Logout'),
            onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Admin metrics and filters go here', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
