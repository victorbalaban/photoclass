import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacings.dart';

class AdminGatewayBanner extends StatelessWidget {
  const AdminGatewayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacings.lg),
      padding: const EdgeInsets.all(AppSpacings.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacings.sm),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
          ),
          AppSpacings.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrative Console Access',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have admin privileges. Access global submissions, '
                  'filter them by demographics and view metadata fields.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          AppSpacings.horizontalMd,
          ElevatedButton.icon(
            icon: const Icon(Icons.dashboard_customize, size: 18),
            label: const Text('Open Console'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacings.lg, vertical: AppSpacings.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => context.go('/admin'),
          ),
        ],
      ),
    );
  }
}
