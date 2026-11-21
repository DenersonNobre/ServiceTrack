# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-03.04` (Pausa e Cancelamento com Justificativa)
- **Status**: EM ANDAMENTO (Gate 3/4 pendentes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-03`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: Cancelamento de OS com justificativa obrigatória (domínio, SQLite v5, controller, UI com diálogo de justificativa). "Pausa" sem status/contrato na SPEC — fora do escopo implementado; registrado como limitação.
- **Gate 2.5 (Segurança)**: Gate 2.5: PULADO — transição local de estado com justificativa em SQLite, sem nova dependência/superfície sensível.
- **Gates 3/4**: pendentes.

## [EVIDENCIA]
- Leitura: `docs/plan/epics/epic-03-ordens-servico.md` UC-03.04, `docs/architecture/SPEC.md` INV-01 e `cancel(reason)`.
- Verifica: `flutter analyze --fatal-infos` -> No issues found. `flutter test` -> 106/106 All tests passed.
- Confirma: RED `work_order_cancel_test.dart` falhou por ausência de `cancel`; após implementação verde (16/16 em `test/modules/work_orders`).

## Arquivos do slice
- `lib/modules/work_orders/domain/value_objects/work_order.dart`
- `lib/modules/work_orders/data/work_order_migration.dart`
- `lib/modules/work_orders/data/work_order_sqlite_repository.dart`
- `lib/modules/work_orders/ui/list/work_order_list_controller.dart`
- `lib/modules/work_orders/ui/list/work_order_list_page.dart`
- `lib/app/database/app_database.dart`
- `test/modules/work_orders/domain/work_order_cancel_test.dart`
- `test/modules/work_orders/data/work_order_sqlite_repository_test.dart`
- `docs/plan/state/uc-current.md`

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-03.04.
