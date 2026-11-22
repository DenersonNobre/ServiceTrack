import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/database/app_database.dart';
import 'app/service_track_app.dart';
import 'core/.index.dart';
import 'modules/checklists/data/checklist_answer_sqlite_repository.dart';
import 'modules/checklists/data/checklist_template_sqlite_repository.dart';
import 'modules/customers/data/.index.dart';
import 'modules/profile/data/.index.dart';
import 'modules/work_orders/data/.index.dart';

export 'app/service_track_app.dart' show ServiceTrackApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  applyDeviceOrientationPolicy();
  final db = createAppDatabase();
  runApp(
    ServiceTrackApp(
      profileRepository: FileTechnicianProfileRepository(
        baseDir: getApplicationSupportDirectory,
      ),
      customerRepository: CustomerSqliteRepository(provider: db),
      serviceLocationRepository: ServiceLocationSqliteRepository(provider: db),
      workOrderRepository: WorkOrderSqliteRepository(provider: db),
      checklistTemplateRepository: ChecklistTemplateSqliteRepository(provider: db),
      checklistAnswerRepository: ChecklistAnswerSqliteRepository(provider: db),
    ),
  );
}
