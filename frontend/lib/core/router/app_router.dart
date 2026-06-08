import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/user_profile_screen.dart';
import '../../features/auth/view_models/auth_view_model.dart';
import '../../features/photo_submission/views/photo_submission_screen.dart';
import '../../features/admin_panel/views/admin_dashboard_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

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
      final String userRole = ref.read(userRoleProvider);

      // Guard Rule A: If not logged in and trying to go to a private area -> move to login
      if (!isLoggedIn && !isAtLoginScreen) {
        return '/';
      }

      // Guard Rule B: If logged in and trying to go to login screen -> Forward to workspace
      if (isLoggedIn && isAtLoginScreen) {
        return '/submit';
      }

      // Guard Rule C: If logged in but trying to access admin panel without admin role -> Forward to workspace
      if (state.matchedLocation == '/admin' && userRole != 'admin') {
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
