import 'package:flutter/material.dart';

import 'core/electric_charge_station_app.dart';
import 'data/api/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialRoute = await TokenStorage().hasRememberedSession()
      ? '/home'
      : '/';

  runApp(ElectricChargeStationApp(initialRoute: initialRoute));
}
