import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/electric_charge_station_app.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ElectricChargeStationApp());

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Charge the Future'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
