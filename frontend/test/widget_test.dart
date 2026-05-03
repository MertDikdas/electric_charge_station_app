import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/electric_charge_station_app.dart';

void main() {
  testWidgets('shows login and opens main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ElectricChargeStationApp());

    expect(find.text('Ho\u015f Geldin'), findsOneWidget);
    expect(find.text('Telefon numaran\u0131z\u0131 giriniz'), findsOneWidget);
    expect(find.text('Giri\u015f Yap'), findsOneWidget);

    await tester.tap(find.text('Misafir Olarak Devam Et \u2192'));
    await tester.pumpAndSettle();

    expect(find.text('Stations Map'), findsOneWidget);
    expect(find.text('Map placeholder'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.directions_car_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle'), findsWidgets);
    expect(find.text('Add Vehicle'), findsWidgets);

    await tester.tap(find.byIcon(Icons.event_available_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Reservation'), findsWidgets);
    expect(find.text('Create Reservation'), findsWidgets);

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();

    expect(find.text('My Reservations'), findsWidgets);
    expect(find.text('No reservations yet'), findsOneWidget);
  });
}
