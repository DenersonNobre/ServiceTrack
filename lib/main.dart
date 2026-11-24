import 'package:flutter/material.dart';

import 'app/database/app_database.dart';
import 'app/service_track_app.dart';
import 'core/.index.dart';

export 'app/service_track_app.dart' show ServiceTrackApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  applyDeviceOrientationPolicy();
  final db = createAppDatabase();
  runApp(ServiceTrackApp(database: db));
}
