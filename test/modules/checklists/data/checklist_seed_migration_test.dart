// Testes do seed de modelos de checklist embutidos (UC-04.09 / UC-04.01).
//
// SRP: provar que uma instalação limpa nasce com os modelos do épico
// (Instalação, Manutenção, Vistoria), cada um com itens válidos — sem isso o
// dropdown de template da OS fica vazio e o fluxo checklist é inalcançável.

import 'dart:io';

import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/app/database/app_database.dart';
import 'package:service_track/modules/checklists/.index.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UC-04.09 - seed de modelos embutidos', () {
    late SqliteProvider provider;
    late ChecklistTemplateSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_checklist_seed_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = createAppDatabase(dbName: 'seed_test.db');
      repo = ChecklistTemplateSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('instalação limpa expõe os 3 modelos do épico com itens', () async {
      final result = await repo.findAll();

      expect(result.isSuccess, isTrue, reason: '$result');
      final templates = result.getOrNull()!;
      expect(
        templates,
        hasLength(3),
        reason: '${templates.map((t) => t.title)}',
      );

      final titles = templates.map((t) => t.title).toList();
      expect(
        titles,
        containsAll(<String>[
          'Instalação Split',
          'Manutenção Preventiva',
          'Vistoria Rápida',
        ]),
      );

      for (final template in templates) {
        expect(
          template.items,
          isNotEmpty,
          reason: 'template "${template.title}" sem itens quebra o checklist',
        );
      }
    });

    test('seed não duplica modelos em reabertura do banco', () async {
      final first = (await repo.findAll()).getOrNull()!;
      expect(first, hasLength(3));

      await provider.close();
      final reopened = createAppDatabase(dbName: 'seed_test.db');
      final repoReopened = ChecklistTemplateSqliteRepository(
        provider: reopened,
      );
      final second = (await repoReopened.findAll()).getOrNull()!;

      expect(second, hasLength(3), reason: 'migration não pode re-semear');
      await reopened.close();
    });
  });
}
