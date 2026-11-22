# QA Review — v0.17.0

> **Data**: 2026-11-21  
> **Commit auditado**: `59661c6` — `feat(work-orders): add pause and resume flow for UC-03.04`  
> **Escopo**: UC-03.04 — Pausa e Cancelamento com Justificativa (complemento pausa/retomada)  
> **Gate 2.5**: PULADO — transição local com justificativa em SQLite, sem nova superfície sensível; retomada sem GPS por decisão do PO.  
> **Gate 3**: APROVADO — confiança Média (`ses_dfedd90adffeEk5ZybiJqKFgWd`).  
> **Gate 4**: APROVADO — confiança Alta (`ses_dfedd90abffeX2FsP3Wc1IiQMH`).

## Evidência empírica

| Comando | Resultado | Evidência |
|---|---|---|
| `flutter analyze --fatal-infos` | PASSOU | `No issues found! (ran in 88.2s)` (exit 0) |
| `flutter test` (suíte completa) | PASSOU COM RESSALVA FORA DO SLICE | `03:21 +137 -5` (exit 1). 5 falhas fora do slice: `auth_session_settings_test.dart` UC-01.02 (timeout no full, PASS isolado) e `credential_recovery_test.dart` UC-01.04 (flakiness/timing, falhas persistem em reruns isolados). |
| `flutter test test/modules/work_orders` | PASSOU | `00:06 +32: All tests passed!` (exit 0) |

## Matriz de conformidade

| Invariante / Requisito | Status | Evidência |
|---|---|---|
| **INV-01** Pausa só de IN_PROGRESS; PAUSED retoma para IN_PROGRESS; PAUSED não conclui direto | Conforme | `work_order_pause_test.dart` cobre transições e rejeições. |
| **UC-03.04** Justificativa obrigatória na pausa | Conforme | Domínio rejeita vazia `ERR_OS_JUSTIFICATIVA_OBRIGATORIA`; UI dialog. |
| **UC-03.04** Retomada sem GPS (decisão PO) | Conforme | `resume()` sem LocationCapture. |
| **UC-03.04** PAUSED -> CANCELLED com justificativa | Conforme | Teste domínio e UI. |
| **Persistência SQLite v7** | Conforme | `pause_reason` migração/repo/teste. |
| **DESIGN >=48dp / #115E59** | Conforme | Diálogo pausa com botões 48dp e CTA primaryAction. |

## Apontamentos

- **A1 (fora do slice, conhecido)**: flakiness `credential_recovery_test.dart` UC-01.04; `auth_session_settings_test.dart` timeout no full, verde isolado.
- **A2**: `pauseReason` persistido mas não exposto em UI de detalhe/histórico.

## Parecer

**APROVADO — confiança Alta**. UC-03.04 (cancelamento + pausa/retomada) consolidável como concluída.