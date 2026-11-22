# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-07.01` — Fundação do Módulo de Configurações Locais
- **Status**: CONCLUÍDO (código+testes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-07`
- **Gate 2.5 (Segurança)**: PULADO — sem superfície sensível nova, sem PII e sem nova dependência; persistência local SQLite padrão do projeto.
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Concluído**: `SettingKey` (catálogo tipado), `SettingsSnapshot` (defaults seguros), `ISettingsRepositoryPort`, `SettingsSqliteRepository`, `MemorySettingsRepository`, `GetSettings`, `UpdateSetting` e `SettingsMigration.v11`; `app_database` em `dbVersion: 11`.
- **Defaults**: `require_checklist_template=true`; `require_receiver_document=false` (minimização D2).
- **Barrels**: `settings/.index.dart` → `data/`, `domain/`, `features/`; `domain/.index.dart` → entities/ports/value_objects. Sem imports profundos entre camadas.
- **Decisão**: [ADR-003](../../architecture/adr-003-settings-locais-tipadas.md).
- **Testes do módulo**: 10 verdes (snapshot, SQLite, use cases). Suíte completa: **190 verdes**.

## [EVIDENCIA]
- Leitura: `lib/modules/settings/domain/value_objects/setting_key.dart`, `lib/modules/settings/domain/entities/settings_snapshot.dart`, `lib/modules/settings/data/settings_sqlite_repository.dart`, `lib/modules/settings/features/update_setting.dart`, `lib/app/database/app_database.dart` → catálogo/defaults/porta/migration v11.
- Verifica: `flutter analyze --fatal-infos` → `No issues found!`; `flutter test test/modules/settings` → `+10 All tests passed!`.
- Confirma: `flutter test` → `+190 All tests passed!`; `SettingsMigration.v11` registrada em `createAppDatabase` (`dbVersion: 11`).

## Próximo passo
1. **UC-07.02**: UI de Configurações (Kortex, >=48dp, leitura/edição por use case).
2. **Gate 2.5** antes de UC-07.03 (D2/PII; manter C-01/D-01 fail-closed).
3. **UC-07.03**: integrar `require_checklist_template`/`require_receiver_document` nos consumidores.
