import 'dart:io';
import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/ports/backup_failure_codes.dart';

/// Assinatura para compartilhamento de arquivo via share sheet nativo.
typedef BackupShareInvoker = Future<void> Function(
  List<XFile> files, {
  String? text,
  String? subject,
});

/// Assinatura para obter diretório temporário/armazenamento.
typedef DirectoryProvider = Future<Directory> Function();

/// Adaptador para I/O local de arquivos e acionamento do compartilhamento do SO (UC-08.02, RF-13).
final class BackupFileAdapter {
  const BackupFileAdapter({
    BackupShareInvoker? shareInvoker,
    DirectoryProvider? tempDirectoryProvider,
    DirectoryProvider? documentsDirectoryProvider,
  })  : _shareInvoker = shareInvoker ?? _defaultShareInvoker,
        _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory,
        _documentsDirectoryProvider = documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final BackupShareInvoker _shareInvoker;
  final DirectoryProvider _tempDirectoryProvider;
  final DirectoryProvider _documentsDirectoryProvider;

  static Future<void> _defaultShareInvoker(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    await Share.shareXFiles(files, text: text, subject: subject);
  }

  /// Salva os bytes cifrados em arquivo temporário e abre a folha nativa de compartilhamento.
  Future<IResult<String, ValidationError>> shareBackupFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final dir = await _tempDirectoryProvider();
      final backupDir = Directory(p.join(dir.path, 'backups'));
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      final filePath = p.join(backupDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      final xFile = XFile(filePath, mimeType: 'application/octet-stream');
      await _shareInvoker([xFile], subject: 'Backup ServiceTrack');

      return Success(filePath);
    } catch (e) {
      return Failure(
        ValidationError(
          code: BackupFailureCodes.ioError,
          message: 'Falha ao salvar ou compartilhar arquivo de backup: $e',
        ),
      );
    }
  }

  /// Salva o arquivo de backup no diretório de documentos do aplicativo.
  Future<IResult<String, ValidationError>> saveToDocuments({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final dir = await _documentsDirectoryProvider();
      final backupDir = Directory(p.join(dir.path, 'backups'));
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }
      final filePath = p.join(backupDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return Success(filePath);
    } catch (e) {
      return Failure(
        ValidationError(
          code: BackupFailureCodes.ioError,
          message: 'Falha ao salvar arquivo de backup no armazenamento: $e',
        ),
      );
    }
  }

  /// Lista arquivos de backup salvos localmente.
  Future<IResult<List<File>, ValidationError>> listLocalBackups() async {
    try {
      final dir = await _documentsDirectoryProvider();
      final backupDir = Directory(p.join(dir.path, 'backups'));
      if (!backupDir.existsSync()) {
        return const Success([]);
      }
      final entities = backupDir.listSync();
      final files = entities.whereType<File>().toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return Success(files);
    } catch (e) {
      return Failure(
        ValidationError(
          code: BackupFailureCodes.ioError,
          message: 'Falha ao listar backups locais: $e',
        ),
      );
    }
  }

  /// Lê os bytes de um arquivo local.
  Future<IResult<Uint8List, ValidationError>> readFileBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Failure(
          ValidationError(
            code: BackupFailureCodes.ioError,
            message: 'Arquivo de backup não encontrado.',
          ),
        );
      }
      final bytes = await file.readAsBytes();
      return Success(bytes);
    } catch (e) {
      return Failure(
        ValidationError(
          code: BackupFailureCodes.ioError,
          message: 'Falha ao ler arquivo de backup: $e',
        ),
      );
    }
  }
}
