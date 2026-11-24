import 'package:flutter/material.dart';
import 'package:grabber_app/core/constants/app_colors.dart';
import 'package:grabber_app/core/constants/app_fonts.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';

/// Collects a required primary address or edits an existing saved address.
class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({
    required this.uid,
    required this.deliveryAddressRepository,
    required this.onAddressSaved,
    this.initialAddress,
    this.addressNeedsCorrection = false,
    super.key,
  });

  final String uid;
  final DeliveryAddressRepository deliveryAddressRepository;
  final ValueChanged<DeliveryAddress> onAddressSaved;
  final DeliveryAddress? initialAddress;
  final bool addressNeedsCorrection;

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _buildingNumberController = TextEditingController();
  bool _isSaving = false;
  String? _saveError;

  bool get _isEditing =>
      widget.initialAddress != null || widget.addressNeedsCorrection;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    if (address != null) {
      _cityController.text = address.city;
      _districtController.text = address.district;
      _streetNameController.text = address.streetName;
      _buildingNumberController.text = address.buildingNumber;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _streetNameController.dispose();
    _buildingNumberController.dispose();
    super.dispose();
  }

  /// Validates, saves the address for the authenticated UID, and reports success.
  ///
  /// Repository failures leave the form open and show a retryable message.
  Future<void> _submit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final address = DeliveryAddress(
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      streetName: _streetNameController.text.trim(),
      buildingNumber: _buildingNumberController.text.trim(),
    );
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await widget.deliveryAddressRepository.saveAddress(
        uid: widget.uid,
        address: address,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = _saveErrorMessage(error);
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onAddressSaved(address);
  }

  /// Keeps permission errors distinct from other address save failures.
  String _saveErrorMessage(Object error) {
    if (error is ProfileFailure && error.code == 'permission-denied') {
      return 'You do not have permission to save this address.';
    }
    return 'Unable to save your delivery address. Please try again.';
  }

  /// Requires each address field to contain a non-whitespace value.
  String? _requiredAddressValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: AppFonts.bebasNeue),
      ),
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isEditing
                                ? 'Update your delivery address'
                                : 'Add your delivery address',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: const Color(0xFF1E2A1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the address where you want your orders delivered.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (widget.addressNeedsCorrection) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Your saved address is incomplete. Please '
                              'correct it to continue.',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _cityController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _requiredAddressValidator,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _districtController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _requiredAddressValidator,
                            decoration: const InputDecoration(
                              labelText: 'District',
                              prefixIcon: Icon(Icons.map_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _streetNameController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: _requiredAddressValidator,
                            decoration: const InputDecoration(
                              labelText: 'Street Name',
                              prefixIcon: Icon(Icons.signpost_outlined),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _buildingNumberController,
                            enabled: !_isSaving,
                            style: const TextStyle(fontFamily: 'Roboto'),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: _requiredAddressValidator,
                            decoration: const InputDecoration(
                              labelText: 'Building Number',
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                          ),
                          if (_saveError != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _saveError!,
                              style: TextStyle(color: colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _isSaving ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Saving address...'),
                                      ],
                                    )
                                  : Text(
                                      _saveError == null
                                          ? _isEditing
                                                ? 'Update Address'
                                                : 'Save Address'
                                          : _isEditing
                                          ? 'Retry Update Address'
                                          : 'Retry Save Address',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
