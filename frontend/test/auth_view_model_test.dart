import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:photoclass/features/auth/view_models/auth_view_model.dart';
import 'package:photoclass/features/auth/models/user_model.dart';
import 'package:photoclass/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

void main() {
  late MockDio mockDio;
  late MockResponse mockResponse;
  late UserModel testUser;

  setUp(() {
    mockDio = MockDio();
    mockResponse = MockResponse();
    testUser = UserModel(
      username: 'testuser',
      password: 'password123',
      name: 'victor',
      age: 29,
      gender: 'male',
      placeOfLiving: 'Bucharest',
      countryCode: 'RO',
    );

    // mock response to return a dummy token
    when(() => mockResponse.data).thenReturn({
      'access_token': 'mocked_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.token',
      'token_type': 'bearer',
    });
    when(() => mockResponse.statusCode).thenReturn(200);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockDio),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthViewModel - registerUser Unit Tests', () {
    test('Successful registration returns true and logs in the user', () async {
      final container = createContainer();

      // Registration endpoint request
      when(() => mockDio.post('/api/auth/register', data: any(named: 'data'))).thenAnswer((_) async => mockResponse);

      // follow-up Login endpoint request
      when(() => mockDio.post('/api/auth/login', data: any(named: 'data'))).thenAnswer((_) async => mockResponse);

      final notifier = container.read(authViewModelProvider.notifier);

      final result = await notifier.registerUser(testUser);

      expect(result, isTrue);
      expect(container.read(authViewModelProvider).isLoading, isFalse);
    });

    test('Failed registration due to existing username sets state to error and returns false', () async {
      final container = createContainer();

      // We target the specific register endpoint here to force the error
      when(() => mockDio.post('/api/auth/register', data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/register'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/register'),
            statusCode: 400,
            data: {'detail': 'Username already exists.'},
          ),
        ),
      );

      final notifier = container.read(authViewModelProvider.notifier);

      final result = await notifier.registerUser(testUser);

      expect(result, isFalse);

      final authState = container.read(authViewModelProvider);
      expect(authState, isA<AsyncError>());
      expect(authState.error, 'Username already exists.');
    });
  });
}
