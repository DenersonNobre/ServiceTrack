import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';

void main() {
  group('GeoPoint', () {
    test('cria ponto válido e normaliza para UTC', () {
      final r = GeoPoint.tryCreate(
        latitude: -23.55052,
        longitude: -46.633308,
        timestampUtc: DateTime(2026, 11, 21, 10).toLocal(),
      );
      expect(r.isSuccess, isTrue);
      final p = r.getOrNull()!;
      expect(p.latitude, -23.55052);
      expect(p.timestampUtc.isUtc, isTrue);
    });

    test('rejeita coordenadas fora da faixa', () {
      expect(GeoPoint.tryCreate(latitude: -91, longitude: 0, timestampUtc: DateTime.utc(2026)).isFailure, isTrue);
      expect(GeoPoint.tryCreate(latitude: 0, longitude: 181, timestampUtc: DateTime.utc(2026)).isFailure, isTrue);
    });

    test('rejeita NaN/Infinity', () {
      expect(GeoPoint.tryCreate(latitude: double.nan, longitude: 0, timestampUtc: DateTime.utc(2026)).isFailure, isTrue);
      expect(GeoPoint.tryCreate(latitude: 0, longitude: double.infinity, timestampUtc: DateTime.utc(2026)).isFailure, isTrue);
    });

    test('toString não expõe coordenadas (INV-SEC-18)', () {
      final p = GeoPoint.tryCreate(latitude: -23.55, longitude: -46.63, timestampUtc: DateTime.utc(2026)).getOrNull()!;
      expect(p.toString(), isNot(contains('-23.55')));
      expect(p.toString(), isNot(contains('-46.63')));
    });
  });
}
