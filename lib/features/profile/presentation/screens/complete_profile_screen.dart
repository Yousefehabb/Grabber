import 'package:flutter/material.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/features/profile/domain/entities/user_profile.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';

/// Collects profile details when an authenticated customer profile is missing.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    required this.uid,
    required this.email,
    required this.profileRepository,
    required this.onProfileSaved,
    super.key,
  });

  final String uid;
  final String email;
  final UserProfileRepository profileRepository;
  final VoidCallback onProfileSaved;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  String? _gender;
  String? _saveError;
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  /// Validates form input and asks the profile repository to persist it.
  ///
  /// On success, notifies the authenticated-entry gate to continue; on failure,
  /// keeps the customer here so they can retry without re-registering.
  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.profileRepository.createProfile(
        UserProfile(
          uid: widget.uid,
          fullName: _fullNameController.text.trim(),
          email: widget.email,
          mobileNumber: _mobileNumberController.text.trim(),
          gender: _gender,
        ),
      );
    } on ProfileFailure {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = 'Unable to save your profile. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onProfileSaved();
  }

  /// Requires non-empty profile fields before submission.
  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Complete your profile',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2A1D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account is signed in. Complete these details to '
                    'continue to your delivery address.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: widget.email,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.words,
                    validator: _requiredValidator,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mobileNumberController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _gender = value),
                    validator: (value) =>
                        value == null ? 'Gender is required' : null,
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _saveError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Profile and Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
