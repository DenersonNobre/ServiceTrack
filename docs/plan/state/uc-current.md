# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-03.03` (Check-in de Atendimento & Georreferenciamento)
- **Status**: EM ANDAMENTO (Gate 3/4 pendentes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-03`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: GeoPoint VO (validação INV-SEC-20, redaction INV-SEC-18), startService com LocationCapture tipada (INV-SEC-17), transição SCHEDULED->IN_PROGRESS (INV-01), ILocationServicePort + adapter geolocator foreground com timeout/permissão/erros tipados (INV-SEC-19/21), SQLite v4 check-in, UI iniciar atendimento com bypass auditável explícito.
- **Gate 2.5 (Segurança)**: Gate 2.5: INVOKED — APROVADO COM CONDICIONANTES (Média, `ses_dfff9c294ffeKsUX0t27vzhOvX`); INV-SEC-17 bypass tipado/auditável; INV-SEC-18 redação/minimização GeoPoint; INV-SEC-19 fail-closed timeout/permissão/erro tipado; INV-SEC-20 validação estrita GeoPoint; INV-SEC-21 foreground only. A6/D-02 advisory.
- **Gates 3/4**: pendentes.

## [EVIDENCIA]
- Leitura: `docs/plan/epics/epic-03-ordens-servico.md` UC-03.03, `docs/architecture/SPEC.md` INV-01/INV-02/RN-02, Gate 2.5.
- Verifica: `flutter test` -> 102/102 All tests passed; `flutter analyze --fatal-infos` -> No issues found.
- Confirma: RED domain/data tests falharam por símbolos ausentes; após implementação verde.

## Arquivos do slice
- `lib/modules/work_orders/domain/**` (geo_point, check_in_*, location_capture, work_order startService)
- `lib/modules/work_orders/data/**` (migration v4, repo check-in, geolocator service)
- `lib/modules/work_orders/ui/list/**` (controller startService, page iniciar/bypass)
- `lib/app/database/app_database.dart`, `lib/main.dart`
- `test/modules/work_orders/**`
- `docs/plan/state/uc-current.md`

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-03.03.
