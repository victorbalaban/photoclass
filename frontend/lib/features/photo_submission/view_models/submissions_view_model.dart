import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../models/photo_submission.dart';

part 'submissions_view_model.g.dart';

@riverpod
class SubmissionsViewModel extends _$SubmissionsViewModel {
  @override
  FutureOr<List<PhotoSubmission>> build() async {
    // Automatically runs whenever a user enters the main dashboard
    return _fetchMySubmissions();
  }

  Future<List<PhotoSubmission>> _fetchMySubmissions() async {
    final dio = ref.read(classificationClientProvider);
    final authToken = ref.read(authViewModelProvider).value;

    if (authToken == null) return [];

    final response = await dio.get(
      '/api/submissions/me',
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );

    final List<dynamic> data = response.data;
    return data
        .map((json) => PhotoSubmission(
              id: json['id'].toString(),
              imageUrl: json['image_url'] ?? '',
              classificationTitle: json['classification_title'],
              timestamp: DateTime.parse(json['timestamp']),
            ))
        .toList();
  }

  Future<PhotoSubmission?> uploadPhotoStream(Uint8List fileBytes, String filename) async {
    // Keep a backup of current items to handle errors if they arise
    final previousState = state;
    state = const AsyncLoading();

    try {
      final dio = ref.read(classificationClientProvider);
      final authToken = ref.read(authViewModelProvider).value;

      // 1. Pack bytes into a standard Multipart network request form
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
        ),
      });

      // 2. Transmit binary stream to classification-service on port 8001
      final response = await dio.post(
        '/api/submissions/upload',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      // 3. Parse server schema output and append directly to active UI state
      final freshUpload = PhotoSubmission(
        id: response.data['id'].toString(),
        imageUrl: response.data['image_url'] ?? '',
        classificationTitle: response.data['classification_title'],
        timestamp: DateTime.parse(response.data['timestamp']),
      );

      final currentList = previousState.value ?? [];
      state = AsyncData([freshUpload, ...currentList]);

      return freshUpload;
    } catch (e, stackTrace) {
      state = AsyncValue.error('Network upload failed: ${e.toString()}', stackTrace);
      state = previousState;
      return null;
    }
  }

  Future<bool> deletePhotoRecord(String targetId) async {
    final previousState = state;
    if (previousState.value == null) return false;

    try {
      final dio = ref.read(classificationClientProvider);
      final authToken = ref.read(authViewModelProvider).value;

      // Send the network DELETE instruction to port 8001
      await dio.delete(
        '/api/submissions/$targetId',
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      // Perform a state change, filtering out the removed element item card
      final cleanedList = previousState.value!.where((item) => item.id != targetId).toList();
      state = AsyncData(cleanedList);
      return true;
    } catch (e) {
      // Keep old screen layout references intact if request encounters failure drops
      state = previousState;
      return false;
    }
  }
}
