import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grabber_app/features/profile/domain/entities/delivery_address.dart';
import 'package:grabber_app/features/profile/domain/repositories/delivery_address_repository.dart';
import 'package:grabber_app/features/profile/presentation/screens/delivery_address_screen.dart';

void main() {
  testWidgets('shows exactly the four required address fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(_FakeDeliveryAddressRepository()));

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('City'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('Street Name'), findsOneWidget);
    expect(find.text('Building Number'), findsOneWidget);
    expect(find.text('Add your delivery address'), findsOneWidget);
  });

  testWidgets('editing pre-fills the saved address and updates it', (
    WidgetTester tester,
  ) async {
    const savedAddress = DeliveryAddress(
      city: 'Cairo',
      district: 'Nasr City',
      streetName: 'Example Street',
      buildingNumber: '12A',
    );
    final repository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(_testApp(repository, initialAddress: savedAddress));

    expect(find.text('Update your delivery address'), findsOneWidget);
    expect(find.text('Update Address'), findsOneWidget);
    expect(_fieldValue(tester, 0), 'Cairo');
    expect(_fieldValue(tester, 3), '12A');

    await tester.enterText(find.byType(TextFormField).at(2), 'Updated Street');
    await tester.tap(find.text('Update Address'));
    await tester.pumpAndSettle();

    expect(repository.savedAddresses.single.streetName, 'Updated Street');
  });

  testWidgets('invalid existing address can be replaced without skipping', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(_FakeDeliveryAddressRepository(), addressNeedsCorrection: true),
    );

    expect(
      find.text(
        'Your saved address is incomplete. Please correct it to continue.',
      ),
      findsOneWidget,
    );
    expect(find.text('Update Address'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('rejects empty and whitespace-only values in every field', (
    WidgetTester tester,
  ) async {
    for (final invalidValue in ['', ' \t ']) {
      for (var invalidIndex = 0; invalidIndex < 4; invalidIndex++) {
        final repository = _FakeDeliveryAddressRepository();
        await tester.pumpWidget(_testApp(repository));
        for (var index = 0; index < 4; index++) {
          await tester.enterText(
            find.byType(TextFormField).at(index),
            index == invalidIndex ? invalidValue : 'Valid value',
          );
        }

        await tester.tap(find.text('Save Address'));
        await tester.pumpAndSettle();

        expect(repository.saveCalls, 0);
        expect(find.text('This field is required'), findsOneWidget);
      }
    }
  });

  testWidgets('valid input saves the address using the authenticated UID', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository();
    await tester.pumpWidget(_testApp(repository));
    await _enterValidAddress(tester);

    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 1);
    expect(repository.savedUids, ['authenticated-user']);
    expect(repository.savedAddresses, hasLength(1));
    expect(repository.savedAddresses.single.city, 'Cairo');
    expect(repository.savedAddresses.single.district, 'Nasr City');
    expect(repository.savedAddresses.single.streetName, 'Example Street');
    expect(repository.savedAddresses.single.buildingNumber, '12A');
  });

  testWidgets('saved and reported address values are trimmed consistently', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository();
    DeliveryAddress? reportedAddress;
    await tester.pumpWidget(
      _testApp(
        repository,
        onAddressSaved: (address) => reportedAddress = address,
      ),
    );
    const values = [' Cairo ', ' Nasr City ', ' Example Street ', ' 12A '];
    for (var index = 0; index < values.length; index++) {
      await tester.enterText(
        find.byType(TextFormField).at(index),
        values[index],
      );
    }

    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    expect(repository.savedAddresses.single.city, 'Cairo');
    expect(repository.savedAddresses.single.streetName, 'Example Street');
    expect(reportedAddress?.city, 'Cairo');
    expect(reportedAddress?.streetName, 'Example Street');
  });

  testWidgets('reports a successful save to the caller', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository();
    DeliveryAddress? savedAddress;
    await tester.pumpWidget(
      _testApp(repository, onAddressSaved: (address) => savedAddress = address),
    );
    await _enterValidAddress(tester);

    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    expect(savedAddress?.city, 'Cairo');
    expect(savedAddress?.district, 'Nasr City');
    expect(savedAddress?.streetName, 'Example Street');
    expect(savedAddress?.buildingNumber, '12A');
  });

  testWidgets('save failure keeps the screen and entered values for retry', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..failures.add(Exception('temporary failure'));
    await tester.pumpWidget(_testApp(repository));
    await _enterValidAddress(tester);

    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
    expect(
      find.text('Unable to save your delivery address. Please try again.'),
      findsOneWidget,
    );
    expect(_fieldValue(tester, 0), 'Cairo');
    expect(_fieldValue(tester, 1), 'Nasr City');
    expect(_fieldValue(tester, 2), 'Example Street');
    expect(_fieldValue(tester, 3), '12A');
    expect(find.text('Retry Save Address'), findsOneWidget);
  });

  testWidgets('retry saves again without an account-registration dependency', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..failures.add(Exception('temporary failure'));
    await tester.pumpWidget(_testApp(repository));
    await _enterValidAddress(tester);

    await tester.tap(find.text('Save Address'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Retry Save Address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry Save Address'));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, 2);
    expect(repository.savedUids, ['authenticated-user', 'authenticated-user']);
    expect(repository.savedAddresses, hasLength(2));
    expect(repository.savedAddresses[1].city, 'Cairo');
    expect(repository.savedAddresses[1].district, 'Nasr City');
    expect(repository.savedAddresses[1].streetName, 'Example Street');
    expect(repository.savedAddresses[1].buildingNumber, '12A');
    expect(find.byType(DeliveryAddressScreen), findsOneWidget);
  });

  testWidgets('prevents duplicate submissions while saving', (
    WidgetTester tester,
  ) async {
    final repository = _FakeDeliveryAddressRepository()
      ..pendingSave = Completer<void>();
    var successCount = 0;
    await tester.pumpWidget(
      _testApp(repository, onAddressSaved: (_) => successCount++),
    );
    await _enterValidAddress(tester);

    await tester.tap(find.text('Save Address'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    expect(repository.saveCalls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('Saving address...'), findsOneWidget);
    expect(successCount, 0);

    repository.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(successCount, 1);
  });

  testWidgets('does not offer a Skip action', (WidgetTester tester) async {
    await tester.pumpWidget(_testApp(_FakeDeliveryAddressRepository()));

    expect(find.text('Skip'), findsNothing);
    expect(find.textContaining('Skip'), findsNothing);
  });
}

Widget _testApp(
  _FakeDeliveryAddressRepository repository, {
  ValueChanged<DeliveryAddress>? onAddressSaved,
  DeliveryAddress? initialAddress,
  bool addressNeedsCorrection = false,
}) {
  return MaterialApp(
    key: UniqueKey(),
    home: DeliveryAddressScreen(
      uid: 'authenticated-user',
      deliveryAddressRepository: repository,
      onAddressSaved: onAddressSaved ?? (_) {},
      initialAddress: initialAddress,
      addressNeedsCorrection: addressNeedsCorrection,
    ),
  );
}

Future<void> _enterValidAddress(WidgetTester tester) async {
  const values = ['Cairo', 'Nasr City', 'Example Street', '12A'];
  for (var index = 0; index < values.length; index++) {
    await tester.enterText(find.byType(TextFormField).at(index), values[index]);
  }
}

String? _fieldValue(WidgetTester tester, int index) => tester
    .widget<TextFormField>(find.byType(TextFormField).at(index))
    .controller
    ?.text;

class _FakeDeliveryAddressRepository implements DeliveryAddressRepository {
  final List<String> savedUids = [];
  final List<DeliveryAddress> savedAddresses = [];
  final List<Object> failures = [];
  int saveCalls = 0;
  Completer<void>? pendingSave;

  @override
  Future<DeliveryAddress?> getAddress(String uid) async => null;

  @override
  Future<void> saveAddress({
    required String uid,
    required DeliveryAddress address,
  }) async {
    saveCalls++;
    savedUids.add(uid);
    savedAddresses.add(address);
    final pending = pendingSave;
    if (pending != null) await pending.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
  }
}
