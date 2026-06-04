import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

// This is required for Riverpod's build_runner code generator
part 'auth_view_model.g.dart';

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  FutureOr<String?> build() {
    // Our state is a String? representing the active user's JWT token.
    // It starts as null (not unauthenticated).
    return null;
  }

  Future<bool> registerUser({
    required String username,
    required String password,
    required String name,
    required int age,
    required String gender,
    required String placeOfLiving,
    required String countryCode,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post(
        '/api/auth/register',
        data: {
          'username': username,
          'password': password,
          'name': name,
          'age': age,
          'gender': gender,
          'place_of_living': placeOfLiving,
          'country_code': countryCode,
          'description': description,
        },
      );

      return await loginUser(username, password);
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
