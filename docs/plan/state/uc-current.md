# UC-CURRENT — Handoff de Estado

## Metadados
- **Fatia (Slice)**: `UC-03.04` (Pausa e Cancelamento com Justificativa)
- **Status**: EM ANDAMENTO (Gate 3/4 pendentes)
- **Dono**: `opc01@e03ff640`
- **Épico**: `EPIC-03`
- **Última Atualização**: `2026-11-21`

## Contexto Atual
- **O que foi feito**: Complemento da UC-03.04 com pausa/retomada. Contrato confirmado pelo PO: pausa só registra motivo (sem GPS na retomada). Adicionado `PAUSED` em `WorkOrderStatus`, `pause(reason)`, `resume()`, migração SQLite v7 `pause_reason`, repo/controller/UI (filtro Pausadas, ações Pausar/Retomar). Cancelamento de PAUSED permitido.
- **Gate 2.5 (Segurança)**: Gate 2.5: PULADO — transição local de estado com justificativa em SQLite, sem nova dependência/superfície sensível; retomada sem GPS por decisão do PO.
- **Gates 3/4**: pendentes.

## [EVIDENCIA]
- Leitura: `docs/plan/epics/epic-03-ordens-servico.md` UC-03.04, `docs/architecture/SPEC.md` INV-01/WorkOrderStatus/pause/resume.
- Verifica: `flutter analyze --fatal-infos` -> No issues found (exit 0). `flutter test test/modules/work_orders` -> 32/32 pass. `flutter test` completo -> 02:50 +128 -3 (3 falhas fora do slice: 2x `credential_recovery_test.dart` UC-01.04 flakiness conhecida, 1x `checklist_template_sqlite_repository_test.dart` UC-04.01 que passou isolado `00:01 +1 All tests passed!`).
- Confirma: RED `work_order_pause_test.dart` falhou por ausência de `pause/resume/paused` (exit 1); após implementação verde.

## Próximo passo
1. Gate 3 (review).
2. Gate 4 (QA) + laudo.
3. Consolidação UC-03.04 completa e release claim.