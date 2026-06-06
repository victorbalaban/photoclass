// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submissions_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SubmissionsViewModel)
final submissionsViewModelProvider = SubmissionsViewModelProvider._();

final class SubmissionsViewModelProvider extends $AsyncNotifierProvider<
    SubmissionsViewModel, List<PhotoSubmission>> {
  SubmissionsViewModelProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'submissionsViewModelProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$submissionsViewModelHash();

  @$internal
  @override
  SubmissionsViewModel create() => SubmissionsViewModel();
}

String _$submissionsViewModelHash() =>
    r'2070b9c33dac5709ece12c73244fa6ca7f23a154';

abstract class _$SubmissionsViewModel
    extends $AsyncNotifier<List<PhotoSubmission>> {
  FutureOr<List<PhotoSubmission>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<List<PhotoSubmission>>, List<PhotoSubmission>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PhotoSubmission>>, List<PhotoSubmission>>,
        AsyncValue<List<PhotoSubmission>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
