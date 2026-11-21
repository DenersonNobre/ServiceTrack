// Porta do repositório de credenciais locais (UC-01.01, TASK-02).
//
// SRP: contrato de cadastro, verificação e limpeza das credenciais.
// NÃO implementa hash, KDF ou I/O de plataforma.
// Pattern: Port do Hexagonal; falhas esperadas via Result.
//
// Dependências: dnolib (core/patterns), value_objects desta fatia.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../value_objects/auth_credentials.dart';

/// Contrato de persistência e verificação das credenciais do técnico.
abstract class IAuthCredentialRepositoryPort {
  /// Cadastra senha mestre e PIN no cofre; devolve o identificador gerado.
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  });

  /// Verifica a tentativa de PIN; aplica rate-limit com bloqueio temporário.
  Future<IResult<bool, ValidationError>> verifyPin(String attempt);

  /// Verifica a tentativa de senha mestre (recuperação de acesso).
  Future<IResult<bool, ValidationError>> verifyPassword(String attempt);

  /// Apaga as credenciais conhecidas do cofre.
  Future<IResult<bool, ValidationError>> clearAll();
}
