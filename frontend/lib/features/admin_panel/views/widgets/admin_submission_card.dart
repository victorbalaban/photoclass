import 'package:flutter/material.dart';
import 'package:photoclass/features/admin_panel/models/admin_submission.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacings.dart';

class AdminSubmissionCard extends StatelessWidget {
  final AdminSubmission record;
  final VoidCallback onTap;

  const AdminSubmissionCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.blueGrey[50],
                child: record.imageUrl.isNotEmpty
                    ? Image.network(record.imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 40, color: AppColors.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacings.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.classificationTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Render a clean metadata badge row summarizing the demographic metrics
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      _buildMetaTag('👤 ${record.userName}'),
                      _buildMetaTag('🎂 ${record.userAge}y/o'),
                      _buildMetaTag('🚻 ${record.userGender[0]}'),
                      _buildMetaTag('🌍 ${record.userCountry}'),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
    );
  }
}