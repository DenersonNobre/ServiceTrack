// Repositório em memória de perfil comercial (testes/fallback).
//
// SRP: implementação simples do contrato de perfil para testes.
// Não normaliza imagem, não acessa disco.

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../domain/ports/profile_failure_codes.dart';
import '../domain/ports/technician_profile_repository_port.dart';
import '../domain/value_objects/technician_profile.dart';

/// Repositório em memória.
final class MemoryTechnicianProfileRepository
    implements ITechnicianProfileRepositoryPort {
  TechnicianProfile? _profile;

  @override
  Future<IResult<TechnicianProfile?, ValidationError>> load() async =>
      Success(_profile);

  @override
  Future<IResult<bool, ValidationError>> save(TechnicianProfile profile) async {
    _profile = profile;
    return const Success(true);
  }

  @override
  Future<IResult<String, ValidationError>> importLogo(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return const Failure(
        ValidationError(
          code: ProfileFailureCodes.invalidImage,
          message: 'Imagem inválida.',
        ),
      );
    }
    return const Success('memory://logo.jpg');
  }

  @override
  Future<IResult<bool, ValidationError>> clearLogo() async =>
      const Success(true);
}
