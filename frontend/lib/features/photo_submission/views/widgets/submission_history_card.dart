import 'package:flutter/material.dart';
import 'package:photoclass/features/photo_submission/models/photo_submission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacings.dart';

class SubmissionHistoryCard extends StatelessWidget {
  final PhotoSubmission photo;
  final VoidCallback onTap;
  final VoidCallback onDeleteRequested;

  const SubmissionHistoryCard({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
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
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              );
                            },
                            errorBuilder: (context, error, stack) => const Icon(
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
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textMain,
                        ),
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
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              type: MaterialType.transparency,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
                tooltip: 'Options',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black12,
                  shape: const CircleBorder(),
                ),
                onSelected: (action) {
                  if (action == 'delete') {
                    onDeleteRequested();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        AppSpacings.horizontalSm,
                        Text(
                          'Delete Photo',
                          style: TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
