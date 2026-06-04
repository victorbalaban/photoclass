import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacings.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/submissions_view_model.dart';

class PhotoSubmissionScreen extends ConsumerStatefulWidget {
  const PhotoSubmissionScreen({super.key});

  @override
  ConsumerState<PhotoSubmissionScreen> createState() => _PhotoSubmissionScreenState();
}

class _PhotoSubmissionScreenState extends ConsumerState<PhotoSubmissionScreen> {
  bool _isDragging = false;

  // Handles standard file explorer dialog browsing clicks
  Future<void> _handleBrowseFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true, // CRITICAL FOR FLUTTER WEB: Forces browser to cache data bytes directly
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      await ref.read(submissionsViewModelProvider.notifier).uploadPhotoStream(
            file.bytes!,
            file.name,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watches the state of our network async notifier
    final submissionsAsync = ref.watch(submissionsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Classification Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            child: const Text('Logout', style: TextStyle(color: AppColors.primary)),
            onPressed: () => ref.read(authViewModelProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacings.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // drag&drop frame
                DropTarget(
                  onDragEntered: (details) => setState(() => _isDragging = true),
                  onDragExited: (details) => setState(() => _isDragging = false),
                  onDragDone: (details) async {
                    setState(() => _isDragging = false);
                    if (details.files.isNotEmpty) {
                      final dropFile = details.files.first;
                      final bytes = await dropFile.readAsBytes();
                      await ref.read(submissionsViewModelProvider.notifier).uploadPhotoStream(
                            bytes,
                            dropFile.name,
                          );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 240,
                    decoration: BoxDecoration(
                      color: _isDragging ? AppColors.accent.withValues(alpha: 0.08) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDragging ? AppColors.accent : AppColors.textMuted.withValues(alpha: 0.4),
                        width: _isDragging ? 3 : 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (submissionsAsync is AsyncLoading)
                          const CircularProgressIndicator()
                        else ...[
                          Icon(Icons.cloud_upload_outlined,
                              size: 64, color: _isDragging ? AppColors.accent : AppColors.textMuted),
                          AppSpacings.verticalSm,
                          Text(
                            _isDragging ? 'Drop to upload file!' : 'Drag and drop your photos here',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isDragging ? AppColors.accent : AppColors.textMain),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        AppSpacings.verticalSm,
                        const Text('Supports PNG, JPG, JPEG, or WEBP',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        AppSpacings.verticalMd,
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Browse Local Files'),
                          onPressed: (submissionsAsync is AsyncLoading) ? null : _handleBrowseFiles,
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacings.verticalLg,

                // render historical submission from server
                submissionsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacings.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Container(
                    padding: const EdgeInsets.all(AppSpacings.md),
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
                  ),
                  data: (items) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items.length > 0 ? 'Your Submission' : 'Your Submissions (${items.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppSpacings.verticalMd,
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacings.xxl),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.photo_library_outlined,
                                      size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
                                  AppSpacings.verticalSm,
                                  const Text('No submissions yet.',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              crossAxisSpacing: AppSpacings.md,
                              mainAxisSpacing: AppSpacings.md,
                              childAspectRatio: 0.82,
                            ),
                            itemBuilder: (context, index) {
                              final photo = items[index];
                              return Card(
                                color: AppColors.surface,
                                clipBehavior: Clip.antiAlias,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        color: Colors.blueGrey[50],
                                        child: photo.imageUrl.isNotEmpty
                                            ? Image.network(
                                                photo.imageUrl,
                                                fit: BoxFit.cover,
                                                // Render placeholder loading progressions
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  );
                                                },
                                                // Fallback in case of network issues
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.broken_image,
                                                  color: AppColors.textMuted,
                                                ),
                                              )
                                            : const Icon(Icons.image, size: 40, color: AppColors.textMuted),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(AppSpacings.sm),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            photo.classificationTitle,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${photo.timestamp.hour}:${photo.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
