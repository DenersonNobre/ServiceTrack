import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:kortex_lib/kortex_lib.dart';
import 'package:sqflite/sqflite.dart' as sqf;

import '../domain/entities/backup_metadata.dart';
import '../domain/entities/backup_payload.dart';
import '../domain/ports/backup_failure_codes.dart';
import '../domain/ports/backup_service_port.dart';

/// Implementação do serviço de backup e restauração local para SQLite (UC-08.02, RF-13).
///
/// SRP: extrair tabelas, empacotar, cifrar com AES-GCM (usando chave derivada por PBKDF2/SHA256)
/// e restaurar atomicamente dentro de uma transação.
final class SqliteBackupService implements IBackupServicePort {
  SqliteBackupService({required this.provider});

  final SqliteProvider provider;

  static const int currentSchemaVersion = 1;
  static const int _saltLength = 16;
  static const int _ivLength = 12;
  static const int _pbkdf2Iterations = 10000;
  static const int _keyLength = 32;

  /// Ordem de inserção: tabelas pai primeiro, filhas depois.
  static const List<String> supportedTables = [
    'customers',
    'checklist_templates',
    'service_locations',
    'checklist_items',
    'work_orders',
    'checklist_answers',
    'app_settings',
  ];

  @override
  Future<IResult<Uint8List, ValidationError>> exportBackup({
    required String password,
  }) async {
    try {
      final db = await provider.db;
      final tablesData = <String, List<Map<String, dynamic>>>{};

      for (final table in supportedTables) {
        final rows = await db.query(table);
        tablesData[table] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      }

      final payload = BackupPayload(tables: tablesData);
      final jsonPayloadString = jsonEncode(payload.toMap());
      final payloadBytes = utf8.encode(jsonPayloadString);
      final checksum = sha256.convert(payloadBytes).toString();

      final metadata = BackupMetadata(
        schemaVersion: currentSchemaVersion,
        createdAt: DateTime.now().toUtc(),
        recordCounts: payload.calculateRecordCounts(),
        checksumSha256: checksum,
      );

      final rootContainer = {
        'metadata': metadata.toMap(),
        'payload': payload.toMap(),
      };

      final plaintextBytes = utf8.encode(jsonEncode(rootContainer));

      // Gerar Salt seguro
      final random = Random.secure();
      final salt = Uint8List.fromList(
        List<int>.generate(_saltLength, (_) => random.nextInt(256)),
      );

      // Derivar chave de 256 bits com PBKDF2-HMAC-SHA256
      final derivedKeyBytes = _deriveKey(password, salt);
      final key = enc.Key(derivedKeyBytes);

      // Cifrar com AES-GCM
      final iv = enc.IV.fromSecureRandom(_ivLength);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encryptBytes(plaintextBytes, iv: iv);

      // Formato binário: [salt (16b)] + [iv (12b)] + [ciphertext + tag]
      final builder = BytesBuilder(copy: false)
        ..add(salt)
        ..add(iv.bytes)
        ..add(encrypted.bytes);

      return Success(builder.toBytes());
    } catch (_) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.databaseError,
          message: 'Falha ao extrair e empacotar dados do banco local.',
        ),
      );
    }
  }

  @override
  Future<IResult<BackupMetadata, ValidationError>> inspectBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    final decryptRes = _decryptContainer(encryptedData, password);
    if (decryptRes case Failure(:final value)) {
      return Failure(value);
    }

    final container = decryptRes.getOrNull()!;
    final metaMap = container['metadata'] as Map<String, dynamic>?;
    if (metaMap == null) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.corruptedData,
          message: 'Metadados ausentes no arquivo de backup.',
        ),
      );
    }

    try {
      final meta = BackupMetadata.fromMap(metaMap);
      return Success(meta);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.corruptedData,
          message: 'Metadados corrompidos no arquivo de backup.',
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> restoreBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    final decryptRes = _decryptContainer(encryptedData, password);
    if (decryptRes case Failure(:final value)) {
      return Failure(value);
    }

    final container = decryptRes.getOrNull()!;
    final metaMap = container['metadata'] as Map<String, dynamic>?;
    final payloadMap = container['payload'] as Map<String, dynamic>?;

    if (metaMap == null || payloadMap == null) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.corruptedData,
          message: 'Estrutura interna do backup corrompida.',
        ),
      );
    }

    final metadata = BackupMetadata.fromMap(metaMap);
    final payload = BackupPayload.fromMap(payloadMap);

    // Validar checksum SHA-256
    final payloadJson = jsonEncode(payload.toMap());
    final computedChecksum = sha256.convert(utf8.encode(payloadJson)).toString();
    if (computedChecksum != metadata.checksumSha256) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.corruptedData,
          message: 'Falha na verificação de integridade dos dados (checksum incorreto).',
        ),
      );
    }

    // Executar restauração atômica em transação
    try {
      final db = await provider.db;
      await db.transaction((txn) async {
        // Desativar chaves estrangeiras temporariamente durante recarga ou limpar em ordem reversa
        final reversedTables = supportedTables.reversed.toList();
        for (final table in reversedTables) {
          await txn.delete(table);
        }

        for (final table in supportedTables) {
          final rows = payload.tables[table];
          if (rows != null && rows.isNotEmpty) {
            for (final row in rows) {
              await txn.insert(
                table,
                row,
                conflictAlgorithm: sqf.ConflictAlgorithm.replace,
              );
            }
          }
        }
      });
      return const Success(true);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.databaseError,
          message: 'Erro durante a aplicação atômica do backup no banco de dados.',
        ),
      );
    }
  }

  IResult<Map<String, dynamic>, ValidationError> _decryptContainer(
    Uint8List encryptedData,
    String password,
  ) {
    if (encryptedData.length < _saltLength + _ivLength + 16) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.corruptedData,
          message: 'Arquivo de backup corrompido ou incompleto.',
        ),
      );
    }

    try {
      final salt = encryptedData.sublist(0, _saltLength);
      final ivBytes = encryptedData.sublist(_saltLength, _saltLength + _ivLength);
      final cipherBytes = encryptedData.sublist(_saltLength + _ivLength);

      final derivedKeyBytes = _deriveKey(password, salt);
      final key = enc.Key(derivedKeyBytes);
      final iv = enc.IV(ivBytes);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted(cipherBytes),
        iv: iv,
      );

      final decryptedJson = utf8.decode(decryptedBytes);
      final map = jsonDecode(decryptedJson) as Map<String, dynamic>;
      return Success(map);
    } catch (_) {
      // Se falhar a decifração AES-GCM (tag mismatch), a senha está incorreta ou os dados foram alterados
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.invalidPassword,
          message: 'Senha incorreta para decifrar o backup ou arquivo corrompido.',
        ),
      );
    }
  }

  Uint8List _deriveKey(String password, Uint8List salt) {
    // PBKDF2-HMAC-SHA256
    final hmac = Hmac(sha256, utf8.encode(password));
    final result = Uint8List(_keyLength);
    final blocksNeeded = (_keyLength / 32).ceil();

    var offset = 0;
    for (var blockIndex = 1; blockIndex <= blocksNeeded; blockIndex++) {
      final blockBytes = Uint8List(salt.length + 4);
      blockBytes.setRange(0, salt.length, salt);
      final bdata = ByteData.view(blockBytes.buffer);
      bdata.setUint32(salt.length, blockIndex, Endian.big);

      var u = Uint8List.fromList(hmac.convert(blockBytes).bytes);
      final t = Uint8List.fromList(u);

      for (var iter = 1; iter < _pbkdf2Iterations; iter++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var i = 0; i < t.length; i++) {
          t[i] ^= u[i];
        }
      }

      final copyLength = min(t.length, _keyLength - offset);
      result.setRange(offset, offset + copyLength, t.sublist(0, copyLength));
      offset += copyLength;
    }

    return result;
  }
}
