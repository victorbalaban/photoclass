// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_dashboard_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminFilterController)
final adminFilterControllerProvider = AdminFilterControllerProvider._();

final class AdminFilterControllerProvider
    extends $NotifierProvider<AdminFilterController, AdminFilterState> {
  AdminFilterControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminFilterControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminFilterControllerHash();

  @$internal
  @override
  AdminFilterController create() => AdminFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminFilterState>(value),
    );
  }
}

String _$adminFilterControllerHash() =>
    r'cac19f53ba181bd7e3039f8b2bc1b2321d1d561b';

abstract class _$AdminFilterController extends $Notifier<AdminFilterState> {
  AdminFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AdminFilterState, AdminFilterState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AdminFilterState, AdminFilterState>,
        AdminFilterState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AdminSubmissionsViewModel)
final adminSubmissionsViewModelProvider = AdminSubmissionsViewModelProvider._();

final class AdminSubmissionsViewModelProvider extends $AsyncNotifierProvider<
    AdminSubmissionsViewModel, List<AdminSubmission>> {
  AdminSubmissionsViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminSubmissionsViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminSubmissionsViewModelHash();

  @$internal
  @override
  AdminSubmissionsViewModel create() => AdminSubmissionsViewModel();
}

String _$adminSubmissionsViewModelHash() =>
    r'c2f6ec2121e5642cac9ca6af4c6d9dde8fddf6cd';

abstract class _$AdminSubmissionsViewModel
    extends $AsyncNotifier<List<AdminSubmission>> {
  FutureOr<List<AdminSubmission>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<AdminSubmission>>, List<AdminSubmission>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<AdminSubmission>>, List<AdminSubmission>>,
        AsyncValue<List<AdminSubmission>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
