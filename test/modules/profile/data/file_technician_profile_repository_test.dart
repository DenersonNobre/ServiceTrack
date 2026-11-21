import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:service_track/modules/profile/data/file_technician_profile_repository.dart';
import 'package:service_track/modules/profile/domain/value_objects/technician_profile.dart';

void main() {
  group('FileTechnicianProfileRepository', () {
    late Directory dir;
    late FileTechnicianProfileRepository repo;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_profile_');
      repo = FileTechnicianProfileRepository(baseDir: () async => dir);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('load retorna null quando vazio', () async {
      final r = await repo.load();
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull(), isNull);
    });

    test('save/load roundtrip preserva dados e não usa secure storage', () async {
      final profile = TechnicianProfile.tryCreate(
        commercialName: 'Rodrigo Serviços',
        whatsapp: '11999998888',
        logoPath: null,
      ).getOrNull()!;
      final saved = await repo.save(profile);
      expect(saved.isSuccess, isTrue);

      final loaded = await repo.load();
      expect(loaded.getOrNull()?.commercialName.value, 'Rodrigo Serviços');
      expect(loaded.getOrNull()?.whatsapp.digits, '11999998888');
    });

    test('importLogo rejeita bytes vazios/inválidos (INV-SEC-16)', () async {
      final r = await repo.importLogo(Uint8List.fromList([1, 2, 3]));
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_PERFIL_IMAGEM_INVALIDA');
    });

    test('importLogo normaliza e persiste imagem (INV-SEC-15)', () async {
      final image = img.Image(width: 2000, height: 1000);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      final bytes = Uint8List.fromList(img.encodePng(image));

      final r = await repo.importLogo(bytes);
      expect(r.isSuccess, isTrue);
      final path = r.getOrNull()!;
      final file = File(path);
      expect(await file.exists(), isTrue);
      final saved = img.decodeImage(await file.readAsBytes())!;
      expect(saved.width, lessThanOrEqualTo(1024));
      expect(saved.height, lessThanOrEqualTo(1024));
    });

    test('clearLogo remove arquivo', () async {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(0, 255, 0));
      final imported = await repo.importLogo(Uint8List.fromList(img.encodePng(image)));
      final path = imported.getOrNull()!;
      expect(await File(path).exists(), isTrue);

      final cleared = await repo.clearLogo();
      expect(cleared.isSuccess, isTrue);
      expect(await File(path).exists(), isFalse);
    });
  });
}
