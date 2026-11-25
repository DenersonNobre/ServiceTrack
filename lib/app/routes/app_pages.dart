// Gerador e roteador declarativo de páginas da aplicação ServiceTrack.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:path_provider/path_provider.dart';

import '../../modules/auth/ui/auth_routes.dart';
import '../../modules/checklists/data/checklist_answer_sqlite_repository.dart';
import '../../modules/checklists/data/checklist_template_sqlite_repository.dart';
import '../../modules/checklists/domain/entities/checklist_answer.dart';
import '../../modules/checklists/domain/entities/checklist_template.dart';
import '../../modules/checklists/ui/checklists_routes.dart';
import '../../modules/customers/data/customer_sqlite_repository.dart';
import '../../modules/customers/ui/customers_routes.dart';
import '../../modules/home/ui/home_routes.dart';
import '../../modules/profile/data/file_technician_profile_repository.dart';
import '../../modules/profile/ui/profile_routes.dart';
import '../../modules/reports/data/pdf_report_generator_adapter.dart';
import '../../modules/reports/data/report_data_assembler.dart';
import '../../modules/reports/data/report_storage_adapter.dart';
import '../../modules/reports/data/share_service_adapter.dart';
import '../../modules/reports/domain/models/report_data.dart';
import '../../modules/reports/domain/models/report_history_item.dart';
import '../../modules/reports/ui/reports_routes.dart';
import '../../modules/schedule/ui/schedule_routes.dart';
import '../../modules/settings/ui/settings_routes.dart';
import '../../modules/work_orders/data/work_order_sqlite_repository.dart';
import '../../modules/work_orders/domain/value_objects/work_order_status.dart';
import '../../modules/work_orders/ui/work_orders_routes.dart';
import '../app_gate.dart';
import '../app_services.dart';
import 'app_routes.dart';

/// Fabrica de rotas do aplicativo integrando os sub-módulos com o Navigator.
class AppPages {
  AppPages({
    required this.services,
    this.navigatorKey,
    AuthRoutes? authRoutes,
    HomeRoutes? homeRoutes,
    CustomersRoutes? customersRoutes,
    WorkOrdersRoutes? workOrdersRoutes,
    ProfileRoutes? profileRoutes,
    ChecklistsRoutes? checklistsRoutes,
    SettingsRoutes? settingsRoutes,
    ScheduleRoutes? scheduleRoutes,
    ReportsRoutes? reportsRoutes,
  })  : _authRoutes = authRoutes ?? AuthRoutes.fromServices(services),
        _initialHomeRoutes = homeRoutes,
        _initialCustomersRoutes = customersRoutes,
        _initialWorkOrdersRoutes = workOrdersRoutes,
        _initialProfileRoutes = profileRoutes,
        _initialChecklistsRoutes = checklistsRoutes,
        _initialSettingsRoutes = settingsRoutes,
        _initialScheduleRoutes = scheduleRoutes,
        _initialReportsRoutes = reportsRoutes {
    _initSubRoutes();
  }

  final AppServices services;
  final GlobalKey<NavigatorState>? navigatorKey;
  final AuthRoutes _authRoutes;
  final HomeRoutes? _initialHomeRoutes;
  final CustomersRoutes? _initialCustomersRoutes;
  final WorkOrdersRoutes? _initialWorkOrdersRoutes;
  final ProfileRoutes? _initialProfileRoutes;
  final ChecklistsRoutes? _initialChecklistsRoutes;
  final SettingsRoutes? _initialSettingsRoutes;
  final ScheduleRoutes? _initialScheduleRoutes;
  final ReportsRoutes? _initialReportsRoutes;

  HomeRoutes? _homeRoutes;
  CustomersRoutes? _customersRoutes;
  WorkOrdersRoutes? _workOrdersRoutes;
  ProfileRoutes? _profileRoutes;
  ChecklistsRoutes? _checklistsRoutes;
  SettingsRoutes? _settingsRoutes;
  ScheduleRoutes? _scheduleRoutes;
  ReportsRoutes? _reportsRoutes;

  void _initSubRoutes() {
    _homeRoutes = _initialHomeRoutes;
    _customersRoutes = _initialCustomersRoutes;
    _workOrdersRoutes = _initialWorkOrdersRoutes;
    _profileRoutes = _initialProfileRoutes;
    _checklistsRoutes = _initialChecklistsRoutes;
    _settingsRoutes = _initialSettingsRoutes;
    _scheduleRoutes = _initialScheduleRoutes;
    _reportsRoutes = _initialReportsRoutes;

    final db = services.database;
    if (db != null) {
      _homeRoutes ??= HomeRoutes.fromDatabase(db);
      _customersRoutes ??= CustomersRoutes.fromDatabase(db);
      _workOrdersRoutes ??= WorkOrdersRoutes.fromDatabase(
        database: db,
        locationService: services.locationService,
      );
      _profileRoutes ??= ProfileRoutes.standard();
      _checklistsRoutes ??= ChecklistsRoutes.fromDatabase(db);
      _settingsRoutes ??= SettingsRoutes.fromDatabase(db);
      _scheduleRoutes ??= ScheduleRoutes.fromDatabase(db);
      _reportsRoutes ??= ReportsRoutes(
        pdfGenerator: const PdfReportGeneratorAdapter(),
        shareService: const ShareServiceAdapter(),
        reportStorage: ReportStorageAdapter(),
        reportDataLoader: _loadReportData,
      );
    }
  }

  Future<IResult<ReportData, ValidationError>> _loadReportData(
    String workOrderId,
  ) async {
    final db = services.database;
    if (db == null) {
      return const Failure(
        ValidationError(
          code: 'REPORT_DATA_LOAD_FAILED',
          message: 'Banco de dados indisponível para carregar o laudo.',
        ),
      );
    }

    try {
      final workOrderRepository = WorkOrderSqliteRepository(provider: db);
      final customerRepository = CustomerSqliteRepository(provider: db);
      final templateRepository = ChecklistTemplateSqliteRepository(provider: db);
      final answerRepository = ChecklistAnswerSqliteRepository(provider: db);
      final profileRepository = FileTechnicianProfileRepository(
        baseDir: getApplicationSupportDirectory,
      );

      final workOrdersResult = await workOrderRepository.findAll();
      if (workOrdersResult.isFailure) {
        final err = workOrdersResult.getOrNullFailure()!;
        return Failure(
          ValidationError(
            code: err.code,
            message: 'Não foi possível carregar a Ordem de Serviço.',
          ),
        );
      }

      final workOrder = workOrdersResult
          .getOrNull()!
          .where((wo) => wo.id == workOrderId)
          .firstOrNull;
      if (workOrder == null) {
        return const Failure(
          ValidationError(
            code: 'REPORT_DATA_NOT_FOUND',
            message: 'Ordem de Serviço não encontrada para gerar o laudo.',
          ),
        );
      }

      final customerResult = await customerRepository.findById(
        workOrder.customerId,
      );
      final customer = customerResult.isSuccess
          ? customerResult.getOrNull()
          : null;

      final profileResult = await profileRepository.load();
      final profile = profileResult.isSuccess ? profileResult.getOrNull() : null;

      Uint8List? technicianLogoBytes;
      final logoPath = profile?.logoPath;
      if (logoPath != null && logoPath.isNotEmpty) {
        final logoFile = File(logoPath);
        if (await logoFile.exists()) {
          technicianLogoBytes = await logoFile.readAsBytes();
        }
      }

      ChecklistTemplate? template;
      final templateId = workOrder.checklistTemplateId;
      if (templateId != null && templateId.isNotEmpty) {
        final templateResult = await templateRepository.findById(templateId);
        if (templateResult.isSuccess) {
          template = templateResult.getOrNull();
        }
      }

      var answers = const <ChecklistAnswer>[];
      final answersResult = await answerRepository.findByWorkOrder(workOrderId);
      if (answersResult.isSuccess) {
        answers = answersResult.getOrNull()!;
      }

      final reportData = ReportDataAssembler.assemble(
        workOrder: workOrder,
        customer: customer,
        technicianProfile: profile,
        template: template,
        answers: answers,
        technicianLogoBytes: technicianLogoBytes,
      );
      return Success(reportData);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: 'REPORT_DATA_LOAD_FAILED',
          message: 'Não foi possível carregar os dados do laudo.',
        ),
      );
    }
  }

  Future<IResult<List<ReportHistoryItem>, ValidationError>>
      _loadReportHistory() async {
    final db = services.database;
    if (db == null) {
      return const Failure(
        ValidationError(
          code: 'REPORT_HISTORY_LOAD_FAILED',
          message: 'Banco de dados indisponível para carregar o histórico.',
        ),
      );
    }

    try {
      final workOrderRepository = WorkOrderSqliteRepository(provider: db);
      final customerRepository = CustomerSqliteRepository(provider: db);
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      final workOrdersResult = await workOrderRepository.findAll();
      if (workOrdersResult.isFailure) {
        final err = workOrdersResult.getOrNullFailure()!;
        return Failure(
          ValidationError(
            code: err.code,
            message: 'Não foi possível carregar o histórico de laudos.',
          ),
        );
      }

      final customersResult = await customerRepository.findAll();
      final customersById = <String, String>{};
      if (customersResult.isSuccess) {
        for (final customer in customersResult.getOrNull()!) {
          customersById[customer.id] = customer.name.value;
        }
      }

      final completed = workOrdersResult
          .getOrNull()!
          .where((wo) => wo.status == WorkOrderStatus.completed)
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      final items = completed
          .map(
            (wo) => ReportHistoryItem(
              workOrderId: wo.id,
              serviceDescription: wo.serviceDescription,
              scheduledDateFormatted: dateFormat.format(
                wo.scheduledAt.toLocal(),
              ),
              completedDateFormatted: wo.checkOut == null
                  ? null
                  : dateFormat.format(wo.checkOut!.timestampUtc.toLocal()),
              customerName: customersById[wo.customerId],
              status: wo.status.code,
            ),
          )
          .toList(growable: false);

      return Success(items);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: 'REPORT_HISTORY_LOAD_FAILED',
          message: 'Não foi possível carregar o histórico de laudos.',
        ),
      );
    }
  }

  /// Método gerador de rotas para plug-in em [MaterialApp.onGenerateRoute].
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.initial => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppGate(),
        ),
      AppRoutes.onboarding => _authRoutes.onboarding(
          onCompleted: () => _pushNamedReplacement(AppRoutes.home),
        ),
      AppRoutes.lock => _authRoutes.lock(
          onUnlocked: () => _pushNamedReplacement(AppRoutes.home),
          onForgotPin: () => _pushNamed(AppRoutes.recovery),
        ),
      AppRoutes.recovery => _authRoutes.recovery(
          onRecovered: () => _popAndPushNamedReplacement(AppRoutes.home),
        ),
      AppRoutes.home => _homeRoutes?.home(
          onProfile: () => _pushNamed(AppRoutes.profile),
          onCustomers: () => _pushNamed(AppRoutes.customers),
          onWorkOrders: () => _pushNamed(AppRoutes.workOrders),
          onNewWorkOrder: () => _pushNamed(AppRoutes.newWorkOrder),
          onChecklists: () => _pushNamed(AppRoutes.checklists),
          onSettings: () => _pushNamed(AppRoutes.settings),
          onReportHistory: () => _pushNamed(AppRoutes.reportHistory),
          onSchedule: () => _pushNamed(AppRoutes.schedule),
        ),
      AppRoutes.profile => _profileRoutes?.edit(),
      AppRoutes.customers => _customersRoutes?.list(),
      AppRoutes.workOrders => _workOrdersRoutes?.list(
          onReport: (id) =>
              _pushNamedWithArgs(AppRoutes.reportPreview, arguments: id),
        ),
      AppRoutes.schedule => _scheduleRoutes?.schedule(
            onWorkOrderTapped: (id) => _pushNamed(AppRoutes.workOrders),
            onEmptySlotTapped: (date, time) => _pushNamed(AppRoutes.newWorkOrder),
          ) ??
          _workOrdersRoutes?.list(
            onReport: (id) =>
                _pushNamedWithArgs(AppRoutes.reportPreview, arguments: id),
          ),
      AppRoutes.newWorkOrder => _workOrdersRoutes?.form(),
      AppRoutes.checklists => _checklistsRoutes?.list(),
      AppRoutes.settings => _settingsRoutes?.edit(),
      AppRoutes.reportPreview =>
        _reportsRoutes?.preview(settings.arguments),
      AppRoutes.reportHistory => _reportsRoutes?.history(
          loadHistory: _loadReportHistory,
          onOpenReport: (id) =>
              _pushNamedWithArgs(AppRoutes.reportPreview, arguments: id),
        ),
      _ => null,
    };
  }

  void _pushNamed(String routeName) {
    final nav = navigatorKey?.currentState;
    nav?.pushNamed(routeName);
  }

  void _pushNamedWithArgs(String routeName, {Object? arguments}) {
    final nav = navigatorKey?.currentState;
    nav?.pushNamed(routeName, arguments: arguments);
  }

  void _pushNamedReplacement(String routeName) {
    final nav = navigatorKey?.currentState;
    nav?.pushReplacementNamed(routeName);
  }

  void _popAndPushNamedReplacement(String routeName) {
    final nav = navigatorKey?.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    nav?.pushReplacementNamed(routeName);
  }
}
