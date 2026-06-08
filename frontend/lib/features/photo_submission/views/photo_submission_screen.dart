import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:photoclass/features/photo_submission/models/photo_submission.dart';
import 'package:photoclass/features/photo_submission/views/widgets/admin_gateway_banner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacings.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/submissions_view_model.dart';
import 'widgets/upload_drop_zone.dart';
import 'widgets/submission_history_card.dart';

class PhotoSubmissionScreen extends ConsumerStatefulWidget {
  const PhotoSubmissionScreen({super.key});

  @override
  ConsumerState<PhotoSubmissionScreen> createState() => _PhotoSubmissionScreenState();
}

class _PhotoSubmissionScreenState extends ConsumerState<PhotoSubmissionScreen> {
  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(submissionsViewModelProvider);
    final userRole = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Classification Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 26),
          tooltip: 'Your Profile Settings',
          onPressed: () {
            context.go('/profile');
          },
        ),
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
                // Conditional Admin Gateway Banner
                if (userRole == 'admin') const AdminGatewayBanner(),
                // Photo Upload Drop Zone with File Picker
                UploadDropZone(
                  submissionsAsync: submissionsAsync,
                  onBrowseFiles: _handleBrowseFiles,
                  onUploadComplete: _showUploadConfirmationDialog,
                ),

                AppSpacings.verticalLg,

                // Submission History Section with Async Loading/Error/Data states
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
                          items.length > 1 ? 'Your Submissions (${items.length})' : 'Your Submission',
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
                              // Submission History Card for each photo
                              return SubmissionHistoryCard(
                                photo: photo,
                                onTap: () => _showFullScaleImageDialog(photo),
                                onDeleteRequested: () => _showDeleteConfirmationDialog(photo),
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

  /// Handles the file picking and upload process when the user clicks the "Browse Files" button.
  Future<void> _handleBrowseFiles() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final uploadedItem = await ref.read(submissionsViewModelProvider.notifier).uploadPhotoStream(
            file.bytes!,
            file.name,
          );
      if (uploadedItem != null) {
        _showUploadConfirmationDialog(uploadedItem);
      }
    }
  }

  /// Displays a confirmation dialog with the classification result after a successful upload.
  void _showUploadConfirmationDialog(PhotoSubmission item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 26),
            SizedBox(width: 8),
            Text('Analysis Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.blueGrey[50],
                height: 200,
                child: Image.network(item.imageUrl, fit: BoxFit.cover),
              ),
            ),
            AppSpacings.verticalMd,
            const Text('Classification Result:',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(item.classificationTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Displays a full-scale view of the selected photo in a dialog.
  void _showFullScaleImageDialog(PhotoSubmission photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacings.xl),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(onTap: () => Navigator.of(context).pop()),
            Container(
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppBar(
                    title: Text(photo.classificationTitle, style: const TextStyle(color: AppColors.textMain)),
                    backgroundColor: AppColors.surface,
                    elevation: 0,
                    leading: const CloseButton(color: AppColors.textMain),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacings.md),
                      child: InteractiveViewer(
                        maxScale: 4.0,
                        child: Image.network(photo.imageUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a confirmation dialog before permanently deleting a photo.
  void _showDeleteConfirmationDialog(PhotoSubmission photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 8),
            Text('Permanently Delete Photo?'),
          ],
        ),
        content: const Text(
            'Are you sure you want to delete the photo? This action removes it entirely and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref.read(submissionsViewModelProvider.notifier).deletePhotoRecord(photo.id);
              if (!mounted) return;
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Could not successfully complete deletion.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
