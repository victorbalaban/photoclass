import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacings.dart';
import '../view_models/admin_dashboard_view_model.dart';
import '../models/admin_submission.dart';
import 'widgets/admin_submission_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(adminSubmissionsViewModelProvider);
    final filterState = ref.watch(adminFilterControllerProvider);
    final filterNotifier = ref.read(adminFilterControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrative Console'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.go('/submit'),
          tooltip: 'Return to Submission Workspace',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacings.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // filter section
                Card(
                  color: AppColors.surface,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacings.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            // show "clear filters" button only when at least one filter is active
                            if (filterState.age != null ||
                                filterState.gender != null ||
                                (filterState.placeOfLiving != null && filterState.placeOfLiving!.isNotEmpty) ||
                                filterState.countryCode != null)
                              SizedBox(
                                height: 32,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.clear_all, size: 18, color: AppColors.error),
                                  label: const Text('Clear Filters', style: TextStyle(color: AppColors.error)),
                                  onPressed: filterNotifier.clearFilters,
                                ),
                              )
                            else
                              // Keeps the row height perfectly symmetrical when the button is missing
                              const SizedBox(height: 32),
                          ],
                        ),
                        AppSpacings.verticalMd,
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useVertical = constraints.maxWidth < 700;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: useVertical ? double.infinity : 120,
                                  child: TextFormField(
                                    initialValue: filterState.age?.toString() ?? '',
                                    decoration:
                                        const InputDecoration(labelText: 'Exact Age', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => filterNotifier.updateAge(int.tryParse(v)),
                                  ),
                                ),
                                SizedBox(
                                  width: useVertical ? double.infinity : 190,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: filterState.gender,
                                    decoration:
                                        const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                                    items: ['Male', 'Female', 'Prefer Not to Say']
                                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                        .toList(),
                                    onChanged: filterNotifier.updateGender,
                                  ),
                                ),
                                SizedBox(
                                  width: useVertical ? double.infinity : 220,
                                  child: TextFormField(
                                    initialValue: filterState.placeOfLiving ?? '',
                                    decoration: const InputDecoration(
                                        labelText: 'Search Location/City', border: OutlineInputBorder()),
                                    onChanged: filterNotifier.updatePlaceOfLiving,
                                  ),
                                ),
                                SizedBox(
                                  width: useVertical ? double.infinity : 220,
                                  child: OutlinedButton.icon(
                                    icon: Icon(Icons.public, color: Theme.of(context).hintColor, size: 20),
                                    label: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        filterState.countryCode ?? 'Select Country Filter',
                                        style: TextStyle(
                                          color: filterState.countryCode != null
                                              ? AppColors.textMain
                                              : Theme.of(context).hintColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(
                                          strokeAlign: BorderSide.strokeAlignOutside,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                                      backgroundColor: Colors.transparent,
                                    ),
                                    onPressed: () {
                                      showCountryPicker(
                                        context: context,
                                        onSelect: (Country c) => filterNotifier.updateCountryCode(c.countryCode),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),

                AppSpacings.verticalLg,

                // submissions list
                submissionsAsync.when(
                  loading: () =>
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (err, __) => Center(child: Text('Access Denied or Connection Error: $err')),
                  data: (records) {
                    if (records.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No submissions matched your filters.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        crossAxisSpacing: AppSpacings.md,
                        mainAxisSpacing: AppSpacings.md,
                        childAspectRatio: 0.76,
                      ),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return AdminSubmissionCard(
                          record: record,
                          onTap: () => _showAdminDetailDialog(context, record),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminDetailDialog(BuildContext context, AdminSubmission record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.classificationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(record.imageUrl, height: 250, fit: BoxFit.contain),
            ),
            ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Uploaded By'),
                subtitle: Text(record.userName),
                dense: true),
            ListTile(
                leading: const Icon(Icons.cake),
                title: const Text('Age'),
                subtitle: Text(record.userAge.toString()),
                dense: true),
            ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                subtitle: Text('${record.userPlaceOfLiving}, ${record.userCountry}'),
                dense: true),
            ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Timestamp'),
                subtitle: Text(DateFormat('dd.MM.yyyy HH:mm:ss').format(record.timestamp.toLocal())),
                dense: true),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
