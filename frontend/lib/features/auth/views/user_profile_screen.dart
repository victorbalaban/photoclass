import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacings.dart';
import '../models/user_model.dart';
import '../view_models/profile_view_model.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  String _selectedGender = 'Male';
  String _selectedCountryCode = 'RO';
  String _countryButtonText = 'Select Country';
  bool _initialized = false;

  void _initializeFields(UserModel user) {
    if (_initialized) return;

    _nameController = TextEditingController(text: user.name);
    _ageController = TextEditingController(text: user.age.toString());
    _locationController = TextEditingController(text: user.placeOfLiving);
    _descriptionController = TextEditingController(text: user.description ?? '');
    _selectedGender = user.gender;
    _selectedCountryCode = user.countryCode.isNotEmpty ? user.countryCode : 'RO';

    // Map country code: Converts into country_picker property
    final countryInstance = Country.tryParse(_selectedCountryCode);
    if (countryInstance != null) {
      _countryButtonText = '${countryInstance.flagEmoji} ${countryInstance.name} (${countryInstance.countryCode})';
    } else {
      _countryButtonText = _selectedCountryCode;
    }

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _ageController.dispose();
      _locationController.dispose();
      _descriptionController.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = UserModel(
      username: '', password: '', // Locked system configurations
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      placeOfLiving: _locationController.text.trim(),
      countryCode: _selectedCountryCode.toUpperCase(),
      description: _descriptionController.text.trim(),
    );

    final success = await ref.read(profileViewModelProvider.notifier).updateProfile(updated);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile changes saved successfully!' : 'Error: Failed to save changes.'),
        backgroundColor: success ? Colors.green : AppColors.error,
      ),
    );

    if (success) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go('/submit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileViewModelProvider);
    final isLoading = profileAsync is AsyncLoading;

    // Evaluate screen width breakpoints to mirror register page adaptations
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobileState = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.go('/submit'),
          tooltip: 'Return to Dashboard Workspace',
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Error loading dashboard profile: $err')),
        data: (user) {
          if (user == null) return const Center(child: Text('Please sign in to view settings.'));
          _initializeFields(user);

          // Define primitive sub-widgets cleanly before generating structural multi-axis layouts
          final ageField = TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Valid age is required' : null,
            enabled: !isLoading,
          );

          final genderField = DropdownButtonFormField<String>(
            initialValue: _selectedGender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['Male', 'Female', 'Prefer Not to Say'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: isLoading ? null : (v) => setState(() => _selectedGender = v!),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacings.lg),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Update Profile Metadata',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      AppSpacings.verticalLg,

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        enabled: !isLoading,
                      ),
                      AppSpacings.verticalMd,

                      // Adaptive for mobile and desktop layouts
                      isMobileState
                          ? Column(
                              children: [
                                ageField,
                                AppSpacings.verticalMd,
                                genderField,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(flex: 2, child: ageField),
                                AppSpacings.horizontalMd,
                                Expanded(flex: 3, child: genderField),
                              ],
                            ),

                      AppSpacings.verticalMd,
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Place of Living (City/Region)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                        enabled: !isLoading,
                      ),
                      AppSpacings.verticalMd,

                      // Country picker
                      OutlinedButton.icon(
                        icon: const Icon(Icons.public),
                        label: Align(alignment: Alignment.centerLeft, child: Text(_countryButtonText)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(AppSpacings.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode: false,
                                  onSelect: (Country country) {
                                    setState(() {
                                      _selectedCountryCode = country.countryCode;
                                      _countryButtonText =
                                          '${country.flagEmoji} ${country.name} (${country.countryCode})';
                                    });
                                  },
                                );
                              },
                      ),
                      AppSpacings.verticalMd,

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                        enabled: !isLoading,
                      ),
                      AppSpacings.verticalLg,

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: isLoading ? null : _handleSaveProfile,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Profile Updates',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
