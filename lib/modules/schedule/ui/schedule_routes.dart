// Rotas e bindings Kortex do módulo de Agenda / Calendário.
//
// SRP: compor rotas escopadas da Agenda. Não implementa regra de negócio
// nem conhece o shell do app.

import 'package:flutter/material.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../../../core/security/document_at_rest_cipher_port.dart';
import '../../../core/ui/app_scoped_route.dart';
import '../../settings/data/settings_sqlite_repository.dart';
import '../../settings/domain/entities/settings_snapshot.dart';
import '../../settings/domain/ports/settings_repository_port.dart';
import '../../settings/domain/value_objects/setting_key.dart';
import '../../settings/features/get_settings.dart';
import '../../work_orders/data/work_order_sqlite_repository.dart';
import '../../work_orders/domain/ports/work_order_repository_port.dart';
import 'day/schedule_day_controller.dart';
import 'day/schedule_day_page.dart';
import 'schedule_controller.dart';
import 'schedule_page.dart';

/// Bindings de navegação do módulo de Agenda.
final class ScheduleRoutes {
  const ScheduleRoutes({
    required this.repository,
    this.settingsRepository,
  });

  /// Constrói as rotas injetando o repositório SQLite de Ordens de Serviço.
  factory ScheduleRoutes.fromDatabase(
    SqliteProvider database, {
    IDocumentAtRestCipher? documentCipher,
  }) {
    return ScheduleRoutes(
      repository: WorkOrderSqliteRepository(
        provider: database,
        documentCipher: documentCipher,
      ),
      settingsRepository: SettingsSqliteRepository(provider: database),
    );
  }

  final IWorkOrderRepositoryPort repository;
  final ISettingsRepositoryPort? settingsRepository;

  /// Retorna a rota escopada da página de Agenda (visão mensal em tela cheia).
  Route<void> schedule({
    void Function(String workOrderId)? onWorkOrderTapped,
    void Function(DateTime date)? onDayTapped,
    void Function(DateTime date, String time)? onEmptySlotTapped,
  }) {
    return appScopedRoute<ScheduleController, void>(
      create: (_) => ScheduleController(repository: repository),
      builder: (context, _) => SchedulePage(
        onWorkOrderTapped: onWorkOrderTapped,
        onDayTapped: onDayTapped ??
            (date) {
              Navigator.of(context).push(
                day(
                  initialDate: date,
                  onWorkOrderTapped: onWorkOrderTapped,
                  onEmptySlotTapped: onEmptySlotTapped,
                ),
              );
            },
      ),
    );
  }

  /// Retorna a rota escopada da visão diária da Agenda.
  Route<void> day({
    DateTime? initialDate,
    void Function(String workOrderId)? onWorkOrderTapped,
    void Function(DateTime date, String time)? onEmptySlotTapped,
  }) {
    ISettingsRepositoryPort resolveSettingsRepo() {
      if (settingsRepository != null) return settingsRepository!;
      if (repository is WorkOrderSqliteRepository) {
        return SettingsSqliteRepository(
          provider: (repository as WorkOrderSqliteRepository).provider,
        );
      }
      return _DefaultSettingsFallbackRepo();
    }

    return appScopedRoute<ScheduleDayController, void>(
      create: (_) => ScheduleDayController(
        repository: repository,
        getSettings: GetSettings(
          repository: resolveSettingsRepo(),
        ),
        initialDate: initialDate,
      ),
      builder: (_, _) => ScheduleDayPage(
        onWorkOrderTapped: onWorkOrderTapped,
        onEmptySlotTapped: onEmptySlotTapped,
      ),
    );
  }
}

class _DefaultSettingsFallbackRepo implements ISettingsRepositoryPort {
  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async =>
      Success(SettingsSnapshot.defaults());

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    Object value,
  ) async =>
      Success(SettingsSnapshot.defaults());
}
