import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/electric_charge_station_app.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ElectricChargeStationApp());

    expect(find.text('Ho\u015f Geldin'), findsOneWidget);
    expect(find.text('Gelece\u011fi \u015earj Et'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
