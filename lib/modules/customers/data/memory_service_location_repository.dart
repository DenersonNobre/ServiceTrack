// Repositório em memória de locais de atendimento (testes/fallback).

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../domain/ports/service_location_repository_port.dart';
import '../domain/value_objects/service_location.dart';

final class MemoryServiceLocationRepository implements IServiceLocationRepositoryPort {
  final Map<String, ServiceLocation> _store = {};

  @override
  Future<IResult<ServiceLocation, ValidationError>> save(ServiceLocation location) async {
    _store[location.id] = location;
    return Success(location);
  }

  @override
  Future<IResult<List<ServiceLocation>, ValidationError>> findByCustomerId(String customerId) async {
    final list = _store.values.where((l) => l.customerId == customerId).toList()
      ..sort((a, b) => a.label.value.toLowerCase().compareTo(b.label.value.toLowerCase()));
    return Success(list);
  }

  @override
  Future<IResult<bool, ValidationError>> delete(String id) async {
    _store.remove(id);
    return const Success(true);
  }
}
