import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/admin_submission.dart';

part 'admin_dashboard_view_model.g.dart';

class AdminFilterState {
  final int? age;
  final String? gender;
  final String? placeOfLiving;
  final String? countryCode;

  AdminFilterState({this.age, this.gender, this.placeOfLiving, this.countryCode});

  AdminFilterState copyWith({
    int? Function()? age,
    String? Function()? gender,
    String? Function()? placeOfLiving,
    String? Function()? countryCode,
  }) {
    return AdminFilterState(
      age: age != null ? age() : this.age,
      gender: gender != null ? gender() : this.gender,
      placeOfLiving: placeOfLiving != null ? placeOfLiving() : this.placeOfLiving,
      countryCode: countryCode != null ? countryCode() : this.countryCode,
    );
  }
}

@riverpod
class AdminFilterController extends _$AdminFilterController {
  @override
  AdminFilterState build() => AdminFilterState();

  void updateAge(int? age) => state = state.copyWith(age: () => age);
  void updateGender(String? gender) => state = state.copyWith(gender: () => gender);
  void updatePlaceOfLiving(String? placeOfLiving) => state = state.copyWith(placeOfLiving: () => placeOfLiving);
  void updateCountryCode(String? code) => state = state.copyWith(countryCode: () => code);

  void clearFilters() => state = AdminFilterState();
}

@riverpod
class AdminSubmissionsViewModel extends _$AdminSubmissionsViewModel {
  @override
  FutureOr<List<AdminSubmission>> build() async {
    final filters = ref.watch(adminFilterControllerProvider);
    return _fetchGlobalSubmissions(filters);
  }

  Future<List<AdminSubmission>> _fetchGlobalSubmissions(AdminFilterState filters) async {
    final dio = ref.read(classificationClientProvider);
    final authToken = ref.read(authViewModelProvider).value;

    if (authToken == null) return [];

    // Map our local filter state parameters cleanly onto query string keys matching FastAPI
    final Map<String, dynamic> queryParams = {};
    if (filters.age != null) queryParams['age'] = filters.age;
    if (filters.gender != null) queryParams['gender'] = filters.gender;
    if (filters.placeOfLiving != null && filters.placeOfLiving!.isNotEmpty) queryParams['place_of_living'] = filters.placeOfLiving;
    if (filters.countryCode != null && filters.countryCode!.isNotEmpty)
      queryParams['country_code'] = filters.countryCode;

    final response = await dio.get(
      '/api/submissions/admin',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );

    final List<dynamic> data = response.data;
    return data.map((json) => AdminSubmission.fromJson(json)).toList();
  }
}
