// Repositório de perfil comercial em arquivo local (UC-01.05, INV-SEC-14/15/16).
//
// SRP: persistir perfil comercial e logo normalizado em diretório privado do app.
// Não contém regras de UI, não usa secure storage.
//
// Pattern: Adapter (Port impl) + Result.Fail tipado.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../domain/ports/technician_profile_repository_port.dart';
import '../domain/value_objects/technician_profile.dart';

/// Repositório de perfil em arquivo JSON + logo normalizado.
final class FileTechnicianProfileRepository
    implements ITechnicianProfileRepositoryPort {
  /// Cria repositório com diretório base injetável para testes.
  FileTechnicianProfileRepository({required this._baseDir});

  final Future<Directory> Function() _baseDir;

  static const _profileFile = 'technician_profile.json';
  static const _logoFile = 'technician_logo.jpg';
  static const _maxInputBytes = 5 * 1024 * 1024;
  static const _maxOutputBytes = 512 * 1024;
  static const _maxDimension = 1024;

  Future<File> _profilePath() async {
    final dir = await _baseDir();
    return File(p.join(dir.path, _profileFile));
  }

  Future<Directory> _profileDir() async {
    final dir = await _baseDir();
    final profileDir = Directory(p.join(dir.path, 'profile'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    return profileDir;
  }

  @override
  Future<IResult<TechnicianProfile?, ValidationError>> load() async {
    try {
      final file = await _profilePath();
      if (!await file.exists()) return const Success(null);
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final name = raw['commercialName'] as String? ?? '';
      final whatsapp = raw['whatsapp'] as String? ?? '';
      final logoPath = raw['logoPath'] as String?;
      final result = TechnicianProfile.tryCreate(
        commercialName: name,
        whatsapp: whatsapp,
        logoPath: (logoPath != null && logoPath.isNotEmpty) ? logoPath : null,
      );
      return switch (result) {
        Success<TechnicianProfile, ValidationError>(:final value) => Success(value),
        Failure<TechnicianProfile, ValidationError>() => const Success(null),
      };
    } catch (_) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_LEITURA',
          message: 'Não foi possível carregar o perfil.',
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> save(TechnicianProfile profile) async {
    try {
      final file = await _profilePath();
      final data = <String, dynamic>{
        'commercialName': profile.commercialName.value,
        'whatsapp': profile.whatsapp.digits,
        'logoPath': profile.logoPath,
      };
      await file.writeAsString(jsonEncode(data), flush: true);
      return const Success(true);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_ESCRITA',
          message: 'Não foi possível salvar o perfil.',
        ),
      );
    }
  }

  @override
  Future<IResult<String, ValidationError>> importLogo(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > _maxInputBytes) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_IMAGEM_INVALIDA',
          message: 'Imagem inválida ou muito grande.',
        ),
      );
    }
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const Failure(
          ValidationError(
            code: 'ERR_PERFIL_IMAGEM_INVALIDA',
            message: 'Formato de imagem não suportado.',
          ),
        );
      }
      if (decoded.width <= 0 || decoded.height <= 0) {
        return const Failure(
          ValidationError(
            code: 'ERR_PERFIL_IMAGEM_INVALIDA',
            message: 'Imagem inválida.',
          ),
        );
      }
      var normalized = decoded;
      if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
        normalized = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? _maxDimension : null,
          height: decoded.height > decoded.width ? _maxDimension : null,
          interpolation: img.Interpolation.average,
        );
      }
      // Re-encode strips EXIF/metadata (INV-SEC-15).
      var quality = 85;
      List<int> encoded = img.encodeJpg(normalized, quality: quality);
      while (encoded.length > _maxOutputBytes && quality > 40) {
        quality -= 10;
        encoded = img.encodeJpg(normalized, quality: quality);
      }
      if (encoded.length > _maxOutputBytes) {
        return const Failure(
          ValidationError(
            code: 'ERR_PERFIL_IMAGEM_INVALIDA',
            message: 'Imagem muito grande após normalização.',
          ),
        );
      }
      final dir = await _profileDir();
      final target = File(p.join(dir.path, _logoFile));
      await target.writeAsBytes(encoded, flush: true);
      return Success(target.path);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_IMAGEM_INVALIDA',
          message: 'Não foi possível processar a imagem.',
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> clearLogo() async {
    try {
      final dir = await _profileDir();
      final target = File(p.join(dir.path, _logoFile));
      if (await target.exists()) {
        await target.delete();
      }
      return const Success(true);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_ESCRITA',
          message: 'Não foi possível remover o logo.',
        ),
      );
    }
  }
}
