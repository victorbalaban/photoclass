import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:photoclass/features/photo_submission/models/photo_submission.dart';
import 'package:photoclass/features/photo_submission/view_models/submissions_view_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacings.dart';

class UploadDropZone extends ConsumerStatefulWidget {
  final AsyncValue<List<PhotoSubmission>> submissionsAsync;
  final VoidCallback onBrowseFiles;
  final Function(PhotoSubmission) onUploadComplete;

  const UploadDropZone({
    super.key,
    required this.submissionsAsync,
    required this.onBrowseFiles,
    required this.onUploadComplete,
  });

  @override
  ConsumerState<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends ConsumerState<UploadDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.submissionsAsync is AsyncLoading;

    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty && !isLoading) {
          final dropFile = details.files.first;
          final bytes = await dropFile.readAsBytes();
          final uploaded = await ref.read(submissionsViewModelProvider.notifier).uploadPhotoStream(
                bytes,
                dropFile.name,
              );

          if (uploaded != null) {
            widget.onUploadComplete(uploaded);
          }
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
            if (isLoading)
              const CircularProgressIndicator()
            else ...[
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: _isDragging ? AppColors.accent : AppColors.textMuted,
              ),
              AppSpacings.verticalSm,
              Text(
                _isDragging ? 'Drop to upload file!' : 'Drag and drop your photos here',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDragging ? AppColors.accent : AppColors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            AppSpacings.verticalSm,
            const Text(
              'Supports PNG, JPG, JPEG, or WEBP',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            AppSpacings.verticalMd,
            ElevatedButton.icon(
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Browse Local Files'),
              onPressed: isLoading ? null : widget.onBrowseFiles,
            ),
          ],
        ),
      ),
    );
  }
}
