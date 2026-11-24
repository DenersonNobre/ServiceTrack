import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/database/app_database.dart';
import 'core/.index.dart';

export 'app/app.dart' show App;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  applyDeviceOrientationPolicy();
  final db = createAppDatabase();
  runApp(App(database: db));
}
