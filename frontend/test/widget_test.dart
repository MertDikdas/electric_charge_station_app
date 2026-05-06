import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/electric_charge_station_app.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ElectricChargeStationApp());

    expect(find.text('Hos Geldin'), findsNothing);
    expect(find.text('Hoş Geldin'), findsOneWidget);
    expect(find.text('Telefon veya e-posta'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('Üye Ol'), findsOneWidget);
  });
}
