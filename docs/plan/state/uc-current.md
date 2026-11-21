# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-03.01` (Criação Rápida de Ordem de Serviço)
- **Status**: EM ANDAMENTO (Gate 3/4 pendentes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-03`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: Agregado `WorkOrder` com `WorkOrderStatus` (SCHEDULED), valor estimado `Money` BRL, port repo, SQLite migration v3 + repo, UI list/form Kortex, wiring no app/home. Criação rápida com cliente, descrição, data/hora e valor estimado.
- **Gate 2.5 (Segurança)**: PULADO — CRUD local SQLite, sem nova dependência/superfície sensível; sem auth/upload/webhook/shell/PII extra além do padrão local.
- **Gates 3/4**: pendentes.

## [EVIDENCIA]
- Leitura: `docs/plan/epics/epic-03-ordens-servico.md` UC-03.01, `docs/architecture/SPEC.md` (WorkOrder, INV-01/INV-06 contexto), `docs/architecture/DESIGN.md`.
- Verifica: `flutter test` -> 92/92 All tests passed; `flutter analyze --fatal-infos` -> No issues found.
- Confirma: RED `work_order_test.dart` falhou por símbolos ausentes; após implementação domínio/data/UI verdes.

## Arquivos do slice
- `lib/app/database/app_database.dart`, `lib/main.dart`
- `lib/modules/work_orders/**`
- `test/modules/work_orders/**`
- `docs/plan/state/uc-current.md`

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação e release claim UC-03.01.