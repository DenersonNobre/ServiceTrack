// Value Objects e entidade de Local de Atendimento (UC-02.02).
//
// SRP: validar e normalizar dados de endereço/local. Não persiste, não formata UI.
//
// Pattern: Value Objects + Entity com Result.Fail tipado.

import 'package:dnolib/brlib/brlib.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../ports/customer_failure_codes.dart';

/// Rótulo do local (ex.: Casa, Escritório).
final class LocationLabel {
  const LocationLabel._(this.value);
  final String value;

  static IResult<LocationLabel, ValidationError> tryCreate(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.invalidLocationLabel, message: 'Informe um rótulo para o local.'),
      );
    }
    if (normalized.length > 60) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.invalidLocationLabel, message: 'Rótulo do local muito longo.'),
      );
    }
    return Success(LocationLabel._(normalized));
  }

  @override
  String toString() => 'LocationLabel(redacted)';
}

/// CEP brasileiro opcional.
final class BrazilianCep {
  const BrazilianCep._(this.digits);
  final String digits;

  static IResult<BrazilianCep?, ValidationError> tryCreate(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const Success(null);
    if (!CepValidator.isValid(digits)) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.invalidCep, message: 'CEP inválido.'),
      );
    }
    return Success(BrazilianCep._(digits));
  }

  @override
  String toString() => 'BrazilianCep(redacted)';
}

/// Entidade Local de Atendimento.
final class ServiceLocation {
  const ServiceLocation._({
    required this.id,
    required this.customerId,
    required this.label,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.cep,
    required this.reference,
  });

  final String id;
  final String customerId;
  final LocationLabel label;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final BrazilianCep? cep;
  final String reference;

  static IResult<ServiceLocation, ValidationError> tryCreate({
    required String id,
    required String customerId,
    required String label,
    required String street,
    required String number,
    required String neighborhood,
    required String city,
    required String state,
    required String cep,
    required String reference,
  }) {
    if (id.trim().isEmpty || customerId.trim().isEmpty) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.invalidLocationId, message: 'Identificador inválido.'),
      );
    }
    final labelR = LocationLabel.tryCreate(label);
    if (labelR.isFailure) return Failure(labelR.getOrNullFailure()!);
    final cepR = BrazilianCep.tryCreate(cep);
    if (cepR.isFailure) return Failure(cepR.getOrNullFailure()!);

    final streetN = street.trim();
    final cityN = city.trim();
    if (streetN.isEmpty || cityN.isEmpty) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.invalidAddress, message: 'Informe logradouro e cidade.'),
      );
    }

    return Success(ServiceLocation._(
      id: id.trim(),
      customerId: customerId.trim(),
      label: labelR.getOrNull()!,
      street: streetN,
      number: number.trim(),
      neighborhood: neighborhood.trim(),
      city: cityN,
      state: state.trim().toUpperCase(),
      cep: cepR.getOrNull(),
      reference: reference.trim(),
    ));
  }

  @override
  String toString() => 'ServiceLocation(redacted)';
}
