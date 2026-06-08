import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photoclass/features/auth/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import 'dart:convert';

part 'auth_view_model.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  FutureOr<String?> build() {
    // Our state is a String? representing the active user's JWT token.
    // It starts as null (not unauthenticated).
    return null;
  }

  Future<bool> registerUser(UserModel user) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        '/api/auth/register',
        data: user.toJson(),
      );

      return await loginUser(user.username, user.password);
    } on DioException catch (e, stackTrace) {
      final errorMessage = e.response?.data['detail'] ?? 'Registration failed.';
      state = AsyncValue.error(errorMessage, stackTrace);
      return false;
    } catch (e, stackTrace) {
      state = AsyncValue.error('An unexpected error occurred.', stackTrace);
      return false;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      );

      final token = response.data['access_token'] as String;

      // Update state with the verified session token.
      // This automatically pushes updates to your UI and routing listeners!
      state = AsyncData(token);
      return true;
    } on DioException catch (e, stackTrace) {
      final errorMessage = e.response?.data['detail'] ?? 'Login failed.';
      state = AsyncValue.error(errorMessage, stackTrace);
      return false;
    } catch (e, stackTrace) {
      state = AsyncValue.error('An unexpected login error occurred.', stackTrace);
      return false;
    }
  }

  void logout() {
    state = const AsyncData(null); // Clear token, forcing route guard to bounce user back to login
  }
}

final userRoleProvider = Provider<String>((ref) {
  final token = ref.watch(authViewModelProvider).value;
  if (token == null) return 'user';

  try {
    // Split the JWT to inspect the claims payload signature natively
    final parts = token.split('.');
    if (parts.length != 3) return 'user';

    final payloadString = String.fromCharCodes(
      base64Url.decode(base64Url.normalize(parts[1])),
    );

    final Map<String, dynamic> payload = jsonDecode(payloadString);
    return payload['role'] ?? 'user'; // Pulls the exact "admin" or "user" string from API
  } catch (_) {
    return 'user';
  }
});
