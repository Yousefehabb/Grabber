import 'package:flutter/material.dart';
import 'package:grabber_app/app/app_session.dart';
import 'package:grabber_app/app/main_navigation_screen.dart';
import 'package:grabber_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/errors/profile_failure.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:grabber_app/features/profile/presentation/screens/complete_profile_screen.dart';
import 'package:grabber_app/features/profile/presentation/screens/delivery_address_screen.dart';

/// Resolves incomplete customer data before allowing entry to the main app.
class AuthenticatedEntryScreen extends StatefulWidget {
  const AuthenticatedEntryScreen({
    required this.uid,
    required this.email,
    required this.deliveryAddressRepository,
    required this.authRepository,
    required this.profileRepository,
    this.session,
    super.key,
  });

  final String uid;
  final String email;
  final DeliveryAddressRepository deliveryAddressRepository;
  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final AppSession? session;

  @override
  State<AuthenticatedEntryScreen> createState() =>
      _AuthenticatedEntryScreenState();
}

enum _EntryState { loading, profileMissing, addressMissing, error, ready }

class _AuthenticatedEntryScreenState extends State<AuthenticatedEntryScreen> {
  _EntryState _entryState = _EntryState.loading;
  bool _readInProgress = false;
  String? _readError;
  DeliveryAddress? _address;
  bool _addressNeedsCorrection = false;
  int _readGeneration = 0;

  /// Starts profile and address checks for the current authenticated identity.
  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  /// Reloads customer data if this gate is reused for a different identity.
  @override
  void didUpdateWidget(covariant AuthenticatedEntryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid ||
        oldWidget.email != widget.email ||
        oldWidget.deliveryAddressRepository !=
            widget.deliveryAddressRepository ||
        oldWidget.profileRepository != widget.profileRepository) {
      _readGeneration++;
      _readInProgress = false;
      _address = null;
      _addressNeedsCorrection = false;
      _entryState = _EntryState.loading;
      _loadAddress();
    }
  }

  /// Loads the signed-in user's profile, then checks their primary address.
  ///
  /// Missing data opens its completion form; malformed addresses can be
  /// corrected, while read failures remain on a retry screen.
  Future<void> _loadAddress() async {
    if (_readInProgress) return;
    final generation = ++_readGeneration;
    final uid = widget.uid;
    final repository = widget.deliveryAddressRepository;
    _readInProgress = true;
    if (_entryState != _EntryState.loading) {
      setState(() {
        _entryState = _EntryState.loading;
        _readError = null;
      });
    }

    late final _EntryState nextState;
    DeliveryAddress? address;
    var addressNeedsCorrection = false;
    var checkingProfile = true;
    String? errorMessage;
    try {
      final profile = await widget.profileRepository.getProfile(uid);
      if (profile == null) {
        nextState = _EntryState.profileMissing;
      } else {
        checkingProfile = false;
        address = await repository.getAddress(uid);
        nextState = address == null
            ? _EntryState.addressMissing
            : _EntryState.ready;
      }
    } on ProfileFailure catch (error) {
      if (error.operation == 'get-address' && error.code == 'invalid-address') {
        nextState = _EntryState.addressMissing;
        addressNeedsCorrection = true;
      } else {
        nextState = _EntryState.error;
        errorMessage = error.operation == 'get-profile'
            ? 'Unable to check your profile. Please try again.'
            : 'Unable to check your delivery address. Please try again.';
      }
    } on Object {
      nextState = _EntryState.error;
      errorMessage = checkingProfile
          ? 'Unable to check your profile. Please try again.'
          : 'Unable to check your delivery address. Please try again.';
    }

    if (!mounted || generation != _readGeneration) return;
    _address = address;
    _addressNeedsCorrection = addressNeedsCorrection;
    setState(() {
      _entryState = nextState;
      _readError = errorMessage;
      _readInProgress = false;
    });
  }

  /// Updates the gate after the address form has saved the user's address.
  void _onAddressSaved(DeliveryAddress address) {
    if (!mounted) return;
    setState(() {
      _address = address;
      _addressNeedsCorrection = false;
      _entryState = _EntryState.ready;
      _readError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_entryState) {
      _EntryState.loading => const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking your profile and delivery address...'),
              ],
            ),
          ),
        ),
      ),
      _EntryState.profileMissing => CompleteProfileScreen(
        uid: widget.uid,
        email: widget.email,
        profileRepository: widget.profileRepository,
        onProfileSaved: _loadAddress,
      ),
      _EntryState.addressMissing => DeliveryAddressScreen(
        uid: widget.uid,
        deliveryAddressRepository: widget.deliveryAddressRepository,
        addressNeedsCorrection: _addressNeedsCorrection,
        onAddressSaved: _onAddressSaved,
      ),
      _EntryState.error => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_readError!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _readInProgress ? null : _loadAddress,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      _EntryState.ready => MainNavigationScreen(
        uid: widget.uid,
        initialAddress: _address!,
        authRepository: widget.authRepository,
        deliveryAddressRepository: widget.deliveryAddressRepository,
        session: widget.session,
      ),
    };
  }
}
