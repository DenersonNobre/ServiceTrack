# QA Review — v0.15.0

> **Data**: 2026-11-21  
> **Commit auditado**: `4eaf47a` — `fix(work-orders): address gate findings for UC-03.04 cancel dialog and coverage` (sobre `7e48d22` feat UC-03.04)  
> **Escopo**: UC-03.04 — Pausa e Cancelamento com Justificativa (**entrega parcial: cancelamento**)  
> **Gate 2.5**: PULADO — transição local de estado com justificativa em SQLite, sem nova dependência/superfície sensível.  
> **Gate 3 (final)**: APROVADO — confiança Alta (`ses_dff8c8204ffeOQEveh82FaK3T1`); evidência RED sanada.  
> **Gate 4 (re-review)**: APROVADO COM RESSALVAS — confiança Alta (`ses_dff92e61affeaWZgVuM3UKcJUz`)

## Evidência empírica

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 41.9s)` (exit 0) |
| `flutter test` (suíte completa, Gate 4 re-review) | FALHOU por flakiness fora do slice | `01:59 +106 -1: Some tests failed.` (exit 1). Única falha: `test/modules/auth/data/credential_recovery_test.dart` `UC-01.04 - recuperação de credenciais resetPin limpa lockout do PIN (A5)` — `TimeoutException after 0:00:30.000000`. Fora do slice UC-03.04. |
| `flutter test test/modules/auth/data/credential_recovery_test.dart` (rerun isolado) | PASSOU | `01:02 +4: All tests passed!` (exit 0) — confirma flakiness preexistente/ambiental fora do slice. |
| `flutter test test/modules/work_orders` | PASSOU | 17/17 pass (inclui cancelamento + INV-06). |

## Rastreabilidade UC-03.04

| Critério / Invariante | Evidência | Status |
|---|---|---|
| Cancelamento com justificativa obrigatória | `WorkOrder.cancel` trim+empty => `ERR_OS_JUSTIFICATIVA_OBRIGATORIA` (`work_order.dart`); teste domínio; UI valida campo. | Conforme |
| Cancelamento de OS agendada/iniciada | `work_order_cancel_test.dart`; `work_order_list_controller.dart`. | Conforme |
| INV-06 / transição inválida completed/cancelled -> cancel | `work_order.dart` rejeita `completed/cancelled` com `ERR_OS_TRANSICAO_INVALIDA`; testes domínio cobrem cancelada e concluída. | Conforme |
| Persistência cancelamento/justificativa | Migração v5 `cancellation_reason`; repo save/map; teste repo UC-03.04. | Conforme |
| 48dp diálogo cancelamento | `work_order_list_page.dart` botões com `minimumSize: Size(48,48)`. | Conforme |
| "Pausa" (título UC-03.04) | Sem contrato/status na SPEC; não implementado. Documentado como lacuna. | Parcial / pendente SPEC |

## Observações

- **M1 (Maior, fora do slice)**: Flakiness intermitente `credential_recovery_test.dart` UC-01.04 na suíte completa; rerun isolado verde. Não bloqueia UC-03.04. Registrar/estabilizar antes de release gate.
- **M2 (Escopo)**: UC-03.04 consolidada como **PARCIAL**: cancelamento entregue e validado; pausa depende de definição contratual na SPEC/épico.
- **A1 (Advisory)**: Cobertura de controller/widget para cancelamento pode ser reforçada.

## Parecer

**APROVADO COM RESSALVAS — confiança Alta** para consolidação da UC-03.04 como **PARCIAL** no HEAD `4eaf47a`. Cancelamento com justificativa obrigatória, INV-06 e persistência validados empiricamente. M1 é flakiness fora do slice (rerun isolado verde). "Pausa" permanece pendente por ausência de contrato em SPEC — não bloquear por invenção de domínio; registrar como dívida/definição necessária.
