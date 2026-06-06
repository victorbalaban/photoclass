// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProfileViewModel)
final profileViewModelProvider = ProfileViewModelProvider._();

final class ProfileViewModelProvider
    extends $AsyncNotifierProvider<ProfileViewModel, UserModel?> {
  ProfileViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'profileViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$profileViewModelHash();

  @$internal
  @override
  ProfileViewModel create() => ProfileViewModel();
}

String _$profileViewModelHash() => r'3ae0835236cf6ff3c54b3a3b9ff51f49445a4618';

abstract class _$ProfileViewModel extends $AsyncNotifier<UserModel?> {
  FutureOr<UserModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserModel?>, UserModel?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UserModel?>, UserModel?>,
        AsyncValue<UserModel?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
