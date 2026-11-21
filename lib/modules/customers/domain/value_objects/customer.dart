// Value Objects e entidade de Cliente (UC-02.01).
//
// SRP: validar e normalizar dados de cliente. Não persiste, não formata UI.
//
// Pattern: Value Objects + Entity com Result.Fail tipado.

import 'package:dnolib/brlib/brlib.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

/// Nome do cliente.
final class CustomerName {
  const CustomerName._(this.value);
  final String value;

  static IResult<CustomerName, ValidationError> tryCreate(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const Failure(
        ValidationError(code: 'ERR_CLIENTE_NOME_INVALIDO', message: 'Informe o nome do cliente.'),
      );
    }
    if (normalized.length > 120) {
      return const Failure(
        ValidationError(code: 'ERR_CLIENTE_NOME_INVALIDO', message: 'Nome do cliente muito longo.'),
      );
    }
    return Success(CustomerName._(normalized));
  }

  @override
  String toString() => 'CustomerName(redacted)';
}

/// Documento brasileiro CPF/CNPJ.
final class BrazilianDocument {
  const BrazilianDocument._(this.digits, this.isCpf);
  final String digits;
  final bool isCpf;

  static IResult<BrazilianDocument, ValidationError> tryCreate(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (CpfValidator.isValid(digits)) return Success(BrazilianDocument._(digits, true));
    if (CnpjValidator.isValid(digits)) return Success(BrazilianDocument._(digits, false));
    return const Failure(
      ValidationError(code: 'ERR_CLIENTE_DOCUMENTO_INVALIDO', message: 'CPF ou CNPJ inválido.'),
    );
  }

  @override
  String toString() => 'BrazilianDocument(redacted)';
}

/// WhatsApp/telefone do cliente.
final class CustomerPhone {
  const CustomerPhone._(this.digits);
  final String digits;

  static IResult<CustomerPhone, ValidationError> tryCreate(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!PhoneBrValidator.hasValidShape(digits)) {
      return const Failure(
        ValidationError(code: 'ERR_CLIENTE_WHATSAPP_INVALIDO', message: 'Informe um WhatsApp válido com DDD.'),
      );
    }
    return Success(CustomerPhone._(digits));
  }

  @override
  String toString() => 'CustomerPhone(redacted)';
}

/// Email opcional do cliente.
final class CustomerEmail {
  const CustomerEmail._(this.value);
  final String value;

  static IResult<CustomerEmail?, ValidationError> tryCreate(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return const Success(null);
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
    if (!ok) {
      return const Failure(
        ValidationError(code: 'ERR_CLIENTE_EMAIL_INVALIDO', message: 'E-mail inválido.'),
      );
    }
    return Success(CustomerEmail._(normalized));
  }

  @override
  String toString() => 'CustomerEmail(redacted)';
}

/// Entidade Cliente.
final class Customer {
  const Customer._({
    required this.id,
    required this.name,
    required this.document,
    required this.whatsapp,
    required this.email,
    required this.notes,
  });

  final String id;
  final CustomerName name;
  final BrazilianDocument? document;
  final CustomerPhone whatsapp;
  final CustomerEmail? email;
  final String notes;

  static IResult<Customer, ValidationError> tryCreate({
    required String id,
    required String name,
    required String document,
    required String whatsapp,
    required String email,
    required String notes,
  }) {
    if (id.trim().isEmpty) {
      return const Failure(ValidationError(code: 'ERR_CLIENTE_ID_INVALIDO', message: 'Identificador inválido.'));
    }
    final nameR = CustomerName.tryCreate(name);
    if (nameR.isFailure) return Failure(nameR.getOrNullFailure()!);
    BrazilianDocument? doc;
    if (document.trim().isNotEmpty) {
      final docR = BrazilianDocument.tryCreate(document);
      if (docR.isFailure) return Failure(docR.getOrNullFailure()!);
      doc = docR.getOrNull();
    }
    final phoneR = CustomerPhone.tryCreate(whatsapp);
    if (phoneR.isFailure) return Failure(phoneR.getOrNullFailure()!);
    final emailR = CustomerEmail.tryCreate(email);
    if (emailR.isFailure) return Failure(emailR.getOrNullFailure()!);

    return Success(Customer._(
      id: id.trim(),
      name: nameR.getOrNull()!,
      document: doc,
      whatsapp: phoneR.getOrNull()!,
      email: emailR.getOrNull(),
      notes: notes.trim(),
    ));
  }

  @override
  String toString() => 'Customer(redacted)';
}
