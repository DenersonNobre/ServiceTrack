// Porta do repositório de perfil comercial (UC-01.05, INV-SEC-14).
//
// SRP: contrato de persistência do perfil comercial (PII fora do cofre).
// Não conhece JSON/arquivo/UI.
//
// Pattern: Port (DIP) + Result.Fail tipado.

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../value_objects/technician_profile.dart';

/// Contrato de persistência do perfil comercial.
abstract interface class ITechnicianProfileRepositoryPort {
  /// Carrega o perfil salvo, ou null se inexistente.
  Future<IResult<TechnicianProfile?, ValidationError>> load();

  /// Salva o perfil comercial.
  Future<IResult<bool, ValidationError>> save(TechnicianProfile profile);

  /// Importa e normaliza logo/foto, retornando caminho gerenciado (INV-SEC-15/16).
  Future<IResult<String, ValidationError>> importLogo(Uint8List bytes);

  /// Remove logo gerenciado atual, se houver.
  Future<IResult<bool, ValidationError>> clearLogo();
}
