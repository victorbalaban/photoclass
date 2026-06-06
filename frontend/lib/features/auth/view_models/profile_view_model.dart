import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import './auth_view_model.dart';
import '../models/user_model.dart';

part 'profile_view_model.g.dart';

@riverpod
class ProfileViewModel extends _$ProfileViewModel {
  @override
  FutureOr<UserModel?> build() async {
    final authToken = ref.watch(authViewModelProvider).value;
    if (authToken == null) return null;

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(
        '/api/users/profile',
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      final data = response.data;
      return UserModel(
        username: '',
        password: '',
        name: data['name'],
        age: data['age'],
        gender: data['gender'],
        placeOfLiving: data['place_of_living'],
        countryCode: data['country_code'],
        description: data['description'],
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to load profile data', stackTrace);
      return null;
    }
  }

  Future<bool> updateProfile(UserModel updatedUser) async {
    final authToken = ref.read(authViewModelProvider).value;
    if (authToken == null) return false;

    try {
      final dio = ref.read(apiClientProvider);
      
      // Send the snake_case payload mapping straight to port 8000
      await dio.put(
        '/api/users/profile',
        data: updatedUser.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      // Refresh local provider state cache on success
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }
}