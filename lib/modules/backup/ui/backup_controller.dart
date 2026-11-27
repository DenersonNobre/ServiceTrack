import 'dart:io';
import 'package:intl/intl.dart';
import 'package:kortex_lib/kortex_lib.dart';

import '../data/backup_file_adapter.dart';
import '../domain/entities/backup_metadata.dart';
import '../domain/use_cases/export_backup_use_case.dart';
import '../domain/use_cases/inspect_backup_use_case.dart';
import '../domain/use_cases/restore_backup_use_case.dart';

/// Estado da operação de backup/restauração.
enum BackupOperationStatus {
  idle,
  exporting,
  inspecting,
  restoring,
}

/// Controller Kortex para operações de Backup e Restauração Segura Local (UC-08.02, RF-13).
final class BackupController extends IKortexController {
  BackupController({
    required this.exportBackupUseCase,
    required this.inspectBackupUseCase,
    required this.restoreBackupUseCase,
    BackupFileAdapter? fileAdapter,
  }) : fileAdapter = fileAdapter ?? const BackupFileAdapter();

  final ExportBackupUseCase exportBackupUseCase;
  final InspectBackupUseCase inspectBackupUseCase;
  final RestoreBackupUseCase restoreBackupUseCase;
  final BackupFileAdapter fileAdapter;

  final KortexSignal<BackupOperationStatus> status =
      KortexSignal<BackupOperationStatus>(BackupOperationStatus.idle);

  final KortexSignal<List<File>> localBackups =
      KortexSignal<List<File>>(const []);

  final KortexSignal<BackupMetadata?> inspectedMetadata =
      KortexSignal<BackupMetadata?>(null);

  final KortexSignal<String?> selectedBackupPath =
      KortexSignal<String?>(null);

  final KortexSignal<String?> errorMessage =
      KortexSignal<String?>(null);

  final KortexSignal<String?> successMessage =
      KortexSignal<String?>(null);

  /// Inicializa e lista backups locais conhecidos.
  Future<void> loadLocalBackups() async {
    final result = await fileAdapter.listLocalBackups();
    if (result case Success(:final value)) {
      localBackups.value = value;
    }
  }

  /// Exporta o backup cifrado e aciona a folha de compartilhamento/salvamento.
  Future<bool> exportBackup({
    required String password,
    bool saveToLocalDocuments = true,
  }) async {
    errorMessage.value = null;
    successMessage.value = null;
    status.value = BackupOperationStatus.exporting;

    final exportResult = await exportBackupUseCase.execute(password: password);
    if (exportResult case Failure(:final value)) {
      status.value = BackupOperationStatus.idle;
      errorMessage.value = value.message;
      return false;
    }

    final bytes = exportResult.getOrNull()!;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'servicetrack_backup_$timestamp.stb';

    if (saveToLocalDocuments) {
      final saveRes = await fileAdapter.saveToDocuments(
        bytes: bytes,
        fileName: fileName,
      );
      if (saveRes case Failure(:final value)) {
        status.value = BackupOperationStatus.idle;
        errorMessage.value = value.message;
        return false;
      }
    }

    final shareRes = await fileAdapter.shareBackupFile(
      bytes: bytes,
      fileName: fileName,
    );

    status.value = BackupOperationStatus.idle;

    if (shareRes case Failure(:final value)) {
      errorMessage.value = value.message;
      return false;
    }

    successMessage.value = 'Backup gerado com sucesso: $fileName';
    await loadLocalBackups();
    return true;
  }

  /// Inspeciona o arquivo de backup e senha antes de confirmar a restauração.
  Future<bool> inspectBackup({
    required String filePath,
    required String password,
  }) async {
    errorMessage.value = null;
    successMessage.value = null;
    inspectedMetadata.value = null;
    selectedBackupPath.value = null;
    status.value = BackupOperationStatus.inspecting;

    final readRes = await fileAdapter.readFileBytes(filePath);
    if (readRes case Failure(:final value)) {
      status.value = BackupOperationStatus.idle;
      errorMessage.value = value.message;
      return false;
    }

    final bytes = readRes.getOrNull()!;
    final inspectRes = await inspectBackupUseCase.execute(
      encryptedData: bytes,
      password: password,
    );

    status.value = BackupOperationStatus.idle;

    if (inspectRes case Failure(:final value)) {
      errorMessage.value = value.message;
      return false;
    }

    inspectedMetadata.value = inspectRes.getOrNull()!;
    selectedBackupPath.value = filePath;
    return true;
  }

  /// Executa a restauração atômica dos dados a partir do arquivo inspecionado.
  Future<bool> confirmRestore({
    required String password,
  }) async {
    final filePath = selectedBackupPath.value;
    if (filePath == null) {
      errorMessage.value = 'Nenhum backup selecionado para restauração.';
      return false;
    }

    errorMessage.value = null;
    successMessage.value = null;
    status.value = BackupOperationStatus.restoring;

    final readRes = await fileAdapter.readFileBytes(filePath);
    if (readRes case Failure(:final value)) {
      status.value = BackupOperationStatus.idle;
      errorMessage.value = value.message;
      return false;
    }

    final bytes = readRes.getOrNull()!;
    final restoreRes = await restoreBackupUseCase.execute(
      encryptedData: bytes,
      password: password,
    );

    status.value = BackupOperationStatus.idle;

    if (restoreRes case Failure(:final value)) {
      errorMessage.value = value.message;
      return false;
    }

    inspectedMetadata.value = null;
    selectedBackupPath.value = null;
    successMessage.value = 'Dados restaurados com sucesso a partir do backup.';
    return true;
  }

  void clearSelection() {
    inspectedMetadata.value = null;
    selectedBackupPath.value = null;
    errorMessage.value = null;
  }
}
