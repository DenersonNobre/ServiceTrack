# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-07.02` — UI de Configurações Locais
- **Status**: CONCLUÍDO (código+testes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-07`
- **Gate 2.5 (Segurança)**: PULADO — UI consome use cases; não coleta PII nova e apenas edita políticas já definidas (D2).
- **Última Atualização**: `2026-11-22`

## Contexto Atual
- **Concluído**: `SettingsController` (Kortex), `SettingsPage` (`SwitchListTile` >=48dp, `KortexListener` + `AppFeedback`), `SettingsRoutes` e entrada `home-settings` na Home.
- **Wiring**: `AppDependencies`/`ServiceTrackApp` recebem `ISettingsRepositoryPort`; `main.dart` injeta `SettingsSqliteRepository`; fallback de testes usa `MemorySettingsRepository`.
- **Defaults visíveis**: checklist exigido = `true`; documento do recebedor = `false` (minimização D2).
- **Testes**: 4 testes de UI/controller; suíte completa **194 verdes**; análise limpa.
- **Decisão**: [ADR-003](../../architecture/adr-003-settings-locais-tipadas.md).

## [EVIDENCIA]
- Leitura: `lib/modules/settings/ui/settings_controller.dart`, `lib/modules/settings/ui/settings_page.dart`, `lib/modules/settings/ui/settings_routes.dart`, `lib/app/home_page.dart`, `lib/app/app_dependencies.dart`, `lib/app/service_track_app.dart`, `lib/main.dart` → UI, feedback, rota e injeção.
- Verifica: `flutter test test/modules/settings/ui` → `+4 All tests passed!`; `flutter analyze --fatal-infos` → `No issues found!`.
- Confirma: `flutter test` → `+194 All tests passed!`; `SwitchListTile` com altura >=48dp e persistência via `UpdateSetting`.

## Próximo passo
1. **Gate 2.5** para `UC-07.03` (D2/PII; C-01/D-01 fail-closed).
2. **UC-07.03**: integrar `require_checklist_template`/`require_receiver_document` nos consumidores (`AppEntry`, `ServiceTrackApp`, `WorkOrderListController/Page`).
3. **EPIC-06 residual**: UC-06.01/02 residuais.
4. **E2E device EPIC-04**: validação pendente.
