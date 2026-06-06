import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:country_picker/country_picker.dart';
import 'package:photoclass/features/auth/models/user_model.dart';
import '../../../core/theme/app_spacings.dart';
import '../view_models/auth_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedGender;
  String? _selectedCountryCode;
  String _countryButtonText = 'Select Country of Origin';

  bool _isSignUp = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer Not to Say'];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      if (_selectedCountryCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your country of origin.')),
        );
        return;
      }

      final userProfile = UserModel(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _selectedGender!,
        placeOfLiving: _locationController.text.trim(),
        countryCode: _selectedCountryCode!,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      await ref.read(authViewModelProvider.notifier).registerUser(userProfile);
    } else {
      await ref.read(authViewModelProvider.notifier).loginUser(username, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState is AsyncLoading;

    // Detect if the application is rendering on a mobile display
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobileState = screenWidth < 500;

    ref.listen<AsyncValue<void>>(authViewModelProvider, (_, state) {
      state.whenOrNull(error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString()), backgroundColor: Colors.redAccent),
        );
      });
    });

    // Extracting the Age and Gender input fields into reusable widget variables
    // to keep our adaptive layout clean and readable.
    final ageField = TextFormField(
      controller: _ageController,
      decoration: const InputDecoration(labelText: 'Age'),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final age = int.tryParse(v);
        if (age == null || age < 0 || age > 125) return 'Invalid age';
        return null;
      },
      enabled: !isLoading,
    );

    final genderField = DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Gender'),
      items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: isLoading ? null : (val) => setState(() => _selectedGender = val),
      validator: (v) => v == null ? 'Required' : null,
    );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacings.md),
          child: Container(
            constraints: BoxConstraints(maxWidth: _isSignUp ? 600 : 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacings.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isSignUp ? 'Create Account' : 'Sign In',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacings.verticalLg,
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Minimum 3 characters required' : null,
                        enabled: !isLoading,
                      ),
                      AppSpacings.verticalMd,
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters required' : null,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) => _handleSubmit(),
                      ),
                      if (_isSignUp) ...[
                        AppSpacings.verticalMd,
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Full Name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          enabled: !isLoading,
                        ),
                        AppSpacings.verticalMd,

                        // Adaptive for mobile and desktop layouts: stacked on narrow screens, horizontal on wider screens.
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
                      ],
                      AppSpacings.verticalLg,
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleSubmit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_isSignUp ? 'Register' : 'Login'),
                      ),
                      AppSpacings.verticalMd,
                      TextButton(
                        onPressed: isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                            _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Register Now"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
